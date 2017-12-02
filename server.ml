open Core
open Opium.Std

exception Unimplemented

type version = int

type config = {
  server_id: string;
  url: string;
  token: string;
  port: int;
  version: int;
}

let config = ref {
    server_id = "default";
    url = "localhost";
    token = "wilsonsb";
    port = 8080;
    version = 0;
  }


let init token =
  raise Unimplemented

let load_config () =
  raise Unimplemented

let verify c token =
  raise Unimplemented

let calc_diff_by_version v_from v_to =
  raise Unimplemented

let handle_get_current_version = get "/version" begin fun req ->
    `String ("Hello World") |> respond'
  end

let handle_post_diff_from_client = post "/diff" begin fun
    req ->
    raise Unimplemented 
  end

let handle_get_diff_from_client = get "/diff" begin fun
    req ->
    raise Unimplemented
  end

let main () =
  App.empty
  |> App.port 8080
  |> handle_get_current_version
  |> handle_post_diff_from_client
  |> handle_get_diff_from_client
  |> App.run_command

let _ = main ()