open Core
open Opium.Std

exception Unimplemented
exception Not_init
exception Already_init
exception Server_error of string

type version = int

type config = {
  server_id: string;
  url: string;
  token: string;
  port: int;
  version: int;
}

module StrMap = Map.Make(String)

(* keyed on filename, value is content of the file
 * [(filename, [line1; line2; line3]); ...] *)
type state = string list StrMap.t

let default_config = {
  server_id = "localhost";
  url = "127.0.0.1";
  token = "default";
  port = 8080;
  version = 0;
}

let lock = Rwlock.create ()

(* [write_config c] writes server config [c] to "config.json". *)
let write_config c =
  let open Ezjsonm in
  dict ["server_id", (string c.server_id);
        "url", (string c.url);
        "token", (string c.token);
        "port", (int c.port);
        "version", (int c.version)]
  |> write_json "config.json"

let load_config () =
  let json = read_json "config.json" in
  {
    server_id = extract_string json "server_id";
    url = extract_string json "url";
    token = extract_string json "token";
    port = extract_int json "port";
    version = extract_int json "version";
  }

let init_history () =
  {
    log = [{
        version = 0;
        timestamp = Unix.time ()
      }]
  } |> build_history_log_json |> write_json "history.json"

let write_history log =
  log |> build_history_log_json |> write_json "history.json"

let load_history () =
  let json = read_json "history.json" in
  json |> parse_history_log_json

let init token =
  write_config {default_config with token = token};
  init_history ();
  {
    prev_version = 0;
    cur_version = 0;
    edited_files = []
  } |> build_version_diff_json |> write_json "version_0.diff"

let calc_file_diffs_between_states state1 state2 =
  let open StrMap in
  (* iterate over all files in state1 and compare with state2 *)
  let diff_lst_0 =
    fold (
      fun cur_file cur_content acc ->
        if not(mem cur_file state2) then
          {
            file_name = cur_file;
            is_deleted = true;
            content_diff = Diff_Impl.calc_diff [] []
          }::acc
        else
          let new_content = find cur_file state2 in
          let content_diff = Diff_Impl.calc_diff cur_content new_content in
          {
            file_name = cur_file;
            is_deleted = false;
            content_diff = content_diff
          }::acc
    ) state1 [] in
  (* add all files that appear in state2 but not in state1 *)
  let diff_lst_1 =
    fold (
      fun cur_file cur_content acc ->
        if not(mem cur_file state1) then
          {
            file_name = cur_file;
            is_deleted = false;
            content_diff = Diff_Impl.calc_diff [] cur_content
          }::acc
        else acc
    ) state2 [] in
  diff_lst_1 @ diff_lst_0

let apply_version_diff_to_state version_diff state =
  let open StrMap in
  List.fold_left
    (fun acc filediff ->
       let cur_file = filediff.file_name in
       let to_delete = filediff.is_deleted in
       let content_diff = filediff.content_diff in
       if not(mem cur_file acc) then
         begin
           if (to_delete) then raise (Server_error "Invalid version diff")
           else
             (* create new file *)
             let new_content = Diff_Impl.apply_diff [] content_diff in
             add cur_file new_content acc
         end
       else
         begin
           if to_delete then remove cur_file acc
           else let old_content = find cur_file acc in
             let new_content = Diff_Impl.apply_diff old_content content_diff in
             add cur_file new_content acc
         end
    ) state (version_diff.edited_files)

let calc_diff_by_version v_from v_to =
  assert (v_from <= v_to);
  if v_from = v_to then []
  else let init_state = StrMap.empty in
    let rec update_to_version state cur_ver ver = begin
      Rwlock.read_lock lock;
      let v_json = read_json ("version_" ^ string_of_int cur_ver ^ ".diff") in
      Rwlock.read_unlock lock;
      let v_diff = parse_version_diff_json v_json in
      assert (v_diff.cur_version = cur_ver);
      let new_state = apply_version_diff_to_state v_diff state in
      if cur_ver = ver then
        new_state
      else
        update_to_version new_state (cur_ver + 1) ver
    end in
    let s_from = update_to_version init_state 0 v_from in
    let s_to = update_to_version s_from (v_from + 1) v_to in
    calc_file_diffs_between_states s_from s_to

(* [verify_token req config] returns true if the token in request
 * is equal to the valid token *)
let verify_token req config =
  match "token" |> Uri.get_query_param (Request.uri req) with
  | Some tk -> tk = config.token
  | None -> false

let handle_get_current_version = get "/version" begin fun req ->
    (* load config from config.json *)
    Rwlock.read_lock lock;
    let config = load_config () in
    Rwlock.read_unlock lock;
    if verify_token req config then
      `Json (
        let open Ezjsonm in
        dict ["version", int config.version]
      ) |> respond'
    else
      (* Token is invalid. *)
      `String ("Unauthorized Access") |> respond' ~code:`Unauthorized
  end

let handle_get_history_list = get "/history" begin fun
    req ->
    Rwlock.read_lock lock;
    let config = load_config () in
    if verify_token req config then
      let logs = (load_history ()).log in
      Rwlock.read_unlock lock;
      `Json ({log = List.tl logs} |> build_history_log_json) |> respond'
    else
      `String ("Unauthorized Access") |> respond' ~code:`Unauthorized
  end

let handle_post_diff_from_client = post "/diff" begin fun
    req ->
    Rwlock.read_lock lock;
    let config = load_config () in
    Rwlock.read_unlock lock;
    if verify_token req config then
      let history_log = load_history () in
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
          Rwlock.write_lock lock;
          write_json ("version_" ^ (string_of_int new_version) ^ ".diff") save_json;
          write_config new_config;
          write_history {
            log = ( {version = new_version; timestamp = Unix.time ()} :: 
                    (List.rev history_log.log)) |> List.rev 
          };
          Rwlock.write_unlock lock;
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
    Rwlock.read_lock lock;
    let config = load_config () in
    Rwlock.read_unlock lock;
    if verify_token req config then
      try
        let parse_from_or_to from_or_to =
          let is_int s =
            try ignore (int_of_string s); true
            with _ -> false in
          match from_or_to |> Uri.get_query_param (Request.uri req) with
          | Some str -> 
            if is_int str then int_of_string str
            else if from_or_to = "from" then raise (Invalid_argument "Parameter [from] is illegal.")
            else if from_or_to = "to" then raise (Invalid_argument "Parameter [to] is illegal.")
            else raise (Server_error "parse_from_or_to only can parse from or to")
          | None ->
            if from_or_to = "from" then 0
            else if from_or_to = "to" then config.version
            else raise (Server_error "parse_from_or_to only can parse from or to") in
        let from_v = parse_from_or_to "from" in
        let to_v = parse_from_or_to "to" in
        if from_v <= to_v then
          let v_diff = {
            prev_version = from_v;
            cur_version = to_v;
            edited_files = calc_diff_by_version from_v to_v
          } in
          `Json (build_version_diff_json v_diff) |> respond'
        else
          raise (Invalid_argument "Parameter [from] is larger than [to].")
      with
      | Invalid_argument s -> 
        `String (s) |> respond' ~code:`Bad_request
    else
      `String ("Unauthorized Access") |> respond' ~code:`Unauthorized
  end

let main () =
  try
    if Array.length Sys.argv = 1
    then
      try
        let config = load_config () in
        print_endline ("Server's name: " ^ config.server_id);
        print_endline ("Server opens at " ^ config.url ^ ":" ^ (string_of_int config.port));
        print_endline ("Token: " ^ config.token);
        App.empty
        |> App.port config.port
        |> handle_get_current_version
        |> handle_post_diff_from_client
        |> handle_get_diff_from_client
        |> handle_get_history_list
        |> App.run_command
      with
      | File_not_found msg ->
        raise Not_init
    else if Array.length Sys.argv = 2 && Sys.argv.(1) = "init"
    then 
      if not (Sys.file_exists "config.json") then
        init "default"
      else raise Already_init
    else if Array.length Sys.argv = 3 && Sys.argv.(1) = "init"
    then
      let token = Sys.argv.(2) in
      if not (Sys.file_exists "config.json") then
        init token
      else raise Already_init
    else if Array.length Sys.argv = 2 && Sys.argv.(1) = "clean"
    then
      let dir = "." in
      let d_handle =
        try Unix.opendir dir  with | _ -> raise Not_found
      in search_dir d_handle (List.cons) [] [] dir [".json"; ".diff"] |> List.iter delete_file;
      Unix.closedir d_handle
    else
      raise (Invalid_argument "Invalid arguments")
  with
  | Not_init -> print_endline "Please initialize your server first.";
  | Already_init -> 
    print_endline "This directory has already been initialized as a server working directory.";
    print_endline "You can use \'camlsyncserver clean\' to clean up this direcotry."
  | Invalid_argument _ -> 
    print_endline "Invalid arguments.";
    print_endline "usage: camlsyncserver [<init [token]> | <clean>]"

let _ = main ()
