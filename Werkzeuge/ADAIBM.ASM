; Wang PC / MS-Macro-Assembler V1.0
; (c) Ulrich Berntien .09.1988

; Stellt die Interrupt Vektoren 11H, 1CH aus dem IBM-BIOS zur Verfügung
; nach Instalation ist das Ada von Meridian auf dem Wang PC lauffähig
;
; Aufrufformat: IBMADA [-t] [-f]
; Optinen: -f => Floating Point Processor (8087) kann benutzt werden
;          -t => Timer Interrupt ist aktiv für Ada Tasking
; Gross/Kleinschreibung beachten !

;Beschreibung der Interrupt Vectoren (siehe MC Februar 1988)
;
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
;
;INT 1CH : Timer-Interrupt
;Wird 18.2 mal pro Sekunde angesprungen. Benutzerprogramme, die den Vektor
;umleiten, sollten am Ende der Routine zur bisherigen Adresse springen.

;-------------------------------------------------------------------------------

IBMADA  Segment
        Assume Ds:IBMADA,Cs:IBMADA

True    = Byte PTR 01
False   = Byte PTR 00

        ORG 0080H
chars   DB ?                                  ;Anzahl der Zeichen im Parameter
param   DB ?                                  ;parameter der Aufrufzeile
        ORG 0100H
        Jmp   Init

;-------------------------------------------------------------------------------
; RESIDENT PART:

Int_11  Proc Far                              ;Hard-ware test
        DB    0B8H                            ;Mov Ax,????
syswrd  DW    0100001001110101B
           ;  5432109876543210
        IRet
Int_11  EndP

Int_1C  Proc Far                              ;timer-interrupt
        IRet
Int_1C  EndP

timer   Proc Far                              ;Aufruf des Int 1C
        Int   1CH
        Ret
timer   EndP

timeflg DB False                              ;01H => timer interrupt is on
QID     DW 0000H                              ;    trap queue identification no

End_Mark: NOP

;-------------------------------------------------------------------------------

resSeg  DW 0000H                              ;Segment des residenten Teils
timeADR DW 0000H                              ;Adresse der timer ProcFar
timeDTA DW 0000H                              ;Adresse der Daten für timer
sysDTA  DW 0000H                              ;Adresse des Systemdatenworts

newRun  DB False                              ;01 => res. Teil wird installiert
fpu     DB False                              ;01 => -f is set
tasking DB False                              ;01 => -t is set

mess1   DB 'ADA runtime bios ext. (c) Ulrich Berntien 1988',0DH,0AH,'$'
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
        Jl    C_loop
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
New:    Call  Install

Option: Xor   Ch,Ch
        Mov   Cl,chars                        ;number of charters in param.
        Cmp   Cl,0
        Jle   no_para                         ;keine parameter
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
no_para:Cmp   fpu,True
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

        Cmp   newRun,True                     ;muß res. Teil installiert werden
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
Ret_1:  Mov   Byte PTR Es:[Si],False          ;timer ausgeschaltet
        Ret
time_off EndP

Install Proc Near
        Mov   Dx,offset Int_11                ;interrupt 11H setzen
        Mov   Ax,2511H
        Int   21H
        Jnc   No_err
        Jmp   ErrDOS
No_err: Mov   Dx,offset Int_1C                ;interrupt 1CH setzen
        Mov   Ax,251CH
        Int   21H
        Jnc   Ret_2
        Jmp   ErrDOS
Ret_2:  Mov   newRun,True                     ;res. Teil installieren
        Mov   resSEG,Ds
        Mov   timeADR,offset timer
        Mov   timeDTA,offset timeflg
        Mov   sysDTA,offset syswrd
        Ret
Install EndP

ErrDos  Proc Near
        Mov   Dl,Ah                           ;Errorcode in ASCII wandlen
        AAA
        Add   [errd1+2],Ah
        Add   [errd1+3],Al
        Mov   Al,Dl
        AAA
        Add   [errd1],Ah
        Add   [errd1+1],Al
        Mov   Dx,offset errd0                 ;print error message
        Mov   Ah,09H
        Int   21H
        Int   20H                             ;terminate
ErrDos  EndP

ErrBios Proc Near
        AAA                                   ;Errorcode in ASCII wandlen
        Add   [errb1],Ah
        Add   [errb1+1],Al
        Mov   Dx,offset errb0                 ;print error message
        Mov   Ah,09H
        Int   21H
        Int   20H                             ;terminate
ErrBIOS EndP

IBMADA  EndS
        END
