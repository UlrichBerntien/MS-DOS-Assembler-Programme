; MS-Macro-Assembler V1.10 /Wang PC
;  (c) Ulrich Berntien .02.1986
; Type Attribute = Set of (Top,Down,Under,Over,Bold,Blank,Reverse,Blink);
; Procedure ATTR (Para :Attribute);
; die Schriftart wird nach dem Parameter geändert, es bedeuten:
;    Top          = Superscipt
;    Down         = Subscript
;    Under        = Underscore
;    Over         = Overscore
;    Bold         = Bold
;    Blank        = Blank
;    Reverse      = Reverse video
;    Blink        = Bink

Data    Segment Public 'Data'
 DGroup Group Data
 Assume Ds: DGroup
 Extrn  TTSIB :DWord
Data    EndS

Schrift Segment Public 'Code'
 Assume Cs: Schrift
 Public ATTR
ATTR    Proc Far
        Mov     Si,Bp           ;Frame Pointer retten
        Mov     Bp,Sp           ;Bp auf Stack zeigen
        Mov     Dx,4[Bp]        ;Parameter in Dx
        LEs     Bx,TTSIB        ;Adresse des SIB in Es:Bx
        Mov     Es:[Bx+7],Dl    ;Attribute setzten
        Mov     Bp,Si           ;Frame Pointer herstellen
        Ret     2               ;Zurück und Stack säubern
ATTR    EndP
Schrift EndS
        End
