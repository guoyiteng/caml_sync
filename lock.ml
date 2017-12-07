open Rwlock

let lock = Rwlock.create ()

let reader id =
  while true; do
    Printf.printf "Reader %i trying to read...\n" id;
    Rwlock.read_lock lock;
    Printf.printf "Reader %i is reading!\n" id;
    Thread.delay (Random.float 1.5);
    Rwlock.read_unlock lock;
    Printf.printf "Reader %i exits.\n" id;
    flush stdout; 
    Thread.delay (Random.float 1.5)
  done

let writer id =
  while true; do
    Printf.printf "Writer %i trying to read...\n" id;
    Rwlock.write_lock lock;
    Printf.printf "Writer %i is reading!\n" id;
    Thread.delay (Random.float 1.5);
    Rwlock.write_unlock lock;
    Printf.printf "Writer %i exits.\n" id;
    flush stdout;
    Thread.delay (Random.float 1.5)
  done

let test_reader_writer () =
  for i = 0 to 3 do ignore (Thread.create reader i) done;
  for i = 0 to 2 do ignore (Thread.create writer i) done

let () = test_reader_writer ()