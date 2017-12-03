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

(* [(filename, [line1; line2; line3]); ...] *)
type state = (string * string list) list

let default_config = {
  server_id = "default";
  url = "localhost";
  token = "password";
  port = 8080;
  version = 0;
}

let write_config c =
  let open Ezjsonm in
  dict ["server_id", (string c.server_id);
        "url", (string c.url);
        "token", (string c.token);
        "port", (int c.port);
        "version", (int c.version)] 
  |> Ezjsonm.to_channel (open_out "config.json")

let init token =
  write_config {default_config with token = token}


let load_config () =
  let open Ezjsonm in
  let json = Ezjsonm.from_channel (open_in "config.json") in
  {
    server_id = extract_string json "server_id";
    url = extract_string json "url";
    token = extract_string json "token";
    port = extract_int json "port";
    version = extract_int json "version";
  }

let calc_version_diff_between_states state1 state2 =
  raise Unimplemented

let apply_version_diff_to_state version_diff state =
  raise Unimplemented

let calc_diff_by_version v_from v_to =
  raise Unimplemented

(* [verify_token req config] is true if the token in request is equal to  *)
let verify_token req config =
  match "token" |> Uri.get_query_param (Request.uri req) with
  | Some tk -> tk = config.token
  | None -> false

let handle_get_current_version = get "/version/:token" begin fun req ->   
    (* load config from config.json *)
    let config = load_config () in    
    if verify_token req config then
      `Json (
        let open Ezjsonm in
        dict ["version", int config.version]
      ) |> respond'
    else
      (* Token is incorrect. *)
      `String ("Unauthorized Access") |> respond' ~code:`Unauthorized
  end

let handle_post_diff_from_client = post "/diff" begin fun
    req ->
    let config = load_config () in
    if verify_token req config then
      req |> App.json_of_body_exn |> Lwt.map 
        begin fun req_json -> 
          let req_v_diff = parse_version_diff_json req_json in
          let new_version = config.version + 1 in
          let new_config = {config with version = new_version} in
          let save_json = {
            req_v_diff with 
            prev_version = config.version; 
            cur_version = new_version
          } |> build_version_diff_json in
          Ezjsonm.to_channel (open_out ("version_" ^ (string_of_int new_version) ^ ".diff")) save_json;
          write_config new_config;
          `Json (
            let open Ezjsonm in
            dict ["version", int new_config.version]
          ) |> respond
        end
    else
      `String ("Unauthorized Access") |> respond' ~code:`Unauthorized
  end

let handle_get_diff_from_client = get "/diff" begin fun
    req ->
    let config = load_config () in
    if verify_token req config then
      match "from" |> Uri.get_query_param (Request.uri req) with
      | Some from_str -> begin
          let is_int s =
            try ignore (int_of_string s); true
            with _ -> false in
          if is_int from_str then
            let from = int_of_string from_str in
            let v_diff = calc_diff_by_version from config.version in 
            let json = build_version_diff_json v_diff in
            `Json (
              json
            ) |> respond'
          else
            `String ("Parameter [from] is illegal.") |> respond' ~code:`Bad_request
        end
      | None -> `String ("Parameter [from] is required.") |> respond' ~code:`Bad_request
    else
      `String ("Unauthorized Access") |> respond' ~code:`Unauthorized
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