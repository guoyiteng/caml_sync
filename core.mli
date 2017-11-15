(* [diff] represents an ocaml diff object between contents*)
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

exception File_existed
exception File_not_found

(* [calc_diff base_content new_content] is the diff result between
 * [base_content] and the [new_content] *)
val calc_diff : string list -> string list -> diff

(* [update_diff base_content diff_content] is the result that we apply
 * [diff_content] to the [base_czontent]  *)
val update_diff : string list -> diff -> string list

(* [parse_json diff_json] returns an ocaml diff object
 * represented by the diff json *)
val parse_json : [> Ezjsonm.t ] -> diff

(* [build_json diff_obj] returns the diff json of the ocaml diff object*)
val build_json : diff -> [> Ezjsonm.t ]

(* [write_json json filename] writes the json to output file. *)
val write_json : [> Ezjsonm.t ] -> string -> unit

(* [create_file filename content] creates a new file named [filename]. [filename]
 * should include any directory if wanted. [content] is a list of lines
 * representing the content.
 * raise: [File_existed] if there has already existed a file at [filename]. *)
val create_file : string -> string list -> unit

(* [delete_file filename] deletes a file named [file].
 * raise: [File_not_found] *)
val delete_file : string -> unit