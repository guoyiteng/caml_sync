open Core

type config = {
  client_name: string;
  url: string;
  token: string;
  version: int;
}

(* [get_latest_version config] makes a query to the server and returns
 * the server's current version number *)
val get_latest_version : config -> int

(* [post_local_diff config version_diff] *)
val post_local_diff : config -> version_diff -> int

(* [get_update_diff config] *)
val get_update_diff : config -> version_diff

(* [check_modified_files _] *)
val check_modified_files : unit -> string list

(* [check_both_modified_files modified_files version_diff] *)
val check_both_modified_files : string list -> version_diff -> string list

(* [rename_both_modified both_modified] *)
val rename_both_modified : string list -> unit

(* [compare_file filename] *)
val compare_file : string -> file_diff

(* [compare_working_backup both_modified] *)
val compare_working_backup : string_list -> version_diff

(* [backup_working_files _] *)
val backup_working_files : unit -> unit

(* [init url token] creates a hidden ".config" file and stores [url] and [token]
 * in ".config". It also creates a folder ".caml_sync/" in the current directory.
 * Users can change this [url] and [token] manually in ".config". *)
val init : string -> string -> unit

(* [load_config _] *)
val load_config : unit -> config

(* usage:
 *  caml_sync init <url> <token> ->
 *    inits the current directory as a client directory
 *  caml_sync ->
 *    syncs files in local directories with files in server
 *)
val main : unit -> unit
