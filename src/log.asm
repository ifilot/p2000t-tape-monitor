;# MAIN="main.asm"
;-------------------------------------------------------------------------------
; LOGGING ROUTINES
;-------------------------------------------------------------------------------

initlog:
	ld hl,LOGSTART
	ld (LOGPOINTER),hl
	ret

;-------------------------------------------------------------------------------
; copyramromlog
;-------------------------------------------------------------------------------
copyramromlog:
	ld hl,.message
	call writelogstring
	call writecolon
	ld a,(FREEBANK)
	call writeloghex
	ld hl,(ROMADDR)
	call writelogword
	call writelognextline
	ret

.message: DB "CRR",255

;-------------------------------------------------------------------------------
; print string to screen
; input:  hl - string pointer
; output: de - log address pointer
; uses: a
;-------------------------------------------------------------------------------
writelogstring:
	ld de,(LOGPOINTER)
.nextbyte:
	ld a,(hl)
	cp 255
	jp z,.exit
	ld (de),a
	inc de
	inc hl
	jp .nextbyte
.exit:
	ld (LOGPOINTER),de
	ret

;-------------------------------------------------------------------------------
; Write colon to logaddress
;-------------------------------------------------------------------------------
writecolon:
	ld de,(LOGPOINTER)
	ld a,":"
	ld (de),a
	inc de
	ld (LOGPOINTER),de
	ret

;-------------------------------------------------------------------------------
; write a newline character to LOG
; uses: a,de
;-------------------------------------------------------------------------------
writelognextline:
	ld de,(LOGPOINTER)
	ld a,10 				; newline character
	ld (de),a
	inc de
	ld (LOGPOINTER),de
	ret

;-------------------------------------------
; printhex subroutine
; input: a  - value to print
; uses:  a,b
; output: de - new cursor position of video address
;-------------------------------------------
writeloghex:
	ld de,(LOGPOINTER)
	ld b,a
    rra
	rra
	rra
	rra
	and $0f
    call .printnibble
	ld a,b
	and $0f
	call .printnibble
	ret

.printnibble:
	add $30
	cp $3A
	jp c,.print
	add 7
.print:
	ld (de),a
	inc de
	ld (LOGPOINTER),de
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