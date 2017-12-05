.PHONY: server client
server:
	ocamlbuild -use-ocamlfind caml_sync_server.native
	rm -f server/caml_sync_server.native
	mv caml_sync_server.native server/caml_sync_server.native
client:
	ocamlbuild -use-ocamlfind caml_sync_client.native
	rm -f client/caml_sync_client.native
	mv caml_sync_client.native client/caml_sync_client.native
compile: server client
server_template:
	ocamlbuild -use-ocamlfind server_template.native && ./server_template.native
sync:
	ocamlbuild -use-ocamlfind -pkg cohttp-lwt-unix caml_sync_client.native
	rm -f client/caml_sync_client.native
	mv caml_sync_client.native client/caml_sync_client.native
	cd client
	./client/caml_sync_client.native
	cd ..
init:
	ocamlbuild -use-ocamlfind -pkg cohttp-lwt-unix caml_sync_client.native
	rm -f client/caml_sync_client.native
	mv caml_sync_client.native client/caml_sync_client.native
	cd client
	./client/caml_sync_client.native init
	cd ..
check:
	bash checktypes.sh
debug:
	ocamlbuild -use-ocamlfind -tag 'debug' debug.byte
clean:
	ocamlbuild -clean
install:
	opam update
	opam install opium ezjsonm cohttp
test:
	ocamlbuild -use-ocamlfind core_test.byte
	./core_test.byte
