        PAGE 80,132
        .SALL
;=====================================================================
; MS-Macro-Assembler V1.10 / Wang PC
; (c) Ulrich Berntien .06.1991
;     letzte Änderung .06.1991
;=====================================================================
; Möglichst hohe IBM Kompatibilität erreichen durch teilweise
; Emulation des IBM-BIOS
; und IBM Zeichensatz installieren
;=====================================================================
; linken mit IBM2.ASM, IBM3.ASM
;=====================================================================

INCLUDE ibmi.asm

stdoutdev EQU 01
stderrdev EQU 02

;=====================================================================
resident SEGMENT WORD PUBLIC
resident ENDS

;=====================================================================
data    SEGMENT WORD PUBLIC 'data'

PUBLIC installflag, usefpu, usetimer

installflag DB false              ;true => residenter teil zurücklassen
usefpu      DB true               ;true => emulator soll 8087 melden
usetimer    DB false              ;true => timer interrupt emulieren

pspseg      DW ?                  ;segment des prpgram segment präfix

err1    DB 'DOS-Error: '                      ;einleitung dos fehler
err1len EQU $ - err1
err2    DB 'BIOS-Error: '                     ;einl. bios fehler
err2len EQU $ - err2
err3    DB cr,lf,'Programm bendet',cr,lf      ;abschluss
err3len EQU $ - err3

msg0    DB 'IBM Emulator (C) Ulrich Berntien 1991',cr,lf
msg0len EQU $ - msg0
msg1    DB 'Residenter Teil installiert',cr,lf
msg1len EQU $ - msg1

dos_table EQU THIS BYTE                       ;tabelle der dos meldungen
        message 001H,'invalid function'
        message 002H,'file not found'
        message 003H,'path not found'
        message 004H,'too many open files'
        message 005H,'access denied'
        message 006H,'invalid handle'
        message 007H,'memory block bad'
        message 008H,'not enough memory'
        message 009H,'invalid block'
        message 00CH,'invalid access'
        message 00DH,'invalid data'
        message 00FH,'invalid drive'
        message 000H,'no error occured'       ;mit 0000 beneden

bios_table EQU THIS BYTE                      ;tabelle der bios meldungen
        message 001H,'Function Index is invalid'
        message 002H,'Function not jet implemented'
        message 003H,'Invalid parameter(s) specified'
        message 004H,'Operation impossible'
        message 005H,'Event queue or keyboardbuffer full'
        message 006H,'Invalid QID specified'
        message 007H,'Invalid screen indec specified'
        message 008H,'Resource allocation denied'
        message 009H,'Internal error'
        message 000H,'function completed normaly'

data    ENDS

;=====================================================================
code    SEGMENT WORD PUBLIC 'code'
ASSUME  ds : data, cs : code, ss : stack

EXTRN install    : NEAR
EXTRN setibmfont : NEAR

PUBLIC stdout

; Ausgabe auf Standartausgabe
; ARGS: DS:DX auf einen Meldungstext
;       CX die Länge des Textes
; RETS: -
; REGS: alle erhalten
;-------------------------------------------------------------------05
stdout PROC NEAR
        pushing <ax,bx>
        mov   bx,stdoutdev                    ;ausgabe gerät
        mov   ah,40H                          ;write a file
        dos
        poping <bx,ax>
        ret
stdout ENDP

; Programm benenden
; Falls installflag true, dann
; ARGS: -
; RETS: -
; REGS: DS auf data
;-------------------------------------------------------------------00
termit  PROC NEAR
        cmp   installflag, true
        jne   l0000                           ;programm einfach benenden

        mov   es,pspseg
        mov   es,es:[002CH]                   ;segment des enviroments
        mov   ah,49H                          ;free allocated memory
        dos

        lea   dx,msg1                         ;meldung ausgeben
        mov   cx,msg1len
        call  stdout

        mov   dx,ds                           ;bis dahin resident
        sub   dx,pspseg                       ;länge des teils
        inc   dx                              ;aufrunden
        mov   ax,3100H                        ;keep process
        dos

l0000:  mov   ax,4C00H                        ;terminate
        int   21H                             ;dos direkt aufrufen !
        jmp   l0000
termit  ENDP

; Gibt Meldung auf das Standart-Error-Device
; ARGS: DS:DX auf den Meldungstext
;       CX die LÄnge des Textes
; RETS: -
; REGS: alle erhalten
;-------------------------------------------------------------------06
printerr PROC NEAR
        pushing <ax,bx>
        mov   bx,stderrdev                    ;ausgabe gerät
        mov   ah,40H                          ;write a file
        int   21H                             ;dos direkt aufrufen !
        poping <bx,ax>
        ret
printerr ENDP

; Behandelt Fehlerausgabe
; ARGS: AL mit Fehlercode
;       SI mit ADR einer Fehlercodetabelle
;       DX mit ADR einer einleitenden Meldung
;       CX mit Länge der     -"-
; RETS: DS auf data
; REGS: -
;-------------------------------------------------------------------04
errout  PROC NEAR
        mov   bx,SEG data
        mov   ds,bx                           ;ds auf data setzen
        call  printerr                        ;einleitugn ausgeben

        mov   cl,al                           ;fehlernummer in cl
l0402:  mov   ax,[si]
        cmp   ah,cl                           ;stimmt die fehlernummer ?
        je    l0401                           ;  ja
        or    ah,ah                           ;ende der tabelle ?
        jz    l0401                           ;  ja
        xor   ah,ah                           ;ax := al
        add   si,ax                           ;auf nächsten eintrag
        jmp   l0402                           ;schleife über die tabelle

l0401:  xor   ah,ah                           ;ax := al
        mov   cx,ax
        sub   cx,2                            ;länge der fehlermeldung
        lea   dx,[si+02]                      ;dx auf den text
        call  printerr                        ;text ausagben

        lea   dx,err3                         ;abschluß meldung
        mov   cx,err3len
        call  printerr

        jmp   termit                          ;programm beneden
errout  ENDP

PUBLIC doserr

; Falls DOS Fehler aufgetreten ist, bebendet das Programm
; ARGS: AL mit DOS Fehlercode
; RETS: -
; REGS: -
;-------------------------------------------------------------------01
doserr  PROC NEAR
        lea   dx,err1                         ;einleitende meldung
        mov   cx,err1len
        lea   si,dos_table                    ;tabelle mit meldungen
        jmp   errout
doserr  ENDP

PUBLIC bioserr

; Falls BIOS Fehler aufgetreten ist, bebendet das Programm
; ARGS: AL mit BIOS Fehlercode
; RETS: -
; REGS: -
;-------------------------------------------------------------------02
bioserr PROC NEAR
        lea   dx,err2                         ;auf einleitende meldung
        mov   cx,err2len
        lea   si,bios_table                   ;auf tabelle mit meldungen
        jmp   errout
bioserr ENDP

; Hauptprogramm
;-------------------------------------------------------------------03
main    PROC FAR
        mov   ax,SEG data
        mov   ds,ax                           ;ds auf data segment
        mov   pspseg,es                       ;psp speichern

        lea   dx,msg0
        mov   cx,msg0len
        call  stdout                          ;meldung ausgeben

        call  install                         ;ggf. installieren
        call  setibmfont
        jmp   termit
main    ENDP

code    ENDS

;=====================================================================
stack   SEGMENT WORD STACK 'stack'
        DB 512 DUP (?)
stack   ENDS

        END main
