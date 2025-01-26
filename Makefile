hello: hello.s
	nasm -felf64 hello.s -o obj/hello.o
	ld obj/hello.o -o bin/hello
