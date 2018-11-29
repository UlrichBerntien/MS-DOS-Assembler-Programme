; MS-MAcro-Assembler V1.10 /Wang PC
;  (c) Ulrich Berntien .02.1986
; Procedure CTrap (On :Boolean);
;  Ein/Ausschalten der Verarbeitung der KTRL-C Taste bei DOS Aufrufen
;  über Funktion 33H.

Schrift Segment Public 'Code'
 Assume Cs: Schrift
 Public CTrap

CTrap   Proc Far
        Mov     Si,Bp           ;Frame Pointer retten
        Mov     Bp,Sp           ;Bp auf Stack zeigen
        Mov     Dl,4[Bp]        ;Parameter On in Dl
        Mov     Ax,3301h        ;Funktionsnummer
        Int     21h             ;DOS call
        Mov     Bp,Si           ;Frame Pointer restaurieren
        Ret     2               ;zurück und Stack säubern
CTrap   EndP
Schrift EndS
        End
