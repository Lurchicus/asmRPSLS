#makefile for rpsls.asm
rpsls: rpsls.o
	gcc -o rpsls rpsls.o -no-pie -z noexecstack
rpsls.o: rpsls.asm
	nasm -f elf64 -g -F dwarf rpsls.asm -l rpsls.lst
