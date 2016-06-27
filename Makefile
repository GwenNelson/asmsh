all: asmsh
asmsh.o: asmsh.asm
	nasm -f macho64 asmsh.asm
asmsh: asmsh.o
	ld  -lreadline -lc /usr/lib/crt1.o -o asmsh asmsh.o
