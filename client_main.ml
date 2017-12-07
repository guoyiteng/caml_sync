open Caml_sync_client

let () =
  try Caml_sync_client.main () with
  | Unauthorized -> print_endline ("Your token is wrong.\n" ^ "Please run 'camlsync clean' and 'camlsync init <url> <token>' to reinitialize your server.")
  | Timeout -> print_endline "Your request is time out."
  | Unix.Unix_error _ -> print_endline ("Cannot connect to the server." ^ "\nPlease double check your server address and make sure your server is running.")
  | ServerError e -> print_endline e
  | Bad_request s -> print_endline s
  | Not_Initialized -> print_endline "Current directory has not been initialized."
  | Invalid_argument s -> print_endline s
