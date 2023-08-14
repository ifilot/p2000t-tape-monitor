;-------------------------------------------------------------------------------
; printhex subroutine
;
; input: a  - value to print
;        de - video memory address
; uses:  a,iyh
; output: de - new cursor position of video address
;-------------------------------------------------------------------------------
printhex:
	ld iyh,a				; load value into b
    rra						; shift right by 4, ignore leaving bits
	rra
	rra
	rra
	and $0f					; mask
    call printnibble		; print upper nibble
	ld a,iyh				; reload value to print
	and $0f					; mask
	call printnibble		; print lower nibble
	ret

;-------------------------------------------------------------------------------
; printnibble subroutine
;
; input: a  - value to print
;        de - video memory address
; uses:  a,b
; output: de - new cursor position of video address
;-------------------------------------------------------------------------------
printnibble:
	add $30					; add $30 to number in a
	cp $3A					; less than $3A?
	jp c,.print				; if so, number between 0-9, so print it
	add 7					; if not, number between A-F, so add 7
.print:
	ld (de),a				; load accumulator into (de)
	inc de					; increment video position
	ret

;-------------------------------------------------------------------------------
; printdec routine
; input: a  - value to print
;        de - video memory address
; uses:  a,ix
;-------------------------------------------------------------------------------
printdec:
	ld ixh,0				; store hundredths digit
	ld ixl,0				; store tenths digit
.hundredths:
	cp a,100				; check smaller than 100
	jp c,.tenths			; if so, go to tenths
	sub 100					; if not, subtract 100
	inc ixh					; increment counter
	jp .hundredths			; check for more
.tenths:
	cp a,10					; check smaller than 10
	jp c,.ones				; if so, remainder are ones
	sub 10					; if not, subtract 10
	inc ixl					; increment counter
	jp .tenths				; check for more
.ones:
	push af
	ld a,ixh
	add $30					; int to ascii
	ld (de),a				; print hundredths
	inc de
	ld a,ixl
	add $30
	ld (de),a				; print tenths
	inc de
	pop af
	add $30
	ld (de),a
	inc de
	ret

;-------------------------------------------------------------------------------
; printdec routine for 16 bit value, prints trailing zeros
;
; input: hl - number to convert
;        de - video memory address
; uses:  a,bc
;-------------------------------------------------------------------------------
printdec16:
	ld	bc,-10000			; check for 10,000's
	call .num1				; repetitively decrement to build value
	ld	bc,-1000			; check for 1,000's
	call .num1				; repetitively decrement to build value
	ld	bc,-100				; check for 100's
	call .num1				; repetitively decrement to build value
	ld	c,-10				; check for 10's
	call .num1				; repetitively decrement to build value
	ld	c,b					; remaining value are 1's
.num1:
	ld	a,'0'-1				; start with ascii value one lower than '0'
.num2:
	inc	a					; increment a
	add	hl,bc				; add bc to hl
	jr c,.num2				; if carry, try to add once more
	sbc	hl,bc				; correct value when no carry is found
	ld (de),a				; load result into memory addr
	inc	de					; go to next position in memory
	ret

;-------------------------------------------------------------------------------
; printdec routine for 16 bit value, but only three digits
;
; input: hl - number to convert
;        de - video memory address
; uses:  a,bc
;-------------------------------------------------------------------------------
printdec16_3:
	ld	bc,-100				; check for 100's
	call .num1				; repetitively decrement to build value
	ld	c,-10				; check for 10's
	call .num1				; repetitively decrement to build value
	ld	c,b					; remaining value are 1's
.num1:
	ld	a,'0'-1				; start with ascii value one lower than '0'
.num2:
	inc	a					; increment a
	add	hl,bc				; add bc to hl
	jr c,.num2				; if carry, try to add once more
	sbc	hl,bc				; correct value when no carry is found
	ld (de),a				; load result into memory addr
	inc	de					; go to next position in memory
	ret

;-------------------------------------------------------------------------------
; Clear screen
; uses: a,bc,de,hl
;-------------------------------------------------------------------------------
clearscreen:
	ld a,0 ; load 0 into first byte
	ld ($5000),a
	ld de,$5001
	ld bc,$1000
	dec bc
	ld hl,$5000
	ldir ; copy next byte from previous
	ret

;-------------------------------------------------------------------------------
; convert hex characters to int
; input:  bc - two digit hex characters
; output:  a - integer result
; errors: bc = 0
;-------------------------------------------------------------------------------
atoi:
	call ati		; int in a, error status in b
	push af			; put a on stack
	or b			; check if a = b = 0
	jp z,.atoierr	; if so, give error
	pop af			; get a result
	ld b,c			; load lower nibble hex in b
	ld c,a			; keep upper nibble in c
	call ati
	push af
	or b			; check if a = b = 0
	jp z,.atoierr	; if so, give error
	pop af			; upper nibble on a
	ld b,a			; store lower nibble on b
	ld a,c			; put upper nibble back on a
	rla				; shift to left
	rla
	rla
	rla
	and $F0			; mask upper nibble
	or b			; get lower nibble from b
	ret
.atoierr:
	pop af			; restore stack
	ld bc,0
	ld a,0
	ret

;-------------------------------------------------------------------------------
; convert hex characters to int
; input:  b - hex char
; output: a - integer result
; errors: a = b = 0
;-------------------------------------------------------------------------------
ati:
	ld a,b
	cp 71	; larger than 'F', but might be lowercase
	jp c,.atipass
	sub 32	; subtract 32 to potentially get uppercase
.atipass:
	cp 71	; larger than 'F', so give error
	jp nc,.atierror
	cp 48   ; smaller than '0', so give error
	jp c,.atierror
	cp 58	; between 0-9, so convert the digit
	jp c,.convdig
	cp 41
	jp c,.atierror ; between '0' and 'A', so give error
	sub 55
	ret
.convdig:
	sub 48
	ret
.atierror:
	ld a,0
	ld b,0
	ret

;-------------------------------------------------------------------------------
; push video to RAM
; uses: all
;-------------------------------------------------------------------------------
pushvideo:
	ld de,VIDEOTEMP	; set destination address
	ld hl,VIDEO		; set source address
	ld c,24			; 24 lines
.nextline:
	push bc			; push counter
	ld bc,40
	ldir
	pop bc			; retrieve counter
	dec c
	ret z
	push de
	ld de,40		; increment de by 40
	add hl,de
	pop de
	jp .nextline

;-------------------------------------------------------------------------------
; pop video from RAM
; uses all
;-------------------------------------------------------------------------------
popvideo:
	ld de,VIDEO		; set destination address
	ld hl,VIDEOTEMP	; set source address
	ld c,24			; 24 lines
.nextline:
	push bc			; push counter
	ld bc,40
	ldir
	pop bc			; retrieve counter
	dec c
	ret z
	push hl			; put source address on stack
	ex de,hl		; put destination address on hl
	ld de,40		; increment de by 40
	add hl,de
	ex de,hl		; put destination address back on de
	pop hl			; load source address back in hl
	jp .nextline

;-------------------------------------------------------------------------------
; print string to screen
; input: hl - string pointer
; 		 de - screen address
; output: de - exit video address
; uses: a
;-------------------------------------------------------------------------------
printstring:
	ld a,(hl)
	cp 255
	ret z
	ld (de),a
	inc de
	inc hl
	jp printstring