        TITLE *** keycodes ***
        PAGE 70,132
;=====================================================================
; MS-Macro-Assembler V1.10 /Wang PC
; (c) Ulrich Berntien .07.1989
;   letzte Änderung 16.07.1989
;
; gibt den Code der gedrückten Taste in hex aus.
; beendet wird das Programm mit CNTRL-C
;=====================================================================
; Die Register (nicht Flags) werden bei allen Procs erhalten.
; DS immer auf das DATA segment
; CS immer auf das CODE segment
; alle Procs sind vom Typ NEAR
; trift eine Proc auf einen DOS-Fehler, so wird er i.a. über Carry
; weitergmeldet und der error-code aus AX in err_status abgelegt.
;=====================================================================

dos = 21H
keyboard = 10E8H
ctrl_c = 03

;=====================================================================
data    SEGMENT PUBLIC 'data'
buf     DB 'hh        ','$'
last    DB ?
table   DB '0123456789ABCDEF'
data    ENDS

;=====================================================================
code    SEGMENT PUBLIC 'code'
ASSUME  cs : code, ds : data, ss : stack, es : nothing

; l0100 --------------------------------------------------------------
main    PROC NEAR
        mov   ax,SEG data                     ;ds auf data segment
        mov   ds,ax
        mov   bx,SEG top
        mov   ax,es
        sub   bx,ax                           ;bx := benötigter speicher in para
        mov   ah,4AH                          ;modify allocated block
        clc
        int   dos                             ;nicht benötigter speicher zurück
l0101:  call  get_code
        mov   dl,0FFH
        mov   ah,06H                          ;direct console i/o
        cmp   al,ctrl_c
        jne   l0101
l0100:  mov   ax,4C00H                        ;exit form a process
        int   dos
        jmp   l0100
main    ENDP

; l0200 --------------------------------------------------------------
get_code PROC NEAR
        push  ax
        push  dx
        push  di
        mov   dx,keyboard
        in    al,dx                           ;hole tastencode
        test  al,80H                          ;taste gedrückt ?
        jz    l0200
        and   al,0FFH-080H                    ;oberste bit ausblenden
        mov   ah,last
        cmp   ah,al
        je    l0200                           ;neue gedrückt
        mov   last,al
        mov   di,offset buf
        call  tohex2                          ;in hex-format
        mov   dx,di
        mov   ah,09H                          ;print string
        int   dos
l0200:  pop   di
        pop   dx
        pop   ax
        ret
get_code ENDP

; l0300 --------------------------------------------------------------
tohex2  PROC NEAR
              ; schreibt die zahl in AL in hex-format xx ab DS:DI
        push  ax
        push  cx
        push  bx
        mov   cx,0204H                        ;2 zeichen / 4 bits ein zeichen
        add   di,2                            ;auf least significant
l0300:  mov   bx,ax
        and   bx,1111B                        ;nur die untersten 4 bits
        mov   bl,[bx+table]                   ;wert in zeichen wandlen
        dec   di
        mov   [di],bl                         ;zeichen schreiben
        shr   ax,cl                           ;div 16
        dec   ch
        jnz   l0300                           ;bis alle zeichen ausgegeben
        pop   bx
        pop   cx
        pop   ax
        ret
tohex2  ENDP

code    ENDS

;=====================================================================
stack   SEGMENT STACK
        DB 0500H DUP (?)
stack   ENDS

;=====================================================================
top     SEGMENT PARA MEMORY
top     ENDS

;=====================================================================
        END main
