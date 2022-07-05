/*
** COMPILE:
** # Windows
** "c:\Program Files (x86)\MADS\mads.exe" -i:inc\ -o:xex\filename.xex filename.asm
**
** # Linux / OSX
** mads -i:inc/ -o:xex/filename.xex filename.asm
*/

        icl "systemequates.20070530_bkw.inc"            ; Don't forget the specify -i:<path to file> at compile time

; Variables
PicStart        equ $30

; ABBUC 150 Logo
        ; COLBK  = 
        ; COLOR0 =
        ; COLOR1 = 
        ; COLOR2 = 
        ; COLOR3 = 
        org $3010
lABBUC
        ins 'abbuc.raw'
        .align $1010

; SAG Logo
        ; COLBK  = $0E
        ; COLOR0 = $00
        ; COLOR1 = $24
        ; COLOR2 = $0E
        ; COLOR3 = 
        org $4010
lSAG
        ins 'sag.raw'
        .align $1010

; Pokey Logo
        ; COLBK  = $F0
        ; COLOR0 = $26
        ; COLOR1 = $22
        ; COLOR2 = $1A
        ; COLOR3 = 
        org $5010
lPOKEY
        ins 'pokey.raw'
        .align $1010

; Friesland Logo
        ; COLBK  = $0e
        ; COLOR0 = $82
        ; COLOR1 = $00
        ; COLOR2 = $24
        ; COLOR3 = 
        org $6010
lFRIESLAND
        ins 'friesland.raw'
        .align $1010
        
; *** MAIN ***
        org $2000
main
        lda #0
        sta COLBK
        sta COLOR1
        sta COLOR2
        sta COLOR3
        sta COLOR4

;       mwa #dli0 VDSLST
        lda #<dli0
        sta VDSLST
        lda #>dli0
        sta VDSLST+1

;       mwa #dlist SDLSTL
        lda #<dlist
        sta SDLSTL
        lda #>dlist
        sta SDLSTL+1
                        
        lda #$c0        ; Enable DLI
        sta NMIEN

wait
        lda CONSOL
        cmp #6          ; Wait for START
        bne wait

; Next part
        lda PicStart
        clc
        adc #$10
        sta PicStart
        sta logo+1
        jmp wait

; The end
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


dlist
:3      dta DL_BLANK1                   ; 70
        dta DL_GR15 | DL_LMS            ; 4e

logo
        dta a(lABBUC)

:101    dta DL_GR15                     ; 0e
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
tFRIESLAND
        dta d'    Atari Gebruikers Groep Friesland    '

        run main
        
dli0    pha
        lda #0
        sta COLPF2
        lda #10
        sta COLPF1
        pla
        rti
