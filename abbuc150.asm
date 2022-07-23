; ABBUC 150 intro

/*
** COMPILE:
** # Windows
** "c:\Program Files (x86)\MADS\mads.exe" -i:inc\ -o:xex\filename.xex filename.asm
**
** # Linux / OSX
** mads -i:inc/ -o:xex/filename.xex filename.asm
*/

        icl "inc/systemequates.20070530_bkw.inc"            ; Don't forget the specify -i:<path to file> at compile time

source              = $f0
target              = $f2
line_count          = $f4
image_number        = $f5
current_dl_ptr      = $f6
last_dl_ptr         = $f8
is_image_moving     = $fa
image_scrol_count   = $fb
image_clock         = $fc   ; and $fd

; ABBUC 150

        org $2000

IMAGE_COUNT = 6
IMAGE_WIDTH = 40        ; bytes
IMAGE_HEIGHT = 102      ; scanlines

main
        jsr make_scanline_ptrs
        
        jsr make_color_tables
        
        jsr reset_current_dl_ptr
        
        jsr insert_image_dl

; init
        lda #0
        sta 20
        sta is_image_moving
        sta image_scrol_count
        sta image_clock

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

reset_colors
        lda #<color0_tab
        sta color0_ptr
        lda #>color0_tab
        sta color0_ptr+1
        
        lda #<color1_tab
        sta color1_ptr
        lda #>color1_tab
        sta color1_ptr+1
        
        lda #<color2_tab
        sta color2_ptr
        lda #>color2_tab
        sta color2_ptr+1

        lda #<color3_tab
        sta color3_ptr
        lda #>color3_tab
        sta color3_ptr+1
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

; make all color tables

make_color_tables
        ldx #0
all_colors
        txa
        pha
        
        lda image_colors_lo,x
        sta source
        lda image_colors_hi,x
        sta source+1
        
        lda color_tab_lo,x
        sta target
        lda color_tab_hi,x
        sta target+1
        
        jsr fill_one_table

        pla
        tax
        inx
        cpx #4
        bne all_colors
        
; raster colors for ABBUC

        ldx #0
try_abbuc_colors
        lda raster_abbuc,x
        sta color1_tab_ABBUC,x
        inx
        cpx #IMAGE_HEIGHT
        bne try_abbuc_colors
        
        rts        

raster_abbuc
        dta $12,$14,$16,$18,$1a,$1c,$0e,$0e
        dta $20,$22,$24,$26,$28,$2a,$2c,$2e,$0e,$0e
        dta $50,$52,$54,$56,$58,$5a,$5c,$5e,$0e,$0e
        dta $70,$72,$74,$76,$78,$7a,$7c,$7e,$0e,$0e
        dta $80,$82,$84,$86,$88,$8a,$8c,$8e,$0e,$0e
        dta $b0,$b2,$b4,$b6,$b8,$ba,$bc,$be,$0e,$0e
        dta $d0,$d2,$d4,$d6,$d8,$da,$dc,$de,$0e,$0e
        dta $f0,$f2,$f4,$f6,$f8,$fa,$fc,$fe,$0e,$0e
        
        dta $04,$04,$04,$04,$04,$04,$04,$04
        dta $08,$08,$08,$08,$08,$08,$08,$08
        dta $04,$04,$04,$04,$04,$04,$04,$04
        dta $08,$08,$08,$08,$08,$08,$08,$08

        dta $04,$04,$04,$04,$04,$04
        

fill_one_table
        ldy #0
more_to_fill
        tya
        pha
        lda (source),y
        
        ldy #0
fill_colors        
        sta (target),y
        iny
        cpy #IMAGE_HEIGHT
        bne fill_colors

        lda #IMAGE_HEIGHT
        jsr add_target
        
        pla
        tay
        iny
        cpy #IMAGE_COUNT
        bne more_to_fill
                
        rts

vbi
; end of raster colors
        lda #0
        sta COLBK
        sta COLPF0
        sta COLPF1
        sta COLPF2
;        lda #34
;        sta $d01a

        lda #>megafont
        STA CHBASE

        lda #0
        sta CHACTL
        
        lda 20
        and #7
        bne no_course
                
        inc scrol_ptr1
        bne no_hi_scrol
        inc scrol_ptr1+1
no_hi_scrol

        lda scrol_ptr1
        cmp #<scroltext_end
        bne no_end_scrol
        lda scrol_ptr1+1
        cmp #>scroltext_end
        bne no_end_scrol
        
        lda #<scroltext
        sta scrol_ptr1
        lda #>scroltext
        sta scrol_ptr1+1

no_end_scrol
        lda scrol_ptr1
        sta scrol_ptr2
        lda scrol_ptr1+1
        sta scrol_ptr2+1

        lda #0
no_course
        eor #7
        sta HSCROL

        inc 20
        
        inc image_clock
        bne no_hi_clock
        inc image_clock+1
no_hi_clock

        mwa #dlist DLISTL
        mwa #dli0 VDSLST

        jsr insert_image_dl

        lda is_image_moving
        bne move_image
       
; pause
        lda image_clock+1
        and #1
        beq skip_moving
        
        lda #1
        sta is_image_moving     

move_image        
        inc color0_ptr
        bne nh_c0
        inc color0_ptr+1
nh_c0

        inc color1_ptr
        bne nh_c1
        inc color1_ptr+1
nh_c1

        inc color2_ptr
        bne nh_c2
        inc color2_ptr+1
nh_c2

        inc color3_ptr
        bne nh_c3
        inc color3_ptr+1
nh_c3
        
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
        jsr reset_colors

not_last_image
        inc image_scrol_count
        lda image_scrol_count
        cmp #IMAGE_HEIGHT
        bne keep_moving
        
        lda #0
        sta is_image_moving
        lda #0
        sta image_clock
        sta image_clock+1
        sta image_scrol_count

keep_moving

skip_moving
        lda #0
        sta $d01a

        jmp XITVBV

; @todo 
; should change the color0_tab address here in the VBI
; color0_tab should point to the color of the current (first) scanline in the DL image
; each color should use their own colorX_tab

dli0    pha
        txa
        pha
        tya
        pha
        
        sta WSYNC
        ldx #0
rasters
color1_ptr  = *+1
        lda color1_tab,x
        tay
color0_ptr  = *+1         
        lda color0_tab,x
        sta WSYNC
        sta COLBK
        sty COLPF0

color2_ptr  = *+1
        lda color2_tab,x
        sta COLPF1
color3_ptr  = *+1
        lda color3_tab,x
        sta COLPF2

        inx
        cpx #IMAGE_HEIGHT-1
        bne rasters

; end of raster colors
        lda #0
        sta WSYNC
        sta COLBK
        sta COLPF0
        sta COLPF1
        sta COLPF2

        mwa #dli1 VDSLST

        pla
        tay
        pla
        tax
        pla
        rti

dli1    pha
        txa
        pha
 
        ldx #0
rasta
        lda scrol_raster,x
        sta WSYNC
        sta COLPF0
        lda VCOUNT
        adc 20
        lsr
;        lda highlight_raster,x
        sta COLPF1
        inx
        cpx #16
        bne rasta

        lda #4
        sta CHACTL
        
        ldx #15
rasta2
        lda scrol_raster,x
        sta WSYNC
        and #$0f
        sta COLPF0
        sta COLPF1
        dex
        dex
        bpl rasta2

        mwa #dli2 VDSLST

        pla
        tax
        pla
        rti

dli2
        pha
        txa
        pha
        
        ldx #0
        stx COLPF0
do_sky
        lda skyline_raster,x
        sta WSYNC
        sta COLBK
        inx
        cpx #64
        bne do_sky
        
        pla
        tax        
        pla
        rti

skyline_raster
        dta $70,$70,$70,$70,$70,$70,$70,$70
        dta $62,$60,$62,$60,$62,$60,$62,$60
        dta $54,$50,$54,$50,$54,$50,$54,$50
        dta $46,$40,$46,$40,$46,$40,$46,$40

        dta $38,$30,$38,$30,$38,$30,$38,$30
        dta $2a,$20,$2a,$20,$2a,$20,$2a,$20
        dta $1c,$10,$1c,$10,$1c,$10,$1c,$10
        dta $de,$d2,$de,$d2,$de,$d2,$de,$00
        
scrol_raster
        dta $00,$22,$24,$26
        dta $28,$2a,$0c,$0e
        dta $0e,$0c,$8a,$88
        dta $86,$84,$82,$00

highlight_raster
        dta $00,$02,$04,$06
        dta $08,$0a,$2c,$2e
        dta $2e,$2c,$da,$d8
        dta $d6,$d4,$d2,$00

        .align $400

dlist
        dta DL_BLANK8                   ; 70
        dta DL_BLANK8 | DL_DLI          ; dli0

dlist_image
; space for image DL (102 x 3)
:102*3  dta 0

        dta DL_BLANK8 | DL_DLI          ; dli1
        
        dta DL_GR2 | DL_LMS | $10       ; enable HSCROL
scrol_ptr1
        dta a(scroltext)

        dta DL_GR1 | DL_LMS | $10       ; enable HSCROL
scrol_ptr2
        dta a(scroltext)

        dta DL_BLANK8 | DL_DLI          ; dli2

        dta DL_GR15 | DL_LMS
        dta a(skyline)
:63     dta DL_GR15

        dta DL_JVB
        dta a(dlist)

; colors for each image
color0_congrats = $0e
color1_congrats = $84
color2_congrats = $24
color3_congrats = $00

color0_ABBUC    = $00
color1_ABBUC    = $26
color2_ABBUC    = $48
color3_ABBUC    = $6a

color0_POKEY    = $1c
color1_POKEY    = $28
color2_POKEY    = $04
color3_POKEY    = $20

color0_SAG      = $0e
color1_SAG      = $24
color2_SAG      = $00
color3_SAG      = $7c

color0_AGGF     = $dc
color1_AGGF     = $0e
color2_AGGF     = $26
color3_AGGF     = $74

                .align $100

scroltext
                dta d'                    '
                icl 'inc/scroltext.inc'
scroltext_end
                dta d'                    '

                .align $100

image_colors_lo
        dta <image_colors0
        dta <image_colors1
        dta <image_colors2
        dta <image_colors3

image_colors_hi
        dta >image_colors0
        dta >image_colors1
        dta >image_colors2
        dta >image_colors3

image_colors0
        dta color0_congrats
        dta color0_ABBUC
        dta color0_POKEY
        dta color0_SAG
        dta color0_AGGF
        dta color0_congrats
        
image_colors1
        dta color1_congrats
        dta color1_ABBUC
        dta color1_POKEY
        dta color1_SAG
        dta color1_AGGF
        dta color1_congrats

image_colors2
        dta color2_congrats
        dta color2_ABBUC
        dta color2_POKEY
        dta color2_SAG
        dta color2_AGGF
        dta color2_congrats

image_colors3
        dta color3_congrats
        dta color3_ABBUC
        dta color3_POKEY
        dta color3_SAG
        dta color3_AGGF
        dta color3_congrats

; first entry must repeat in last entry to generate extra scanlines for vertical scrolling
image_tab_lo
        dta <lcongrats
        dta <lABBUC
        dta <lPOKEY
        dta <lSAG
        dta <lAGGF
        dta <lcongrats

image_tab_hi
        dta >lcongrats
        dta >lABBUC
        dta >lPOKEY
        dta >lSAG
        dta >lAGGF
        dta >lcongrats

; image data

        .align $1000
lABBUC
        ins 'images/abbuc.raw'

        .align $1000
lSAG
        ins 'images/sag.raw'

        .align $1000
lPOKEY
        ins 'images/pokey.raw'

        .align $1000
lAGGF
        ins 'images/friesland.raw'

        .align $1000
lcongrats
        ins 'images/gefeliciteerd.raw'

        .align $1000
skyline
        ins 'images/skylinegr15.raw'

        .align $0400
megafont
        ins 'fonts/megazine.fnt'

scanline_tab = *

        org scanline_tab+(IMAGE_HEIGHT*IMAGE_COUNT*2)

; scanline color tables for all images
color0_tab

        org color0_tab+(IMAGE_HEIGHT*IMAGE_COUNT)
        
color1_tab
color1_tab_ABBUC = color1_tab + IMAGE_HEIGHT
        org color1_tab+(IMAGE_HEIGHT*IMAGE_COUNT)

color2_tab

        org color2_tab+(IMAGE_HEIGHT*IMAGE_COUNT)

color3_tab

        org color3_tab+(IMAGE_HEIGHT*IMAGE_COUNT)

color_tab_lo
        dta <color0_tab
        dta <color1_tab
        dta <color2_tab
        dta <color3_tab

color_tab_hi
        dta >color0_tab
        dta >color1_tab
        dta >color2_tab
        dta >color3_tab

        run main
