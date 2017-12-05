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
	ocamlbuild -use-ocamlfind -tag 'debug' caml_sync_client.byte
	rm -f client/caml_sync_client.byte
	cp caml_sync_client.byte client/caml_sync_client.byte
	mv caml_sync_client.byte client2/caml_sync_client.byte
	ocamlbuild -use-ocamlfind -tag 'debug' caml_sync_server.byte
	rm -f server/caml_sync_server.byte
	mv caml_sync_server.byte server/caml_sync_server.byte
clean:
	ocamlbuild -clean
	rm -rf client/*
	rm -rf client2/*
install:
	opam update
	opam install opium ezjsonm cohttp
test:
	ocamlbuild -use-ocamlfind core_test.byte
	./core_test.byte
