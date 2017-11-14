install:
	opam install cohttp lwt js_of_ocaml cohttp-lwt-unix
	opam update
	opam upgrade
	opam install cohttp-lwt-unix
