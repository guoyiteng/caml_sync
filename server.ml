open Core
open Opium.Std

exception Unimplemented

type version = int

type config = {
  server_id: string;
  url: string;
  token: string;
  port: string;
  version: int;
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