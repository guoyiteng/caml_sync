open OUnit2
open Caml_sync_client

let config : Caml_sync_client.config = {
  client_id="1";
  url="127.0.0.1:8080";
  token="sb";
  version=0
}

let config_tests = [
  "basic_write_read_consistency" >::(fun _ -> assert_equal
                                        config (update_config config;
                                                load_config ()));
  "basic_update">:: (fun _ -> assert_equal
                        (update_config {config with version=1};
                         Caml_sync_client.load_config ())
                        {config with version=1});
]

let request_tests = [
  "test_init" >:: (fun _ -> ());
  "test_sync" >:: (fun _ -> ());
  "test_get_update_diff" >:: (fun _ -> ());
  "test_post_local_diff" >:: (fun _ -> ());
  "test_history_list" >:: (fun _ -> ());
  "test_time_travel" >:: (fun _ -> ());

]

let tests =
  "test suite for client"  >::: List.flatten [
    config_tests;
    request_tests
  ]

let _ = run_test_tt_main tests
