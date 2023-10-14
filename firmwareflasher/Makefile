main.bin main.map main.rom: main.c sst39sf.c memory.c util.c copy.asm config.h
	zcc \
	+embedded -clib=sdcc_iy \
	main.c \
	copy.asm \
	sst39sf.c \
	memory.c \
	util.c \
	-startup=2 \
	-pragma-define:CRT_ORG_CODE=0x1000 \
	-pragma-define:CRT_ORG_DATA=0x6100 \
	-pragma-define:REGISTER_SP=0x9FFF \
	-pragma-define:CRT_STACK_SIZE=256 \
	-pragma-define:CRT_INCLUDE_PREAMBLE=1 \
	-pragma-define:CLIB_FOPEN_MAX=0 \
	--max-allocs-per-node2000 \
	-SO3 -bn main.bin \
	-create-app -m
