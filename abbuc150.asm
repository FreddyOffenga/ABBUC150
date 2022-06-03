; ABBUC 150

        org $3010

screen        
        ins 'abbuc.raw'
        
        .align $1010
;screen
        ins 'sag.raw'

        org $2000
        
main
        lda #<dlist
        sta $230
        lda #>dlist
        sta $231
        
        lda #0
        sta 712
        sta 710
        
        lda #04
        sta 709
        lda #$26
        sta 708
        
        lda #<dli0
        sta $200
        lda #>dli0
        sta $201
        
        lda #$c0
        sta $d40e

loop
        jmp loop
        
dlist
        dta $70,$70,$70
       
        dta $4e
        dta a(screen)
                
:101    dta $0e       
        
        dta $70+128
        
        dta $42
        dta a(text)
                
        dta $41
        dta a(dlist)

text
        dta d'       Stichting Atari Gebruikers       '
        run main
        
dli0    pha
        lda #0
        sta $d018
        lda #10
        sta $d017
        pla
        rti
