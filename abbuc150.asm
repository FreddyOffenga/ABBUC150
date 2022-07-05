/*
** COMPILE:
** # Windows
** "c:\Program Files (x86)\MADS\mads.exe" -i:inc\ -o:xex\filename.xex filename.asm
**
** # Linux / OSX
** mads -i:inc/ -o:xex/filename.xex filename.asm
*/

        icl "inc/systemequates.20070530_bkw.inc"            ; Don't forget the specify -i:<path to file> at compile time

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
        
main

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

/*
        jmp *           ; Endless loop
*/
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

dlist
:3      dta DL_BLANK1                   ; 70
        dta DL_GR15 | DL_LMS            ; 4e

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
