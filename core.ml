type op = Delete of int | Insert of (int * string list)

type diff = op list

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

let apply_diff base_content diff_content =
  (* go over every element in base_content, and compare the line number with
   * information in diff_content, in order to see whether the current line
   * should be kept, deleted, or followed by some new lines. *)
  let rec match_op cur_index diff_lst acc =
    (* new content willl be saved in acc, in reverse order*)
    match diff_lst with
    | [] ->
      if cur_index > List.length base_content then acc
      else let cur_elem = List.nth base_content (cur_index-1) in
        match_op (cur_index+1) diff_lst (cur_elem::acc)
    | h::t ->
      begin match h with
        | Delete ind ->
          if cur_index = ind then
            (* move on to the next line. Do not add anything to acc *)
            match_op (cur_index+1) t acc
          else if cur_index < ind then
            (* copy current line from base_content to acc *)
            let cur_elem = List.nth base_content (cur_index-1) in
            match_op (cur_index+1) diff_lst (cur_elem::acc)
          else failwith "should not happen in update_diff"
        | Insert (ind, str_lst) ->
          if ind = 0 then
            match_op cur_index t (List.rev str_lst)
          else if cur_index < ind then
            (* copy current line from base_content to acc *)
            let cur_elem = List.nth base_content (cur_index-1) in
            match_op (cur_index+1) diff_lst (cur_elem::acc)
          else if cur_index = ind then
            (* insert lines after current line *)
            let cur_elem = List.nth base_content (cur_index-1) in
            let new_lst = List.rev (cur_elem::str_lst) in
            match_op (cur_index+1) t (new_lst @ acc)
          else failwith "should not happen in update_diff"
      end
  in List.rev (match_op 1 diff_content [])

let parse_json diff_json =
  let open Ezjsonm in
  get_list
    (fun elem ->
      let extract_string key = Ezjsonm.(get_string (find elem [key])) in
      let extract_int key = Ezjsonm.(get_int (find elem [key])) in
      let extract_strlst key = Ezjsonm.(get_strings (find elem [key])) in
      let op = extract_string "op" in
      let line_index = extract_int "line" in
      let content = extract_strlist "content" in
      if op = "del" then Delete line_index
      else if op = "ins" then Insert (line_index, content)
      else failwith "Error when parsing json"
    ) diff_json

let build_json diff_obj =
  let open Ezjsonm in
  let to_json_strlist str_lst =
    list (fun str -> string str) str_lst in
  (* list of dicts *)
  list (fun op ->
      match op with
      | Delete index ->
        dict [("op", string "del");
              ("line", int index);
              ("content", to_json_strlist [""])]
      | Insert (index, str_lst) ->
        dict [("op", string "ins");
         ("line", int index);
         ("content", to_json_strlist str_lst)]
    ) diff_obj

let write_json w_json filename = failwith "todo"

(* create a directory given by information in [filename],
 * given that it currently does not exist *)
let create_dir filename =
  let lst_split = String.split_on_char '/' filename in
  let rec inc_dir_create lst acc =
    (* incrementally create directories *)
    match lst with
      | [] | _::[]-> ()
      | h::t ->
        let new_acc = acc ^ h ^ Filename.dir_sep in
          try ignore (Sys.is_directory new_acc); inc_dir_create t new_acc with
          | Sys_error _ -> Unix.mkdir new_acc 0o770; inc_dir_create t new_acc in
  inc_dir_create lst_split ""

let create_file filename content =
  if Sys.file_exists filename
  then raise (File_existed "Error when creating file")
  else
    (* create directory if necessary. *)
    let _ = create_dir filename in
    let rec print_content channel = function
      | [] -> ()
      | h::t -> Printf.fprintf channel "%s\n" h; print_content channel t
    in let oc = open_out filename in
    print_content oc content; close_out oc

let delete_file filename =
  try Sys.remove filename
  with Sys_error _ -> raise (File_not_found "Cannot remove file")
