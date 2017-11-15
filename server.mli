open Core
open Opium.Std

type version = int

val cur_version: int

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

