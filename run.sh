#/bin/sh
nasm -f bin -o disk disk.s
qemu-system-x86_64 -hda disk
rm disk
