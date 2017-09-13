all:
	nasm -f bin -o disk disk.s

clean:
	rm disk

run:	all
	qemu-system-x86_64 -hda disk
