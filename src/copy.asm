;# MAIN="main.asm"
;-------------------------------------------------------------------------------
; Copies the first X b from ROM bank to RAM chip. Maximum number of bytes
; is limited to 32kb due to RAM chip capacity. For full 64kb copy, one needs
; to execute this function twice.
;
; input: de - start ROM address
;		 hl - number of bytes
;-------------------------------------------------------------------------------
copybank_rora:
	ld a,(ROMBANK)		; get rom bank
	out (O_ROM_BANK),a	; set rom bank
	ld a,(ROMCHIP)		; load rom chip to read from; value in c is retained
	ld c,a				; throughout this whole function
	ld a,h				; set counter
	ld ixh,a
	ld a,l
	ld ixl,a
	ld hl,0				; set RAM address (fixed to start at 0)
.next:
	call sst39sfrecv	; load byte in a from address in de
	ex de,hl			; RAM address in de
	call ramsend		; store byte in RAM from a to address de
	ex de,hl			; RAM address back in hl
	inc de				; increment ROM address
	inc hl				; increment RAM address
	dec ix				; decrement counter
	ld a,ixh
	or ixl				; check if zero
	jp nz,.next			; if not, next byte
	ret

;-------------------------------------------------------------------------------
; Copies the first X b from RAM chip to ROM bank. Maximum number of bytes
; is limited to 32kb due to RAM chip capacity. For full 64kb copy, one needs
; to execute this function twice.
;
; input: de - start address
;		 hl - number of bytes
;-------------------------------------------------------------------------------
copybank_raro:
	ld a,(ROMBANK)			; get rom bank
	out (O_ROM_BANK),a		; set rom bank
	ld a,(ROMCHIP)			; load rom chip to read from; value in c is retained
	ld c,a					; throughout this whole function
	ld a,h					; set counter
	ld ixh,a
	ld a,l
	ld ixl,a
	ld hl,0					; set RAM address (fixed to start at 0)
.next:
	ex de,hl				; RAM address in de
	call ramrecvde			; read byte from RAM in a from address de
	ex de,hl				; ROM address in de
	call sst39sfwrbyteacc	; write byte from a into address de
	inc de					; increment ROM address
	inc hl					; increment RAM address
	dec ix					; decrement counter
	ld a,ixh
	or ixl					; check if zero
	jp nz,.next				; if not, next byte
	ret