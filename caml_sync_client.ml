open Core
open Lwt
open Cohttp
open Cohttp_lwt_unix
open Ezjsonm

module StrSet = Set.Make (String)

exception Timeout
exception Unauthorized
exception ServerError of string

let hidden_dir = ".caml_sync"

let valid_extensions = [".ml"; ".mli"; ".txt"]

let unwanted_strs =
  ["." ^ Filename.dir_sep ^ hidden_dir ^ Filename.dir_sep;
   "." ^ Filename.dir_sep ^ ".config"]

type config = {
  client_id: string;
  url: string;
  token: string;
  version: int;
}

let timeout =
  fun () -> bind (Lwt_unix.sleep 5.) (fun _ -> raise Timeout)

let load_config () =
  try
    let dict = get_dict (from_channel (open_in ".config")) in
    try
      {
        client_id = get_string (List.assoc "client_id" dict);
        url = get_string (List.assoc "url" dict);
        token = get_string (List.assoc "token" dict);
        version = get_int (List.assoc "version" dict);
      }
    with
    | Not_found -> raise (File_not_found ".config")
  with
  | Sys_error e ->
    raise (File_not_found ".config")

let update_config config =
  try
    let json =
      dict [
        "client_id", (string config.client_id);
        "url", (string config.url);
        "token", (string config.token);
        "version", (int config.version);
      ] in
    let out = open_out ".config"in
    to_channel out json;
    flush out
  with
  | _ ->
    raise (File_not_found ".config")

(* [get_all_filenames dir] returns a set of all the filenames
 * in directory [dir] or its subdirectories that are of approved suffixes *)
let get_all_filenames dir =
  let d_handle =
    try Unix.opendir dir  with | _ -> raise Not_found
  in search_dir d_handle StrSet.add StrSet.empty [] dir valid_extensions

let post_local_diff config version_diff =
  let open Uri in
  let uri = Uri.of_string  ("//"^config.url) in
  let uri = with_path uri "diff" in
  let uri = with_scheme uri (Some "http") in
  let uri = Uri.add_query_param' uri ("token", config.token) in
  let body = version_diff |> Core.build_version_diff_json |> Ezjsonm.to_string |> Cohttp_lwt__Body.of_string in
  let request = Client.post ~body:(body) uri
    >>= fun (resp, body) ->
    let code = resp |> Response.status |> Code.code_of_status in
    if code = 401 then raise Unauthorized
    else try (
      body |> Cohttp_lwt.Body.to_string >|= fun body ->
      match body |> from_string with
      | `O lst ->
        begin match List.assoc_opt "version" lst with
          | Some v ->
            get_int v
          | None ->
            raise (ServerError "Unexpected response: not field version")
        end
      | _ -> raise (ServerError "Unexpected response")
    ) with _ -> raise (ServerError "Unexpected response body format")
  in Lwt_main.run (Lwt.pick [request; timeout ()])

let compare_file filename =
  let cur_file_content = read_file filename in
  let old_file_content =
    try read_file (hidden_dir ^ Filename.dir_sep ^ filename)
    with | File_not_found _ -> [] (* this file is newly created *)
  in {
    file_name = filename;
    is_deleted = false;
    content_diff = calc_diff old_file_content cur_file_content
  }

(* [replace_prefix str prefix_old prefix_new] replaces the prefix [prefix_old]
 * of [str] with [prefix_new]
 * requires: [prefix_old] is a prefix of [str] *)
let replace_prefix str prefix_old prefix_new =
  let open String in
  if length str < length prefix_old
  then failwith "prefix to be replaced does not exist in current string"
  else let suffix = sub str (length prefix_old) (length str - length prefix_old) in
    prefix_new ^ suffix

(* [has_prefix_in_lst str_to_check lst_prefices] checks whether [str_to_check]
 * has a prefix in [lst_prefices] *)
let has_prefix_in_lst str_to_check lst_prefices =
  List.fold_left
    (fun acc elem ->
       try
         let sub_str = String.sub str_to_check 0 (String.length elem) in
         if sub_str = elem then true else acc
       with | Invalid_argument _ -> acc
    ) false lst_prefices

(* [contains s1 s2] checks if [s2] is a substring of [s1] *)
let contains s1 s2 =
  try
    let len = String.length s2 in
    for i = 0 to String.length s1 - len do
      if String.sub s1 i len = s2 then raise Exit
    done;
    false
  with Exit -> true

(* [contains_local filename] checks whether [filename] contains "_local"
 * right before its extension *)
let contains_local filename =
  let no_extension = Filename.chop_extension filename in
  let open String in
  let from_i = length no_extension - length "_local" in
  try
    let match_str = sub filename from_i (length "_local")    in
    match_str = "_local"
  with | _ -> false

let check_invalid_filename () =
  let filenames_cur = get_all_filenames "." in
  StrSet.fold
    (fun elem acc ->
       if has_prefix_in_lst elem unwanted_strs then acc (* skip this file *)
       else if contains_local elem then true else acc) filenames_cur false

let compare_working_backup () =
  let filenames_last_sync = get_all_filenames hidden_dir in
  let filenames_cur =
    get_all_filenames "." |> StrSet.filter
      (fun elem -> not(has_prefix_in_lst elem unwanted_strs)) in
  let working_files_diff_lst =
    (* all files in working directory *)
    StrSet.fold
      (fun f_name acc -> (compare_file f_name)::acc) filenames_cur []
  in let total_files_diff_lst =
       (* all files in sync directory but not in working direcoty.
        * These files have been removed after the last update *)
       let trans_filenames_last_sync =
         (* map every string in filenames_last_sync to a new string with "."
          * as prefix rather than hidden_dir *)
         StrSet.map
           (fun str -> replace_prefix str hidden_dir ".") filenames_last_sync in
       let deleted_files =
         StrSet.diff trans_filenames_last_sync filenames_last_sync in
       StrSet.fold
         (fun f_name acc ->
            {
              file_name = f_name;
              is_deleted = true;
              content_diff = calc_diff [] []
            }::acc) deleted_files working_files_diff_lst in
  List.filter (fun {content_diff} -> content_diff <> empty) total_files_diff_lst

let check_both_modified_files modified_file_diffs version_diff =
  let server_diff_files = version_diff.edited_files in
  let check_modified clt_file =
    if List.exists (fun f -> f.file_name = clt_file.file_name) server_diff_files
    then Some (clt_file.file_name, clt_file.is_deleted)
    else None in
  let modified_files_option = List.map check_modified modified_file_diffs in
  List.fold_left (fun acc ele ->
      match ele with
      | Some e -> e :: acc
      | None -> acc
    ) [] modified_files_option

let rename_both_modified both_modified_lst =
  List.iter
    (fun (elem, to_delete) ->
       if to_delete then delete_file elem
       else let extension = Filename.extension elem in
         let old_f_name = Filename.chop_extension elem in
         Sys.rename elem (old_f_name ^ "_local" ^ extension)) both_modified_lst

(* copy a file at [from_name] to [to_name], creating additional directories
 * if [to_name] indicates writing a file deeper down than the current directory
*)
let copy_file from_name to_name =
  write_file to_name (read_file from_name)

(* [copy_files from_names to_names] copy all files in [from_names] to
 * [to_names]. *)
let copy_files from_names to_names =
  List.iter2 (fun f t -> copy_file f t) from_names to_names

let backup_working_files () =
  let filenames_cur =
    get_all_filenames "." |> StrSet.filter
      (fun elem -> not(has_prefix_in_lst elem unwanted_strs)) in
  StrSet.iter (fun f ->
      let to_name = replace_prefix f "." hidden_dir in
      copy_file f to_name) filenames_cur

(* [remove_dir_and_files folder_name] removes the folder [folder_name] and its
 * content. It is equal to "rm -rf folder_name" in Unix. If [folder_name] is not
 * found, do nothing here. *)
let remove_dir_and_files folder_name =
  try
    get_all_filenames folder_name |> StrSet.iter delete_file;
    if Sys.file_exists folder_name then
      Unix.rmdir folder_name
  with
  | Not_found -> ()

let generate_client_version_diff server_diff =
  (*  0. create local_diff with compare_working_backup. *)
  let local_files_diff = compare_working_backup () in
  (* 1. call check_both_modified_files to get both_modified_lst. *)
  let both_modified_lst =
    check_both_modified_files local_files_diff server_diff in
  (* 2. rename files in both_modified_lst. *)
  rename_both_modified both_modified_lst;
  (* 3. copy files in both_modified_lst from hidden to local
   * directory. *)
  let to_file_names =
    both_modified_lst |> List.map (fun (filename, is_deleted) -> filename) in
  let from_file_names =
    to_file_names |> List.map
      (fun filename -> replace_prefix filename "." hidden_dir) in
  copy_files from_file_names to_file_names;
  (* 4. remove everything in hidden directory. *)
  remove_dir_and_files hidden_dir;
  (* 5. apply server_diff to local directory. *)
  List.iter (fun {file_name; is_deleted; content_diff} ->
      if is_deleted
      then delete_file file_name
      else
        let content =
          if Sys.file_exists file_name
          then
            let content' = read_file file_name in
            delete_file file_name;
            content'
          else [] in
        apply_diff content content_diff |> write_file file_name
    ) server_diff.edited_files;
  (* 6. call backup_working_files to copy everything from local
   * directory to hidden directory. *)
  backup_working_files ();
  begin
    try
      Unix.mkdir hidden_dir 0o770
    with
    | Unix.Unix_error _ -> ()
  end;
  (* 7. remove files in both_modified_list from local_diff
   * and return the resulting version_diff *)
  let return_files_diff = List.filter (fun {file_name} ->
      List.exists
        (fun (ele, _) -> ele = file_name)
        both_modified_lst |> not
    ) local_files_diff in
  (both_modified_lst, return_files_diff)


let get_update_diff config =
  let open Uri in
  let uri = Uri.of_string  ("//"^config.url) in
  let uri = with_path uri "diff" in
  let uri = with_scheme uri (Some "http") in
  let uri = Uri.add_query_param' uri ("token", config.token) in
  let uri = Uri.add_query_param' uri ("from", string_of_int config.version) in
  let request = Client.get uri
    >>= fun (resp, body) ->
    let code = resp |> Response.status |> Code.code_of_status in
    if code = 401 then raise Unauthorized
    else
      try (
        body |> Cohttp_lwt.Body.to_string >|= fun body ->
        let diff = body |> from_string |> parse_version_diff_json in
        update_config {config with version=diff.cur_version};
        generate_client_version_diff diff
      )
      with
      | _ ->
        raise (ServerError "during getting update diff")
  in Lwt_main.run (Lwt.pick [request; timeout ()])

let sync () =
  print_endline "Loading [.config]...";
  let config = load_config () in
  print_endline "Successfully loaded [.config].";
  if check_invalid_filename () then
    print_endline "Please resolve local merge conflict before syncing with the server.\n"
  else
    let print_modified m_list =
      if m_list = [] then ()
      else
        print_endline "Following file(s) have sync conflicts with the server:";
        List.iter (
          fun (file, deleted)->
            if deleted then
              print_endline (file^" - deleted")
            else
              print_endline file
        ) m_list;
      print_endline "These files have been renamed to [_local].";
      if List.exists (fun (_,deleted) -> deleted) m_list then
        print_endline "Files with [- deleted] appended have updates \
                       from the server, yet are deleted locally and are not \
                       renamed with the [_local] prefix. Please delete them again \
                       if you still wish to do so."
      else ()
    in
    match get_update_diff config with
    | (m_list, []) ->
      print_modified m_list
    | (m_list, diff_list) ->
      print_modified m_list;
      let version_diff = {
        prev_version = config.version;
        cur_version = config.version;
        edited_files = diff_list;
      } in
      let new_v = post_local_diff config version_diff in
      update_config {config with version=new_v}

let init url token =
  (* TODO: should not insert token directly *)
  (* Makes a dummy call to check if the url is a caml_sync server *)
  (* let uri = (Uri.add_query_param' (Uri.of_string (url^"/version")) ("token", token))  in
     let () = print_endline (Uri.to_string uri) in *)
  let open Uri in
  let uri = Uri.of_string  ("//"^url) in
  let uri = with_path uri "version" in
  let uri = with_scheme uri (Some "http") in
  let uri = Uri.add_query_param' uri ("token", token) in
  Client.get uri >>= fun (resp, body) ->
  let code = resp |> Response.status |> Code.code_of_status in
  (* First checks if pass token test by the response status code *)
  if code = 401 then
    `Empty |> Cohttp_lwt.Body.to_string >|= fun _ -> raise Unauthorized
  else
  if code <> 200 then
    `Empty |> Cohttp_lwt.Body.to_string >|= fun _ ->
    raise (ServerError "unexpected response code")
  else
    body |> Cohttp_lwt.Body.to_string >|= fun body ->
    print_endline body;
    match (from_string body) with
    | `O (json) ->
      begin match List.assoc_opt "version" json with
        | Some v ->
          if Sys.file_exists ".config" then
            print_endline "[.config] already exsits; it seems like the current directory\
                           has update_configalready been initialized into a caml_sync client directory"
          else
            let config = {
              client_id = "TODO";
              url = url;
              token = token;
              version = 0
            } in
            update_config config;
            remove_dir_and_files hidden_dir;
            Unix.mkdir hidden_dir 0o770;
            sync ()
        | None ->
          print_endline "The address you entered does not seem to be a valid caml_sync address"
      end
    | _ -> print_endline "The address you entered does not seem to be a valid caml_sync address"

(* usage:
 *  caml_sync init <url> <token> ->
 *    inits the current directory as a client directory
 *  caml_sync ->
 *    syncs files in local directories with files in server
*)
let () =
   if Array.length Sys.argv = 1 then
    sync ()
   else match Array.get Sys.argv 1 with
     | "init" ->
       if (Array.length Sys.argv) = 4 then
         Lwt_main.run (init (Array.get Sys.argv 2) (Array.get Sys.argv 3))
       else Lwt_main.run (init "127.0.0.1:8080" "default")
     | "clean" ->
       remove_dir_and_files ".caml_sync";
       begin try Sys.remove ".config" with
         | Sys_error e -> ()
       end
     | _ ->
       print_endline "usage:\n\
                      caml_sync init <url> <token> ->\n\
                      \tinits the current directory as a client directory\
                      caml_sync ->\n\
                      \tsyncs files in local directories with files in server"
