        PAGE 60,132
        .RADIX 16
        .MODEL TINY
;=====================================================================
;       WARMBOOT.COM
;       kommentare (c) Ulrich Berntien .09.1989
;       letzte Änderung 28.05.1992
;=====================================================================

        .CODE
        ORG 0100

        mov   dx,offset message               ;massage ausgeben
        mov   ah,09                           ;write a string
        int   21
        jmp   boot                            ;warmboot

        .DATA

message DB    0A,'WARMBOOT VERSION 2.40',0A,0D,'$'
boot    DD    0FFFE0009

        END
