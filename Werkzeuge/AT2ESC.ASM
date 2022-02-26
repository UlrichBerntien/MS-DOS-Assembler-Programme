        TITLE *** AT 2 ESCAPE ***
        PAGE 60,132
        .SALL
;---------------------------------------------------------------------
;       MS-Macro-Assmebler v1.10 /Wang PC
;       (c) Ulrich Berntien .02.1990
;           letzte Änderung .06.1990
;
; Entstanden durch ändern von bs2port.
;
; Aufrufformat:
;       AT2ESC <INPUT-FILE-NAME> <OUTPUT-FILE-NAME>
;
; Das Programm setzt den Returncode:
;       00H => kein Fehler
;       01H => ein Fehler selbst gefunden
;       02H => Fehler kam vom DOS
;---------------------------------------------------------------------

BUF_LEN = 0400H
EOF = 019H                  ; end marker im input-buffer
ESC = 1BH                   ; ascii values
BLANK = 20H
AT = '@'
LF = 0AH
CR = 0DH
SWITCH = '-'

;---------------------------------------------------------------------
DATA    SEGMENT
;---------------------------------------------------------------------

FNAME   DB 65 DUP (?)                         ; Zwischenspeicher für dateinamen

INFILE  DW (?)                                ; file handle
OUTFILE DW (?)
BUF     DB BUF_LEN+1 DUP (?)                  ; buffer + end marker

DOS_ERR_TABLE = THIS WORD
        DW OFFSET DOS_00
        DW OFFSET DOS_01
        DW OFFSET DOS_02
        DW OFFSET DOS_03
        DW OFFSET DOS_04
        DW OFFSET DOS_05
        DW OFFSET DOS_06
        DW OFFSET DOS_07
        DW OFFSET DOS_08
        DW OFFSET DOS_09
        DW OFFSET DOS_0A
        DW OFFSET DOS_0B
        DW OFFSET DOS_0C
        DW OFFSET DOS_0D
        DW OFFSET DOS_0E
        DW OFFSET DOS_0F
        DW OFFSET DOS_10
        DW OFFSET DOS_11
        DW OFFSET DOS_12

DOSERR  DB 'DOS-ERROR: $'

DOS_00  DB 'no error ocurred$'
DOS_01  DB 'invalid function$'
DOS_02  DB 'file not found$'
DOS_03  DB 'path not found$'
DOS_04  DB 'too many open file$'
DOS_05  DB 'access denied$'
DOS_06  DB 'invalid handle$'
DOS_07  DB '$'
DOS_08  DB '$'
DOS_09  DB '$'
DOS_0A  DB '$'
DOS_0B  DB '$'
DOS_0C  DB 'invalid access$'
DOS_0D  DB 'invalid data$'
DOS_0E  DB 'unknown error code$'
DOS_0F  DB 'invalid drive$'
DOS_10  DB 'current directory$'
DOS_11  DB '$'
DOS_12  DB '$'

OWN_01  DB 'fehler beim file schreiben$'
OWN_02  DB 'unbekannter schalter$'

CRLF    DB 0AH,0DH,'$'

DATA    ENDS

;---------------------------------------------------------------------
CODE    SEGMENT
;---------------------------------------------------------------------
ASSUME CS : CODE, DS : DATA

        ; Register DS,CS,SS bleiben in allen Procs unverändert
        ; DI wird nur für Zugriff auf BUF benutzt

;---------------------------------------------------------------------
DOS     MACRO
        CLC
        INT   21H                             ;; call DOS
        CALL  CHK_DOS                         ;; testet auf Fehler
        ENDM

; L00XX---------------------------------------------------------------
MAIN    PROC NEAR
        CLD                                   ; alles in positiver Richtung
        MOV   CX,SEG DATA
        MOV   DS,CX                           ; DS auf den richtigen Wert
        CALL  INIT                            ; Parameter auswerten
        XOR   DI,DI                           ; alle Zeiger auf Null

L0002:  CALL  READ_FILE                       ; einlesn
        CMP   BYTE PTR [BUF],EOF              ; buffer ist ganz leer
        JE    L0004                           ; d.h. file zu ende
L0006:  MOV   AL,[BUF+DI]
        CMP   AL,AT                           ; at durch esc ersetzen
        JNE   L0003
        MOV   [BUF+DI],ESC
L0003:  INC   DI                              ; auf nächstes zeichen
        CMP   AL,EOF                          ; buffer am ende ?
        JNE   L0006
        DEC   DI
        CALL  WRITE_FILE                      ; buffer wegschreiben
        JMP   L0002
L0004:  CALL  TERM
L0005:  MOV   AX,4C00H                        ; exit from a process
        DOS
        JMP   L0005
MAIN    ENDP

; L04XX --------------------------------------------------------------
INIT    PROC NEAR
              ; Parameter auswerten, File öffnen
              ; nur Segemnt Register werden erhalten

        MOV   CL,[ES:0080H]                   ; char# in parameter
        XOR   CH,CH                           ; cx := cl
        MOV   SI,0081H                        ; erstes Zeichen im Parameter
        CALL  SCHALTER                        ; lesen und auswerten der switchs

        CALL  MOV_NAME                        ; Dateiname lesen
        MOV   DX,OFFSET FNAME
        MOV   AX,3D00H                        ; open file for reading
        DOS
        MOV   INFILE,AX                       ; store file handle

        CALL  MOV_NAME                        ; Dateinamen lesen
        JMP   OPEN_OUTFILE                    ; file öffnen für ausgabe
                                              ; und Return
INIT    ENDP

; L0BXX --------------------------------------------------------------
SCHALTER PROC NEAR
              ; Auswerten der Switchs
              ; aktualisiert CX, SI
              ; alle anderen Register bleiben erhalten

        PUSH  AX                              ; backup register
L0B00:  MOV   AL,ES:[SI]
        INC   SI                              ; auf nächstes Zeichen
        DEC   CX
        JS    L0B01                           ; keine Zeichen mehr da
        CMP   AL,BLANK
        JNA   L0B00                           ; ein Steuerzeichen, Leerzeichen

        CMP   AL,SWITCH
        JNE   L0B01                           ; kein Switch da

        MOV   DX,OFFSET OWN_02                ; unbekannter switch
        JMP   OWN_ERR

L0B01:  DEC   SI                              ; wurde nicht mehr ausgewertet
        INC   CX
        POP   AX                              ; restore register
        RET
SCHALTER ENDP

; L07XX --------------------------------------------------------------
MOV_NAME PROC NEAR
              ; überträgt einen filename von ES:SI nach FNAME
              ; max. CX Zeichen werden gelesen, CX wird aktualisiert
              ; SI wird auf das Zeichen hinter den Filename gesetzt
              ; alle anderen Register belieben unverändert

        PUSH  AX                              ; backup register
        PUSH  DI
        MOV   DI,DS                           ; DS und ES vertauschen
        MOV   AX,ES
        MOV   DS,AX
        MOV   ES,DI
        MOV   DI,OFFSET FNAME                 ; dorthin der name

L0700:  LODSB
        DEC   CX
        JS    L0702                           ; keine Zeichen mehr da
        CMP   AL,BLANK
        JNA   L0700                           ; ein Soderzeichen,Leerzeichen

L0703:  STOSB                                 ; Zeichen speichern
        LODSB                                 ; nächstes Zeichen lesen
        DEC   CX
        JS    L0702                           ; keine Zeichen mehr da
        CMP   AL,BLANK
        JA    L0703                           ; ein Zeichen für Filenamen

L0702:  INC   CX                              ; letztes wurde nicht verwendet
        DEC   SI
        XOR   AL,AL                           ; ASICIZ format
        STOSB
        MOV   DI,DS                           ; DS und ES vertauschen
        MOV   AX,ES
        MOV   DS,AX
        MOV   ES,DI
        POP   AX                              ; restore register
        POP   DI
        RET
MOV_NAME ENDP

; L06XX --------------------------------------------------------------
TERM    PROC NEAR
              ; files schließen

        MOV   BX,OUTFILE                      ; file handle des ausgabefiles
        MOV   AH,3EH                          ; close a file
        DOS
        MOV   BX,INFILE                       ; file handle des eingabfiles
        MOV   AH,3EH                          ; close a file
        DOS
        RET
TERM    ENDP

; L0AXX --------------------------------------------------------------
OPEN_OUTFILE PROC NEAR
              ; öffnet das ausgabefile
              ; der name des files muß in FNAME stehen (asciz-foramt)
              ; der file handle wird in OUTFILE abgespeichert
              ; alle register bleiben erhalten

        PUSH  AX                              ; backup register
        PUSH  BX
        PUSH  CX
        PUSH  DX
        MOV   DX,OFFSET FNAME                 ; auf filenamen

        XOR   CX,CX                           ; kein attribut
        MOV   AH,3CH                          ; create file
        DOS
        MOV   OUTFILE,AX                      ; file handle sichern

        POP   DX
        POP   CX
        POP   BX
        POP   AX
        RET
OPEN_OUTFILE ENDP

; L02XX --------------------------------------------------------------
READ_FILE PROC NEAR
              ; einlesen aus dem Eingabefile in den Buffer
              ; di = 0, alle anderen Register werden nicht verändert
              ; setzt EOF nach letztem gelesenen Zeichen

        PUSH  AX                              ; backup register
        PUSH  BX
        PUSH  CX
        PUSH  DX
        MOV   BX,INFILE                       ; file handle
        MOV   CX,BUF_LEN
        MOV   DX,OFFSET BUF
        MOV   AH,3FH                          ; read a file
        DOS
        MOV   BX,AX
        MOV   [BX+BUF],EOF                    ; end marker sezten
        XOR   DI,DI                           ; auf nächstes Bytes zum einlesen
        POP   DX                              ; restore register
        POP   CX
        POP   BX
        POP   AX
        RET
READ_FILE ENDP

; L03XX --------------------------------------------------------------
WRITE_FILE PROC NEAR
              ; schreiben aus dem Ausgabebuffer in das Ausgabefile
              ; DI gibt die Anzahl der Bytes, wird aktuallisiert
              ; alle anderen Register werden nicht verändert

        PUSH  AX                              ; backup register
        PUSH  BX
        PUSH  CX
        PUSH  DX
        MOV   BX,OUTFILE                      ; file handle
        MOV   CX,DI
        MOV   DX,OFFSET BUF
        MOV   AH,40H                          ; write a file
        DOS
        CMP   AX,CX
        JE    L0300                           ; alles wurde geschrieben
        MOV   DX,OFFSET OWN_01
        JMP   OWN_ERR                         ; Fehler, anzahl der bytes falsch
L0300:  POP   DX                              ; restore register
        POP   CX
        POP   BX
        POP   AX
        RET
WRITE_FILE ENDP

; L05XX --------------------------------------------------------------
OWN_ERR PROC NEAR
              ; DX zeigt auf einen Fehler Text
              ; dieser wird ausgegeben, danach das Programm beendet

        MOV   AH,09H                          ; print a string
        DOS
        MOV   DX,OFFSET CRLF
        MOV   AH,09H
        DOS
L0501:  MOV   AX,4C01H                        ; exit from a process
        DOS                                   ; errorcode = 01
        JMP   L0501
OWN_ERR ENDP

; L01XX --------------------------------------------------------------
CHK_DOS PROC NEAR
              ; wird sofort nach einem DOS-Call aufgerufen
              ; bei einem Fehler: Ausagabe der Meldung, und Programmabbruch

        JC    L0104                           ; wenn DOS Fehler meldet
        RET
L0104:  CMP   AX,00H
        JG    L0101
        JNE   L0100
        RET                                   ; doch kein Fehler
L0100:  MOV   AX,000EH                        ; unbekannter Fehlercode
L0101:  CMP   AX,12H
        JL    L0102
        MOV   AX,000EH                        ; unbekannter Fehlercode
L0102:  SHL   AX,1                            ; in Word-address
        MOV   DI,AX                           ; in di sichern
        MOV   DX,OFFSET DOSERR
        MOV   AH,09H
        INT   21H
        MOV   DX,[DI+DOS_ERR_TABLE]           ; Addresse des Fehler Textes
        MOV   AH,09H                          ; print a string
        INT   21H
        MOV   DX,OFFSET CRLF
        MOV   AH,09H
        INT   21H
L0103:  MOV   AX,4C02H                        ; exit from a process
        INT   21H                             ; errorcode = 02
        JMP   L0103
CHK_DOS ENDP

CODE    ENDS

;---------------------------------------------------------------------
STACK   SEGMENT STACK
        DB 0200H DUP (?)
STACK   ENDS

        END   MAIN
