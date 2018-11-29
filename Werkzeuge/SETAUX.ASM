        TITLE *** SETAUX ***
        PAGE 60,132
;---------------------------------------------------------------------
;       MS-Macro-Assembler V1.10 /Wang PC
;       (c) Ulrich Berntien .04.1989
;           letzte Änderung .03.1990
;
; Einstellen der seriellen Schnittstelle des Wang PC
; Aufrufformat:
;     SETAUX <BAUDRATE> <DATABITS> <STOPBITS> <PARITY>
; alle Parameter sind Ganzezahlen, die Bedeutung ist aus den Tabellen
; im Datenteil ersichtlich.
; Die Parameter werden durch Leerzeichen und/oder TAB's getrennt.
;
; Das Programm setzt den Returncode:
;       00H => kein Fehler aufgetreten
;       01H => ein Fehler aufgetreten
;---------------------------------------------------------------------

BLANK = 20H                   ; ascii-values
TAB = 09H
AUX_CTR = 108CH               ; Port zum einstellen der Schnittstelle
AUX_2   = 108EH
AUX_3   = 1086H
TERMINATOR = 0FFFFH           ; mit diesm Word werden die Tabellen beendet
;---------------------------------------------------------------------
DATA    SEGMENT
;---------------------------------------------------------------------

BAUD    DW  110D              ; Tabelle der möglichen Baudraten
        DW  150D
        DW  300D
        DW  600D
        DW 1200D
        DW 2400D
        DW 4800D
        DW 9600D
        DW TERMINATOR

BAUD_CODE = THIS BYTE         ; Codes für die Baudraten
        DB 032H,034H,035H,036H,037H,03AH,03CH,03EH

DATABIT DW 7D
        DW 8D
        DW TERMINATOR

DATABIT_CODE = THIS BYTE
        DB 009H,00DH

PARITY  DW 0D                 ; non parity
        DW 1D                 ; parity even
        DW 2D                 ; parity odd
        DW TERMINATOR

PARITY_CODE = THIS BYTE       ; Codes für das Paritybit
        DB 000H,010H,030H

STOP    DW 1D
        DW 2D
        DW 3D
        DW TERMINATOR

STOP_CODE = THIS BYTE
        DB 040H,0C0H,080H

FIRST   DB 00H                ; Speicher für den Code an die Schnittstelle
SECOND  DB 00H

ERR_01  DB 'Zahl für Baudrate nicht lesbar$'
ERR_02  DB 'falsche Baudrate$'
ERR_03  DB 'Zahl für Databits nicht lesbar$'
ERR_04  DB 'nur 7 oder 8 Datenbits$'
ERR_05  DB 'Zahl für Stopbits nicht lesbar$'
ERR_06  DB 'Für Stopbit nur 1,2 oder 3 gültig$'
ERR_07  DB 'Zahl für Parity nicht lesbar$'
ERR_08  DB 'Für Parity nur 0,1,2 gültig$'

OK_TEXT DB 'AUX gesetzt$'

CRLF    DB 0DH,0AH,'$'

DATA    ENDS

;---------------------------------------------------------------------
CODE    SEGMENT
;---------------------------------------------------------------------
        ASSUME ES : DATA, CS : CODE, SS : STACK
        ; ES,CS,DS werden von den Proc's nicht verändert
        ; Destinationflag ist immer gelöscht

; L00xx --------------------------------------------------------------
MAIN    PROC NEAR
        MOV   AX,SEG DATA                     ; ES := richtiger Wert
        MOV   ES,AX
        CLD                                   ; alle Richtungen positiv
        MOV   CL,01                           ; pessimist, Fehlercode
        MOV   SI,0081H                        ; auf die Parameter
        CALL  READNUM                         ; baudrate lesen
        JNC   L0000
        MOV   DX,OFFSET ERR_01
        JMP   MESSAGE
L0000:  MOV   DI,OFFSET BAUD
        MOV   BX,OFFSET BAUD_CODE
        CALL  GETTABLE                        ; code für baudrate
        JNC   L0001
        MOV   DX,OFFSET ERR_02
        JMP   MESSAGE
L0001:  MOV   SECOND,AL
        CALL  READNUM                         ; #databits lesen
        JNC   L0002
        MOV   DX,OFFSET ERR_03
        JMP   MESSAGE
L0002:  MOV   DI,OFFSET DATABIT
        MOV   BX,OFFSET DATABIT_CODE
        CALL  GETTABLE                        ; code für #datenbits
        JNC   L0003
        MOV   DX,OFFSET ERR_04
        JMP   MESSAGE
L0003:  MOV   FIRST,AL
        CALL  READNUM                         ; #stopbits lesen
        JNC   L0004
        MOV   DX,OFFSET ERR_05
        JMP   MESSAGE
L0004:  MOV   DI,OFFSET STOP
        MOV   BX,OFFSET STOP_CODE
        CALL  GETTABLE                        ; code für stopbits
        JNC   L0005
        MOV   DX,OFFSET ERR_06
        JMP   MESSAGE
L0005:  OR    FIRST,AL
        CALL  READNUM                         ; parity lesen
        JNC   L0006
        MOV   DX,OFFSET ERR_07
        JMP   MESSAGE
L0006:  MOV   DI,OFFSET PARITY
        MOV   BX,OFFSET PARITY_CODE
        CALL  GETTABLE                        ; code für parity
        JNC   L0007
        MOV   DX,OFFSET ERR_08
        JMP   MESSAGE
L0007:  OR    FIRST,AL
        CALL  SET                             ; schnittstelle konfigurieren
        MOV   DX,OFFSET OK_TEXT
        XOR   CL,CL                           ; Returncode 00, alles ok
        JMP   MESSAGE
MAIN    ENDP

; L01xx --------------------------------------------------------------
SET     PROC NEAR
              ; gibt die Bytes in FIRST,SECOND auf den Port
              ; alle Register werden erhalten

        PUSH  AX                              ; backup register
        PUSH  DX

        MOV   DX,AUX_2                        ; aus SER1DRVR übernommen
        MOV   AL,22H
        OUT   DX,AL
        MOV   DX,AUX_2
        MOV   AL,22H
        OUT   DX,AL
        MOV   DX,AUX_2
        MOV   AL,22H
        OUT   DX,AL
        MOV   DX,AUX_3
        IN    AL,DX

        MOV   DX,AUX_CTR                      ; port adresse
        MOV   AL,FIRST
        OUT   DX,AL
        MOV   AL,SECOND
        OUT   DX,AL                           ; beide bytes ausgeben

        MOV   DX,AUX_2
        MOV   AL,26H
        OUT   DX,AL

        POP   DX                              ; restore register
        POP   AX
        RET
SET     ENDP

; L02xx --------------------------------------------------------------
READNUM PROC NEAR
              ; liest eine Ganzezahl ab Adresse DS:SI
              ; die Zahl wird in AX zurück gegeben
              ; falls ein Fehler auftrat ist das CARY-flag gesetzt
              ; SI zeigt danach auf das erste Zeichen hinter der Zahl
              ; alle anderen Register beliben erhalten
        PUSH  BX
        PUSH  CX
        PUSH  DX
        XOR   BH,BH                           ; immer bx = bl
        MOV   CX,10D                          ; basis der zahl
L0201:  MOV   BL,[DS:SI]
        INC   SI
        CMP   BL,BLANK                        ; die Trennungszeichen überlesen
        JE    L0201
        CMP   BL,TAB
        JE    L0201
        CMP   BL,'0'
        JB    L0203                           ; unterhalb der ziffern
        CMP   BL,'9'
        JA    L0203                           ; überhalb der ziffern
        SUB   BL,'0'                          ; ascii in ziffernwert
        MOV   AX,BX                           ; erste ziffer
L0202:  MOV   BL,[DS:SI]                      ; nächstes Zeichen in BL
        INC   SI
        CMP   BL,'0'
        JB    L0204                           ; keine ziffer mehr
        CMP   BL,'9'
        JA    L0204                           ; keine ziffer mehr
        MUL   CX                              ; eine stelle verschieben
        JC    L0200                           ; überlauf
        SUB   BL,'0'                          ; ascii in ziffernwert
        ADD   AX,BX
        JMP   L0202                           ; in schleife
L0203:  DEC   DI                              ; zeichen nicht verarbeitbar
        STC                                   ; fehlerhafte zahl
        JMP   L0200
L0204:  CLC                                   ; alles gut gelaufen
L0200:  POP   DX
        POP   CX
        POP   BX
        RET
READNUM ENDP

; L03xx --------------------------------------------------------------
GETTABLE PROC NEAR
              ; AX wird in der Tabelle ab ES:DI gesucht
              ; AL wird der korospondierende  Wert aus der Tabelle ab ES:BX
              ;   zugewiesen
              ; die Tabell ist der Größe nach aufsteigend geordnet
              ; ist CARY-flag beim Rücksprung gestzt, so wirde AX nicht gefunden
              ; nur das AL Register wird verändert

        PUSH  BX                              ; backup register
        PUSH  DI
        CMP   AX,TERMINATOR
        JNE   L0302
        STC                                   ; AX hat ungültigen Wert
        JMP   L0303
L0304:  INC   BX
L0302:  SCASW                                 ; vergleich mit Tabelle
        JE    L0301
        JG    L0304
        STC                                   ; Fehler, nicht in der Tabelle
        JMP   L0303
L0301:  MOV   AL,ES:[BX]                      ; Code gefunden
        CLC                                   ; keine Fehler
L0303:  POP   DI                              ; restore register
        POP   BX
        RET
GETTABLE ENDP

; L04xx --------------------------------------------------------------
MESSAGE PROC NEAR
              ; gibt den String aus, aufden ES:DX zeigt
              ; beendet danach das Programm
              ; gibt CL als Returncode an das DOS

        MOV   AX,ES
        MOV   DS,AX                           ; ds := es
        MOV   AH,09H                          ; print a string
        INT   21H                             ; DOS call
        MOV   DX,OFFSET CRLF                  ; zeile beenden
        MOV   AH,09H                          ; print a string
        INT   21H
        MOV   AL,CL                           ; error code
L0400:  MOV   AH,4CH                          ; exit form process
        INT   21H
        JMP   L0400                           ; sicher ist sicher
MESSAGE ENDP

CODE    ENDS

;---------------------------------------------------------------------
STACK   SEGMENT STACK
;---------------------------------------------------------------------
        DB 0100H DUP (?)
STACK   ENDS

        END   MAIN
