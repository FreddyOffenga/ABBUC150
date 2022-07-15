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
current_dl_ptr  = $f6
last_dl_ptr     = $f8

; ABBUC 150

        org $2000

IMAGE_COUNT = 4
IMAGE_WIDTH = 40        ; bytes
IMAGE_HEIGHT = 102      ; scanlines

; add a to target
add_target
        clc
        adc target
        sta target
        lda target+1
        adc #0
        sta target+1
        rts

; add a to source
add_source
        clc
        adc source
        sta source
        lda source+1
        adc #0
        sta source+1
        rts

reset_current_dl_ptr
        lda #<scanline_tab
        sta current_dl_ptr
        lda #>scanline_tab
        sta current_dl_ptr+1
        rts
        
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

; store last_dl_ptr, points to first scanline of last processed image
        lda target
        sta last_dl_ptr
        lda target+1
        sta last_dl_ptr+1
    
        lda #IMAGE_HEIGHT
        sta line_count

copy_line_ptrs
        ldy #0

        lda source
        sta (target),y
        lda source+1
        iny
        sta (target),y

        lda #2
        jsr add_target
        
        lda #IMAGE_WIDTH
        jsr add_source
        
        dec line_count
        bne copy_line_ptrs

        ldx image_number
        inx
        cpx #IMAGE_COUNT
        bne next_image

        rts

insert_image_dl
        lda current_dl_ptr
        sta source
        lda current_dl_ptr+1
        sta source+1

        ldx #0
        ldy #0

insert_p1
        lda #$4e
        sta dlist_image,x
        lda (source),y
        sta dlist_image+1,x
        iny
        lda (source),y
        sta dlist_image+2,x
        iny 
        
        inx
        inx
        inx
        
        cpy #80*2         ; first part
        bne insert_p1 

        lda #2*80
        jsr add_source
        
        ldx #0
        ldy #0

insert_p2
        lda #$4e
        sta dlist_image+(3*80),x
        lda (source),y
        sta dlist_image+(3*80)+1,x
        iny
        lda (source),y
        sta dlist_image+(3*80)+2,x
        iny 
        
        inx
        inx
        inx
                
        cpy #22*2         ; second part
        bne insert_p2

        rts
        
main
        jsr make_scanline_ptrs

        jsr reset_current_dl_ptr
        jsr insert_image_dl

        lda #6
        ldx #>vbi
        ldy #<vbi
        jsr SETVBV
        
        lda #$c0        ; Enable DLI
        sta NMIEN

wait
        lda CONSOL
        cmp #6                  ; Wait for START
        bne wait

        lda #$40
        sta NMIEN

        lda #6
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

vbi
        lda #34
        sta $d01a

        mwa #dlist DLISTL
        mwa #dli0 VDSLST

        jsr insert_image_dl
        
        lda current_dl_ptr
        clc
        adc #2
        sta current_dl_ptr
        lda current_dl_ptr+1
        adc #0
        sta current_dl_ptr+1

        lda current_dl_ptr
        cmp last_dl_ptr
        bne not_last_image
        lda current_dl_ptr+1
        cmp last_dl_ptr+1
        bne not_last_image
        
        jsr reset_current_dl_ptr

not_last_image

        lda #0
        sta $d01a

        jmp XITVBV

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
;        dta DL_GR15 | DL_LMS | DL_DLI   ; ce

;logo
;        dta a(lPOKEY)

;:101    dta DL_GR15

dlist_image
; space for image DL (102 x 3)
:102*3  dta 0

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

; first entry must repeat in last entry to generate extra scanlines for vertical scrolling
image_tab_lo
        dta <lABBUC
        dta <lPOKEY
        dta <lSAG
        dta <lABBUC

image_tab_hi
;        dta >lABBUC
        dta >lABBUC
        dta >lPOKEY
        dta >lSAG
        dta >lABBUC

; image data

        .align $1000
lABBUC
        ins 'abbuc.raw'

        .align $1000
lSAG
        ins 'sag.raw'

        .align $1000
lPOKEY
        ins 'pokey.raw'

        .align $1000

scanline_tab = *

        run main
