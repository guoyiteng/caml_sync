module type Diff_Core = sig
  type op = Delete of int | Insert of (int * string list)
  type t = op list
  val empty : t
  val calc_diff : string list -> string list -> t
end

module type Diff = sig
  type op = Delete of int | Insert of (int * string list)
  type t
  val empty : t
  val calc_diff : string list -> string list -> t
  val apply_diff : string list -> t -> string list
  val build_diff_json : t -> Ezjsonm.value
  val parse_diff_json : Ezjsonm.value -> t
end

module Naive_Diff : Diff_Core = struct
  type op = Delete of int | Insert of (int * string list)
  type t = op list
  let empty = []
  let calc_diff base_content new_content =
    let base_delete =
      (* create a list of Delete's corresponding to all lines in [base_content] *)
      let rec add_delete from_index acc =
        if from_index = 0 then acc
        else add_delete (from_index - 1) ((Delete from_index)::acc)
      in add_delete (List.length base_content) [] in
    (Insert (0, new_content))::base_delete
end

module DP_Diff : Diff_Core = struct
  type op = Delete of int | Insert of (int * string list)
  type t = op list
  let empty = []

  let calc_diff base_content new_content =
    (* better implementation based on dynamic programming *)
    let open Array in
    let arr_base = of_list base_content in
    let arr_new = of_list new_content in
    let mat = make_matrix (length arr_new + 1) (length arr_base + 1) 0 in
    (* initialize first row*)
    iteri (fun i ele -> mat.(0).(i) <- i) mat.(0);
    iteri (fun i ele -> mat.(i).(0) <- i) mat;
    for r = 1 to length arr_new do
      for c = 1 to length arr_base do
        let from_left = 1 + mat.(r).(c-1) in
        let from_top = 1 + mat.(r-1).(c) in
        let from_diagonal =
          if arr_new.(r-1) = arr_base.(c-1)
          then mat.(r-1).(c-1)
          else max_int in
        let min_dist = from_left |> min from_top |> min from_diagonal in
        mat.(r).(c) <- min_dist
      done
    done;
    let rec backtrack r c acc =
      if r = 0 then
        let rec prepend_delete counter acc' =
          if counter = 0 then acc'
          else prepend_delete (counter - 1) ((Delete counter) :: acc') in
        prepend_delete c acc
      else if c = 0 then
        let content = sub arr_new 0 r |> to_list in
        (Insert (0, content)) :: acc
      else
        let cur = mat.(r).(c) in
        let from_left = mat.(r).(c-1) + 1 in
        let from_top = mat.(r-1).(c) + 1 in
        let from_diagonal = mat.(r-1).(c-1) in
        if from_diagonal = cur && arr_new.(r-1) = arr_base.(c-1)
        then backtrack (r-1) (c-1) acc
        else if from_left = cur
        then backtrack r (c-1) ((Delete c)::acc)
        else if from_top = cur
        then match acc with
          | (Insert (line, content_lst)) :: t when c = line ->
            let cur_content = arr_new.(r-1) in
            backtrack (r-1) c ((Insert (c, cur_content :: content_lst)) :: t)
          | _ -> backtrack (r-1) c ((Insert (c, [arr_new.(r-1)])) :: acc)
        else failwith "impossible"
    in
    backtrack (length arr_new) (length arr_base) []

end

let extract_string json key = Ezjsonm.(get_string (find json [key]))

let extract_int json key = Ezjsonm.(get_int (find json [key]))

(* [extract_bool json key] gets the key-value pair in [json] keyed on [key],
  * and returns the corresponding bool value *)
let extract_bool json key = Ezjsonm.(get_bool (find json [key]))

(* [extract_float json key] gets the key-value pair in [json] keyed on [key],
  * and returns the corresponding float value *)
let extract_float json key = Ezjsonm.(get_float (find json [key]))

(* [extract_strlist json key] gets the key-value pair in [json] keyed on [key],
  * and returns the corresponding string list value *)
let extract_strlist json key = Ezjsonm.(get_strings (find json [key]))

module Make_Diff ( Diff_Impl : Diff_Core) : Diff = struct
  include Diff_Impl

  let apply_diff base_content diff_content =
    (* go over every element in base_content, and compare the line number with
     * information in diff_content, in order to see whether the current line
     * should be kept, deleted, or followed by some new lines. *)
    let rec match_op cur_index diff_lst acc =
      (* new content willl be saved in acc, in reverse order *)
      match diff_lst with
      | [] ->
        if cur_index > List.length base_content then acc
        else let cur_line = List.nth base_content (cur_index-1) in
          match_op (cur_index+1) diff_lst (cur_line::acc)
      | h::t ->
        begin match h with
          | Delete ind ->
            if cur_index = ind then
              (* current line is deleted.
               * move on to the next line. Do not add anything to acc *)
              match_op (cur_index+1) t acc
            else if cur_index < ind then
              (* copy current line from base_content to acc *)
              let cur_line = List.nth base_content (cur_index-1) in
              match_op (cur_index+1) diff_lst (cur_line::acc)
            else failwith "should not happen in update_diff"
          | Insert (ind, str_lst) ->
            if ind = 0 then
              match_op cur_index t (List.rev str_lst)
            else if cur_index < ind then
              (* copy current line from base_content to acc *)
              let cur_line = List.nth base_content (cur_index-1) in
              match_op (cur_index+1) diff_lst (cur_line::acc)
            else if cur_index = ind then
              (* insert lines after current line *)
              let cur_line = List.nth base_content (cur_index-1) in
              let new_lst = List.rev (cur_line::str_lst) in
              match_op (cur_index+1) t (new_lst @ acc)
            else failwith "should not happen in update_diff"
        end
    in List.rev (match_op 1 diff_content [])

  let build_diff_json diff_obj =
    let open Ezjsonm in
    let to_json_strlist str_lst =
      list (fun str -> string str) str_lst in
    (* list of dicts *)
    let open Diff_Impl in
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

  let parse_diff_json diff_json =
    let open Ezjsonm in
    get_list
      (fun elem ->
         let op = extract_string elem "op" in
         let line_index = extract_int elem "line" in
         let content = extract_strlist elem "content" in
         let open Diff_Impl in
         if op = "del" then Delete line_index
         else if op = "ins" then Insert (line_index, content)
         else failwith "Error when parsing json"
      ) diff_json
end

module Diff_Impl = Make_Diff (DP_Diff)

type op = Diff_Impl.op
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

let build_version_diff_json v_diff =
  let open Ezjsonm in
  dict [
    "prev_version", (int v_diff.prev_version);
    "cur_version", (int v_diff.cur_version);
    "edited_files", list (
      fun f_diff -> dict [
          "file_name", (string f_diff.file_name);
          "is_deleted", (bool f_diff.is_deleted);
          "content_diff", (Diff_Impl.build_diff_json f_diff.content_diff);
        ]
    ) v_diff.edited_files;
  ]

(* [parse_file_diff_json f_json] returns an ocaml file_diff object
 * represented by [f_json] *)
let parse_file_diff_json f_json =
  let open Ezjsonm in
  {
    file_name = extract_string f_json "file_name";
    is_deleted = extract_bool f_json "is_deleted";
    content_diff = Diff_Impl.parse_diff_json (find f_json ["content_diff"])
  }

let parse_version_diff_json v_json =
  let open Ezjsonm in
  let v_json' = value v_json in
  {
    prev_version = extract_int v_json' "prev_version";
    cur_version = extract_int v_json' "cur_version";
    edited_files =
      get_list parse_file_diff_json (find v_json' ["edited_files"])
  }

(* create a directory given by information in [filename],
 * if it currently does not exist *)
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

let read_json filename =
  if not (Sys.file_exists filename)
  then raise (File_not_found (filename ^ ": File to read does not exist."))
  else let in_c = open_in filename in
    let json = Ezjsonm.from_channel in_c in
    close_in in_c; json

let write_json filename w_json =
  create_dir filename;
  let out_c = open_out filename in
  w_json |> Ezjsonm.to_channel out_c;
  close_out out_c

let read_file filename =
  if not (Sys.file_exists filename)
  then raise (File_not_found (filename ^ ": File to read does not exist."))
  else
    let read_line channel =
      try Some (input_line channel) with End_of_file -> None in
    let rec lines_from_files in_c acc =
      match (read_line in_c) with
      | None -> List.rev acc
      | Some s -> lines_from_files in_c (s :: acc) in
    let c = open_in filename in
    let return_content = lines_from_files c [] in
    close_in c;
    return_content

let write_file filename content =
  if Sys.file_exists filename
  then raise (File_existed "Cannot create file.")
  else
    (* create directory if necessary. *)
    let _ = create_dir filename in
    let rec print_content channel = function
      | [] -> ()
      | h::t -> Printf.fprintf channel "%s\n" h; print_content channel t
    in let oc = open_out filename in
    print_content oc content;
    close_out oc

let rec recursively_rm_dir rev_lst =
  match rev_lst with
  | [] | _::[] -> ()
  | (h::t) as lst ->
    let cur_dir = List.fold_left
        (fun acc d -> d ^ Filename.dir_sep ^ acc) "" lst in
    try Unix.rmdir cur_dir; recursively_rm_dir t with
      Unix.Unix_error (Unix.ENOTEMPTY, "rmdir", _) -> ()

let delete_file filename =
  (* rev_lst_split contains the separate path fields *)
  let rev_lst_split = String.split_on_char '/' filename |> List.rev |> List.tl in
  try Sys.remove filename; recursively_rm_dir rev_lst_split
  with Sys_error _ -> raise (File_not_found "Cannot remove file.")

let rec search_dir dir_handle add acc_file acc_dir dir_name valid_exts =
  (* similar to BFS *)
  match Unix.readdir dir_handle with
  | exception End_of_file ->
    let () = Unix.closedir dir_handle in
    (* go into subdirectories *)
    List.fold_left
      (fun acc a_dir ->
         let sub_d_handle = Unix.opendir a_dir in
         search_dir sub_d_handle add acc [] a_dir valid_exts
      ) acc_file acc_dir
  | p_name ->
    let path = dir_name ^ Filename.dir_sep ^ p_name in
    if Sys.is_directory path && p_name <> "." && p_name <> ".." then
      (* save information about this subdirectory in acc_dir, to be processed
       * after having seen all files in the current directory *)
      search_dir dir_handle add acc_file (path::acc_dir) dir_name valid_exts
      (* support suffix here in addition to extension. *)
    else if List.exists (fun suff -> Filename.check_suffix p_name suff) valid_exts then
      let new_fileset = add path acc_file in
      search_dir dir_handle add new_fileset acc_dir dir_name valid_exts
    else search_dir dir_handle add acc_file acc_dir dir_name valid_exts

type history = {
  version: int;
  timestamp: float
}

type history_log = {
  log: history list
}

let build_history_json h =
  let open Ezjsonm in
  dict [
    "version", (int h.version);
    "timestamp", (float h.timestamp);
  ]

let parse_history_json h_json =
  {
    version = extract_int h_json "version";
    timestamp = extract_float h_json "timestamp";
  }

let build_history_log_json hl =
  let open Ezjsonm in
  dict [
    "log", list (fun h -> build_history_json h) hl.log;
  ]

let parse_history_log_json hl_json =
  let open Ezjsonm in
  let hl_json' = value hl_json in
  {
    log = get_list parse_history_json (find hl_json' ["log"])
  }
