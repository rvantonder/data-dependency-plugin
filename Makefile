all:
	bapbuild -pkg ocamlgraph ddep.plugin
clean:
	rm -r _build *.plugin *.dot *.png
