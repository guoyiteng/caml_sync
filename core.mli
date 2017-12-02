(* [diff] represents an ocaml diff object between contents *)
type diff

type file_diff = {
  file_name: string;
  is_directory: bool;
  content_diff: diff;
}

type version_diff = {
  prev_version: int;
  cur_version: int;
  edited_files: file_diff list
}

exception File_existed of string
exception File_not_found of string

(* [calc_diff base_content new_content] returns the difference between
 * [base_content] and [new_content] *)
val calc_diff : string list -> string list -> diff

(* [update_diff base_content diff_content] returns the result after applying the changes in
 * [diff_content] to [base_content] *)
val update_diff : string list -> diff -> string list

(* [parse_json diff_json] returns an ocaml diff object
 * represented by the diff json *)
val parse_json : [> Ezjsonm.t ] -> diff

(* [build_json diff_obj] returns the diff json containing all the information
 * in the ocaml diff object [diff] *)
val build_json : diff -> [> Ezjsonm.t ]

(* [write_json w_json filename] writes the json to an output file specified by [filename] *)
val write_json : [> Ezjsonm.t ] -> string -> unit

(* [create_file filename content] creates a new file named [filename]. [filename]
 * should include any directory if wanted. [content] is a list of lines
 * representing the content to be written to the new file.
 * raises: [File_existed] if there already exists a file with the same name as [filename] *)
val create_file : string -> string list -> unit

(* [delete_file filename] deletes a file named [filename].
 * raises: [File_not_found] if [filename] cannot be found *)
val delete_file : string -> unit
