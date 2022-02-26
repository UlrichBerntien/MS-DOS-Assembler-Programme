;---------------------------------------------------------------------
; Vergrößeren eines Zeichensatztes
; MS-Macro-Assembler V1.10 / Wang PC
; (c) Ulrich Berntien .12.1990
;     letzte Änderung .12.1990
;---------------------------------------------------------------------

space = 32                                    ;assii zeichen
tab = 09
cr = 0DH
lf = 0AH
dotchr = '#'
nodotchr = space
atchr = '@'
stdout = 1                                    ;ausgabe gerät
stdin = 0                                     ;eingabe gerät

;=====================================================================
data    SEGMENT WORD 'DATA'

buffersize = 1024                             ;größe des ausgabe buffers
optr    DW 0                                  ;auf letztes zeichen im buffer
obuffer DB buffersize DUP (?)                 ;ausgabe buffer
ispalte DW 0
ispaces DW 0
iptr    DW 0                                  ;auf letztes ausgegbene zeichen
iend    DW 0                                  ;auf letztes gültige zeichen
ibuffer DB buffersize DUP (?)                 ;eingabe buffer

zeilen  DW ?
spalten DW ?

zeile   DB 255 DUP (?)

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

; Ausgabe einer Zeile in den Buffer, wird mit cr,lf abgeschlossen
; ARGS : SI adr der Zeilen
;        CX Länge der Zeilen
; RETS : -
; REGS : BP,Segmente erhalten
;-----------------------------------------------------------------0600
writeline PROC NEAR
        mov   di,optr                         ;di zeiger im buffer
l0601:  cmp   di,buffersize                   ;ist buffer voll ?
        jl    l0600                           ;nein
        mov   optr,di
        push  cx
        call  writebuffer                     ;buffer wegschreiben
        pop   cx
        xor   di,di                           ;auf das nullte zeichen
l0600:  mov   al,[si]
        mov   [di+obuffer],al                 ;zeichen übertragen
        inc   di                              ;auf nächstes zeichen
        inc   si
        loop  l0601                           ;schleife über alle zeichen
        mov   optr,di                         ;neue länge speichern
        call  endline                         ;zeilenendmaker ausgeben
        ret
writeline ENDP

; schreibt das Word aus AX in den Buffer in ASCII Format
; ARGS: AX die auszugebende Zahl
; RETS: -
; REGS: BP,Segment erhalten
;-----------------------------------------------------------------0800
writeint PROC NEAR
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
writeint ENDP

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

; Eine Zeile auslesen mit Verdoppelung in den Buffer DS:DI
; ARGS : CX mindest Anzahl der Zeichen
;        es wird mit Spaces aufgefüllt
;        DI Adresse des Zeilenbuffers
; RETS : -
; REGS : BP,Segmente erhalten
;-----------------------------------------------------------------0300
readline PROC NEAR
l0300:  call  outbuffer                       ;zeichen einlesen
        cmp   al,cr                           ;zeilenende ?
        je    l0301                           ; ja
        mov   ah,al                           ;zeichen verdoppeln
        mov   [di],ax                         ;zwei zeichen speichern
        inc   di                              ;zeiger weiterschieben
        inc   di
        loop  l0300                           ;bis grenze erreicht
l0304:  call  outbuffer
        cmp   al,cr
        jne   l0304
l0301:  jcxz  l0302
        mov   ax,space*10H+space              ;mit leerzeichen füllen
l0303:  mov   [di],ax                         ;zwei zeichen speichern
        inc   di                              ;zeiger weiterschieben
        inc   di
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

; ein Zeichen quadrieren
; ARGS : -
; RETS : -
; REGS : BP,Segmente erhalten
;-----------------------------------------------------------------0A00
quad    PROC NEAR
        push  bp                              ;reg sichern
        jmp   SHORT l0A02                     ;kopfzeile übertragen
l0A00:  call  inbuffer
l0A02:  call  outbuffer
        cmp   al,cr                           ;bis zeilenende
        jne   l0A00
        call  endline                         ;zeile abschließen
        mov   bp,zeilen                       ;anzahl der zeilen
l0A01:  mov   cx,spalten
        mov   di,OFFSET zeile
        call  readline                        ;zeile doppelt lesen
        mov   cx,spalten
        sal   cx,1
        mov   si,OFFSET zeile                 ;einmal schreiben
        call  writeline
        mov   cx,spalten
        sal   cx,1
        mov   si,OFFSET zeile                 ;zweitemal schreiben
        call  writeline
        dec   bp                              ;bis alle zeilen geschrieben
        jnz   l0A01
        pop   bp                              ;register zurückholen
        ret
quad    ENDP

; Hauptprogramm
;-----------------------------------------------------------------0500
main    PROC FAR
        mov   ax,SEG data
        mov   ds,ax                           ;daten segment setzten
        call  outbuffer
        call  inbuffer
        call  readint
        mov   zeilen,ax
        sal   ax,1                            ;zeilen verdoppeln
        call  writeint
        mov   al,','
        call  inbuffer
        call  readint
        mov   spalten,ax
        sal   ax,1                            ;spalten verdoppeln
        call  writeint
        call  endline
        cmp   spalten,127                     ;falls zeilen zu lang
        jg    l0501
        mov   bp,128-space
l0502:  call  quad
        dec   bp
        jnz   l0502
l0501:  call  writebuffer
l0500:  mov   ax,4C00H                        ;programm beenden
        int   21H                             ;dos call
        jmp   l0500
main    ENDP

code    ENDS

;=====================================================================
stack   SEGMENT WORD STACK
        DW 512 DUP (?)
stack   ENDS

        END main
