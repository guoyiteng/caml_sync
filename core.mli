type diff

(* [calc_diff base_content new_content] is the diff result between
 * [base_content] and the [new_content] *)
val calc_diff : string list -> string list -> diff

(* [update_diff base_content diff_content] is the result that we apply
 * [diff_content] to the [base_content]  *)
val update_diff : string list -> diff -> string list
