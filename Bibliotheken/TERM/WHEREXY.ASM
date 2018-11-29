; MS-Macro-Assembler V1.1 /Wang PC
;  (c) Ulrich Berntien .03.1986
; Procedure WhereXY(Var X,Y :Integer );
;  Den Variablen X,Y wird die aktuelle Cursorposition zugewiesen.

Data    Segment Public 'Data'
 DGroup Group Data
 Assume Ds : DGroup
 Extrn  TTSIB : DWord
Data    EndS

Schrift Segment Public 'Code'
 Assume  Cs : Schrift
 Public  WhereXY

WhereXY Proc Far
        Mov     Si,Bp           ;Frame Pointer sichern
        Mov     Bp,Sp           ;Bp auf Stack zeigen
        Mov     Ch,0
        Les     Bx,TTSIB        ;Adresse des SIB in Es:Bx laden
        Mov     Cl,Es:[Bx+5]    ;Zeilenwert laden
        Inc     Cx              ;Ursprung im SIB (0,0)
        Mov     Di,4[Bp]        ;Adresse von Y
        Mov     [Di],Cx         ;abspeichern
        Mov     Cl,Es:[Bx+6]    ;Zeilenwert laden
        Inc     Cx              ;Ursprung im SIB (0,0)
        Mov     Di,6[Bp]        ;Adresse von X
        Mov     [Di],Cx         ;abspeichern
Ende:   Mov     Bp,Si           ;Frame Pointer setzen
        Ret     4               ;zurück und Stack säubern

WhereXY EndP
Schrift EndS
        End
