guess: guess.s
	nasm -felf64 guess.s -o obj/guess.o
	ld obj/guess.o -o bin/guess

hello: hello.s
	nasm -felf64 hello.s -o obj/hello.o
	ld obj/hello.o -o bin/hello
