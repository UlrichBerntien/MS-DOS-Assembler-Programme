;---------------------------------------------------------------------
; Ausgeben des Zeichenvorrarts in ein Assembler-Format
; MS-Macro-Assembler V1.10 / Wang PC
; (c) Ulrich Berntien .06.1991
;     letzte Änderung .06.1991
; entstanden aus   GEN2ASCII.ASM
;---------------------------------------------------------------------

space = 32                                    ;assii zeichen
cr = 0DH
lf = 0AH
stdout = 1                                    ;ausgabe gerät

zeilen = 12                                   ;format der zeichen

;=====================================================================
data    SEGMENT WORD 'DATA'

sib     DW ?                                  ;daten für monitorkarte
status  DW ?                                  ;  ansteuerrung
outport DW ?

image   DW zeilen DUP (?)                     ;buffer für gen.image

buffersize = 2048                             ;größe des ausgabe buffers
optr    DW 0                                  ;auf letztes zeichen im buffer
obuffer DB buffersize DUP (?)                 ;ausgabe buffer

achar   DW 0                                  ;variable in main

outblock EQU THIS BYTE

        DB 'DW '
noffset DB '....H  ; '
nchar   DB '..H',cr,lf,'  DW '
nfont   DB 11 DUP ('...H,')
        DB '...H',cr,lf,00

data    ENDS

;=====================================================================
code    SEGMENT WORD 'CODE'

ASSUME cs : code, ds : data, es : nothing, ss : stack

; Schreibt den Buffer in die Standart-Ausgabe
; setzt nicht den buffer pointer zurück !!
; ARGS : bx anzahl der Zeichen im buffer
; RETS : -
; REGS : SI,DI,BP,Segmente erhalten
;-----------------------------------------------------------------0000
writebuffer PROC NEAR
        mov   cx,bx                           ;anzahl der bytes im buffer
        jcxz  l0000
        mov   bx,stdout                       ;device handle
        lea   dx,obuffer                      ;ds:dx buffer ads
        mov   ah,40H                          ;write file or device
        int   21H                             ;dos call
l0000:  ret
writebuffer ENDP

; outblock in den Buffer schreiben
; ARGS : -
; RETS : -
; REGS : Segmente erhalten
;-----------------------------------------------------------------0100
inbuffer PROC NEAR
        lea   si,outblock
        mov   bx,optr                         ;position im buffer
l0102:  cmp   bx,buffersize                   ;ist buffer voll
        jl    l0100                           ;nein
        call  writebuffer                     ;buffer wegschreiben
        xor   bx,bx                           ;buffer ist wieder leer
l0100:  mov   al,[si]
        or    al,al                           ;00 => outblock zu ende
        jz    l0101
        mov   [obuffer+bx],al                 ;zeichen im buffer speichern
        inc   bx                              ;ein zeichen weiter
        inc   si
        jmp   l0102
l0101:  mov   optr,bx                         ;buffer pointer speichern
        ret
inbuffer ENDP

; schreibt das Word aus AX an Position DI in HEX Format
; ARGS: AX die auszugebende Zahl
;       CX Anzahl der Stellen
;       DI Adresse für den String
; RETS: -
; REGS: alle außer CX erhalten
;-----------------------------------------------------------------0800
writehex PROC NEAR
        push  ax
        push  bx
        push  di
        add   di,cx                           ;di hinter letzte Ziffer
        mov   bx,cx                           ;in bx die stellen zählen

l0800:  dec   di                              ;di eine Stelle nach vorn
        mov   cx,ax                           ;zahl merken
        and   al,01111B                       ;low nible auswählen
        add   al,'0'                          ;in ascii
        cmp   al,'9'
        jbe   l0801
        add   al,'A'-'0'-10
l0801:  mov   [di],al                         ;ziffer schreiben
        mov   ax,cx                           ;altes ax
        mov   cl,4
        sar   ax,cl                           ;nächstes nibble
        dec   bx                              ;stellen zählen
        jnz   l0800

        pop   di
        pop   bx
        pop   ax
        ret
writehex ENDP

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
;        AX Adresse des Fonts
; REGS : Segmente erhalten
;-----------------------------------------------------------------0300
readfont PROC NEAR
        push  es                              ;regs sichern
        xor   ah,ah                           ;ax := al
        mov   cl,5
        sal   ax,cl                           ;ax := ax * 32
        add   ax,2
        mov   si,ax                           ;si = adresse des bit-image
        push  si                              ;adresse merken
        mov   cx,zeilen
        lea   di,image
l0300:  call  readw                           ;ein word lesen
        mov   [di],ax                         ;word des image speichern
        add   di,2                            ;nächstes word des image buffers
        add   si,2                            ;nächste word des gen.image
        loop  l0300                           ;words zählen
        pop   ax                              ;adresse des fonts
        pop   es                              ;regs zurückholen
        ret
readfont ENDP

;Ausgeben eines Characters
; ARGS : AL das auszugebende Zeichen
; RETS : -
; REGS : Segmente erhalten
;-----------------------------------------------------------------0600
charout PROC NEAR
        xor   ah,ah                           ;ax := al
        lea   di,nchar
        mov   cx,2
        call  writehex                        ;zeichencode ausgeben
        call  readfont                        ;font lesen
        lea   di,noffset
        mov   cx,4
        call  writehex                        ;offset ausgeben
        mov   dx,zeilen                       ;12 words pro font
        lea   di,nfont
        lea   si,image

l0600:  mov   cx,3
        mov   ax,[si]
        call  writehex
        add   di,5                            ;auf nächste postion
        inc   si                              ;auf nächstes word
        inc   si
        dec   dx                              ;zeichen mitzählen
        jnz   l0600

        call  inbuffer                        ;ausgabe fertig
        ret
charout ENDP

; Initialisierung der Grafik-Routinen
; ARGS : -
; RETS : globale Variablen setzten
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

        xor   ax,ax
l0500:  mov   achar,ax
        call  charout
        mov   ax,achar
        inc   ax
        cmp   ax,0100H
        jb    l0500

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
