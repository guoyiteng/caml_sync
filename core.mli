module type Diff = sig
  (* [Delete i] indicates that the [i]'th line in the original file needs
   * to be deleted;
   * [Insert (i, content)] indicates that [content] needs to be added
   * right after the [i]'th line of the original file *)
  type op = Delete of int | Insert of (int * string list)
  (* represents the difference between contents*)
  type t
  (* [empty] represents no difference between contents*)
  val empty : t
  (* [calc_diff base_content new_content] returns the difference between
   * [base_content] and [new_content] *)
  val calc_diff : string list -> string list -> t
  (* [apply_diff base_content diff_content] returns the result
   * after applying the changes in [diff_content] to [base_content] *)
  val apply_diff : string list -> t -> string list

  (* [build_diff_json diff_obj] returns the diff json representing
   * the ocaml diff object [diff_obj] *)
  val build_diff_json : t -> Ezjsonm.value

  (* [parse_diff_json diff_json] returns an ocaml diff object
   * represented by [diff_json] *)
  val parse_diff_json : Ezjsonm.value -> t
end

module Diff_Impl : Diff

(* [diff] represents an ocaml diff object between contents *)
type diff = Diff_Impl.t

type file_diff = {
  file_name: string;
  is_deleted: bool;
  content_diff: diff;
}

type version_diff = {
  prev_version: int;
  cur_version: int;
  edited_files: file_diff list
}

exception File_existed of string
exception File_not_found of string

(* [extract_string json key] gets the key-value pair in [json] keyed on [key],
  * and returns the corresponding string value *)
val extract_string: Ezjsonm.value -> string -> string

(* [extract_int json key] gets the key-value pair in [json] keyed on [key],
  * and returns the corresponding int value *)
val extract_int: Ezjsonm.value -> string -> int

(* [build_version_diff_json v_diff] returns a json representing
 * the ocaml version_diff object [version_diff] *)
val build_version_diff_json : version_diff -> Ezjsonm.t

(* [parse_version_diff_json v_json] returns an ocaml version_diff object
 * represented by [v_json] *)
val parse_version_diff_json : Ezjsonm.t -> version_diff

(* [read_json filename] reads the file specified by [filename] and returns
 * the information as a json *)
val read_json: string -> [> Ezjsonm.t]

(* [write_json filename w_json] writes the json to an output file
 * specified by [filename].
 * Makes directories when necessary if [filename] indicates a file \
 * to be written in a subdirectory *)
val write_json : string -> Ezjsonm.t -> unit

(* [read_file filename] returns a list of strings representing the contentn
 * of the file represented by [filename] *)
val read_file : string -> string list

(* [write_file filename content] creates a new file named [filename].
 * [filename] may include any sub-directory.
 * [content] is a list of strings representing the content
 * to be written to the new file.
 * Makes directories when necessary if [filename] indicates a file
 * to be written in a subdirectory
 * raises: [File_existed "Cannot create file."] if there already exists
 * a file with the same name as [filename] *)
val write_file : string -> string list -> unit

(* [delete_file filename] deletes a file named [filename]. Also recursively
 * deletes any subdirectory if, after deleting the file [filename],
 * the directory originally containing [filename] becomes empty
 * raises: [File_not_found "Cannot remove file."] if [filename] cannot be found *)
val delete_file : string -> unit

(* [search_dir dir_handle f_add acc_file acc_dir dir_name valid_exts]
 * recursively searches for all the files in the directory
 * represented by [dir_handle] or its subdirectories,
 * and returns a set of all such files of approved suffixes in [valid_exts].
 * [f_add] is a function to add new file to the existing data structure [acc_file].
 * requires: [dir_handle] is a valid directory handle returned by Unix.opendir. *)
val search_dir : Unix.dir_handle -> (string -> 'a -> 'a) -> 'a -> string list -> string -> string list -> 'a
