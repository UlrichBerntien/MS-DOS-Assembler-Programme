; MS-Macro-Assembler V1.1 /Wang PC
; (c) Ulrich Berntien .12.1986

;  Format : CURSOR <Nummer>
;  0 - Cursor ausschalten  / 1 - einschalten
;  2 - Blinken ausschalten / 3 - einschalten
;  4 - Underline           / 5 - Block

Code Segment
 Assume  Cs: Code, Ds: Code

Long    EQU     Byte PTR DS:080H
        ORG     100H

        Mov     Bx,0080H        ;erstes Zeichen des Parameters
        Add     Bl,Long
        Jnc     CLab
        Inc     Bh              ;Übertrag
CLab:   Mov     Dl,[Bx]
        Sub     Dl,'0'
        Mov     Ax,Cs           ;DS auf Code Segemnt
        Mov     Ds,Ax
        Cmp     Dl,0            ;kleiner als 0
        Jl      ende            ; ja
        Cmp     Dl,5            ;größer als 5
        Jg      ende            ; ja
        SAL     Dl,1
        SAL     Dl,1            ;Dx := Dx *4
        Xor     Dh,Dh           ;Dh:= 0
        Add     Dx,Offset on    ;Adresse berechnen
        Mov     Cx,04           ;vier Zeichen ausgeben
        Mov     Al,0dH          ;Zeichen auf Bildschirm
        Int     88H             ;BIOS call
ende:   Int     20H             ;zurück

on      DB 27,'[5l'
off     DB 27,'[5h'
blon    DB 27,'[2h'
bloff   DB 27,'[2l'
under   DB 27,'[3l'
block   DB 27,'[3h'

Code    EndS
        End
