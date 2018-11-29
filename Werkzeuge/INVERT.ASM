; MS-Macro-Assembler V1.1 /Wang PC
; (c) Ulrich Berntien .12.1987
; invertiert sämtliche Zeichen
; dadurch eine schwarz auf weiß Darstellung auf dem Monitor

Code    Segment
Assume  Ds : Code, Cs : Code

        ORG 100H

        Mov     Ax,Cs                   ;Datensegment stetzen
        Mov     Ds,Ax
        Mov     Dx,offset Text          ;Namen ausgeben
        Mov     Ah,09H                  ;print a string
        Int     21H                     ;DOS-Call
        Mov     Al,01                   ;Zeiger zum system configuration table
        Int     88h                     ;BIOS call
        Mov     Bx,Es:[Bx+0Ah]          ;Adresse des SIB
        Mov     Dh,Es:[Bx+13H]          ;High Byte von Anschluß
        Mov     Dl,10H                  ;Least Byte
        Add     Bx,8                    ;Zeiger auf Statusbyte der Karte
        Mov     Al,Es:[Bx]              ;Status lesen
        And     Al,0cH
        Or      Al,01H                  ;Signal für Karte
        Mov     Si,0f200H               ;Bildschirmspeicher
        Mov     Es,Si                   ;  in Es
        Xor     Si,Si                   ;bei Null starten
        Mov     Cx,4096                 ;soviel Words invertieren
LLL:    Out     Dx,Al                   ;Ausgeben
        Not     Word PTR Es:[Si]        ;invertieren
        Inc     Si
        Inc     Si                      ;nächstes Word
        Loop    LLL
        Int     20H                     ;Ende

Text    DB 'Char.Gen. Invert -- (C) .12.1987 Ulrich Berntien',13,10,'$'

Code    EndS

        End
