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

exception File_existed
exception File_not_found

let calc_diff base_content new_content =
  let base_delete =
    let rec add_delete from_index acc =
      if from_index = 0 then acc
      else add_delete (from_index - 1) ((Delete from_index)::acc)
    in add_delete (List.length base_content) [] in
  (Insert (0, new_content))::base_delete

let update_diff base_content diff_content =
  let rec match_command cur_index diff_lst acc =
    match diff_lst with
    | [] ->
      if cur_index > List.length base_content then acc
      else let cur_elem = List.nth base_content (cur_index-1) in
        match_command (cur_index+1) diff_lst (cur_elem::acc)
    | h::t ->
      begin match h with
        | Delete ind ->
          if cur_index = ind then
            match_command (cur_index+1) t acc
          else if cur_index < ind then
            let cur_elem = List.nth base_content (cur_index-1) in
            match_command (cur_index+1) diff_lst (cur_elem::acc)
          else failwith "should not happen in update_diff"
        | Insert (ind, str_lst) ->
          if ind = 0 then
            match_command cur_index t (List.rev str_lst)
          else if cur_index < ind then
            let cur_elem = List.nth base_content (cur_index-1) in
            match_command (cur_index+1) diff_lst (cur_elem::acc)
          else if cur_index = ind then
            let cur_elem = List.nth base_content (cur_index-1) in
            let new_lst = List.rev (cur_elem::str_lst) in
            match_command (cur_index+1) t (new_lst @ acc)
          else failwith "should not happen in update_diff"
      end
  in List.rev (match_command 1 diff_content [])

let parse_json diff_json = failwith "todo"

let build_json diff_obj = failwith "todo"

let write_json w_json filename = failwith "todo"

let create_file filename content = failwith "todo"

let delete_file filename = failwith "todo"
