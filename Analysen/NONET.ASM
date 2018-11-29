        PAGE  60,132
;---------------------------------------------------------------------
; Assembler Listing von NONET.EXE  (c) Phonix Software 1983
;
; möglicher Schalter '-V' (switch character '-' von DOS erfragt)
;       dann wird nur der Programmname ausgegeben
;
; Analysiert und kommentiert .08.1992 Ulrich Berntien
;
; Wichtiges Ergebnis, der Netzwerktrieber wird aufgerufen über den
; DOS-API Aufruf int 21H mit AH = 0EFH
;
; 30.08.1992  Beginn
;---------------------------------------------------------------------

code    SEGMENT PUBLIC WORD

        ASSUME cs : code, ss : data, ds : data

        DB 'Lattice C 1.02'     ;compiliert mit Lattice C im Modell small

; Initialisieren
;       Einrichten des Stacks
;       Segmentregister setzen
;       vor die Kommandozeile ein '?' setzen, weil MS-DOS nicht wie
;         in UNIX den Programmname übergibt
;---------------------------------------------------------------------
start   PROC  FAR
        cli                                   ;sperre interrupts
        mov   ax,SEG data
        mov   ds,ax                           ;ds auf data segment
        mov   ss,ax                           ;ss auf data segment
        mov   bx,es:[0002H]                   ;endadresse des speichers aus psp
        sub   bx,ax                           ;paragraphs im data segemnt frei
        test  bx,0F000H                       ;mehr als 64 Kbyte ?
        jnz   l0129                           ; ja
        mov   cl,04H                          ; nein
        shl   bx,cl                           ;paragraphen in bytes umrechnen
        jmp   SHORT l012c
l0129:  mov   bx,0FFF0H                       ;maximal 64 Kbyte benutzen
l012c:  mov   sp,bx                           ;stack wächst von oben in data
        sti                                   ;interrupts freigeben
        mov   top_stack,bx                    ;stack obergrenze speichern
        mov   ax,01F0H                        ;anzahl bytes an statischen daten
        mov   low_stack,ax                    ;stack untergrenze speichern
        push  es
        xor   ax,ax
        push  ax                              ;psp:0000 auf stack, zum programmbeneden
        mov   bp,sp                           ;mit bp lokale varia. adressieren
        mov   si,0080H                        ;es:si auf kommandozeile im psp
        mov   cl,es:[si]
        inc   si                              ;es:si auf erstes zeichen
        xor   ch,ch                           ;länge der kommandozeile in cx
        mov   bx,cx
        add   bx,+04H
        and   bx,0FFFEH                       ;auf wordgrenze ausrichten
        sub   sp,bx                           ;platz auf stack schaffen
        mov   di,sp
        mov   BYTE PTR [di],'?'
        inc   di
        jcxz  l0168                           ;falls cmd-zeile leer ist
        mov   BYTE PTR [di],20H               ;kommando zeile mit ' ' beginnen
        inc   di
l015f:  mov   al,es:[si]                      ;kommandozeile aus dem psp
        mov   [di],al                         ;auf den stack kopieren
        inc   si
        inc   di
        loop  l015f
l0168:  xor   ax,ax
        mov   [di],al                         ;kommandozeile mit 0 abschließen
        mov   ax,ds
        mov   es,ax                           ;es auch auf data segment
        mov   ax,sp
        push  ax                              ;adr des cmd-zeile übergeben
        call  setup
        mov   sp,bp                           ;parameter vom stack nehmen
        ret                                   ;programm ende
start   ENDP

; void _exit ( void )
;       Programm beenden
;---------------------------------------------------------------------
_exit   PROC  FAR
        mov   ax,top_stack
        sub   ax,0004H
        mov   sp,ax                           ;ss:sp = psp:0000
        ret                                   ;sprung dort hin
_exit   ENDP                                  ;   int 20H ausführen

; void main ( int arg, char* argv[] )
;       Hauptprogramm
;---------------------------------------------------------------------
main    PROC  NEAR
        push  bp                              ;frame pointer sichern
        sub   sp,+0AH                         ;10 bytes lokale variablen
        mov   bp,sp                           ;mit bp lokale var. adressieren
        call  checknet                        ;netzwerk vorhanden ?
        test  ax,ax
        jnz   l019d                           ;  ja
        mov   ax,OFFSET msg_nonet             ;  nein, Meldung: 'kein Netzwerk'
        push  ax
        call  puts                            ;string ausgeben
        mov   sp,bp                           ;parameter vom stack nehmen
        add   sp,+0AH                         ;lokale variablen freigeben
        pop   bp                              ;frame pointer zurück
        ret

l019d:  mov   WORD PTR [bp+06H],0000H         ;index für argv liste
l01a2:  mov   ax,[bp+06H]
        cmp   ax,[bp+0EH]                     ;index < argc
        jl    l01ad                           ;  ja
        jmp   l02b8                           ;  nein, fast fertig
l01ad:  shl   ax,1
        mov   si,[bp+10H]
        add   si,ax                           ;si = argv + index
        mov   di,[si]                         ;di = *( argv + index )
        mov   [bp+00H],di                     ;den zeiger auf den string merken
        call  switchchar                      ;ax = switch character
        mov   si,[bp+00H]
        mov   bl,[si]
        xor   bh,bh
        cmp   bx,ax                           ;ein switch-char gefunden
        je    l01ca                           ;  ja
        jmp   l02b2                           ;  nein, ignorieren
l01ca:  mov   ax,[bp+06H]
        shl   ax,1
        mov   si,[bp+10H]
        add   si,ax                           ;si = argv + index
        mov   bx,[si]                         ;bx = argv[index]
        inc   bx
        mov   al,[bx]                         ;das zeichen hinter dem switch
        xor   ah,ah                           ;ax = argv[index][1]
        mov   [bp+00H],ax
        inc   ax
        mov   si,ax
        mov   al,_ctype[si]
        xor   ah,ah
        and   ax,0002H
        je    l01f5
        mov   ax,[bp+00H]
        sub   ax,0020H
        jmp   l027b
l01f5:  mov   ax,[bp+06H]
        shl   ax,1
        mov   si,[bp+10H]
        add   si,ax
        mov   di,[si]
        inc   di
        mov   al,[di]
        xor   ah,ah
        jmp   SHORT l027b
l0208:  mov   ax,OFFSET msg_paxnet            ;programmname ausgeben
        push  ax
        call  puts
        mov   sp,bp                           ;parameter vom stack nehmen
        mov   ax,OFFSET msg_copy              ;erster teil des copyright
        push  ax
        call  puts
        mov   sp,bp                           ;parameter vom stack nehmen
        mov   ax,OFFSET msg_right             ;zweiter teil des copyright
        push  ax
        call  puts                            ;ausgeben
        mov   sp,bp                           ;parameter vom stack nehmen
        call  exit                            ;programm beeneden

l0226:  mov   ax,OFFSET msg_switch
        push  ax
        call  puts
        mov   sp,bp                           ;parameter vom stack nehmen
        mov   ax,[bp+06H]
        shl   ax,1
        mov   si,[bp+10H]
        add   si,ax
        mov   di,[si]
        inc   di
        mov   al,[di]
        xor   ah,ah
        mov   [bp+00H],ax
        inc   ax
        mov   si,ax
        mov   al,_ctype[si]
        xor   ah,ah
        and   ax,0002H
        je    l0259
        mov   ax,[bp+00H]
        sub   ax,0020H
        jmp   SHORT l026a
l0259:  mov   ax,[bp+06H]
        shl   ax,1
        mov   si,[bp+10H]
        add   si,ax
        mov   di,[si]
        inc   di
        mov   al,[di]
        xor   ah,ah
l026a:  push  ax                              ;das zeichen übergeben
        call  putchar                         ;ausgeben auf stdout
        mov   sp,bp                           ;parameter vom stack nehmen
        mov   ax,OFFSET msg_ignor
        push  ax
        call  puts
        mov   sp,bp                           ;parameter vom stack nehmen
        jmp   SHORT l0282
l027b:  cmp   ax,'V'
        je    l0208
        jmp   SHORT l0226
l0282:  mov   ax,[bp+06H]
        inc   ax
        mov   [bp+08H],ax
l0289:  mov   ax,[bp+08H]
        cmp   ax,[bp+0EH]
        jnl   l02ac
        shl   ax,1
        mov   [bp+00H],ax
        dec   ax
        dec   ax
        mov   si,[bp+10H]
        add   si,ax
        mov   di,[bp+10H]
        add   di,[bp+00H]
        mov   ax,[di]
        mov   [si],ax
        inc   WORD PTR [bp+08H]
        jmp   SHORT l0289
l02ac:  dec   WORD PTR [bp+0EH]
        dec   WORD PTR [bp+06H]
l02b2:  inc   WORD PTR [bp+06H]               ;index um eins erhöhen
        jmp   l01a2
l02b8:  call  dismount
        add   sp,+0AH                         ;lokale variablen freigeben
        pop   bp                              ;frame pointer zurück
        ret
main    ENDP

; int checknet ( void )
;       testet ob ein Netzwerk vorhanden ist
;       gibt 0 zurück, wenn kein Netzwerk installiert ist
;---------------------------------------------------------------------
checknet PROC  NEAR
        mov   bx,0000H
        mov   ah,0EFH                         ;netzwerk ansprechen
        push  bp                              ;frame pointer sichern
        mov   bp,008AH
        int   21H                             ;dos call
        pop   bp                              ;frame pointer zurück
        mov   ax,bx
        ret
checknet ENDP

; char switchchar ( void )
;  Erfrage den Kommanozeilenschalter von DOS
;  beim WANG PC üblich '-' beim IBM üblich '/'
;---------------------------------------------------------------------
switchchar  PROC  NEAR
l02cf:  mov   ah,37H                          ;switch-character ermittlen
        mov   al,00H
        int   21H                             ;dos call
        mov   al,dl
        xor   ah,ah                           ;ax = switch character
        ret
switchchar ENDP

; void setup ( char* cmdline )
;    Die Kommandozeile analysieren, zerlegen für main
;    Argument 'cmdline' eine aufbereitet Form der Kommandozeile
;---------------------------------------------------------------------
setup   PROC NEAR
        push  bp                              ;sichere frame pointer
        sub   sp,+04H                         ;4 bytes für lokale variablen
        mov   bp,sp                           ;mit bp lokale var. adressieren
l02e0:  mov   si,[bp+08H]                     ;si = &cmdline
        mov   al,[si]                         ;zeichen aus cmdline lesen
        xor   ah,ah
        inc   ax
        mov   di,ax                           ;mit dem zeichen eine tabelle
        mov   al,_ctype[di]                   ;  indizieren
        xor   ah,ah
        and   ax,0008H
        jz    l02fa
        inc   WORD PTR [bp+08H]               ;nächstes zeichen in der cmdline
        jmp   l02e0
l02fa:  mov   si,[bp+08H]
        mov   al,[si]                         ;zeichen nochmal aus der cmdline
        xor   ah,ah
        test  ax,ax                           ;ist string zu ende ?
        jz    l036c                           ;  ja
        cmp   WORD PTR ds:[00A8H],+20H        ;  nein
        jnl   l036c
        mov   ax,WORD PTR ds:[00A8H]
        inc   WORD PTR ds:[00A8H]
        shl   ax,1
        mov   di,ax
        mov   ax,si
        mov   [di+00AAH],ax
l031d:  mov   si,[bp+08H]
        mov   al,[si]
        xor   ah,ah
        test  ax,ax
        mov   [bp+00H],ax
        je    l033e
        inc   ax
        mov   di,ax
        mov   al,_ctype[di]
        xor   ah,ah
        and   ax,0008H
        jne   l033e
        inc   WORD PTR [bp+08H]
        jmp   SHORT l031d
l033e:  mov   si,[bp+08H]
        mov   al,[si]
        xor   ah,ah
        test  ax,ax
        je    l036c
        mov   si,[bp+08H]
        inc   WORD PTR [bp+08H]
        mov   BYTE PTR [si],00H
l0352:  mov   si,[bp+08H]
        mov   al,[si]
        xor   ah,ah
        inc   ax
        mov   di,ax
        mov   al,_ctype[di]
        xor   ah,ah
        and   ax,0008H
        je    l02fa
        inc   WORD PTR [bp+08H]
        jmp   SHORT l0352
l036c:  mov   ax,00AAH                        ;tabelle der string pointer
        push  ax
        push  WORD PTR ds:[00A8H]             ;anzahl der parameter
        call  main
        mov   sp,bp                           ;parameter vom stack nehmen
        add   sp,+04H                         ;lokale variablen freigeben
        pop   bp                              ;frame pointer zurück
        ret
setup   ENDP

; *** wird nicht benutzt ***
; int getch ( void )
;       Zeichen von Konsole einlesen, kein Echo ausgeben
;---------------------------------------------------------------------
getch   PROC  NEAR
l037e:  push  bp                              ;frame pointer retten
        mov   ah,07H                          ;direkte zeichen eingabe
        int   21H                             ;dos call
        xor   ah,ah                           ;ax = eingelesenes zeichen
        pop   bp                              ;frame pointer zurück
        ret
getch   ENDP

; *** wird nicht benutzt ***
; int getch ( void )
;       Zeichen von Konsole einlesen, Echo wird auf Konsole ausgeben
;---------------------------------------------------------------------
getche  PROC  NEAR
l0387:  push  bp                              ;frame pointer sichern
        mov   ah,01H                          ;zeicheneingabe mit echo
        int   21H                             ;dos call
        xor   ah,ah                           ;ax = eingelesenes zeichen
        pop   bp                              ;frame pointer zurück
        ret
getche  ENDP

;---------------------------------------------------------------------
buffer  DB 00                                 ;buffer für putchar

; void putchar ( char c )
;    Ausgabe des Zeichens 'c' auf Standartausgabegerät
;---------------------------------------------------------------------
putchar PROC  NEAR
        push  ds                              ;datensegment retten
        mov   ax,cs
        mov   ds,ax                           ;ds auf code segment
        mov   dl,[bp-02H]
        mov   [buffer],dl                     ; c in den buffer
        mov   ah,40H                          ;write a file or device
        mov   bx,0001H                        ;handle 1, stdout
        mov   cx,0001H                        ;ein byte ausgeben
        mov   dx,OFFSET code:buffer           ;ds:dx auf buffer
        int   21H
        pop   ds                              ;datensegment zurück
        ret
putchar ENDP

; *** wird nicht benutzt ***
; int kbhit ( void )
;       Testet ob eine Taste zum Einlesen bereit ist
;       gibt != 0 falls ein Zeichen bereit ist
;---------------------------------------------------------------------
kbhit   PROC  NEAR
l03ad:  mov   ah,0BH                          ;lese eingabestatus
        int   21H                             ;dos call
        mov   ah,00H                          ;ax = al
        ret
kbhit   ENDP

; void puts ( char* str )
;---------------------------------------------------------------------
puts    PROC  NEAR
        push  bp                              ;frame pointer sichern
        mov   si,[bp-02H]                     ;si auf str
        mov   bp,sp                           ;stack pointer merken
l03ba:  lodsb                                 ;ein zeichen aus string laden
        or    al,al                           ;string zu ende ?
        je    l03c7                           ;  ja
        push  ax                              ;das zeichen übergeben
        call  putchar                         ;auf stdout ausgaben
        mov   sp,bp                           ;parameter vom stack nehmen
        jmp   SHORT l03ba
l03c7:  pop   bp                              ;frame pointer zurück
        ret
puts    ENDP

; *** wird nicht benutzt ***
; void putsf( char _far* str )
;       Ausgabe eines Strings auf Standartausgabegerät
;---------------------------------------------------------------------
putsf   PROC  NEAR
l03c9:  push  ds                              ;datensegment sichern
        push  bp                              ;frame pointer sichern
        mov   ds,[bp-02H]
        mov   si,[bp-04H]                     ;ds:si auf str
l03d1:  mov   al,[si]
        or    al,al                           ;ende des strings ?
        jz    l03e0                           ;  ja
        mov   ah,02H                          ;ein zeichen ausgeben
        mov   dl,al
        int   21H                             ;dos call

l03dd:  inc   si                              ;auf nächstes zeichen
        jmp   SHORT l03d1
l03e0:  pop   bp                              ;frame pointer zurück
        pop   ds                              ;data segment zurück
        ret
putsf   ENDP

; *** wird nicht benutzt ***
; int inp ( int port )
;       ein Byte von 'port' lesen
;---------------------------------------------------------------------
inp     PROC  NEAR
l03e3:  mov   dx,[bp-02H]                     ;dx = port
        in    al,dx
        mov   ah,00H                          ;ax = al
        ret
inp     ENDP

; *** wird nicht benutzt ***
; void outp ( int port, int b )
;       Ausagbe eines Bytes 'b' auf den 'port'
;---------------------------------------------------------------------
outp    PROC  NEAR
l03ea:  mov   al,[bp-02H]                     ;al = b
        mov   dx,[bp-04H]                     ;dx = port
        out   dx,al
        ret
outp    ENDP

; void exit ( void )
;       Programm beenden
;---------------------------------------------------------------------
exit    PROC  NEAR
        push  bp                              ;frame pointer retten
        mov   bp,sp                           ;stack pointer in bp merken
        push  WORD PTR [bp+06H]
        push  WORD PTR [bp+04H]
        call  _exit                           ;programm beenden
        mov   sp,bp                           ;parameter vom stack nehmen
        pop   bp                              ;frame pointer restaurieren
        ret
exit    ENDP

code    ENDS

;---------------------------------------------------------------------
data    SEGMENT PUBLIC BYTE

ALARM   EQU 07H                               ;pipser betútigen
CR      EQU 0DH                               ;carriage return
LF      EQU 0AH                               ;line feed
HKOMMA  EQU 27H                               ;das Zeichen '

top_stack  DW  0000                           ;obere grenze des stacks
low_stack  DW  0000                           ;untere grenze des stacks

msg_nonet   DB  ALARM, 'Network not installed', CR, LF, 0
msg_paxnet  DB  'PAXNET dismounting utility, ver 1.5, 10/11/83', 0
msg_copy    DB  CR,LF,'Copyright (c) 1983 by ', 0
msg_right   DB  'Phoenix Software Associates, LTD.', CR, LF, 0
msg_switch  DB  'Invalid switch ', HKOMMA, 0
msg_ignor   DB  HKOMMA, ' ignored', CR, LF, 0

        DB 44H DUP (00H)

_ctype EQU THIS BYTE - 1
        DB                                              20H,20H,20H,20H,20H
        DB  20H,20H,20H,20H,28H,28H,28H,28H,28H,20H,20H,20H,20H,20H,20H,20H
        DB  20H,20H,20H,20H,20H,20H,20H,20H,20H,20H,20H,48H,10H,10H,10H,10H
        DB  10H,10H,10H,10H,10H,10H,10H,10H,10H,10H,10H,84H,84H,84H,84H,84H
        DB  84H,84H,84H,84H,84H,10H,10H,10H,10H,10H,10H,10H,81H,81H,81H,81H
        DB  81H,81H,01H,01H,01H,01H,01H,01H,01H,01H,01H,01H,01H,01H,01H,01H
        DB  01H,01H,01H,01H,01H,01H,10H,10H,10H,10H,00H,10H,82H,82H,82H,82H
        DB  82H,82H,02H,02H,02H,02H,02H,02H,02H,02H,02H,02H,02H,02H,02H,02H
        DB  02H,02H,02H,02H,02H,02H,10H,10H,10H,10H,20H,20H,20H,20H,20H,20H
        DB  20H,20H,20H,20H,28H,28H,28H,28H,28H,20H,20H,20H,20H,20H,20H,20H
        DB  20H,20H,20H,20H,20H,20H,20H,20H,20H,20H,20H,48H,10H,10H,10H,10H
        DB  10H,10H,10H,10H,10H,10H,10H,10H,10H,10H,10H,84H,84H,84H,84H,84H
        DB  84H,84H,84H,84H,84H,10H,10H,10H,10H,10H,10H,10H,81H,81H,81H,81H
        DB  81H,81H,01H,01H,01H,01H,01H,01H,01H,01H,01H,01H,01H,01H,01H,01H
        DB  01H,01H,01H,01H,01H,01H,10H,10H,10H,10H,00H,10H,82H,82H,82H,82H
        DB  82H,82H,02H,02H,02H,02H,02H,02H,02H,02H,02H,02H,02H,02H,02H,02H
        DB  02H,02H,02H,02H,02H,02H,10H,10H,10H,10H,20H

        DB 0104H DUP (00)

data    ENDS

;---------------------------------------------------------------------
code    SEGMENT PUBLIC WORD

; void dismount ( void )
;       Netzwerkunterstützung abschalten
;---------------------------------------------------------------------
dismount PROC NEAR
        mov   ah,0EFH                         ;netzwerk ansprechen
        push  bp                              ;frame pointer sichern
        mov   bp,0085H
        int   21H                             ;dos call
        pop   bp                              ;frame pointer zurück
        ret
dismount ENDP

code    ENDS

;---------------------------------------------------------------------
        END   start
