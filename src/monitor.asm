;-------------------------------------------------------------------------------
; monitor.asm
;
; Shows memory at given RAM address
;
; TODO: Reduce the code duplication between monitoring internal and external
;       RAM.
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
	cp 0					; 0 -> internal ram, external ram otherwise
	jr nz,printblockexram	; jump to external ram printing routine
	jr printblockintram		; jump to internal ram printing routine

;-------------------------------------------------------------------------------
; show block of internal RAM on the monitor
;
; input: de - video address
;        MONADDR - monitor address
;
; register 'b' contains the number of rows to write
;
; uses:  all
;-------------------------------------------------------------------------------
printblockintram:
	ld hl,(MONADDR)		; load monitor address from RAM
.nextline:
	call printaddrline
	ld c,8				; number of bytes per row
.nextbyte:
	ld a,(hl)			; load byte from memory
	call printhex		; print hex representation of byte
	inc de				; next video address (giving a blank)
	inc hl				; next memory address
	dec c				; decrement byte counter
	jr nz,.nextbyte		; zero? if not, next byte
	push de				; put video address on stack
	ld de,8				; load number 8 into de register
	or a				; reset carry flag (does not affect a)
	sbc hl,de			; rewind memory address to beginning of line
	pop de				; restore video ram address
	dec de				; decrement video position
	call printascii		; print ascii characters
	push hl				; put memory address on stack
	ex de,hl			; swap de,hl
	ld de,42			; put 42 into de register
	add hl,de			; increment video memory by 42 positions
	ex de,hl			; swap de,hl again
	pop hl				; restore memory adress
	dec b				; decrement line counter
	ret z				; return on zero
	jr .nextline		; if not zero, go to next line

;-------------------------------------------------------------------------------
; show block of external RAM on the monitor
;
; input: de - video address
;        EXRAMADDR - monitor address
;
; register 'b' contains the number of rows to write
;
; uses:  all
;-------------------------------------------------------------------------------
printblockexram:
	ld hl,(EXRAMADDR)	; load monitor address from RAM
.nextline:
	call printaddrline
	ld c,8				; number of bytes per row
.nextbyte:
	call ramrecvhl		; receive external ram byte into a
	call printhex		; print hex representation of byte
	inc de				; next video address (giving a blank)
	inc hl				; next memory address
	dec c				; decrement byte counter
	jr nz,.nextbyte		; zero? if not, next byte
	push de				; put video address on stack
	ld de,8				; load number 8 into de register
	or a				; reset carry flag (does not affect a)
	sbc hl,de			; rewind memory address to beginning of line
	pop de				; restore video ram address
	dec de				; decrement video position
	call printasciiexram; print ascii characters
	push hl				; put memory address on stack
	ex de,hl			; swap de,hl
	ld de,42			; put 42 into de register
	add hl,de			; increment video memory by 42 positions
	ex de,hl			; swap de,hl again
	pop hl				; restore memory adress
	dec b				; decrement line counter
	ret z				; return on zero
	jr .nextline		; if not zero, go to next line

;-------------------------------------------------------------------------------
; print the address line
; input: hl - starting address
;        de - video ram position
; uses:  all
;-------------------------------------------------------------------------------
printaddrline:
	push bc				; put counter on stack
	ld a,COL_YELLOW		; print address in yellow
	ld (de),a			; put yellow marker in video memory
	inc de				; increment video memory position
	ld a,'$'			; load '$' sign
	ld (de),a			; write '$' sign to video memory
	inc de				; increment video memory position
	ld a,h				; load upper byte of memory address into a
	call printhex		; print upper byte address
	ld a,l				; load lower byte of memory address into a
	call printhex		; print lower byte address
	ld a,COL_WHITE		; set color to white
	ld (de),a			; put white marker in video memory
	inc de				; increment video memory position
	pop bc				; grab counter from stack
	ret

;-------------------------------------------------------------------------------
; print ASCII characters
; de - video address
; hl - memory address
;-------------------------------------------------------------------------------
printascii:
	ld a,COL_CYAN		; print ascii in cyan
	ld (de),a			; put cyan marker in video ram
	inc de				; increment memory position
	ld c,8				; set byte counter
.next:
	ld a,(hl)			; get character from internal ram
	cp $21				; check if smaller than $21?
	jr c,.printdot		; write a dot if so
	cp $7E				; check if smaller than $7E?
	jr nc,.printdot		; if not, also write a dot
	jr .printchar		; else write a regular character
.printdot:
	ld a,$2E			; load 'dot' character
.printchar:
	ld (de),a			; write character in a to video memory
	inc hl				; increment memory address
	dec c				; decrement byte counter
	ret z				; return on zero
	inc de				; if not zero, increment memory position
	jr .next			; and go to next byte

;-------------------------------------------------------------------------------
; print ASCII characters from external memory
; de - video address
; hl - memory address
;-------------------------------------------------------------------------------
printasciiexram:
	ld a,COL_CYAN		; print ascii in cyan
	ld (de),a			; put cyan marker in video ram
	inc de				; increment memory position
	ld c,8				; set byte counter
.next:
	call ramrecvhl		; get character from external ram (leaves hl untouched)
	cp $21				; check if smaller than $21?
	jr c,.printdot		; write a dot if so
	cp $7E				; check if smaller than $7E?
	jr nc,.printdot		; if not, also write a dot
	jr .printchar		; else write a regular character
.printdot:
	ld a,$2E			; load 'dot' character
.printchar:
	ld (de),a			; write character in a to video memory
	inc hl				; increment memory address
	dec c				; decrement byte counter
	ret z				; return on zero
	inc de				; if not zero, increment memory position
	jr .next			; and go to next byte