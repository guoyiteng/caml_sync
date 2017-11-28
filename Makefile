server_template:
	ocamlbuild -use-ocamlfind server_template.native && ./server_template.native
server:
	ocamlbuild -use-ocamlfind server.native
	rm server/server.native
	mv server.native server/server.native
client:
	ocamlbuild -use-ocamlfind client.byte
	rm client/client.byte
	mv client.native client/client.byte
check:
	bash checktypes.sh
debug:
	ocamlbuild -use-ocamlfind -tag 'debug' debug.byte
cleanup:
	ocamlbuild -clean
install:
	opam install opium
