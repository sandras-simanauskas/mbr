all:
	mkdir -p bin
	nasm -f bin -o bin/MBR x86/MBR.s
	nasm -f bin -o bin/VBR x86/VBR.s
	nasm -f bin -o bin/kernel x86/64/kernel.s
	cat bin/MBR bin/VBR bin/kernel > bin/disk

clean:
	rm -rf bin

run: all
	qemu-system-x86_64 -hda bin/disk
