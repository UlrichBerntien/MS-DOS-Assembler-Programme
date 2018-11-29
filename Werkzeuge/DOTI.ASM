        PAGE 60,132
;---------------------------------------------------------------------
;  MS-Macro-Assembler V1.1
;
;   Einzige Aufgabe dieses Programmes ist die Beschäftigung der CPU.
;   Es werden zwischen durch Punkte ausgegeben, dann ist ein
;   Abbrechen mit CTRL-C möglich.
;
;  Ulrich Berntien .10.1992
;
;  09.10.1992  Beginn
;---------------------------------------------------------------------

CR      EQU 0DH
LF      EQU 0AH

_data   SEGMENT WORD PUBLIC 'DATA'

text    DB CR,LF
        DB 'DOTI        .10.1992      Ulrich Berntien', CR, LF
        DB LF
        DB 'Einzige Aufgabe dieses Programmes ist die', CR, LF
        DB 'Beschäftigung der CPU.', CR, LF
        DB 'Es werden zwischen durch ...... ausgegeben', CR, LF
        DB 'dann ist ein Abbrechen mit CTRL-C möglich.', CR, LF
        DB LF
        DB '$'

_data   ENDS

_text   SEGMENT WORD PUBLIC 'CODE'

        ASSUME CS : _text, DS : _data, ES : _stack

;---------------------------------------------------------------------
main    PROC FAR
        mov   ax, SEG _data
        mov   ds, ax

        mov   ah,09H                          ;ausgabe eines strings
        mov   dx,OFFSET text
        int   21H

a:      mov   cx,20

b:      mov   si,cx
        mov   cx,20000

c:      mov   ax,4545
        mul   cx
        loop  c

        mov   cx,si
        loop  b

        mov   ah,02H                          ;ausgabe eines zeichens
        mov   dl,'.'
        int   21H

        jmp   a

main    ENDP

_text   ENDS

_stack  SEGMENT WORD STACK 'STACK'
        DB 512 DUP (?)
_stack  ENDS

        END main
