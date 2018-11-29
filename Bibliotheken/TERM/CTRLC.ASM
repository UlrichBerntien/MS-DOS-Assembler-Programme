; MS-Marco-Assembler V1.1 /Wang PC
; (c) Ulrich Berntien .03.1987
; Prozeduren zur Behandlung von KRTL-C
; Procedure CtrlrC( Procedure C_Trap; ); Extern;
;   Bei KRTL-C wird die Procedure C_Trap aufgerufen
;   Die Procedure C_Trap muß EXTERN oder PUBLIC definiert sein
; Procedure CtrlCoff;
;   Der KRTL-C Trap wird abgeschaltet

Schrift Segment Public 'Code'
 Assume Cs : Schrift
 Public CtrlC, CtrlCoff

CtrlC   Proc Far
        Push    Bp              ;Frame Pointer sichern
        Mov     Bp,Sp           ;Bp auf Stack zeigen
        Mov     Bx,8[Bp]        ;Adresse von C_Trap
        Mov     Ax,[Bx]         ;übertragen nach Label
        Mov     Word PTR Cs:PCall,Ax
        Mov     Ax,[Bx+2]
        Mov     Word PTR Cs:PCall+2,Ax
        Mov     Cs:DSeg,Ds      ;Pascal-Datensegment sichern
        Mov     Ah,34H          ;DOS critical Flag Adresse holen
        Int     21H             ;DOS-Call
        Mov     Word PTR Cs:Flag,Bx ;Adresse speichern
        Mov     Word PTR Cs:Flag+2,Es
        Mov     Dx,Offset CTrap ;Adresse der Prozedur in Ds:Dx
        Mov     Ax,Seg Schrift
        Mov     Ds,Ax
        Mov     Bx,09H          ;KRTL-C Trap
        Mov     Cx,01           ;Bei erstem Mal trapen
        Mov     Al,02H          ;Set Event Trap
        Int     88H             ;Bios-Call
        Mov     Cs:QID,Bx       ;Queue Identification sichern
        Mov     Ds,Cs:DSeg      ;Ds wiederherstellen
        Pop     Bp
        Ret     4               ;Zurück und Stack säubern
CtrlC   EndP

CTrap   Proc Far
        PushF                   ;Register sichern
        Push    Bx
        Push    Ds
        LDs     Bx,Cs:Flag      ;Adresse des DOS critical Flags
        Cmp     [Bx],Byte PTR 0 ;nicht kritisch ?
        Jnz     Back            ; doch kritisch!
        Push    Ax              ;restliche Register sichern
        Push    Dx
        Push    Cx
        Push    Si
        Push    Di
        Push    Bp
        Push    Es
        Mov     Bx,Cs:QID       ;Trap Queue Identification
        Mov     Al,03H          ;Clear Event Trap
        Int     88H             ;BIOS-Call

        Mov     Ds,Cs:DSeg      ;Pascal Datensegment laden
        Call    Cs:[PCall]      ;Pascal C_Trap aufrufen


;       Mov     Bx,'C'
;       Mov     Al,06H
;       Int     88H

        Mov     Dx,Offset CTrap ;Adresse der Prozedur in Ds:Dx
        Mov     Ax,Seg Schrift
        Mov     Ds,Ax
        Mov     Bx,09H          ;KRTL-C Trap
        Mov     Cx,01           ;Bei erstem Mal trapen
        Mov     Al,02H          ;Set Event Trap
        Int     88H             ;Bios-Call
        Mov     Cs:QID,Bx       ;Queue Identification sichern
        Pop     Es              ;Register zurück holen
        Pop     Bp
        Pop     Di
        Pop     Si
        Pop     Cx
        Pop     Dx
        Pop     Ax
Back:   Pop     Ds              ;schnell zurück, wenn kritisch
        Pop     Bx
        PopF
        Ret                     ;weiter
CTrap   EndP

CtrlCoff Proc Far
        Mov     Bx,Cs:QID       ;Trap Queue Identification
        Mov     Al,03H          ;Clear Event Trap
        Int     88H             ;BIOS-Call
        Ret                     ;zurück
CtrlCoff EndP

        EVEN
QID     DW (?)                  ;Queue Event Identification
Flag    DD (?)                  ;DOS critical Flag
DSeg    DW (?)                  ;Datensegment von Pascal
PCall   DD (?)                  ;Adresse von der Pascal C_Trap

Schrift EndS
        End
