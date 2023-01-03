.PHONY: all floppyimage kernel bootloader clean always

floppyimage: build/floppy.iso
build/floppy.iso: bootloader kernel
	dd if=/dev/zero of=build/floppy.iso bs=512 count=2880
	mkfs.fat -F12 build/floppy.iso
	dd if=build/bootloader.bin of=build/floppy.iso conv=notrunc
	mcopy -i build/floppy.iso build/kernel.bin "::kernel.bin"
	chown 1000:1000 build/floppy.iso

bootloader: build/bootloader.bin
build/bootloader.bin: always
	nasm src/bootloader/boot.asm -f bin -o build/bootloader.bin

kernel: build/kernel.bin
build/kernel.bin: always 
	nasm src/kernel/main.asm -f bin -o build/kernel.bin

always: 
	mkdir -p build

clean:
	rm -rf build/*
