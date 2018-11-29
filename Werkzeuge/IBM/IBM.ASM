; Wang PC / MS-Macro-Assembler V1.0
; (c) Ulrich Berntien .09.1988
;     letzte Änderung .06.1991

; Stellt die Interrupt Vektoren 10H, 11H, 12H, 1CH, 16H, 33H zur Verfügung

; Aufrufformat: IBM [-t] [-f]
; Optinen: -f => Floating Point Processor (8087) kann benutzt werden
;          -t => Timer Interrupt ist aktiv für Ada Tasking
; Gross/Kleinschreibung beachten !

;Beschreibung der Interrupt Vektoren (siehe MC Februar 1988)
;Beschreibung des Interrupt #33 (Maus) siehe MC Dezember 1989

;INT 10H : Bildschirm

;INT 16H : Tastaturabfrage
;AH = 00: Auf Tastendruck warten und Zeichen holen
;         Output: Al = ASCII-Wert,  Ah = Scan-Code
;AH = 01: Prüfen ob Taste gedrückt
;         Output: Z-Flag = 1 : keine Taste gedrückt
;                 Z-Flag = 0 : Taste gedrückt, Al = ASCII, Ah = Scan-Code
;AH = 02: Sondertasten abfragen
;         Output Al

;INT 11H : Hardware-Test
;Output Ax-Bits:
;       0       1 => Disk-Laufwerk(e) vorhanden
;       1       1 => FPU 80x87 vorhanden
;       2,3     Speicherbänke auf der Hauptplatine
;       4,5     Default video modus 3 => Monochrom Karte 80 x 25
;       6,7     Zahl der Disk-Laufwerke, falls Bit 0 = 1
;       8       ---
;       9,10,11 Anzahl der V.24 Schnittstellen
;       12      1 => Game-Adapter vorhanden
;       13      ---
;       14,15   Anzahl der Parallelschnittstellen

;INT 1CH : Timer-Interrupt
;Wird 18.2 mal pro Sekunde angesprungen. Benutzerprogramme, die den Vektor
;umleiten, sollten am Ender der Routine zur bisherigen Adresse springen.

;INT 33H : Maus
;AX = 00: Maus initialisieren
;         Rückgabe AX = 0000 -> Mausstatus fehlerhaft
;                  BX = 0000 -> keine Mausknöpfe da

;-------------------------------------------------------------------------------

IBM     Segment
        Assume CS:IBM

True    = Byte PTR 01
False   = Byte PTR 00

        ORG 0080H
chars   DB ?
param   DB ?
        ORG 0100H
        Jmp   Init

;-------------------------------------------------------------------------------
; RESIDENT PART:

sib     DD ?                              ;ads des screen information blocks

membx   DW ?                              ;bx register zwischespeichern

tab10   EQU THIS WORD                     ;funktionscode tabelle für int 10H
        DW tf00             ;00           ;Bildschirmmodus wählen
        DW tf00             ;01           ;Cursorgröße wählen
        DW tf04             ;02           ;Cursorpositionieren
        DW tf05             ;03           ;Cursorposition ermitteln
        DW tf01             ;04           ;Lichtgriffel abfragen
        DW tf00             ;05           ;Bildschirmseite wählen
        DW tf00             ;06
        DW tf00             ;07
        DW tf00             ;08
        DW tf02             ;09
        DW tf02             ;0A
        DW tf00             ;0B           ;Farbpalette setzen
        DW tf00             ;0C           ;Grafikpunkt setzen
        DW tf01             ;0D           ;Grafikpunktlesen
        DW tf02             ;0E
        DW tf03             ;0F           ;Bildschirmmodus lesen

tf00    PROC NEAR                             ;mache nichts
        ret
tf00    ENDP

tf01    PROC NEAR                             ;gebe ax = 0 zurück
        xor     ax,ax
        ret
tf01    ENDP

tf02    PROC NEAR                             ;character ausgeben
        push    ax
        mov     bl,al                         ;character
        cmp     bl,20H                        ;keine Sonderzeichen ausgeben
        ja      tf021
        mov     bl,20H
        jmp     short tf022
tf021:  cmp     bl,80H
        jb      tf022
        mov     bl,'.'                        ;keine Sonderzeichen ausgeben
tf022:  xor     bh,bh                         ;to default screen
        mov     al,06H                        ;bios call
        int     88H
        pop     ax
        ret
tf02    ENDP

tf03    PROC NEAR
        mov     al,al                         ;Bildschirmmodus 0
        mov     ah,80                         ;80 Zeichen pro Zeile
        mov     membx,0                       ;Bildschirmseite 0
        ret
tf03    ENDP

tf04    PROC NEAR
        push    ds
        lds     bx,sib
        cmp     dl,80
        jb      tf041
        mov     dl,79                         ;Spalte 79 maximal
tf041:  cmp     dh,25
        jb      tf042                         ;Zeile 24 maximal
        mov     dh,24
tf042:  mov     [bx+05],dh                    ;cursor spalte setzen
        mov     [bx+06],dl                    ;cursor zeile setzen
        pop     ds
        ret
tf04    ENDP

tf05    PROC NEAR
        push    ds
        lds     bx,sib
        mov     dx,[bx+05]                    ;cursorposition lesen
        xchg    dh,dl
        xor     cx,cx                         ;cursorgröße
        pop     ds
        ret
tf05    ENDP

int_10  PROC FAR                              ;Bildschirm
        cli
        cmp     ah,0FH                        ;über 0FH nicht unterstützt
        ja      l0100
        mov     membx,bx                      ;bx zwischenspeichern
        mov     bl,ah
        sal     bx,1                          ;words adressieren
        call    [tab10+bx]
        mov     bx,membx                      ;bx zurÞckholen
l0100:  iret
int_10  ENDP

int_11  PROC FAR                              ;Hard-ware test
        cli
        DB    0B8H                            ;Mov Ax,????
syswrd  DW    0100001001110101B
           ;  5432109876543210
        iret
int_11  EndP

int_12  PROC FAR
        cli
        mov     ax,640                        ;640 KB Speicher
        iret
int_12  ENDP

int_16  Proc FAR
        cli
        or    ah,ah
        jnz   l0001
        mov   ah,08H                          ;console input
        int   21H
        mov   ah,00H
        iret
l0001:  cmp   ah,01
        jne   l0002
        push  dx
        mov   ah,0BH                          ;check keyboard status
        int   21H
        pop   dx
        xor   ah,ah
        cmp   al,al                           ;taste gedrückt ?
        jz    l0003
        mov   ax,000DH
l0003:  iret
l0002:  xor   al,al                           ;keine Sondertaste aktiv
        iret
int_16  EndP

int_1C  PROC FAR                              ;timer-interrupt
        iret
int_1C  ENDP

timer   PROC FAR                              ;Aufruf des Int 1C
        int   1CH
        ret
timer   ENDP

int_33  PROC FAR                              ;maus-interrupt
        cli
        xor     ax,ax
        xor     bx,bx
        iret
int_33  ENDP

timeflg DB False                              ;01H => timer interrupt is on
QID     DW 0000H                              ;    trap queue identification no

End_Mark: NOP

;-------------------------------------------------------------------------------
assume DS : IBM

resSeg  DW 0000H                              ;Segment des residenten Teils
timeADR DW 0000H                              ;Adresse der timer ProcFar
timeDTA DW 0000H                              ;Adresse der Daten für timer
sysDTA  DW 0000H                              ;Adresse des Systemdatenworts

newRun  DB 00H                                ;01 => res. Teil wird installiert
fpu     DB 00H                                ;01 => -f is set
tasking DB 00H                                ;01 => -t is set

mess1   DB 'IBM runtime bios ext. (c) Ulrich Berntien 1988',0DH,0AH,'$'
mess2   DB 'is new installed',0DH,0AH,'$'
errd0   DB 'Fehler vom DOS: '
errd1   DB '0000 dez.',0DH,0AH,07H,'$'
errb0   DB 'Fehler vom BIOS: '
errb1   DB '00 dez.',0DH,0AH,07H,'$'

;-------------------------------------------------------------------------------

Init    Proc Near
        Mov   Dx,Offset mess1                 ;Meldung ausgeben
        Mov   Ah,09H                          ;print string
        Int   21H
        Jnc   Next_0
        Jmp   ErrDOS
Next_0: Mov   Ax,3511H                        ;get interrupt vektor 11H
        Int   21H
        Jnc   Next_1
        Jmp   ErrDOS
Next_1: Mov   Di,Bx                           ;Vergleich ob schon geladen
        Mov   Si,offset Int_11
        CLD
        CMPSB
        Jne   New                             ;Sprung, wenn nicht identisch
        CMPSB                                 ;überspringen des Systemworts
        CMPSB
C_loop: CMPSB
        Jne   New
        Cmp   Si,offset timeflg -1            ;Ende des Vergleichs
        Jl    C_Loop
        Mov   resSEG,Es                       ;hier wenn schon installiert
        Mov   Ax,Bx
        Add   Ax,offset timer - offset int_11
        Mov   timeADR,Ax
        Mov   Ax,Bx
        Add   Ax,offset timeflg - offset int_11
        Mov   timeDTA,Ax
        Mov   Ax,Bx
        Add   Ax,offset syswrd - offset int_11
        Mov   sysDTA,Ax
        Jmp   Option
new:    call  setsib
        call  install

Option: XOR   Ch,Ch
        Mov   Cl,chars                        ;number of charters in param.
        OR    Cl,Cl
        Jle   no_fpu                          ;keine parameter
        Mov   Di,offset param
        Mov   Ax,Ds
        Mov   Es,Ax
        Mov   Al,'-'                          ;scan for switch '-'
scan_l: SCASB
        Jne   no_sw
        Mov   Ah,[Di]                         ;Zeichen nach dem switch char
        Cmp   Ah,'f'                          ;-f option
        Jne   nf
        Mov   fpu,True
        Jmp   nt
nf:     Cmp   Ah,'t'                          ;-t option
        Jne   nt
        Mov   tasking,True
nt:     Inc   Di
no_sw:  Loop  scan_l
        Cmp   fpu,True
        Jne   no_fpu
        Or    syswrd,0000000000000010B        ;fpu im syswrd eintragen
no_fpu: Mov   Es,resSeg
        Mov   Di,timeDTA
        Cmp   tasking,True
        Jne   no_t
        Cmp   Byte PTR Es:[Di],True           ;Tasking gewünscht
        Je    Next_2
        Call  time_on
        Jmp   Next_2
no_t:   Cmp   Byte PTR Es:[Di],False          ;kein Tasking gewünscht
        Je    Next_2
        Call  time_off
Next_2: Mov   Di,sysDTA                       ;neues syswrd setzen
        Mov   Ax,syswrd
        Mov   Es:[Di],Ax

        Cmp   newRun,True                     ;mu¯ res. Teil installiert werden
        Je    ResSet
        Int   20H                             ;normales Ende
ResSet: Mov   Dx,offset mess2                 ;print message
        Mov   Ah,09H
        Int   21H
        Jnc   Next_3
        Jmp   ErrDOS
Next_3: Mov   Dx,offset End_Mark              ;resistenter Teil setzen
        Int   27H
Init    EndP

setsib  PROC NEAR
        mov     al,01                         ;zeiger zum sys.config table
        int     88H
        mov     WORD PTR sib+2,es             ;segment des sib
        mov     bx,es:[bx+0AH]                ;offset des sib
        mov     WORD PTR sib,bx               ;speichern
        ret
setsib  ENDP

time_on Proc Near
        Mov   Bx,0000H                        ;event: 10ms timer
        Mov   Cx,0006                         ;60ms approc. 1/18.2 min
        Mov   Dx,timeADR
        Mov   Di,Ds                           ;Datensegment retten
        Mov   Ax,resSEG
        Mov   Ds,Ax                           ;DS:DX time ProcFar adresse
        Mov   Al,02H                          ;set event trap
        Int   88H
        Cmp   Al,00                           ;00 => kein Fehler
        Je    Ret_0
        Mov   Ds,Di                           ;Datensegment wiederherstellen
        Jmp   ErrBIOS
Ret_0:  Mov   Si,Cs:timeDTA
        Mov   Byte PTR [Si],True              ;timer läuft
        Mov   [Si+1],Bx                       ;QID hinterlassen
        Mov   Ds,Di                           ;Datensegment wiederherstellen
        Ret
time_on EndP

time_off Proc Near
        Mov   Si,timeDTA
        Mov   Es,resSeg
        Mov   Bx,Es:[Si+1]                    ;QID vom timer laden
        Mov   Al,03H                          ;clear event trap
        Int   88H
        Cmp   Al,00                           ;00 => kein Fehler
        Je    Ret_1
        Jmp   ErrBIOS
Ret_1:  Mov   Byte PTR Es:[Si],00             ;timer ausgeschaltet
        Ret
time_off EndP

install Proc Near
        mov   dx,offset Int_12                ;interrupt 12H setzen
        mov   ax,2512H
        int   21H
        jnc   no_er3
        jmp   ErrDOS
no_er3: mov   dx,offset Int_33                ;interrupt 33H setzen
        mov   ax,2533H
        int   21H
        jnc   no_er2
        jmp   ErrDOS
no_er2: mov   Dx,offset Int_10                ;interrupt 10H setzen
        mov   Ax,2510H
        int   21H
        jnc   no_er1
        jmp   ErrDOS
no_er1: mov   dx,offset Int_11                ;interrupt 11H setzen
        mov   ax,2511H
        int   21H
        jnc   no_er0
        jmp   ErrDOS
no_er0: mov   dx,offset Int_16                ;interrupt 11H setzen
        mov   ax,2516H
        int   21H
        jnc   no_err
        jmp   ErrDOS
no_err: mov   dx,offset Int_1C                ;interrupt 1CH setzen
        mov   ax,251CH
        int   21H
        jnc   ret_2
        jmp   ErrDOS
ret_2:  mov   newRun,True                     ;res. Teil installieren
        mov   resSEG,Ds
        mov   timeADR,offset timer
        mov   timeDTA,offset timeflg
        mov   sysDTA,offset syswrd
        ret
Install ENDP

ErrDos  PROC NEAR
        Mov   Dl,Al                           ;Errorcode in ASCII wandlen
        Mov   Al,Ah
        AAA
        Add   [errd1],Ah
        Add   [errd1+1],Al
        Mov   Al,Dl
        AAA
        Add   [errd1+2],Ah
        Add   [errd1+3],Al
        Mov   Dx,offset errd0                 ;print error message
        Mov   Ah,09H
        Int   21H
        Int   20H                             ;terminate
ErrDos  ENDP

ErrBios PROC NEAR
        AAA                                   ;Errorcode in ASCII wandlen
        Add   [errb1],Ah
        Add   [errb1+1],Al
        Mov   Dx,offset errb0                 ;print error message
        Mov   Ah,09H
        Int   21H
        Int   20H                             ;terminate
ErrBIOS ENDP

IBM     ENDS
        END
