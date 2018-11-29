        TITLE *** MODUL err ***
        PAGE 70,132
        .SALL
;=====================================================================
; MS-Macro-Assembler V1.10 /Wang PC
; (c) Ulrich Berntien .07.1989
;   letzte Änderung 11.12.1989
;
; Ausgabe von Fehlermeldungen auf dem standart error message device.
; Programmabbruch mit Fehlercodes.
;
; ERR_DOS : NEAR
;       -> AX - error code nach dos 2.0
;       Ausgabe der entsprechenden Fehlermeldung und Programmabbruch
;       Returncode = 01
;
; ERR_ABORT : NEAR
;       -> ES:DX - auf Fehlermeldung
;          CX    - Länge der Meldung
;       Ausgabe der Fehlermeldung und Programmabbruch. Returncode = 02
;
; ERR_MES : NEAR
;       -> ES:DX - auf Fehlermeldung
;          CX    - Länge der Meldung
;       <- CARRY gesetzt bei DOS-Fehler
;       Ausgabe der Fehlermeldung auf dem error device
;
; ERR_DOS_PTR : NEAR
;       -> AX - error code nach dos 2.0
;       <- ES:DX - auf Fehlermeldung
;          CX    - Länge der Meldung
;       Klartext zum Fehlercode.
;
; ERR_STATUS : WORD
;       wird auf den Fehlercode gesetzt, nachdem DOS einen Fehler
;       gemeldet hat.
;
;=====================================================================
; Die Register (ohne Flags) werden bei allen Procs erhalten.
; DS immer auf das DATA segment
; CS immer auf das CODE segment
; alle Procs sind vom Typ NEAR
; trift eine Proc auf einen DOS-Fehler, so wird er i.a. über Carry
; weitergmeldet und der error-code aus AX in err_status abgelegt.
;=====================================================================

dos = 21H                ;dos interrupt
err_device = 02H         ;default file handle of standart error device
cr = 0DH
lf = 0AH

;=====================================================================
data    SEGMENT WORD PUBLIC 'data'
PUBLIC  err_status

err_status DW 0

data    ENDS

;=====================================================================
messages SEGMENT WORD PUBLIC 'data'

err_table = THIS WORD
        DW OFFSET dos_00
        DW OFFSET dos_01
        DW OFFSET dos_02
        DW OFFSET dos_03
        DW OFFSET dos_04
        DW OFFSET dos_05
        DW OFFSET dos_06
        DW OFFSET dos_07
        DW OFFSET dos_08
        DW OFFSET dos_09
        DW OFFSET dos_0A
        DW OFFSET dos_0B
        DW OFFSET dos_0C
        DW OFFSET dos_0D
        DW OFFSET dos_0E
        DW OFFSET dos_0F
        DW OFFSET dos_10
        DW OFFSET dos_11
        DW OFFSET dos_12
        DW OFFSET dos_13

dos_00  DB 'DOS: no error occurred',cr,lf
dos_01  DB 'DOS: invalid function',cr,lf
dos_02  DB 'DOS: file not found',cr,lf
dos_03  DB 'DOS: path not found',cr,lf
dos_04  DB 'DOS: too many open files',cr,lf
dos_05  DB 'DOS: access denied',cr,lf
dos_06  DB 'DOS: invalid handle',cr,lf
dos_07  DB 'DOS: memory block bad',cr,lf
dos_08  DB 'DOS: not enough memory',cr,lf
dos_09  DB 'DOS: invalid block',cr,lf
dos_0A  DB 'DOS: bad enviroment',cr,lf
dos_0B  DB 'DOS: bad format',cr,lf
dos_0C  DB 'DOS: invalid access',cr,lf
dos_0D  DB 'DOS: invalid data',cr,lf
dos_0E  DB 'DOS: unknown error code',cr,lf
dos_0F  DB 'DOS: invalid drive',cr,lf
dos_10  DB 'DOS: current directory',cr,lf
dos_11  DB 'DOS: not same device',cr,lf
dos_12  DB 'DOS: no more files',cr,lf
dos_13  = THIS BYTE
messages ENDS

; --------------------------------------------------------------------
push_reg MACRO regs
        IRP reg,<regs>
          push reg
        ENDM
        ENDM

; --------------------------------------------------------------------
pop_reg MACRO regs
        IRP reg,<regs>
          pop reg
        ENDM
        ENDM

;=====================================================================
code    SEGMENT WORD PUBLIC 'code'
ASSUME  cs : code, ds : data, es : nothing

PUBLIC  err_dos, err_abort, err_mes, err_dos_ptr

; l0100 --------------------------------------------------------------
err_dos PROC NEAR
        call  err_dos_ptr
        call  err_mes
l0100:  mov   ax,4C01H                        ;exit from a process
        int   dos                             ;returncode = 01
        jmp   l0100
err_dos ENDP

; l0200 --------------------------------------------------------------
err_abort PROC NEAR
        call  err_mes                         ;meldung ausgeben
l0200:  mov   ax,4C02H                        ;exit from a process
        int   dos                             ;returncode = 02
        jmp   l0200
err_abort ENDP

; l0300 --------------------------------------------------------------
err_mes PROC NEAR
        push_reg <ax,bx,cx,ds>                ;register sichern
        mov   ax,es
        mov   ds,ax                           ;ds:dx auf meldung
        mov   bx,err_device
        mov   ah,40H                          ;write a file
        clc
        int   dos
        pop   ds
        jnc   l0300
        mov   err_status,ax                   ;bei dos-fehler setzen
l0300:  pop_reg <cx,bx,ax>
        ret
err_mes ENDP

; l0400 --------------------------------------------------------------
err_dos_ptr PROC NEAR
        push  bx
        cmp   ax,0013H
        jb    l0400                           ;gültiger error code
        mov   bx,000EH * 2                    ;unbekannter code
        jmp   l0401
l0400:  mov   bx,ax
        shl   bx,1                            ;words addressieren
l0401:  mov   dx,SEG messages
        mov   es,dx                           ;es auf das seg der meldungen
        mov   dx,es:[err_table+bx]            ;offset der meldung
        mov   cx,es:[err_table+2+bx]          ;offset der folgenden meldung
        sub   cx,dx                           ;cx := länge der meldung
        pop   bx
        ret
err_dos_ptr ENDP

code    ENDS

;=====================================================================
        END
