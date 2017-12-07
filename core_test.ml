open OUnit2
open Core

let old_1 = ["1"; "2"]
let new_1 = ["3"; "4"]
let diff_1 = Diff_Impl.calc_diff old_1 new_1
let old_2 = ["a";"b";"c";"a";"b";"b";"a"]
let new_2 = ["c";"b";"a";"b";"a";"c"]
let diff_2 = Diff_Impl.calc_diff old_2 new_2
let file_content_1 = read_file "resources/helloworld.json"
let file_content_2 = read_file "resources/sample.json"
let diff_file_1 = Diff_Impl.calc_diff file_content_1 file_content_2
let diff_file_2 = Diff_Impl.calc_diff file_content_2 file_content_1

let hello_world_diff = {
  prev_version = 0;
  cur_version = 0;
  edited_files = [
    {
      file_name = "1.txt";
      is_deleted = false;
      content_diff = (Diff_Impl.calc_diff [] ["hello"; "world"]);
    }
  ];
}

let update_diff_tests = [
  "test_1" >:: (fun _ -> assert_equal new_1 (Diff_Impl.apply_diff old_1 diff_1));
  "test_2" >:: (fun _ -> assert_equal new_2 (Diff_Impl.apply_diff old_2 diff_2));
  "test_file_1" >:: (fun _ -> assert_equal file_content_2
                        (Diff_Impl.apply_diff file_content_1 diff_file_1));
  "test_file_1" >:: (fun _ -> assert_equal file_content_1
                        (Diff_Impl.apply_diff file_content_2 diff_file_2));
  "test_parse_json" >:: (fun _ ->
      assert_equal hello_world_diff
        (open_in "resources/helloworld.json" |> Ezjsonm.from_channel
         |> parse_version_diff_json)
  )
]

let tests =
  "test suite for core"  >::: List.flatten [
    update_diff_tests;
  ]

let _ = run_test_tt_main tests
