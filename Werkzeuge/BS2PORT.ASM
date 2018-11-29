        TITLE *** BS2000 - PORT ***
        PAGE 60,132
        .SALL
;---------------------------------------------------------------------
;       MS-Macro-Assmebler v1.10 /Wang PC
;       (c) Ulrich Berntien .04.1989
;           letzte Änderung .06.1990
; Umwandlung eines WISCII-Files in ein ASCII-File gegeignet zum
; übertragen auf einen BS2000 Rechner.
; Wenn die Übertragung mit RDAC erfolgt, so müssen danach die Leerzeilen
; wieder aufbereitet werden.
;
; Aufrufformat:
;       BS2PORT [SWITCH] <WISCII-FILE-NAME> <ASCII-FILE-NAME>
;
; Switch: (unabhängig von Groß/kleinschreibweise)
;       -A  : an das bestehende Ausgabefile anhängen
;       -P  : EBCEDIC Steuerzeichen in erste Spalte für FF,LF
;
; Das Programm setzt den Returncode:
;       00H => kein Fehler
;       01H => ein Fehler selbst gefunden
;       02H => Fehler kam vom DOS
;---------------------------------------------------------------------

INBUF_LEN = 0200H
OUTBUF_LEN = 0200H
EOF = 019H                  ; end marker im input-buffer
TAB = 09H                   ; ascii values
BACKSPACE = 08H
BLANK = 20H
LF = 0AH
CR = 0DH
SWITCH = '-'

;---------------------------------------------------------------------
DATA    SEGMENT
;---------------------------------------------------------------------

FNAME   DB 65 DUP (?)                         ; Zwischenspeicher für dateinamen

INFILE  DW (?)                                ; file handle
INCOUNT DW (?)                                ; number of bytes im buffer
INBUF   DB INBUF_LEN+1 DUP (?)                ; buffer + end marker

OUTFILE DW (?)                                ; file handle
OUTBUF  DB OUTBUF_LEN DUP (?)                 ; buffer

APPEND  DB 00H                                ; 01H, wenn -A switch gesetzt
EBCEDIC DB 00H                                ; 01H, wenn -P switch gesetzt
SPALTE DB 00                                  ; aktuelle eingabespalte

SONDERZEICHEN LABEL BYTE                      ; Tabelle der zu übersetzenden
        DB BACKSPACE,TAB,LF,0CH               ; Zeichen, dem Wert nach geordnet
        DB 'Ä','ä','Ö','ö','Ü','ü','ß'
        DB 0FFH                               ; terminiert die liste

        EVEN

TRANSFORMER LABEL WORD                        ; verknüpft Sonderzeichen-tabelle
        DW OFFSET CHARNULL
        DW OFFSET TAB_CHAR                    ; mit den Umsetzungs Codes
        DW OFFSET LF_CHAR
        DW OFFSET FF_CHAR
        DW OFFSET GA_UMLAUT
        DW OFFSET KA_UMLAUT
        DW OFFSET GO_UMLAUT
        DW OFFSET KO_UMLAUT
        DW OFFSET GU_UMLAUT
        DW OFFSET KU_UMLAUT
        DW OFFSET SS_UMLAUT
        DW OFFSET CHARNULL

TAB_CHAR  DW OFFSET TABZEICHEN                ; dorthin zur verarbeitung
LF_CHAR   DW OFFSET PZEICHEN
          DB LF,BLANK                         ; daten für die routine
FF_CHAR   DW OFFSET PZEICHEN
          DB BACKSPACE,'A'
GA_UMLAUT DW OFFSET ZWEIZEICHEN
          DB 'Ae'
KA_UMLAUT DW OFFSET ZWEIZEICHEN
          DB 'ae'
GO_UMLAUT DW OFFSET ZWEIZEICHEN
          DB 'Oe'
KO_UMLAUT DW OFFSET ZWEIZEICHEN
          DB 'oe'
GU_UMLAUT DW OFFSET ZWEIZEICHEN
          DB 'Ue'
KU_UMLAUT DW OFFSET ZWEIZEICHEN
          DB 'ue'
SS_UMLAUT DW OFFSET ZWEIZEICHEN
          DB 'ss'
CHARNULL  DW OFFSET NULLZEICHEN

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
DOS_07  DB 'memory block bad$'
DOS_08  DB 'not enough memory$'
DOS_09  DB 'invalid block$'
DOS_0A  DB 'bad enviroment$'
DOS_0B  DB 'bad format$'
DOS_0C  DB 'invalid access$'
DOS_0D  DB 'invalid data$'
DOS_0E  DB 'unknown error code$'
DOS_0F  DB 'invalid drive$'
DOS_10  DB 'current directory$'
DOS_11  DB 'not same device$'
DOS_12  DB 'no more files$'

OWN_01  DB 'fehler beim file schreiben$'
OWN_02  DB 'unbekannter schalter$'

CRLF    DB 0AH,0DH,'$'

DATA    ENDS

;---------------------------------------------------------------------
CODE    SEGMENT
;---------------------------------------------------------------------
ASSUME CS : CODE, DS : DATA

        ; Register DS,CS,SS bleiben in allen Procs unverändert
        ; DI wird nur für Zugriff auf OUTBUF benutzt
        ; SI wird nur für Zugriff auf INBUF benutzt
        ; BP enthält die Ausgabe Spalte (für TAB)

;---------------------------------------------------------------------
DOS     MACRO
        LOCAL NO_ERROR
        CLC
        INT   21H                             ;; call DOS
        JNC   NO_ERROR
        CALL  ERR_DOS                         ;; testet auf Fehler
NO_ERROR:
        ENDM

; L00XX---------------------------------------------------------------
MAIN    PROC NEAR
        CLD                                   ; alles in positiver Richtung
        MOV   CX,SEG DATA
        MOV   DS,CX                           ; DS auf den richtigen Wert
        CALL  INIT                            ; Parameter auswerten
        XOR   DI,DI                           ; alle Zeiger auf Null
        XOR   SI,SI
        XOR   BP,BP                           ; Ausgabespalte := 0

L0002:  CALL  READ_FILE                       ; einlesn
L0003:  MOV   AL,[INBUF+SI]
        CMP   AL,EOF                          ; end marker gefunden ?
        JE    L0000
L0004:  INC   SI                              ; auf nächstes Eingabezeichen
        CALL  OUTPUT                          ; AL ausgeben
        JMP   L0003                           ; Schleife

L0000:  CMP   SI,INCOUNT
        JL    L0004                           ; kein Endmarker vom Programm
        CMP   SI,0                            ; ende der datei erreicht ?
        JNE   L0002
        CALL  TERM
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
        MOV   AL,ES:[SI]
        INC   SI
        DEC   CX
        JS    L0B02                           ; kein Zeichen danach

        AND   AL,11011111B                    ; in Großbuchastaben
        CMP   AL,'A'
        JNE   L0B03
        MOV   APPEND,01H                      ; append-switch gefunden
        JMP   L0B00                           ; weiter suchen
L0B03:  CMP   AL,'P'
        JNE   L0B02
        MOV   EBCEDIC,01H                     ; EBCEDIC-switch gefunden
        JMP   L0B00                           ; weiter suchen

L0B02:  MOV   DX,OFFSET OWN_02                ; unbekannter switch
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
              ; alle anderen Register belieben unverúndert

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
              ; rest des ausgabe buffers schreiben
              ; files schließen

        CMP   DI,0
        JE    L0600
        CALL  WRITE_FILE                      ; rest des schreiben

L0600:  MOV   BX,OUTFILE                      ; file handle des ausgabefiles
        MOV   AH,3EH                          ; close a file
        DOS
        MOV   BX,INFILE                       ; file handle des eingabfiles
        MOV   AH,3EH                          ; close a file
        DOS
        RET
TERM    ENDP

; L08XX --------------------------------------------------------------
OUTPUT  PROC NEAR
              ; gibt zeichen in AL aus
              ; erhält nur DI,SI,BP Register

        XOR   BX,BX
L0801:  INC   BX
        CMP   AL,[SONDERZEICHEN-1+BX]         ; testen auf Sonderzeichen
        JA    L0801                           ; weitersuchen
        JE    L0800                           ; ein Sonderzeichen
        INC   SPALTE
L0802:  CALL  AL_INBUF
        RET

L0800:  SHL   BX,1                            ; zum word-adressieren
        MOV   BX,[TRANSFORMER-2+BX]
        JMP   WORD PTR [BX]                   ; WORD PTR nicht vergessen !!!!

PZEICHEN:
        MOV   SPALTE,0
        CMP   EBCEDIC,01H                     ; nur wenn -P gesetzt ist
        JNE   L0802
        JMP   SHORT L0804
                                              ; dann zwei Zeichen ausgeben
ZWEIZEICHEN:                                  ; gibt zwei Zeichen aus dem
        ADD   SPALTE,+2
L0804:  MOV   AX,[BX+2]                       ; Datenteil aus
        CALL  AL_INBUF                        ; erstes Zeichen
        MOV   AL,AH
        JMP   L0802                           ; zweites Zeichen und zurück

TABZEICHEN:                                   ; Tabulaturfunktion
        MOV   AL,SPALTE                       ; aktuelle Ausgabespalte
        AND   AL,0111B                        ; 8,16,24,.. sind TAB-Position
        MOV   CL,1000B
        SUB   CL,AL                           ; so viele fehlen noch
        XOR   CH,CH                           ; CX := CL
        ADD   SPALTE,CL
        MOV   AL,BLANK
L0803:  CALL  AL_INBUF                        ; bis Position erreicht auffüllen
        LOOP  L0803
        RET

NULLZEICHEN:                                  ; Zeichen ignorieren
        RET
OUTPUT  ENDP

; L09XX --------------------------------------------------------------
AL_INBUF PROC NEAR
              ; gibt das Zeichen in AL in den Buffer
              ; aktuallisiert DI, alle anderen Register beleiben erhalten
              ; wenn Buffer voll ist wird in die Datei geschrieben

        CMP   AL,CR                           ; CR wird besonders behandelt
        JE    L0901
        CMP   AL,BACKSPACE
        JE    L0907
        CMP   AL,BLANK                        ; auf Steuerzeichen testen (zB.LF)
        JL    L0902
        INC   BP                              ; nächste Ausgabespalte
L0902:  MOV   [OUTBUF+DI],AL                  ; in den Ausgabebuffer
        INC   DI
        CMP   DI,OUTBUF_LEN
        JGE   L0900                           ; buffer voll
        RET

L0900:  CALL  WRITE_FILE                      ; buffer ist voll, also schreiben
        RET

L0901:  CMP   AL,[OUTBUF-1+DI]
        JNE   L0906
        RET                                   ; doppeltes CR wird gelöscht

L0907:  DEC   BP                              ; backspace gefunden
        DEC   DI
        JS    L0903
        RET                                   ; könnte noch gelöscht werden
L0908:  INC   DI
        JMP   L0902

L0906:  DEC   DI                              ; Vielfache Blanks vor Zeilenende
        JS    L0903                           ; löschen, wenn noch im Buffer
        CMP   [OUTBUF+DI],BLANK
        JNE   L0903
L0904:  DEC   DI
        JS    L0905
        CMP   [OUTBUF+DI],BLANK
        JE    L0904

L0905:  INC   DI
L0903:  INC   DI
        XOR   BP,BP                           ; Ausgabespalte := 0
        JMP   L0902
AL_INBUF ENDP

; L0AXX --------------------------------------------------------------
OPEN_OUTFILE PROC NEAR
              ; öffnet das ausgabefile
              ; der name des files muß in FNAME stehen (asciz-foramt)
              ; der file handle wird in OUTFILE abgespeichert
              ; berücksichtigt APPEND
              ; alle register bleiben erhalten

        PUSH  AX                              ; backup register
        PUSH  BX
        PUSH  CX
        PUSH  DX
        MOV   DX,OFFSET FNAME                 ; auf filenamen

        CMP   APPEND,01H
        JE    L0A01
        XOR   CX,CX                           ; kein attribut
        MOV   AH,3CH                          ; create file
        DOS
        MOV   OUTFILE,AX                      ; file handle sichern
        JMP   L0A00

L0A01:  MOV   AX,3D01H                        ; open file for writing
        DOS
        MOV   OUTFILE,AX                      ; file handle sichern
        MOV   BX,AX
        XOR   CX,CX                           ; CX:DX := 0
        XOR   DX,DX
        MOV   AX,4202H                        ; write pointer to EOF + cx,dx
        DOS

L0A00:  POP   DX                              ; restore register
        POP   CX
        POP   BX
        POP   AX
        RET
OPEN_OUTFILE ENDP

; L02XX --------------------------------------------------------------
READ_FILE PROC NEAR
              ; einlesen aus dem Eingabefile inden Eingabebuffer
              ; SI wird aktuallisiert
              ; alle anderen Register werden nicht verändert
              ; setzt EOF nach letztem gelesenen Zeichen
              ; setzt INCOUNT

        PUSH  AX                              ; backup register
        PUSH  BX
        PUSH  CX
        PUSH  DX
        MOV   BX,INFILE                       ; file handle
        MOV   CX,INBUF_LEN
        MOV   DX,OFFSET INBUF
        MOV   AH,3FH                          ; read a file
        DOS
        MOV   INCOUNT,AX
        MOV   BX,AX
        MOV   [BX+INBUF],EOF                  ; end marker sezten
        XOR   SI,SI                           ; auf nächstes Bytes zum einlesen
        POP   DX                              ; restore register
        POP   CX
        POP   BX
        POP   AX
        RET
READ_FILE ENDP

; L03XX --------------------------------------------------------------
WRITE_FILE PROC NEAR
              ; schreiben aus dem ausgabebuffer in das Ausgabefile
              ; DI gibt die Anzahl der Bytes, wird aktuallisiert
              ; alle anderen Register werden nicht verändert

        PUSH  AX                              ; backup register
        PUSH  BX
        PUSH  CX
        PUSH  DX
        MOV   BX,OUTFILE                      ; file handle
        MOV   CX,DI
        MOV   DX,OFFSET OUTBUF
        MOV   AH,40H                          ; read a file
        DOS
        CMP   AX,CX
        JE    L0300                           ; alles wurde geschrieben
        MOV   DX,OFFSET OWN_01
        JMP   OWN_ERR                         ; Fehler, anzahl der bytes falsch
L0300:  XOR   DI,DI
        POP   DX                              ; restore register
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
ERR_DOS PROC NEAR
              ; wird sofort nach einem DOS-Call aufgerufen
              ; bei einem Fehler: Ausagabe der Meldung, und Programmabbruch

        CMP   AX,12H
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
ERR_DOS ENDP

CODE    ENDS

;---------------------------------------------------------------------
STACK   SEGMENT STACK
        DB 0200H DUP (?)
STACK   ENDS

        END   MAIN
