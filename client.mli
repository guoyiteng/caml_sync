open Core

(* [version] represents a version number of a server/client *)
type version = int

(* [get_latest_version _] makes a querry to the server and returns
 * the server's current version number *)
val get_latest_version : unit -> version

(* [init _] creates a hidden [.config] file and prompts to ask user
 * for the url of the server *)
val init : unit -> unit

(* usage:
 *  csync init ->
 *    inits the current directory as a client directory
 *  csync sync ->
 *    syncs files in local directories with files in server
 *)
val main : unit -> unit
