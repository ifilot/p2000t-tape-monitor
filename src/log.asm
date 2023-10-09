;# MAIN="main.asm"
;-------------------------------------------------------------------------------
; LOGGING ROUTINES
;-------------------------------------------------------------------------------

initlog:
	ld hl,LOGSTART
	ld (LOGPOINTER),hl
	ret

;-------------------------------------------------------------------------------
; print string to screen
; input:  hl - string pointer
; uses: a
;-------------------------------------------------------------------------------
writelogstring:
	push de
	ld de,(LOGPOINTER)
.nextbyte:
	ld a,(hl)
	cp 255
	jp z,.exit
	ld (de),a
	inc de
	inc hl
	jr .nextbyte
.exit:
	ld (LOGPOINTER),de
	pop de
	ret

;-------------------------------------------------------------------------------
; Write colon to logaddress
;-------------------------------------------------------------------------------
writecolon:
	push de
	ld de,(LOGPOINTER)
	ld a,":"
	ld (de),a
	inc de
	ld (LOGPOINTER),de
	pop de
	ret

;-------------------------------------------------------------------------------
; write a newline character to LOG
; uses: a
;-------------------------------------------------------------------------------
writelognextline:
	push de
	ld de,(LOGPOINTER)
	ld a,10 				; newline character
	ld (de),a
	inc de
	ld (LOGPOINTER),de
	pop de
	ret

;-------------------------------------------
; printhex subroutine
; input: a  - value to print (retained)
; uses:  a,iyh
;-------------------------------------------
writeloghex:
	push de
	ld de,(LOGPOINTER)
	ld iyh,a				; load value into b
    rra						; shift right by 4, ignore leaving bits
	rra
	rra
	rra
	and $0f					; mask
    call .printnibble		; print upper nibble
	ld a,iyh				; reload value to print
	and $0f					; mask
	call .printnibble		; print lower nibble
	ld (LOGPOINTER),de
	ld a,iyh
	pop de
	ret
.printnibble:
	add $30
	cp $3A
	jp c,.print
	add 7
.print:
	ld (de),a
	inc de
	ret

;-------------------------------------------
; printword subroutine
; input: hl - word to print
;-------------------------------------------
writelogword:
	ld a,h
	call writeloghex
	ld a,l
	call writeloghex
	ret