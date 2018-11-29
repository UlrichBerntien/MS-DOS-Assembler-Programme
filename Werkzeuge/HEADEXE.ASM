        TITLE *** Head EXE ***
        PAGE 60,132
        .SALL
;=====================================================================
; MS-Macro-Assmebler V1.10 /Wang PC
; (c) Ulrich Berntien .06.1990
;   letzte Änderung 10.06.1990
;
; Aufrufformat:
;       HEADEXE <EXECUTE-FILE-NAME>
;
; Das Programm setzt den Returncode:
;       00H => kein Fehler
;       01H => ein Fehler gefunden
;=====================================================================

stdout = 1                             ;standart ausgabe gerät
errout = 2                             ;standart gerät für fehlermeldungen
space = 20H                            ;ascii zeichen
cr = 0DH
lf = 0AH
hsize = 28                             ;bytes im header
ssize = 0200H                          ;größe des stacks in byte

;=====================================================================
data    SEGMENT WORD

sout    DB cr,lf,'Dateiname . . . . . . . . : '
fname   DB 64 DUP (space)
        DB cr,lf,'Signature . . . . . . . . : MZ'
        DB cr,lf,'# Bytes in last page. . . : '
lmod    DB '0000H    == '
lmodd   DB 6 DUP (space)
        DB cr,lf,'# 512-byte pages  . . . . : '
pages   DB '0000H    == '
pagesd  DB 6 DUP (space)
        DB cr,lf,'# entries in rel.table  . : '
relc    DB '0000H    == '
relcd   DB 6 DUP (space)
        DB cr,lf,'# paragraphs in header  . : '
parhead DB '0000H    == '
parheadd DB 6 DUP (space)
        DB cr,lf,'min # paragraphs required : '
parmin  DB '0000H    == '
parmind DB 6 DUP (space)
        DB cr,lf,'max # paragraphs required : '
parmax  DB '0000H    == '
parmaxd DB 6 DUP (space)
        DB cr,lf,'initial SS:SP . . . . . . : '
iss     DB '0000:'
isp     DB '0000H'
        DB cr,lf,'checksum  . . . . . . . . : '
chksum  DB '0000H'
        DB cr,lf,'initial CS:IP . . . . . . : '
ics     DB '0000:'
iip     DB '0000H'
        DB cr,lf,'offset of rel.table . . . : '
reloff  DB '0000H'
        DB cr,lf,'number of overlay . . . . : '
ovc     DB '0000H'
        DB cr,lf
sout_len = $ - sout

wohin   DW OFFSET lmod
        DW OFFSET pages
        DW OFFSET relc
        DW OFFSET parhead
        DW OFFSET parmin
        DW OFFSET parmax
        DW OFFSET iss
        DW OFFSET isp
        DW OFFSET chksum
        DW OFFSET iip
        DW OFFSET ics
        DW OFFSET reloff
        DW OFFSET ovc

wohind  DW OFFSET lmodd + 5
        DW OFFSET pagesd + 5
        DW OFFSET relcd + 5
        DW OFFSET parheadd + 5
        DW OFFSET parmind + 5
        DW OFFSET parmaxd + 5

nout    DB cr,lf,'Kein Execute-File.'
        DB cr,lf,'Signature: '
sign    DB '??',cr,lf
nout_len = $ - nout

buffer  DW hsize / 2 DUP (?)

perr    DB cr,lf,'Kein Dateiname als Parameter gefunden.',cr,lf
perr_len = $ - perr
rerr    DB cr,lf,'Fehler beim Einlesen der Datei.',cr,lf
rerr_len = $ - rerr

ziffern DB '0123456789ABCDEF'

data    ENDS

;=====================================================================
code    SEGMENT WORD

ASSUME cs : code, ds : data

; ARGS: DS:DX auf eine Ausgabe, CX Länge der Ausgabe
; Gibt die Ausgabe auf das Standartausgabegerät
; und bebendet das Program
;-----------------------------------------------------------------0200
stdend  PROC NEAR
        mov   ah,40H                          ;write a file
        mov   bx,stdout
        int   21H
l0200:  mov   ax,4C00H                        ;exit form a process
        int   21H
        jmp   l0200
stdend  ENDP

; ARGS: DS:DX auf eine Fehlermeldung, CX Länge der Fehlermeldung
; Gibt die Fehlermeldung aus und bebendet das Program
;-----------------------------------------------------------------0100
errend  PROC NEAR
        mov   ah,40H                          ;write a file
        mov   bx,errout
        int   21H
l0100:  mov   ax,4C01H                        ;exit form a process
        int   21H
        jmp   l0100
errend ENDP

; ARGS: ES auf den PSH
;       DS auf data
; RETS: ES:DX auf Filename, mit 00H abgeschlossen
;       und überträgt name in den 'sout' bereich
;-----------------------------------------------------------------0300
takename PROC NEAR
        mov   si,80H
        mov   cl,es:[si]                      ;anzahl der zeichen im parameter
        xor   ch,ch                           ;in cx laden
        jcxz  l0300
l0302:  inc   si                              ;auf erstes (nächstes) ziechen
        cmp   BYTE PTR es:[si],space          ;space und steuerzeichen
        ja    l0301                           ;     überlesen
        loop  l0302                           ;solang zeichen da sind
        jmp   SHORT l0300                     ;kein name gefunden
l0301:  mov   dx,si                           ;dort beginnt der filename
        mov   di,OFFSET fname                 ;dorthin den namen kopieren
l0304:  mov   al,es:[si]
        cmp   al,space                        ;gültiges zeichen ?
        jbe   l0303                           ;nein, dann name zu ende
        mov   [di],al
        inc   di                              ;auf nächstes zeichen
        inc   si
        loop  l0304
l0303:  mov   BYTE PTR es:[si],00H            ;name in asciz format
        ret
l0300:  mov   dx,OFFSET perr                  ;fehler aufgetreten
        mov   cx,perr_len
        jmp   errend
takename ENDP

; ARGS: ES:DX auf Filename
;       DS auf data
;-----------------------------------------------------------------0400
readfile PROC NEAR
        clc
        push  ds
        mov   ax,es
        mov   ds,ax                           ;ds:dx auf filename
        mov   ax,3D00H                        ;open file for reading
        int   21H
        pop   ds
        jc    l0400                           ;falls dos-fehler
        mov   bx,ax                           ;file handle in bx
        mov   cx,hsize
        mov   dx,OFFSET buffer
        mov   ah,3FH                          ;read a file
        int   21H
        jc    l0400
        cmp   ax,hsize                        ;alle bytes gelesen ?
        jne   l0400
        ret
l0400:  mov   dx,OFFSET rerr
        mov   cx,rerr_len
        jmp   errend
readfile ENDP

;ARGS : AX enthält das auszugebende Word
;       DI ab dort das Word in 4 Zeichen ausgaben
;       DS auf data Segment
;REGS : erhält alle Registerm, DI wird aktualisiert
;-----------------------------------------------------------------0700
hexax   PROC NEAR
        push  ax                              ;register sichern
        push  bx
        push  cx
        mov   cx,0404H                        ;4 mal 4 bit ausgeben
l0700:  rol   ax,cl                           ;die verlangten 4 bits nach unten
        mov   bx,ax
        and   bx,0FH                          ;low nible durchlassen
        mov   bl,[ziffern+bx]                 ;in ascii-ziffer wandlen
        mov   [di],bl                         ;ausgeben
        inc   di                              ;auf nächstes zeichen
        dec   ch                              ;nächstes nibble
        jg    l0700                           ;bis alle nibble ausgeben
        pop   cx                              ;register zurückholen
        pop   bx
        pop   ax
        ret
hexax   ENDP

; ARGS : den Inhalt von AX in Dezimalform ausgeben
;        DS:DI auf die letzte Ziffer
; REGS : alle register werden erhalten
;-----------------------------------------------------------------0800
dezax   PROC NEAR
        push  ax                              ;register sichern
        push  bx
        push  cx
        push  dx
        push  di
        mov   cx,10                           ;ziffernbasis ist 10
l0800:  xor   dx,dx
        div   cx                              ;durch basis teilen
        mov   bx,dx                           ;dx enthält den divisions-rest
        mov   bl,[ziffern+bx]                 ;ziffer in ascii holen
        mov   [di],bl                         ;ziffer schreiben
        dec   di                              ;auf die höhere ziffer
        cmp   ax,0                            ;solange bis die zahl ausgeben
        jg    l0800
        pop   di                              ;register zurückholen
        pop   dx
        pop   cx
        pop   bx
        pop   ax
        ret
dezax   ENDP

; ARGS: ES,DS auf data
;-----------------------------------------------------------------0500
exeanalyse PROC NEAR
        cld
        mov   cx,hsize/2 - 1                  ;anzahl der darzustellenden words
        mov   si,OFFSET buffer + 2            ;dort stehen diese words
        xor   bx,bx                           ;pointer in der wohin tabelle
l0500:  lodsw
        mov   di,[wohin+bx]
        call  hexax                           ;ax in hex nach ds:di schreiben
        inc   bx
        inc   bx                              ;auf nächsten eintrag in "wohin"
        loop  l0500
        mov   cx,6                            ;anzahl der darzustellenden words
        mov   si,OFFSET buffer + 2            ;dort stehen diese words
        xor   bx,bx                           ;pointer in der wohin tabelle
l0501:  lodsw
        mov   di,[wohind+bx]
        call  dezax                           ;ax in dez nach ds:di schreiben
        inc   bx
        inc   bx                              ;auf nächsten eintrag in "wohin"
        loop  l0501
        mov   cx,sout_len                     ;länge des ausgabe-textes
        mov   dx,OFFSET sout                  ;ds:dx auf den ausgabe-text
        jmp   stdend                          ;den text ausgeben
exeanalyse ENDP

; ARGS: ES,DS auf data
;-----------------------------------------------------------------0600
noexe   PROC NEAR
        mov   ax,WORD PTR [buffer]            ;die file-siagnature
        mov   WORD PTR [sign],ax              ;in den ausgabe-text schreiben
        mov   dx,OFFSET nout                  ;ds:dx auf den ausgabe-text
        mov   cx,nout_len                     ;länge des ausgabetextes
        jmp   stdend                          ;den text ausgeben
noexe   ENDP

;-----------------------------------------------------------------0000
main    PROC NEAR
        mov   ax,es                           ;es hat segement des psh
        mov   bx,ss
        add   bx,ssize/16                     ;ende des benutzten speichers
        sub   bx,ax                           ;größe in paragraphs
        mov   ah,4AH                          ;modify allocated block
        int   21H
        mov   ax,SEG data
        mov   ds,ax
        call  takename                        ;filename aus parameter holen
        call  readfile                        ;den filekopf einlesen
        mov   ax,ds
        mov   es,ax
        cmp   buffer,WORD PTR 'ZM'            ;ist es ein EXE-File ?
        jne   l0001                           ; nein
        jmp   exeanalyse                      ;den kopf ausgeben
l0001:  jmp   noexe                           ;andere meldung ausgaben
main    ENDP

code    ENDS

;=====================================================================
stack   SEGMENT WORD STACK
        DB ssize DUP (?)
stack   ENDS

        END main
