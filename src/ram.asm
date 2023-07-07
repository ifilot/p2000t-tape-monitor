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
; Receive a byte from RAM chip
; input: de - chip address
; output: a - byte at address
; fixed: de
;-------------------------------------------------------------------------------
ramrecv:
	ld a,e
	out (O_ROM_LA),a		; set lower address
	ld a,d
	out (O_ROM_UA),a		; set upper address
	in a,(O_RAM_RW)
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