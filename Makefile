all:
	nasm -f bin -o mbr mbr.s

clean:
	rm mbr

run:	all
	qemu-system-x86_64 -hda mbr
