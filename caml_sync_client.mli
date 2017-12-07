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

(* [get_update_diff config]
 * retrieves the current version of the working directory from [config],
 * sends a post request to the server to retrieve the difference between
 * the local version and the server's latest version, and returns the difference
*)
val get_update_diff : config -> (string * bool) list * file_diff list

(* [post_local_diff config version_diff] sends the difference between the local version
 * and the server version to the server via json
*)
val post_local_diff : config -> version_diff -> int

(* [compare_file filename] returns all the updates that the user has made
 * on the file represented by [filename] since the latest sync *)
val compare_file : string -> file_diff

(* [check_invalid_filename ()] returns true if the local directory contains
 * any file whose filename (excluding file extension) ends with "_local" *)
val check_invalid_filename : unit -> string list

(* [compare_working_backup () ] returns a list of file_diff's that
 * have been modified after the last sync with the server.
 * The previous local version is stored in the hidden directory ".caml_sync/".
*)
val compare_working_backup : unit -> file_diff list

(* [check_both_modified_files modified_file_diffs version_diff]
 * returns a list of [(filename, is_deleted)] that indicates files that are
 * inconsistent in the following three versions: the local working version,
 * the remote server version, and the backup version in the hidden folder. If
 * [is_deleted] is true, it means that that file is deleted in the local working
 * version compared with the backup version. *)
val check_both_modified_files :
  file_diff list -> version_diff -> (string * bool) list

(* [rename_both_modified both_modified_list] delete or renames local files in
 * [both_modified_list] by appending "_local" to their filenames,
 * because those files have merge conflicts. [both_modified_list] is a list of
 * [(filename, is_deleted)]. The [is_deleted] indicates whether we should delete
 * or rename the file. If [is_deleted] is true, we should delete the file. *)
val rename_both_modified : (string * bool) list -> unit

(* [generate_client_version_diff server_diff] returns [(both_modified_lst, local_diff_files)].
 * returns: [None] if the current client has not made any update since the last sync,
 * otherwise returns [Some client_diff] where [client_diff] is the new update
 * that the current client has made
*)
val generate_client_version_diff : version_diff -> (string * bool) list * file_diff list

(* [backup_working_files ()] copies all the files in current working
 * directory to ".caml_sync/", except those files in that contain "_local" at the
 * end of their filename
 *)
val backup_working_files : unit -> unit

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
