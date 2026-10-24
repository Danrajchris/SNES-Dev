.p816
.smart

; --- SNES Hardware Registers ---
INIDISP   = $2100
BGMODE    = $2105
BG1SC     = $2107          ; BG1 Screen Base & Size
BG12NBA   = $210B          ; BG1/BG2 Tile Data Base
VMAINC    = $2115
VMADDL    = $2116
VMADDH    = $2117
CGADD     = $2121
CGDATA    = $2122
TM        = $212C

; --- DMA Registers (Channel 0) ---
DMAP0     = $4300
BBAD0     = $4301
A1T0L     = $4302
A1T0H     = $4303
A1B0      = $4304
DAS0L     = $4305
DAS0H     = $4306
MDMAEN    = $420B

.segment "HEADER"
    .byte "MY SNES TILE1"   
    .byte $30                    
    .byte $00                    
    .byte $05                    
    .byte $00                    
    .byte $01                    
    .byte $33                    
    .byte $00                    
    .word $0000                  
    .word $0000                  

.segment "VECTORS"
    ; Native Mode Vectors ($FFE0 - $FFEF) - 16 bytes
    .word 0, 0, 0, 0, 0, 0, 0, 0
    
    ; Emulation Mode Vectors ($FFF0 - $FFFF) - 16 bytes
    ; $FFF0, $FFF2, $FFF4, $FFF6, $FFF8, $FFFA (NMI), $FFFC (RESET), $FFFE (IRQ)
    .word 0, 0, 0, 0, 0, 0, reset, 0

.segment "CODE"
.proc reset
    sei                
    clc                
    xce                

    sep #$30           ; 8-bit A, 8-bit Index registers

    ; 1. Forced Blanking ON
    lda #$80
    sta INIDISP

    ; 2. VRAM Address Increment (+1 word after $2119 write)
    lda #$80
    sta VMAINC

    ; =========================================================================
    ; 3. DMA TRANSFER: TILE GRAPHICS (`GFX00.bin`) TO VRAM $0000
    ; =========================================================================
    stz VMADDL         
    stz VMADDH         

    lda #$01           ; Transfer mode 1 (write $2118, then $2119)
    sta DMAP0
    lda #$18           ; Target: VRAM Data Write ($2118)
    sta BBAD0

    lda #<tile_graphics
    sta A1T0L
    lda #>tile_graphics
    sta A1T0H
    lda #^tile_graphics
    sta A1B0

    lda #<$0800        ; Transfer 2048 bytes
    sta DAS0L
    lda #>$0800
    sta DAS0H

    lda #$01           ; Trigger DMA Channel 0
    sta MDMAEN

   ; =========================================================================
    ; 4. DMA TRANSFER: TILEMAP TO VRAM $0800 (Matching BG1SC = #$08)
    ; =========================================================================
    lda #$00           
    sta VMADDL
    lda #$08           ; VRAM Word Address = $0800
    sta VMADDH

    lda #$01           ; Re-arm DMA Channel 0
    sta DMAP0
    lda #$18           
    sta BBAD0

    lda #<tilemap_data
    sta A1T0L
    lda #>tilemap_data
    sta A1T0H
    lda #^tilemap_data
    sta A1B0

    lda #<$0800        ; Transfer 2048 bytes (32x32 tiles * 2 bytes)
    sta DAS0L
    lda #>$0800
    sta DAS0H

    lda #$01           ; Trigger DMA Channel 0
    sta MDMAEN

    ; =========================================================================
    ; 5. WRITE PALETTE DATA TO CGRAM (16 Colors in 16-bit Mode)
    ; =========================================================================
    stz CGADD          ; Start at CGRAM index 0
    
    rep #$20           ; Switch Accumulator to 16-bit mode
    ldx #$00
@load_palette:
    lda palette_data, x
    sta CGDATA         ; Writes full 16-bit color word atomically
    inx
    inx                ; Advance index by 2 bytes per word
    cpx #32            ; 16 colors * 2 bytes = 32 bytes total
    bne @load_palette

    sep #$20           ; Switch Accumulator back to 8-bit mode

    ; =========================================================================
    ; 6. CONFIGURE PPU REGISTERS
    ; =========================================================================
    lda #$01           ; Mode 1 (4BPP BG1)
    sta BGMODE

    lda #$08           ; BG1 Tilemap Address = $1000 (Size = 32x32)
    sta BG1SC

    lda #$00           ; BG1 Tile Graphics Address = $0000
    sta BG12NBA

    lda #$01           ; Enable BG1 on Main Screen ($212C)
    sta TM

    ; 7. Forced Blanking OFF (Display on at max brightness)
    lda #$0F
    sta INIDISP

@loop:
    lda $4212          ; Wait for VBLANK
    and #$80           
    beq @loop          

    bra @loop          
.endproc

.segment "RODATA"
tile_graphics:
    .incbin "GFX00.bin"

; 16-color SNES 15-bit BGR palette (Palette Row 0)
palette_data:
    .word $01E0        ; Color 0: Dark Green Backdrop
    .word $7FFF        ; Color 1: White
    .word $0000        ; Color 2: Black
    .word $001F        ; Color 3: Red
    .word $03E0        ; Color 4: Green
    .word $7C00        ; Color 5: Blue
    .word $03FF        ; Color 6: Yellow
    .word $7C1F        ; Color 7: Magenta
    .word $7FFF        ; Color 8: White
    .word $39CE        ; Color 9: Light Gray
    .word $2108        ; Color 10: Dark Gray
    .word $01FF        ; Color 11: Orange
    .word $0200        ; Color 12: Dark Blue
    .word $000F        ; Color 13: Dark Red
    .word $02E0        ; Color 14: Cyan
    .word $5AD6        ; Color 15: Bright Yellow

; Tilemap: Top rows draw the Nintendo Presents logo from GFX00, remaining grid is blank
tilemap_data:
    ; Row 0: Tiles 0 to 31
    .repeat 32, i
        .word i
    .endrepeat

    ; Row 1: Tiles 32 to 63
    .repeat 32, i
        .word i + 32
    .endrepeat

    ; Row 2: Tiles 64 to 95
    .repeat 32, i
        .word i + 64
    .endrepeat

    ; Remaining rows filled with blank tiles
    .repeat 1024 - 96
        .word $0000
    .endrepeat