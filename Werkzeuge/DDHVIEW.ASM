        TITLE *** DEVICE DRIVER VIEW ***
        PAGE 60,132
;=====================================================================
; MS-Macro-Assembler V1.10
; (c) Ulrich Berntien .09.1989
;   letzte Änderung 16.02.1991
; wertet die Liste der Device Driver headers (DDH) aus.
; Idee : H.G.Joepgen ,MC September 1989 ,pp 68
;=====================================================================

con_out EQU word ptr 01H                      ;standartausgabe
LF      EQU byte ptr 0AH
CR      EQU byte ptr 0DH
blank   EQU byte ptr 20H

ddh     STRUC                                 ;device driver header
  next  DD (?)                           ;pointer to next driver header
                                         ; -1 if last driver
  attr  DW (?)                           ;attribut
  enque DW (?)                           ;pointer to device enqueue point
  serv  DW (?)                           ;pointer to device service point
  name  DB 8 DUP (?)                     ;character device: name field
                                         ;block device : one byte number
ddh     ENDS

;=====================================================================
data    SEGMENT WORD

hallo   DB     'Device Driver Header View'
        DB     ' . (c) Ulrich Berntien .09.1989',CR,LF
        DB     '(name, bei Block-Devices Anzahl der Units)',CR,LF,LF
hallo_len EQU $ - hallo

headl   DB     ' address  |  name     | attribut | blk |',CR,LF
        DB     '----------|-----------|----------|-----|------'
        DB     32 DUP ('-')
        DB     CR,LF
headl_len EQU $ - headl

line    DB     'xxxx:xxxx |  xxxxxxxx |   xxxx   | xxx | '
        DB     32 DUP ('x')
lineend EQU $
        DB     CR,LF
line_len EQU $ - line

yes     DB     'YES',0
no      DB     'NO ',0

attr_tt DW     0100000000000000B              ;attribut bits gesetzt
        DW     offset ioctl_t                 ;bedeutet:
        DW     0010000000000000B
        DW     offset noibm_t
        DW     1000000000000001B
        DW     offset sti_t
        DW     1000000000000010B
        DW     offset sto_t
        DW     1000000000000100B
        DW     offset nul_t
        DW     1000000000001000B
        DW     offset clk_t
        DW     0
        DW     0
ioctl_t DB     'IOCTRL ',0
noibm_t DB     'NONIBM ',0
sti_t   DB     'STI ',0
sto_t   DB     'STO ',0
nul_t   DB     'NULL ',0
clk_t   DB     'CLOCK ',0

data    ENDS

;=====================================================================
code    SEGMENT WORD
ASSUME cs:code, ds:data, es:stack

; l00XX --------------------------------------------------------------
        ; hauptprogramm
main    PROC NEAR
        mov   ax,seg data
        mov   ds,ax
        mov   dx,offset hallo                 ;say hallo
        mov   cx,hallo_len + headl_len
        mov   bx,con_out
        mov   ah,40H                          ;write a file
        int   21H
        mov   ah,52H                          ;get ptr to dos information block
        int   21H
        les   bp,dword ptr es:[bx+17H]        ;es:bp auf ersten ddh
        call  nextddh
l0001:  mov   ax,4c00H                        ;exit from process
        int   21H                             ;return code 00
        jmp   l0001
main    ENDP

; l01XX --------------------------------------------------------------
        ; register erhalten: DS
        ; klettert in der liste der ddh nach oben
        ; in ES:BP wird die adresse eines ddh erwartet
nextddh PROC NEAR
        mov   ax,es
        cmp   ax,0FFFFH                       ;war der letzte ddh ?
        jne   l0103                           ;  nein
        cmp   bp,0FFFFH
        jne   l0103                           ;  nein
        ret                                   ;  ja
l0103:  call  print_ddh                       ;den ddh ausgeben
        les   bp,es:[bp].next                 ;adresse des nächsten ddh
        jmp   nextddh                         ;zum nächsten ddh
nextddh ENDP

; l02XX --------------------------------------------------------------
        ; register erhalten: DS
        ; Ausgabe des DDH [ES:BP]
print_ddh PROC NEAR
        mov   di,offset line                  ;daten in druckzeile bringen
        mov   ax,es
        call  tohex4
        add   di,5
        mov   ax,bp
        call  tohex4
        add   di,8
        mov   cx,08                           ;name 8 zeichen lang
        test  es:[bp].attr,8000H              ;character device ?
        jz    l0201
        xor   si,si                           ;si := 0
l0203:  mov   ah,es:[bp+si].name
        mov   [di],ah                         ;zeichen übertragen
        inc   di
        inc   si                              ;auf nächstes zeichen
        loop  l0203
        mov   si,offset no
        jmp   SHORT l0202
l0201:  mov   al,es:[bp].name                 ;blk device
        xor   ah,ah                           ;ax := anzahl der units
        call  tohex4                          ;schreiben
        add   di,3
        sub   cx,4                            ;rest mit blanks füllen
        mov   ah,blank
l0204:  inc   di
        mov   [di],ah
        loop  l0204
        mov   si,offset yes
l0202:  mov   di,34 + offset line
        call  copyds                          ;blk device yes/no eintragen
        sub   di,11
        mov   ax,es:[bp].attr                 ;attribute word schreiben
        mov   cx,ax                           ;attribute in cx sichern
        call  tohex4                          ;das word schreiben
        add   di,14
        mov   bx,offset attr_tt               ;auf tabelle für die attribute
        mov   dx,[bx]
l0206:  mov   ax,cx
        and   ax,dx
        cmp   ax,dx
        jne   l0205                           ;trift das attribut zu ?
        mov   si,[bx+2]
        call  copyds                          ;ja, dann den text ausgeben
l0205:  add   bx,04                           ;nächstes attribut
        mov   dx,[bx]
        or    dx,dx                           ;0 => ende der liste
        jne   l0206
        mov   ah,blank
        jmp   SHORT l0207
l0208:  mov   [di],ah                         ;rest der zeile mit blanks füllen
        inc   di
l0207:  cmp   di,offset lineend
        jl    l0208
        mov   dx,offset line                  ;write the line
        mov   cx,line_len
        mov   bx,con_out
        mov   ah,40H                          ;write a file
        int   21H
        ret
print_ddh ENDP

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
        add   bl,'0'                          ;wert in ascii-zeichen wandlen
        cmp   bl,'9'
        jbe   l0301
        add   bl,'A'-'0'-10
l0301:  dec   di
        mov   [di],bl                         ;zeichen schreiben
        shr   ax,cl                           ;div 16
        dec   ch
        jnz   l0300                           ;bis alle zeichen ausgegeben
        pop   bx
        pop   cx
        ret
tohex4  ENDP

; l04XX --------------------------------------------------------------
copyds PROC NEAR
        ;nur SI wird verändert , DI wird aktualisiert
        ;copiert von DS:SI nach DS:DI bis im source 0 byte gefunden
        push  ax
        cld
        jmp   SHORT l0401
l0400:  mov   [di],al
        inc   di
l0401:  lodsb
        or    al,al
        jnz   l0400
        pop   ax
        ret
copyds ENDP

code    ENDS

;=====================================================================
stack   SEGMENT STACK WORD
        DB 0200H DUP (?)
stack   ENDS

        END main
