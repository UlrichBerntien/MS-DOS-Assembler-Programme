        TITLE *** wall, a game ***
        PAGE 70,132
;=====================================================================
; MS-Macro-Assembler V1.10 /Wang PC
; (c) Ulrich Berntien .07.1989
;   letzte Änderung 16.07.1989
;=====================================================================
; Die Register (nicht Flags) werden bei allen Procs erhalten.
; DS immer auf das DATA segment
; CS immer auf das CODE segment
; alle Procs sind vom Typ NEAR
; trift eine Proc auf einen DOS-Fehler, so wird er i.a. über Carry
; weitergmeldet und der error-code aus AX in err_status abgelegt.
;=====================================================================
; ES bleibt auch immer auf DATA segment

dos = 21H
escape = 01BH
cr = 0DH
lf = 0AH
tab = 0BH
cls = 0CH
underscore = 0020H                     ;bildschirm zeichen
overscore = 0010H
brettline = 23
targetlines = 3                        ;anzahl der zielzeilen
keyboard = 10E8H                       ;keyboard port

;=====================================================================
data    SEGMENT PUBLIC 'data'

contrblock STRUC                              ;kontrollblock für eine Zielzeile
  speed DB ?                           ;geschw der Zeile max +,- 128
  now   DB 0                           ;zum summieren der subspalten bewegung
  row   DB ?                           ;in diese bildschirmzeile
  shift DB 0                           ;spalten um die zeile geschoben ist
  loc   DW ?                           ;adresse der targetzeile in DATA
  chr   DW ?                           ;bildschirmzeichen für targetzeile
contrblock ENDS

line_c  contrblock <+10,, 2,, line,       08100H>
len_block = $ - line_c
        contrblock <-10,, 3,, line+80*2,  08700H>
        contrblock <+10,, 4,, line+160*2, 0EB00H>
line    DW 80 DUP (0)                  ;die zielzeilen
        DW 80 DUP (0)
        DW 80 DUP (0)

brett   DW 2002H,2002H                 ;invert. blanks
brettnow DB 0
brettpos DB 40

hello   DB    cls,escape,'[5h',tab,tab,tab,'W A L L',cr,lf,lf
        DB    'Steuern mit den Taste 1 2 4 6 7 9 + * des',cr,lf
        DB    'Zehnerblocks.',cr,lf,lf
        DB    'Starten mit <RETURN>','$'

bye     DB    cls,escape,'[5l','$'

data    ENDS

;=====================================================================
code    SEGMENT PUBLIC 'code'
ASSUME  cs : code, ds : data, ss : stack, es : nothing

; MODUL scr
EXTRN scr_init : NEAR, scr_put : NEAR, scr_put_ln : NEAR

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
        mov   ax,ds
        mov   es,ax                           ;es aud DATA segment
        call  scr_init                        ;modul scr initialisieren
        call  init

        mov   cx,2000
l01FF:  call  one_round
        mov   bl,4
        call  MS10
        loop  l01FF

        call  termit
l0100:  mov   ax,4C00H                        ;exit form a process
        int   dos
        jmp   l0100
main    ENDP

; l0200 --------------------------------------------------------------
              ;initialisieren des bildschirms
init    PROC NEAR
        push  ax
        push  cx
        push  bx
        push  dx
        push  si
        push  di
        ;------------ hello text ausgeben ----------------------
        mov   ah,09H                          ;print a string
        mov   dx,offset hello                 ;say hello
        int   dos
        mov   ah,07H                          ;direct keyboard input
l0200:  int   dos
        cmp   al,cr                           ;wait for return
        jne   l0200
        mov   ah,06H                          ;direct console i/o
        mov   dl,cls                          ;cls to screen
        int   dos
        ;------------ ziel zeilen vorbereiten ------------------
        mov   cx,targetlines                  ;anzahl der zielzeilen
        mov   si,offset line_c
l0201:  mov   bx,[si].loc                     ;adr der zielzeile
        mov   ax,bx
        add   ax,80*2                         ;hier ende der Zeile
        mov   dx,cx
        shl   dx,1                            ;dx := schrittweite der besetzung
        mov   di,[si].chr                     ;aussehen auf dem bildschrim
l0202:  mov   [bx],di
        add   bx,dx
        cmp   bx,ax
        jle   l0202                           ;bis ende der zeile
        call  print_line                      ;diese zeile auf den bildschrim
        add   si,len_block
        loop  l0201                           ;bis alle zeilen gesetzt
        ;------------ rahmenzeilen auf screen ------------------
        mov   ax,4F01H                        ;die Zeile 1 (zweite von oben)
        mov   dx,underscore
l0203:  call  scr_put
        dec   ah
        jnz   l0203
        mov   ax,4F18H                        ;die unterste Zeile
        mov   dx,overscore
l0204:  call  scr_put
        dec   ah
        jnz   l0204
        pop   di
        pop   si
        pop   dx
        pop   cx
        pop   bx
        pop   ax
        ret
init    ENDP

; l0300 --------------------------------------------------------------
termit  PROC NEAR
        push  ax
        push  dx
        mov   ax,0C00H                        ;input buffer flush
        int   dos
        mov   ah,09H                          ;print a string
        mov   dx,offset bye                   ;say bye
        int   dos
        pop   dx
        pop   ax
        ret
termit  ENDP

; l0400 --------------------------------------------------------------
              ;einmal alles bewegen
one_round PROC NEAR
        push  cx
        push  si
        mov   cx,targetlines
        mov   si,offset line_c
l0400:  call  move_line
        add   si,len_block
        loop  l0400
        pop   si
        pop   cx
        ret
one_round ENDP

; l0500 --------------------------------------------------------------
              ;bewegt eine targetzeile, -> SI auf contrblock der zeile
move_line PROC NEAR
        push  ax
        mov   ax,WORD PTR [si].speed          ;al := speed, ah := now
        add   ah,al
        mov   [si].now,ah
        jno   l0500
        mov   al,[si].shift
        js    l0502
        dec   al
        jge   l0503
        mov   al,79
        jmp   l0503
l0502:  inc   al
        cmp   al,80
        jl    l0503
        xor   al,al
l0503:  mov   [si].shift,al
        call  print_line
l0500:  pop   ax
        ret
move_line ENDP

; l0600 --------------------------------------------------------------
move_brett PROC NEAR
        ret
move_brett ENDP

; l0700 --------------------------------------------------------------
              ;gibt die geschwindigkeit des brettes in AL zurück
brett_speed PROC NEAR
        push  dx
        mov   dx,keyboard
        in    al,dx
        test  al,80H                          ;taste gedrückt ?
        cmp   al,31H
        jz    l0700
        and   al,0FFH-080H
        ja    l0701
        jb    l0702
l0701:  cmp   al,50H
        ja    l0703
        jb    l0704
        mov   al,
l0703:  cmp   al,60H
        jne   l0700
l0704:  cmp   al,41H
        jne   l0700
l0702:  cmp   al,16H
        ja    l0705
        jb    l0706
l0705:  cmp   al,17H
        jne   l0700
l0706:  cmp   al,14H
        ja    l0700
        jb    l0707
l0707:  cmp   al,10H
        jne   l0700
l0700:  pop   dx
        ret
brett_speed ENDP

; l0800 --------------------------------------------------------------
        ;gibt eine targetzeile aus, -> SI auf contrblock der zeile
print_line PROC NEAR
        push  ax
        push  cx
        push  dx
        mov   ax,WORD PTR [si].row            ;al := row, ah := shift
        mov   dx,[si].loc                     ;ds:dx auf die zeile
        mov   cx,80
        sub   cl,ah                           ;cx := länge der zeile
        call  scr_put_ln
        shl   cx,1                            ;pro bildschrimzeichen ein word
        add   dx,cx                           ;ds:dx auf den rest der zeile
        mov   cl,ah                           ;länge des restes
        xor   ah,ah                           ;den anfang der bildschirmzeile
        call  scr_put_ln
        pop   dx
        pop   cx
        pop   ax
        ret
print_line ENDP

; l0900 --------------------------------------------------------------
              ;wartet ca. BL 1/100 sekunden
MS10    PROC NEAR
        push  ax
        push  bx
        push  cx
        push  dx
l0901:  mov   ah,2CH                          ;get time
        int   dos
        mov   bh,dl                           ;1/100 sec
l0900:  mov   ah,2CH
        int   dos
        cmp   bh,dl                           ;warte auf nächste 1/100 sec
        je    l0900
        dec   bl                              ;so viele 1/100 sec warten
        jnz   l0901
        pop   dx
        pop   cx
        pop   bx
        pop   ax
        ret
MS10    ENDP

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
