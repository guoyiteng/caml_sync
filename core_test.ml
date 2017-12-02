open OUnit2
open Core

let old_1 = ["1"; "2"]
let new_1 = ["3"; "4"]
let diff_1 = calc_diff old_1 new_1

let update_diff_tests = [
  "test_1" >:: (fun _ -> assert_equal new_1 (update_diff old_1 diff_1));
]

let tests =
  "test suite for core"  >::: List.flatten [
    update_diff_tests;
  ]

let _ = run_test_tt_main tests
