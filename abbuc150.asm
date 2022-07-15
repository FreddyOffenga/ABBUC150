/*
** COMPILE:
** # Windows
** "c:\Program Files (x86)\MADS\mads.exe" -i:inc\ -o:xex\filename.xex filename.asm
**
** # Linux / OSX
** mads -i:inc/ -o:xex/filename.xex filename.asm
*/

        icl "inc/systemequates.20070530_bkw.inc"            ; Don't forget the specify -i:<path to file> at compile time

source          = $f0
target          = $f2
line_count      = $f4
image_number    = $f5

scanline_tab    = $8000

; ABBUC 150

        org $3010

lABBUC
        ins 'abbuc.raw'

        .align $1010

        org $4010
lSAG
        ins 'sag.raw'

        org $5010
lPOKEY
        ins 'pokey.raw'

        org $2000

image_tab_lo
        dta <lABBUC
        dta <lSAG
        dta <lPOKEY

image_tab_hi
        dta >lABBUC
        dta >lSAG
        dta >lPOKEY

IMAGE_COUNT = 2         ; image tab size
IMAGE_WIDTH = 40        ; bytes
IMAGE_HEIGHT = 102      ; scanlines

make_scanline_ptrs
        lda #<scanline_tab
        sta target
        lda #>scanline_tab
        sta target+1

        ldx #0

next_image
        stx image_number

        lda image_tab_lo,x
        sta source
        lda image_tab_hi,x
        sta source+1

        lda #IMAGE_HEIGHT
        sta line_count

copy_line_ptrs
        ldy #0

        lda source
        sta (target),y
        lda source+1
        iny
        sta (target),y

        lda target
        clc
        adc #2
        sta target
        lda target+1
        adc #0
        sta target+1

        lda source
        clc
        adc #IMAGE_WIDTH
        sta source
        lda source+1
        adc #0
        sta source+1

        dec line_count
        bne copy_line_ptrs

        ldx image_number
        inx
        cpx #IMAGE_COUNT
        bne next_image

        rts

main
        jsr make_scanline_ptrs

        lda #0
        sta COLBK
        sta COLOR1
        sta COLOR2
        sta COLOR3
        sta COLOR4

        mwa #dli0 VDSLST
        mwa #dlist SDLSTL

        lda #$c0        ; Enable DLI
        sta NMIEN

wait
        lda CONSOL
        cmp #6                  ; Wait for START
        bne wait

; Next part
        mwa #lSAG logo
        mwa #tSAG title
        jmp wait

        lda #$40
        sta NMIEN

        lda #6                  ; Restore Immediate VBlank 
        ldx #$e4
        ldy #$5f
        jsr SETVBV

        lda #0
        sta COLOR0
        sta COLOR1
        sta COLOR2
        sta COLBK
        sta AUDC1
        sta AUDC2
        sta AUDC3
        sta AUDC4
        sta IRQST
        sta DMACTL
        sta NMIEN
        lda #$ff
        sta PORTB

        jmp *

        rts
// END: main

dli0    pha
        lda #0
        sta COLPF2
        lda #10
        sta COLPF1
        pla
        rti

        .align $4000

dlist
:3      dta DL_BLANK8                   ; 70
        dta DL_GR15 | DL_LMS | DL_DLI   ; ce

logo
        dta a(lPOKEY)

:101    dta DL_GR15
        dta DL_BLANK7 | DL_DLI
        dta DL_GR0 | DL_LMS

title
        dta a(tABBUC)
                
        dta DL_JVB

        dta a(dlist)

tABBUC
        dta d'       Atari Bit Byters User Club       '
tSAG
        dta d'       Stichting Atari Gebruikers       '
tPOKEY
        dta d'            Stichting Pokey             '

        run main
