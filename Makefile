.PHONY: server client
all: server client
install:
	ln -sf "`pwd | sed 's/ /\\ /g'`"/_build/client_main.native /usr/local/bin/camlsync
	ln -sf "`pwd | sed 's/ /\\ /g'`"/_build/client_main.native /usr/local/bin/camlsyncserver
uninstall:
	unlink /usr/local/bin/camlsync
	unlink /usr/local/bin/camlsyncserver
server:
	ocamlbuild -use-ocamlfind caml_sync_server.native
client:
	ocamlbuild -use-ocamlfind client_main.native
server_template:
	ocamlbuild -use-ocamlfind server_template.native && ./server_template.native
sync:
	ocamlbuild -use-ocamlfind client_main.native
	rm -f client/caml_sync_client.native
	mv caml_sync_client.native client/caml_sync_client.native
	cd client
	./client/client_main.native
	cd ..
init:
	ocamlbuild -use-ocamlfind client_main.native
	rm -f client/client_main.native
	mv client_main.native client/client_main.native
	cd client
	./client/client_main.native init
	cd ..
check:
	bash checktypes.sh
debug:
	ocamlbuild -use-ocamlfind -tag 'debug' client_main.byte
	rm -f client/client_main.byte
	rm -f client2/client_main.byte
	cp client_main.byte client/client_main.byte
	mv client_main.byte client2/client_main.byte
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
	rm -rf .config .caml_sync config.json history.json *.diff
	ocamlbuild -use-ocamlfind client_test.byte
	./client_test.byte
	ocamlbuild -use-ocamlfind core_test.byte
	./core_test.byte
