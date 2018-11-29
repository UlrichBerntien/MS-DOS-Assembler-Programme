        TITLE *** HANOI ***
        PAGE 70,132
;=====================================================================
; MS-Macro-Assembler V1.10 /Wang PC
; (c) Ulrich Berntien .07.1989
;   letzte Änderung 15.07.1989
;
; Die Türme von Hanoi in Assembler
;=====================================================================
; Die Register (nicht Flags) werden bei allen Procs erhalten.
; DS immer auf das DATA segment
; CS immer auf das CODE segment
; alle Procs sind vom Typ NEAR
; trift eine Proc auf einen DOS-Fehler, so wird er i.a. über Carry
; weitergmeldet und der error-code aus AX in err_status abgelegt.
;=====================================================================
; ES auch auf das DATA segment

dos = 21H
space = 20H                    ; Leerzeichen
cls = 0CH
tab = 09H
max = 13                       ; Anzahl der Scheiben

;=====================================================================
data    SEGMENT PUBLIC 'data'
        EVEN
pos     DB 24,14,24,40,24,65
scheibe DB 00010B              ;eine scheibe für den bildschirm
        DB max*2+1 DUP (space)
leer    DB 0000B               ;keine scheibe für den bildschirm
        DB max*2+1 DUP (0)
st_text DB cls,tab,tab,'D I E  T Ü R M E  V O N  H A N O I$'
data    ENDS

;=====================================================================
code    SEGMENT PUBLIC 'code'
ASSUME  cs : code, ds : data, ss : stack, es : nothing

; MODUL scr
EXTRN scr_init : NEAR , scr_print : NEAR

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
        call  scr_init                        ;modul scr initialisieren
        mov   ax,ds
        mov   es,ax                           ;es auch auf DATA segment
        call  game_init
        mov   cx,max                          ;anzahl der scheiben
        xor   ax,ax                           ;von stapel 0
        mov   bx,1                            ;über stapel 1
        mov   dx,2                            ;nach stapel 2
        call  move_turm
l0100:  mov   ax,4C00H                        ;exit form a process
        int   dos
        jmp   l0100
main    ENDP

; l0200 --------------------------------------------------------------
game_init PROC NEAR
        push  ax
        push  bx
        push  cx
        push  dx
        mov   dx,offset st_text
        mov   ah,09H                          ;print a string
        int   dos
        mov   BYTE PTR [pos+2],24-max         ;scheinbarer Turm
        mov   ax,1                            ;von dem scheinbaren turm
        xor   dx,dx                           ;zum turm 1
        mov   cx,max                          ;alle scheiben bewegen
l0200:  call  move_scheibe
        loop  l0200
        pop   dx
        pop   cx
        pop   bx
        pop   ax
        ret
game_init ENDP

; l0300 --------------------------------------------------------------
        ; einen turm bewegen
        ; cx = anzahl der scheiben
        ; ax = von diesem stapel
        ; bx = über diesen stapel
        ; dx = nach diesen stapel

        ; Algorithmus:
        ;  move_turm( scheiben, von, ueber, nach ) IS
        ;    IF scheiben > 0 THEN
        ;      move_turm( scheiben-1, von, nach, ueber )
        ;      move_scheibe( scheiben, von, nach )
        ;      move_turm( scheiben-1, ueber, von, nach )
        ;    ENDIF

move_turm PROC NEAR
        push  ax
        push  bx
        push  cx
        push  dx
move_turm_tail:
        dec   cx                              ;turm über unterste scheibe
        jz    l0300
        xchg  bx,dx
        call  move_turm
        inc   cx
        xchg  bx,dx
        call  move_scheibe
        dec   cx
        xchg  ax,bx
        jmp   move_turm_tail
l0300:  inc   cx                              ;turm nur aus einer scheibe
        jmp   move_scheibe_tail
move_turm ENDP

; l0400 --------------------------------------------------------------
        ; einen scheibe bewegen
        ; cx = größe der scheibe
        ; ax = von diesem stapel
        ; dx = nach diesen stapel
move_scheibe PROC NEAR
        push  ax
        push  bx
        push  cx
        push  dx
move_scheibe_tail:
        dec   cx
        shl   cx,1
        inc   cx                              ;cx := breite der scheibe in chars
        mov   bx,ax                           ;bx := von diesem stapel
        shl   bx,1                            ;words addressieren
        mov   ax,WORD PTR [pos+bx]
        inc   al                              ;turm geht nach untern
        mov   [pos+bx],al
        dec   al
        mov   bx,cx
        shr   bx,1                            ;halbe breite der scheibe
        sub   ah,bl                           ;ah auf anfang der scheibe
        mov   bx,dx                           ;bx := nach diesem stapel
        mov   dx,offset leer
        call  scr_print
        shl   bx,1                            ;words addressieren
        mov   ax,WORD PTR [pos+bx]
        dec   al                              ;turm geht nach oben
        mov   [pos+bx],al
        mov   bx,cx
        shr   bx,1                            ;halbe breite der scheibe
        sub   ah,bl                           ;ah auf anfang der scheibe
        mov   bx,dx
        mov   dx,offset scheibe
        call  scr_print
        pop   dx
        pop   cx
        pop   bx
        pop   ax
        ret
move_scheibe ENDP

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
