; MS-Macro-Assembler V1.1 /Wang PC
; (c) Ulrich Berntien .01.1986
; Procedure GotoXY(x,y :Integer);
;  Cursor auf Position (X,Y) setzen
;  wobei x= 1-80 , y =1-25

Data    Segment Public 'Data'
 DGroup Group Data
 Assume DS: DGroup
 Extrn  TTSIB:DWord
Data    EndS

Schrift Segment Public 'Code'
 Assume  Cs:Schrift
 Public  GotoXY

GotoXY  Proc Far
        Mov     Si,Bp           ;Frame Pointer retten
        Mov     Bp,Sp           ;BP auf Stack zeigen
        Mov     Cx,4[Bp]        ;Y-Wert in Cx
        Cmp     Cx,25           ;größer als 25?
        JG      Ende            ; ja
        Cmp     Cx,01           ;kleiner als 1?
        JL      Ende            ; ja
        Mov     Dx,6[BP]        ;X-Wert in Dx
        Cmp     Dx,80           ;größer als 80
        JG      Ende            ; ja
        Cmp     Dx,01           ;kleiner als 1
        JL      Ende            ; ja
        Dec     Dx              ;im SIB ist (0,0) Ursprung
        Dec     Cx              ;also -1
        Les     Bx,TTSIB        ;Adresse laden
        Mov     Es:[Bx+5],Cl    ;Spalte setzen
        Mov     Es:[Bx+6],Dl    ;Zeile setzen
Ende:   Mov     Bp,Si           ;Frame Pointer setzen
        Ret     4               ;zurück und Stack säubern
GotoXY  EndP
Schrift EndS
        End
