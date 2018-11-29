; MS-Macro-Assembler V1.1 /Wang PC /Epson FX-80
;  (c) Ulrich Berntien .09.1986
; Das Programm schaltet bei Drucker den Proportionalmodus ein oder aus.
; Aufruf zum Einschalten: Setprop +     Ein(!) Leerzeichen
; Aufruf zum Ausschalten: Setprop -

Prog    Segment
 Assume Ds : Prog, Cs : Prog
 Param  EQU     Byte PTR Ds:0082H
        ORG     100H

        Cmp     Param,'-'       ;ausschalten ?
        Je      Off
        Cmp     Param,'+'       ;einschalten ?
        Jne     Ende            ;ungültig
        Mov     Di,Offset ESCP
        Mov     Si,Offset TextP
        Jmp     Set
Off:    Mov     Di,Offset ESCM
        Mov     Si,Offset TextM
Set:    Mov     Ah,09H          ;String ausgeben
        Mov     Dx,Offset Text
        Int     21H             ;DOS-Call
        Mov     Cx,3            ;drei Zeichen an Drucker
Loop0:  Mov     Dx,1020H        ;Parallelsattusport
Lab0:   In      Al,Dx
        Test    Al,10H          ;ist Busy ?
        Jnz     Lab0
        Mov     Dx,10EAH        ;Parallelausgang
        Mov     Al,[Di]         ;Zeichen für Ausgabe
        Out     Dx,Al
        Inc     Di              ;nächstes Byte
        Loop    Loop0           ;Schleife 3x
        Mov     Dx,Si           ;Adresse des TextP oder TestM
        Mov     Al,09H          ;Stringausgabe
        Int     21H             ;DOS-Call
Ende:   Int     20H

ESCP    DB 27,'p',01
ESCM    DB 27,'p',00
Text    DB 'PROPORTIONAL $'
TextP   DB 'ON$'
TextM   DB 'OFF$'

Prog    EndS
        End
