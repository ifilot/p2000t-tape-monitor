;-------------------------------------------------------------------------------
; Completely erase a 64 kb bank of a ROM chip
; $0000-$FFFF
; input: c - port id
;-------------------------------------------------------------------------------
sst39erase64kb:
	ld a,(ROMBANK)			; load rom bank
	ld b,a
	ld h,0					; counter on h
	ld l,b					; store bank number on l
.erasenextblock:
	push hl
	ld a,h					; load erase sector
	rla						; four times shift left
	rla
	rla
	rla
	and $F0					; set lower nibble to zero
	ld d,a					; load upper address byte
	ld e,0
	ld b,l					; get bank number
	call sst39sferase		; wipe 4kb sector
	pop hl					; get counter and bank
	inc h
	ld a,h
	cp 16
	jp nz,.erasenextblock	; if zero, fall through and stop
	ret

;-------------------------------------------------------------------------------
; Get CHIP id, for the SST39SF040, the response
; should be $BF,$B7
; input:   c - port number
; output: hl - output of chip id
; uses: a,bc,de,hl
; fixed: c
;-------------------------------------------------------------------------------
sst39sfid:
	;---
	; uncomment the lines below for debugging
	;ld hl,$BFB7
	;ret
	;---
	ld a,0
	out (O_ROM_BANK),a	; set to bank 0
	ld de,$5555			; open interface
	ld b,$AA
	call sst39sfsend
	ld de,$2AAA
	ld b,$55
	call sst39sfsend
	ld de,$5555
	ld b,$90
	call sst39sfsend
	ld de,$0000
	call sst39sfrecv	; receive first byte of id
	ld h,a				; store in h
	ld de,$0001
	call sst39sfrecv	; receive second byte of id
	ld l,a				; store in l
	ld de,$5555			; close interface
	ld b,$AA
	call sst39sfsend
	ld de,$2AAA
	ld b,$55
	call sst39sfsend
	ld de,$5555
	ld b,$F0
	call sst39sfsend
	ret
	
;-------------------------------------------------------------------------------
; Send a byte to SST39SF0x0 chip
; input:  c - port number
;		 de - chip address
;         b - byte to send
; uses: a
; fixed: c,de
;-------------------------------------------------------------------------------
sst39sfsend:
	ld a,e
	out (O_ROM_LA),a
	ld a,d
	out (O_ROM_UA),a
	ld a,b
	out (c),a
	ret

;-------------------------------------------------------------------------------
; Receive a byte from SST39SF0x0 chip
; input:  c - port number
;		 de - chip address
; output: a - byte at address
;		 de - chip address
; fixed: c
;-------------------------------------------------------------------------------
sst39sfrecv:
	ld a,e
	out (O_ROM_LA),a
	ld a,d
	out (O_ROM_UA),a
	in a,(c)
	ret

;-------------------------------------------------------------------------------
; Receive a byte from internal SST39SF0x0 chip
; input: de - chip address
; output: a - byte at address
;		 de - chip address
;-------------------------------------------------------------------------------
sst39sfrecvintromhl:
	ld a,l
	out (O_ROM_LA),a
	ld a,h
	out (O_ROM_UA),a
	in a,(O_ROM_RW)
	ret

;-------------------------------------------------------------------------------
; Receive a byte from internal SST39SF0x0 chip
; input: de - chip address
; output: a - byte at address
;		 de - chip address
;-------------------------------------------------------------------------------
sst39sfrecvextromhl:
	ld a,l
	out (O_ROM_LA),a
	ld a,h
	out (O_ROM_UA),a
	in a,(O_ROM_EXT)
	ret

;-------------------------------------------------------------------------------
; Receive a byte from external SST39SF0x0 chip
; input: de - chip address
; output: a - byte at address
;		 de - chip address
;-------------------------------------------------------------------------------
sst39sfrecvextrom:
	ld a,e
	out (O_ROM_LA),a
	ld a,d
	out (O_ROM_UA),a
	in a,(O_ROM_EXT)
	ret

;-------------------------------------------------------------------------------
; Clear a 4kb sector
; input:  de - chip address
;		   b - bank number
;          c - port number
; output: hl - number of poll calls
; uses: a,b,de,hl (all)
; fixed: c
;-------------------------------------------------------------------------------
sst39sferase:
	push de	; chip erase address on stack
	push bc ; put port number and bank number on stack
	ld a,0
	out (O_ROM_BANK),a
	ld de,$5555
	ld b,$AA
	call sst39sfsend
	ld de,$2AAA
	ld b,$55
	call sst39sfsend
	ld de,$5555
	ld b,$80
	call sst39sfsend
	ld de,$5555
	ld b,$AA
	call sst39sfsend
	ld de,$2AAA
	ld b,$55
	call sst39sfsend
	pop bc  ; pop bank number from the stack
	ld a,b
	out (O_ROM_BANK),a
	pop de	; pop chip erase address from stack
	ld b,$30
	call sst39sfsend
	call sst39sfpollbyte
	ret

;-------------------------------------------------------------------------------
; Write a single byte at address
; input:  de - chip address
;		  hl - address of byte to be written
;		   c - port number
; uses: a,bc,de,h
; output: de - rom address
;         hl - source address
;          c - port number
;-------------------------------------------------------------------------------
sst39sfwrbytemem:
	push de				; store rom address
	ld de,$5555
	ld b,$AA
	call sst39sfsend
	ld de,$2AAA
	ld b,$55
	call sst39sfsend
	ld de,$5555
	ld b,$A0
	call sst39sfsend
	pop de				; retrieve rom address
	ld b,(hl)			; load byte to be written
	call sst39sfsend
	ret

;-------------------------------------------------------------------------------
; Write a single byte from accumulator
; input:  de - chip address
;		   a - byte to write
;		   c - port number
; uses: a,bc,de
; output:  a - byte to write
;		   b - byte to write
;		   c - port number
;		  de - rom address
;-------------------------------------------------------------------------------
sst39sfwrbyteacc:
	push af				; store byte to be written
	push de				; store rom address
	ld de,$5555
	ld b,$AA
	call sst39sfsend
	ld de,$2AAA
	ld b,$55
	call sst39sfsend
	ld de,$5555
	ld b,$A0
	call sst39sfsend
	pop de				; retrieve rom address
	pop af				; retrieve byte to be written
	ld b,a				; set byte in b
	call sst39sfsend
	ret

;-------------------------------------------------------------------------------
; poll bit 7 until chip confirms write operation
; is complete
; input:  de - chip address
; output: hl - number of iterations
; uses: a,de
;-------------------------------------------------------------------------------
sst39sfpollbyte:
	ld hl,$0000
nextpoll:
	call sst39sfrecv
	and $80
	cp $80
	ret z
	inc hl
	ld a,h
	and l
	cp $FF
	ret z
	jp nextpoll