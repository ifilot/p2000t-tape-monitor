main.bin main.map main.rom: *.c *.asm
	zcc \
	+embedded -clib=sdcc_iy \
	*.c \
	*.asm \
	-startup=0 \
	-pragma-define:CRT_ORG_CODE=0x7000 \
	-pragma-define:REGISTER_SP=-1 \
	-pragma-define:CLIB_FOPEN_MAX=0 \
	-pragma-define:CRT_ON_EXIT=0x10002 \
	-pragma-define:CRT_ENABLE_EIDI=0x00 \
	--max-allocs-per-node2000000 \
	-SO3 -bn main.bin \
	-create-app -m
