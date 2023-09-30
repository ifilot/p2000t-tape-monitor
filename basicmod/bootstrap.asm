;-----------------------------------------------------
; bootstrap.asm
;
; Upon the first keyboard parse routine of the basic
; rom, executes the code located at $4EE0. This will
; modify a few pointers and loads in the code from
; the I/O port to ADDR EXCODE and launches it from there.
;
;-----------------------------------------------------

;-----------------------------------------------------
; VARIABLES
;-----------------------------------------------------
EXCODE:         EQU $7000       ; address to put and launch external code from
IO_ROMEX1:      EQU $62         ; internal ROM
IO_ROMEX2:      EQU $65         ; external ROM
IO_RAMEX:       EQU $64         ; external RAM
IO_AL:          EQU $60         ; address low
IO_AH:          EQU $61         ; address high
IO_BANK:        EQU $63         ; address bank
NUMBYTES:       EQU $2500
PROGADDR:       EQU $0000

;-----------------------------------------------------
; CODE INJECTION PART
;-----------------------------------------------------
	; This part is injected into the standard BASIC cartridge
	; starting at $4EE0
    org $4EE0
	
    ; store bootstrap enable launch code  
    ld a,$55
    ld ($6150),a
    
    ; store byte character for jump
    ld a,$C3
    ld ($6151),a   

    ; store loadcode pointer (will be executed after rom boot)
    ld hl,loadcode
    ld ($6152),hl
    
    ; continue with normal execution of the ROM startup
    jp $1f5a

;-----------------------------------------------------
; OTHER CODE
;
; Load code from I/O port and launch the code
;
; bc - number of bytes
; de - start location on ROM
; hl - destination in RAM
;
;-----------------------------------------------------
loadcode:
    ld a,0
    ld ($6150),a        ; disable bootstrap routine
    call clrscrn
    call printmsg
    di
    ld a,0
    out (IO_BANK),a     ; set to bank 0

    ; load number of bytes from internal ram
    ld hl,EXCODE                    ; location where to write
    ld de,PROGADDR                  ; location where to read
.nextbyte:
    call read_rom
    ld (hl),a
    inc hl
    inc de
    dec bc
    ld a,b
    or c
    jr nz,.nextbyte
    ei
    call EXCODE
    jp loadrom

loadrom:
    call clrscrn
    ld de,$8000-2
    call read_ram
    ld de,$5000
    call printhex
    ld de,$8000-1
    call read_ram
    ld de,$5002
    call printhex
.loop:
    jr .loop

;-----------------------------------------------------
; clear the screen
;-----------------------------------------------------
clrscrn:
    ld a,0 ; load 0 into first byte
    ld ($5000),a
    ld de,$5001
    ld bc,$1000
    dec bc
    ld hl,$5000
    ldir ; copy next byte from previous
    ret

;-----------------------------------------------------
; Load message to screen
;-----------------------------------------------------
message:
    DB "Test loading external code...",255

printmsg:
    call clrscrn
    ld hl,message
    ld bc,$5000
print:
    ld a,(hl)
    cp 255
    ret z
    ld (bc),a
    inc hl
    inc bc
    jp print

;-----------------------------------------------------
; go into infinite loop
;-----------------------------------------------------
loop:
    jp loop

;-----------------------------------------------------
; Reads a byte from the I/O port and put it in reg A.
; The address stored at IOREADADDR is used as the load
; address for the I/O port. Upon loading a byte, this
; address is incremented and stored back into the storage
; location.
;
; input: (IOREADADDR) I/O port address to read code from
;  uses: a,de
;
;-----------------------------------------------------
read_rom:
    ld a,d
    out (IO_AH),a         ; store upper bytes in register
    ld a,e
    out (IO_AL),a         ; store lower bytes in register
    in a,(IO_ROMEX1)      ; load byte
    ret

;-----------------------------------------------------
; read a byte to external ram
;
;  a - byte to write
; de - address
;-----------------------------------------------------
read_ram:
    ld a,d
    out (IO_AH),a         ; store upper bytes in register
    ld a,e
    out (IO_AL),a         ; store lower bytes in register
    in a,(IO_RAMEX)       ; load byte
    ret

;-----------------------------------------------------
; write a byte to external ram
;
;  a - byte to write
; hl - address
;-----------------------------------------------------
write_ram:
    ld ixl,a
    ld a,h
    out (IO_AH),a         ; store upper bytes in register
    ld a,l
    out (IO_AL),a         ; store lower bytes in register
    ld a,ixl
    out (IO_RAMEX),a      ; write byte
    ret

;-----------------------------------------------------
; printhex subroutine
;
; input: a  - value to print
;        de - video memory address
; uses:  a,iyh
; output: de - new cursor position of video address
;-------------------------------------------------------------------------------
printhex:
    ld iyh,a                ; load value into b
    rra                     ; shift right by 4, ignore leaving bits
    rra
    rra
    rra
    and $0f                 ; mask
    call printnibble        ; print upper nibble
    ld a,iyh                ; reload value to print
    and $0f                 ; mask
    call printnibble        ; print lower nibble
    ret

;-------------------------------------------------------------------------------
; printnibble subroutine
;
; input: a  - value to print
;        de - video memory address
; uses:  a
; output: de - new cursor position of video address
;-------------------------------------------------------------------------------
printnibble:
    add $30                 ; add $30 to number in a
    cp $3A                  ; less than $3A?
    jp c,.print             ; if so, number between 0-9, so print it
    add 7                   ; if not, number between A-F, so add 7
.print:
    ld (de),a               ; load accumulator into (de)
    inc de                  ; increment video position
    ret