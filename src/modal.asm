;-------------------------------------------------------------------------------
; modal.asm
;
; Used for providing the user with a modal pop-up Window wherein the
; user can confirm or type some data
;-------------------------------------------------------------------------------

MODAL_START: 		EQU $5000 + 8*$50+4
MODAL_QUESTIONLINE: EQU $5000 + 9*$50+7

;-------------------------------------------------------------------------------
; Produces a modal window that asks for a user confirmation
;
; Input: hl - pointer to question string 1 
;		 de - pointer to question string 2
; Output: a - 0 (yes), 1 (no)
;-------------------------------------------------------------------------------
confirmmodal:
	ld a,255					; set modal to invalid selection
	ld (MODALSEL),a
	push de						; push pointer to question string 2 on stack
	push hl						; push pointer to question string 1 on stack
	call pushvideo
	call showmodal				; build modal window
	ld de,MODAL_QUESTIONLINE	; load video address string 1
	pop hl						; retrieve pointer string 1 from stack
	call printstring			; print question line 1
	ld de,MODAL_QUESTIONLINE + $50
	pop hl						; retrieve pointer string 2 from stack
	call printstring			; print question line 2
	call modalprintyes
	call modalprintno
	;ld a,(KEYBUF)				; uncomment these lines for debugging
	;ld de,$5000
	;call printhex
.userinput:
	ld a,(NKEYBUF)
	cp 0
	jp z,.userinput
	ld de,KEYBUF
.nextkey:
	ld a,(de)					; load key from buffer
	cp 144						; larger than 144?
	jp nc,.getkeycont			; skip key
	cp KRETURN					; is key enter?
	jp z,.return				; go to enter routine
	call keytoascii				; convert key to ASCII code
	cp 'y'
	jp z,modalselectyes			; auto-jumps to .getkeycont
	cp 'n'
	jp z,modalselectno			; auto-jumps to .getkeycont
.getkeycont:
	ld hl,KEYBUF
	ld d,0
	ld a,(NKEYBUF)
	ld e,a
	add hl,de
	ex de,hl
	inc de						; next position in key buffer
	ld a,(NKEYBUF)
	dec a						; decrement number of keys to print
	ld (NKEYBUF),a				; store this number in nkeybuf
	cp 0						; zero keys reached, return
	jp z,.userinput
	jp .nextkey					; else parse next key
.return:
	ld a,(MODALSEL)
	and $FE						; check if modal is only 0 or 1
	jp z,.exitmodal
	jp .getkeycont
.exitmodal:
	ld a,0
	ld (KEYBUF),a
	call popvideo
	ld a,(MODALSEL)
	ret

;-------------------------------------------------------------------------------
; Produces a modal window that allows the user to select a bank
;
; Input: hl - pointer to question string 1 
;		 de - pointer to question string 2
; Output: a - 1-8 bank number; 0: cancel
;-------------------------------------------------------------------------------
selectbankmodal:
	ld a,255					; set modal to invalid selection
	ld (MODALSEL),a
	push de						; push pointer to question string 2 on stack
	push hl						; push pointer to question string 1 on stack
	call pushvideo
	call showmodal				; build modal window
	ld de,MODAL_QUESTIONLINE	; load video address string 1
	pop hl						; retrieve pointer string 1 from stack
	call printstring			; print question line 1
	ld de,MODAL_QUESTIONLINE + $50
	pop hl						; retrieve pointer string 2 from stack
	call printstring			; print question line 2
	;ld a,(KEYBUF)				; uncomment these lines for debugging
	;ld de,$5000
	;call printhex
.userinput:
	ld a,(NKEYBUF)
	cp 0
	jp z,.userinput
	ld de,KEYBUF
.nextkey:
	ld a,(de)					; load key from buffer
	cp KRETURN					; is key enter?
	jp z,.return				; go to enter routine
	call keytoascii				; convert key to ASCII code
	cp '0'						; check if key is between 0 and 8, inclusive
	jp c,.getkeycont
	cp '9'
	jp c,modalselectbank
.getkeycont:
	ld hl,KEYBUF
	ld d,0
	ld a,(NKEYBUF)
	ld e,a
	add hl,de
	ex de,hl
	inc de						; next position in key buffer
	ld a,(NKEYBUF)
	dec a						; decrement number of keys to print
	ld (NKEYBUF),a				; store this number in nkeybuf
	cp 0						; zero keys reached, return
	jp z,.userinput
	jp .nextkey					; else parse next key
.return:
	ld a,(MODALSEL)
	cp 9						; check if value is between 0-8, inclusive
	jp c,.exitmodal
	jp .getkeycont
.exitmodal:
	ld a,0						; reset key buffer
	ld (KEYBUF),a
	call popvideo
	ld a,(MODALSEL)
	ret

;-------------------------------------------------------------------------------
; print the yes line
;-------------------------------------------------------------------------------
modalprintyes:
	ld hl,.yes
	ld de,YESLINE
	call printstring
	ret

.yes: DB "YES",255

YESLINE:			EQU $5000 + 13*$50 + 17

;-------------------------------------------------------------------------------
; print the no line
;-------------------------------------------------------------------------------
modalprintno:
	ld hl,.no
	ld de,NOLINE
	call printstring
	ret

.no: DB "NO",255

NOLINE:				EQU $5000 + 12*$50 + 17

;-------------------------------------------------------------------------------
; undo selection of both lines (prior to selecting a new one)
;-------------------------------------------------------------------------------
modaldeselect:
	ld de,MODAL_START+4*$50
	call modal_centerline
	ld de,MODAL_START+5*$50
	call modal_centerline
	call modalprintyes
	call modalprintno
	ret

;-------------------------------------------------------------------------------
; select the no line
; uses: all
;-------------------------------------------------------------------------------
modalselectno:
	call modaldeselect
	ld de,SELECTNOLINE
	ld hl,.select
	call printstring
	ld de,SELECTNOLINE+8
	ld hl,.end
	call printstring
	ld a,1						; set modal condition to 1 (false)
	ld (MODALSEL),a
	jp confirmmodal.getkeycont

.select: DB 7,157,132,255
.end: 	 DB 156,7,255

SELECTNOLINE:		EQU NOLINE-5

;-------------------------------------------------------------------------------
; select the yes line
; uses: all
;-------------------------------------------------------------------------------
modalselectyes:
	call modaldeselect
	ld de,SELECTYESLINE
	ld hl,.select
	call printstring
	ld de,SELECTYESLINE+9
	ld hl,.end
	call printstring
	ld a,0						; set modal condition to 0 (true)
	ld (MODALSEL),a
	jp confirmmodal.getkeycont

.select: DB 7,157,132,255
.end: 	 DB 156,7,255

SELECTYESLINE:		EQU YESLINE-5

;-------------------------------------------------------------------------------
; modal
;-------------------------------------------------------------------------------
modalselectbank:
	sub '0'
	ld (MODALSEL),a
	;---
	;ld de,$5000
	;call printhex
	;---
	ld de,MODAL_QUESTIONLINE + $50 * 3
	cp 8
	jp nz,.printbank
	ld hl,.cancel
	call printstring
	jp .end
.printbank:
	ld hl,.message
	call printstring
	ld a,(MODALSEL)
	call printhex
.end:
	jp selectbankmodal.getkeycont

.message: DB COL_CYAN,"Bank ID: ",COL_WHITE,255
.cancel: DB COL_RED,"Cancel      ",COL_WHITE,255

;-------------------------------------------------------------------------------
; produce a modal window of 28x5 blocks with a white border
;-------------------------------------------------------------------------------
showmodal:
	ld hl,MODAL_START
	ld de,MODAL_START
	call modal_borderline
	ld c,5
.nextcenterline:
	ld de,$50
	add hl,de
	ld d,h
	ld e,l
	call modal_centerline
	dec c
	jp nz,.nextcenterline
	ld de,MODAL_START+6*$50
	call modal_borderline
	ret

;-------------------------------------------------------------------------------
; Print the top and bottom line of the modal window
; (used in showmodal)
;-------------------------------------------------------------------------------
modal_borderline:
	ld a,COL_WHITE
	ld (de),a
	ld b,30
	ld a,127
.loopfill:
	inc de
	ld (de),a
	dec b
	jp nz,.loopfill
	ld a,COL_WHITE
	ld (de),a
	ret

;-------------------------------------------------------------------------------
; Print the center lines of the modal window
; (used in showmodal)
;-------------------------------------------------------------------------------
modal_centerline:
	ld a,COL_WHITE
	ld (de),a
	inc de
	ld a,127
	ld (de),a
	ld b,28
	ld a,0
.loopfill:
	inc de
	ld (de),a
	dec b
	jp nz,.loopfill
	ld a,127
	ld (de),a
	ret