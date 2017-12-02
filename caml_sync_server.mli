open Core
open Opium.Std

type version = int

(* ocaml representation of server config in "config.json". *)
type config = {
  server_id: string;
  url: string;
  token: string;
  port: int;
  version: int;
}

(* [init token] creates a caml_sync server directory structure in the current
 * directory if it does not exist. It also initializes a ".config" file. *)
val init: string -> unit

(* [load_config _] loads the configuration of server if there's already a 
 * configuration created for the server.
 * requires: ".config" must exist in the current directory.
 *)
val load_config: unit -> config

(* [calc_diff_by_version v_from v_to] returns the difference between version [from] and
 * version [to].
*)
val calc_diff_by_version: int -> int -> version_diff

(* Handle GET request at "/version".
 * returns: a json containing [cur_version] to the client. *)
val handle_get_current_version: App.builder

(* Handle POST request at "/diff". 
 * accepts: the diff json representing the difference between the current client version 
 * and the latest server version
 * effects: updates [cur_version] to [cur_version + 1], and creates a new directory in the server 
 * to store this new diff
 * returns: a json containing the [cur_version] to the client. *)
val handle_post_diff_from_client: App.builder

(* Handle GET request at "/diff/:client_version"
 * accepts: the client's current version number ([client_version]).
 * returns: a diff json containing the difference between the client version and
 * current server version. [cur_version] should also be included and sent back
 * to the client. *)
val handle_get_diff_from_client: App.builder

(* usage:
 *  caml_sync_server init <token> ->
 *    initializes the current directory as a server directory
 *  caml_sync_server ->
 *    runs the server
 *)
 val main : unit -> unit