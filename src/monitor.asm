;-------------------------------------------------------------------------------
; monitor.asm
;
; Shows memory at given RAM address
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; print block of RAM, depending on the RAMFLAG setting, either part of internal 
; RAM or part of the external RAM is printed
;-------------------------------------------------------------------------------
printblock:
	; initialize some variables
	call clearinterface
	ld de,BLKSCRN			; load video address
	ld b,NUMROWS			; load number of rows to print
	; check whether to print internal or external RAM
	ld a,(RAMFLAG)			; read RAMFLAG
	cp 0
	jp nz,printblockexram	; jump to external ram printing routine
	jp printblockintram		; jump to internal ram printing routine

;-------------------------------------------------------------------------------
; show block of internal RAM on the monitor
;
; input: de - video address
;        MONADDR - monitor address
; uses:  all
;-------------------------------------------------------------------------------
printblockintram:
	ld hl,(MONADDR)		; load monitor address from RAM
.nextline:
	call printaddrline
	ld c,8				; number of bytes per row
.next:
	ld a,(hl)			; load byte from memory
	push bc				; put counter on stack
	call printhex
	pop bc				; retrieve counter from stack
	inc de
	inc hl
	dec c				; decrement byte counter
	jp nz,.next			; zero? if not, next byte
	push de				; put video address on stack
	ld de,7				; rewind address by 7 bytes
	sbc hl,de
	pop de				; restore video ram address
	dec de				; decrement video position
	call printascii		; print ascii characters
	push hl
	ex de,hl
	ld de,42			; set address to start of next line
	add hl,de
	ex de,hl
	pop hl
	dec b
	ret z
	jp .nextline

;-------------------------------------------------------------------------------
; show block of external RAM on the monitor
;
; input: de - video address
;        EXRAMADDR - monitor address
; uses:  all
;-------------------------------------------------------------------------------
printblockexram:
	ld hl,(EXRAMADDR)	; load monitor address from RAM
.nextline:
	call printaddrline
	ld c,8				; number of bytes per row
.nextbyte:
	call ramrecvhl		; receive external ram byte into a
	ld (RAMBUF),a
	push bc				; put counter on stack
	call printhex
	pop bc				; retrieve counter from stack
	inc de				; next video address
	inc hl				; next memory address
	dec c				; decrement byte counter
	jp nz,.nextbyte		; zero? if not, next byte
	push de				; put video address on stack
	ld de,8				; rewind address by 7 bytes
	sbc hl,de
	pop de				; restore video ram address
	dec de				; decrement video position
	call printasciiexram; print ascii characters
	push hl
	ex de,hl
	ld de,42			; set address to start of next line
	add hl,de
	ex de,hl
	pop hl
	dec b
	ret z
	jp .nextline
	ret

;-------------------------------------------------------------------------------
; print the address line
; input: hl - starting address
;        de - video ram position
; uses:  all
;-------------------------------------------------------------------------------
printaddrline:
	push bc
	ld a,COL_YELLOW		; print address in yellow
	ld (de),a
	inc de
	ld a,'$'
	ld (de),a
	inc de
	ld a,h
	call printhex	; print upper byte address
	ld a,l
	call printhex	; print lower byte address
	ld a,$7			; reset to white
	ld (de),a
	inc de
	pop bc
	ret

;-------------------------------------------------------------------------------
; print ASCII characters
; de - video address
; hl - memory address
;-------------------------------------------------------------------------------
printascii:
	ld a,6		; print ascii in cyan
	ld (de),a
	inc de
	ld c,8
.next:
	ld a,(hl)
	cp $21
	jp c,.printdot
	cp $7E
	jp nc,.printdot
	jp .printchar
.printdot:
	ld a,$2E
.printchar:
	ld (de),a
	inc hl
	dec c
	ret z
	inc de
	jp .next

;-------------------------------------------------------------------------------
; print ASCII characters from external memory
; de - video address
; hl - memory address
;-------------------------------------------------------------------------------
printasciiexram:
	ld a,6		; print ascii in cyan
	ld (de),a
	inc de
	ld c,8
.next:
	call ramrecvhl
	cp $21
	jp c,.printdot
	cp $7E
	jp nc,.printdot
	jp .printchar
.printdot:
	ld a,$2E
.printchar:
	ld (de),a
	inc hl
	dec c
	ret z
	inc de
	jp .next