SECTION code_user

ADDR_LOW    EQU  $60
ADDR_HIGH   EQU  $61
ROMINT      EQU  $62
ROMBANK     EQU  $63
ROMEXT      EQU  $65

PUBLIC _copybank0
PUBLIC _calculatecrc16

;-------------------------------------------------------------------------------
; Copy $0000 - $3FFF from external ROM
; to internal ROM
;-------------------------------------------------------------------------------
_copybank0:
    ld bc,$4000
    ld de,$0000
    ld hl,$0000
    di
copybank_nextbyte:
    push bc                        ; free up bc to be used in the routines below
    call sst39sfrecv_external      ; load value from external rom addr hl into a
    call sst39sfwrbyte_internal    ; send value to internal rom addr de from a
    pop bc
    inc de
    inc hl
    dec bc
    ld a,b
    or c
    jp nz,copybank_nextbyte
    ei
    ret

_calculatecrc16:
    ld hl,$0000                     ; start external address
    ld b,4
    ld c,$00
nextpage:
    push bc                         ; store page counter
    ld de,$8000                     ; destination address in ram
    ld bc,$1000
calculatecrc16_nextbyte:
    call sst39sfrecv_internal
    ld (de),a
    inc hl
    inc de
    dec bc
    ld a,b
    or c
    jr nz,calculatecrc16_nextbyte
    push hl
    ld bc,$1000
    ld de,$0000
    ld hl,$8000
    call crc16                      ; checksum in de
    pop hl                          ; restore rom counter
    pop bc                          ; restore page counter
    push hl                         ; store rom counter
    ld h,$90                        ; set upper byte memory
    ld a,c                          ; load counter
    ld l,a                          ; set lower address
    ld (hl),d                       ; store upper byte checksum in memory
    inc hl                          ; next address
    ld (hl),e                       ; store lower byte checksum in memory
    inc c                           ; increment storage address by 2
    inc c
    pop hl                          ; restore rom counter
    djnz nextpage                   ; next page
    ret

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
bytelp:
    push bc                     ; push counter onto stack
    ld a,(hl)                   ; fetch byte
    xor d                       ; xor byte into CRC top byte
    ld b,8                      ; prepare to rotate 8 bits
rotlp:
    sla e                       ; rotate crc
    adc a,a
    jp nc,clear                 ; bit 15 was zero
    ld d,a                      ; put crc high byte back into d
    ld a,e                      ; crc = crc ^ $1021 (xmodem polynomic)
    xor $21
    ld e,a
    ld a,d                      ; get crc top byte back into a
    xor $10
clear:
    dec b                       ; decrement bit counter
    jp nz,rotlp                 ; loop for 8 bits
    ld d,a                      ; put crc top byte back into d
    inc hl                      ; step to next byte
    pop bc                      ; get counter back from stack
    dec bc                      ; decrement counter
    ld a,b                      ; check if counter is zero
    or c
    jp nz,bytelp               ; if not zero, go to next byte
    ret

;-------------------------------------------------------------------------------
; Receive a byte from external SST39SF0x0 chip
;        hl - chip address
; output: a - byte at address
;        hl - chip address
;-------------------------------------------------------------------------------
sst39sfrecv_external:
    ld a,l
    out (ADDR_LOW),a
    ld a,h
    out (ADDR_HIGH),a
    in a,(ROMEXT)
    ret

;-------------------------------------------------------------------------------
; Receive a byte from internal SST39SF0x0 chip
;        hl - chip address
; output: a - byte at address
;        hl - chip address
;-------------------------------------------------------------------------------
sst39sfrecv_internal:
    ld a,l
    out (ADDR_LOW),a
    ld a,h
    out (ADDR_HIGH),a
    in a,(ROMINT)
    ret

;-------------------------------------------------------------------------------
; Send a byte to SST39SF0x0 chip
; input: de - chip address
;         a - byte to send
; uses: a,b
; fixed: de
;-------------------------------------------------------------------------------
sst39sfsend_internal:
    ld b,a
    ld a,e
    out (ADDR_LOW),a
    ld a,d
    out (ADDR_HIGH),a
    ld a,b
    out (ROMINT),a
    ret

;-------------------------------------------------------------------------------
; Write a single byte from accumulator
; input:  de - chip address
;          a - byte to write
; uses: a,b
; fixed: de
;-------------------------------------------------------------------------------
sst39sfwrbyte_internal:
    push de
    ld c,a
    ld de,$5555
    ld a,$AA
    call sst39sfsend_internal
    ld de,$2AAA
    ld a,$55
    call sst39sfsend_internal
    ld de,$5555
    ld a,$A0
    call sst39sfsend_internal
    pop de
    ld a,c
    call sst39sfsend_internal
    ret
