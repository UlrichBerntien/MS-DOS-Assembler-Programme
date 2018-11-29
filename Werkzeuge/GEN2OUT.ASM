;---------------------------------------------------------------------
; Ausgeben des Zeichenvorrarts in ein ASCII-File
; MS-Macro-Assembler V1.10 / Wang PC
; (c) Ulrich Berntien .12.1990
;     letzte Änderung .12.1990
;---------------------------------------------------------------------

space = 32                                    ;assii zeichen
cr = 0DH
lf = 0AH
dotchr = '#'
nodotchr = space
atchr = '@'
stdout = 1                                    ;ausgabe gerät
zeilen = 12                                   ;format der zeichen
spalten = 10

;=====================================================================
data    SEGMENT WORD 'DATA'

sib     DW ?                                  ;daten für monitorkarte
status  DW ?                                  ;  ansteuerrung
outport DW ?

image   DW zeilen DUP (?)                     ;buffer für gen.image

buffersize = 1024                             ;größe des ausgabe buffers
optr    DW 0                                  ;auf letztes zeichen im buffer
obuffer DB buffersize DUP (?)                 ;ausgabe buffer

achar   DB (?)                                ;variable in main

data    ENDS

;=====================================================================
code    SEGMENT WORD 'CODE'

ASSUME cs : code, ds : data, es : nothing, ss : stack

; Schreibt den Buffer in die Standart-Ausgabe
; setzt nicht den buffer pointer zurück !!
; ARGS : -
; RETS : -
; REGS : SI,DI,BP,Segmente erhalten
;-----------------------------------------------------------------0000
writebuffer PROC NEAR
        mov   cx,optr                         ;anzahl der bytes im buffer
        jcxz  l0000
        mov   bx,stdout                       ;device handle
        mov   dx,OFFSET obuffer               ;ds:dx buffer ads
        mov   ah,40H                          ;write file or device
        int   21H                             ;dos call
l0000:  ret
writebuffer ENDP

; Ein Zeichen in den Buffer schreiben
; ARGS : AL mit dem Zeichen
; RETS : -
; REGS : AX,DI,SI,BP,Segmente erhalten
;-----------------------------------------------------------------0100
inbuffer PROC NEAR
        mov   bx,optr                         ;position im buffer
        cmp   bx,buffersize                   ;ist buffer voll
        jl    l0100                           ;nein
        push  ax
        call  writebuffer                     ;buffer wegschreiben
        pop   ax
        xor   bx,bx                           ;buffer ist wieder leer
l0100:  mov   [obuffer+bx],al                 ;zeichen im buffer speichern
        inc   bx                              ;ein zeichen weiter
        mov   optr,bx                         ;buffer pointer speichern
        ret
inbuffer ENDP

; CR,LF in den Buffer schreiben
; ARGS : -
; RETS : -
; REGS : DI,BP,Segment erhalten
;-----------------------------------------------------------------0700
endline PROC NEAR
        mov   al,cr
        call  inbuffer                        ;cr schreiben
        mov   al,lf
        call  inbuffer                        ;lf schreiben
        ret
endline ENDP

; schreibt das Word aus AX in den Buffer in ASCII Format
; ARGS: AX die auszugebende Zahl
; RETS: -
; REGS: BP,Segment erhalten
;-----------------------------------------------------------------0800
bufferint PROC NEAR
        xor   di,di                           ;di := 0
        mov   cx,10                           ;basis 10
l0801:  xor   dx,dx                           ;dx := 0
        div   cx
        push  dx                              ;rest speichern
        inc   di                              ;ziffer zählen
        or    ax,ax                           ;alle ziffern berechnet?
        jnz   l0801                           ;nein
l0800:  pop   ax                              ;ziffer holen
        add   al,'0'                          ;ziffer in ascii
        call  inbuffer
        dec   di                              ;ziffern zählen
        jnz   l0800
        ret
bufferint ENDP

; ein WORD aus dem Bildschirm-Speicher lesen
; ARGS : SI, Adresse
; RETS : AX mit dem Word
; REGS : CX,BP,SI,DI,DS,CS,SS erhalten
;-----------------------------------------------------------------0200
readw   PROC NEAR
        mov   dx,outport                      ;port zur monitor karte
        mov   es,sib                          ;segemnt des sib lesen
        mov   bx,status                       ;adr des 1.statusbytes
        mov   al,es:[bx]                      ;status lesen
        and   al,0CH
        or    al,01H                          ;signal für karte erzeugen
        mov   bx,0F200H                       ;segment des zeichengen.
        mov   es,bx
        out   dx,al                           ;signal an die karte
        mov   ax,es:[si]                      ;zeichen lesen
        ret
readw   ENDP

; ein Zeichenimage in den Buffer laden
; ARGS : AL mit dem Zeichencode
; RETS : image gestzt
; REGS : BP,Segmente erhalten
;-----------------------------------------------------------------0300
readg   PROC NEAR
        push  es                              ;regs sichern
        xor   ah,ah                           ;ax := al
        mov   cl,5
        sal   ax,cl                           ;ax := ax * 32
        add   ax,2
        mov   si,ax                           ;si = adresse des bit-image
        mov   cx,zeilen
        mov   di,OFFSET image
l0300:  call  readw                           ;ein word lesen
        mov   [di],ax                         ;word des image speichern
        add   di,2                            ;nächstes word des image buffers
        add   si,2                            ;nächste word des gen.image
        loop  l0300                           ;words zählen
        pop   es                              ;regs zurückholen
        ret
readg   ENDP

;Ausgeben eines Characters
; ARGS : AL das auszugebende Zeichen
; RETS : -
; REGS : BP, Segmente erhalten
;-----------------------------------------------------------------0600
charout PROC NEAR

ss06    STRUC                                 ;struktur der lokalen daten
  count   DW ?
  nr      DW ?
ss06    ENDS

        push  bp
        sub   sp,SIZE ss06                    ;lokale daten auf stack
        mov   bp,sp
        call  readg                           ;zeichen image lesen
        mov   [bp.count],zeilen               ;12 words lang
        mov   di,OFFSET image                 ;fptr auf den image buffer
l0603:  mov   [bp.nr],spalten                 ;10 bits im word genützt
        mov   cl,16-spalten                   ;die ersten 6 bits ungenutzt
        sal   WORD PTR [di],cl
l0602:  shl   WORD PTR [di],1                 ;höchstes bit ins carry
        jc    l0600                           ;das bit auswerten
        mov   al,nodotchr                     ;bit nicht gesetzt
        jmp   SHORT l0601
l0600:  mov   al,dotchr                       ;bit gestezt
l0601:  call  inbuffer                        ;ausgeben
        dec   [bp.nr]                         ;bits zählen
        jnz   l0602                           ;bis alle bits ausgegeben
        call  endline                         ;zeile abschließen
        add   di,2                            ;auf nächstes word
        dec   [bp.count]                      ;words zählen
        jnz   l0603
        add   sp,SIZE ss06                    ;lokale daten vom stack
        pop   bp
        ret
charout ENDP

; Initialisierung der Grafik-Routinen
; ARGS : -
; RETS : lobale Varibalen setzten
; REGS : -
;-----------------------------------------------------------------0400
init    PROC NEAR
        mov   al,01                           ;zeiger auf sys.config table
        int   88H                             ;bios call
        mov   sib,es                          ;screen interface segment
        mov   bx,es:[bx+0AH]                  ;adr des sib
        mov   dh,es:[bx+13H]                  ;high byte des ports
        mov   dl,10H                          ;low byte des ports
        mov   outport,dx                      ;port numer speichern
        add   bx,8                            ;bx auf status byte
        mov   status,Bx                       ;die adr speichern
        ret                                   ;zurück
init    ENDP

; Hauptprogramm
;-----------------------------------------------------------------0500
main    PROC FAR
        mov   ax,SEG data
        mov   ds,ax                           ;daten segment setzten
        call  init                            ;zugriff auf chargen. vorbereitn
        mov   al,atchr
        call  inbuffer
        mov   ax,zeilen                       ;zeilen,spalten ausgeben
        call  bufferint
        mov   al,','
        call  inbuffer
        mov   ax,spalten
        call  bufferint
        call  endline
        mov   al,space
l0500:  mov   achar,al                        ;zeichen speichern
        mov   al,atchr
        call  inbuffer
        mov   al,achar
        call  inbuffer
        call  endline                         ;eol zeichen ausgeben
        mov   al,achar
        call  charout                         ;zeichen ausgeben
        mov   al,achar
        inc   al                              ;nächstes zeichen
        jno   l0500
        call  writebuffer                     ;buffer leeren
l0501:  mov   ax,4C00H                        ;programm beenden
        int   21H                             ;dos call
        jmp   l0501
main    ENDP

code    ENDS

;=====================================================================
stack   SEGMENT WORD STACK
        DW 512 DUP (?)
stack   ENDS

        END main
