open Core
open Lwt
open Cohttp
open Cohttp_lwt_unix

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

(* [search_dir dir_handle acc dir_name] recursively searches for all the files
 * in the directory represented by [dir_handle] or its subdirectories,
 * and returns a list of all such files of approved suffixes
 * requires: [dir_handle] is a valid directory handle returned by Unix.opendir. *)
let rec search_dir dir_handle acc dir_name =
  match Unix.readdir dir_handle with
  | exception End_of_file ->
    let () = Unix.closedir dir_handle in acc
  | s_name ->
    if Sys.is_directory s_name then
      let sub_d_path = dir_name ^ Filename.dir_sep ^ s_name in
      let sub_d_handle = Unix.opendir sub_d_path in
      let sub_acc = search_dir sub_d_handle acc sub_d_path in
       search_dir dir_handle (sub_acc @ acc) dir_name
    else if Filename.check_suffix s_name ".txt" then
      let file_path = dir_name ^ Filename.dir_sep ^ s_name in
      search_dir dir_handle (file_path::acc) dir_name
    else search_dir dir_handle acc dir_name

(* [get_all_filenames dir] returns a list of all the files in directory [dir] or
 * its subdirectories that are of approved suffixes *)
let get_all_filenames dir =
  let d_handle =
    try Unix.opendir dir  with | _ -> raise Not_found
     in search_dir d_handle [] dir

let post_local_diff config version_diff =
  failwith("unimplemented")

let check_modified_files () =
  failwith("unimplemented")

let check_both_modified_files str_list version_diff =
  failwith("unimplemented")

let rename_both_modified str_list =
  failwith("unimplemented")

let compare_file file_name =
  failwith("unimplemented")

let compare_working_backup str_list =
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
