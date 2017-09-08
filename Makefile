all:
	nasm -f bin -o mbr mbr.s
	nasm -f bin -o vbr vbr.s
	cat	mbr vbr > disk
	rm	mbr vbr

clean:
	rm disk

run:	all
	qemu-system-x86_64 -hda disk
