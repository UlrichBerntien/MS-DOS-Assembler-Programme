        PAGE 70,132
        .SALL
        .RADIX 16
;---------------------------------------------------------------------
; MS-MACRO-Assembler V6.0
; (c) Ulrich Berntien .08.1991
;   letzte Änderung 28.05.1992
;---------------------------------------------------------------------

cr      EQU 0D                                ;ascii
lf      EQU 0A
keyport EQU 10E8                              ;port adresse

;---------------------------------------------------------------------
data    SEGMENT WORD 'data'

text    DB lf
        DB 'KEYRUN (c) Ulrich Berntien .08.1991',cr,lf
        DB lf
        DB 'Erzeugt den Effekt der "Laufenden Tastatur".',cr,lf
        DB 'Nach dem Drücken einer Taste wird die automatische',cr,lf
        DB 'Tastenwiederholung aktiv, ohne das eine Taste',cr,lf
        DB 'gedrückt ist.',cr,lf
        DB lf
        DB 'Dieser Effekt wird erreicht indem auf den Tastaurport',cr,lf
        DB 'die Bytes 031H,0BFH,020H,001H mehrmals ausgegeben',cr,lf
        DB 'werden ohne Beachtung der Empfangsbereitschaft.',cr,lf
        DB lf
        DB 'ACHTUNG: nach 2 min erfolgt automatisch ein Warmboot.',cr,lf
        DB '$'

bootvector DD 0FFFE0009                       ;ads von warmboot

data    ENDS

;---------------------------------------------------------------------
code    SEGMENT WORD 'code'
        ASSUME ds : data, cs : code, ss : stack

outdx   MACRO was
          mov al,was
          out dx,al
        ENDM

segdata DW  SEG data

;---------------------------------------------------------------------
main    PROC FAR
        mov   ds,segdata

        lea   dx,text                         ;ds:dx auf text
        mov   ah,09                           ;print a string
        int   21

        lds   dx,bootvector
        xor   bx,bx                           ;index 0 => 10ms timer
        mov   cx,12000t                       ;= 120 sekunden
        mov   al,02                           ;set event trap
        int   88

        mov   si,400t
        mov   dx,keyport
iloop:  outdx 031
        outdx 0BF
        outdx 020
        outdx 001
        mov   cx,25
@@:     loop  @b
        dec   si
        ja    iloop

@@:     mov   ax,4C00                         ;terminate process
        int   21
        jmp   @b
main    ENDP

code    ENDS

;---------------------------------------------------------------------
stack   SEGMENT WORD STACK
        BYTE 1024t DUP (?)
stack   ENDS

        END main
