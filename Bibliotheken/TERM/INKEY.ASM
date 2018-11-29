; MS-Macro-Assembler V1.1 /Wang PC
;  (c) Ulrich Berntien .08.1985
; Function InKey :Byte;
;  Die Funktion übergibt den WISCII-Wert der gedrükten Taste, ist keine
;  Taste gedrückt wird der Wert 00 ausgegeben.

Schrift Segment Public 'Code'
Assume  Cs:Schrift
Public  InKey

InKey   Proc Far
        Mov     Ah,06h          ;MS-DOS Funktion Nr.6
        Mov     Dl,0FFh         ;Zeichen einlesen
        Int     21h             ;Sprung in DOS
        Ret                     ;Wert ist in Al

InKey   EndP
Schrift EndS
        End
