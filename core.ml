type command = Delete of string | Insert of string list

type diff = command list

let calc_diff base_content new_content =
  List.fold_right
    (fun elem acc -> (Delete elem)::acc) base_content [Insert new_content]

let update_diff base_content diff_content = failwith "todo"

let parse_json diff_json = failwith "todo"

let build_json diff_obj = failwith "todo"

let write_json w_json filename = failwith "todo"

let create_file filename content = failwith "todo"

let delete_file filename = failwith "todo"
