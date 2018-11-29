        PAGE 70,132
        .SALL
;=====================================================================
; MS-Macro-Assembler V1.10  / Wang PC
; (c) Ulrich Berntien .12.1990
;
; Ausgeben eines WP-Documents
;=====================================================================
;
; Reihenfolge der Segmente muß eingehalten werden:
;       CODE
;       DATA
;       STACK
;
; Rückgabecodes an DOS:
;       00H  -  kein Fehler
;       01H  -  eigener Fehler
;       02H  -  Fehler von DOS gemeldet
;
; Aufrufformat:
;       LSDOC [-sw] <ausgabedatei> [-sw] <einagbedatei> [-sw]
;
;=====================================================================
; last proc number : 27
;=====================================================================
;
; Aufbau eines Documents:
;
; Das Document besteht aus einer Reihe von Blöcken, allem mit einer
; Länge von 1024 Bytes (1 KByte).
; Der erste (Nummer 0) Block eines Documents ist ein Kopf mit Verwaltungs-
; daten "head".
; Die folgenden Blöcke sind Datenblöcke.
;
; Inhalt des Kopfblocks:
;
;        256 Bytes reserviert alle mit 00H gefüllt
; sc     Byte mit Seitencodenummer der für die letzte neue Seite im
;          Document benutzt wird.
;        3 Bytes reserviert mit 00 gefüllt
; footp  Word, Nummer der ersten Blocks der Fußzeilenseite
;            falls Seite leer mit 0000H eingetragen
; headp  Word, Nummer des ersten Blocks der Kopfzeilenseite
;            falls Seite leer mit 0000H eingetragen
; workp  Word, Nummer des ersten Blocks der Arbeitsseite
;            falls Seite leer mit 0000H eingetragen
; first  123 Words: Liste des erten Blockes der jeweiligen Seite
;            falls die Seite leer ist im -1 = 0FFFFH eingetragen
;            maximal 123 Seiten pro Document
;        Byte 00 schließt die Liste ab
; free   510 Bytes der Frei-Block-Liste
;           - ist der entsprechnde Block benutzt, so wird
;             NOT Seitencodenummer in das Byte eingetragen
;           - ist der Block nicht vorhanden, so wird NOT 00H = 0FFH
;             in das Byte eingetragen
;           - ist der Block leer, so wird auch 0FFH eingetragen
; nsc    Byte enthält NOT sc, von der Seitencodenummer der letzten
;             neuen Seite
;
; Inhalt des Datenblocks:
;
; chr    1024 Bytes mit Textdaten
; next   Word mit Nummer des folgenden Blocks, 0FFFFH falls kein Block folgt
;
; Inhalt der Textdaten (kann sich über mehrere Blocks erstrecken):
;
;       Bytes wie sie auch auf dem Bildschirm angezeigt werden.
;           die grafischen Symbole haben die entsprechende Funktion
;       Byte 01FH schließt den Bereich der einfachen Textdaten ab.
;           es folgen Informationen, die auf dem Bildschirm nicht als
;           grafische Symbole dargestellt werden.
;       die Liste der Textattribut muß von den hohen Adressen zu den
;       niedrigen ausgewertet werden.
;       Byte 0FFH schließt die Liste ab (wird als Attribut gelesen)
;       wiederholt : Byte mit Länge-1, Byte mit Attribut
;                    ( ^ = 0 bedeutet also 1 Zeichen mit dem Attribut)
;       Anfang der Liste Bytes 000H,0FFH
;

; Spezielle Zeichen, die in Documents benutzt werden
;---------------------------------------------------------------------
tab     EQU 082H   ;tabulatur im text und in formatzeile
ret     EQU 083H   ;return, zeileende in formatzeile, abschnittende im text
eop     EQU 01FH   ;beendet die 'einfachen' textdaten

; Spezielle Konstanten, die in Documents benutzt werden
;---------------------------------------------------------------------
maxpage EQU 123    ;Seiten maximal in eimen Document
                   ;jede Seite maximal aus 4 Datenblöcke
maxcol  EQU 158    ;Spalte maximal in einer Zeile
maxblk  EQU 510    ;Anzahl der Blöcke in der (frei-)Block Verwaltung
nilblk  EQU 0FFFFH ;letzter block oder kein block
freeblk EQU 0FFH   ;freier block

scor_cd EQU 001H   ;Document-Attribut : Unterstreichen
doub_cd EQU 002H   ;Document-Attribut : Doppelt Unterstreichen
sup_cd  EQU 003H   ;Document-Attribut : Hochstellen
sub_cd  EQU 006H   ;Document-Attribut : Tiefstellen
bold_cd EQU 012H   ;Document-Attribut : Fettdruck

; Struktur des Kopfblockes
;---------------------------------------------------------------------
head    STRUC
        DB 256 DUP (0)
 sc     DB 1
        DB 3 DUP (0)
 footp  DW 0
 headp  DW 0
 workp  DW 0
 first  DW maxpage DUP (nilblk)
        DB 0
 free   DB maxblk DUP (freeblk)
 nsc    DB 0FEH
head    ENDS

; Struktur eines Datenblocks
;---------------------------------------------------------------------
body    STRUC
  chr   DB 1022 DUP (0)
  next  DW nilblk
body    ENDS

; DOS Aufruf, mit Fehler abfangen
;---------------------------------------------------------------------
dos     MACRO
        LOCAL noerror
        clc
        int   21H
        jnc   noerror
        jmp   NEAR PTR doserror
noerror:
        ENDM

; Eigene Fehlerbehandlung aufrufen
;---------------------------------------------------------------------
error   MACRO nummer
        mov   al,nummer
        jmp   NEAR PTR myerror
        ENDM

; Register auf Stack sichern
;---------------------------------------------------------------------
pushing MACRO regs
        IRP reg,<regs>
          push reg
        ENDM
        ENDM

; Register vom Stach zurückholen
;---------------------------------------------------------------------
poping  MACRO regs
        IRP reg,<regs>
          pop reg
        ENDM
        ENDM

; Belegt Speicher mit dptr verwaltet
;---------------------------------------------------------------------
mem     MACRO name,laenge
  name = dptr
  dptr = dptr + laenge
        ENDM

; Eine Fehler-Meldung speichern
;---------------------------------------------------------------------
errmsg  MACRO nummer,text
        LOCAL msg,len
  msg   DB len
        DB nummer
        DB text
  len EQU $ - msg
        ENDM

; Einfache ASCII-Zeichencode
;---------------------------------------------------------------------
lf      EQU 0AH    ;line feed
ff      EQU 0CH    ;form feed
cr      EQU 0DH    ;carige return
space   EQU 20H    ;leerzeichen

;---------------------------------------------------------------------
stacksize  EQU 04*1024                        ;stack größe
buffersize EQU 20*1024                        ;output buffer größe
swchar     EQU '-'                            ;zeichen für switch in cmdline
stderr     EQU 02                             ;error message device

; Status des 'chr moduls'
;---------------------------------------------------------------------
informat_sc EQU 01H                           ;innerhlabt formatzeile eingabe

code    SEGMENT PUBLIC WORD 'code'
code    ENDS

;=====================================================================
data    SEGMENT PUBLIC WORD 'data'

firstdata EQU $                               ;anfang der daten

cmdptr  DW ?                                  ;zeiger in die commandline
cmdseg  DW ?                                  ;segment in der commandline ist
cmdlast DW ?                                  ;letzte adresse in der cmdline

infile  DW ?                                  ;handle des document files

outfile DW ?                                  ;handle des output files
optr    DW ?                                  ;letztes byte im obuffer

stsp    DW ?                                  ;startspalte
spalte  DW ?                                  ;aktuelle spalte
txtptr  DW ?                                  ;adr der aktuelle textzeile

sta_chr DB 0                                  ;status des 'chr moduls'

sws     DB 0                                  ;schalter stellung

swtable DB 00                                 ;tabelle der möglichen schalter

swbittable EQU THIS WORD                      ;tabelle der zugeordneten bits
                                              ;zusetzde, zulöschende bits

crlf    DB cr,lf                              ;zeichen für zeilenende

chr_table EQU THIS BYTE
              ; Tabelle mit Nummer der Procedure (siehe proc_table)
              ; wie das jeweilige Zeichen des Documents verarbeitet
              ; werden soll
   DB 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;00H - 0FH
   DB 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,02 ;10H - 1FH
   DB 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;20H - 2FH
   DB 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;30H - 3FH
   DB 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;40H - 4FH
   DB 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;50H - 5FH
   DB 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;60H - 6FH
   DB 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;70H - 7FH
   DB 00,00,00,01,00,00,03,00,00,00,00,00,00,00,00,00 ;80H - 8FH
   DB 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;90H - 9FH
   DB 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;A0H - AFH
   DB 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;B0H - BFH
   DB 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;C0H - CFH
   DB 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;D0H - DFH
   DB 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;E0H - EFH
   DB 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00 ;F0H - FFH

proc_table EQU THIS WORD
              ; Tabelle mit den Proceduren, die die Zeichen
              ; aus einem Document verarbeiten
        DW simple_chr                         ;00
        DW return_chr                         ;01
        DW eop_chr                            ;02
        DW format_chr                         ;03

doserrmsg EQU THIS BYTE
        DB cr,lf,'DOS-Fehler gefunden:',cr,lf
        DB 'DOS-ERROR '
doserrmsg_len EQU $ - doserrmsg

doserr_table EQU THIS WORD
              ; Tabelle der DOS-Fehler Meldungen
              ; mit Errornummer 00 benendet
   errmsg 002H,'file not found'
   errmsg 003H,'path not found'
   errmsg 004H,'too many open files'
   errmsg 005H,'access denied'
   errmsg 006H,'invalid handle'
   errmsg 007H,'memory block bad'
   errmsg 008H,'not enough memory'
   errmsg 00CH,'invalid access'
   errmsg 00FH,'invalid drive'
   errmsg 000H,'unknwon error code'

myerrmsg EQU THIS BYTE
        DB cr,lf,'Fehler aufgetreten',cr,lf
        DB 'MY-ERROR '
myerrmsg_len EQU $ - myerrmsg

enderrmsg EQU THIS BYTE
        DB cr,lf,'*** Programm beendet ***',cr,lf
enderrmsg_len EQU $ - enderrmsg

myerr_table EQU THIS WORD
              ; Tabelle der Eigenen-Fehler Meldungen
              ; mit Errornummer 00 benendet
   errmsg 001H,'Dateiname fehlt'
   errmsg 002H,'bei Dateischreiben, Disk full ?'
   errmsg 003H,'Unbekannter Schalter'
   errmsg 004H,'bei Document lesen, Datei Ende'
   errmsg 005H,'eine Seite zu lang'
   errmsg 006H,'Seiteende Symbol nicht gefunden'
   errmsg 007H,'Dateiname nicht angegeben'
   errmsg 008H,'Formatzeile zu lang'
   errmsg 009H,'leere Blöcke geladen'
   errmsg 00AH,'Attributliste zu kurz'
   errmsg 000H,'Unbekannter Fehler Code'

dptr EQU $                                    ;anfang der nichtinitialisierten
                                              ;daten, mit dptr verwaltet

mem foline,maxcol                             ;aktuelle formatzeile
mem t1line,maxcol                             ;textzeile 1
mem a1line,maxcol                             ;attribute der textzeile 1
mem t2line,maxcol                             ;textzeile 2
mem a2line,maxcol                             ;attribute der textzeile 2

mem kopf,<SIZE head>                          ;head-block des documents

mem seite,<4 * SIZE body>                     ;max. vier blöcke für eine seite

mem obuffer,buffersize                        ;ausgabe buffer

datasize EQU dptr - firstdata                 ;größe des datenbereichs

data    ENDS

;=====================================================================
code    SEGMENT PUBLIC WORD 'code'

  ASSUME DS : data, ES : data, CS : code,  SS : stack

  ;  i.a. DS und ES auf data Segment

data_seg DW SEG data                          ;Segment von data

;=====================================================================
; Unterprogramm zur Ausgabe von Text
; kein Einfluß aus dem Document
;=====================================================================

; Öffnen der Ausgabedatei
; ARGS: -
; RETS: -
; REGS: nur Segmente erhalten
;-----------------------------------------------------------------0900
openout PROC NEAR
        call  getname                         ;dateinamen holen
        xor   cx,cx                           ;no protection code
        mov   ah,3CH                          ;create a file
        dos
        mov   ds,data_seg                     ;ds wieder auf data segment
        mov   outfile,ax                      ;file handle merken
        mov   optr,OFFSET obuffer             ;auf anfang des buffers
        ret
openout ENDP

; Schreibt OutputBuffer in die Ausagbedatei
; ARGS: DI hinter das letzte Byte im Buffer
; RETS: DI auf erstes freis Byte im Buffer
; REGS: alle anderen erhalten
;-----------------------------------------------------------------1600
writeout PROC NEAR
        pushing <ax,bx,cx>
        mov   cx,di
        mov   dx,OFFSET obuffer               ;ds:dx auf den ausgabe buffer
        sub   cx,dx                           ;anzahl der bytes im buffer
        jbe   l1600                           ;falls buffer leer ist
        mov   bx,outfile                      ;handle das outputfiles
        mov   ah,40H                          ;write a file
        dos
        cmp   ax,cx                           ;alle geschrieben ?
        je    l1600                           ;nein
        error 02                              ;fehlermeldung
l1600:  mov   di,OFFSET obuffer               ;auf anfang des buffers
        poping <cx,bx,ax>
        ret
writeout ENDP

; Schließen der Ausgabedatei, ggf. den Rest des Buffers schreiben
; ARGS: -
; RETS: -
; REGS: nur Segmente erhalten
;-----------------------------------------------------------------1700
closeout PROC NEAR
        mov   di,optr                         ;zeiger in den obuffer holen
        call  writeout
        mov   bx,outfile                      ;file handle von output file
        mov   ah,3EH                          ;close a file
        dos
        ret
closeout ENDP

; Ausgabe eines Strings
; ARGS: SI auf den String
;       CX Länge des Strings
; RETS: -
; REGS: alle erhalten
; Vorsicht ! strout2 ! Einsprung aus lineout
;-----------------------------------------------------------------1400
strout  PROC NEAR
        pushing <cx,si,di>
        jcxz  l1401                           ;falls string leer ist
strout2:cld
        mov   di,optr                         ;im buffer mit di adressieren
l1402:  cmp   di,buffersize+OFFSET obuffer    ;ist buffer voll ?
        jb    l1400                           ;  nein
        call  writeout                        ;  ja, buffer wegschreiben
        cld
l1400:  movsb                                 ;zeichen aus string kopieren
        loop  l1402                           ;bis alle zeichen kopiert
        mov   optr,di                         ;aktueller bufferzeiger speichern
l1401:  poping <di,si,cx>
        ret
strout  ENDP

; Ausgabe eines Strings, danach Zeilenende ausgeben
; ARGS: SI auf den String
;       CX Länge des Strings
; RETS: -
; REGS: alle erhalten
;-----------------------------------------------------------------1500
lineout PROC NEAR
        pushing <cx,si,di>
        call  strout                          ;den string ausgeben
        mov   cx,2
        mov   si,OFFSET crlf                  ;die zeilenende ausgeben
        jmp   strout2
lineout ENDP

;=====================================================================
; Unterprogramm zur Verarbeitung der Daten aus dem Document
; 'chr Modul'
;=====================================================================

; Unterstützt die Umschaltung der Zeilenbuffer
; ARGS: SI Zeiger auf aktuellen Zeilenbuffer
; RETS: BX auf den neuen Zeilenbuffer
; REGS: alle anderen erhalten
;-----------------------------------------------------------------2500
chgline PROC NEAR
        mov   bx,OFFSET t1line
        cmp   si,bx
        jne   l2500
        mov   bx,OFFSET t2line
l2500:  mov   txtptr,bx
        ret
chgline ENDP

; Ausgeben der aktuellen Zeile und danach umschalten der Zeile
; ARGS: DI hinter die letzte benutzte Spalte
;       BX auf den aktuelle Zeilenbuffer
; RETS: BX auf adr des neuen Zeilenbuffers
; REGS: alle anderen erhalten
;-----------------------------------------------------------------2400
linechr PROC NEAR
        pushing <cx,si>
        mov   cx,di                           ;länge der zeile
        mov   si,bx                           ;auf anfang der zeile
        call  lineout                         ;die zeile ausgeben
        call  chgline                         ;zeilenbuffer wechseln
        poping <si,cx>
        ret
linechr ENDP

; Eine Zeile muß abgeschnitten werden
; ARGS: BX auf den aktuellen Zeilenbuffer
;       SI auf die nächste Spalte (hinter das Ende der Zeile)
; RETS: SI auf die nächste Spalte
;       BX auf den (neuen) aktuellen Zeilenbuffer
; REGS: alle anderen erhalten
;-----------------------------------------------------------------2700
cutline PROC NEAR
        pushing <ax,cx,dx,di>
        mov   di,si                           ;mit di die zeile durchsuchen
l2701:  dec   di
        jz    l2702                           ;falls anfang der zeile erreicht
        cmp   BYTE PTR [bx+di],space
        ja    l2701
        jmp   SHORT l2703
l2702:  mov   di,si                           ;muß wort zerschneiden
        dec   di
l2703:  lea   cx,[bx+si]                      ;begrenzung der vorhandene zeile
        lea   dx,[bx+1+di]                    ;bis dahin wird weggeschrieben
        call  linechr                         ;zeile wegschreiben
        mov   si,stsp                         ;auf erste spalte der neuen zeile
        cmp   cx,dx                           ;ist ein zeilenrest zu kopieren ?
        jbe   l2705                           ;  nein
        mov   di,dx                           ;  ja, auf rest der alten zeile
l2704:  mov   al,[di]
        mov   [bx+si],al                      ;zeichen umcopieren
        mov   ah,[di+maxcol]
        mov   [bx+si+maxcol],ah               ;attribut umcopieren
        inc   di
        inc   si                              ;auf nächste zeichen
        cmp   di,cx                           ;ende der alten zeile erreicht ?
        jb    l2704                           ;  nein
l2705:  poping <di,dx,cx,ax>
        ret
cutline ENDP

; Einfaches Zeichen aus Document entgegen nehmen
; ARGS,RETS,REGS wie allchr
;-----------------------------------------------------------------0300
simple_chr PROC NEAR
        pushing <bx,si>
        mov   si,spalte                       ;aktuelle spalte holen
        mov   bx,txtptr                       ;aktueller zeilenbuffer holen
        mov   [bx+si],al                      ;das zeichen in die zeile
        mov   [bx+si+maxcol],ah               ;das attribut auch speichern
        inc   si                              ;auf nächste spalte
        cmp   BYTE PTR [foline-1+si],ret      ;laut format zeile zu ende ?
        jne   l0300                           ;  nein
        call  cutline                         ;  ja, zeile wird abgeschitten
l0300:  mov   spalte,si                       ;spaltennummer abspeichern
        poping <si,bx>
        ret
simple_chr ENDP

; Zeilende-Symbol aus Document bearbeiten
; ARGS,RETS,REGS wie allchr
;-----------------------------------------------------------------0400
return_chr PROC NEAR
        pushing <bx,di>
        mov   bx,txtptr                       ;auf aktuellen zeilebuffer
        mov   di,spalte                       ;aktuelle spalte laden
        call  linechr                         ;aktuelle zeile ausgeben
        xor   di,di
        mov   stsp,di                         ;start spalte auf null
        mov   spalte,di                       ;akt. spalte = startspalte
        poping <di,bx>
        ret
return_chr ENDP

; Format-Symbol aus Document bearbeiten
; ARGS,RETS,REGS wie allchr
;-----------------------------------------------------------------2000
format_chr PROC NEAR
        pushing  <di>
        mov   di,spalte                       ;aktuelle spalte laden
        cmp   di,stsp                         ;ist die aktuelle zeile leer ?
        jbe   l2000                           ;  ja
        call  return_chr                      ;  nein, angefangene zeile beenden
l2000:  mov   spalte,1                        ;in der formatzeile vorne anfangen
        mov   BYTE PTR [foline],al            ;in formatzeile schreiben
        or    sta_chr,informat_sc             ;status entsprechend setzen
        poping <di>
        ret
format_chr ENDP

; Seitenende-Konstante aus Document bearbeiten
; ARGS,RETS,REGS wie allchr
;-----------------------------------------------------------------2100
eop_chr PROC NEAR
        pushing <bx,di>
        mov   di,spalte                       ;aktuelle spalte
        cmp   di,stsp                         ;ist die akt. zeile leer ?
        jbe   l2100                           ;  ja
        mov   bx,txtptr                       ;adr des aktuellen zeilenbuffers
        call  linechr                         ;akt. zeile ausgeben
l2100:  xor   di,di
        mov   spalte,di                       ;spalte auf null
        mov   stsp,di                         ;startspalte auf null
        poping <di,bx>
        ret
eop_chr ENDP

; Zeichen in die Formatzeile schreiben
; ARGS, RETS, REGS wie allchr
;-----------------------------------------------------------------2600
readformat PROC NEAR
        pushing <si>
        mov   si,spalte                       ;position in der zeile laden
        cmp   si,maxcol                       ;ist ende des buffers erreicht ?
        jbe   l2601                           ;  nein
        error 008H                            ;  ja, formatzeile zu lang
l2601:  mov   BYTE PTR [foline+si],al         ;das zeichen speichern
        inc   si                              ;auf nächstes zeichen
        cmp   al,ret                          ;ende der zeile ?
        jne   l2600                           ;  nein
        and   sta_chr, NOT informat_sc        ;  ja, formatzeile fertig
        xor   si,si                           ;neue zeile beginnen
        mov   stsp,si                         ;startspalte auf null
l2600:  mov   spalte,si
        poping <si>
        ret
readformat ENDP

; allg. Zeichen aus Document entgegennehmen
; wird dann entschlüssel und an die speziell UPs übergeben
; ARGS: AL das Zeichen
;       AH das Attribut
; RETS: -
; REGS: alle erhalten
;-----------------------------------------------------------------0500
allchr  PROC NEAR
        pushing <bx>
        test  sta_chr,informat_sc             ;innerhalb einer fomratzeile
        jz    l0500                           ;  nein
        call  readformat                      ;  ja, dann spezielle bearbeitung
        jmp   SHORT l0501
l0500:  mov   bl,al
        xor   bh,bh                           ;bx := al
        mov   bl,[chr_table+bx]               ;nummer der zustädigen proc
        sal   bx,1                            ;words adressieren
        call  [proc_table+bx]                 ;spezielle proc aufrufen
l0501:  poping <bx>
        ret
allchr  ENDP

; Vorbereiten zur Ausgabe einer Seite
; ARGS: -
; RETS: -
; REGS: Alle erhalten
;-----------------------------------------------------------------2300
startchr PROC NEAR
        pushing <ax>
        mov   txtptr,OFFSET t1line            ;mit textzeile1 beginnen
        xor   ax,ax
        mov   spalte,ax                       ;aktuelle spalte auf null
        mov   stsp,ax                         ;startspalte auf null
        mov   sta_chr,al                      ;status auf null
        poping <ax>
        ret
startchr ENDP

;=====================================================================
; Unterprogramme um Document zu laden
; Byteweise ( Zeichen, oder spezielle Code ) werden die Daten dann
; an die Unterprogramm zur Verarbeitung übergeben
; (an allchr, cntrchr )
;=====================================================================

; Einlesen eines Blockes aus der Documentdatei
; ARGS: AX Nummer des Blockes
;       DX Adresse wohin der Block geschrieben werden soll
; RETS: -
; REGS: alle Register erhalten
;-----------------------------------------------------------------1300
loadblock PROC NEAR
        pushing <ax,bx,cx>
        push  dx                              ;adresse merken
        xor   ch,ch
        mov   cl,ah
        mov   dh,al
        xor   dl,dl                           ;(cx,dx) := ax * 2^8
        sal   dx,1
        rcl   cx,1
        sal   dx,1
        rcl   cx,1                            ;(cx,dx) := ax * 8^10
        mov   bx,infile                       ;file handle lesen
        mov   ax,4200H                        ;move read pointer
        dos                                   ;  offset bytes from beginning
        pop   dx                              ;buffer adresse zurückholen
        mov   cx,SIZE body                    ;länge des blocks
        mov   ah,3FH                          ;read a file
        dos
        cmp   cx,ax                           ;alles gelesen ?
        je    l1300                           ;  ja, alles ok
        error 004H                            ;  nein, fehlermelden
l1300:  poping <cx,bx,ax>
        ret
loadblock ENDP

; Lädt Daten einer Seite in den Buffer seite
; ARGS: AX die Nummer des ersten Blocks der Seite
; RETS: DI vor das letzte nichttriviale (d.h. <> 0 ) Byte der Seite
; REGS: alle erhalten
;-----------------------------------------------------------------1900
loadpage PROC NEAR
        pushing <ax,bx,cx,dx>
        mov   dx,OFFSET seite                 ;auf anfang des buffers
l1900:  call  loadblock                       ;einen block laden
        mov   bx,dx
        mov   ax,[bx.next]                    ;nummer des nächtes blocks laden
        cmp   ax,nilblk                       ;war es letzter block ?
        je    l1901                           ;  ja, fertig mit laden
        add   dx,SIZE chr                     ;hinter den letzten datenteil
        cmp   dx,OFFSET seite + 3* SIZE body  ;ist buffer voll ?
        jbe   l1900                           ;  nein, weiter block laden
        error 05H                             ;die seite ist zu lang
l1901:  std
        lea   di,[bx.next-1]                  ;auf letztes datenbyte im buffer
        mov   cx,di
        sub   cx,OFFSET seite                 ;anzahl der bytes im buffer
        xor   al,al                           ;nullbytes ausmustern
        repe  scasb                           ;durchsuchen
        jne   l1902                           ;ein byte <> 0 gefunden
        error 009H                            ;buffer ist leer, fehler
l1902:  poping <dx,cx,bx,ax>
        ret
loadpage ENDP

; Ausgeben einer Seite aus dem Document
; ARGS: AX die Nummer des ersten Blocks der Seite
; RETS: -
; REGS: alle erhalten
;-----------------------------------------------------------------1200
writepage PROC NEAR
        pushing <ax,cx,si,di>
        call  loadpage                        ;die seite einladen
        call  startchr                        ;die ausgabe vorbereiten
        xor   si,si                           ;damit zeichen indizieren
        mov   cx,1
l1200:  mov   al,[seite+si]                   ;zeichen lesen
        inc   si
        loop  l1202                           ;falls attribut noch gültig ?
        dec   di                              ;auf nächste attribut
        mov   ah,[di]                         ;attribut laden
        dec   di                              ;auf die nächste länge
        mov   cl,[di]                         ;längen-byte laden laden
        inc   cx                              ;wahre anzahl der zeichen
        cmp   ah,0FFH                         ;ende der attr.liste ?
        jne   l1202                           ;  nein
        error 00AH                            ;  ja, ein Fehler
l1202:  cmp   si,4*SIZE body                  ;bufferende überschritten ?
        jbe   l1201                           ;  nein
        error 06H                             ;  ja, eop fehlt
l1201:  call  allchr                          ;das zeichen ausgeben
        cmp   al,eop                          ;ist ende des textes erreicht ?
        jne   l1200                           ;  nein, weiter ausgeben
        poping <di,si,cx,ax>
        ret
writepage ENDP

; Ausgeben aller Seiten eines Documents
; ARGS: -
; RETS: -
; REGS: nur Segmente erhalten
;-----------------------------------------------------------------1100
writedoc  PROC NEAR
        mov   si,OFFSET kopf.footp            ;die speziellen seiten duchlaufen
l1104:  mov   ax,[si]                         ;nummer des erten blocks
        or    ax,ax                           ;ist die seite leer ?
        jz    l1103                           ;  ja
        call  writepage                       ;  nein, seite ausgeben
l1103:  inc   si                              ;auf nächste blocknummer
        inc   si
        cmp   si,OFFSET kopf.workp            ;alle drei durchlaufen ?
        jbe   l1104                           ;  nein, weiter
        xor   si,si                           ;damit in der liste indizieren
        jmp   SHORT l1101
l1100:  call  writepage                       ;eine seite ausgeben
        inc   si                              ;auf nächste blocknummer
        inc   si
        cmp   si,SIZE head.first
        jae   l1102                           ;liste der seiten zu ende
l1101:  mov   ax,[kopf.first+si]              ;nummer des ersten blocks laden
        cmp   ax,nilblk                       ;ende der liste ?
        jne   l1100                           ;nein
l1102:  ret
writedoc ENDP

; ╝ffnen eines Documents, den Kopfblock lesen
; ARGS: -
; RETS: -
; REGS: nur Segmente erhalten
;-----------------------------------------------------------------1000
opendoc PROC NEAR
        call  getname                         ;get filename
        mov   ax,3D00H                        ;open file for reading
        dos
        mov   ds,data_seg                     ;ds wieder auf data segment
        mov   infile,ax                       ;file handle abspeichern
        xor   ax,ax                           ;ax := 0
        mov   dx,OFFSET kopf                  ;in den doc.kopf speicher
        jmp   loadblock
        ;ret
opendoc ENDP

;=====================================================================
; allg. Unterprogramm
;=====================================================================

; allg. Fehlerbehandlung
; ARGS: AL mit Fehlercode
;       DX mit ADR von erstem Teil der Fehlermeldung
;       CX mit der Länge davon
;       SI auf Tabelle mit den Fehlermeldungen
; RETS: -
; REGS: DS wird aufs data Segment gelegt
;-----------------------------------------------------------------1800
doerror PROC NEAR
        push  ax                              ;fehlercode sichern
        mov   ds,data_seg
        mov   bx,stderr                       ;ausgabe auf error message device
        mov   ah,40H                          ;write a file or device
        int   21H
        pop   ax
l1801:  mov   dx,[si]                         ;code und laenge aus tabelle lesen
        cmp   al,dh                           ;stimmt der code überein
        je    l1800                           ;  ja, dann ausgeben
        or    dh,dh                           ;letzter tabelleneintrag ?
        jz    l1800                           ;  ja, dann ausgeben
        xor   dh,dh                           ;dx := dl = länge des eintrags
        add   si,dx                           ;auf nächsten eintrag in tabelle
        jmp   l1801                           ;schleife über alle einträge
l1800:  mov   cx,dx
        xor   ch,ch                           ;cx := dl
        sub   cl,2                            ;cx := länge des textes
        lea   dx,[si+02]                      ;dx auf den meldungs text
        mov   ah,40H                          ;write a file or device
        int   21H
        mov   dx,OFFSET enderrmsg
        mov   cx,enderrmsg_len
        mov   ah,40H                          ;write a file or device
        int   21H
        ret
doerror ENDP

; Fehlerbehandlung bei eigenen Fehler
; Programm wird beendet
; ARGS: AL mit dem MY-Fehlercode
;-----------------------------------------------------------------0200
myerror PROC NEAR
        mov   si,OFFSET myerr_table
        mov   cx,myerrmsg_len
        mov   dx,OFFSET myerrmsg
        call  doerror                         ;fehlermeldung ausgeben
l0200:  mov   ax,4C01H                        ;terminate process
        dos                                   ;return code 1
        jmp   l0200
myerror ENDP

; Fehlerbehandlung bei einem DOS - Fehler
; Programm wird beendet
; ARGS: AL mit den DOS-Fehlercode
;-----------------------------------------------------------------0100
doserror PROC NEAR
        mov   si,OFFSET doserr_table
        mov   cx,doserrmsg_len
        mov   dx,OFFSET doserrmsg
        call  doerror                         ;fehlermeldung ausgeben
l0100:  mov   ax,4C02H                        ;terminate process
        int   21H                             ;return code 2
        jmp   l0100
doserror ENDP

; Zeiger auf Name aus Commandline holen
; ggf. Switches bearbeiten
; ARGS: -
; RETS: DS:DX auf den Namen in der Commandline
; REGS: alle anderen erhalten
;-----------------------------------------------------------------0800
getname PROC NEAR
        pushing <ax,si,es>
        les   si,DWORD PTR cmdptr             ;es:si in die cmdline
        mov   dx,cmdlast                      ;ende der cmdline laden
        cmp   BYTE PTR es:[si],space          ;zeiger hinter einem namen
        jbe   l0800                           ;  ja
l0801:  inc   si                              ;  nein, name überlesen
        cmp   si,dx                           ;ende der zeile erreicht ?
        jb    l0802                           ;  nein
        error 007H                            ;  ja, dann fehlermedlung
l0802:  cmp   BYTE PTR es:[si],space
        ja    l0801                           ;bis der name überlesen
l0800:  inc   si
        cmp   si,dx                           ;ende der zeile erreicht ?
        jb    l0803                           ;  nein
        error 007H                            ;  ja, dann fehlermeldung
l0803:  cmp   BYTE PTR es:[si],space
        jbe   l0800                           ;bis anfang des nächsten gefunden
        mov   cmdptr,si                       ;neue position merken
        mov   dx,si                           ;ds:dx auf den filenamen
        mov   ax,es
        mov   ds,ax
        poping <es,si,ax>
        ret
getname ENDP

; Schalter auswerten und aus CMDline löschen
; ARGS: ES:SI auf den Schalter
;       CX Anzahl der restlichen Zeichen in der CMDline
; RETS: ES:SI hinter den Schalter
;       CX Anzahl der restlichen Zeichen in der CMDline
; REGS: nur Segmente erhalten
;-----------------------------------------------------------------2200
switch  PROC NEAR
l2202:  mov   al,es:[si]                      ;zeichen des schalters laden
        mov   es:[si],ch                      ;und löschen
        inc   si
        dec   cx                              ;die zeichen zählen
        cmp   al,space                        ;ende des Schalters ?
        jbe   l2200                           ;  ja
        cmp   al,swchar                       ;schalter symbol ?
        je    l2201                           ;  ja, dann nicht decodieren
        xor   bx,bx                           ;zur indizierung
l2204:  mov   ah,[swtable+bx]                 ;aus schaltertabelle lesen
        cmp   ah,al                           ;ist es der gesuchte schalter
        je    l2203                           ;  nein
        inc   bx                              ;auf nächsten eintrag
        or    ah,ah                           ;war es der letzte eintrag ?
        jnz   l2204                           ;  nein
        error  003H                           ;unbekannter schalter
l2203:  sal   bx,1                            ;word indizeiren
        mov   ax,[swbittable+bx]              ;die bitoperationen lesen
        or    al,sws                          ;diese bits werden gestzt
        not   ah
        and   al,ah                           ;diese bits werden gelöscht
        mov   sws,al                          ;veränderte schalterstellung
l2201:  or    cx,cx                           ;noch zeichen in der zeile
        jnz   l2202                           ;  ja, weiter mit auswertung
l2200:  ret
switch  ENDP

; Commandline vorbereiten
; ARGS: ES auf PSH
; RETS: -
; REGS: nur Segmente erhalten
;-----------------------------------------------------------------0700
cmdline PROC NEAR
        mov   cmdseg,es
        mov   cmdptr,0081H                    ;auf anfang der cmdline
        mov   si,0080H
        mov   cl,es:[si]                      ;länge des cmdline laden
        xor   ch,ch                           ;cx := cl
        mov   ax,si
        add   ax,cx                           ;adr des zeilen endes
        mov   cmdlast,ax                      ;speichern
        jcxz  l0703                           ;falls cmdline leer ist
        inc   cx
l0702:  inc   si                              ;auf näcshtes zeichen
        mov   al,es:[si]                      ;zeichen lesen
        cmp   al,space
        jbe   l0700                           ;es ist ein füllzeichen
        cmp   al,swchar                       ;ist es das schalter symbol ?
        jne   l0701                           ;  nein
        call  switch                          ;schalter auswerten
        or    cx,cx
        jnz   l0702                           ;zeile ist noch nicht zu ende
        jmp   SHORT l0703                     ;zeile ist zu ende
l0700:  mov   es:[si],ch                      ;füllzeichen löschen
l0701:  loop  l0702                           ;schleife über alle zeichen
l0703:  ret
cmdline ENDP

; Speicherbelegung vornehmen
; ARGS: ES auf PSH
; RETS: -
; REGS: nur Segment erthalten
; der Stack wird gelöscht !
;-----------------------------------------------------------------0600
setmem  PROC NEAR
        pop   dx                              ;rücksprungadresse sichern
        mov   bx,ds
        add   bx,(stacksize+datasize)/16+1    ;obere speichergrenze
        mov   ax,es
        sub   bx,ax                           ;benötigte paragraphs
        mov   ah,4AH                          ;modify allocated block
;;;;;;  dos
        mov   ax,ds
        add   ax,datasize/16+1                ;stack segment über data segment
        mov   bx,stacksize                    ;stack leer
        cli
        mov   ss,ax                           ;stack neu einrichten
        mov   sp,bx
        sti
        jmp   dx                              ;rücksprung simulieren
setmem  ENDP

; Hauptprogramm
; ARGS: ES auf PSH Segment
;-----------------------------------------------------------------0000
main    PROC NEAR
        mov   ds,data_seg                     ;ds auf data segment
        call  setmem                          ;speicher einrichten
        call  cmdline                         ;command line aufbereiten
        mov   es,data_seg                     ;es auf data segment
        call  openout                         ;output file öffnen
        call  opendoc                         ;document file öffnen
        call  writedoc                        ;document ausgeben
        call  closeout
l0000:  mov   ax,4C00H                        ;terminate process
        dos                                   ;return code 0
        jmp   l0000
main    ENDP

code    ENDS

;=====================================================================
stack   SEGMENT WORD STACK 'stack'
        DB 256 DUP (?)
stack   ENDS

;=====================================================================
        END main
