; MS-Macro-Assembler V1.1 /Wang PC
;  (c) Ulrich Berntien .05.1986
; Function ReadInt: Integer;
;  Einlesen eines Integer Wertes von Tastatur und dabei
;  Ausgabe auf Monitor.

Data    Segment Public 'Data'
 DGroup Group Data
 Assume Ds : DGroup
Mem     DB 6 DUP (?)
Data    EndS

Schrift Segment Public 'Code'
 Assume Cs : Schrift
 Public ReadInt

ReadInt Proc Far
        Xor     Si,Si           ;erstes Byte
        Xor     Bh,Bh           ;Bh:= 0
Ein:    Mov     Ah,07H          ;Eingabe eines Zeichen
        Int     21H             ;DOS-Call
        Cmp     Al,'9'          ;Zeichen größer als '9'
        Jg      Ein             ;ignorieren
        Cmp     Al,'-'          ;Vorzeichen
        Je      Minus
        Cmp     Al,13           ;Zeilenschaltung
        Je      CR
        Cmp     Al,8            ;Rückschritt
        Je      BS
        Cmp     Al,'0'          ;kleiner als '0'
        Jl      Ein             ;ignorieren
inm:    Cmp     Si,6            ;Ende des Speichers ?
        Jge     ein             ; nein
        Mov     Bl,Al           ;Die Ziffer ausgeben
        Mov     Al,06           ;ein Zeichen ausgeben
        Int     88H             ;BIOS-Call
        Mov     Mem[Si],Bl      ;speichern
        Inc     Si              ;nächstes
        Jmp     ein             ; ja
Minus:  Cmp     Si,0            ;nur am Anfange
        Je      inm             ; ja
        Jmp     ein             ;ignorieren
BS:     Cmp     Si,0            ;schon am Anfang
        Je      ein             ;ignorieren
        Mov     Bl,08           ;Backspace
        Mov     Al,06           ;ein Zeichen aus
        Int     88H             ;BIOS-Call
        Mov     Bl,' '          ;Leerzeichen
        Mov     Al,06           ;ein Zeichen aus
        Int     88H             ;BIOS-Call
        Mov     Bl,08           ;Backspace
        Mov     Al,06           ;ein Zeichen aus
        Int     88H             ;BIOS-Call
        Dec     Si              ;ein zurück
        Jmp     ein
CR:     Xor     Ax,Ax           ;Ax:= 0
        Xor     Di,Di           ;Di:= 0
        Cmp     Mem[Di],Byte PTR '-' ;Vorzeichen ?
        Jne     Lab3            ; nein
        Inc     Di              ;auf erste Ziffer
Lab3:   Cmp     Di,Si           ;Ende erreicht ?
        Jge     Ende            ;ja
        Cmp     Ax,3275         ;overflow ?
        Jg      over            ; ja
        Sal     Ax,1            ;Ax:= Ax*2
        Mov     Cx,Ax           ;Cx:= Ax
        Sal     Ax,1            ;Ax:= Ax*4
        Sal     Ax,1
        Add     Ax,Cx           ;=> Ax:= Ax *10
        Mov     Bl,Mem[Di]      ;Ziffer einladen
        Sub     Bl,'0'          ;in Zahlenwert
        Add     Ax,Bx           ;Ax:=Ax + Bl
        Inc     Di              ;nächste Ziffer
        Jmp     Lab3            ;weiter
Ende:   Cmp     Mem[0],Byte PTR '-'  ;Vorzeichen ?
        Jne     Lab4            ; nein
        Neg     Ax              ;Ax:= -Ax
Lab4:   Ret                     ;zurück
over:   Mov     Ax,32767        ;Ax:= MaxInt
        Jmp     Ende

ReadInt EndP
Schrift EndS
        End
