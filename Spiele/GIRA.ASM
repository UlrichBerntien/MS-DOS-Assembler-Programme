        .SALL
        PAGE 70,132
;=====================================================================
; MS-Macro-Assembler V1.10
; (c) Ulrich Berntien .04.1991
;     letzte Änderung .04.1991
;=====================================================================
;
; Lösen eines Kreuzwort-Gitter-Rätsels
;
; Das Rätsel wird aus der Standarteingabe gelesen
; Die Lösung wird in die Standartausgabe geschrieben
; Fehlermeldungen auf das Standartfehlergerät
;
; Aufbau des Rätsels:
;   wiederholt <Wort für das Rätsel> <cr,lf>
;   <cr,lf>
;   wiederholt <Zeile des Gitters> <cr,lf>
;   <Ende der Datei>
;
; in der Zeile des Rätsels werden leere Positionen durch # dargestellt
;
;=====================================================================
; ES und DS enthalten (fast) immer SEG data

filesize  EQU 20*1024                         ;speichergrössen
stacksize EQU 10*1024

tab   EQU 09H                                 ;ascii konstanten
cr    EQU 0DH
lf    EQU 0AH
eof   EQU 1FH
space EQU 20H
spchr EQU '#'

stdin  EQU 00H                                ;dos standart dateien
stdout EQU 01H
stderr EQU 02H

rechts  EQU 01                                ;richtungscodes
unten   EQU 02

; Aufbau der Liste der Wortköpfe
;---------------------------------------------------------------------
;  wiederholt solange Wörter mit gleicher Länge vorhanden

wort STRUC
 wadr    DW (?)      ; adr des strings
 len     DW (?)      ; länge des worts in der Einlesephase
                     ; In der Suchphase 0 => Wort noch verfügbar
wort ENDS

; ein solcher Block wird abgeschlossen mit
;        DW 0000H
; es folgt dann ein Block mit kürzeren Wörtern
; am Ende der Liste folgt ein weiteres Wort
;        DW 0000H

; Aufbau der Liste der Feldköpfe
;---------------------------------------------------------------------
; wiederholt solange Felder da sind

feld STRUC
 gadr    DW (?)      ; releative adr des Feldes im Gitter
 sadr    DW (?)      ; adr des erste Wortkopfs mit der passenden Länge
 leer    DW (?)      ; = 0, d.h. Feld ist leer
 rcd     DB (?)      ; Richtungscode
         DB (?)      ; auf Wordgrenze auffüllen
feld ENDS

; Am Ende der Liste ein
;        DW 0000

; Register pop'en
;---------------------------------------------------------------------
poping MACRO regs
        IRP reg,<regs>
          pop reg
        ENDM
        ENDM

; Register push'en
;---------------------------------------------------------------------
pushing MACRO regs
        IRP reg,<regs>
          push reg
        ENDM
        ENDM

; DOS Function Request mit Fehlerbehandlung
;---------------------------------------------------------------------
doscall MACRO
        LOCAL noerror
        clc
        int 21H
        jnc   noerror
        jmp   doserror
noerror:
        ENDM

;=====================================================================
code    SEGMENT WORD PUBLIC 'code'
  segdata DW SEG data
code    ENDS

;=====================================================================
data    SEGMENT WORD PUBLIC 'data'

fileptr  DW 0FFFFH - filesize                 ;nächstes byte im filebuffer

woerter  DW ?                                 ;adr der liste der wortköpfe
gitter   DW ?                                 ;adr des orginal gitters
felder   DW ?                                 ;adr der liste der feldköpfe

zeilen   DW ?                                 ;größe des gitters
spalten  DW ?
schritt  DW ?                                 ;zum durchgehen = spalten + 1
nschritt DW ?                                 ;zum wechsel auf nächste spalte
laenge   DW ?                                 ;größe des gittes in words

free     DW lastdata                          ;adr des ersten freien bytes

doserr  DB cr,lf,'Fehler von DOS gemeldet',cr,lf
doserrlen EQU $ - doserr

myerr   DB cr,lf,'Selbst Fehler gefunden',cr,lf
myerrlen EQU $ - myerr

crlf    DB cr,lf

lastdata EQU THIS BYTE                        ;ende der statischen daten

data    ENDS

;=====================================================================
code    SEGMENT WORD PUBLIC 'code'

ASSUME ds : data, es : data, cs : code, ss : stack

; DOS Fehlermeldung ausgeben und Programm abbrechen
; ARGS: AL mit DOS Fehlercode
; RETS: -
; REGS: -
;-----------------------------------------------------------------0100
doserror PROC NEAR
        mov   ds,segdata
        lea   dx,doserr                       ;ds:dx auf fehlertext
        mov   cx,doserrlen                    ;länge der ausgabe
        jmp   enderror                        ;fehlerausgaben
doserror ENDP

; Eigene Fehlermeldung ausgeben und Programm abbrechen
; ARGS: AL mit eigenem Fehlercode
; RETS: -
; REGS: -
;-----------------------------------------------------------------0400
myerror PROC NEAR
        mov   ds,segdata
        lea   dx,myerr                        ;ds:dx auf fehlertext
        mov   cx,myerrlen                     ;länge der ausgabe
        jmp   enderror
myerror ENDP

; Fehlermeldung ausgeben und Programm abbrechen
; ARGS: DS:DX auf eine Fehlermeldung
;       CX mit länge der Fehlermeldung
; RETS: Returncode 01H geben
; REGS: -
;-----------------------------------------------------------------0500
enderror PROC NEAR
        mov   bx,stderr                       ;fehlerausgabekanal
        mov   ah,40H                          ;write a file or device
        int   21H
l0500:  mov   ax,4C01H                        ;exit from process
        int   21H
        jmp   l0500
enderror ENDP

; lieste eine Zeile aus der Eingabe
; Berücksichtigts TAB's ,Zeile als String mit 00H abgeschlossen
; Dateiende wird durch EOF erkannt
; ARGS: DS,ES auf data Segment
;       DI auf Speicher für den String
; RETS: CX mit der Länge der Zeile
;       DI hinter den String
; REGS: alle anderen erhalten
;-----------------------------------------------------------------0600
readln PROC NEAR
        pushing <ax,si>
        cld
        xor   cx,cx                           ;zähler auf null
        mov   ah,space                        ;öfters benutzte konstante
        mov   si,fileptr                      ;mit si adressieren
l0603:  lodsb                                 ;zeichen im buffer abfragen
        cmp   al,eof                          ;datei zu ende ?
        je    l0600                           ;  ja, nichts tun
        cmp   al,cr                           ;ende der zeile ?
        je    l0601                           ;  ja
        cmp   al,tab                          ;ein tabulator ?
        jne   l0602                           ;  nein

        mov   al,ah                           ;  ja, expandieren
l0604:  stosb
        inc   cx                              ;zeichen zählen
        test  cl,07H                          ;tabs alle 8 zeichen
        jnz   l0604
        jmp   l0603                           ;nächstes zeichen

l0602:  cmp   al,ah                           ;andere control codes überlesen
        jb    l0603
        stosb                                 ;normales zeichen speichern
        inc   cx                              ;zeichen zählen
        jmp   l0603                           ;schleife über eine zeile

l0601:  xor   al,al                           ;string mit 00H abschließen
        stosb
        mov   fileptr,si                      ;aktueller stand merken
l0600:  poping <si,ax>
        ret
readln ENDP

; Liest eine Reihe von Wörter/Zeilen ein
; Die Liste der Wortköpfe wächst nach unten
; ARGS: DS,ES auf data Segment
;       BX auf Liste der Wortköpfe, nicht sortiert
;       DI auf Speicher für die Wörter
; RETS: DI hinter den benutzten Speicher
;       CX Anzahl der gelesenen Wörter/Zeilen
;       DX Länge des längsten Wortes
; REGS: alle andere erhalten
;-----------------------------------------------------------------0700
loadworts PROC NEAR
        pushing <ax,bx>
        xor   dx,dx                           ;dx für größte länge
        xor   ax,ax                           ;ax für zählen der wörter
l0701:  inc   ax                              ;im voraus zählen
        mov   [bx.wadr],di                    ;adr des wortes
        call  readln
        jcxz  l0702                           ;leeres wort beendet die reihe
        mov   [bx.len],cx                     ;länge des wortes
        cmp   dx,cx
        ja    l0700
        mov   dx,cx                           ;neue größte länge
l0700:  sub   bx,SIZE wort                    ;auf nächsten kopfeintrag
        jmp   l0701

l0702:  dec   ax                              ;eins zuviel gezählt
        mov   cx,ax                           ;in cx anzahl zurückgeben
        mov   WORD PTR [bx],0                 ;liste der köpfe abschließen
        poping <bx,ax>
        ret
loadworts ENDP

; Erzeugt Wortkopf-Liste aller Wörter der Länge DX
; DX ist die größte Länge in der unsortieren Liste
; ARGS: DS,ES auf data Segment
;       BX auf Liste der Wortköpfe, nicht sortiert, abfallend
;       DI auf Speicher für die neu Wortkopf-Liste
;       DX die vorgebene Länge
; RETS: DI hinter den benutzten Speicher
;       DX Länge des längsten Wortes das verblieben ist
; REGS: alle andere erhalten
;-----------------------------------------------------------------1000
takeworts PROC NEAR
        pushing <ax,bx,cx>
        xor   cx,cx                           ;in cx max. länge suchen
        jmp   SHORT l1002                     ;in schleife springen

l1000:  mov   ax,[bx.wadr]                    ;kopf kopieren
        mov   [di.len],dx
        mov   [di.wadr],ax
        add   di,SIZE wort                    ;auf nächsten kopf
l1003:  sub   bx,SIZE wort

l1002:  mov   ax,[bx.len]
        cmp   ax,dx
        je    l1000                           ;den kopf übernehmen
        ja    l1003                           ;nächster kopf
        cmp   [bx.wadr],0                     ;liste zu ende ?
        jz    l1001                           ;  ja
        cmp   cx,ax
        jae   l1003
        mov   cx,ax                           ;neue maximale länge
        jmp   l1003                           ;weiter suchen

l1001:  mov   WORD PTR [di],0                 ;liste mit word 0 abschließen
        add   di,2
        mov   dx,cx                           ;neue max. länge
        poping <cx,bx,ax>
        ret
takeworts ENDP

; Ausgabe des Gitters auf Standart-Ausgabegerät
; ARGS: ES,DS auf data Segment
;       BP auf das Gitter
; RETS: -
; REGS: alle erhalten
;-----------------------------------------------------------------2100
ausgabe PROC NEAR
        pushing <ax,bx,cx,dx,si,di>
        mov   di,zeilen                       ;zeilen zählen
        mov   si,bp                           ;mit si das gitter durchgehen
        lea   dx,crlf                         ;zuerst eine leerzeile
        mov   bx,stdout                       ;auf standart ausgabe
        mov   cx,2
        mov   ah,40H                          ;write a file
        doscall

l2100:  mov   dx,si                           ;zeile ausgeben
        mov   cx,spalten                      ;länge der zeile
        mov   ah,40H                          ;write a file
        doscall
        lea   dx,crlf                         ;zeile abschliessen
        mov   cx,2
        mov   ah,40H                          ;write a file
        doscall
        add   si,schritt                      ;auf nächste zeile
        dec   di                              ;zeilen zählen
        jnz   l2100
        poping <di,si,dx,cx,bx,ax>
        ret
ausgabe ENDP

; Sucht in der Liste der Wörter nach erstem Wort der Länge CX
; ARGS: DS,ES auf data Segment
;       CX Länge des Worts
; RETS: BX auf den zugehörigen Kopf
; REGS: alle anderen erhalten
;-----------------------------------------------------------------1200
suchewort PROC NEAR
        pushing <ax>
        mov   bx,woerter                      ;auf anfang der liste
        jmp   SHORT l1200                     ;in die suchschleife springen

l1201:  add   bx,SIZE wort                    ;auf nächsten wortkopf
        cmp   [bx.wadr],0                     ;ist es ende des blockes ?
        jne   l1201                           ;  nein
        add   bx,2                            ;  ja, bx auf nächsten block
l1200:  mov   ax,[bx.len]
        or    ax,ax                           ;ist die liste zu ende ?
        jz    l1202                           ;  ja, dann nicht gefunden
        cmp   ax,cx                           ;stimmt die länge ?
        jne   l1201                           ;  nein, weiter suchen
        poping <ax>                           ;  ja, dann zurück
        ret

l1202:  mov   al,2                            ;fehlermeldung
        jmp   myerror
suchewort ENDP

; Bewegt sich im Gitter ein Feld nach oben oder unten
; ja nach Ýwohin¦, Ýwomit¦ ist der Zeiger der bewegt wird
;---------------------------------------------------------------------
go      MACRO wohin,womit
        LOCAL lunten, weiter
        cmp   wohin,rechts
        jne   lunten
        inc   womit
        jmp   SHORT weiter
lunten: add   womit,schritt
weiter:
        ENDM

; Fügt an die Liste der Felder alle entsprechend AH orientierte
; Felder an
; ARGS: DS,ES auf data Segment
;       AH mit der Richtung
;       DI auf freien Speicher für die Liste
; RETS: DI auf Rest des freien Speichers
; REGS: alle anderen erhalten
;-----------------------------------------------------------------1300
buildfelder PROC NEAR
        pushing <ax,bx,cx,dx,si>
        mov   si,gitter                       ;mit si das gitter druchlaufen
        jmp   SHORT l1302

l1303:  go    ah,si

l1302:  mov   al,[si]                         ;aus gitter lesen
l1306:  cmp   al,space
        ja    l1300                           ;anfang von etwas gefunden

l1301:  or    al,al                           ;zeile/spalte zu ende ?
        jnz   l1303                           ;  nein, nächstes Feld bearbeiten

        cmp   ah,rechts
        jne   l1304
        inc   si                              ;in nächste zeile
        jmp   SHORT l1305
l1304:  sub   si,nschritt                     ;in nächste spalte

l1305:  mov   al,[si]
        or    al,al                           ;ganz zu ende ?
        jnz   l1306                           ;  nein
        poping <si,dx,cx,bx,ax>               ;  ja, fertig
        ret

l1300:  xor   cx,cx                           ;länge des felds zählen
        xor   bx,bx                           ;anzahl der # zählen
        mov   dx,si                           ;anfang merken

l1307:  cmp   al,spchr
        jne   l1308
        inc   bx                              ;ein # gefunden
l1308:  inc   cx                              ;eine position zählen

        go    ah,si

        mov   al,[si]                         ;aus gitter lesen
        cmp   al,space
        ja    l1307                           ;noch im feld

        cmp   cx,1                            ;ist es ein richtiges feld ?
        jbe   l1301                           ;  nein, feld nicht aufnehmen
        cmp   bx,1                            ;enthält es #
        jb    l1301                           ;  nein, feld nicht aufnehmen

        call  suchewort                       ;zeiger auf wörter holen
        sub   dx,gitter                       ;relative adresse bilden
        mov   [di.gadr],dx                    ;adr des feldes speichern
        mov   [di.sadr],bx                    ;adr für suche
        mov   [di.leer],0                     ;feld leer
        mov   [di.rcd],ah                     ;orientierung speichern
        add   di,SIZE feld                    ;auf nächsten feldkopf
        jmp   l1301                           ;weiter suchen
buildfelder ENDP

; Löscht den 'vergeben'-Hinweis in den allen Wortköpfen,
; bei denen gilt .len .le. bp
; ARGS: DS,ES auf data segment
;       BP : falls .len <= BP dann .len := 0 für alle Wortköpfe
; RETS: -
; REGS: alle erhalten
;-----------------------------------------------------------------1400
resetwoerter PROC NEAR
        pushing <bx,si>
        mov   si,woerter                      ;mit di die liste durchsuchen
        xor   bx,bx                           ;bx = 0, als konstante
        jmp   SHORT l1402

l1400:  cmp   [si.len],bp                     ;bedingung erfüllt ?
        jb    l1401                           ;  nein
        mov   [si.len],bx                     ;  ja, auf 0 setzen
l1401:  add   si,SIZE wort                    ;si auf nächsten wortkopf
l1402:  cmp   [si.wadr],bx                    ;block zu ende ?
        jne   l1400                           ;  nein
        add   si,2                            ;auf nächsten block
        cmp   [si.wadr],bx                    ;liste zu ende ?
        jne   l1400                           ;  nein
        poping <si,bx>
        ret
resetwoerter ENDP

; Setzt ein Wort in das Gitter ein
; Im Wortkopf und im Feldkopf werden die Werte entsprechend geändert
; ARGS: DS,ES auf data segment
;       BX auf den Feldkopf, gibt an wo eingestzt wird
;       SI auf den Wortkopf, gibt an was eingestzt wird
;       BP auf Anfang des Gitters
; RETS: -
; REGS: alle erhalten
;-----------------------------------------------------------------1500
einsetzwort PROC NEAR
        pushing <ax,si,di>
        mov   [si.len],bp                     ;als vergeben kennzeichnen
        mov   [bx.leer],bp                    ;als gefüllt kennzeichnen
        mov   si,[si.wadr]                    ;das einsetzten
        mov   ah,[bx.rcd]                     ;die orientierung des feldes
        mov   di,[bx.gadr]                    ;dorthin einsetzen
        add   di,bp                           ;absolute adresse
        cld
        jmp   SHORT l1501

l1500:  mov   [di],al                         ;ins gitter einsetzen
        go    ah,di
l1501:  lodsb                                 ;aus dem wort lesen
        or    al,al                           ;wort zu ende ?
        jnz   l1500                           ;nein

        poping <di,si,ax>
        ret
einsetzwort ENDP

; Prüft ob ein Wort in das Feld des Gitters eingesetzt werden kann
; ARGS: DS,ES auf data segment
;       BX auf Feldkopf
;       SI auf Wortkopf
;       BP auf Gitteranfang
; RETS: ZERO    => das Wort paßt
;       NO ZERO => das Wort paßt nicht
; REGS: alle erhalten
;-----------------------------------------------------------------1700
cmpwort PROC NEAR
        pushing <ax,dx,di,si>
        mov   di,[bx.gadr]                    ;mit di im gitter laufen
        add   di,bp                           ;absolute adresse
        mov   ah,[bx.rcd]                     ;orientierung des feldes
        mov   si,[si.wadr]                    ;mit si das wort durchlaufen
        mov   dh,spchr                        ;konstante
        cld
        jmp   SHORT l1702

l1700:  mov   dl,[di]                         ;zeichen aus gitter lesen
        cmp   dl,dh                           ;ist die position leer ?
        je    l1701                           ;  ja
        cmp   al,dl                           ;paßt das wort ?
        jne   l1703                           ;  nein
l1701:  go    ah,di
l1702:  lodsb                                 ;zeichen aus wort lesen
        or    al,al                           ;string zu ende ?
        jnz   l1700                           ;  nein
l1703:  poping <si,di,dx,ax>
        ret
cmpwort ENDP

; Sucht nach in ein Feld passenden Wörter.
; ARGS: DS,ES auf data segment
;       BX auf Feldkopf
; RETS: CX Anzahl der passenden Wörter
;       SI auf letzten passendes Wort
; REGS: außer CX,SI alle anderen erhalten
;-----------------------------------------------------------------1800
checkfeld PROC NEAR
        pushing <ax,dx>
        mov   si,[bx.sadr]                    ;auf liste möglicher wörter
        xor   cx,cx                           ;anzahl der passenden zählen
        xor   ax,ax                           ;als konstante

l1800:  cmp   [si.len],ax                     ;das wort noch verfügbar ?
        jne   l1801                           ;  nein
        call  cmpwort                         ;vergleichen
        jnz   l1801                           ;paßt nicht
        mov   dx,si                           ;den wortkopf merken
        inc   cx                              ;passende wörter zählen
l1801:  add   si,SIZE wort                    ;auf nächsten wortkopf
        cmp   [si.wadr],ax                    ;liste zu ende ?
        jne   l1800                           ;  nein
        mov   si,dx                           ;passendes wort zurückgeben
        poping <dx,ax>
        ret
checkfeld ENDP

; Setzt alle eindeutig bestimmte Felder ein.
; ARGS: DS,ES auf data segment
; RETS: CARRY    => mindestens ein Feld kann nicht gefüllt werden
;       NO CARRY => BX auf Feldkopf mit den wenigsten Möglichkeiten
;                   oder BX = 0, dann ist das Gitter ausgefüllt
; REGS: außer BX alle anderen erhalten
;-----------------------------------------------------------------1900
zwang   PROC NEAR
        pushing <ax,cx,dx,si,di>
l1900:  mov   bx,felder                       ;mit bx die felder durchlaufen
        xor   dx,dx                           ;zählt gemachte einsetzungen
        mov   ax,0FFFFH                       ;kleinste anzahl won möglichkeiten
        xor   di,di                           ;der feldkopf bei dem dies

l1901:  cmp   [bx.leer],0                     ;feld noch leer ?
        jnz   l1903                           ;  nein
        call  checkfeld                       ;passendes wort suchen
        cmp   cx,1
        jb    l1905                           ;es gibt keins, nicht lösbar
        ja    l1902                           ;es gibt mehrere
        inc   dx                              ;einsetzung zählen
        call  einsetzwort                     ;wort einsetzen
        jmp   SHORT l1903                     ;zum nächsten

l1902:  cmp   ax,cx                           ;neues Minimum ?
        jb    l1903                           ;  nein
        mov   ax,cx                           ;  ja, merken
        mov   di,bx                           ;den feldkopf merken

l1903:  add   bx,SIZE feld                    ;auf nächstes feld in liste
        cmp   WORD PTR [bx],0                 ;liste zu ende ?
        jnz   l1901                           ;  nein

        or    dx,dx                           ;wurde etwas eingesetzt ?
        jnz   l1900                           ;liste nochmal durchgehen

        mov   bx,di                           ;adr des feldkopfs übergeben
        clc                                   ;gitter noch lösbar
l1904:  poping <di,si,dx,cx,ax>
        ret

l1905:  xor   bx,bx                           ;dummy wert
        stc                                   ;gitter nicht lösbar
        jmp   l1904                           ;fertig
zwang   ENDP

; Versuch das Gitter zu lösen
; eine Kopie des alten Gitters wird angefertigt
; das Wort SI in das Feld BX eingesetzt
; dann werden alle Zwangs-Einsetzungen vorgenommen
; dann werden bei einem Feld alle Möglichkeiten ausprobiert
; zum Abschluß werden alle Spuren beseitigt
; ARGS: BX = 0 ,dann keine Einsetzung zuerst machen
;       SI auf einen Wortkopf zum einsetzen
;       BP auf das 'alte' Gitter
; RETS: -
; REGS: alle erhalten
;-----------------------------------------------------------------2000
loese   PROC NEAR
        pushing <bx,cx,dx,si,di,bp>
        mov   dx,si                           ;si zwischenspeichern
        mov   si,bp                           ;vom alten gitter kopieren
        mov   di,free                         ;dorthin neues gitter
        mov   bp,di                           ;adresse des neuen merken
        mov   cx,laenge                       ;größe des gitters
        add   bp,cx                           ;speicher bis FFFF frei
        jnc   l2007                           ;speicher groß genug
        mov   al,3                            ;fehlermeldung
        jmp   myerror
l2007:  mov   bp,di                           ;wiederherstellen
        rep movsw                             ;gitter kopieren
        mov   free,di                         ;neue speicher frei grenze

        or    bx,bx                           ;muß eingesetzt werden ?
        jz    l2000                           ;  nein
        mov   si,dx                           ;si wieder zurück
        call  einsetzwort                     ;einsetzen
l2000:  call  zwang                           ;die zwingenden machen
        jc    l2004                           ;das gitter ist nicht lösbar
        or    bx,bx                           ;alles ausgefüllt ?
        jnz   l2001                           ;  nein
        call  ausgabe                         ;  ja, ergebnis ausgeben
        jmp   SHORT l2004

l2001:  mov   si,[bx.sadr]                    ;auf mögliche wörter
l2002:  cmp   [si.len],0                      ;das wort benutzt ?
        jne   l2003                           ;  ja
        call  cmpwort                         ;paßt das wort ?
        jnz   l2003                           ;  nein
        call  loese                           ;  ja, damit ausprobieren
l2003:  add   si,SIZE wort                    ;auf nächstes wort
        cmp   WORD PTR [si],0                 ;ist die liste zu ende ?
        jnz   l2002                           ;  nein

l2004:  call  resetwoerter                    ;benutzte wörter freigeben

        mov   bx,felder                       ;die felder freigeben
        xor   cx,cx                           ;cx := 0, als konstante
l2005:  cmp   [bx.leer],bp                    ;feld von mit gefüllt ?
        jb    l2006                           ;  nein
        mov   [bx.leer],cx
l2006:  add   bx,SIZE feld                    ;auf nächsten kopf
        cmp   [bx],cx                         ;liste zu ende ? (cx=0)
        jnz   l2005

        mov   free,bp                         ;speicher wieder freigeben
        poping <bp,di,si,dx,cx,bx>
        ret
loese   ENDP

;=====================================================================
; Die Reihenfolde der folgenden PROC's ist wichtig !

; Speicherbelegung durchführen
; ARGS: ES auf PSH
; RETS: ES,DS auf data Segment
; REGS: -
;-----------------------------------------------------------------0000
init    PROC NEAR
        mov   bx,segdata                      ;beginn der daten
        mov   ax,es
        sub   bx,ax                           ;länge des codes
        add   bx,1000H + stacksize/16         ;benötigter speicher
        mov   ah,4AH                          ;modify allocated block
        doscall
        mov   ax,segdata                      ;data segmente setzen
        mov   es,ax
        mov   ds,ax
        add   ax,1000H                        ;data dort zu ende
        mov   bx,stacksize
        cli                                   ;neuer stack einrichten
        mov   ss,ax
        mov   sp,bx
        sti
init    ENDP

; Laden aus Standartinput
; Datei muß kleiner als filesize sein !
; ARGS: -
; RETS: -
; REGS: ES,DS auf data segment
;-----------------------------------------------------------------0200
load    PROC NEAR
        mov   bx,stdin                        ;aus standartinput lesen
        mov   dx,fileptr                      ;ds:dx auf filebuffer
        mov   cx,filesize                     ;maximale länge
        mov   ah,3FH                          ;read a file
        doscall
        cmp   ax,cx                           ;datei zu groß ?
        jb    l0200                           ;  nein
        mov   al,1                            ;  ja
        jmp   myerror                         ;fehlermeldung ausgeben
l0200:  add   dx,ax                           ;fileanfang + filelänge
        mov   bx,dx                           ;hinter fileende
        mov   BYTE PTR [bx],eof               ;ende der Datei kennzeichen
load    ENDP

; Liest die vorgegeben Wörter ein
; ARGS: -
; RETS: -
; REGS: ES,DS auf data segment
;-----------------------------------------------------------------0800
wortein PROC NEAR
        mov   bx,fileptr
        sub   bx,4                            ;obere grenze des freien speichers
        and   bl,0FEH                         ;auf word abrunden
        mov   di,free                         ;unter grenze      -"-
        call  loadworts
        inc   di
        and   di,0FFFEH                       ;di auf word aufrunden
        mov   woerter,di                      ;adr der wortkopf liste merken
l0800:  call  takeworts                       ;wörter der länge dx aussuchen
        or    dx,dx                           ;max länge = 0 ?
        jnz   l0800                           ;nein, es gibt noch wörter
        mov   WORD PTR [di],0                 ;liste abschließen
        add   di,2
wortein ENDP

; Liest das Gitter ein, zuerst in normalen Strings
; dann werden alle Strings auf gleiche Länge gebracht
; und eine Abschlusszeile mit nur 00 angehängt
; ARGS: DS,ES auf data segment
;       DI untere Speichergrenze
; RETS: -
; REGS: ES,DS auf data segment
;-----------------------------------------------------------------0900
gitterein PROC NEAR
        mov   bx,fileptr
        sub   bx,4                            ;obere grenze des freien speichers
        and   bl,0FEH                         ;auf word abrunden
        mov   gitter,di                       ;adr des gitters merken
        call  loadworts
        mov   zeilen,cx                       ;größe des gitters merken
        mov   spalten,dx

        inc   dx
        mov   schritt,dx                      ;schrittweite merken
        mov   ax,cx
        mul   dx                              ;ax := ax * dx, dx := 0
        mov   dx,ax
        dec   dx
        mov   nschritt,dx                     ;zum spaltenweisen durchlaufen
        mov   si,di                           ;si auf erstes freies byte
        dec   si                              ;si auf ende der strings
        mov   di,gitter
        add   di,ax                           ;di hinter das gitter
        push  di                              ;für später merken
        dec   di                              ;di auf ende des format. gitters
        dec   cx
        sal   cx,1
        sal   cx,1
        sub   bx,cx                           ;bx auf letzten wortkopf

        std                                   ;di,si läuft abwärts
        mov   al,space                        ;zeile füllen mit spaces

l0900:  mov   dx,[bx.len]                     ;länge des strings
        mov   cx,spalten                      ;auf diese länge bringen
        sub   cx,dx                           ;das muß aufgefüllt werden
        movsb                                 ;zeilenabschluß kopieren
        rep stosb
        mov   cx,dx                           ;rest der zeile kopieren
        rep movsb
        add   bx,SIZE wort                    ;auf nächsten wortkopf
        cmp   si,di                           ;weiteres schieben nötig ?
        jne   l0900                           ;  ja

        pop   di                              ;gemerktes gitter ende holen
        mov   cx,spalten                      ;länge der abschlußzeile
        xor   al,al                           ;besteht aus nullen
        cld                                   ;di läuft nun aufwärts
        rep stosb                             ;zeile schreiben
        mov   ax,di
        sub   ax,gitter                       ;laenge des gesamten gitters
        sar   ax,1                            ;in words
        jnc   l0901
        inc   ax                              ;aufrunden
l0901:  mov   laenge,ax                       ;laenge speichern
gitterein ENDP

; Durchsucht das Gitter, erstellt dabei Liste der Felder
; ARGS: DS,ES auf data segment
;       DI untere Speichergrenze
; RETS: -
; REGS: ES,DS auf data segment
;-----------------------------------------------------------------1100
suchefelder PROC NEAR
        inc   di
        and   di,0FFFEH                       ;di auf wordgrenze aufrunden
        mov   felder,di                       ;anfang der liste merken
        mov   ah,rechts
        call  buildfelder                     ;alle rechts orientierte sammeln
        mov   ah,unten
        call  buildfelder                     ;alle nach unten orientierte
        mov   WORD PTR [di],0                 ;liste abschliessen
        add   di,2
        mov   free,di
suchefelder ENDP

; Versuchen das Gitter zu lösen
; ARGS: DS,ES auf data segment
; RETS: -
; REGS: ES,DS auf data segment
;-----------------------------------------------------------------2200
doit    PROC NEAR
        xor   bp,bp
        call  resetwoerter                    ;alle .len felder auf 0 setzen
        mov   bp,gitter                       ;dort liegt das orginal gitter
        xor   bx,bx                           ;kein wort vorgeben
        call  loese                           ;lösungsversuch
doit    ENDP

; Programm beenden
; ARGS: -
; RETS: -
; REGS: ES,DS auf data segment
;-----------------------------------------------------------------0300
termit  PROC NEAR
        mov   ax,4C00H                        ;exit from a process
        doscall
l0300:  mov   ax,4CFFH                        ;sicher ist besser
        int   21H
        jmp   l0300
termit  ENDP

code    ENDS

;=====================================================================
stack   SEGMENT WORD STACK
        DB 100H DUP (?)
stack   ENDS

        END init
