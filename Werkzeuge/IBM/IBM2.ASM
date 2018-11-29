        PAGE 80,132
        .SALL
;=====================================================================
; MS-Macro-Assembler V1.10 / Wang PC
; (c) Ulrich Berntien .06.1991
;     letzte Änderung .06.1991
;=====================================================================
; Emulation einiger IBM-BIOS Funktionen
;
; BIOS Beschreibungen in
;    MC Juni 1986        (Übersicht)
;    MC Feb. 1988        (Übersicht)
;    MC Dez. 1989        (Maus 33H)
;=====================================================================
; linken mit IBM1.ASM, IBM3.ASM
;=====================================================================

INCLUDE ibmi.asm

fpuflag EQU 2                     ;FPU flag im system word

crrs EQU 00001010B                ;Attribute für Cursor symbol

specialkey = 1FH

;=====================================================================
resident SEGMENT WORD PUBLIC
ASSUME ds : resident, cs : resident

;= D A T E N =========================================================

status  DD ?                      ;ADS des Statusbytes der Grafikkarte
outport DW ?                      ;Portadresse der Grafikkarte

sysword DW 0100001011110101B      ;System Configuration
        ;  5432109876543210

memkb   DW ?                      ;Speicherbestückung in KB

saveds  DW ?                      ;zum zwischenspeichern
savebx  DW ?

retads  DD ?                      ;Rücksprung adresse bim Int 16H speichern

kbd     DW 0                      ;zeichen in keyboard buffer

timerQID DW 0                     ;QID des Timer Event

crrspos  DW 0                     ;aktuelle Curpsorposition
crrsold  DW 0                     ;alte Cursorposition
crrsline DB 0                     ;aktuelle Cursorkoordinaten
crrsrow  DB 0                     ;  line/row reihenfolge nicht ändern

crrsakt  DB false                 ;cursor aktuell

timeron  DB false                 ;true => timer event ist eingeschaltet

startcheck EQU THIS BYTE          ;ab hier Vergleich für check

;= Konstanten ========================================================

scrinit DB escape,'[2J',escape,'[5h$'

scancodes EQU THIS BYTE
        DB 000H,01EH,030H,02EH,020H,012H,021H,022H   ;00-07H
        DB 00EH,00FH,024H,025H,026H,01CH,031H,018H   ;08-0FH
        DB 019H,010H,013H,01FH,014H,016H,02FH,011H   ;10-17H
        DB 02DH,02DH,02CH,01AH,000H,000H,000H,000H   ;18-1FH

        DW 039H,002H,02BH,004H,005H,006H,008H,028H   ;20-27H
        DW 00AH,00BH,009H,04EH,033H,04AH,034H,035H   ;28-2FH
        DW 00BH,002H,003H,004H,005H,006H,007H,008H   ;30-37H
        DW 009H,00AH,027H,027H,33DH,00DH,034H,035H   ;38-3FH

        DB 003H,01EH,030H,02EH,020H,012H,021H,022H   ;40-47H
        DB 023H,017H,024H,025H,026H,032H,031H,018H   ;48-4FH
        DB 019H,010H,013H,01FH,014H,016H,02FH,011H   ;50-57H
        DB 02DH,02DH,02CH,01AH,02BH,01BH,007H,00CH   ;58-5FH

        DB 029H,01EH,030H,02EH,020H,012H,021H,022H   ;60-67H
        DB 023H,017H,024H,025H,026H,032H,031H,018H   ;68-6FH
        DB 019H,010H,013H,01FH,014H,016H,02FH,011H   ;60-67H
        DB 02DH,02DH,02CH,01AH,02BH,01BH,029H,00EH   ;78-7FH

;= Sprungtabellen ====================================================

        EVEN
int10H_table EQU THIS BYTE
        DB 0FH,00H              ;bis unterstützte funktionen
        DW int10f00             ;00
        DW noaction             ;01
        DW int10f02             ;02
        DW int10f03             ;03
        DW int10f04             ;04
        DW noaction             ;05
        DW noaction             ;06
        DW noaction             ;07
        DW int10f08             ;08
        DW int10f09             ;09
        DW int10f09             ;0A
        DW noaction             ;0B
        DW noaction             ;0C
        DW int10f0D             ;0D
        DW int10f0E             ;0E
        DW int10f0F             ;0F

int16H_table EQU THIS BYTE
        DB 02H,00H              ;bis unterstützte funktionen
        DW int16f00             ;00
        DW int16f01             ;01
        DW int16f02             ;02

;= C O D E ===========================================================

; Hierhin den Timer-Event alle 60 ms legen von Wang BIOS aus
;-------------------------------------------------------------------19
timerevent PROC FAR
        int   1CH
        ret
timerevent ENDP

; Wählt Bildschirmspeicher an
; ARGS: DS auf resident
; RETS: ES auf den Bildschirmspeicher
; REGS: nur DX,SI,ES verändert
;-------------------------------------------------------------------01
selectscreen PROC NEAR
        push  ax
        mov   dx,outport                      ;port zur monitorkarte
        les   si,status
        mov   al,es:[si]                      ;status der karte lesen
        and   al,0CH
        or    al,01H
        mov   si,0F000H
        mov   es,si                           ;segment des frame buffers
        out   dx,al                           ;signal an karte senden
        pop   ax
        ret
selectscreen ENDP

; Wandelt Bildschirmkoordinate in Bildschirmposition
; ARGS: DH Zeile, DL Spalte
; RETS: BX die Bildschirmposition
; REGS: bis auf DX alle erhalten
;-------------------------------------------------------------------01
xy2pos PROC NEAR
        mov   bx,184EH                        ;bl := 79, bh := 24
        cmp   dl,bl
        jb    l0100
        mov   dl,bl                           ;maximal spalte 79
l0100:  cmp   dh,bh
        jb    l0101
        mov   dh,bh                           ;maximal zeile 24

l0101:  xor   bh,bh
        mov   bl,dh                           ;bx := zeile
        sal   bx,1
        sal   bx,1
        add   bl,dh                           ;bx := zeile *5 (carry unmöglich)
        sal   bx,1
        sal   bx,1
        sal   bx,1
        sal   bx,1                            ;bx := zeile * 80
        xor   dh,dh
        add   bx,dx                           ;bx := zeile * 80 + spalte
        sal   bx,1                            ;bx := bildschirmposition
        ret
xy2pos ENDP

; Setzt Cursor auf neue Position löscht auf alter Position
; ARGS: DS auf resident
; RETS: -
; REGS: bis auf BX alle erhalten
;-------------------------------------------------------------------02
setcursor PROC NEAR
        pushing <ax,dx,si,es>
        mov   bx,crrsold                      ;dort crrs löschen
        call  selectscreen
        mov   ax,es:[bx]
        xor   al,al                           ;attribut := 0
        mov   es:[bx],ax                      ;crrs löschen
        mov   bx,crrspos
        mov   crrsold,bx                      ;crrs aktualisiern
        call  selectscreen
        mov   ax,es:[bx]
        mov   al,crrs                         ;attribut := cursorsymbol
        mov   es:[bx],ax                      ;crrs anzeigen
        mov   crrsakt,true                    ;aktualisiert
        poping <es,si,dx,ax>
        ret
setcursor ENDP

; Bewegt Cursorposition ein Zeichen weiter
; nicht auf dem Bildschirm aktualisiert
; ARGS: DS auf resident
; RETS: -
; REGS: alle erhalten
;-------------------------------------------------------------------03
movecursor PROC NEAR
        pushing <ax,bx>
        mov   ax,WORD PTR crrsline
        mov   bx,crrspos
        cmp   ah,79
        jb    l0300                           ;weiter in dieser zeile
        cmp   al,24
        jb    l0301                           ;weiter auf diesem schirm
        xor   ax,ax
        xor   bx,bx                           ;wieder oben anfangen
        jmp   SHORT l0302

l0301:  xor   ah,ah                           ;spalte := 0
        inc   al                              ;nächste zeile
        jmp   SHORT l0303

l0300:  inc   ah                              ;nächste spalte
l0303:  add   bx,2                            ;nächste position
l0302:  mov   WORD PTR crrsline,ax
        mov   crrspos,bx
        poping <bx,ax>
        ret
movecursor ENDP

; Schreibt ein Zeichen auf den Bildschirm
; ARGS: AL das Zeichen
;       BX die Position
;       DS auf resident
; RETS: -
; REGS: alle erhalten
;-------------------------------------------------------------------04
printchr PROC NEAR
        pushing <ax,dx,si,es>
        mov   ah,al                           ;zeichen ins high byte
        xor   al,al                           ;attribut := 0
        call  selectscreen
        mov   es:[bx],ax                      ;zeichen ausgeben
        poping <es,si,dx,ax>
        ret
printchr ENDP

; Liest ein Zeichen vom Bildschirm
; ARGS: BX die Position
;       DS auf resident
; RETS: AL das Zeichen, AH := 0
; REGS: alle anderen erhalten
;-------------------------------------------------------------------05
readchr PROC NEAR
        pushing <dx,si,es>
        call  selectscreen
        mov   ax,es:[bx]                      ;zeichen lesen
        mov   al,ah                           ;der zeichencode
        xor   ah,ah                           ;attribut := 0
        poping <es,si,dx>
        ret
readchr ENDP

; Verzweigt laut Angabe im AH Register
; ARGS: AH Verzweigungswert
;       BX mit Offset der Sprungtabelle
;       DS auf resident
; RETS: mit RET zurück wenn AX nicht in der Tabelle
;       sonst mit JMP NEAR zum gegeben Ziel
; REGS: bis auf BX,DS alle erhalten
;-------------------------------------------------------------------06
switch  PROC NEAR
        cmp   ah,[bx]
        ja    l0600                           ;ah oberhalb der tabelle
        add   bx,2
        add   bl,ah
        adc   bh,0                            ;ggf. Übertrag
        add   bl,ah
        adc   bh,0                            ;bx := tabelle[0] + ah*2
        jmp   [bx]                            ;verzweigen

l0600:  ret
switch  ENDP

; Keine Aktion
; REGS: alle erhalten
;-------------------------------------------------------------------20
noaction PROC NEAR
        ret
noaction ENDP

; int 10H, Funktion 00H
; Bildschirmlöschen
; ARGS: DS auf resident
; RETS: -
; REGS: alle erhalten
;-------------------------------------------------------------------21
int10f00 PROC NEAR
        pushing <ax,dx>
        xor   ax,ax
        mov   crrspos,ax                      ;cursor auf 0
        mov   crrsold,ax
        mov   WORD PTR crrsline,ax
        lea   dx,scrinit
        mov   ah,09H                          ;print a string
        int   21H
        poping <dx,ax>
        ret
int10f00 ENDP

; int 10H, Funktion 02H
; Cursor positionieren
; ARGS: DH = zeile, DL = Spalte
;       DS auf resident
; RETS: -
; REGS: bis auf BX alle erhalten
;-------------------------------------------------------------------22
int10f02 PROC NEAR
        push  dx
        mov   crrsline,dh
        mov   crrsrow,dl
        call  xy2pos
        mov   crrspos,bx
        pop   dx
        ret
int10f02 ENDP

; int 10H, Funktion 03H
; Cursorposition lesen
; ARGS: DH = zeile, DL = Spalte
;       DS auf resident
; RETS: CX := 11H
;       DX := Cursor Koordianten
; REGS: alle andern erhalten
;-------------------------------------------------------------------23
int10f03 PROC NEAR
        mov   dh,crrsline
        mov   dl,crrsrow
        xor   cx,cx
        ret
int10f03 ENDP

; int 10H, Funktion 04H
; Lichtgriffelposition ermitteln
; ARGS: -
; RETS: AH = 0
; REGS: alle anderen erhalten
;-------------------------------------------------------------------24
int10f04 PROC NEAR
        xor   ah,ah
        ret
int10f04 ENDP

; int 10H, Funktion 08H
; Zeichen mit Attribut von Cursor Position lesen
; ARGS: -
; RETS: AL = Zeichen, AH = Attribut
; REGS: alle außer BX erhalten
;-------------------------------------------------------------------25
int10f08 PROC NEAR
        mov   bx,crrspos
        jmp   readchr
int10f08 ENDP

; int 10H, Funktion 09H und 0AH
; Zeichen mit Attribut an Cursor Position ausgeben
; ARGS: AL = Zeichen, AH = Attribut
; RETS: -
; REGS: alle außer BX erhalten
;-------------------------------------------------------------------26
int10f09 PROC NEAR
        mov   bx,crrspos
        jmp   printchr
int10f09 ENDP

; int 10H, Funktion 0DH
; Grafikpunkt lesen
; ARGS: -
; RETS: AL = 0
; REGS: alle anderen erhalten
;-------------------------------------------------------------------27
int10f0D PROC NEAR
        xor   al,al
        ret
int10f0D ENDP

; int 10H, Funktion 0EH
; Zeichen an Cursor Position ausgeben und Cursor weiterbewegen
; ARGS: AL = Zeichen
; RETS: -
; REGS: alle außer BX erhalten
;-------------------------------------------------------------------28
int10f0E PROC NEAR
        mov   bx,crrspos
        call  printchr
        jmp   movecursor
int10f0E ENDP

; int 10H, Funktion 0FH
; Bildschirmmodus ermitteln
; ARGS: -
; RETS: AL = Bildschirmmodus 30H ????
;       AH = Zeichen pro Zeile 80
;       savebx.high = 0, Bildschirmseite
; REGS: alle erhalten
;-------------------------------------------------------------------29
int10f0F PROC NEAR
        mov   ax,5030H;
        mov   savebx,0000H
        ret
int10f0F ENDP

; Liste Funktionstaste
; ARGS: - (zuvor "spcialkey" von der Tastatur gelesen)
; RETS: AX mit Tastencode
; REGS: alle erhalten
;-------------------------------------------------------------------33
readfkt PROC NEAR
        mov   ah,07H
        int   21H                             ;direct console input
        mov   ah,al
        xor   al,al                           ;ascii := 0
        ret
readfkt ENDP

; int 16H, Funktion 00H
; Auf Tastendruck warten und Zeichen holen
; ARGS: DS auf resident
; RETS: AL = ASCII Wert,  AH = Scan-Code
; REGS: alle erhalten
;-------------------------------------------------------------------30
int16f00 PROC NEAR
        mov   ax,kbd
        or    ax,ax                           ;etwas im buffer ?
        jz    l3000
        mov   kbd,0
        jmp   SHORT l3001
l3000:  mov   ah,07H                          ;direct console input
        int   21H
        cmp   al,specialkey                   ;funktionstaste ?
        jne   l3002
        call  readfkt
        jmp   SHORT l3001
l3002:  lea   bx,[scancodes]                  ;nullpunkt der scann-code-tabelle
        add   bl,al
        adc   bh,0
        mov   ah,[bx]                         ;scann-code lesen
l3001:  ret
int16f00 ENDP

; int 16H, Funktion 01H
; Prüfen ob Taste gedrückt
; ARGS: DS auf resident
; RETS: AL = ASCII Wert,  AH = Scan-Code
;       ZERO <=> keine Taste gedrückt
; REGS: alle erhalten
;-------------------------------------------------------------------31
int16f01 PROC NEAR
        push  dx
        mov   ax,kbd
        or    ax,ax                           ;etwas im buffer ?
        jnz   l3100

        mov   ah,06H                          ;direct console i/o
        mov   dl,0FFH                         ;input
        int   21H
        cmp   al,specialkey                   ;funktionstaste ?
        jne   l3101
        call  readfkt
        jmp   SHORT l3103

l3101:  or    al,al                           ;kein zeichen bereit ?
        jz    l3100

        lea   bx,[scancodes]                  ;nullpunkt der scann-code-tabelle
        add   bl,al
        adc   bh,0
        mov   ah,[bx]                         ;scann-code lesen

l3103:  mov   kbd,ax                          ;zeichen merken
        or    ax,ax
l3100:  pop   dx
        ret
int16f01 ENDP

; int 16H, Funktion 02H
; Sondertasten abfragen (Shift,Control,usw.)
; ARGS: -
; RETS: AL = 0
; REGS: alle erhalten
;-------------------------------------------------------------------32
int16f02 PROC NEAR
        xor   al,al
        ret
int16f02 ENDP

;= Interrupt Handler =================================================

; Emuliert IBM-BIOS : 10H, Bildschirmabfrage
;-------------------------------------------------------------------07
myint10H PROC FAR
        cli
        mov   cs:saveds,ds                    ;ds,bx sichern
        mov   cs:savebx,bx
        mov   bx,cs
        mov   ds,bx                           ;ds auf resiendet
        mov   crrsakt,false                   ;crrs ggf. nicht mehr aktuell
        lea   bx,int10H_table
        call  switch                          ;gemäß ah verzweigen
        mov   bx,savebx                       ;ds,bx wieder zurück
        mov   ds,saveds
        iret
myint10H ENDP

; Emuliert IBM-BIOS : 11H, Hardwaretest
;-------------------------------------------------------------------08
myint11H PROC FAR
        cli
        mov   ax,cs:sysword
        iret
myint11H ENDP

; Emuliert IBM-BIOS : 12H, Speicherabfrage
;-------------------------------------------------------------------09
myint12H PROC FAR
        cli
        mov   ax,cs:memkb
        iret
myint12H ENDP

; Emuliert IBM-BIOS : 16H, Tastaturabfrage
;-------------------------------------------------------------------10
myint16H PROC FAR
        cli
        mov   cs:saveds,ds                    ;ds,bx sichern
        mov   cs:savebx,bx
        mov   bx,cs
        mov   ds,bx                           ;ds auf resiendet
        cmp   crrsakt,true
        je    l1000
        call  setcursor                       ;cursor positionieren
l1000:  lea   bx,int16H_table
        call  switch                          ;gemäß ah verzweigen
        pop   WORD PTR [retads]               ;rücksprung ads vom stack
        pop   WORD PTR [retads+02]
        pop   bx                              ;falgs vom stack entfernen
        mov   bx,savebx                       ;ds,bx wieder zurück
        mov   ds,saveds
        jmp   cs:[retads]                     ;simulierter iret
myint16H ENDP

; Emuliert IBM-BIOS : 1CH, Timerinterrupt Rücksprung für Daisy Chain
;-------------------------------------------------------------------11
myint1CH PROC FAR
        iret
myint1CH ENDP

; Emuliert IBM-BIOS : 33H, Maus
;-------------------------------------------------------------------12
myint33H PROC FAR
        cli
        xor   ax,ax
        iret
myint33H ENDP

countcheck EQU ($ - startcheck)/2

resident ENDS

inteintrag MACRO num
          DB num
          DW OFFSET resident:myint&num
        ENDM

;=====================================================================
data    SEGMENT WORD PUBLIC 'data'

EXTRN installflag : BYTE
EXTRN usefpu : BYTE
EXTRN usetimer : BYTE

sysblk  DD ?                                  ;ADS des system inform. blocks

int_table EQU THIS BYTE                       ;Tabelle aller neuer int.
        inteintrag 10H
        inteintrag 11H
        inteintrag 12H
        inteintrag 16H
        inteintrag 1CH
        inteintrag 33H
        DB 00H                                ;Ende der Tabelle

msg0    DB 'Neue Installation',cr,lf
msg0len EQU $ - msg0
msg1    DB 'Bereits Installiert',cr,lf
msg1len EQU $ - msg1

data    ENDS

;=====================================================================
code    SEGMENT WORD PUBLIC 'code'
ASSUME  ds : data, cs : code, es : resident

EXTRN doserr : NEAR
EXTRN bioserr: NEAR
EXTRN stdout : NEAR

; Überprüft ab bereits Installiert ist
; ARGS: ES auf resident
; RETS: CARRY <=> schon installiert
;       ggf. ES auf installiertes Segemt
; REGS: alle anderern unverändert
;-------------------------------------------------------------------13
check   PROC NEAR
        pushing <ax,bx,cx,ds>
        mov   al,int_table                    ;eine interrupt nummer
        mov   bx,es
        mov   ds,bx                           ;ds auf resident
        mov   ah,35H                          ;get int.vector
        dos

        lea   bx,startcheck                   ;dort vergleich beginnen
        mov   cx,countcheck                   ;anzahl zu vergleichen words

l1300:  mov   ax,[bx]
        cmp   ax,es:[bx]
        jne   l1301                           ;nicht gleich
        inc   bx
        inc   bx
        loop  l1300                           ;bis alle vergleichen
        stc                                   ;schon installiert
        jmp   SHORT l1302

l1301:  mov   ax,SEG resident                 ;noch nicht installiert
        mov   es,ax                           ;neues resident segment
        clc

l1302:  poping <ds,cx,bx,ax>
        ret
check   ENDP

; Setzt die Interrupts
; ARGS: DS auf data
;       ES auf resident
; RETS: -
; REGS: alle erhalten
;-------------------------------------------------------------------14
initint PROC NEAR
        pushing <ax,bx,dx,ds,es>
        mov   ax,ds
        mov   bx,es
        mov   ds,bx                           ;ds auf resident
        mov   es,ax                           ;es auf data

        lea   bx,int_table                    ;auf tabellen anfang
        jmp   SHORT l1401

l1400:  inc   bx
        mov   dx,es:[bx]                      ;adresse lesen
        add   bx,2                            ;auf nächsten eintrag
        mov   ah,25H                          ;set interrupt
        dos                                   ;ineterrupt auf DS:DX setzen
l1401:  mov   al,es:[bx]                      ;interrupt nummer
        or    al,al
        jnz   l1400                           ;00H bendet die tabelle

        poping <es,ds,dx,bx,ax>
        ret
initint ENDP

; Initialisiert den Timer Event, gemäß Angaben in "timeron","usetimer"
; ARGS: ES auf resident
;       DS auf data
; RETS: -
; REGS: alle erhalten
;-------------------------------------------------------------------18
timersetting PROC NEAR
        pushing <ax>
        mov   ah,timeron
        cmp   ah,usetimer
        je    l1800                           ;keine änderung nötig
        cmp   ah,true
        je    l1801                           ;timer also ausschalten

        pushing <bx,cx,dx,ds>
        mov   ax,es
        mov   ds,ax
        lea   dx,timerevent                   ;ds:dx auf "timerevent"
        xor   bx,bx                           ;event index 0 = 10ms timer
        mov   cx,6                            ;alle 60ms aufrufen
        mov   al,2                            ;set event trap
        bios
        mov   timerQID,bx                     ;die queue identification sichern
        mov   timeron,true
        poping <ds,dx,cx,bx>
        jmp   SHORT l1800                     ;fertig

l1801:  pushing <bx>
        mov   bx,timerQID
        mov   al,3                            ;clear event trap
        bios
        mov   timeron,false
        poping <bx>

l1800:  poping <ax>
        ret
timersetting ENDP

; Initialisiert Werte "sysword","memkb", und auch "sysblk"
; ARGS: ES auf resident
;       DS auf data
; RETS: -
; REGS: alle erhalten
;-------------------------------------------------------------------17
sysinit PROC NEAR
        pushing <ax,bx,cx,ds,es>
        mov   ax,fpuflag                      ;position fpu flag im sysword
        cmp   usefpu,true
        je    l1700
        not   ax
        and   sysword,ax                      ;fpu flag löschen
        jmp   SHORT l1701
l1700:  or    sysword,ax                      ;fpu flag setzen

l1701:  mov   al,1                            ;get system config table
        bios
        mov   WORD PTR sysblk,bx              ;sysblk auf die table richten
        mov   WORD PTR sysblk+2,es
        mov   ax,es:[bx+0002H]                ;size of memory in paragraphs
        mov   cl,6
        shr   ax,cl                           ;ax := ax DIV 64
      pop   es
        mov   memkb,ax                        ;speicher größe in KB
        poping <ds,cx,bx,ax>
        ret
sysinit ENDP

; Initialisiert die Daten "status","outport"
; erwartet, das "sysblk" bereits initialisiert ist
; ARGS: ES auf resident
;       DS auf data
; RETS: -
; REGS: alle erhalten
;-------------------------------------------------------------------16
grafikinit PROC NEAR
        pushing <ax,bx,ds>
        lds   bx,sysblk                       ;ds:bx auf system confi. table
        mov   bx,[bx+0AH]                     ;adr des sib
        mov   ah,[bx+13H]                     ;high byte des ports
        mov   al,10H                          ;low byte des ports
        mov   outport,ax                      ;port numer speichern
        add   bx,8                            ;bx auf status byte
        mov   WORD PTR status,bx              ;die adr speichern
        mov   WORD PTR status+2,ds            ;das segment speichern
        poping <ds,bx,ax>
        ret
grafikinit ENDP

; Setzt Werte für den Residenten Teil
; ARGS: ES auf resident
;       DS auf data
; RETS: -
; REGS: alle erhalten
;-------------------------------------------------------------------15
setup PROC NEAR
        call  sysinit
        call  grafikinit
        call  timersetting
        ret
setup ENDP

PUBLIC install

; Setzen der Daten für den Residenten Teil
; ggf. Installieren der Interrupts
; ARGS: -
; RETS: -
; REGS: alle erhalten
;-------------------------------------------------------------------00
install PROC NEAR
        pushing <ax,ds,es>
        mov   ax,SEG data
        mov   ds,ax                           ;ds auf data
        mov   ax,SEG resident
        mov   es,ax                           ;es auf resident
        call  check
        jc    l0001                           ;bereits installiert

        lea   dx,msg0                         ;meldung machen
        mov   cx,msg0len
        call  stdout
        mov   installflag,true                ;muß installiert werden
        call  initint                         ;interrupts setzen
        jmp   SHORT l0000

l0001:  mov   installflag,false               ;nicht nochmal installieren
        lea   dx,msg1                         ;meldung machen
        mov   cx,msg1len
        call  stdout

l0000:  call  setup                           ;werte im residenten teil setzen
        poping <es,ds,ax>
        ret
install ENDP

code    ENDS
        END
