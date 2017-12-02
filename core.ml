type command = Delete of int | Insert of (int * string list)

type diff = command list

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

let calc_diff base_content new_content =
  let base_delete =
    (* create a list of Delete's *)
    let rec add_delete from_index acc =
      if from_index = 0 then acc
      else add_delete (from_index - 1) ((Delete from_index)::acc)
    in add_delete (List.length base_content) [] in
  (Insert (0, new_content))::base_delete

let update_diff base_content diff_content =
  (* go over every element in base_content, and compare the line number with
   * information in diff_content, in order to see whether the current line
   * should be kept, deleted, or followed by some new lines. *)
  let rec match_command cur_index diff_lst acc =
    (* new content willl be saved in acc, in reverse order*)
    match diff_lst with
    | [] ->
      if cur_index > List.length base_content then acc
      else let cur_elem = List.nth base_content (cur_index-1) in
        match_command (cur_index+1) diff_lst (cur_elem::acc)
    | h::t ->
      begin match h with
        | Delete ind ->
          if cur_index = ind then
            (* move on to the next line. Do not add anything to acc *)
            match_command (cur_index+1) t acc
          else if cur_index < ind then
            (* copy current line from base_content to acc *)
            let cur_elem = List.nth base_content (cur_index-1) in
            match_command (cur_index+1) diff_lst (cur_elem::acc)
          else failwith "should not happen in update_diff"
        | Insert (ind, str_lst) ->
          if ind = 0 then
            match_command cur_index t (List.rev str_lst)
          else if cur_index < ind then
            (* copy current line from base_content to acc *)
            let cur_elem = List.nth base_content (cur_index-1) in
            match_command (cur_index+1) diff_lst (cur_elem::acc)
          else if cur_index = ind then
            (* insert lines after current line *)
            let cur_elem = List.nth base_content (cur_index-1) in
            let new_lst = List.rev (cur_elem::str_lst) in
            match_command (cur_index+1) t (new_lst @ acc)
          else failwith "should not happen in update_diff"
      end
  in List.rev (match_command 1 diff_content [])

let parse_json diff_json = failwith "todo"

let build_json diff_obj = failwith "todo"

let write_json w_json filename = failwith "todo"

(* create a directory named [file_dir] if it currently does not exist *)
let create_dir file_dir =
  try ignore (Sys.is_directory file_dir);() with
  | Sys_error _ -> Unix.mkdir file_dir 0o666

let create_file filename content =
  if Sys.file_exists filename
  then raise (File_existed "Error when creating file")
  else
    (* check if directory create directory if necessary. *)
    let lst_split = String.split_on_char '/' filename in
    let rec merge_seps lst acc =
      match lst with
      | [] | _::[]-> acc
      | h::t -> merge_seps t (acc ^ h ^ Filename.dir_sep) in
    let file_dir = merge_seps lst_split "" in
    let _ = create_dir file_dir in
    let rec print_content channel = function
      | [] -> ()
      | h::t -> Printf.fprintf channel "%s\n" h; print_content channel t
    in let oc = open_out filename in
    print_content oc content; close_out oc

let delete_file filename =
  try Sys.remove filename
  with Sys_error _ -> raise (File_not_found "Cannot remove file")
