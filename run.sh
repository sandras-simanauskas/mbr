#!/bin/sh
nasm -f bin -o MBR MBR.s
nasm -f bin -o VBR VBR.s
cat MBR VBR > disk
qemu-system-x86_64 -hda disk
rm MBR VBR disk
