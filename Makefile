.PHONY: server client
all: server client
install:
	ln -sf `pwd | sed 's/ /\\ /g'`/_build/caml_sync_client.native /usr/local/bin/camlsync
	ln -sf `pwd | sed 's/ /\\ /g'`/_build/caml_sync_server.native /usr/local/bin/camlsyncserver
uninstall:
	unlink /usr/local/bin/camlsync
	unlink /usr/local/bin/camlsyncserver
server:
	ocamlbuild -use-ocamlfind caml_sync_server.native
	rm -f server/caml_sync_server.native
client:
	ocamlbuild -use-ocamlfind caml_sync_client.native
	rm -f client/caml_sync_client.native
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
	rm -rf client
	rm -rf client2
	mkdir client
	mkdir client2
dependencies:
	opam update
	opam install opium ezjsonm cohttp
test:
	ocamlbuild -use-ocamlfind core_test.byte
	./core_test.byte
