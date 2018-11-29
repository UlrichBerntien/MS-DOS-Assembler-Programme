; MS-Marco-Assembler V1.1 /Wang PC
;  (c) Ulrich Berntien .03.1987
; Type GenM = Array [1..12] of Word;
; Procedure GetGen( n :Integer; Var z :GenM );
;   Liest von Zeichen# n das Font aus den Zeichengenerator
; Procedure PutGen( n :Integer; Const z :GenM );
;   Schreibt bei Zeichen# n das Font z in den Zeichengenerator
; Das Zeichen nutzt die niederen 10 Bits des Words

Data    Segment Public  'Data'
DGroup  Group Data
Assume DS:DGroup
Extrn   TTSib:Word ,TTSta:Word ,TTOut:Word
                ;TTSib+2 =Segment des Sreen Information Block
                ;TTSta =Adresse des ersten Status Bytes
                ;TTOut =Ausgabeanschluß für Grafikkarte
Data    EndS

Schrift Segment Public 'Code'
 Assume  CS: Schrift
 Public  GetGen, PutGen

Main    Proc Near
        Cmp     Bx,0            ;Bereichstest
        Jl      E1
        Cmp     Bx,255
        Jg      E1
      Rept 5
        Sal    Bx,1
      EndM                      ;Bx:= Bx * 32
        Inc     Bx
        Inc     Bx              ;Bx:= Bx + 2
        Mov     Dx,TTOut        ;Ausgang zur Monitorkarte
        Mov     Es,TTSib+2
        Mov     Si,TTSta        ;Adresse des 1.Statusbytes
        Mov     Al,Es:[Si]      ;Byte in Al
        And     AL,0cH
        Or      AL,01H          ;Signal für Monitorkarte
        Mov     Cx,0f200H       ;Charactergeneratorspeicher
        Mov     Es,Cx
        Mov     Cx,12           ;12 Words übertragen
        Sub     Di,Bx           ;für Adressierung
        Ret
Main    EndP


GetGen  Proc Far
        Push    Bp              ;Frame Pointer rettern
        Mov     Bp,Sp           ;Bp auf Stack
        Mov     Bx,8[Bp]        ;Bx:= n
        Mov     Di,6[Bp]        ;Di auf Array
        Call    Main
        Out     Dx,Al           ;Ausgabe zur Karte
L1:     Mov     Dx,Es:[Bx]      ;lesen
        Mov     [Di+Bx],Dx      ;abspeichern
        Inc     Bx
        Inc     Bx              ;nächstes Word
        Loop    L1
E1:     Pop     Bp
        Ret     4
GetGen  EndP

PutGen  Proc Far
        Push    Bp              ;Frame Pointer rettern
        Mov     Bp,Sp           ;Bp auf Stack
        Mov     Bx,8[Bp]        ;Bx:= n
        Mov     Di,6[Bp]        ;Di auf Array
        Call    Main
        Out     Dx,Al           ;Ausgabe zur Karte
L2:     Mov     Dx,[Di+Bx]      ;lesen
        Mov     Es:[Bx],Dx      ;abspeichern
        Inc     Bx
        Inc     Bx              ;nächstes Word
        Loop    L2
E2:     Pop     Bp
        Ret     4
PutGen  EndP

Schrift EndS
        End
