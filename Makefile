server_template:
	ocamlbuild -use-ocamlfind server_template.native && ./server_template.native
install:
	opam install opium
