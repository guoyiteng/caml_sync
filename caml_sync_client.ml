open Core
open Lwt
open Cohttp
open Cohttp_lwt_unix

module StrSet = Set.Make (String)

let hidden_dir = ".caml_sync/"

let valid_extensions = [".ml"; ".mli"; ".txt"]

type config = {
  client_id: string;
  url: string;
  token: string;
  version: int;
}

let timeout =
  bind (Lwt_unix.sleep 5.) (fun _ -> return None)

let load_config () =
  try
    let open Ezjsonm in
    let dict = get_dict (from_channel (open_in ".config")) in
    try
    {
      client_id = get_string (List.assoc "client_id" dict);
      url = get_string (List.assoc "url" dict);
      token = get_string (List.assoc "token" dict);
      version = get_int (List.assoc "version" dict);
    }
    with
    | Not_found -> failwith("Fails to load [.config]: incorrect format")
    | _ -> failwith("Unexpected Error")
  with
  | Sys_error e ->
    print_endline e;
    failwith("Cannot find .config. It seems the directory hass not
      been initialized to a caml_sync directory.")
  | _ -> failwith("Unexpected internal error")

let update_config config =
  try
    let open Ezjsonm in
    let json =
      dict [
        "client_id", (string config.client_id);
        "url", (string config.url);
        "token", (string config.token);
        "version", (int config.version);
      ] in
    to_channel (open_out ".config") json
  with
  | Sys_error e ->
    print_endline "Cannot find .config. It seems the directory hass not
      been initialized to a caml_sync directory.";
    print_endline e
  | _ -> print_endline "Unexpected internal error"

let get_latest_version config =
  let request = Client.get (Uri.of_string
                (config.url^"/version/?token="^config.token)) >>=
  fun (resp, body) ->
  let code = resp |> Response.status |> Code.code_of_status in
  if code = 401 then
    let () = print_endline
        "Token incorrect; you no longer have access to the repo.\n"
    in
    return (Some (-1))
  else
    failwith("unimplemented") in
  Lwt_main.run (Lwt.pick [request; timeout])

let get_update_diff config =
  failwith("unimplemented")

(* [search_dir dir_handle acc_file acc_dir dir_name valid_exts]
 * recursively searches for all the files in the directory
 * represented by [dir_handle] or its subdirectories,
 * and returns a set of all such files of approved suffixes in [valid_exts]
 * requires: [dir_handle] is a valid directory handle returned by Unix.opendir. *)
let rec search_dir dir_handle acc_file acc_dir dir_name valid_exts =
  (* similar to BFS *)
  match Unix.readdir dir_handle with
  | exception End_of_file ->
    let () = Unix.closedir dir_handle in
    (* go into subdirectories *)
    List.fold_left
      (fun acc a_dir ->
         let sub_d_handle = Unix.opendir a_dir in
         search_dir sub_d_handle acc [] a_dir valid_exts
      ) acc_file acc_dir
  | p_name ->
    let path = dir_name ^ Filename.dir_sep ^ p_name in
    if Sys.is_directory path && p_name <> "." && p_name <> ".." then
      (* save information about this subdirectory in acc_dir, to be processed
       * after having seen all files in the current directory *)
      search_dir dir_handle acc_file (path::acc_dir) dir_name valid_exts
    else if List.mem (Filename.extension p_name) valid_exts then
      let new_fileset = StrSet.add path acc_file in
      search_dir dir_handle new_fileset acc_dir dir_name valid_exts
    else search_dir dir_handle acc_file acc_dir dir_name valid_exts

(* [get_all_filenames dir] returns a set of all the filenames
 * in directory [dir] or its subdirectories that are of approved suffixes *)
let get_all_filenames dir =
  let d_handle =
    try Unix.opendir dir  with | _ -> raise Not_found
  in search_dir d_handle StrSet.empty [] dir valid_extensions

let post_local_diff config version_diff =
  failwith("unimplemented")

let compare_file filename =
  let cur_file_content = read_file filename in
  let old_file_content =
    try read_file (hidden_dir ^ filename)
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
  let suffix = String.(sub str (length prefix_old) (length str - 1)) in
  prefix_new ^ suffix

(* [has_prefix_in_lst str_to_check lst_prefices] checks whether [str_to_check]
 * has a prefix in [lst_prefices] *)
let has_prefix_in_lst str_to_check lst_prefices =
  List.fold_left
    (fun acc elem ->
       try
         let sub_str = String.sub str_to_check 0 (String.length elem - 1) in
         if sub_str = elem then true else acc
       with | Invalid_argument _ -> acc
) false lst_prefices

let compare_working_backup () =
  let filenames_last_sync = get_all_filenames hidden_dir in
  let unwanted_strs =
    ["." ^ Filename.dir_sep ^ hidden_dir; "." ^ Filename.dir_sep ^ ".config"] in
  let filenames_cur =
    get_all_filenames "." |> StrSet.filter
      (fun elem -> not(has_prefix_in_lst elem unwanted_strs)) in
  let file_diff_lst0 =
    (* all files in working directory *)
    StrSet.fold
      (fun f_name acc -> (compare_file f_name)::acc) filenames_cur []
  in let file_diff_lst1 =
       (* all files in sync directory but not in working direcoty.
        * These files have been removed after the last update *)
       let trans_filenames_last_sync =
         (* map every string in filenames_last_sync to a new string with "./"
          * as prefix rather than hidden_dir *)
         StrSet.map
           (fun str -> replace_prefix str hidden_dir "./") filenames_last_sync in
       let deleted_files =
         StrSet.diff trans_filenames_last_sync filenames_last_sync in
       StrSet.fold
         (fun f_name acc ->
            {
              file_name = f_name;
              is_deleted = true;
              content_diff = calc_diff [] []
            }::acc) deleted_files [] in
  file_diff_lst1 @ file_diff_lst0

let check_both_modified_files str_list version_diff =
  failwith("unimplemented")

let rename_both_modified str_list =
  List.iter
    (fun elem ->
       let extension = Filename.extension elem in
       let old_f_name = String.(sub elem 0 ((length elem) - (length extension))) in
       Sys.rename elem (old_f_name ^ "_local" ^ extension))

let generate_client_version_diff server_diff =
  failwith("unimplemented")

let backup_working_files () =
  failwith("unimplemented")

let sync =
  Client.get (Uri.of_string ("http://www.google.com")) >>= fun (resp, body) ->
  body |> Cohttp_lwt.Body.to_string >|= fun body ->
  print_endline "hey boi"

let init url token =
  (* TODO: should not insert token directly *)
  (* Makes a dummy call to check if the url is a caml_sync server *)
  Client.get (Uri.of_string (url^"/version/?token="^token)) >>= fun (resp, body) ->
  let code = resp |> Response.status |> Code.code_of_status in
  (* First checks if pass token test by the response status code *)
  if code = 401 then
    `Empty |> Cohttp_lwt.Body.to_string >|= fun _ -> print_endline "Token entered is incorrect\n"
  else
    (* body |> Cohttp_lwt.Body.to_string >|= fun body -> *)
    let open Ezjsonm in
    body |> Cohttp_lwt.Body.to_string >|= fun body ->
    match (from_string body) with
    | `O (json) ->
      begin match List.assoc_opt "verson" json with
      | Some v ->
        if Sys.file_exists ".config" then
          raise (File_existed "[.config] already exsits; it seems like the current directory
            has already been initialized into a caml_sync client directory\n")
        else
          let config = {
            client_id = "TODO";
            url = url;
            token = token;
            version = 0
          } in
          let () = update_config config in
          Lwt_main.run sync
      | None ->
        print_endline "The address you entered does not seem to be a valid caml_sync address\n"
      end
    | _ -> print_endline "The address you entered does not seem to be a valid caml_sync address\n"

(* usage:
 *  caml_sync init <url> <token> ->
 *    inits the current directory as a client directory
 *  caml_sync ->
 *    syncs files in local directories with files in server
*)
let () =
  if Array.length Sys.argv = 1 then
    Lwt_main.run sync
  else
  if (Array.length Sys.argv) = 2 && (Array.get Sys.argv 1) = "init" then
    let () = print_endline "\nYou are initializing current directory as a caml_sync\
                            directory; Please indicate the address of the server you are\
                            connecting to:\n" in
    match read_line () with
    | exception End_of_file -> ()
    | url ->
      let () = print_endline ("Please enter the password for the server at "
                              ^ url ^ " to connect to the server:\n") in
          match read_line () with
          | exception End_of_file -> ()
          | token ->
            Lwt_main.run (init url token)
  else
    print_endline "usage:\n\
                   caml_sync init <url> <token> ->\n\
                   \tinits the current directory as a client directory\
                   caml_sync ->\n\
                   \tsyncs files in local directories with files in server\n"
