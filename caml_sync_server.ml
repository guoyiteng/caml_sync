open Core
open Opium.Std

exception Unimplemented
exception Server_Error

type version = int

type config = {
  server_id: string;
  url: string;
  token: string;
  port: int;
  version: int;
}

let config = {
  server_id = "default";
  url = "localhost";
  token = "password";
  port = 8080;
  version = 0;
}


let init token =
  let open Ezjsonm in
  dict ["server_id", (string config.server_id);
        "url", (string config.url);
        "token", (string token);
        "port", (int config.port);
        "version", (int config.version)] 
  |> Ezjsonm.to_channel (open_out "config.json")

let load_config () =
  let open Ezjsonm in
  let json = Ezjsonm.from_channel (open_in "config.json") in
  let extract_string name = Ezjsonm.(get_string (find json [name])) in
  let extract_int name = Ezjsonm.(get_int (find json [name])) in
  {
    server_id = extract_string "server_id";
    url = extract_string "url";
    token = extract_string "token";
    port = extract_int "port";
    version = extract_int "version";
  }

let calc_diff_by_version v_from v_to =
  raise Unimplemented

let handle_get_current_version = get "/version/:token" begin fun req ->   
    let token = param req "token" in
    (* load config from config.json *)
    let config = load_config () in    
    if token = config.token then
      `Json (
        let open Ezjsonm in
        dict ["version", int config.version]
      ) |> respond'
    else
      (* Token is incorrect. *)
      `String ("Unauthorized Access") |> respond' ~code:`Unauthorized
  end

let handle_post_diff_from_client = post "/diff/:token" begin fun
    req ->
    raise Unimplemented
  end

let handle_get_diff_from_client = get "/diff/:token" begin fun
    req ->
    raise Unimplemented
  end

let main () =
  if Array.length Sys.argv = 1
  then
    try
      let config = load_config () in
      App.empty
      |> App.port config.port
      |> handle_get_current_version
      |> handle_post_diff_from_client
      |> handle_get_diff_from_client
      |> App.run_command
    with
    | Sys_error msg -> 
      print_endline "Cannot find config.json.";
      print_endline msg
    | _ -> raise Server_Error
  else if Array.length Sys.argv = 3 && Sys.argv.(1) = "init"
  then
    let token = Sys.argv.(2) in
    init token
  else
    print_endline "Invalid arguments.
    usage: ./caml_sync_server.native [init <token>]"
let _ = main ()