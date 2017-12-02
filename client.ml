open Core
open Lwt
open Cohttp
open Cohttp_lwt_unix

let get_latest_version config =
  failwith("unimplemented")

let get_update_diff config =
  failwith("unimplemented")

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

let init url token =
  failwith("unimplemented")

let load_config () =
  failwith("unimplemented")

(* usage:
 *  caml_sync init <url> <token> ->
 *    inits the current directory as a client directory
 *  caml_sync ->
 *    syncs files in local directories with files in server
*)
let () =
  if Array.length Sys.argv = 0 then
    failwith("unimplemented")
  else
    if (Array.length Sys.arv 3) = "init" && (Array.get Sys.arv 0) = "init" then
    let () = print_endline "You are initializing the current directory as a
      caml_sync directory; Please indicate the address of the server you are
      linking to:\n" in
    match read_line () with
    | exception End_of_file -> ()
    | url ->
      match read_line () with
      | exception End_of_file -> ()
      | token -> let () = print_endline
                     "Please enter the password for the server at "
                          + url + " to connect to the server:\n" in
        init url token
    else
      print_endline "usage:\n
        \tcaml_sync init <url> <token> ->\n
        \t\tinits the current directory as a client directory
        \tcaml_sync ->\n
        \t\tsyncs files in local directories with files in server\n"
