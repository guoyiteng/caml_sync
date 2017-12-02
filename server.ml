open Core
open Opium.Std

exception Unimplemented

type version = int

type config = {
  server_id: string;
  url: string;
  token: string;
  port: int;
  mutable version: int;
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
  raise Unimplemented

let verify c token =
  raise Unimplemented

let calc_diff_by_version v_from v_to =
  raise Unimplemented

let handle_get_current_version = get "/version/:token" begin fun req ->   
    let token = param req "token" in
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
    App.empty
    |> App.port 8080
    |> handle_get_current_version
    |> handle_post_diff_from_client
    |> handle_get_diff_from_client
    |> App.run_command
  else if Array.length Sys.argv = 3 && Sys.argv.(1) = "init"
  then
    let token = Sys.argv.(2) in
    init token
  else
    print_endline "Invalid arguments.
    usage: ./caml_sync_server.native [init <token>]"
let _ = main ()