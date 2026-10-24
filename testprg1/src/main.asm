.p816
.smart

INIDISP   = $2100
CGADD     = $2121
CGDATA    = $2122

.segment "HEADER"
    .byte "SNES HELLO WORLD   "   ; 21 bytes ROM name
    .byte $30                    ; LoROM, fast-capable
    .byte $00                    ; Cartridge type (ROM only)
    .byte $07                    ; ROM size (128 KB)
    .byte $00                    ; RAM size (0)
    .byte $01                    ; Destination (USA)
    .byte $33                    ; Fixed value
    .byte $00                    ; Version
    .word $0000                  ; Checksum complement
    .word $0000                  ; Checksum

.segment "VECTORS"
    ; Native Mode vectors (We can leave them blank/zero for a simple polling test)
    .word 0, 0, 0, 0, 0, 0, 0, 0
    
    ; Emulation Mode vectors (Reset vector points to our init routine)
    .word 0, 0, 0, 0, 0, reset, 0, reset

.segment "CODE"
.proc reset
    sei                ; Disable interrupts
    clc                ; Clear carry
    xce                ; Enter 65816 Native Mode

    sep #$30           ; 8-bit accumulator and index registers

    ; 1. Turn on Forced Blanking while updating palette
    lda #$80
    sta INIDISP

    ; 2. Set palette color 0 (backdrop) to medium green ($01E0)
    stz CGADD          ; CGRAM address 0
    lda #$E0           ; Low byte of medium green
    sta CGDATA
    lda #$01           ; High byte of medium green
    sta CGDATA

    ; 3. Turn on display (medium brightness #$07, blanking off)
    lda #$07
    sta INIDISP

@loop:
    ; Manual VBLANK polling loop (Simple & safe)
@wait_vblank:
    lda $4212          ; Read PPU status register
    and #$80           ; Check bit 7 (VBLANK status)
    beq @wait_vblank   ; If bit 7 is 0, keep waiting

    bra @loop          ; Loop forever
.endproc