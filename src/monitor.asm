;-------------------------------------------
; monitor.asm
;
; Shows memory at given RAM address
;-------------------------------------------

;-------------------------------------------
; print block
; input: BLKSCRN - video address
;        MONADDR - monitor address
; uses:  bc,de,af
;-------------------------------------------
printblock:
	call clearinterface
	ld de,BLKSCRN		; load video address
	ld hl,(MONADDR)		; load monitor address from RAM
	ld b,NUMROWS		; load number of rows to print
.nextline:
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
	ld c,8			; number of bytes per row
.next:
	ld a,(hl)		; load byte from memory
	push bc			; put counter on stack
	call printhex
	pop bc			; retrieve counter from stack
	inc de
	inc hl
	dec c			; decrement byte counter
	jp nz,.next		; zero? if not, next byte
	push de			; put video address on stack
	ld de,7			; rewind address by 7 bytes
	sbc hl,de
	pop de			; restore video ram address
	dec de			; decrement video position
	call printascii	; print ascii characters
	push hl
	ex de,hl
	ld de,42		; set address to start of next line
	add hl,de
	ex de,hl
	pop hl
	dec b
	ret z
	jp .nextline

;-------------------------------------------
; print ASCII characters
; de - video address
; hl - memory address
;-------------------------------------------
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