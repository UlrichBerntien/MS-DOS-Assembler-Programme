        PAGE 70,132
        .SALL
;=====================================================================
; MS-Macro-Assembler V1.10
; (c) Ulrich Berntien .12.1990
;     letzte Änderung .12.1990
;
; Listen von mehreren Dateien.
;
; Aufrufformat von MultiPrint:
;        Aufrufformat:  MP [-sw] <ausgabedatei> [-sw] <eingabedateien>
;
;   <ausgabedatei>
;       Name einer DOS Datei, wird erstellt
;   <eingabedateien>
;   Name(n) von Eigabedateien, können Joker enthalten
;   Namen durch Leerzeichen getrennt
;   Switches können dazwischen stehen
;   mögliche Schalter:
;       F/f  : Formfeed ein/aus
;       H/h  : Kopfteil ein/aus
;       N/n  : Zeilennummerierung ein/aus
;       V/v  : Namen auf STDOUT protokollieren ein/aus
;       S/s  : Alphabetische Sortierung ein/aus
;
; Returncodes:
;       00H   - alles ok
;       01H   - Fehler bei den Parametern
;       02H   - DOS Fehler ausgetreten
;=====================================================================
; Reihenfolge der Segment
;     code
;     data
;     stack
;
; Alle Register werden bei den Prozeduren erhalten
; DS,ES immer auf data Segment bei Aufruf einer Procedure
;=====================================================================

; Register Pushen
;---------------------------------------------------------------------
pushing MACRO regs
        IRP reg,<regs>
          push reg
        ENDM
        ENDM

; Register Popen
;---------------------------------------------------------------------
poping MACRO regs
        IRP reg,<regs>
          pop reg
        ENDM
        ENDM

; Betriebssystem Aufruf mit Fehlerbehandlung
;---------------------------------------------------------------------
dos     MACRO
        LOCAL noerror
        clc
        int   21H
        jnc   noerror
        call  dos_error
noerror:
        ENDM

dosmes  MACRO codenum,text
        LOCAL next
        DB codenum
        DW next
        DB text
next EQU $
        ENDM

; Dateibeschreibung
;---------------------------------------------------------------------
datei   STRUC
  dtime  DW ?                                 ;time of create or last rev.
  ddate  DW ?                                 ;date of create or last rev.
  dsize  DD ?                                 ;file size
  dname  DB 13 DUP (?)                        ;filename with punctuation
datei   ENDS

; Struktur bei Dateiverzeichnis durchsuchen
;---------------------------------------------------------------------
sdir    STRUC
         DB 22 DUP (0)                        ;reserviert
 sdatei  DB SIZE datei DUP (0)                ;dateibeschreibung
sdir    ENDS

;=====================================================================
stacksize  EQU 5*1024                         ;stack größe
buffersize EQU 10*1024                        ;buffergröße
dirsize EQU 100                               ;max. anzahl der dateiköpfe
linelen EQU 90                                ;zeilenlänge
eob     EQU 1AH                               ;ende des eingabe buffes
errdev  EQU 02                                ;error message device handle
stdout  EQU 01                                ;standart output device
cr      EQU 0DH                               ;ascii werte
lf      EQU 0AH
ff      EQU 0CH
ht      EQU 09H
strich  EQU '-'
space   EQU 20H
switchchar EQU '-'

f_flag  EQU 000000001B                        ;schaltercodes
h_flag  EQU 000000010B
n_flag  EQU 000000100B
v_flag  EQU 000001000B
s_flag  EQU 000010000B

code    SEGMENT PUBLIC WORD 'code'
code    ENDS

;=====================================================================
data    SEGMENT PUBLIC WORD 'data'

firstdata EQU $

pshseg  DW ?                                  ;segment des psh
cmdadr  DW 0081H                              ;adr des aktuellen byte in cmdline
cmdlen  DW ?                                  ;anzahl der bytes in cmdline

ohandle DW ?                                  ;handle der ausagbedatei
ihandle DW ?                                  ;handle der akt. eingeabedatei

optr    DW ?                                  ;adr aktuelles byte im obuffer
                                              ;diese ist noch frei
iptr    DW ?                                  ;adr aktuelles byte im ibuffer
                                              ;diese ist noch nicht bearbeitet

inptr   DW ?                                  ;auf den namensanfang in iname
iname   DB 80 DUP (?)                         ;eingabe dateiname mit pfad

ddir    sdir <>                               ;fÞr Dateisuche

oname   DB space,'*',space                    ;dateinamen zur ausgabe
fname   DB 13 DUP (?)                         ;aktueller dateiname

line1   DB 10 DUP (space)                     ;zeile mit dateiinformationen
        DB 'DATEI    Date '
fdate   DB '??.??.????   Time '
ftime   DB '??:??:??'
        DB 7 DUP (space)
        DB 'Size '
fsize   DB '????? KByte',cr,lf
        DB 10 DUP (space)                     ;zeile mit druckinformationen
        DB 'PRINT    Date '
odate   DB '??.??.????   Time '
otime   DB '??:??:??',cr,lf,cr,lf,00

lines   DB '???????.  ',00                    ;zielen-numerierung
linesnum EQU lines + 6                        ;auf letzte ziffer

crlf    DB cr,lf,00                           ;zeilen ende string
ffeed   DB ff,00                              ;seiten ende string

err1    DB 'DOS-Error number:'
        DB 5 DUP (space)
errnum  DB '0',cr,lf
err2    DB cr,lf,'Program aborted',cr,lf
err3    EQU THIS BYTE

sws     DB f_flag+h_flag+n_flag+s_flag        ;aktuelle schalter-stellung

switch_table EQU THIS BYTE                    ;tabelle der schalter
        DB 'F',0,f_flag                       ;zeichen/löschende bits/setzende
        DB 'f',f_flag,0
        DB 'H',0,h_flag
        DB 'h',h_flag,0
        DB 'N',0,n_flag
        DB 'n',n_flag,0
        DB 'V',0,v_flag
        DB 'v',v_flag,0
        DB 'S',0,s_flag
        DB 's',s_flag,0
        DB 0                                  ;mit 0 beenden

errtable EQU THIS BYTE                        ;tabelle der dos fehlermeldunge
        dosmes 002H,'file not found'
        dosmes 003H,'path not found'
        dosmes 004H,'too many open files'
        dosmes 005H,'access denied'
        dosmes 006H,'invalid handle'
        dosmes 008H,'not enough memory'
        dosmes 00CH,'invalid access'
        dosmes 00FH,'invalid drive'
        dosmes 012H,'no more files'
        dosmes 0FFH,'write error (disk full?)'
        dosmes 000H,'unknow errorcode'        ;letzter eintrag in der tabelle

myerror DB 'MultiPrint (c) Ulrich Berntien .12.1990',cr,lf
        DB 'Listen von mehreren Dateien.',cr,lf
        DB 'Aufrufformat:  MP [-sw] <ausgabedatei> [-sw] <eingabedateien>',cr,lf
        DB '<ausgabedatei> :',cr,lf
        DB '  Name einer DOS Datei, wird erstellt',cr,lf
        DB '<eingabedateien> :',cr,lf
        DB '  Name(n) von Eigabedateien, können Joker enthalten',cr,lf
        DB '  Namen durch Leerzeichen getrennt',cr,lf
        DB '  Switches können dazwischen stehen',cr,lf
        DB 'mögliche Schalter:',cr,lf
        DB '  F/f  : Formfeed ein/aus',cr,lf
        DB '  H/h  : Kopfteil ein/aus',cr,lf
        DB '  N/n  : Zeilennummerierung ein/aus',cr,lf
        DB '  V/v  : Namen auf STDOUT protokollieren ein/aus',cr,lf
        DB '  S/s  : Alphabetische Sortierung ein/aus',cr,lf
myerrorlen EQU $ - myerror

        EVEN
lastdir DW ?                                  ;zeiger auf letzten dateikopf

dirtab  EQU $                                 ;liste von adr der dateiköpfe

dats     EQU dirtab + dirsize * 2             ;die dateiköpfe
datsende EQU dats + 2 + dirsize * SIZE datei

ibuf    EQU datsende                          ;input buffer

obuf    EQU ibuf + 1 + buffersize             ;output buffer
obufende EQU obuf + buffersize                ;ende des output buffers

lendata EQU  obufende - firstdata             ;bytes im datensegment

data    ENDS

;=====================================================================
code    SEGMENT PUBLIC WORD 'code'

        ASSUME cs : code, ds : data, ss : stack

; Schreibt einen String (mit 0 terminiert,max 512 Zeichen) auf STDOUT
; und danach Zeilenende ausgeben
; ARGS: DX auf den Stringanfang
; RETS: -
;-----------------------------------------------------------------2800
printstr PROC NEAR
        pushing <ax,bx,cx,dx,di>
        cld
        mov   al,0                            ;damit string terminiert
        mov   cx,512                          ;maximale länge
        mov   di,dx
        repne scasb                           ;nach string ende suchen
        neg   cx
        add   cx,512-1                        ;länge des strings
        mov   bx,stdout                       ;auf standart ausgabe
        mov   ah,40H                          ;write a file or device
        dos
        mov   cx,2                            ;zwei zeichen ausgeben
        mov   dx,OFFSET crlf                  ;auf zeilenende
        mov   ah,40H                          ;write a file or device
        dos
        poping <di,dx,cx,bx,ax>
        ret
printstr ENDP

; Ein Doppelword (< 655369) in dezimalform schreiben
; ARGS: (DX,AX) mit dem Doppelword
;       CX minimale Anzahl der auszugebenden Ziffern
;       DS:DI auf letzte Stelle des Speichers für die Zahl
; RETS: -
;-----------------------------------------------------------------0300
dezword PROC NEAR
        pushing <ax,bx,cx,dx,di>              ;register sichern
        mov   bx,10                           ;basis
        xor   dx,dx                           ;dx := 0, (dx,ax):= ax
l0300:  div   bx                              ;durch 10
        add   dl,'0'                          ;in ascii wandeln
        mov   [di],dl                         ;ziffer speichern
        dec   di                              ;auf höhere ziffer
        dec   cx                              ;ziffer zählen
        xor   dx,dx                           ;high word auf null
        or    ax,ax
        jnz   l0300                           ;falls noch stellen da sind
        cmp   cx,0
        jle   l0301                           ;nicht mehr aufzufüllen
        mov   al,'0'                          ;mit nullen
l0302:  mov   [di],al                         ;auffüllen
        dec   di
        loop  l0302                           ;bis mindest länge voll
l0301:  poping <di,dx,cx,bx,ax>               ;register zurück
        ret
dezword ENDP

; Ein Byte in dezimalform schreiben
; ARGS: AL mit dem Byte
;       CX minimale Anzahl der auszugebenden Ziffern
;       DS:DI auf letzte Stelle des Speichers für die Zahl
; RETS: -
;-----------------------------------------------------------------0200
dezbyte PROC NEAR
        pushing <ax,bx,cx,di>                 ;register sichern
        mov   bl,10                           ;basis
l0200:  xor   ah,ah
        div   bl                              ;durch 10
        add   ah,'0'                          ;in ascii wandeln
        mov   [di],ah                         ;ziffer speichern
        dec   di                              ;auf höhere ziffer
        dec   cx                              ;ziffer zählen
        or    al,al
        jnz   l0200                           ;falls noch stellen da sind
        cmp   cx,0
        jle   l0201                           ;nicht mehr aufzufüllen
        mov   al,'0'                          ;mit nullen
l0202:  mov   [di],al                         ;auffüllen
        dec   di
        loop  l0202                           ;bis mindest länge voll
l0201:  poping <di,cx,bx,ax>                  ;register zurück
        ret
dezbyte ENDP

; Wandelt Datum aus Word aus Dateikopf in einen String
; ARGS: SI auf das Word
;       DI auf die Stringmaske '??.??.????'
; RETS: -
;-----------------------------------------------------------------1800
datum   PROC NEAR
        pushing <ax,cx,di>
        mov   BYTE PTR [di],space             ;erste ziffer kann space sein
        inc   di                              ;letzte ziffer des tags
        mov   ax,[si]                         ;word lesen
        and   ax,0000000000011111B            ;tag bits selektieren
        mov   cx,1                            ;minimal eine Stelle
        call  dezbyte                         ;in dezimal ausgeben
        add   di,3                            ;letzte ziffer des monats
        mov   ax,[si]                         ;word lesen
        and   ax,0000000111100000B            ;monat bits selektieren
        mov   cl,5                            ;die bits schieben
        shr   ax,cl
        mov   cx,2                            ;minimal zwie stellen
        call  dezbyte                         ;in dezimal ausgeben
        add   di,5                            ;auf letzte ziffer des jahrs
        mov   ax,[si]                         ;word lesen
        and   ax,1111111000000000B            ;jahr bits selektieren
        mov   cl,9                            ;rechstbündig schieben
        shr   ax,cl
        add   ax,1980                         ;in richtigem jahr wandeln
        mov   cx,4                            ;vier stellen benötigt
        call  dezword                         ;in dezimal ausgeben
        poping <di,cx,ax>
        ret
datum   ENDP

; Wandelt Zeit aus Word aus Dateikopf in einen String
; ARGS: SI auf das Word
;       DI auf die Stringmaske '??:??:??'
; RETS: -
;-----------------------------------------------------------------1900
zeit    PROC NEAR
        pushing <ax,cx,di>
        mov   BYTE PTR [di],space             ;erste ziffer kann space sein
        inc   di                              ;auf letzte ziffer der stunden
        mov   ax,[si]
        and   ax,1111100000000000B            ;stunden selektieren
        mov   cl,11
        shr   ax,cl                           ;rechtsbündig schieben
        mov   cx,1                            ;eine stelle reicht
        call  dezbyte                         ;dezima ausgeben
        add   di,3
        mov   ax,[si]
        and   ax,0000011111100000B            ;minuten selektieren
        mov   cl,5
        shr   ax,cl                           ;rechtsbündig schieben
        mov   cx,2
        call  dezbyte                         ;dezimal ausgeben
        add   di,3                            ;auf letzte ziffer der sekunden
        mov   ax,[si]
        and   ax,0000000000001111B            ;seconden selektieren
        sal   ax,1                            ;mal zwei
        mov   cx,2                            ;zwei stellen benötigt
        call  dezbyte                         ;in dezimal ausgeben
        poping <di,cx,ax>
        ret
zeit    ENDP

; Ausgeben des Systemdatums in druckbarer Form
; ARGS: DI auf die Stringmaske '??.??.????'
; RETS: -
;-----------------------------------------------------------------2000
sdatum  PROC NEAR
        pushing <ax,bx,cx,dx,di>
        mov   BYTE PTR [di],space             ;erste ziffer kann leer bleiben
        mov   ah,2AH                          ;get date
        dos
        mov   bx,cx                           ;das jahr in bx speichern
        mov   al,dl                           ;tag in al
        inc   di                              ;auf letzte ziffer des tags
        mov   cx,1                            ;eine stelle reicht
        call  dezbyte                         ;dezimal ausgeben
        mov   al,dh                           ;monat in al
        add   di,3                            ;auf letzte ziffer des monats
        mov   cx,2                            ;beide stellen ausgeben
        call  dezbyte                         ;dezimal ausgeben
        mov   ax,bx                           ;jahr in ax
        add   di,5                            ;auf letzte ziffer des jahrs
        mov   cx,4                            ;vier stellen benutzen
        call  dezword                         ;dezimal ausgeben
        poping <di,dx,cx,bx,ax>
        ret
sdatum  ENDP

; Ausgeben der Systemzeit in druckbarer Form
; ARGS: DI auf die Stringmaske '??:??:??'
; RETS: -
;-----------------------------------------------------------------2100
szeit   PROC NEAR
        pushing <ax,bx,cx,dx,di>
        mov   ah,2CH                          ;get time
        dos
        mov   bx,cx                           ;stunden,minuten sichern
        mov   BYTE PTR [di],space             ;erste ziffer kann leer bleiben
        mov   al,bh                           ;stunden in al zur ausgabe
        inc   di                              ;auf letzte ziffer der stunde
        mov   cx,1                            ;eine ziffer reicht
        call  dezbyte                         ;dezimal ausgeben
        mov   al,bl                           ;minuten in al zur ausgabe
        add   di,3                            ;auf letzte ziffer der minute
        mov   cx,2                            ;alle zwei ziffern ausgeben
        call  dezbyte                         ;dezimal ausgeben
        mov   al,dh                           ;secunden in al zur ausgabe
        add   di,3                            ;auf letzte ziffer der sekunde
        mov   cx,2                            ;alle zwei ziffern ausgeben
        call  dezbyte                         ;dezimal ausgeben
        poping <di,dx,cx,bx,ax>
        ret
szeit   ENDP

; Fehlerbearbeitung bei DOS Fehlermeldung
; beendet das Programm
; ARGS: AX mit DOS-Fehlercode
; RETS: -
;-----------------------------------------------------------------0100
dos_error PROC NEAR
        push  ax                              ;error code merken
        mov   ax,SEG data
        mov   ds,ax                           ;ds auf data
        pop   ax
        push  ax                              ;error code in ax
        mov   di,OFFSET errnum                ;dorthin die Code nummer
        xor   cx,cx                           ;keine soll-stellen
        call  dezbyte
        mov   dx,OFFSET err1                  ;meldung
        mov   cx,OFFSET err2-OFFSET err1      ;länge
        mov   bx,errdev
        mov   ah,40H                          ;write a file or device
        int   21H
        pop   ax                              ;error code zurück
        mov   si,OFFSET errtable              ;si auf fehlermeldungstabelle
l0102:  mov   bl,[si]                         ;code aus tabelle lesen
        or    bl,bl
        jz    l0101                           ;falls tabelle zu ende ist
        cmp   al,bl
        je    l0101                           ;falls code übereinstimmt
        mov   si,[si+01]                      ;auf nächsten eintrag
        jmp   l0102
l0101:  lea   dx,[si+03]                      ;dx auf anfang der meldung
        mov   cx,[si+01]
        sub   cx,dx                           ;cx länge der meldung
        mov   bx,errdev
        mov   ah,40H                          ;write a file or device
        int   21H
        mov   dx,OFFSET err2                  ;ds:dx auf meldung
        mov   cx,OFFSET err3-OFFSET err2
        mov   bx,errdev
        mov   ah,40H                          ;write a file or device
        int   21H
l0100:  mov   ax,4C02H                        ;programm beenden
        int   21H
        jmp   l0100
dos_error ENDP

; Eigener Fehlertext ausgeben, wenn Parameter falsch sind
; beendet das Programm
; ARGS: -
; RETS: -
;-----------------------------------------------------------------2500
my_error PROC NEAR
        mov   dx,OFFSET myerror               ;ds:dx auf fehlertext
        mov   cx,myerrorlen                   ;länge der meldung
        mov   bx,errdev
        mov   ah,40H                          ;write a file or device
        dos
l2500:  mov   ax,4C01H                        ;programm beenden, code 01
        dos
        jmp   l2500
my_error ENDP

; Auswerten der Schalter
; ARGS: ES:SI auf Schalter
;       CX anzahl der noch max. auszuwertenden Schaltern
; RETS: SI,CX aktualisiert
;       CX Anzahl der restlichen Zeichen, SI hinter den Schalter
; REGS: DS muß auf data zeigen
;-----------------------------------------------------------------3100
switch  PROC NEAR
        pushing <ax,bx>
l3101:  mov   al,es:[si]                      ;zeichen holen
        inc   si                              ;auf nächstes zeichen
        dec   cx                              ;zeichen zählen
        jz    l3100                           ;falls es letztes zeichen war
        cmp   al,space                        ;trennendes zeichen ?
        jle   l3100                           ;  ja
        mov   bx,OFFSET switch_table          ;bx auf tabelle mit den schaltern
        jmp   SHORT l3103
l3102:  add   bx,3                            ;auf nächsten schalter
l3103:  mov   ah,[bx]                         ;schalter zeichen laden
        or    ah,ah                           ;ist die tabelle zu ende ?
        jz    l3101                           ;  ja, das zeichen ignorieren
        cmp   ah,al                           ;vergleich
        jne   l3102                           ;solage wie gefunden
        mov   ax,[bx+1]                       ;die bitmasken laden
        mov   bl,sws                          ;darin die schalter speichern
        not   al                              ;maske für löschen
        and   bl,al                           ;bit(s) löschen
        or    bl,ah                           ;bit(s) setzen
        mov   sws,bl                          ;schalter zurückschreiben
        jmp   l3101                           ;zum nächsten zeichen
l3100:  poping <bx,ax>
        ret
switch  ENDP

; lesen eines Dateinamens aus der Commandline
; in den Namensbuffer iname, setzt den Zeigen inptr
; ARGS: -
; RETS: CARRY falls kein name gelesen wurde
;-----------------------------------------------------------------0400
readiname PROC NEAR
        pushing <ax,bx,cx,si,di,es>
        mov   es,pshseg
        mov   si,cmdadr                       ;es:si auf command line
        mov   cx,cmdlen                       ;restlänge der cmd line
        cmp   cx,0                            ;falls zeile leer ist
        jle   l0400
l0402:  mov   al,es:[si]                      ;zeichen lesen
        inc   si
        dec   cx                              ;zeichen zählen
        jz    l0400                           ;ende der zeile erreicht
        cmp   al,space
        jle   l0402                           ;füllzeichen überlesen
        cmp   al,switchchar                   ;ein schalter ?
        jne   l0407                           ;  nein
        call  switch                          ;schalter auswerten
        jcxz  l0400                           ;falls dabei das ende gefunden
        jmp   l0402                           ;nächstes zeichen auswerten
l0407:  mov   di,OFFSET iname                 ;dorthin speichern
        mov   bx,di                           ;bx hinter den pfad
l0403:  mov   [di],al                         ;zeichen speichern im namen
        inc   di
        cmp   al,':'                          ;das kann pfad beenden
        je    l0405
        cmp   al,'/'
        je    l0405
        cmp   al,'\'
        jne   l0406
l0405:  mov   bx,di
l0406:  mov   al,es:[si]                      ;nächstes zeichen lesen
        inc   si
        dec   cx                              ;zeichen zählen
        js    l0404                           ;kein zeichen mehr da
        cmp   al,space
        jg    l0403                           ;bis ein füllzeichen kommt
l0404:  mov   BYTE PTR [di],00                ;in asciz-string format
        mov   inptr,bx                        ;zeiger auf teil hinter pfad
        clc                                   ;ok, name gelesen
        jmp   SHORT l0401
l0400:  stc                                   ;kein name gelesen
l0401:  mov   cmdlen,cx                       ;veränderte werte speichern
        mov   cmdadr,si
        poping <es,di,si,cx,bx,ax>
        ret
readiname ENDP

; Öffnet die Ausgabedatei, der Dateiname steht in iname
; Speicher den Filehandle in ohandle
; ARGS: -
; RETS: -
;-----------------------------------------------------------------0500
openout PROC NEAR
        pushing <ax,cx,dx>
        mov   dx,OFFSET iname                 ;ds:dx auf name
        xor   cx,cx                           ;no file protection
        mov   ah,3CH                          ;create a file
        dos
        mov   ohandle,ax                      ;save file handle
        mov   ax,OFFSET obuf
        mov   optr,ax                         ;bufferzeiger initialisieren
        poping <dx,cx,ax>
        ret
openout ENDP

; Schreibt die Daten aus dem Ausgabebuffer in die Ausgabedatei
; ARGS: DI auf erstes ungenütztes Byte im Buffer
; RETS: DI auf Bufferanfang
;-----------------------------------------------------------------0600
writeout PROC NEAR
        pushing <ax,bx,cx,dx>
        mov   dx,OFFSET obuf                  ;ds:dx auf den buffer
        mov   cx,di                           ;erstes freies byte
        sub   cx,dx                           ;cx anzahl der bytes im buffer
        jle   l0600                           ;falls buffer leer ist
        mov   bx,ohandle                      ;output file handle
        mov   ah,40H                          ;write a file
        dos
        cmp   cx,ax                           ;alle geschrieben ?
        je    l0600                           ;ja
        mov   ax,0FFH                         ;eigener fehlercode
        call  dos_error                       ;fehler abbruch
l0600:  mov   di,OFFSET obuf                  ;buffer ist wieder leer
        poping <dx,cx,bx,ax>
        ret
writeout ENDP

; Schlie¯t das Ausgabefile, wenn n╠tig schreibt vorher den buffer
; ARGS: -
; RETS: -
;-----------------------------------------------------------------0700
closeout PROC NEAR
        pushing <ax,bx,di>
        mov   di,optr                         ;buffer pointer lesen
        cmp   di,OFFSET obuf                  ;buffer leer ?
        jle   l0700                           ;  ja
        call  writeout                        ;buffer schreiben
l0700:  mov   bx,ohandle                      ;output file handle
        mov   ah,3EH                          ;close a file
        dos
        poping <di,bx,ax>
        ret
closeout ENDP

; Liest aus Eingabefile in den Eingabebuffer
; ARGS: -
; RETS: SI auf den Anfang des Buffers
;-----------------------------------------------------------------0900
readin  PROC NEAR
        pushing <ax,bx,cx,dx>
        mov   bx,ihandle                      ;input file handle
        mov   dx,OFFSET ibuf                  ;ds:dx auf input buffer
        mov   cx,buffersize                   ;größe des buffers
        mov   ah,3FH                          ;read a file
        dos
        mov   bx,ax                           ;anzahl gelesene bytes in bx
        add   bx,OFFSET ibuf                  ;bx auf byte hinter daten
        mov   BYTE PTR [bx],eob               ;sentinel setzen
        mov   si,OFFSET ibuf                  ;zeiger auf buffer anfang
        poping <dx,cx,bx,ax>
        ret
readin  ENDP

; Öffnet Eingabefile, der Dateiname steht in iname
; der Handle wird in ihandle gespeichert
; ARGS: -
; RETS: -
;-----------------------------------------------------------------0800
openin  PROC NEAR
        pushing <ax,dx,si>
        mov   dx,OFFSET iname                 ;ds:dx auf filename
        mov   ax,3D00H                        ;open file for reading
        dos
        mov   ihandle,ax                      ;file handle sichern
        call  readin                          ;buffer füllen
        mov   iptr,si                         ;pointer sichern
        poping <si,dx,ax>
        ret
openin  ENDP

; Schließt Eingabefile
; ARGS: -
; RETS: -
;-----------------------------------------------------------------1000
closein PROC NEAR
        pushing <ax,bx>
        mov   bx,ihandle                      ;input file handle
        mov   ah,3EH                          ;close a file
        dos
        poping <bx,ax>
        ret
closein ENDP

; Schreibt einen ASCIZ-String in die Ausgabe
; ARGS: SI auf den String
; RETS: -
;-----------------------------------------------------------------1100
outstring PROC NEAR
        pushing <ax,si,di>
        mov   di,optr                         ;buffer zeiger laden
        cld
l1102:  cmp   di,OFFSET obufende              ;buffer voll ?
        jle   l1100                           ;  nein
        call  writeout                        ;den buffer wegschreiben
        cld
l1100:  lodsb                                 ;lese aus string
        or    al,al                           ;string ende erreicht ?
        jz    l1101                           ;  ja
        stosb
        jmp   l1102
l1101:  mov   optr,di                         ;buffer pointer speichern
        poping <di,si,ax>
        ret
outstring ENDP

; vielfaches Ausgeben eines Zeichens
; ARGS: AL das Zeichen
;       CX Anzahl wieoft das Zeichen ausgegeben wird
; RETS: -
;-----------------------------------------------------------------1200
outrep  PROC NEAR
        jcxz  l1201                           ;falls nichts auszugeben ist
        pushing <cx,di>
        cld
        mov   di,optr                         ;buffer pointer lesen
l1202:  cmp   di,OFFSET obufende              ;buffer voll ?
        jle   l1200                           ;  nein
        call  writeout                        ;buffer wegschreiben
        cld
l1200:  stosb                                 ;zeichen in buffer schreiben
        loop  l1202                           ;schleife über alle zeichen
        mov   optr,di                         ;pointer sichern
        poping <di,cx>
l1201:  ret
outrep  ENDP

; vielfaches Ausgeben eines Strings
; Abscließen mit Zeilenende
; ARGS: SI auf den String
;       CX Länge der Zeile, String wird wiederholt bis Zeile voll
; RETS: -
;-----------------------------------------------------------------2700
outstrrep PROC NEAR
        jcxz  l2701                           ;falls nichts auszugeben ist
        pushing <ax,bx,cx,si,di>
        mov   bx,si                           ;string anfang merken
        cld
        mov   di,optr                         ;buffer pointer lesen
l2702:  cmp   di,OFFSET obufende              ;buffer voll ?
        jle   l2700                           ;  nein
        call  writeout                        ;buffer wegschreiben
        cld
l2700:  lodsb                                 ;zeichen aus string lesen
        or    al,al                           ;am ende des strings ?
        jnz   l2703                           ;  nein
        mov   si,bx                           ;  ja, wieder vorne anfangen
        jmp   l2700
l2703:  stosb                                 ;zeichen in buffer schreiben
        loop  l2702                           ;schleife über alle zeichen
        mov   optr,di                         ;pointer sichern
        mov   si,OFFSET crlf                  ;zeilenende
        call  outstring                       ;ausgeben
        poping <di,si,cx,bx,ax>
l2701:  ret
outstrrep ENDP

; Kopiert eine Zeile von der Eingabe in die Ausgabe
; Ende der Zeile wird am LF erkannt
; HT wird expandiert
; ARGS: -
; RETS: CARRY, falls es die letzte Zeile war
;-----------------------------------------------------------------1300
cpyline PROC NEAR
        pushing <ax,cx,si,di>
        mov   si,iptr                         ;input buffer pointer lesen
        mov   di,optr                         ;output buffer pointer lesen
        xor   cx,cx                           ;spaltenzähler auf null
l1303:  cmp   di,OFFSET obufende              ;output buffer voll ?
        jle   l1300                           ;  nein
        call  writeout                        ;output buffer schreiben
l1300:  lodsb                                 ;zeichen aus buffer lesen
        cmp   al,eob                          ;ende des inputbuffers ?
        jne   l1301                           ;  nein
        cmp   si,OFFSET ibuf+buffersize       ;inputbuffer war voll ?
        jl    l1302                           ;  nein, ausnahme
        call  readin                          ;input buffer füllen
        mov   al,[si]
        cmp   al,eob                          ;trotzdem am ende ?
        je    l1302                           ;  ja, ausnahme
l1301:  cmp   al,ht                           ;Tabulator expandieren ?
        jne   l1307                           ;  nein
        and   cx,7                            ;modula acht
        xor   cx,7
        inc   cx                              ;cx die anzahl der spaces
        mov   al,space                        ;durch leerzeichen ersetzen
        mov   optr,di                         ;optr muß für outrep aktuell sein
        call  outrep                          ;mehrfach ausgeben
        mov   di,optr                         ;aktuellen optr wieder laden
        xor   cx,cx                           ;spaltenzähler auf null
        jmp   l1303                           ;zum nächsten eingabezeichen
l1307:  stosb                                 ;zeichen kopieren
        inc   cx                              ;spalten zählen
        cmp   al,lf                           ;ende der zeile ?
        jne   l1303                           ;  nein
        mov   optr,di                         ;output buffer pointer speichern
        cmp   BYTE PTR [si],eob               ;ist hinter zeile buffer zu ende?
        jne   l1304                           ;  nein
        cmp   si,OFFSET ibuf+buffersize       ;input buffer voll ?
        jl    l1306                           ;  ja
        call  readin                          ;input buffer auffüllen
        cmp   BYTE PTR [si],eob
        je    l1306
        jmp   l1304
l1302:  mov   optr,si                         ;buffer pointer speichern
        mov   optr,di
        mov   si,OFFSET crlf
        call  outstring                       ;zeile abschließen
        stc                                   ;keine zeile mehr da
        jmp   SHORT l1305                     ;zum ende
l1304:  mov   iptr,si                         ;input buffer pointer speichern
        clc
        jmp   SHORT l1305
l1306:  mov   iptr,si
        stc
l1305:  poping <di,si,cx,ax>
        ret
cpyline ENDP

; Vorbereiten für Erfassen der Dateinamen
; ARGS: -
; RETS: -
;-----------------------------------------------------------------1400
initdir PROC NEAR
        mov   ax,OFFSET dats                  ;anfang der liste der dateiköpfe
        mov   lastdir,ax                      ;ist direkt der letzte
        xor   ax,ax
        mov   WORD PTR [dirtab],ax            ;erster listenzeiger auf
        mov   dx,OFFSET ddir                  ;dorthin daten der dateisuche
        mov   ah,1AH                          ;set disk transfer address
        dos
        ret
initdir ENDP

; Vergleichen zweier Dateinamen
; ARGS: SI,DI auf die beiden Strings
; RETS: Falgs aus dem Vergleich [SI],[DI]
;-----------------------------------------------------------------2900
cmpstr  PROC NEAR
        pushing <cx,si,di>
        mov   cx,SIZE datei.dname             ;länge der strings
        cld
        repe cmpsb                            ;vergleich ausführen
        poping <di,si,cx>
        ret
cmpstr  ENDP

; Einfügen in die Indexliste der Dateiköpfe
; lexikalische Sortierung
; ARGS: BX auf den neuen Namen
;       DX auf den neuen Dateikopf
;-----------------------------------------------------------------3000
sortins PROC NEAR
        pushing <bx,dx,di,si>
        mov   si,bx                           ;zeiger auf den neuen namen
        mov   bx,OFFSET dirtab                ;auf anfang der liste der köpfe
        jmp   SHORT l3002
l3001:  add   bx,2
l3002:  mov   di,[bx]                         ;zeiger auf dateikopf
        or    di,di                           ;liste zu ende ?
        jz    l3000                           ;  ja
        lea   di,[di+datei.dname]             ;di auf name im gespeichert
        call  cmpstr                          ;vergleichen
        jg    l3001                           ;falls neuer > tabelle[bx] weiter
l3000:  xchg  dx,[bx]                         ;speichern und alten zeiger merken
        add   bx,2                            ;zum nächsten eintrag
        or    dx,dx                           ;war es der letzte eintrag ?
        jnz   l3000                           ;  nein
        mov   [bx],dx                         ;mit null liste beenden
        poping <si,di,dx,bx>
        ret
sortins ENDP

; Einfügen in die Indexliste der Dateiköpf
; hängt einfach an die letzte Position an
; ARGS: BX auf den neuen namen
;       DX auf den neuen Dateikopf
; RETS: -
;-----------------------------------------------------------------2300
lastins PROC NEAR
        pushing <ax,cx,di>
        mov   di,OFFSET dirtab                ;auf anfang der liste
        xor   ax,ax                           ;0000 gesucht
        mov   cx,dirsize                      ;max dirsize plätze
        cld
        repne scasw                           ;liste nach ende durchsuchen
        mov   [di-2],dx                       ;speichern
        mov   [di],ax                         ;neues endezeichen speichern
        poping <di,cx,ax>
        ret
lastins ENDP

; In ddir steht ein dateikopf zur Verfügung. In die Liste eintragen
; ARGS: -
; RETS: CARRY, falls Liste voll ist
;-----------------------------------------------------------------2200
dirliste PROC NEAR
        pushing <ax,bx,cx,dx,di,si>
        mov   di,lastdir                      ;di auf platz in der kopf liste
        cmp   di,OFFSET datsende              ;ist liste voll ?
        jge   l2200                           ;  ja
        mov   si,OFFSET ddir.sdatei           ;si auf den neuen dateikopf
        lea   bx,[si+datei.dname]             ;bx auf den namen darin
        mov   dx,di                           ;dx auf den zukünftigen platz
        test  sws,s_flag                      ;soll sortiert werden ?
        jnz   l2202                           ;  ja
        call  lastins                         ;an die indexliste anfügen
        jmp   SHORT l2203
l2202:  call  sortins                         ;lexikalisches einfügen
l2203:  mov   cx,SIZE datei                   ;länge des dateikopfes - 1
        cld
        rep   movsb                           ;speichern
        mov   lastdir,di                      ;neue grenze merken
        clc                                   ;alle ok.
        jmp   SHORT l2201
l2200:  stc                                   ;liste ist voll
l2201:  poping <si,di,dx,cx,bx,ax>
        ret
dirliste ENDP

; Erfassen aller Dateien zu dem gebenen Namen
; Name steht in iname
; ARGS: -
; REGS: -
;-----------------------------------------------------------------1500
readdir PROC NEAR
        pushing <ax,cx,dx>
        mov   dx,OFFSET iname
        xor   cx,cx                           ;keine datei attribute
        mov   ah,4EH                          ;find first
        int   21H
        jc    l1500                           ;keine gefunden
l1501:  call  dirliste                        ;in die liste eintragen
        jc    l1500                           ;falls liste voll ist
        mov   ah,4FH                          ;find next
        int   21H
        jnc   l1501                           ;solange wie suche erfolgreich
l1500:  poping <dx,cx,ax>
        ret
readdir ENDP

; Strich ausgeben
; keine Register Erhaltung
;---------------------------------------------------------------------
prst    PROC NEAR
        mov   al,strich                       ;das zeichen
        mov   cx,linelen                      ;die länge
        call  outrep                          ;ausgeben
        mov   si,OFFSET crlf                  ;zeilenende
        call  outstring                       ;ausgeben
        ret
prst    ENDP

; Initialisierung der Zeilenummern
; ARGS: -
; RETS -
;-----------------------------------------------------------------3200
numstart PROC NEAR
        pushing <ax,cx,di>
        cld
        mov   di,OFFSET lines                 ;auf anfang der zeilennummer
        mov   cx,OFFSET linesnum - OFFSET lines
        mov   al,space
        rep   stosb
        mov   BYTE PTR [di],'1'               ;zeilenummer auf 1 setzen
        poping <di,cx,ax>
        ret
numstart ENDP

; Ausgeben des Kopfes mit den Dateiinformationen und Druckangabe
; ARGS: BX auf einen Dateikopf
; RETS: -
;-----------------------------------------------------------------2400
printhead PROC NEAR
        pushing <ax,cx,dx,si,di>
        mov   si,inptr                        ;si auf anfang dateinamen
        mov   di,OFFSET fname                 ;dorthin den namen kopiern
l2400:  lodsb                                 ;ein byte über al übertragen
        stosb
        or    al,al                           ;am ende des strings ?
        jnz   l2400                           ;nein
        call  prst
        mov   si,OFFSET oname                 ;dateiname in ausgabeform
        mov   cx,linelen                      ;die länge
        call  outstrrep                       ;vielfach ausgeben
        call  prst
        lea   si,[bx+datei.ddate]             ;si auf codiertes datum
        mov   di,OFFSET fdate                 ;dorthin das decodierte datum
        call  datum                           ;datum schreiben
        lea   si,[bx+datei.dtime]             ;si auf codierte zeit
        mov   di,OFFSET ftime                 ;dorthin die decodierte zeit
        call  zeit                            ;zeit schreiben
        mov   di,OFFSET odate                 ;dorthin system datum schreiben
        call  sdatum                          ;datum schreiben
        mov   di,OFFSET otime                 ;dorthin system zeit schreiben
        call  szeit                           ;zeit schreiben
        mov   ax,WORD PTR [bx+datei.dsize]
        mov   dx,WORD PTR [bx+datei.dsize+2]  ;(dx,ax) = file size
        test  ax,1024-1
        jz    l2402
        add   ax,1024                         ;aufrunden
        jnc   l2402                           ;übertrag ?
        inc   dx
l2402:  mov   al,ah
        mov   ah,dl
        mov   dl,dh
        xor   dh,dh                           ;schieben um 8 bit
        mov   cx,2                            ;und schieben um 2 bit
l2401:  sar   dx,1
        rcr   ax,1
        loop  l2401                           ;teilen durch 1024
        mov   cx,5
        mov   di,OFFSET fsize+4
        call  dezword                         ;file size schreiben
        mov   si,OFFSET line1                 ;informationszeile ausgeben
        call  outstring
        poping <di,si,dx,cx,ax>
        ret
printhead ENDP

; Ausgeben der Zeilennummer, weiter zählen
; ARGS: -
; RETS: -
;-----------------------------------------------------------------2600
printnum PROC NEAR
        pushing <ax,si>
        mov   si,OFFSET lines                 ;si auf zeilennummerstring
        call  outstring                       ;zeilenummer ausgeben
        mov   si,OFFSET linesnum              ;zeiger auf letzte ziffer
l2602:  mov   al,[si]                         ;ziffer lesen
        cmp   al,space                        ;ist es ein leerzeichen ?
        jne   l2601                           ;  nein
        mov   al,'0'                          ;  bedeutet null
        jmp   SHORT l2600
l2601:  cmp   al,'9'                          ;ist uebertrag erforderlich
        jl    l2600                           ;  nein
        mov   BYTE PTR [si],'0'               ;  ja
        dec   si                              ;auf eine ziffer höher
        cmp   si,OFFSET lines                 ;gibt es die ziffer ?
        jge   l2602                           ;  ja
        jmp   SHORT l2603                     ;  nein, tu als wäre nichts
l2600:  inc   al                              ;ziffer weiter zählen
        mov   [si],al                         ;ziffer speichern
l2603:  poping <si,ax>
        ret
printnum ENDP

; Ausgabe einer Datei
; ARGS: BX auf den Dateikopf
; RETS: -
;-----------------------------------------------------------------1600
print   PROC NEAR
        pushing <ax,dx,si,di>
        lea   si,[bx+datei.dname]             ;si auf name der datei
        mov   di,inptr                        ;hinter den pfad schreiben
l1601:  lodsb                                 ;aus namen laden
        cmp   al,space                        ;leerzeichen
        jle   l1601                           ;überlesen
        stosb
l1602:  lodsb
        stosb                                 ;hinter pfad schreiben
        or    al,al                           ;falls ende des namens
        jnz   l1602
        test  sws,v_flag
        jz    l1605                           ;protokoll abgeschaltet
        mov   dx,OFFSET iname                 ;dateiname ausgeben
        call  printstr                        ;auf stdout
l1605:  test  sws,h_flag
        jz    l1604                           ;kopfteil abgeschaltet
        call  printhead                       ;kopfteil ausdrucken
l1604:  call  openin                          ;eingabe datei öffnen
        call  numstart                        ;zeilennummerierung vorbereiten
l1600:  test  sws,n_flag
        jz    l1606                           ;zeilennummer abgeschaltet
        call  printnum                        ;zeilennummer schreiben
l1606:  call  cpyline                         ;eine zeile kopieren
        jnc   l1600                           ;solange wie zeilen da sind
        call  closein                         ;eingabe datei schließen
        test  sws,f_flag
        jz    l1603                           ;form feed abgeschaltet
        mov   si,OFFSET ffeed                 ;form feed ausgeben
        call  outstring
l1603:  poping <di,si,dx,ax>
        ret
print   ENDP

; Ausgeben alle Dateien die zu dem Namen in iname gefunden werden
; ARGS: -
; RETS: -
;-----------------------------------------------------------------1700
printing PROC NEAR
        pushing <bx,si>
        call  initdir                         ;initialisierung
        call  readdir                         ;directory auslesen
        mov   si,OFFSET dirtab                ;liste der dateiköpfe
        jmp   SHORT l1700
l1701:  call  print                           ;datei ausgeben
        add   si,2                            ;auf nächsten eintrag
l1700:  mov   bx,[si]                         ;zeiger auf dateikopf
        or    bx,bx                           ;ende der liste ?
        jnz   l1701                           ;  nein
        poping <si,bx>
        ret
printing ENDP

; Hauptprogramm
; ARGS: ES Segment des PSH
; RETS: 00H, falls korrekt bearbeitet
;-----------------------------------------------------------------0000
main    PROC FAR
        mov   ax,SEG data
        mov   ds,ax                           ;ds auf data
        mov   pshseg,es                       ;psh segment merken
        add   ax,(OFFSET lendata + stacksize )/16 +1 ;benötigter speicher
        mov   bx,ax
        mov   es,pshseg                       ;es auf psh segment
        sub   bx,ax                           ;benötigte paragraphs
        mov   ah,4AH                          ;modify allocated memory
        dos
        mov   ax,pshseg
        add   ax,OFFSET lendata /16 + 1       ;ab dort für den stack
        mov   bx,stacksize                    ;stack
        cli                                   ;interrupts unterdrücken
        mov   ss,ax
        mov   sp,bx
        sti                                   ;interrupts erlauben
        xor   cx,cx
        pop   cx                              ;0000:0000 auf den stack
        pop   cx
        mov   al,es:[0080H]                   ;länge der commandline lesen
        xor   ah,ah                           ;ax := al
        mov   cmdlen,ax                       ;länge speichern
        mov   ax,ds
        mov   es,ax                           ;es auch auf data segment
        call  readiname                       ;lese eingabedatei name
        jnc   l0001                           ;falls kein fehler
        call  my_error                        ;wenn name fehlt
l0001:  call  openout                         ;ausgabedatei öffnen
        call  readiname                       ;eingabedateiname lesen
        jnc   l0002                           ;falls kein fehler
        call  my_error
l0002:  call  printing                        ;alles ausgeben
        call  readiname                       ;nächster name versuchen
        jnc   l0002                           ;schleife über alle namen
        call  closeout
l0000:  mov   ax,4C00H                        ;programm beenden, code 00
        dos
        jmp   l0000
main    ENDP

code    ENDS

;=====================================================================
stack   SEGMENT STACK WORD 'stack'
        DB 128 DUP (?)
stack   ENDS

;=====================================================================
        END main
