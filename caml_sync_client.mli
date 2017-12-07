open Core

(* camlsync client config type represeting a client config file. *)
type config = {
  client_id: string;
  url: string;
  token: string;
  version: int;
}

exception Timeout
exception Unauthorized
exception Bad_request of string
exception ServerError of string
exception Not_Initialized

(* [load_config () ] loads the config file of client *)
val load_config : unit -> config

(* [update_config config] updates the [.config] file with [config] *)
val update_config : config -> unit

(* [post_local_diff config version_diff] sends the difference between the local
 * version and the server version to the server via json
*)
val post_local_diff : config -> version_diff -> int

(* [get_update_diff config]
 * retrieves the current version of the working directory from [config],
 * sends a post request to the server to retrieve the difference between
 * the local version and the server's latest version, and returns the difference
*)
val get_update_diff : config -> (string * bool) list * file_diff list

(* [history_list config] queries the server configured at [config] for a list
 * for version and time of all historical versions of the directory
*)
val history_list : config -> history_log

(* [time_travel config n] queries the server configured at [config] for the
 * difference between the current directory from version [n] and applies
 * the diff the restore the file structure at version [n]
*)
val time_travel : config -> int -> unit

(* [init url token] creates a hidden ".config" file and stores [url] and [token]
 * in ".config". It also creates a folder ".caml_sync/" in the current directory.
 * Users can change this [url] and [token] manually in ".config". *)
val init : string -> string -> unit

(* Performs all the sync work *)
val sync : unit -> unit

(* Top level of client
*)
val main : unit -> unit
