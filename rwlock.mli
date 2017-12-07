(* Reference:  
 * http://www.cs.cornell.edu/courses/cs3110/2011fa/recitations/rec16.html *)

type t
val create: unit -> t
val read_lock: t -> unit
val read_unlock: t -> unit
val write_lock: t -> unit
val write_unlock: t -> unit