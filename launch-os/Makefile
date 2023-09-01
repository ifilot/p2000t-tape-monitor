all: main.bin main.map main.rom disassembly.txt

main.bin main.map main.rom: main.c sst39sf.c programs.c ram.c
	docker run -v ${PWD}:/src/ -it z88dk/z88dk zcc \
	+embedded -clib=sdcc_iy main.c sst39sf.c programs.c ram.c \
	-startup=2 \
	-pragma-define:CRT_ORG_CODE=0x1000 \
	-pragma-define:CRT_ORG_DATA=0x6100 \
	-pragma-define:REGISTER_SP=0x9FFF \
	-pragma-define:CRT_STACK_SIZE=256 \
	-pragma-define:CRT_INCLUDE_PREAMBLE=1 \
	-pragma-define:CLIB_FOPEN_MAX=0 \
	--max-allocs-per-node200000 \
	-SO3 -bn main.bin \
	-create-app -m

disassembly.txt: main.map main.rom
	z88dk-dis -mz80 -o 0x1000 -x main.map main.rom > disassembly.txt