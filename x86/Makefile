all:
	nasm -f bin -o MBR MBR.s
	nasm -f bin -o VBR VBR.s
	nasm -f bin -o kernel kernel.s
	cat MBR VBR kernel > disk

clean:
	rm -f MBR VBR kernel disk

run: all
	qemu-system-x86_64 -hda disk
