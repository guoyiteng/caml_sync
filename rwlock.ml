(* Reference: 
 * http://www.cs.cornell.edu/courses/cs3110/2011fa/recitations/rec16.html *)

(* (reader_count, writer_here, mutex, reader_can_enter, writer_can_enter) *)
type t = int ref * bool ref * Mutex.t * Condition.t * Condition.t

let create () =
  (ref 0, ref false, Mutex.create (), Condition.create (), Condition.create ())

let read_lock (num_readers, writer_here, mutex, reader_can_enter, _) =
  Mutex.lock mutex;
  while !writer_here; do
    Condition.wait reader_can_enter mutex;
  done;
  num_readers := !num_readers + 1;
  Mutex.unlock mutex

let read_unlock (num_readers, _, mutex, _, writer_can_enter) =
  Mutex.lock mutex;
  num_readers := !num_readers - 1;
  if !num_readers = 0 then Condition.signal writer_can_enter;
  Mutex.unlock mutex

let write_lock (num_readers, writer_here, mutex, _, writer_can_enter) =
  Mutex.lock mutex;
  while !num_readers > 0 || !writer_here; do
    Condition.wait writer_can_enter mutex;
  done;
  writer_here := true;
  Mutex.unlock mutex

let write_unlock (_, writer_here, mutex, reader_can_enter, writer_can_enter) =
  Mutex.lock mutex;
  writer_here := false;
  Condition.signal writer_can_enter;
  Condition.broadcast reader_can_enter;
  Mutex.unlock mutex;