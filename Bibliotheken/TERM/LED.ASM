; MS-Macro-Assembler V1.1 /Wang PC
;  (c) Ulrich Berntien .08.1985
; Procedure LED(Nr :Integer; On :Boolean);
;  Das Unterprogramm schaltet die LED der Tastatur (Nr.0 bis Nr.5) an (true)
;  oder aus (false). Ist die Nummer -1 werden alle LEDs an/ausgeschaltet.

Schrift Segment Public 'Code'
 Assume  Cs:Schrift
 Public  LED

LED     Proc Far
        Mov     Si,Bp           ;Frame Pointer retten
        Mov     Bp,Sp           ;Bp auf Stack zeigen
        XOr     Cx,Cx           ;Cx:=0
        Mov     Cl,4[Bp]        ;On in Cl
        Mov     Bl,11h          ;Code für Sendung nach Tastatur in Bl
        JCxZ    false           ;on=false ?
        Dec     Bl              ; nein
false:  Mov     Ax,6[Bp]        ; ja   ;Nummer in Ax
        Cmp     Ax,-1           ;bis -1 zulässige Nummern
        Jl      Ende            ; unzulässig
        Je      Lab1            ; gleich -1
        Cmp     Ax,05           ;bis +5 zulässige Nummern
        Jng     Lab2            ; nicht größer
        Jmp     Ende            ; unzulässig
Lab1:   Mov     Al,06           ;Anpassung für gleich -1
Lab2:   Sal     Al,1            ;Al:=Al*2
        Add     Bl,Al           ;Code für Sendung fertig
        Mov     Cx,01           ;ein Zeichen senden
        Mov     Al,07H          ;Code für senden nach Tastatur
        Int     88H             ;BIOS -Funktionsaufruf
Ende:   Mov     Bp,Si           ;Bp wiederholen
        Ret     4               ;zurück

LED     EndP
Schrift EndS
        End
