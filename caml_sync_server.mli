open Core
open Opium.Std

(* Ocaml representation of server config information in "config.json". *)
type config

(* Ocaml representation of all of the user's files *)
type state

(* [init token] creates a caml_sync server directory structure in the current
 * directory if it does not exist. It also initializes a ".config" file. *)
val init: string -> unit

(* [load_config _] loads the configuration of server if there's already a
 * configuration created for the server.
 * requires: ".config" must exist in the current directory.
 *)
val load_config: unit -> config

(* [write_config c] writes server config [c] to "config.json". *)
val write_config: config -> unit

val init_history: unit -> unit

val load_history: unit -> history_log

val write_history: history_log -> unit

(* [calc_file_diffs_between_states state1 state2] returns a file_diff list between
 * [state1] and [state2]. [state1] is the base state and [state2] is the new
 * state. *)
val calc_file_diffs_between_states: state -> state -> file_diff list

(* [apply_version_diff_to_state version_diff state] returns the result state after
 *  we apply all changes in [version_diff] to [state]. *)
val apply_version_diff_to_state: version_diff -> state -> state

(* [calc_diff_by_version v_from v_to] returns the list of edited files
 * between version [v_from] and version [v_to]
 * requires: [v_from] <= [v_to].
*)
val calc_diff_by_version: int -> int -> file_diff list

(* Handle GET request at "/version".
 * returns: a json containing [cur_version] to the client. *)
val handle_get_current_version: App.builder

val handle_post_diff_from_client: App.builder

(* Handle POST request at "/diff".
 * accepts: the diff json representing the difference between the client's
 * current version and the latest server version
 * effects: updates [cur_version] to [cur_version + 1],
 * and creates a new file in the server to store this new diff
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
