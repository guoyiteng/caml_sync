open OUnit2
open Caml_sync_client

let config = {
  client_id="1";
  url="127.0.0.1:8080";
  token="sb";
  version=0
}

let () = update_config config

let config_tests = [
  "basic_write_read_consistency" >::(fun _ -> assert_equal
                                        config (update_config config; load_config ()));
  "basic_update">:: (fun _ -> assert_equal
                        (update_config {config with version=1}; load_config ())
                        {config with version=1});
]

let tests =
  "test suite for client"  >::: List.flatten [
    config_tests;
  ]

let _ = run_test_tt_main tests
