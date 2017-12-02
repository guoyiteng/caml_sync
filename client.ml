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

let load_config () =
  failwith("unimplemented")

let update_config config =
  failwith("unimplemented")

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
  (* TODO: should not insert token directly *)
  (* Makes a dummy call to check if the url is a caml_sync server *)
  Client.get (Uri.of_string url^"/version/"^token) >>= fun (resp, body) ->
  let code = resp |> Response.status |> Code.code_of_status in
  (* First checks if pass token test by the response status code *)
  if code = 401 then print_endline "Token entered is incorrect" else
  body |> Cohttp_lwt.Body.to_string >|= fun body ->
  let open Ezjsonm in
  match (from_string body) with
  | `O [("version", v )::_] ->
    if Sys.file_exists ".config" then
      raise (File_existed "[.config] already exsits; it seems like the current directory
        has already been initialized into a caml_sync client directory")
    else
      let config = {
        client_id = "TODO";
        url = url;
        token = token;
        version = 0
      } in
      update_config config;
      sync _
  | _ -> print_endline "The address you entered does not seem to be a valid caml_sync address"

let sync () =
  failwith("unimplemented")

(* usage:
 *  caml_sync init <url> <token> ->
 *    inits the current directory as a client directory
 *  caml_sync ->
 *    syncs files in local directories with files in server
*)
let () =
  if Array.length Sys.argv = 0 then
    sync _
  else
  if (Array.length Sys.argv) = 3 && (Array.get Sys.argv 0) = "init" then
    let () = print_endline "You are initializing the current directory as a
      caml_sync directory; Please indicate the address of the server you are
      linking to:\n" in
    match read_line () with
    | exception End_of_file -> ()
    | url ->
      match read_line () with
      | exception End_of_file -> ()
      | token -> let () = print_endline
                     ("Please enter the password for the server at "
                      ^ url ^ " to connect to the server:\n") in
        init url token
    else
      print_endline "usage:\n
        caml_sync init <url> <token> ->\n
        \tinits the current directory as a client directory
        caml_sync ->\n
        \tsyncs files in local directories with files in server\n"
