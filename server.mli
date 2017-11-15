open Core
open Opium.Std

type version = int

(* ocaml representation of server config in "config.json". *)
type config = {
  server_name: string;
  url: string;
  token: string;
  port: string;
  version: int;
}

(* [init token] creates a caml_sync server directory structure in the current
 * directory if it does not exist. It also initializes a "config.json" file.*)
val init: string -> unit

(* [load_config] loads the configuration of server if there's already a 
 * configuration created for the server.
 * TODO: what if hasnt init? reject or init?
*)
val load_config: unit -> config

(* [verify token] is true if the token is correct.
 * requires: [config] is a caml_sync configuration 
*)
val verify: config -> string -> bool

(* [calc_diff_by_version from to] is the difference between version [from] and
 * version [to].
*)
val calc_diff_by_version: int -> int -> version_diff

(* Handle GET request at "/version".
 * returns: a json containing [cur_version] to the client. *)
val handle_get_current_version: App.builder

(* Handle POST request at "/diff". 
 * accepts: the diff json between the current client version and the latest
 * server version
 * effects: creates a new version in the server to store this new diff and update
 * [cur_version] to [cur_version + 1].
 * returns: a json containing the [cur_version] to the client. *)
val handle_post_diff_from_client: App.builder

(* Handle GET request at "/diff/:client_version"
 * accepts: [client_version] is the current client version number.
 * returns: a diff json containing the different between the client version and
 * current server version. [cur_version] should also be included and sent back
 * to the client. *)
val handle_get_diff_from_client: App.builder

(* usage:
 *  caml_sync_server init <token> ->
 *    inits the current directory as a server directory
 *  caml_sync_server ->
 *    runs the server
 *)
 val main : unit -> unit