; MS-Macro-Assembler V1.1 /Wang PC
; (c) Ulrich Berntien .02.1986
; Procedure CRRS( Nr :Integer );
;  0 - Cursor ausschalten  / 1 - einschalten
;  2 - Blinken ausschalten / 3 - einschalten
;  4 - Underline           / 5 - Block

Schrift Segment Public 'Code'
 Assume  Cs: Schrift
 Public  CRRS

CRRS    Proc Far
        Mov     Di,Bp           ;Frame Pointer retten
        Mov     Bp,Sp           ;Bp auf Stck zeigen
        Mov     Si,4[Bp]        ;Lobyte der Nr
        Cmp     Si,0            ;kleiner als 0
        Jl      ende            ; ja
        Cmp     Si,5            ;größer als 5
        Jg      ende            ; ja
        SAL     Si,1
        SAL     Si,1            ;Dx := Dx *4
        Xor     Bh,Bh           ;Bh:= 0
        Mov     Cx,04           ;vier Zeichen ausgeben
Aus:    Mov     Bl,CS:on[Si]    ;Zeichen in Bl für Ausgabe
        Mov     Al,06H          ;Zeichen auf Bildschirm
        Int     88H             ;BIOS call
        Inc     Si              ;auf nächstes Zeichen
        Loop    Aus
ende:   Mov     Bp,Di           ;Frame Pointer setzen
        Ret     2               ;zurück

on      DB 27,'[5l'
off     DB 27,'[5h'
blon    DB 27,'[2h'
bloff   DB 27,'[2l'
under   DB 27,'[3l'
block   DB 27,'[3h'

CRRS    EndP
Schrift EndS
        End
