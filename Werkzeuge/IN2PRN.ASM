;---------------------------------------------------------------------
; Zeichensatz auf den Drucker Ausgeben
; MS-Macro-Assembler V1.10 / Wang PC
; (c) Ulrich Berntien .12.1990
;     letzte Änderung .12.1990
;---------------------------------------------------------------------

space = 20H                                   ;assii zeichen
tab = 09
cr = 0DH
lf = 0AH
esc = 1BH
dotchr = '#'
nodotchr = space
atchr = '@'
stdout = 1                                    ;ausgabe gerät
stdin = 0                                     ;eingabe gerät
dpl = 640                                     ;dots per line
lineoff = dpl+7                               ;dpl mit bytes für steuerung

;=====================================================================
data    SEGMENT WORD 'DATA'

buffersize = 1024                             ;größe des ausgabe buffers
ispalte DW 0
ispaces DW 0
iptr    DW 0                                  ;auf letztes ausgegbene zeichen
iend    DW 0                                  ;auf letztes gültige zeichen
ibuffer DB buffersize DUP (?)                 ;eingabe buffer

zeilen  DW ?                                  ;größe eines zeichens
spalten DW ?

pzeilen DW ?                                  ;grafik-zeilen für Drucker
pptr    DW ?                                  ;aktuelle Spalte

image   DB 160*192 DUP (?)                    ;buffer für ein zeichen

ppi     DB esc,'3',24                         ;zeilenvorschub einstellen
ppl     DW 5
        DB esc,'*',4,dpl MOD 100H,dpl/100H    ;grafikmode einstellen
ppe     DW 2
        DB cr,lf                              ;zeilenende

data    ENDS

;=====================================================================
code    SEGMENT WORD 'CODE'

ASSUME cs : code, ds : data, es : parea, ss : stack

; Schreibt auf Standart-Ausgabe
; ARGS : DS:DX auf den Buffer
;        CX    Anzahl der Bytes
; RETS : -
; REGS : DI,SI,Segmente erhalten
;-----------------------------------------------------------------0100
print   PROC NEAR
        mov   bx,stdout                       ;in standart ausgabe
        mov   ah,40H                          ;write file or device
        int   21H                             ;dos-call
        ret
print   ENDP

; Schreibt Daten zum Drucker über Standartausgabe
; ARGS : -
; RETS : -
; REGS : BP,Segmente erhalten
;-----------------------------------------------------------------0000
toprinter PROC NEAR
        cmp   pptr,5                          ;keine daten da ?
        jle   l0000                           ;  ja,nichts zu tun
        mov   cx,pzeilen                      ;soviele zeilen ausgeben
        mov   ax,lineoff                      ;soviele bytes pro zeile
        xor   dx,dx                           ;(dx,ax) := ax
        mul   cx                              ;gesamtzahl der bytes
        mov   cx,ax                           ;in cx speichern
        mov   di,ds                           ;datensegmant sichern
        mov   ax,es
        mov   ds,ax                           ;ds auf pare
        xor   dx,dx                           ;ds:dx auf die druckerdaten
        call  print                           ;ausgeben
        mov   ds,di                           ;datensgement zurück
        mov   pptr,5                          ;buffer wieder leer
l0000:  ret
toprinter ENDP

; Kopiert Zeichen
; ARGS : ES:SI auf Word mit Länge gefolgt von den Bytes
;        DS:DI dorthin
; RETS : DI hinter die Kopie
; REGS : alle außer AX,CX,DI,SI erhalten
;-----------------------------------------------------------------0600
copy    PROC NEAR
        mov   cx,es:[si]                      ;anzahl der bytes
        add   si,2                            ;zeiger auf die bytes
l0600:  mov   al,es:[si]
        mov   [di],al                         ;ein byte copieren
        inc   di                              ;die zeiger weiter
        inc   si
        loop  l0600                           ;schleife über alle bytes
        ret
copy    ENDP

; Buffer und Printer vorbereiten
; ARGS : -
; RETS : -
; REGS : BP,Segment erhalten
;-----------------------------------------------------------------0700
pinit   PROC NEAR
        mov   dx,OFFSET ppi                   ;den drucker einstellen
        mov   cx,3                            ;drei zeichen langer code
        call  print                           ;ausgeben
        mov   ax,ds
        mov   bx,es
        mov   ds,bx
        mov   es,ax                           ;ds <-> es tauschen
  ASSUME ds : parea, es : data
        xor   di,di                           ;mit di den buffer adressieren
        mov   bx,es:pzeilen
l0701:  mov   si,OFFSET ppl
        call  copy                            ;drucker code eincopiern
        mov   cx,dpl
        xor   al,al
l0700:  mov   [di],al                         ;alles löschen
        inc   di
        loop  l0700
        mov   si,OFFSET ppe
        call  copy                            ;zeilenende eincopier
        dec   bx
        jnz   l0701
        mov   ax,ds
        mov   bx,es
        mov   ds,bx
        mov   es,ax                           ;ds <-> es tauschen
  ASSUME ds : data, es : parea
        mov   pptr,5                          ;zeiger aus anfang
        ret
pinit   ENDP

; liest in den Eingabebuffer
; setzt nicht iptr !!!
; ARGS : -
; RETS : -
; REGS : BP,DI,Segment erhalten
;-----------------------------------------------------------------0400
readbuffer PROC NEAR
        mov   cx,buffersize                   ;anzahl der bytes
        mov   dx,OFFSET ibuffer               ;ds:dx auf den buffer
        mov   bx,stdin                        ;input device
        mov   ah,3FH                          ;read device or file
        int   21H                             ;dos call
        mov   iend,ax                         ;anzahl der gelesenen bytes
        or    ax,ax
        jz    l0400                           ;falls nichts gelesen
        ret
l0400:  mov   ax,4C01H                        ;fehler ausgang
        int   21H
        jmp   l0400
readbuffer ENDP

; ein Zeichen aus der Eingabe holen, beachtet TABS
; überließt Steuerzeichen außer CR
; ARGS : -
; RETS : AL das gelesene Zeichen
; REGS : AX,CX,BP,DI,Segmente erhalten
;-----------------------------------------------------------------0200
outbuffer PROC NEAR
        cmp   ispaces,0                       ;tab abzuarbeiten ?
        je    l0202                           ;  nein
        dec   ispaces                         ;ein leerzeichen ausgegeben
        mov   al,space                        ;space ausgeben
        jmp   l0203                           ;bearbeitung fertig
l0202:  mov   si,iptr                         ;zeiger auf eingabebuffer
l0206:  cmp   si,iend                         ;buffer abgearbeitet ?
        jl    l0200                           ;  nein
        push  cx
        push  ax
        call  readbuffer                      ;buffer neu laden
        pop   ax
        pop   cx
        xor   si,si                           ;zeiger wieder auf anfang
l0200:  mov   al,[si+ibuffer]                 ;zeichen aus buffer laden
        inc   si                              ;auf nächstes zeichen
        mov   iptr,si                         ;veränderter zeiger speichern
        cmp   al,space                        ;ein normales zeichen ?
        jge   l0203                           ;  ja
        cmp   al,tab                          ;ein tab ?
        jne   l0204                           ;  nein
        mov   ax,7                            ;tabs alle 8 zeichen
        sub   ax,ispalte                      ;aktuelle position abziehen
        and   ax,0111B                        ;anzahl mod 8
        mov   ispaces,ax                      ;anzahl der erforderlichen spaces
        mov   al,space                        ;ein leerzeichen ausgeben
        jmp   SHORT l0203                     ;fertig
l0204:  cmp   al,cr                           ;zeilenende ?
        jne   l0206                           ;  nein, nächstes zeichen
        mov   ispalte,0                       ;neue zeile anfangen
        jmp   SHORT l0201                     ;fertig
l0203:  inc   ispalte                         ;spalten mitzählen
l0201:  ret
outbuffer ENDP

; Eine Zeile auslesen in den Buffer DS:DI
; ARGS : CX mindest Anzahl der Zeichen
;        es wird mit Spaces aufgefüllt
;        DI Adresse des Zeilenbuffers
; RETS : DI auf Byte hinter der Zeile
; REGS : BP,Segmente erhalten
;-----------------------------------------------------------------0300
readline PROC NEAR
l0300:  call  outbuffer                       ;zeichen einlesen
        cmp   al,cr                           ;zeilenende ?
        je    l0301                           ; ja
        mov   [di],al                         ;zeichen speichern
        inc   di                              ;zeiger weiterschieben
        loop  l0300                           ;bis grenze erreicht
l0304:  call  outbuffer
        cmp   al,cr
        jne   l0304
l0301:  jcxz  l0302
        mov   al,space                        ;mit leerzeichen füllen
l0303:  mov   [di],al                         ;zeichen schreiben
        inc   di                              ;zeiger weiterschieben
        loop  l0303                           ;bis zeile zu ende
l0302:  ret
readline ENDP

; liest eine Integerzahl
; ARGS : -
; RETS : AX mit der Zahl
; REGS : BP,Segmente erhalten
;-----------------------------------------------------------------0900
readint PROC NEAR
        push  bp                              ;regs sichern
        mov   cx,10                           ;basis ist 10
        sub   sp,2                            ;ein word auf dem stack reserv.
        mov   bp,sp                           ;mit bp adressieren
        xor   ax,ax
        mov   [bp],ax                         ;mem := 0
l0902:  call  outbuffer                       ;ziffer einlesen
        sub   al,'0'                          ;ascii in zaiffernwert
        jl    l0901                           ;falls keine ziffer
        cmp   al,9
        jg    l0901                           ;falls keine ziffer
        xor   ah,ah                           ;ax := al
        mov   bx,ax
        mov   ax,[bp]                         ;ax := mem
        mul   cx                              ;ax := ax * 10 (dx verändert)
        add   ax,bx                           ;ax := ax * 10 + ziffernwert
        mov   [bp],ax                         ;speichern
        jmp   l0902
l0901:  mov   ax,[bp]                         ;rückgabewert
        add   sp,2                            ;lokale daten vom stack
        pop   bp
        ret                                   ;zurück
readint ENDP

; ein Zeichen ausgeben
; ARGS : -
; RETS : -
; REGS : BP,Segmente erhalten
;-----------------------------------------------------------------0A00
printchr PROC NEAR
        push  bp                              ;reg sichern
l0A00:  call  outbuffer                       ;kopfzeile überlesen
        cmp   al,cr
        jne   l0A00
        mov   bp,zeilen                       ;soviele zeilen für ein zeichen
        mov   di,OFFSET image
l0A01:  mov   cx,spalten                      ;länge der zeilen
        call  readline                        ;zeile einlesen
        dec   bp                              ;zeiln zählen
        jnz   l0A01
        mov   bp,pptr                         ;merken der adr in druckerdaten
        mov   ax,bp
        add   ax,spalten
        cmp   ax,dpl                          ;paßt das zeichen noch rein ?
        jle   l0A02                           ; ja
        call  toprinter                       ;druckerdaten weg schreiben
        mov   bp,pptr
l0A02:  mov   bx,OFFSET image                 ;in bx die bilddaten merken
        mov   cx,spalten                      ;soviel spalten in einem zeichen
l0A03:  mov   si,bx
        mov   di,bp
        mov   dx,zeilen
        mov   al,80H                          ;bit in druckerdaten
        xor   ah,ah
l0A06:  cmp   BYTE PTR [si],dotchr
        jne   l0A04
        or    ah,al
l0A04:  shr   al,1                            ;nächstes bit in druckerdaten
        jnc   l0A05                           ;ein byte voll ?
        mov   es:[di],ah                      ;byte speichern
        add   di,lineoff                      ;nächste zeilen
        mov   al,80H
        xor   ah,ah
l0A05:  add   si,spalten                      ;in nächste zeile
        dec   dx                              ;zeilen zählen
        jnz   l0A06
        mov   es:[di],ah                      ;letztes byte speichern
        inc   bx
        inc   bp
        loop  l0A03                           ;über alle spalten
        mov   pptr,bp                         ;neuer zeiger schreiben
        pop   bp                              ;register zurückholen
        ret
printchr ENDP

; Hauptprogramm
;-----------------------------------------------------------------0500
main    PROC FAR
        mov   ax,SEG data
        mov   ds,ax                           ;daten segment setzten
        mov   ax,SEG parea
        mov   es,ax
        call  outbuffer
        call  readint
        mov   zeilen,ax                       ;zeilenanzahl
        cmp   zeilen,192
        jg    l0501                           ;zu viele zeilen
        mov   cl,3
        add   ax,0111B                        ;aufrunden
        sar   ax,cl                           ;durch 8
        mov   pzeilen,ax
        call  readint
        mov   spalten,ax
        cmp   spalten,160                     ;falls zeilen zu lang
        jg    l0501
        call  pinit
        mov   bp,128-space
l0502:  call  printchr
        dec   bp
        jnz   l0502
l0501:  call  toprinter
l0500:  mov   ax,4C00H                        ;programm beenden
        int   21H                             ;dos call
        jmp   l0500
main    ENDP

code    ENDS

;=====================================================================
stack   SEGMENT WORD STACK
        DW 512 DUP (?)
stack   ENDS

;=====================================================================
parea   SEGMENT WORD
parea   ENDS

        END main
