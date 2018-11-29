; MS-Macro-Assembler V1.1 /Wang PC
;  (c) Ulrich Berntien .12.1985
; Function WaitKey :Byte;
;  Die Funktion übergibt den WISCII-Wert der gedrükten Taste, ist keine
;  Taste gedrückt wartet die Prozedure auf eine Taste

Schrift Segment Public 'Code'
Assume  Cs:Schrift
Public  WaitKey

WaitKey Proc Far
        Mov     Ah,07h          ;MS-DOS Funktion Nr.7
        Int     21h             ;Sprung in DOS
        Ret                     ;Wert ist in Al

WaitKey EndP
Schrift EndS
        End
