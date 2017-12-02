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
  failwith "todo"

let parse_json diff_json = failwith "todo"

let build_json diff_obj = failwith "todo"

let write_json w_json filename = failwith "todo"

let create_file filename content = failwith "todo"

let delete_file filename = failwith "todo"
