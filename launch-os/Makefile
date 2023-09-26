main.bin main.map main.rom: main.c sst39sf.c programs.c ram.c util.c memory.c
	zcc \
	+embedded -clib=sdcc_iy \
	main.c \
	sst39sf.c \
	programs.c \
	ram.c \
	util.c \
	memory.c \
	-startup=0 \
	-pragma-define:CRT_ORG_CODE=0x7000 \
	-pragma-define:REGISTER_SP=-1 \
	-pragma-define:CLIB_FOPEN_MAX=0 \
	--max-allocs-per-node200000 \
	-SO3 -bn main.bin \
	-create-app -m
