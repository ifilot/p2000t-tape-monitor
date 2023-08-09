;-------------------------------------------------------------------------------
; Generate a 16 bit checksum
; 
; input:  bc - number of bytes
;         de - starting checksum (typically $0000)
;         hl - start of memory address
; output: de - crc16 checksum
; uses: a, bc, de, hl
;
; source: https://mdfs.net/Info/Comp/Comms/CRC16.htm
;-------------------------------------------------------------------------------
crc16:
.bytelp:
	push bc						; push counter onto stack
	ld a,(hl)					; fetch byte
	xor d						; xor byte into CRC top byte
	ld b,8						; prepare to rotate 8 bits
.rotlp:
	sla e						; rotate crc
	adc a,a
	jp nc,.clear				; bit 15 was zero
	ld d,a						; put crc high byte back into d
	ld a,e						; crc = crc ^ $1021 (xmodem polynomic)
	xor $21
	ld e,a
	ld a,d						; get crc top byte back into a
	xor $10
.clear:
	dec b						; decrement bit counter
	jp nz,.rotlp				; loop for 8 bits
	ld d,a						; put crc top byte back into d
	inc hl						; step to next byte
	pop bc						; get counter back from stack
	dec bc						; decrement counter
	ld a,b						; check if counter is zero
	or c
	jp nz,.bytelp				; if not zero, go to next byte
	ret