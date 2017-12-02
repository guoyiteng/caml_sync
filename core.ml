type command = Delete of int | Insert of (int * string list)

type diff = command list

let calc_diff base_content new_content =
  let base_delete =
    let rec add_delete from_index acc =
      if from_index = 0 then acc
      else add_delete (from_index - 1) ((Delete from_index)::acc)
    in add_delete (List.length base_content) [] in
  base_delete @ [Insert (0, new_content)]

let update_diff base_content diff_content = failwith "todo"

let parse_json diff_json = failwith "todo"

let build_json diff_obj = failwith "todo"

let write_json w_json filename = failwith "todo"

let create_file filename content = failwith "todo"

let delete_file filename = failwith "todo"
