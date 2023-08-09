;-------------------------------------------------------------------------------
; Send a byte to RAM chip
; input: de - chip address
;         a - byte to write
; uses: b
; fixed: de
;-------------------------------------------------------------------------------
ramsend:
	ld b,a					; temporarily store a in b
	ld a,e
	out (O_ROM_LA),a		; set lower address
	ld a,d
	out (O_ROM_UA),a		; set upper address
	ld a,b					; recall a from b
	out (O_RAM_RW),a		; store byte
	ret

;-------------------------------------------------------------------------------
; Receive a byte from RAM chip via address in de
;
; input: de - chip address
; output: a - byte at address
; fixed: de
;-------------------------------------------------------------------------------
ramrecvde:
	ld a,e
	out (O_ROM_LA),a		; set lower address
	ld a,d
	out (O_ROM_UA),a		; set upper address
	in a,(O_RAM_RW)
	ret

;-------------------------------------------------------------------------------
; Receive a byte from RAM chip via address in hl
;
; input: hl - chip address
; output: a - byte at address
; fixed: hl
;-------------------------------------------------------------------------------
ramrecvhl:
	ld a,h
	out (O_ROM_LA),a		; set lower address
	ld a,l
	out (O_ROM_UA),a		; set upper address
	in a,(O_RAM_RW)
	ret

;-------------------------------------------------------------------------------
; set 0x00 everywhere in the RAM chip
;
; uses: a,b,de,hl
;-------------------------------------------------------------------------------
clearram:
	ld de,0
	ld hl,$8000
.nextbyte:
	ld a,0
	call ramsend
	inc de
	dec hl
	ld a,h
	or l
	djnz .nextbyte
	ret

;-------------------------------------------------------------------------------
; loop through ram and set incrementing values in a modular fashion
;
; uses: a,b,de,hl
;-------------------------------------------------------------------------------
stairram:
	ld de,0
	ld hl,$8000
	ld c,0
.nextbyte:
	ld a,c
	call ramsend
	inc c
	inc de
	dec hl
	ld a,h
	or l
	djnz .nextbyte
	ret

;-------------------------------------------------------------------------------
; Rinse RAM and ROM
;-------------------------------------------------------------------------------
ramrinse:
	ld a,0
	out (O_ROM_BANK),a
	out (O_ROM_LA),a
	out (O_ROM_UA),a
	in a,(O_ROM_EXT)
	out (O_RAM_RW),a
	ret