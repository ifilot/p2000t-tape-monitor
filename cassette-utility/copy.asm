SECTION code_user

ADDR_LOW    EQU  $60
ADDR_HIGH   EQU  $61
ROMINT      EQU  $62
ROMBANK     EQU  $63
ROMEXT      EQU  $65

PUBLIC _copyblock_ram_rom
PUBLIC _copyheader_ram_rom

_copyblock_ram_rom:
    di
    pop bc                  ; return address
    pop hl                  ; ramptr
    pop de                  ; romptr
    push bc                 ; put return address back on stack
    ld bc,$400
nextbyte1:
    push bc                 ; put counter on stack
    call sst39sfwrbytemem   ; write byte to rom chip
    inc de                  ; increment ramptr
    inc hl                  ; increment romptr
    pop bc                  ; retrieve counter from stack
    dec bc                  ; decrement counter
    ld a,b
    or c
    jp nz,nextbyte1         ; if not zero, go to next byte
    ei
    ret

_copyheader_ram_rom:
    di
    pop bc                  ; return address
    pop hl                  ; ramptr
    pop de                  ; romptr
    push bc                 ; put return address back on stack
    ld bc,$20
nextbyte2:
    push bc                 ; put counter on stack
    call sst39sfwrbytemem   ; write byte to rom chip
    inc de                  ; increment ramptr
    inc hl                  ; increment romptr
    pop bc                  ; retrieve counter from stack
    dec bc                  ; decrement counter
    ld a,b
    or c
    jp nz,nextbyte2         ; if not zero, go to next byte
    ei
    ret

;-------------------------------------------------------------------------------
; Write a single byte at address
; input:  de - chip address
;         hl - address of byte to be written
;
; uses: a,b,de,h
; output: de - rom address
;         hl - source address
;-------------------------------------------------------------------------------
sst39sfwrbytemem:
    push de             ; store rom address
    ld de,$5555
    ld b,$AA
    call sst39sfsend
    ld de,$2AAA
    ld b,$55
    call sst39sfsend
    ld de,$5555
    ld b,$A0
    call sst39sfsend
    pop de              ; retrieve rom address
    ld b,(hl)           ; load byte to be written
    call sst39sfsend
    ret

;-------------------------------------------------------------------------------
; Send a byte to SST39SF0x0 chip
; input: de - chip address
;         b - byte to send
; uses: a
; fixed: de
;-------------------------------------------------------------------------------
sst39sfsend:
    ld a,e
    out (ADDR_LOW),a
    ld a,d
    out (ADDR_HIGH),a
    ld a,b
    out (ROMEXT),a
    ret
