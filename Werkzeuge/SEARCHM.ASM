        TITLE ** SEARCH M **
        PAGE 60,132
;=====================================================================
; MS-Macro-Assembler V1.10
; (c) Ulrich Berntien .06.1989
;   letzte Änderung 25.06.1989
; wertet die Liste der Memory Control Blocks (MCB) aus.
; Idee : H.G.Joepgen ,MC Juli 1989 ,pp 44
; siehe auch: D.Strauß ,MC Juli 1987, pp 66
;=====================================================================

mcb_id  = byte ptr 04DH                       ;id-code eines mcb
last_mcb_id = byte ptr 05AH                   ;id-code des letzten mcb
con_out = word ptr 01H                        ;standartausgabe
LF = byte ptr 0AH
CR = byte ptr 0DH

mcb     STRUC                                 ;memory control block
        id       DB                           ;id byte
        ptr_psh  DW                           ;adresse des prog.seg. headers
        len      DW                           ;länge des belegten speichers
        intern   DB 11 DUP (0)
mcb     ENDS

;=====================================================================
data    SEGMENT
hallo   DB     'Memory Control Block Searcher'
        DB     ' . (c) Ulrich Berntien .06.1989',CR,LF,LF
hallo_len = $ - hallo
nolist  DB     'MCB liste nicht gefunden, sorry',CR,LF
nolist_len = $ - nolist
headl   DB     ' address  | length |free?|PSP-address|   content',CR,LF
        DB     '          |  byte  |     |           |          (all HEX)',CR,LF
        DB     '---------------------------------------'
        DB     '---------------------------------',CR,LF
headl_len = $ - headl
line    DB     'xxxx:0000 |  xxxx0 | --- | xxxx:0000 | '
        DB     'xx xx xx xx xx xx xx xx xx xx xx',CR,LF
line_len = $ - line
yes     DB     'YES'
no      DB     'NO '
table   DB     '0123456789ABCDEF'
data    ENDS

;=====================================================================
code    SEGMENT
ASSUME cs:code, ds:data, es:stack

; l00XX --------------------------------------------------------------
        ; hauptprogramm
main    PROC NEAR
        mov   ax,seg data
        mov   ds,ax
        mov   dx,offset hallo                 ;say hallo
        mov   cx,hallo_len
        mov   bx,con_out
        mov   ah,40H                          ;write a file
        int   21H
        mov   ah,52H                          ;get ptr to dos information block
        int   21H
        mov   ax,es:[bx-2]
        call  next
        jnc   l0001
        mov   dx,offset nolist                ;say sorry
        mov   cx,nolist_len
        mov   bx,con_out
        mov   ah,40H                          ;write a file
        int   21H
l0001:  mov   ax,4c00H                        ;exit from process
        int   21H                             ;return code 00
        jmp   l0001
main    ENDP

; l01XX --------------------------------------------------------------
        ; register erhalten: DS
        ; klettert in der liste der mcb nach oben
        ; in AX wird das segment eines mcb erwartet
        ; ist es kein mcb, so wird CARRY beim rücksprung gesetzt
next    PROC NEAR
        mov   es,ax
        mov   bl,byte ptr es:[0000].id
        cmp   bl,last_mcb_id                  ;der letzte mcb ?
        jne   l0103
        mov   dx,offset headl                 ;write headline of table
        mov   cx,headl_len
        mov   bx,con_out
        mov   ah,40H                          ;write a file
        int   21H
        jmp   l0104
l0103:  cmp   bl,mcb_id                       ;ein mcb ?
        jne   l0101
        add   ax,es:[0000].len
        inc   ax
        push  es
        call  next                            ;zum nächsten mcb
        pop   es
        jc    l0100                           ;bei fehler sofort zurück
l0104:  call  print_mcb
        clc                                   ;kein fehler carry löschen
        ret
l0101:  stc                                   ;fehler, carry setzen
l0100:  ret
next    ENDP

; l02XX --------------------------------------------------------------
        ; register erhalten: DS
        ; Ausgabe des MCB [ES:0000]
print_mcb PROC NEAR
        mov   di,offset line                  ;daten in druckzeile bringen
        mov   ax,es
        call  tohex4
        add   di,13
        mov   ax,[es:0000].len
        call  tohex4
        add   di,8
        cmp   [es:0000].ptr_psh,0000H         ;block frei ?
        jne   l0200
        mov   si,offset yes
        jmp   l0201
l0200:  mov   si,offset no
l0201:  mov   cx,03
l0202:  mov   al,[si]                         ;antwort schreiben
        mov   [di],al
        inc   di
        inc   si
        loop  l0202
        add   di,3                            ;die psh addresse schreiben
        mov   ax,[es:0000].ptr_psh
        call  tohex4
        add   di,12                           ;die internen daten ausgeben
        mov   cx,11
        mov   si,offset intern
l0205:  mov   al,[es:si]
        call  tohex2
        inc   di
        inc   di
        inc   di
        inc   si
        loop  l0205
        mov   dx,offset line                  ;write a line
        mov   cx,line_len
        mov   bx,con_out
        mov   ah,40H                          ;write a file
        int   21H
        ret
print_mcb ENDP

; l03XX --------------------------------------------------------------
        ; register erhalten : alle außer AX
        ; schreibt die zahl in AX in hex-format xxxx ab DS:DI
tohex4  PROC NEAR
        push  cx
        push  bx
        mov   cx,0404H                        ;4 zeichen / 4 bits ein zeichen
        add   di,04                           ;auf least significant
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
        ret
tohex4  ENDP

; --------------------------------------------------------------------
tohex2  PROC NEAR
        ; register erhalten : alle außer AX
        ; schreibt die zahl in AL in hex-format xx ab DS:DI
        push  cx
        push  bx
        mov   cx,0204H                        ;2 zeichen / 4 bits ein zeichen
        add   di,2                            ;auf least significant
        jmp   l0300
tohex2  ENDP

code    ENDS

;=====================================================================
stack   SEGMENT stack
        DB 5000H DUP (?)
stack   ENDS

        END main
