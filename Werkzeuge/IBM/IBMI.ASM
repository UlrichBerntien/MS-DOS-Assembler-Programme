; Include-File für IBM*.ASM Files

true  EQU 01
false EQU 00

lf        EQU 0AH
ff        EQU 0CH
cr        EQU 0DH
escape    EQU 1BH
space     EQU 20H
switchchr EQU '-'

; DOS-Aufruf mit Fehlerüberwachung
;---------------------------------------------------------------------
dos     MACRO
        LOCAL no_error
        clc
        int   21H
        jnc   no_error
        jmp   doserr
  no_error:
        ENDM

; BIOS-Aufruf mit Fehlerüberwachung
;---------------------------------------------------------------------
bios    MACRO
        LOCAL no_error
        int   88H
        or    al,al
        jz    no_error
        jmp   bioserr
  no_error:
        ENDM

; Eine Fehlermeldung speichern
;---------------------------------------------------------------------
message MACRO num,text
        LOCAL len, msg
  msg     DB len
          DB num
          DB text
  len EQU $ - msg
        ENDM

; Register auf dem Stack sichern
;---------------------------------------------------------------------
pushing MACRO regs
          IRP reg,<regs>
            push reg
          ENDM
        ENDM

; Register vom Stack zurückholen
;---------------------------------------------------------------------
poping  MACRO regs
          IRP reg,<regs>
            pop reg
          ENDM
        ENDM
