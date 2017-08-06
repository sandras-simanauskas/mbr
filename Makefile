all:
	nasm -f bin -o mbr mbr.s
	nasm -f bin -o vbr1 vbr1.s
	nasm -f bin -o vbr2 vbr2.s
	nasm -f bin -o vbr3 vbr3.s
	nasm -f bin -o vbr4 vbr4.s
	cat	mbr vbr1 vbr2 vbr3 vbr4 > disk
	rm	mbr vbr1 vbr2 vbr3 vbr4

clean:
	rm disk

run:	all
	qemu-system-i386 -hda disk
