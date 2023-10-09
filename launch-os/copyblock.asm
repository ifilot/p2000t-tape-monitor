SECTION code_user

PUBLIC _copyblock

ADDR_LOW  EQU $60
ADDR_HIGH EQU $61
RAMCHIP   EQU $64
ROMCHIP   EQU $65

_copyblock:
    di
    pop bc                  ; return address
    pop de                  ; ramptr
    pop hl                  ; romptr
    push bc                 ; put return address back on stack
    ld bc,$400
cpnextbyte:
    ld a,h
    out (ADDR_HIGH),a       ; write rom high address
    ld a,l
    out (ADDR_LOW),a        ; write rom low address
    in a,(ROMCHIP)          ; read from rom chip
    push af                 ; store result on stack
    ld a,d
    out (ADDR_HIGH),a       ; write ram high address
    ld a,e
    out (ADDR_LOW),a        ; write ram low address
    pop af                  ; retrieve value from stack
    out (RAMCHIP),a         ; write byte to ram
    inc de                  ; increment ram pointer
    inc hl                  ; increment rom pointer
    dec bc                  ; decrement counter
    ld a,b
    or c
    jp nz,cpnextbyte
    ret
