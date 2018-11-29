;---------------------------------------------------------------------
; aus .FON in den Zeichengenerator
; MS-Macro-Assembler V1.10 / Wang PC
; (c) Ulrich Berntien .06.1991
;     letzte Änderung .06.1991
; entstanden aus   GEN2ASCII.ASM
;---------------------------------------------------------------------
; Die .FON Datei aus dem
; Microsoft System Journal  März/April 1991
;---------------------------------------------------------------------

;=====================================================================
data    SEGMENT WORD 'DATA'

sib     DW ?                                  ;daten für monitorkarte
status  DW ?                                  ;  ansteuerrung
outport DW ?

fonname DB 'SCRN0808.FON',00                  ;Name der fon datei

buffersize = 4000                             ;größe des buffers
buffer DB buffersize DUP (?)                  ;buffer

data    ENDS

;=====================================================================
code    SEGMENT WORD 'CODE'

ASSUME cs : code, ds : data, es : nothing, ss : stack

; Lesen der Datei in den Buffer
; ARGS: -
; RETS: -
; REGS: Segment erhalten
;-----------------------------------------------------------------0100
readfon PROC NEAR
        lea   dx,fonname
        mov   ax,3D00H                        ;open file for reading
        int   21H
        jnc   l0100
        jmp   termit                          ;fehler, bebenden
l0100:  mov   bx,ax
        mov   cx,buffersize
        lea   dx,buffer
        mov   ah,3FH                          ;read a file
        int   21H
        mov   ah,3EH                          ;close a file
        int   21H
        ret
readfon ENDP

; ein WORD in den Bildschirm-Speicher schreiben
; ARGS : DI Adresse
;        AX mit dem Word
; RETS : -
; REGS : alle außer AX,BX,DX,BP,ES erhalten
;-----------------------------------------------------------------0200
writew  PROC NEAR
        mov   bp,ax                           ;das word merken
        mov   dx,outport                      ;port zur monitor karte
        mov   es,sib                          ;segemnt des sib lesen
        mov   bx,status                       ;adr des 1.statusbytes
        mov   al,es:[bx]                      ;status lesen
        and   al,0CH
        or    al,01H                          ;signal für karte erzeugen
        mov   bx,0F200H                       ;segment des zeichengen.
        mov   es,bx
        out   dx,al                           ;signal an die karte
        mov   es:[di],bp                      ;word schreiben
        ret
writew  ENDP

; ein Zeichenimage in den Generator schreiben
; ARGS : AL mit dem Zeichencode
; RETS : -
; REGS : nur AL, Segmente außer ES erhalten
;-----------------------------------------------------------------0300
writefont PROC NEAR
        push  ax

        xor   ah,ah                           ;ax := al
        mov   si,ax                           ;werte merken
        mov   cl,5
        sal   ax,cl                           ;ax := ax * 32
        add   ax,2
        mov   di,ax                           ;di = adresse des bit-image

        add   si,WORD PTR [buffer+10]
        mov   cl,3
        sal   si,cl                           ;bytes pro datensatz
        add   si,OFFSET buffer                ;si = adresse des datensatz

        xor   ax,ax
        call  writew
        add   di,2

        xor   ax,ax
        call  writew
        add   di,2

        mov   cx,08                           ;08 zeile vorhanden

l0300:  mov   al,[si]                         ;eine zeile lesen
        inc   si
        xor   ah,ah                           ;ax := al
        sal   ax,1                            ;zentrieren
        call  writew                          ;in generator setzen
        add   di,2                            ;nächste zeile im generator
        loop  l0300

        xor   ax,ax
        call  writew
        add   di,2

        xor   ax,ax
        call  writew

        pop   ax                              ;adresse des fonts
        ret
writefont ENDP

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
        call  readfon

        mov   al,01H
l0500:  call  writefont
        inc   al
        cmp   al,1FH
        jbe   l0500

        mov   al,80H
l0501:  call  writefont
        inc   al
        cmp   al,0FEH
        jbe   l0501

termit: mov   ax,4C00H                        ;programm beenden
        int   21H                             ;dos call
        jmp   termit
main    ENDP

code    ENDS

;=====================================================================
stack   SEGMENT WORD STACK
        DW 512 DUP (?)
stack   ENDS

        END main
