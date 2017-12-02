open OUnit2
open Core

let old_1 = ["1"; "2"]
let new_1 = ["3"; "4"]
let diff_1 = calc_diff old_1 new_1
let old_2 = ["a";"b";"c";"a";"b";"b";"a"]
let new_2 = ["c";"b";"a";"b";"a";"c"]
let diff_2 = calc_diff old_2 new_2

let update_diff_tests = [
  "test_1" >:: (fun _ -> assert_equal new_1 (update_diff old_1 diff_1));
  "test_2" >:: (fun _ -> assert_equal new_2 (update_diff old_2 diff_2));
]

let tests =
  "test suite for core"  >::: List.flatten [
    update_diff_tests;
  ]

let _ = run_test_tt_main tests
