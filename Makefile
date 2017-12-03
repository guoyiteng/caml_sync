svr:
	ocamlbuild -use-ocamlfind caml_sync_server.native
	rm -f server/caml_sync_server.native
	mv caml_sync_server.native server/caml_sync_server.native
server_template:
	ocamlbuild -use-ocamlfind server_template.native && ./server_template.native
runclient:
	ocamlbuild -use-ocamlfind caml_rsync_client.native
	rm -f client/caml_rsync_client.native
	mv caml_rsync_client.native client/caml_rsync_client.native
	./client/caml_rsync_client.native
check:
	bash checktypes.sh
debug:
	ocamlbuild -use-ocamlfind -tag 'debug' debug.byte
cleanup:
	ocamlbuild -clean
install:
	opam install opium ezjsonm
test:
	ocamlbuild -use-ocamlfind core_test.byte
	./core_test.byte
