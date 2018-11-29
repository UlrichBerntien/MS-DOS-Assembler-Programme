        PAGE 80,132
        .SALL
;=====================================================================
; MS-Macro-Assembler V1.0 / Wang PC
; (c) Ulrich Berntien .12.1990
;     letzte Änderung .12.1990
;=====================================================================
; Aufrufformat:  FCMP [switches] <datei1> [switches] <datei2> [switches]
;
; Fehlercodes bei Programmende ans DOS:
;       00H   -  kein Fehler, Dateien sind gleich
;       01H   -  kein Fehler, Dateien sind ungleich
;       02H   -  falsche Parameter
;       03H   -  DOS hat Fehler gemeldet
;
; Reihenfolge der Segmente muß eingehalten werden:
;       code
;       data
;       stack
;=====================================================================

code    SEGMENT WORD PUBLIC 'code'
code    ENDS

; Macros
;=====================================================================

; Betriebssystem-Aufruf mit Fehlerüberwachung
;---------------------------------------------------------------------
dos     MACRO
        LOCAL no_error
        clc
        int   21H
        jnc   no_error
        jmp   doserror
  no_error:
        ENDM

; Speicher belegen, mit dptr verwaltet
;---------------------------------------------------------------------
mem     MACRO name,size
  name     = dptr
  dptr     = dptr + size
        ENDM

; Einen DOS-Fehlermeldung speichern
;---------------------------------------------------------------------
doserr  MACRO num,text
        LOCAL len, msg
  msg     DB len
          DB num
          DB text
  len EQU $ - msg
        ENDM

; Register auf dem Stack sichern
;---------------------------------------------------------------------
pushing MACRO regs
          IRP reg,<regs>
            push reg
          ENDM
        ENDM

; Register vom Stack zurückholen
;---------------------------------------------------------------------
poping  MACRO regs
          IRP reg,<regs>
            pop reg
          ENDM
        ENDM

; Konstanten-Vereinbarungen
;=====================================================================

stacksize  EQU 04 * 1024                      ;größe des stacks
buffersize EQU 25 * 1024                      ;größe der buffers

stdout EQU 1                                  ;standart output device
stderr EQU 2                                  ;standart error device

        ;ascii zeichen
cr        EQU 0DH
lf        EQU 0AH
space     EQU 20H
switchchr EQU '-'

        ;system zustände:
sys_name1      EQU 1                          ;datei1 name lesen
sys_name2      EQU 2                          ;datei2 name lesen
sys_gelesen    EQU 3                          ;beide namen gelesen
sys_datei1ende EQU 4
sys_datei2ende EQU 5
sys_dateiende  EQU 6

        ;switches
n_switch EQU 1
d_switch EQU 2

; Datenbereich, wird bei Initialisierung expandiert
;=====================================================================
data    SEGMENT WORD PUBLIC 'data'

datafirst EQU $                               ;anfang des datenbereichs

psh_seg DW ?                                  ;segment des PSH

datei1  DW ?                                  ;handle der dateien
datei2  DW ?

dclow   DW 0                                  ;DDWORD
dchigh  DW 0                                  ;  zähler der ungleichen bytes

ct1     DW ?                                  ;zähler für die ausgabe
ct3     DW ?

zeile   STRUC                                 ;format der ausgabe zeile
  count DB 8 DUP (space)
        DB ?
        DB space,space
  hex   DB 16*3 DUP (space)
        DB space
  chr   DB 16 DUP (space)
        DB cr,lf
zeile   ENDS

zeile1  zeile <,'H'>                          ;erste zeile
zeile2  zeile <,space>                        ;zeite zeile

outsize EQU $ - zeile1                        ;länge der ausgabe-zeile

sys     DB sys_name1                          ;system status

sws     DB d_switch                           ;gesetzte schalter

switches DB 'NnDd',00                         ;liste der switch ziechen

swtable EQU THIS WORD
        DB n_switch,0                         ;zu setzende bits,löschende
        DB 0,n_switch
        DB d_switch,0
        DB 0,d_switch

ziffer  DB '0123456789ABCDEF'                 ;ascii ziffern

err1    DB 'DOS-Error '                       ;allg. dos fehlermeldungen
errn    DB '.. (hex)',cr,lf
err1len EQU $ - err1
err2    DB cr,lf,'Programm bendet',cr,lf
err2len EQU $ - err2

dos_table EQU THIS BYTE                       ;tabelle der dos fehlermeldungen
        doserr 002H,'file not found'
        doserr 003H,'path not found'
        doserr 004H,'too many open files'
        doserr 005H,'access denied'
        doserr 006H,'invalid handle'
        doserr 008H,'not enough memory'
        doserr 00CH,'invalid access'
        doserr 00FH,'invalid drive'
        doserr 000H,'no error occured'        ;mit 0000 beneden

myerr   DB 'FCMP - File compare',cr,lf
        DB '(c) Ulrich Berntien .12.1990',cr,lf,lf
        DB 'Aufrufformat:',cr,lf
        DB '  FCMP [-sw] <datei1> [-sw] <datei2> [-sw]',cr,lf
        DB '<datei.>  Name der zu vergleichenden Dateien',cr,lf
        DB 'sw        mögliche Schalter:',cr,lf
        DB '  N/n   Nullmeldung ein/ausschalten',cr,lf
        DB '  D/d   Ausgabe der unterschiedlichen Bytes ein/aus',cr,lf
        DB lf,'Ausgabezeilen bei Ungleichheit:',cr,lf
        DB '  Nr.des Bytes       Bytes aus Datei1',cr,lf
        DB '   (dezimal)         Bytes aus Datei2',cr,lf
        DB 'Nummerierung beginnt bei 0',cr,lf
        DB lf,'Programm benendet',cr,lf

myerrlen EQU $ - myerr

dt1e    DB 'Ende von Datei 1 erreicht'
dt2e    DB 'Ende von Datei 2 erreicht'
dte     DB 'Ende der Dateien erreicht'
dtlen EQU $ - dte

diffs   DB cr,lf,'Unterschiedliche Bytes: '
        DB 8 DUP (space)
diffn   DB '0'
        DB cr,lf
difflen EQU $ - diffs

dptr = $                                      ;ab hier mit dptr verwalten

mem buffer1,buffersize                        ;filebuffer anlegen
mem buffer2,buffersize

datasize EQU dptr - datafirst                 ;länge des datenbereichs

data    ENDS

; Code Bereich
;=====================================================================
code    SEGMENT WORD PUBLIC 'code'

data_seg DW SEG data                          ;segment von data

;=====================================================================
ASSUME es : data, cs : code,  ss : stack
;=====================================================================

; Öffnet Datei für lesenden Zugriff
; beachtet Systemstatus "sys" zum Abspeichern des Handles
; ARGS: DS:DX auf Dateiname
; RETS: -
; REGS: alle erhalten
;-----------------------------------------------------------------0200
opendatei PROC NEAR
        pushing <ax,bx,cx>
        mov   cl,sys                          ;system status lesen
        cmp   cl,sys_name2                    ;system status prüfen
        jle   l0200                           ;falls ok
        jmp   parerror                        ;zuviele dateien
l0200:  mov   ax,3D00H                        ;open a file for reading
        dos
        cmp   cl,sys_name1                    ;datei1 geöffnet ?
        jne   l0201                           ;  nein
        mov   datei1,ax                       ;  ja, dort handle merken
        jmp   SHORT l0202
l0201:  mov   datei2,ax                       ;handle von datei2 merken
l0202:  inc   cl                              ;nächster system status
        mov   sys,cl                          ;status speichern
        poping <cx,bx,ax>
        ret
opendatei ENDP

; Auswertung der Schalter
; ARGS: DS:SI auf Schalter
;       CX Restlänge der Commandline
; RETS: SI hinter den Schalter
;       CX Anzahl der restlichen Zeichen
; REGS: alle Anderen erhalten
;-----------------------------------------------------------------0700
switch  PROC NEAR
        pushing <ax,bx>
l0701:  inc   si                              ;aus nächstes zeichen
        dec   cx
        jz    l0700                           ;falls zeile zu ende
        mov   al,[si]                         ;zeichen lesen
        cmp   al,space                        ;ist schalter zu ende ?
        jle   l0700                           ;  ja, dann zurück
        xor   bx,bx                           ;mit bx die tabelle indizieren
l0702:  mov   ah,[bx+switches]                ;zeichen aus tabelle lesen
        cmp   ah,al
        je    l0703                           ;zeichen sind gleich
        inc   bx                              ;auf nächstes zeichen
        or    ah,ah                           ;tabelle zu ende ?
        jnz   l0702                           ;  nein, dann weiter
        jmp   l0701                           ;  ja, switch ignorieren
l0703:  sal   bx,1                            ;words indizieren
        mov   ax,[bx+swtable]                 ;zu setzende/löschnde bits laden
        or    al,sws                          ;bits sezten
        not   ah                              ;maske erzeugen
        and   al,ah                           ;bits l╠schen
        mov   sws,al                          ;neu schalterstellung speichern
        jmp   l0701                           ;weiter in der schalterauswertung
l0700:  poping <bx,ax>
        ret
switch  ENDP

; Kommandozeile auswerten
; ARGS: -
; RETS: -
; REGS: Sgement Register erhalten
;-----------------------------------------------------------------0100
cmdline PROC NEAR
        pushing <ds,es>
        mov   ax,ds
        mov   es,ax                           ;es auf data
        mov   ds,[psh_seg]                    ;ds auf psh segment
        mov   si,0080H                        ;auf anfang der cmdline
        mov   cl,[si]                         ;länge der command line
        xor   ch,ch                           ;cx := cl
        jcxz  l0100                           ;falls zeile leer ist
        inc   cx
l0102:  inc   si                              ;auf nächstes zeich in der zeile
        dec   cx                              ;zeichen zählen
        jz    l0100                           ;falls zeile zu ende
        mov   al,[si]                         ;zeichen aus zeile lesen
        cmp   al,space                        ;ist es ein füllzeichen
        jle   l0102                           ;  ja, überlesen
        cmp   al,switchchr                    ;ist es das switch-zeichne
        jne   l0103                           ;  nein
        call  switch                          ;  ja, dann den schalter auswerten
        or    cx,cx                           ;zeile zu ende ?
        jnz   l0102                           ;  nein, weiter auswerten
        jmp   l0100                           ;  ja
l0103:  mov   dx,si                           ;anfang des dateinamen merken
l0105:  inc   si                              ;auf nächstes zeichen
        dec   cx
        jz    l0104                           ;falls zeile zu ende
        cmp   BYTE PTR [si],space             ;name zu ende ?
        jg    l0105                           ;  nein
l0104:  mov   BYTE PTR [si],0                 ;name mit 00 beneden
        call  opendatei                       ;datei öffnen
        or    cx,cx                           ;ist zeile zu ende
        jnz   l0102                           ;  nein, weiter mit auswertung
l0100:  cmp   sys,sys_gelesen                 ;alles glatt gegangen ?
        je    l0101                           ;  ja, dann zurück
        jmp   parerror                        ;  nein, dann fehler
l0101:  poping <es,ds>
        ret
cmdline ENDP

;=====================================================================
ASSUME ds : data, cs : code,  ss : stack, es : data
;=====================================================================

; Ein Byte in HEX Format ausgeben
; ARGS: AL mit dem auszugebendem Byte
;       DS:BP ab dieser Adresse schreiben
; RETS: BP hinter die letzte Ziffer
; REGS: alle erhalten
;-----------------------------------------------------------------1000
byteh   PROC NEAR
        pushing <ax,bx,cx,dx>
        mov   dl,2
l1000:  mov   cl,4
        rol   al,cl                           ;ein nibbel weiterschieben
        mov   bx,ax
        and   bx,1111B
        mov   bl,[ziffer+bx]                  ;ascii ziffer holen
        mov   ds:[bp],bl                      ;sschreiben
        inc   bp                              ;auf nächste ziffer
        dec   dl                              ;ziffer zählen
        jnz   l1000                           ;noch eine ziffer da
        poping <dx,cx,bx,ax>
        ret
byteh   ENDP

; Ausgabe eines Doppelwords in HEX Format
; ARGS: (DX,BX) mit dem auszugebem Doppelword, BX low word
;       DS:BP ab dieser Adresse schreiben
; RETS: BP hinter die letzte ziffer
; REGS: alle erhalten
;-----------------------------------------------------------------1100
dwordh  PROC NEAR
        pushing <ax>
        IRP bb,<dh,dl,bh,bl>
          mov   al,bb
          call  byteh
        ENDM
        poping <ax>
        ret
dwordh  ENDP

; Ausagbe eines WORDs in Dezimal Form
; ARGS: AX das auszugeben Word
;       DS:BP auf letzte Stelle im Ausgabebereich
;       CX Anzahl der minimal auszugebenden Stellen
; RETS: BP vor die letzte geschriebene Ziffer
; REGS: alle anderen erhalten
;-----------------------------------------------------------------1400
wordd   PROC NEAR
        pushing <ax,bx,dx,cx>
        mov   bx,10                           ;basis des zahlensystems
l1400:  xor   dx,dx                           ;(dx,ax) := ax
        div   bx                              ;durch 10 teilen
        add   dl,'0'                          ;ascii ziffer
        mov   ds:[bp],dl                      ;schreiben
        dec   bp                              ;auf höhere stelle
        dec   cx                              ;ziffern zählen
        or    ax,ax                           ;ist zahl kompl. ausgegeben ?
        jnz   l1400                           ;  nein, weiter
        cmp   cx,0                            ;ist sollstellen-zahl erreicht ?
        jle   l1401                           ;  ja, dann fertig
        mov   al,'0'                          ;auffüllen mit nullen
l1402:  mov   ds:[bp],al
        dec   bp
        loop  l1402                           ;bis alle sollstellen gefüllt
l1401:  poping <cx,dx,bx,ax>
        ret
wordd   ENDP

; Ausgeben eines DWORDs in Dezimal Format
; ARGS: (DX,BX) mit der Zahl, BX low word
;       DS:BP auf die letzte Stelle
; RETS: BP vor die höchste Stelle
; REGS: alle anderen erhalten
;-----------------------------------------------------------------1500
dwordd  PROC NEAR
        pushing <ax,bx,cx,dx>
        mov   ax,bx                           ;(dx,ax) := (dx,bx)
        mov   cx,10000                        ;aufteilen in zwei words notwendig
        div   cx
        xor   cx,cx
        or    ax,ax
        jz    l1500                           ;falls größer als 10000
        mov   cx,4                            ;nullen müssen ausgegeben werden
l1500:  xchg  ax,dx
        call  wordd                           ;den teil unter 10000 ausgeben
        jcxz  l1501
        xor   cx,cx
        mov   ax,dx
        call  wordd                           ;den teil über 10000 ausgeben
l1501:  poping <dx,cx,bx,ax>
        ret
dwordd  ENDP

; DOS-Fehlerbehandlung, danach wird Programm abgebrochen
; ARGS: AX mit DOS-Fehlercode
;-----------------------------------------------------------------0800
doserror PROC NEAR
        mov   ds,data_seg                     ;ds auf das datensegment
        mov   bp,OFFSET errn
        call  byteh                           ;fehlernummer ausgeben
        mov   bp,ax                           ;fehlernummer merken
        mov   dx,OFFSET err1                  ;erste meldung
        mov   cx,err1len
        mov   bx,stderr                       ;auf standart error device
        mov   ah,40H                          ;write a file
        int   21H
        mov   cx,bp                           ;fehlernummer zurückholen
        mov   si,OFFSET dos_table             ;die fehlertabelle durchsuchen
l0802:  mov   ax,[si]
        cmp   ah,cl                           ;stimmt die fehlernummer ?
        je    l0801                           ;  ja
        or    ah,ah                           ;ende der tabelle ?
        jz    l0801                           ;  ja
        xor   ah,ah                           ;ax := al
        add   si,ax                           ;auf nächsten eintrag
        jmp   l0802                           ;schleife über die tabell
l0801:  xor   ah,ah                           ;ax := al
        mov   cx,ax
        sub   cx,2                            ;länge der fehlermeldung
        lea   dx,[si+02]                      ;dx auf den text
        mov   ah,40H                          ;write a file
        int   21H
        mov   dx,OFFSET err2                  ;abschluß meldung
        mov   cx,err2len
        mov   bx,stderr                       ;auf standart error device
        mov   ah,40H                          ;write a file
        int   21H
l0800:  mov   ax,4C03H                        ;terminate program, return code 3
        int   21H
        jmp   l0800
doserror ENDP

; Fehlerbehandlung bei falschen Parametern, mit Programmende
; ARGS: -
;-----------------------------------------------------------------0500
parerror PROC NEAR
        mov   ds,data_seg                     ;ds auf datensegment
        mov   dx,OFFSET myerr                 ;fehlermeldung
        mov   cx,myerrlen
        mov   bx,stderr                       ;auf standart error device
        mov   ah,40H                          ;write a file
        dos
l0500:  mov   ax,4C02H                        ;terminate program, return code 2
        dos
        jmp   l0500
parerror ENDP

; Die Speicherbelegung durchführen
; der Inhalt des Stacks geht verloren
; ARGS: -
; RETS: -
; REGS: CS,DS erhalten
;-----------------------------------------------------------------0400
setmem  PROC NEAR
        mov   bx,ds
        add   bx,( datasize+stacksize )/ 16 + 1 ;ende des benötigten speichers
        mov   ax,psh_seg                      ;anfang des programmspeicher
        sub   bx,ax                           ;paragraphen des speichers
        mov   es,ax
        mov   ah,4AH                          ;modify allocated memory
        dos
        mov   ax,ds
        add   ax,datasize/16 + 1              ;ax auf segment des stacks
        mov   bx,stacksize                    ;sp auf höchste adresse
        pop   dx                              ;rücksprung adresse merken
        cli                                   ;interrupts verhindern
        mov   ss,ax                           ;stack einrichten
        mov   sp,bx
        sti                                   ;wieder interrupts möglich
        jmp   dx                              ;simulierter rücksprung
setmem  ENDP

; lädt aus den beiden Dateien die beiden Buffern
; ARGS: -
; RETS: CX Anzahl der gelesenen Bytes
;       SI,DI auf Anfang des Buffers1, Buffers2
;       Falls Dateiende errecih "sys" entsprechend gesetzt
; REGS: alle außer CX erhalten
;-----------------------------------------------------------------0900
load    PROC NEAR
        xor   cx,cx                           ;cx := 0, buffer leer
        cmp   sys,sys_datei1ende              ;ist die datei schon am ende ?
        jge   l0904
        pushing <ax,bx,dx,bp>
        mov   bx,datei1                       ;handle von datei1
        mov   dx,OFFSET buffer1               ;ds:dx auf buffer1
        mov   cx,buffersize                   ;lúnge des buffers
        mov   ah,3FH                          ;read a file or device
        dos
        mov   bp,ax                           ;di anzahl der bytes sichern
        cmp   ax,cx                           ;alles gelesen ?
        je    l0900                           ;  ja
        mov   sys,sys_datei1ende              ;datei1 zu ende
l0900:  mov   bx,datei2                       ;handle von datei2
        mov   dx,OFFSET buffer2               ;ds:dx auf buffer2
        mov   ah,3FH                          ;read a file or device
        dos
        cmp   ax,cx                           ;alles gelesen ?
        je    l0901                           ;  ja
        cmp   sys,sys_datei1ende              ;ist datei1 auch zu ende ?
        jne   l0902                           ;  nein
        cmp   ax,bp                           ;war datei2 vor datei1 zu ende ?
        jl    l0902                           ;  ja
        jg    l0901                           ;  nein, datei1 zu erst
        mov   sys,sys_dateiende               ;  nein, beide dateien zu ende
        jmp   SHORT l0901
l0902:  mov   sys,sys_datei2ende              ;  nein, nur datei2 zu ende
l0901:  mov   cx,ax                           ;nutzbare länge buffer1
        cmp   cx,bp                           ;ist buffer2 länge ?
        jle   l0903                           ;  ja, oder gleich lang
        mov   cx,bp                           ;  nein, das ist nutzbare länge
l0903:  mov   si,OFFSET buffer1               ;mit si,di adressieren
        mov   di,OFFSET buffer2
        poping <bp,dx,bx,ax>
l0904:  ret
load    ENDP

; Vorbereiten der Ausgabezeile
; Eintragen der Nummer des Bytes, Rest löschen
; ARGS: (DX,BX) Nummer des Bytes, BX low word
; RETS: -
; REGS: alle erhalten, DS,ES auf data Segment
;-----------------------------------------------------------------1200
prepare PROC NEAR
        pushing <ax,cx,di,bp>
        mov   al,space
        mov   di,OFFSET zeile1.hex            ;auf die erste zeile
        mov   cx,SIZE zeile - 13
        rep   stosb                           ;erste zeile mit spaces füllen
        mov   di,OFFSET zeile2.count          ;auf die zweite zeile
        mov   cx,SIZE zeile - 2
        rep   stosb                           ;zweite zeile mit spaces füllen
        mov   bp,OFFSET zeile1.count          ;zählerstand schreiben
        call  dwordh                          ;einmal in hex
        mov   bp,OFFSET zeile2.count+8        ;in der zeile darunte
        call  dwordd                          ;und einmal in dezimal
        xor   ax,ax
        mov   ct1,ax                          ;die zähler auf 0 setzen
        mov   ct3,ax
        poping <bp,di,cx,ax>
        ret
prepare ENDP

; ein Byte in eine Ausgabezeile schreiben
; ARGS: BP auf Anfang der Zeile
;       AL das auszugebende Zeichen
;       ct1,ct3 die Zähler geben die Positionen an
; RETS: -
; REGS: alle erhalten
;-----------------------------------------------------------------1300
ausgabe PROC NEAR
        pushing <bx,bp>
        mov   bx,bp                           ;zeiger sichern
        lea   bp,(zeile PTR [bx]).hex
        add   bp,ct3                          ;bp auf das byte in hexformat
        call  byteh
        lea   bx,(zeile PTR [bx]).chr
        add   bx,ct1                          ;bx auf das byte in chr format
        cmp   al,space
        jl    l1300
        cmp   al,128
        je    l1300
        mov   [bx],al                         ;zeichen schreiben
        jmp   SHORT l1301
l1300:  mov   BYTE PTR [bx],'.'               ;nicht druckbares zeichen
l1301:  poping <bp,bx>
        ret
ausgabe ENDP

; Ungleiches Byte gefunden
; ARGS: SI,DI im Buffer1,Buffer2 auf die unterschiedlichen Bytes
;       (DX,BX) Nummer des Bytes, BX low word
;       CX Anzahl der Bytes noch im Buffer
; RETS: SI,DI,BX,DX,CX hinter die ausgegebenen Bytes
; REGS: alle anderen erhalten
;-----------------------------------------------------------------0300
different PROC NEAR
        call  prepare                         ;ausgabe zeile vorbereiten
        pushing <ax,bp>
l0303:  mov   al,[si]                         ;byte aus datei1 laden
        mov   bp,OFFSET zeile1                ;zeiger auf erste zeile
        call  ausgabe                         ;byte ausgeben
        mov   ah,[di]                         ;byte aus datei2 laden
        cmp   ah,al                           ;bytes gleich ?
        je    l0300                           ;  ja, dann nicht dc erhöhen
        inc   dclow                           ;ungleiche bytes zählen
        jnz   l0300
        inc   dchigh                          ;übertrag
l0300:  mov   al,ah
        mov   bp,OFFSET zeile2                ;zeiger auf zweite zeile
        call  ausgabe
        inc   si                              ;auf nächstes byte
        inc   di
        inc   bx                              ;bytes in datei zählen
        jnz   l0304
        inc   dx                              ;übertrag
l0304:  dec   cx                              ;zeichen im buffer zählen
        jnz   l0301                           ;falls buffer noch nicht leer ist
        call  load                            ;buffer nachladen
        jcxz  l0302                           ;falls datei zu ende
l0301:  add   ct3,3                           ;zähler erhöhen
        mov   ax,ct1
        inc   ax
        mov   ct1,ax
        cmp   ax,16                           ;16 bytes ausgeben pro zeile
        jl    l0303
l0302:  pushing <bx,cx,dx>
        mov   bx,stdout                       ;das standart ausgabe gerät
        mov   cx,outsize
        mov   dx,OFFSET zeile1                ;die zeilen ausgeben
        mov   ah,40H                          ;write a file or device
        dos
        poping <dx,cx,bx,bp,ax>
        ret
different ENDP

; Den Vergleich durchführen, beide Dateien müssen geöffnet sein
; ARGS: -
; RETS: CARRY falls dateien ungleich sind
; REGS: Segmente erhalten, DS,ES auf data Segment
;-----------------------------------------------------------------0600
compare PROC NEAR
        xor   dx,dx                           ;byte zähler auf 0 setzten
        xor   bx,bx                           ;bx low word, dx high word
l0601:  call  load                            ;inbuffer laden
        jcxz  l0602                           ;falls nichts geladen wurde
l0603:  mov   bp,si                           ;position merken
        repe  cmpsb                           ;bytes vergleichen
        jz    l0609
        test  sws,d_switch
        jz    l0608                           ;keine ausgabe erforderlich
                                              ;verschiedene bytes ausgeben:
        dec   si                              ;auf das verschiedene byte
        dec   di
        inc   cx                              ;das verschiedene byte mitzählen
        mov   ax,si
        sub   ax,bp                           ;die überflognen bytes zählen
        add   bx,ax
        jnc   l0604
        inc   dx                              ;übertrag
l0604:  call  different                       ;unterschied ausgeben
        or    cx,cx                           ;datei zu ende ?
        jnz   l0603                           ;  nein, weiter vergleichen
        jmp   l0602                           ;  ja,   fertig
                                              ;keine ausgeben, nur zählen
l0608:  inc   dclow                           ;unterschiede zählen
        jnz   l0606
        inc   dchigh
l0606:  jcxz  l0601
        jmp   l0603
                                              ;kein unterschied
l0609:  test  sws,d_switch                    ;d-switch gesetzt ?
        jz    l0601                           ;  nein, nichts zu tun
        mov   ax,si                           ;  ja, zu tun :
        sub   ax,bp                           ;die überflognen bytes zählen
        add   bx,ax
        jnc   l0601
        inc   dx                              ;übertrag
        jmp   l0601
                                              ;vergleich ist vertig:
l0602:  cmp   sys,sys_dateiende               ;beide dateien zu ende
        jne   l0607
        cmp   dclow,0                         ;wurden unterschiede gefunden ?
        jnz   l0607
        cmp   dchigh,0
        jnz   l0607
        clc                                   ;  nein, CARRY löschen
        jmp   SHORT l0605
l0607:  stc                                   ;  ja, CARRY setzen
l0605:  ret
compare ENDP

; Zusammenfassende Ausgabe des Vergleiches
; ARGS: -
; RETS: -
; REGS: DS,ES auf data Segment
;-----------------------------------------------------------------1600
summary PROC NEAR
        mov   al,sys                          ;system status lesen
        cmp   al,sys_datei2ende               ;wie sind die datei zu ende
        je    l1601
        jg    l1602
        mov   dx,OFFSET dt1e                  ;nur datei 1 zu ende
        jmp   SHORT l1600
l1601:  mov   dx,OFFSET dt2e                  ;nur datei 2 zu ende
        jmp   SHORT l1600
l1602:  mov   dx,OFFSET dte                   ;beide dateien zu ende
l1600:  mov   cx,dtlen                        ;länge der meldung
        mov   bx,stdout                       ;auf standart output device
        mov   ah,40H                          ;write a file
        dos
        mov   bx,dclow                        ;zähler der untersch. bytes
        mov   dx,dchigh
        mov   bp,OFFSET diffn
        call  dwordd                          ;ausgeben
        mov   dx,OFFSET diffs                 ;ds:dx auf meldung
        mov   cx,difflen                      ;die länge der meldung
        mov   bx,stdout                       ;auf standart output device
        mov   ah,40H                          ;write a file
        dos
        ret
summary ENDP

; Hauptprogramm
; ARGS: ES auf PSH Segment
; RETS: -
;-----------------------------------------------------------------0000
main    PROC FAR
        mov   ds,data_seg                     ;ds auf data segement
        mov   psh_seg,es                      ;psh segment merken
        call  setmem                          ;speicher belegung
        mov   es,data_seg                     ;auch auf data segment
        call  cmdline                         ;kommandozeile auswerten
        call  compare                         ;dateien vergleichne
        jc    l0001                           ;falls dateien nicht gleich
        xor   al,al                           ;return code 0, dateien gleich
        test  sws,n_switch                    ;auch bei gleichheit meldung ?
        jz    l0000                           ;  nein
        call  summary                         ;  ja
        jmp   SHORT l0000
l0001:  mov   al,01                           ;return code 1, dateien unglich
        call  summary
l0000:  mov   ah,4CH                          ;terminate program
        dos
        jmp   l0000
main    ENDP

code    ENDS

; Stack Bereich, wird bei Initialisierung verschoben
;=====================================================================
stack   SEGMENT WORD STACK 'stack'
        DB 128 DUP (?)
stack   ENDS

        END main
