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
	call clearinterface
	call prtmonloc			; show memory location
	ld a,(RAMFLAG)			; read RAMFLAG to determine printblock routine
	rla						; rotate left = multiply by 2
	ld e,a
	ld d,0
	ld ix,MONADDR			; load base address
	add ix,de				; add offset to base, ix points now to addr location
	ld l,(ix)				; load instruction address via ix pointer into hl
	ld h,(ix+1)
	ld b,NUMROWS			; load number of rows to print
	ld de,BLKSCRN			; load video address
.nextline:
	call printaddrline
	ld c,8					; number of bytes per row
.nextbyte:
	call readbytemon		; fetch byte for monitor
	call printhex			; print hex representation of byte
	inc de					; next video address (giving a blank)
	inc hl					; next memory address
	dec c					; decrement byte counter
	jr nz,.nextbyte			; zero? if not, next byte
	push de					; put video address on stack
	ld de,8					; load number 8 into de register
	or a					; reset carry flag (does not affect a)
	sbc hl,de				; rewind memory address to beginning of line
	pop de					; restore video ram address
	dec de					; decrement video position
	call printascii			; print ascii characters
	push hl					; put memory address on stack
	ex de,hl				; swap de,hl
	ld de,42				; put 42 into de register
	add hl,de				; increment video memory by 42 positions
	ex de,hl				; swap de,hl again
	pop hl					; restore memory adress
	dec b					; decrement line counter
	ret z					; return on zero
	jr .nextline			; if not zero, go to next line

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
	call readbytemon
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
; fetch byte for monitor function
; input: hl - memory location
; uses:  de
; 
; returns: a - value to be read
;-------------------------------------------------------------------------------
readbytemon:
	ld a,(RAMFLAG)
	cp RAMFLAGRAMINT
	jr nz,.cont
	ld a,(hl)
	ret
.cont:
	dec a
	rla			; multiply a by two
	push de
	ld e,a
	ld d,0
	ld ix,.pointers
	add ix,de
	pop de
	ld h,(ix+1)
	ld l,(ix)
	jp (hl)

.pointers:	DW 	ramrecvhl
			DW	sst39sfrecvintromhl
			DW	sst39sfrecvextromhl

;-------------------------------------------------------------------------------
; print monitor location (internal/external rom/ram)
;-------------------------------------------------------------------------------
prtmonloc:
	ld a,(RAMFLAG)
	rla							; shift left 3 times (multiply by 8)
	rla
	rla
	ld e,a
	ld d,0
	ld hl,.message1				; set base message address
	add hl,de					; add offset to it, message now in hl
	ld de,$5000+2*$50			; set memory address
	ld a,COL_GREEN
	ld (de),a
	inc de
	call printstring
	ld a,COL_WHITE
	ld (de),a
	ret

; note that the strings below are exactly 8 bytes
.message1: DB "INT RAM",255
.message2: DB "EXT RAM",255
.message3: DB "INT ROM",255
.message4: DB "EXT ROM",255