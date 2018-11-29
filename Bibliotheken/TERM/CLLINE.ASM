; MS-Macro-Assembler V1.1 /Wang PC
;  (c) Ulrich Berntien .03.1986
;      letzte Änderung .03.1989
; Procedure ClLine( Y :Integer );
;  Die Zeile Y ( 1..25 ) wird gelöscht, der Cursor steht am Anfang
;  dieser Zeile.
;  clline( 0 ) -> Bildschrim löschen, Cursor home

Data    Segment Public 'Data'
 DGroup Group Data
 Assume Ds : DGroup
 Extrn  TTSIB : DWord
Data    EndS

Schrift Segment Public 'Code'
 Assume  Cs : Schrift
 Public  ClLine

ClLine  Proc Far
        Mov     Si,Bp           ;Frame Pointer sichern
        Mov     Bp,Sp           ;Bp auf Stack zeigen
        Mov     Cx,4[Bp]        ;Y-Wert laden
        Cmp     Cx,00           ;
        Jg      W01             ;nächste Kontrolle
        Je      cls             ;Bildschirm löschen
        Jmp     Ende            ;kleiner als 0
W01:    Cmp     Cx,25           ;größer als 25 ?
        Jg      Ende            ; ja
        Dec     Cx              ;Urspung (0,0)
        Les     Bx,TTSIB        ;Adresse des SIB in Es:Bx laden
        Mov     Es:[Bx+5],Cl    ;Zeile setzen
        Mov     Es:[Bx+6],Byte PTR 0 ;Spalte setzen
        Mov     Bx,27           ;ESC
        Mov     Al,6            ;Funktion Ausgeben
        Int     88H             ;BIOS Call
        Mov     Bl,'['          ;"["
        Mov     Al,6            ;Funktion Ausgeben
        Int     88H             ;BIOS Call
        Mov     Bl,'K'          ;"K"
        Mov     Al,6            ;Funktion Ausgeben
        Int     88H             ;BIOS Call
Ende:   Mov     Bp,Si           ;Frame Pointer setzen
        Ret     2
cls:    Mov     Bx,12           ;FF
        Mov     Al,6            ;Funktion Ausgeben
        Int     88H             ;BIOS Call
        Mov     Bp,Si           ;Frame Pointer setzen
        Ret     2               ;zurück und Stack säubern

ClLine  EndP
Schrift EndS
        End
