        TITLE *** MOVE ***
        PAGE 60,132
        .SALL
;=====================================================================
; MS-Macro-Assembler V1.10 /Wang PC
; (c) Ulrich Berntien .07.1990
;   letzte Änderung 15.07.1990
;
; Bewegt mehre Dateien aus einem Pfad in einen anderern auf dem gleichen
; Gerät; oder
; eine Datei bekommt einen neuen Namen, der in einem anderen Pfad auf dem
; gleichen Gerät sein kann.
;
; Aufrufformat:
;       MOVE [-v] <QUELL-FILE-NAME> <ZIEL-PFAD/DATEI>
;
; z.B.
;       move pfad1/*.asm pfad2/
;       move pfad1/datei.alt pfad2/datei.neu
;
; Switch:
;  -v : view mode, Protokoll der einzelnen Dateien auf Standart-Ausgabe
;
; Das Programm setzt den Returncode:
;       00H => kein Fehler
;       01H => ein DOS-Fehler gefunden
;       02H => ein eigenen Fehler gefunden
;=====================================================================

stdout = 1                             ;standart ausgabe gerät
errout = 2                             ;standart gerät für fehlermeldungen
space = 20H                            ;ascii zeichen
cr = 0DH
lf = 0AH
switch = '-'                           ;zeichen für schalter kennung
true = 01                              ;logische konstanten
false = 00
ssize = 0200H                          ;größe des stacks in byte

; Daten erzeugen für Meldungen, Ausgabe über msgout
;---------------------------------------------------------------------
err     MACRO code,text
         LOCAL end,start
         DB code
         DW end - start
  start  DB text,cr,lf,00
  end    EQU THIS BYTE
        ENDM

; Datenstruktur für DOS Sub-Funktionen 4Eh und 4Fh
;---------------------------------------------------------------------
fstruc  STRUC
        DB 21 DUP (0)                         ;reserved
        DB 0                                  ;attribute found
        DW 0                                  ;time of create or last write
        DW 0                                  ;date of create or last write
        DD 0                                  ;file size
fname   DB 12 DUP (0)                         ;file name and extension
fstruc  ENDS

;=====================================================================
data    SEGMENT WORD

sn_ptr  DW ?                                  ;zeiger auf anfang des filenamen
dn_ptr  DW ?                                  ;in s_path bzw. d_path

s_path  DB 80 DUP (?)                         ;source filename with path
d_path  DB 80 DUP (?)                         ;destination filename with path

block   fstruc <>

view    DB false                              ;view switch gestetzt ?

outbuf  DB 200 DUP (?)                        ;buffer für ausgaben

fpart   DB 'moving ',00                       ;texte fürs protokoll
mpart   DB ' to ',00
lpart   DB cr,lf,00

cattable DW fpart
         DW s_path
         DW mpart
         DW d_path
         DW lpart
         DW 00

errtext DB '00 dez, DOS-ERROR: '              ;texte für fehlermeldungen
errtext_len = $ - errtext
doserrtable EQU THIS BYTE
        err 002h,'file not found'
        err 003h,'path not found'
        err 005h,'access denied'
        err 007h,'memory block bad'
        err 008h,'not enough memory'
        err 009h,'invalid block'
        err 011h,'not same device'
        err 012h,'no more files'
        err 0FFh,'unknown dos error'

mymsgtable EQU THIS BYTE
        err 000h,'MOVE Version 1.00'
        err 001h,'Fehler: Zwei Argumente verlangt'
        err 002h,'Interner Buffer zu klein'
        err 003h,'Unbekannter Schalter'
        err 004h,'Zugriff verweigert'
        err 0FFh,'unknown message code'
data    ENDS

;=====================================================================
code    SEGMENT WORD

ASSUME cs : code, ds : data, ss : stack, es : nothing

dta_seg DW SEG data
psh_seg DW ?

; Ausgabe einer Meldung aus der Meldungstabelle
; ARGS: DS:BX = auf Anfang der Meldungstabelle
;       DX    = Ausgabe file handle oder device
;       AL    = der Meldungscode
; RETS: nothing
; REGS: alle bis auf AX,BX,DX erhalten
;-----------------------------------------------------------------0200
msgout  PROC NEAR
        push  cx                              ;register sichern
l0202:  mov   ah,[bx]                         ;code aus der tabelle lesen
        cmp   ah,al
        je    l0201                           ;es ist der richtige error code
        cmp   ah,0FFH
        je    l0201                           ;es ist der letze code
        add   bx,[bx+01]                      ;+ länge des textes
        add   bx,3                            ;+ länge des vorspanns
        jmp   l0202
l0201:  mov   cx,[bx+01]                      ;länge des textes
        xchg  dx,bx
        add   dx,3                            ;dx auf anfang des textes
        mov   ah,40h                          ;write a file or device
        int   21H
        pop   cx                              ;register zurückholen
        ret
msgout  ENDP

; Ausgabe einer DOS-Fehlermeldung, dann Programm beeneden
; ARGS: AL = DOS-Fehler code
; REGS: keine wergen erhalten
; RETS: 01, return-code an parent program
;-----------------------------------------------------------------0100
doserr  PROC NEAR
        push  ax                              ;error code sichern
        mov   ds,dta_seg                      ;ds auf data segment
        mov   bx,OFFSET errtext               ;auf anfang des fehler textes
        aam
        or    ax,3030h                        ;error-code in dezimal-ascii-zahl
        xchg  al,ah
        mov   [bx],ax
        mov   dx,bx                           ;ds:dx auf fehler text
        mov   cx,errtext_len                  ;länge des textes
        mov   bx,errout                       ;auf error device ausgeben
        mov   ah,40h                          ;write a file or device
        int   21H                             ;dos call
        pop   ax                              ;error code zurückholen
        mov   bx,OFFSET doserrtable           ;auf anfang der fehlertext tabelle
        mov   dx,errout                       ;auf error device ausgeben
        call  msgout
l0100:  mov   ax,4C01h                        ;exit from a process, error
        int   21H                             ;dos call
        jmp   l0100
doserr  ENDP

; Ausgabe einer Meldung aus der mymsgtable
; ARGS: DX    - Ausgabe file handle oder device
;       AL    - der Meldungscode
; RETS: nothing
; REGS: alle bis auf AX,DX erhalten
;-----------------------------------------------------------------0300
mymsg   PROC NEAR
        push  bx                              ;register sichern
        push  ds
        mov   ds,dta_seg
        mov   bx,OFFSET mymsgtable            ;ds:dx auf die message-tabelle
        call  msgout
        pop   ds
        pop   bx                              ;register zurück
        ret
mymsg   ENDP

; Eigene Fehlermeldung ausgeben und dann Programm beenden
; ARGS: AL    = der Meldungscode
; RETS: 02, als return code an parent program
; REGS: keine erhalten
;-----------------------------------------------------------------0400
myerr   PROC NEAR
        mov   dx,errout                       ;auf Fehlerausgbe
        call  mymsg
l0400:  mov   ax,4C02h                        ;exit from a process, error
        int   21H                             ;dos call
        jmp   l0400
myerr   ENDP

; Liest einen Switch aus der Command-Line
; ARGS: DS:SI auf Command-line, CX Länge der Zeile
; RETS: DS:SI ggf. hinter dem Schalter
;       CX Restlänge der Zeile
; REGS: Segment-Register werden erhalten
;-----------------------------------------------------------------0E00
swread  PROC NEAR
        push  ds
        cld
        mov   ah,space                        ;konstante
        jcxz  l0E00                           ;falls commandline leer ist
l0E02:  lodsb
        cmp   al,ah
        ja    l0E01                           ;ein nicht füllzeichen gefunden
        loop  l0E02                           ;falls cmd-line noch nicht leer
        jmp   SHORT l0E00
l0E01:  cmp   al,switch                       ;ein scahlter
        jne   l0E03
        dec   cx                              ;ja, dann das zeichen annehmen
        jz    l0E04
        lodsb                                 ;das zeichen hinter dem switch
        dec   cx
        mov   ds,dta_seg                      ;zum adressieren der variablen
        cmp   al,'v'
        jne   l0E04                           ;nicht der view-switch
        mov   view,true
        jmp   SHORT l0E00                     ;view switch bearbeitet
l0E03:  dec   si                              ;das zeichen wieder zurück geben
l0E00:  pop   ds
        ret
l0E04:  mov   al,03h                          ;fehler: unbekannter switch
        jmp   myerr
swread  ENDP

; Sucht den eigentlichen Filenamen einer Filebezeichung mit Pfadangabe
; ARGS: DS:DI auf den ASCIZ String mit der kompletten Bezeichnung
; RETS: DS:DI auf Anfang des Filenames
; REGS: Segment-Register werden erhalten
;-----------------------------------------------------------------0A00
selname PROC NEAR
        mov   si,di
        xor   al,al                           ;al := 00
l0A03:  inc   di
        cmp   al,[di]                         ;sucht ende des strings
        jne   l0A03
        dec   di
        mov   bx,'/:'                         ;das kann vor dem namen stehen
        mov   dl,'\'
l0A02:  mov   al,[di]                         ;zeichen lesen
        cmp   al,bl
        je    l0A01
        cmp   al,bh
        je    l0A01
        cmp   al,dl
        je    l0A01
        dec   di                              ;von hinten nach vorne suchen
        cmp   si,di
        jbe   l0A02                           ;wieder am anfang
l0A01:  inc   di
        ret
selname ENDP

; Liest erstes Argument aus DS:SI, überträgt es nach ES:DI
; mit Umwandlung in Großbuchstaben
; ARGS: DS:SI auf Buffer mit Argumenten
;       CX die Länge des Buffers
;       ES:DI auf Buffer in den das erste Argument übertragen wird
;       DX die Länge dieses Buffers
; RETS: DS:SI hinter dem Argument
; REGS: nur DS,ES erhalten
;-----------------------------------------------------------------0900
argread PROC NEAR
        cld
        cmp   cx,0
        jle   l0900                           ;command line ist leer
        mov   ah,space                        ;konstanten laden
        mov   bx,'za'
l0901:  lodsb
        cmp   al,ah                           ;füllzeichen überlesen
        ja    l0903
        loop  l0901
        jmp   SHORT l0900                     ;ende der command line erreicht
l0903:  cmp   al,bl
        jb    l0905                           ;zeichen < 'a'
        cmp   al,bh
        ja    l0905                           ;zeichen > 'z'
        and   al,11011111B                    ;a bis z zu A bis Z wandeln
l0905:  stosb                                 ;abspeichern eines zeichen
        dec   dx
        jz    l0904                           ;falls buffer voll ist
        lodsb
        dec   cx
        js    l0906                           ;ende der command line erreicht
        cmp   al,ah
        ja    l0903                           ;bis ende des arguments
l0906:  xor   al,al                           ;mit 00 abschließen
        stosb
        ret

l0904:  mov   al,02                           ;argument paßt nicht in buffer
        jmp   myerr
l0900:  mov   al,01                           ;argument fehlt in cmd line
        jmp   myerr
        ret
argread ENDP

; Die Command Zeile auswerten, setzt die entspechenden Daten
; ARGS: nothing
; RETS: nothing
; REGS: keine erhalten
;-----------------------------------------------------------------0500
clread  PROC NEAR
        cld                                   ;richtung nach höhere adressen
        mov   es,dta_seg                      ;es auf das data segment
        mov   ds,psh_seg
        mov   si,0080h                        ;ds:si auf command line
        lodsb                                 ;al := länge der commandline
        mov   cl,al
        xor   ch,ch                           ;cx := # zeichen in commandline
        call  swread                          ;schalter auswerten
        mov   di,OFFSET s_path
        mov   dx,LENGTH s_path                ;dx := länge von s_path
        call  argread                         ;den "quell-pfad-name" lesen
        mov   di,OFFSET d_path
        mov   dx,LENGTH d_path                ;dx := länge von d_path
        call  argread                         ;den "ziel-pfad" lesen
        mov   ax,es
        mov   ds,ax                           ;ds := seg data
        mov   di,OFFSET s_path
        call  selname
        mov   sn_ptr,di                       ;zeiger auf den eigentl. namen
        mov   di,OFFSET d_path
        call  selname
        mov   dn_ptr,di
        ret
clread  ENDP

; Überträgt einen ASCIZ-String in den Buffer
; ARGS: DS:SI auf ASCIZ-String
;       ES:DI auf Buffer, der Länge CX
; RETS: ES:DI hinter dem ASCIZ-String im Buffer
;       CX Restlänge im Buffer
; REGS: Segemnt-Register werden erhalten
;-----------------------------------------------------------------0D00
cat     PROC NEAR
        cld                                   ;richtung nach höheren adressen
l0D01:  lodsb                                 ;zeichen ais asciz-string lesen
        or    al,al
        jz    l0D00                           ;00 terminiert den string
        stosb
        loop  l0D01                           ;oder bis buffer voll ist
l0D00:  ret
cat     ENDP

; Protokolliert Filenamen auf s_path und d_path auf der Standartausgabe
; ARGS: DS auf data Segment erwartet
; RETS: nothing
; REGS: Segement-Register werden erhalten
;-----------------------------------------------------------------0C00
viewing PROC NEAR
        push  es
        mov   ax,ds
        mov   es,ax                           ;es := ds
        mov   di,OFFSET outbuf                ;buffer für die ausgabe
        mov   cx,LENGTH outbuf
        mov   bx,OFFSET cattable              ;tabelle der einzel texte
l0C00:  mov   si,[bx]
        inc   bx                              ;auf nächste adresse
        inc   bx
        or    si,si                           ;0 = ende der tabelle
        jz    l0C01
        call  cat                             ;text in ausgabe buffer
        cmp   cx,0
        jg    l0C00
        mov   al,02                           ;ausgabe buffer zu klein
        jmp   myerr
l0C01:  mov   bx,cx
        mov   cx,LENGTH outbuf
        sub   cx,bx                           ;bx := länge der ausagabe
        mov   bx,stdout                       ;auf die standart ausgabe
        mov   dx,OFFSET outbuf                ;ds:dx auf den buffer
        mov   ah,40h                          ;write device
        int   21h                             ;dos call
        pop   es
        ret
viewing ENDP

; Kopiert Filename von ES:SI nach DS:DI, ohne Spaces mit 00 am Ende
; ARGS: ES:SI, DS:DI wie oben erklärt
; RETS: nothing
; REGS: Segment-Register werden erhalten
;-----------------------------------------------------------------0800
putfname PROC NEAR
        cld
        mov   ah,space                        ;ah := space
l0800:  lodsb                                 ;ein zeichen lesen
        cmp   al,ah
        je    l0801                           ;leerzeichen müssen nicht sein
        stosb                                 ;ein zeichen speichern
l0801:  or    al,al                           ;bis 00 Ende anzeigt
        jnz   l0800
        ret
putfname ENDP

; Umbennen einer Datei, die kompl. Namen stehen in s_path, d_path
; falls view = true, wird Protokollausgaberoutine angesprungen
; ARGS: DS auf data Segment
; RETS: nothing
; REGS: Segment-Register werden erhalten
;-----------------------------------------------------------------0B00
renv2   PROC NEAR
        cmp   view,true                       ;view-switsch gesetzt ?
        jne   l0B01
        call  viewing                         ;protokoll ausgabe
l0B01:  mov   dx,OFFSET s_path
        mov   di,OFFSET d_path
        mov   ah,56h                          ;rename
        clc
        int   21h                             ;dos call
        jnc   l0B00
        cmp   ax,05h                          ;access deneid => kein abbruch
        je    l0B02
        jmp   doserr                          ;falls andere dos fehler
l0B02:  mov   al,04                           ;zugriff verweigert
        mov   dx,stdout                       ;aus das standart ausgabe gerät
        call  mymsg                           ;meldung ausgeben
l0B00:  ret
renv2   ENDP

; Umbennen einer Datei, die Pfade stehen in s_path, d_path
; und Dateiname in block.fname, ebenso wird sn_ptr und dn_ptr benutzt
; ARGS: DS auf data Segment
; RETS: nothing
; REGS: nur DS wird erhalten
;-----------------------------------------------------------------0700
rename  PROC NEAR
        mov   ax,ds
        mov   es,ax                           ;es := ds
        mov   si,OFFSET block.fname
        mov   di,sn_ptr
        call  putfname                        ;kompl. quell-filename erzeugen
        mov   si,OFFSET block.fname
        mov   di,dn_ptr
        call  putfname                        ;kompl. ziel-filenamen erzeugen
        call  renv2
        ret
rename  ENDP

; Die Verschiebung der Dateien ausführen
; ARGS: nothing
; RETS: nothing
; REGS: keine erhalten
;-----------------------------------------------------------------0600
moving  PROC NEAR
        mov   ds,dta_seg
        mov   dx,OFFSET block                 ;ds:dx auf block
        mov   ah,1Ah                          ;set disk transfer address
        int   21H                             ;dos call
        mov   dx,OFFSET s_path                ;ds:dx auf "quell-file-name"
        xor   cx,cx                           ;cx := 0, keine file attribute
        mov   ah,4Eh                          ;find first
        clc
        int   21h                             ;dos call
        jnc   l0601
        jmp   doserr                          ;fehler
l0601:  call  rename                          ;der kern des moving
        mov   ah,4Fh                          ;find next
        clc
        int   21h                             ;dos call
        jnc   l0601                           ;noch eine datei gefunden
        cmp   ax,12h                          ;12h == keine weitere datei
        je    l0602
        call  doserr                          ;sonstiger fehler
l0602:  ret
moving  ENDP

; Hauptprogramm
; ungenützer Speicher freigeben
; Auswerterung der Command-Line
; aufrufen der Move-Routine
; Programm beneden
;-----------------------------------------------------------------0000
main    PROC NEAR
        mov   psh_seg,es                      ;psh segment merken
        mov   bx,ss
        add   bx,ssize / 16                   ;bx := höchster genutzer paragraph
        mov   ax,es
        sub   bx,ax                           ;bx := anzahl der benutzten paras
        mov   ah,4Ah                          ;modify allocated block
        clc
        int   21h                             ;dos call (ES noch auf psh)
        jnc   l0001
        jmp   doserr                          ;falls fehler
l0001:  mov   al,0                            ;say hello
        mov   dx,stdout                       ;auf standart ausgabe gerät
        call  mymsg
        call  clread                          ;command line auswerten
        mov   ds,dta_seg
        mov   bx,dn_ptr
        cmp   [bx],BYTE PTR 00                ;dateiname oder pfadname ?
        jne   l0002
        call  moving                          ;dateien in einen andern pfad
        jmp   SHORT l0000
l0002:  call  renv2                           ;eine datei umbennen
l0000:  mov   ax,4C00h                        ;exit from a process
        int   21H                             ;dos call
        jmp   l0000
main    ENDP

code    ENDS

;=====================================================================
stack   SEGMENT STACK WORD
        DB ssize DUP (?)
stack   ENDS

        END main
