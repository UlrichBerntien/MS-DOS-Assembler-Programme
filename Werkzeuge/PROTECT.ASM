; MS-Macro-Assembler V1.1 /Wang PC
;  (c) Ulrich Berntien .05.1986
; Der Schreibschutz eines Files wird geändert. Die Art der Änderung wird durch
; Schalter angegeben: -r => read only       -w => read and write
;                     -h => hide file       -s => no hide
;                     -y => system file     -n => no system file
;                     -b => backup set

Prog    Segment
 Assume Ds :Prog, Cs :Prog

        Long EQU Byte PTR Ds:0080H
        ORG 100H

        Mov     Bx,0081H        ;erstes Zeichen des Parameters
        Add     Bl,Long         ;letztes Zeichen
        Jnc     Lab1
        Inc     Bh              ;Übertrag
Lab1:   Cmp     [Bx],Byte PTR '-' ;nach dem Switch suchen
        Je      found           ;wenn gefunden
        Dec     Bx              ;nächstes Zeichen
        Cmp     Bx,81           ;alles durchsucht
        Jg      Lab1            ;weiter
        Jmp     Fehler          ;kein Switch gefunden
found:  Mov     [Bx-1],Byte PTR 00 ;Ende des Filenmens
        Mov     Ax,4300H        ;Protection attribut lesen
        Mov     Dx,0082H        ;Adresse des Namens
        Int     21H             ;DOS-Call
        Jc      FehlerD         ;bei Fehler
        Mov     Al,[Bx+1]       ;Zeichen holen
        And     Al,11011111B    ;in Großbuchstaben
        Cmp     Al,'R'          ;read only ?
        Jne     Lab2            ; nein
        Or      Cl,00000001B    ;read only flag setzten
        Jmp     set             ;setzten
Lab2:   Cmp     Al,'W'          ;write and read ?
        Jne     Lab3            ; nein
        And     Cl,11111110B    ;read only flag löschen
        Jmp     set             ;setzten
Lab3:   Cmp     Al,'H'          ;hide file ?
        Jne     Lab4            ; nein
        Or      Cl,00000010B    ;hide flag setzten
        Jmp     set             ;setzten
Lab4:   Cmp     Al,'S'          ;no hide ?
        Jne     Lab5            ; nein
        And     Cl,11111101B    ;hide flag löschen
        Jmp     set             ;setzen
Lab5:   Cmp     Al,'Y'          ;system file ?
        Jne     Lab6            ; nein
        Or      Cl,00000100B    ;sytem flag setzen
        Jmp     set             ;setzen
Lab6:   Cmp     Al,'N'          ;no system file ?
        Jne     Lab7            ; nein
        And     Cl,11111011B    ;system flag löschen
        Jmp     set             ;setzten
Lab7:   Cmp     Al,'B'          ;backup ?
        Jne     fehler          ; nein
        And     Cl,11011111B    ;backup setzen
set:    Mov     Ax,4301H        ;Protection attribute setzten
        Int     21H             ;DOS-Call
        Jc      FehlerD         ;wenn Fehler
        Int     20H             ;fertig
fehlerD:
        Mov     Cl,Al           ;Fehhlercode sicher
        Shr     Al,1
        Shr     Al,1
        Shr     Al,1            ;HighNibel
        Shr     Al,1            ;zu LoNibel schieben
        Add     Al,'0'          ;in ASCII
        Mov     Et,Al           ;in Text speichern
        Mov     Al,Cl           ;Fehlercode zurück
        And     Al,00001111B    ;HighNibel ausblenden
        Add     Al,'0'          ;in ASCII
        Mov     Et+1,Al         ;in Textspeichern
        Mov     Cx,Text-TextD   ;Länge des Strings
        Mov     Dx,Offset TextD ;Adresse des Textes
        Jmp     OutE
fehler: Mov     Cx,EText-Text   ;Länge des Strings
        Mov     Dx,Offset Text  ;Adresse des Textes
OutE:   Mov     Al,0dH          ;String ausgeben
        Int     88H             ;BIOS-Call
        Int     20H             ;Ende

TextD   DB 'MS-DOS #'
ET      DB '00'
        DB ' ERROR during work'
Text    DB 'No matched Switch'
EText   DB

Prog    EndS
        End
