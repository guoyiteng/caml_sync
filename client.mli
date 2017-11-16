open Core

type config = {
  client_id: string;
  url: string;
  token: string;
  version: int;
}

(* [get_latest_version config] makes a query to the server and returns
 * the server's current version number *)
val get_latest_version : config -> int

(* [get_update_diff config] retrieves the current version of the working directory from [config],
 * sends a post request to the server to retrieve the difference between the local version
 * and the server's latest version, and returns the difference *)
val get_update_diff : config -> version_diff

(* [post_local_diff config version_diff] sends the difference between the local version 
 * and the server version to the server via json
*)
val post_local_diff : config -> version_diff -> int

(* [check_modified_files _] returns the list of files that have been modified after last 
 * sync with the server 
*)
val check_modified_files : unit -> string list

(* [check_both_modified_files modified_files version_diff] returns a list of filenames that
 * indicates files that are inconsistent in the following three versions: the local working version,
 * the remote server version, and the backup version in the hidden folder *)
val check_both_modified_files : string list -> version_diff -> string list

(* [rename_both_modified both_modified] renames local files in [both_modified] 
 * by appending "_local" to their filenames, because those files have merge conflicts *)
val rename_both_modified : string list -> unit

(* [compare_file filename] returns the all the updates that the user has made since the 
 * latest sync
*)
val compare_file : string -> file_diff

(* [compare_working_backup both_modified] compares all the files in current 
 * working directory to the backup version. The backup version is the latest
 * sync with the server. 
*)
val compare_working_backup : string_list -> version_diff

(* [backup_working_files _] makes a copy for all the files in current working 
* directory.
*)
val backup_working_files : unit -> unit

(* [init url token] creates a hidden ".config" file and stores [url] and [token]
 * in ".config". It also creates a folder ".caml_sync/" in the current directory.
 * Users can change this [url] and [token] manually in ".config". *)
val init : string -> string -> unit

(* [load_config] loads the configuration of client if there is already a 
 * configuration created for the server.
*)
val load_config : unit -> config

(* usage:
 *  caml_sync init <url> <token> ->
 *    inits the current directory as a client directory
 *  caml_sync ->
 *    syncs files in local directories with files in server
 *)
val main : unit -> unit
