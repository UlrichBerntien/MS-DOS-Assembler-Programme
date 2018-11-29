        PAGE 60,132
;-------------------------------------------------------------------------------
;          kommentiertes assembler listing    --- PRINT.COM --- V1.00.10
;  (C kommentare) Ulrich Berntien .06.1988
;                 letzte Änderung .04.1989
;-------------------------------------------------------------------------------
DOS = 21H

XSEG    SEGMENT
        ASSUME CS:XSEG,DS:XSEG

        ORG 0100H
BEGIN:  JMP     MAIN

L0103   DB 00H
L0104   DB 00H
L0105   DB 00H
FILEH   DW 0000H                        ;-- file handle von eingabedatei
ONEDB   DB 00H                          ;-- one byte buffer for output
OUTSTA  DB 00H                          ;-- output status ( 00H => bereit )
L010A   DW 0000H                        ;-- file handle of OUTPUT device
L010C   DW 0000H                        ;-- speicher für SS,SP
L010E   DW 0000H                        ;--  "
L0110   DW 0000H
L0112   DW 0000H
L0114   DW 0000H                        ;-- speicher für orginal vector #24
L0116   DW 0000H                        ;--  "
L0118   DB 000H
L0119   DB 000H
L011A   DW 00000H                       ;-- address of next character in buffer
L011C   DW -1                           ;-- address of queue entry printing now
                                        ;-- begin of queue-table
L011E   DB 660 DUP(00H)                 ;-- tabelle (10*  64+1+1 Byte)
ERRFL   DB 00H                          ;-- errormsg = 1 falls errmsg vorliegt
L03B3   DB 0DH,0AH,0DH,0AH,'**********',0DH,0AH
L03C3   DB 9 DUP ( 20H )
        DB 'Error on file '
L03DA   DB 40h DUP ( 20H )
L041A   DB 0DH,0CH,07H,'$'              ;-- CR,PAGE,BELL
L041E   DB 0DH,0AH,0DH,0AH,'File canceled by operator$'
L043C   DB 0DH,0AH,0DH,0AH,'All files canceled by operator$'
L045F   DB 'Wrt ProtBad UnitNot Rdy Bad CmndData ErrBad CallSeek '
        DB 'ErrBad DiskBad SectNo PaperWrt Flt Rd FaultGen Fail'
L04C7   DB 0DH,0AH,'FAT is bad$'
L04D4   DB 'Open    '                   ;-- texte für fehlermeldung
L04DC   DB 'Read    '
L04E4   DB 'Lseek   '
L04EC   DB 'Close   '

BUFFER_SIZE = 0100H                     ;-- buffer größe
BUFFER  DB BUFFER_SIZE DUP(0000H)       ;-- eingabedatei buffer
L05F4   DB 00H

;-- interrupt routine #28 ---
;-------------------------------------------------------------------------------
NEW_28: STI
        CALL    L05FA
        IRET

L05FA:  CMP     WORD PTR CS:[L011C],-01H
        JNE     L0605                   ;-- eine datei wird gerade ausgedruckt
        JMP     L06F1                   ;-- keine datei in druck => beenden IRET
L0605:  PUSH    AX
        MOV     CS:[L010C],SS           ;-- SS,SP sichern
        MOV     CS:[L010E],SP
        MOV     AX,CS                   ;-- die ersten #0100 bytes werden
        CLI                             ;-- zum stack gemacht
        MOV     SS,AX
        MOV     SP,0100H
        STI
        PUSH    ES                      ;-- register sichern
        PUSH    DS
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        PUSH    CS                      ;-- DX := CS
        POP     DS
        MOV     AL,24H                  ;-- vector #24 = fatal error abort
        MOV     AH,35H                  ;-- get interrupt vector
        INT     DOS
        MOV     DS:[L0116],ES           ;-- store old address of interrupt
        MOV     DS:[L0114],BX
        MOV     DX,OFFSET NEW_24        ;-- neue sprung adresse DS:DX
        MOV     AL,24H                  ;-- vector #24 = fatal error abort
        MOV     AH,25H                  ;-- set interrupt vector
        INT     DOS
        CALL    L0A3B                   ;-- holt output status
        CMP     DS:[OUTSTA],00H
        JNE     L06AB                   ;-- wenn output nicht bereit , IRET
        CALL    PRINT_NULL              ;-- NULL ausdrucken
        CMP     DS:[OUTSTA],00H
        JNE     L06AB                   ;-- wenn output nicht bereit , IRET
        MOV     CX,0001H
L0650:  MOV     BX,DS:[L011A]           ;-- addresse nächsten auszugeben zeiche
        CMP     BX,OFFSET BUFFER + BUFFER_SIZE
        JE      L06A5                   ;-- wenn ende des eingabedatei buffers
        MOV     AL,[BX]                 ;-- zeichen in AL
        CMP     BYTE PTR DS:[L0118],00H
        JE      L066B
        CMP     AL,00H                  ;-- 00H = NUL
        JE      L06A8                   ;-- gibt PAGE aus
        CMP     AL,1AH                  ;-- 1AH = SUB (substitute,ersetzen)
        JE      L06A8                   ;-- gibt PAGE aus
L066B:  CMP     AL,0DH                  ;-- 0DH = CR
        JNE     L0674
        MOV     BYTE PTR DS:[L0119],00H
L0674:  CMP     AL,09H                  ;-- 09H = HT (horizontal tabulation)
        JNE     L06B0
        PUSH    CX
        MOV     CL,DS:[L0119]
        OR      CL,0F8H
        NEG     CL
        XOR     CH,CH
        JCXZ    L0698
L0686:  MOV     AL,20H                  ;-- SPACE in AL
        INC     BYTE PTR DS:[L0119]
        CALL    PRINT_AL                ;-- zeichen SPACE ausdrucken
        CMP     DS:[OUTSTA],00H
        JNE     L06D4                   ;-- output not ready, zurück IRET
        LOOP    L0686
L0698:  POP     CX
        INC     WORD PTR DS:[L011A]     ;-- pointer auf nächstes zeichen
        INC     WORD PTR DS:[L0103]     ;-- read pointer of input file
        LOOP    L0650
        JMP     SHORT L06D4             ;-- zurück IRET

L06A5:  JMP     SHORT NEXT_FILE         ;-- wenn alle zeichen aus buffer raus
        NOP

L06A8:  JMP     L0762                   ;-- wenn auszugebendes zeichen = SUB
                                        ;-- gibt PAGE aus
L06AB:  JMP     SHORT L06D4             ;-- zurück , IRET
        NOP

L06AE:  JMP     SHORT L0650

L06B0:  CMP     AL,08H
        JNE     L06B8
        DEC     BYTE PTR DS:[L0119]
L06B8:  CMP     AL,20H
        JB      L06C0
        INC     BYTE PTR DS:[L0119]
L06C0:  CALL    PRINT_AL                ;-- zeichen in AL ausdrucken
        CMP     DS:[OUTSTA],00H
        JNE     L06D4                   ;-- printer not ready, zurück IRET
        INC     WORD PTR DS:[L011A]     ;-- pointer to next character in buffer
        INC     WORD PTR DS:[L0103]     ;-- read pointer to next char. in file
        LOOP    L06AE

L06D4:  LDS     DX,DWORD PTR DS:[L0114] ;-- alte addresse wiederholen
        MOV     AL,24H                  ;-- vector #24
        MOV     AH,25H                  ;-- set interrupt vector
        INT     DOS
        POP     DI                      ;-- register wiederherstellen
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     DS
        POP     ES
        CLI                             ;-- stack wiederherstellen
        MOV     SS,CS:[L010C]
        MOV     SP,CS:[L010E]
        POP     AX
L06F1:  RET

;-- wenn alle zeichen aus buffer raus ,buffer nachladen, ggf. nächtes file ---
;-------------------------------------------------------------------------------
NEXT_FILE PROC NEAR
        MOV     BYTE PTR DS:[L0118],00H
        MOV     AH,2FH                  ;-- get current disk transfer address
        INT     DOS
        MOV     DS:[L0112],ES           ;-- DTA speichern
        MOV     DS:[L0110],BX
        CALL    CLEAR_BUFFER            ;-- eingabedatei buffer löschen
        MOV     DS:[ERRFL],00H          ;-- no error message
        MOV     DX,DS:[L011C]           ;-- auf asciz-name file printing now
        CALL    OPEN_FILE               ;-- eingabedatei öffnen
        CMP     DS:[ERRFL],00H
        JNE     L0737                   ;-- sprung wenn errmsg vorliegt
        CALL    MOVE_FILE               ;-- move read pointer der eingabedatei
        CMP     DS:[ERRFL],00H
        JNE     L0737                   ;-- sprung wenn errmsg vorliegt
        CALL    READ_FILE
        CMP     DS:[ERRFL],00H
        JNE     L0737                   ;-- sprung wenn errmsg vorliegt
        CALL    CLOSE_FILE              ;-- eingabedatei schließen
        CMP     DS:[ERRFL],00H
        JNE     L0737                   ;-- sprung wenn errmsg vorliegt
L0737:  PUSH    AX
        LDS     DX,DWORD PTR DS:[L0110]
        MOV     AH,1AH                  ;-- set disk transfer address DS:DX
        INT     DOS
        POP     AX
        PUSH    CS
        POP     DS                      ;-- DS := CS
        CMP     DS:[ERRFL],00H
        JNE     L0767                   ;-- sprung wenn errmsg vorliegt
        CMP     AX,0000H
        JE      L0762
        CMP     AX,0100H
        JE      L0758
        INC     BYTE PTR DS:[L0118]
L0758:  MOV     BX,OFFSET BUFFER        ;-- adresse des eingabedatei buffers
        MOV     DS:[L011A],BX
        JMP     L06D4                   ;-- zurück , IRET
L0762:  MOV     AL,0CH                  ;-- PAGE in AL
        CALL    PRINT_AL                ;-- PAGE ausdrucken
L0767:  CALL    END_PRINT               ;-- file printing now beenden; nächstes
        JMP     L06D4                   ;-- zurück IRET
NEXT_FILE ENDP

;-- eingabedatei buffer löschen ---
;-------------------------------------------------------------------------------
CLEAR_BUFFER PROC NEAR
        PUSH    ES
        PUSH    DS                      ;-- seg.register sichern
        PUSH    DS
        POP     ES                      ;-- ES := DS
        MOV     DI,OFFSET BUFFER        ;-- adress eingabedatei buffer
        MOV     CX,BUFFER_SIZE          ;-- länge in bytes
        MOV     AL,00H
L0779:  STOSB                           ;-- mit NUL füllen
        LOOP    L0779
        POP     DS                      ;-- seg.register wiederherstellen
        POP     ES
        RET                             ;-- zurück
CLEAR_BUFFER ENDP

;-- interrupt routine #24 == dos fatal error vector             ---
;-- fehlerbehandlung während den i/o-operationen im hintergrund ---
;-------------------------------------------------------------------------------
NEW_24: STI
        MOV     CS:[OUTSTA],00H         ;-- setzte output bereit
        CMP     CS:[ERRFL],00H
        JNZ     L07D1                   ;-- sprung wenn errmsg vorliegt
        PUSH    BX                      ;-- register sichern
        PUSH    CX
        PUSH    DX
        PUSH    DI
        PUSH    SI
        PUSH    BP
        PUSH    ES
        PUSH    DS
        PUSH    CS
        POP     DS
        TEST    AH,80H                  ;-- charcter divice or FAT error ?
        JNE     L07D4
        AND     DI,00FFH                ;-- high byte ausblenden
        CMP     DI,+0CH                 ;-- highest error code value
        JNA     L07A9                   ;-- sprung wenn error code gültig
        MOV     DI,000CH                ;-- sonst setzt 'general disk failure'
L07A9:  SHL     DI,1
        SHL     DI,1
        SHL     DI,1
        MOV     SI,DI                   ;-- adresse des Fehlertextes generieren
        PUSH    DS
        POP     ES                      ;-- ES := DS
        ADD     SI,OFFSET L045F         ;-- + adr. tabelle mit error messages
        MOV     DI,OFFSET L03C3         ;-- dorthin soll der fehlertext
        MOV     CX,0008H                ;-- länge 8 Byte
        REPZ    MOVSB                   ;-- meldung kopieren
        MOV     DI,OFFSET L03DA         ;-- dorthin der filename printing now
        CALL    L0A1A                   ;-- kopieren
L07C5:  INC     DS:[ERRFL]              ;-- errmsg = 1, fehlermeldung liegt vor
L07C9:  POP     DS                      ;-- register wiederherstellen
        POP     ES
        POP     BP
        POP     SI
        POP     DI
        POP     DX
        POP     CX
        POP     BX
L07D1:  XOR     AL,AL                   ;-- command to DOS ignore the error
        IRET                            ;-- zurück

L07D4:  CMP     DI,+02H
        JE      L07E6                   ;-- drive not ready
        CMP     DI,+09H
        JE      L07E6                   ;-- printer out of paper
        MOV     SI,OFFSET L04C7         ;-- auf "fat is bad"
        CALL    PRINT_STR               ;-- string DS:SI ausdrucken
        JMP     SHORT L07C5             ;-- rücksprung mit fehler meldung
L07E6:  INC     DS:[OUTSTA]             ;-- output nicht beriet setzen
        JMP     SHORT L07C9             ;-- rücksprung ohne fehler meldung
L07EC:  JMP     L08C9

;-- interrupt routine #2F ---
;-- übergibt in den registern addresse von queue u.ä.
;-- nimmt filenamen in DS:DX für den queue entgegen
;-------------------------------------------------------------------------------
NEW_2F: PUSH    SI                      ;-- register sichern
        PUSH    DI
        PUSH    DS
        PUSH    CS
        POP     DS
        CMP     AH,0FFH
        JNE     L07FD                   ;-- sprung wenn kein filename übergeben
        MOV     AH,DS:[L0105]
L07FD:  OR      AH,AH
        JE      L07EC
        CMP     AH,02H
        JE      L07EC
        CMP     AH,01H
        JE      L0838

        XOR     AL,AL                   ;-- keine freien plätze im queue
L080D:  PUSH    AX                      ;-- al sichern

        XOR     AH,AH                   ;-- AH := anzahl der belegten plätze
        MOV     SI,OFFSET L011E         ;-- startadresse des queue-table
        MOV     CX,000AH                ;-- 10 bytes lang
L0816:  CMP     BYTE PTR [SI],00H
        JE      L081D                   ;-- eintrag ist leer
        INC     AH                      ;-- noch einer im queue : AH ++
L081D:  ADD     SI,+42H                 ;-- nächster eintrag
        LOOP    L0816                   ;-- scheife über alle einträge

        MOV     BX,OFFSET L011E         ;-- offsettaddress of queue table
        MOV     DX,DS:[L011C]           ;-- offsetad. of filename printing now
        PUSH    DS                      ;-- ES := DS
        POP     ES                      ;-- segmentaddress of queue-table
        MOV     CH,AH                   ;-- anzahl der belegten plätze sichern
        POP     AX                      ;-- AL = anzahl der freien plätze
        MOV     AH,CH                   ;-- anzahl der files im queue
        MOV     CH,0AH                  ;-- anzahl der plätze im queue
        MOV     CL,41H                  ;-- max. länge der filenamen
        POP     DS                      ;-- register herstellen
        POP     DI
        POP     SI
        IRET                            ;-- rücksprung von #2F

L0838:  MOV     DS:[L0105],AH
        MOV     CX,000AH
        MOV     SI,OFFSET L011E
        CMP     DX,-01H
        JE      L088D
        POP     ES
        PUSH    ES
        MOV     BX,SI
L084B:  MOV     DI,DX
        PUSH    CX
        MOV     CX,0041H
        REPZ    CMPSB
        CMP     CX,+00H
        JE      L0864
L0858:  POP     CX
        ADD     BX,+42H
        MOV     SI,BX
        LOOP    L084B
        XOR     AX,AX
        JMP     SHORT L080D
L0864:  CMP     BYTE PTR [BX+41H],01H
        JNE     L0870
        MOV     DX,BX                   ;-- DS:DX pointer to file name
        MOV     AH,41H                  ;-- delete a directory entry
        INT     DOS

L0870:  MOV     BYTE PTR [BX],00H
        CMP     BX,DS:[L011C]
        JNE     L0858
        MOV     SI,OFFSET L041E         ;-- auf "file canceled by operator"
        CALL    PRINT_STR               ;-- string DS:SI ausdrucken
        MOV     SI,OFFSET L041A         ;-- auf LF + PAGE + BELL
        CALL    PRINT_STR               ;-- string DS:SI ausdrucken
        CALL    END_PRINT               ;-- file printing now beenden; nächstes
        POP     CX
        XOR     AX,AX
        JMP     SHORT L080D
L088D:  CMP     BYTE PTR [SI+41H],01H
        JNE     L0899
        MOV     DX,SI                   ;-- DS:DX pointer to file name
        MOV     AH,41H                  ;-- delete a directory entry
        INT     DOS

L0899:  MOV     BYTE PTR [SI],00H
        ADD     SI,+42H
        LOOP    L088D
        MOV     SI,OFFSET L043C         ;-- auf "all file canceled by operator"
        CALL    PRINT_STR               ;-- string DS:SI ausdrucken
        MOV     SI,OFFSET L041A         ;-- auf CR + PAGE + BELL
        CALL    PRINT_STR               ;-- string DS:SI ausdrucken
        MOV     WORD PTR DS:[L011C],0FFFFH
        MOV     WORD PTR DS:[L0103],0000H
        MOV     WORD PTR DS:[L011A],OFFSET L05F4
        MOV     BYTE PTR DS:[L0119],00H
        XOR     AX,AX
        JMP     L080D
L08C9:  MOV     DS:[L0105],AH
        MOV     SI,011EH
        MOV     CX,000AH
L08D3:  CMP     BYTE PTR [SI],00H
        JE      L08E2
        ADD     SI,+42H
        LOOP    L08D3
        MOV     AL,01H
        JMP     L080D
L08E2:  CMP     BYTE PTR DS:[L0105],02H
        JNE     L08F5
        MOV     BYTE PTR [SI+41H],01H
        MOV     BYTE PTR DS:[L0105],00H
        JMP     SHORT L08F9
        NOP
L08F5:  MOV     BYTE PTR [SI+41H],00H
L08F9:  PUSH    DS
        POP     ES
        POP     DS
        PUSH    DS
        MOV     DI,SI
        MOV     SI,DX
        MOV     CX,0041H
        REPZ    MOVSB
        PUSH    ES
        POP     DS
        XOR     AL,AL
        CMP     WORD PTR DS:[L011C],-01H
        JNE     L0914
        CALL    L092A
L0914:  JMP     L080D

;-- file printing now beenden , zeiger ggf. auf das nächste file ---
;-------------------------------------------------------------------------------
END_PRINT PROC NEAR
        MOV     SI,DS:[L011C]           ;-- SI auf queue entry printing now
        CMP     BYTE PTR [SI+41H],01H
        JNE     L0927                   ;-- falls flag nicht gestzt
        MOV     DX,SI                   ;-- DS:DX pointer to file name
        MOV     AH,41H                  ;-- delete a directory entry
        INT     DOS
L0927:  MOV     BYTE PTR [SI],00H       ;-- queue entry freigeben
L092A:  MOV     SI,OFFSET L011E         ;-- auf begin der queue table
        MOV     CX,000AH                ;-- 10 entries in der tabelle
L0930:  CMP     BYTE PTR [SI],00H
        JNE     L0952                   ;-- sprung wenn entry nicht leer ist
        ADD     SI,+42H                 ;-- auf nächsten entry
        LOOP    L0930                   ;-- schleife über alle entries
        MOV     WORD PTR DS:[L011C],-1    ;-- no file printing now
        MOV     WORD PTR DS:[L0103],0000H ;-- eingabedatei read pointer
        MOV     WORD PTR DS:[L011A],OFFSET L05F4
        MOV     BYTE PTR DS:[L0119],00H   ;--
        RET
L0952:  MOV     WORD PTR DS:[L0103],0000H ;-- eingabedatei read pointer
        MOV     WORD PTR DS:[L011A],OFFSET L05F4
        MOV     BYTE PTR DS:[L0119],00H
        MOV     DS:[L011C],SI           ;-- dieses file nun ausdrucken
        RET
END_PRINT ENDP

;-- eingabedatei öffnen ,asciz name in DS:DX ,file handle in [FILEH] ---
;-------------------------------------------------------------------------------
OPEN_FILE PROC NEAR
        CLC
        MOV     AL,00H                  ;-- opend for reading
        MOV     AH,3DH                  ;-- open a file
        INT     DOS                     ;-- file handle return in AX
        JB      L09DE                   ;-- bei 'open'fehler meldung ausdrucken
        CMP     DS:[ERRFL],00H          ;-- errormsg abfragen
        JNE     L09D7                   ;-- wenn errormsg, meldung ausdrucken
        MOV     DS:[ERRFL],00H          ;-- fehlerflag löschen
        MOV     WORD PTR DS:[FILEH],AX  ;-- file handle speichern
        RET
OPEN_FILE ENDP

;-- eingabedate schließen ,file handle aus [FILEH] ---
;-------------------------------------------------------------------------------
CLOSE_FILE PROC NEAR
        CLC
        MOV     BX,DS:[FILEH]           ;-- file handle von eingabedatei
        MOV     AH,3EH                  ;-- close a file
        INT     DOS
        JB      L09E5                   ;-- sprung bei fehler
        CMP     DS:[ERRFL],00H
        JNE     L09D7                   ;-- wenn errormsg , meldung ausdrucken
        MOV     DS:[ERRFL],00H          ;-- no error message
        RET
CLOSE_FILE ENDP

;-- move read pointer of eingabedatei ---
;-------------------------------------------------------------------------------
MOVE_FILE PROC NEAR
        CLC
        MOV     DX,WORD PTR DS:[L0103]  ;-- read pointer von eingabedatei
        XOR     CX,CX                   ;-- most significant word := 0
        MOV     BX,DS:[FILEH]           ;-- file handle von eingabedatei
        MOV     AL,00H                  ;-- moves offset bytes from beginning
        MOV     AH,42H                  ;-- move read/write pointer
        INT     DOS
        JB      L09EC                   ;-- sprung bei fehler
        CMP     DS:[ERRFL],00H
        JNE     L09D7                   ;-- wenn errormsg , meldung ausdrucken
        MOV     DS:[ERRFL],00H          ;-- no error message
        RET
MOVE_FILE ENDP

;-- read #0100 Bytes aus der eingabedatei ---
;-------------------------------------------------------------------------------
READ_FILE PROC NEAR
        CLC
        MOV     DX,OFFSET BUFFER        ;-- address of eingabedatei buffer
        MOV     CX,BUFFER_SIZE          ;-- number of bytes for i/o
        MOV     BX,DS:[FILEH]           ;-- file handle
        MOV     AH,3FH                  ;-- read a file
        INT     DOS
        JB      L09F3                   ;-- sprung bei fehler
        CMP     DS:[ERRFL],00H
        JNE     L09D7                   ;-- wenn errmsg , meldung ausdrucken
        MOV     DS:[ERRFL],00H          ;-- no error message
        RET
READ_FILE ENDP

;-- die alte fehlermeldung ausdrucken ---
;-------------------------------------------------------------------------------
L09D7:  MOV     SI,OFFSET L03B3         ;-- auf "*** errror on file"
        CALL    PRINT_STR               ;-- string DS:SI ausdrucken
        RET

;-- verschiedene fehlermeldungen auf den drucker geben ---
;-------------------------------------------------------------------------------
L09DE:  PUSH    SI                      ;-- nach fehler beim open
        MOV     SI,OFFSET L04D4         ;-- auf "Open"
        JMP     SHORT L09F7             ;-- meldung ausgeben
        NOP
L09E5:  PUSH    SI                      ;-- nach fehler beim close
        MOV     SI,OFFSET L04EC         ;-- auf "close"
        JMP     SHORT L09F7             ;-- meldung ausgeben
        NOP
L09EC:  PUSH    SI                      ;-- nach fehler beim seek
        MOV     SI,OFFSET L04E4         ;-- auf "seek"
        JMP     SHORT L09F7             ;-- meldung ausgeben
        NOP
L09F3:  PUSH    SI
        MOV     SI,OFFSET L04DC         ;-- auf "read"
L09F7:  MOV     DS:[ERRFL],01H          ;-- error message liegt vor
        PUSH    DI                      ;-- register sichern
        PUSH    ES
        PUSH    DS
        PUSH    DS
        POP     ES
        MOV     DI,OFFSET L03C3         ;-- art des fehlers in message copieren
        MOV     CX,0008H                ;-- immer 8 zeichen lang
        REPZ    MOVSB                   ;-- von SI nach DI kopieren
        MOV     DI,OFFSET L03DA         ;-- nach der fehlermeldung den namen
        CALL    L0A1A                   ;-- filename of printing now copieren
        MOV     SI,OFFSET L03B3         ;-- auf " *** ... error on file ... "
        CALL    PRINT_STR               ;-- string DS:SI ausdrucken
        POP     DS                      ;-- register wiederherstellen
        POP     ES
        POP     DI
        POP     SI
        RET                             ;-- rücksprung

;-- name von file printing now nach DS:DI copieren ---
;-------------------------------------------------------------------------------
L0A1A:  MOV     SI,DS:[L011C]           ;-- auf name von file printing now
        MOV     CX,0040H                ;-- länge des file namens
L0A21:  LODSB                           ;-- ein zeichen aus dem namen holen
        CMP     AL,00H
        JE      L0A2A                   ;-- #00 terminiert transfer
        STOSB                           ;-- namen zeichenweise abspeichern
        LOOP    L0A21
        RET
L0A2A:  MOV     AL,20H                  ;-- den rest mit SPACE füllen
L0A2C:  STOSB
        LOOP    L0A2C
        RET

;-- ausdrucken zeichenkette terminiert mit '$', adresse DS:SI ---
;-------------------------------------------------------------------------------
PRINT_STR PROC NEAR
        LODSB                           ;-- ein Byte lesen in AL, SI:=SI+1
        CMP     AL,'$'
        JE      L0A3A                   ;-- ende der ausgabe durch '$'
        CALL    PRINT_AL                ;-- zeichen in AL ausdrucken
        JMP     SHORT PRINT_STR         ;-- schleife
L0A3A:  RET                             ;-- rÞcksprung
PRINT_STR ENDP

;-- holt den output status in DS:OUTSTA ( 00H => ready ) ---
;-------------------------------------------------------------------------------
L0A3B:  PUSH    AX                      ;-- register sichern
        PUSH    BX
        MOV     DS:[OUTSTA],00H         ;-- output nicht bereit setzen
        MOV     AL,07H                  ;-- subfunction code: get status
        MOV     AH,44H                  ;-- get divice output status
        MOV     BX,DS:[L010A]           ;-- file handle
        INT     DOS
        OR      AL,AL
        JNE     L0A55
        MOV     DS:[OUTSTA],01H         ;-- output ist bereit
L0A55:  POP     BX                      ;-- register widerherstellen
        POP     AX
        RET

;-- NULL ausdrucken ---
;-------------------------------------------------------------------------------
PRINT_NULL PROC NEAR
        PUSH    AX                      ;-- register sichern
        MOV     AL,00H                  ;-- NUL zeichen in AL
        CALL    PRINT_AL                ;-- zeichen in AL ausdrucken
        POP     AX                      ;-- register wiederherstellen
        RET
PRINT_NULL ENDP

;-- zeichen in AL ausdrucken ---
;-------------------------------------------------------------------------------
PRINT_AL PROC NEAR
        PUSH    CX                      ;-- register sichern
        PUSH    DX
        PUSH    AX
        PUSH    BX
        MOV     DS:[OUTSTA],00H ;-- set output status not ready
        MOV     CX,0001H                ;-- ein byte ausdrucken
        MOV     BYTE PTR DS:[ONEDB],AL  ;-- das zeichen in den buffer
        MOV     DX,OFFSET ONEDB         ;-- addresse des buffers DS:DX
        MOV     AH,40H                  ;-- write a file
        MOV     BX,DS:[L010A]           ;-- file handle
        INT     DOS
        POP     BX                      ;-- register wiederherstellen
        POP     AX
        POP     DX
        POP     CX
        RET                             ;-- rÞcksprung
PRINT_AL ENDP

;-------------------------------------------------------------------------------
;-- ende des residenten teils ---
;-------------------------------------------------------------------------------

                                        ;-- ansprung wenn fehler bei instalation
L0A7F:  MOV     DX,OFFSET L0E82         ;-- auf "list not assign to a divice"
        MOV     AH,09H                  ;-- print a string
        INT     DOS
        MOV     BYTE PTR DS:[L0D56],0FFH  ;-- fehlercode
        JMP     L0B35                   ;-- rücksprung nach fehler

;-- instalations routine ---
;-------------------------------------------------------------------------------
INSTAL  PROC NEAR
        CLD
        JMP     SHORT L0AC7             ;-- keine wahl des ausgabe gerätes
        NOP
        MOV     DX,OFFSET L0ED1         ;-- auf "name of list divice [prn]:"
        MOV     AH,09H                  ;-- print a string
        INT     DOS
        MOV     DX,OFFSET L0F0B         ;-- ungenutzter speicherbereich
        MOV     AH,0AH
        INT     DOS                     ;-- bufferd keyboard input
        MOV     DX,OFFSET L0E1A         ;-- ' CR + LF '
        MOV     AH,09H                  ;-- print a string
        INT     DOS
        XOR     CH,CH                   ;-- CH := 0
        MOV     CL,DS:[L0F0C]           ;-- CX:= number of charcters received
        OR      CL,CL
        JE      L0AC7                   ;-- keine zeichen, also standartprinter
        MOV     DI,OFFSET LAST_DB       ;-- auf anfang der eingelesenen zeichen
        ADD     DI,CX                   ;-- auf das ende+1 der zeichenkette
        MOV     BYTE PTR [DI],00H       ;-- in asciz format wandeln
        MOV     DX,OFFSET LAST_DB       ;-- filename ist der eingegebene string
        MOV     AL,01H                  ;-- opend for writing
        MOV     AH,3DH                  ;-- open a file
        INT     DOS
        JB      L0A7F                   ;-- sprung bei fehler
        JMP     SHORT L0ACA             ;-- nicht der standart handle
        NOP                             ;-- wenn nicht anders gegeben:
L0AC7:  MOV     AX,0004H                ;--
L0ACA:  MOV     WORD PTR DS:[L010A],AX  ;--             <=> standart printer
        MOV     AL,00H                  ;-- sub function code: get
        MOV     BX,DS:[L010A]           ;-- file handle
        MOV     AH,44H                  ;-- get divice information
        INT     DOS                     ;--    returnd in DX
        JB      L0A7F                   ;-- sprung bei fehler
        TEST    DL,80H                  ;-- ? ist es die uhr ?
        JE      L0A7F                   ;-- ja als sprung zum fehler
        MOV     BYTE PTR DS:[L0D56],00H ;-- error code := kein fehler
        PUSH    CS
        POP     DS                      ;-- DS := CS
        MOV     WORD PTR DS:[L011A],05F4H
        MOV     DX,OFFSET NEW_2F        ;-- jump to DS:DX
        MOV     AL,2FH                  ;-- vector Nr. #2F
        MOV     AH,25H                  ;-- set interrupt vector
        INT     DOS
        MOV     BYTE PTR DS:[L0D58],01H ;-- flag on, weil residenter teil ins.
        MOV     DX,OFFSET L0EAC         ;-- auf "res. part of print installed"
        MOV     AH,09H                  ;-- print a string, address DS:DX
        INT     DOS
        RET
INSTAL  ENDP

;-- hauptprogramm ---
;-------------------------------------------------------------------------------
MAIN    PROC NEAR
        CLD                             ;-- main program start
        MOV     DX,OFFSET L0EEF         ;-- auf "print version 1.00.10"
        MOV     AH,09H                  ;-- print a string, address DS:DX
        INT     DOS
        MOV     AH,37H
        MOV     AL,00H                  ;-- DOS switch character return in DL
        INT     DOS
        MOV     DS:[L0D57],DL           ;-- switch character abspeichern
        MOV     AH,35H                  ;-- get interrupt vetor
        MOV     AL,2FH                  ;-- Nr. #2F
        INT     DOS
        MOV     DI,BX
        MOV     SI,OFFSET NEW_2F        ;-- adresse der interrupt routine
        MOV     CX,000DH                ;-- anzahl der bytes für den vergleich
        REPZ    CMPSB                   ;-- prüft, ob er schon installiert ist
        PUSH    CS
        POP     ES                      ;-- ES := CS
        JE      L0B2A                   ;-- sprung falls schon installiert
        CALL    INSTAL                  ;-- installieren
L0B2A:  MOV     SI,0080H                ;-- number of character im parameter
        LODSB                           ;-- load byte string AL:=[DS:SI],SI=SI+1
        OR      AL,AL
        JNE     L0B5B                   ;-- sprung wenn AL <> 0
L0B32:  CALL    L0C87                   ;-- inhalt des queue ausgeben
L0B35:  CMP     BYTE PTR DS:[L0D58],00H
        JNE     L0B43                   ;-- residenter teil zurücklassen
        MOV     AL,BYTE PTR DS:[L0D56]  ;-- error code in al als return code
        MOV     AH,4CH                  ;-- exit from a prozess
        INT     DOS                     ;-- program end ;--
                                        ;-- residenter teil zurücklassen
L0B43:  MOV     DX,OFFSET NEW_28
        MOV     AL,28H                  ;-- vector #28
        MOV     AH,25H                  ;-- set interrupt vector
        INT     DOS
        XOR     AL,AL                   ;-- exit code := 0
        MOV     DX,DS:[L0EED]           ;-- anzahl der bytes resident
        MOV     CL,04H                  ;-- umrechnen im paragrphs
        SHR     DX,CL
        INC     DX                      ;-- number of paragraphs allocated
        MOV     AH,31H                  ;-- keep process
        INT     DOS
MAIN    ENDP

;-- auswertung von übergebenen parametern ---
;-------------------------------------------------------------------------------
L0B5B:  MOV     BYTE PTR DS:[L0D59],AL  ;-- lenght of parameter abspeichern
L0B5E:  PUSH    CS
        POP     ES                      ;-- ES := DS
        MOV     DX,SI
        CALL    GOOVER                  ;-- liest leerzeichen raus, SI aktuell
        CMP     BYTE PTR DS:[L0D59],00H ;-- anzahl der restlichen zeichen
        JE      L0B32                   ;-- doch keine parameter
        MOV     CX,0040H                ;-- länge des bereiches für den namen
        MOV     DI,OFFSET L0D15         ;-- speicherbereich für filenamen
        CALL    READ_FNAME              ;-- filename nach DI, switch bliebt dort
        CMP     BYTE PTR DS:[L0D59],00H
        JE      L0BC4                   ;-- kein switch mehr da
        CALL    GOOVER                  ;-- ggf. leerzeichen weglesen
        CMP     BYTE PTR DS:[L0D59],00H
        JE      L0BC4                   ;-- kein switch dabei gewesen
        MOV     AL,[SI]
        CMP     AL,DS:[L0D57]           ;-- stimmt der switch character ?
        JNE     L0BC4                   ;-- nein er war falsch
        INC     SI
        DEC     BYTE PTR DS:[L0D59]     ;-- das switch character weglesen
        JE      L0BC4                   ;-- kein switch nach dem zeichen
        LODSB
        DEC     BYTE PTR DS:[L0D59]     ;-- den switch weglesen
        OR      AL,20H                  ;-- in kleinbuchstaben umwandeln
        CMP     AL,63H
        JE      L0BA3                   ;-- switch ist 'c'
        JMP     SHORT L0BAA             ;-- weitere vergleiche
        NOP
L0BA3:  MOV     BYTE PTR DS:[L0D5B],01H
        JMP     SHORT L0BC4
L0BAA:  CMP     AL,70H
        JE      L0BB1                   ;-- switch ist 'p'
        JMP     SHORT L0BB8             ;-- weitere auswertung
        NOP
L0BB1:  MOV     BYTE PTR DS:[L0D5B],00H
        JMP     SHORT L0BC4
L0BB8:  CMP     AL,74H
        JE      L0BBF                   ;-- switch ist 't'
        JMP     SHORT L0BC4
        NOP
L0BBF:  MOV     BYTE PTR DS:[L0D5A],01H ;-- noch ein zeichen auszuwerten
                                        ;-- kein switch mehr auszuwerten
L0BC4:  CMP     BYTE PTR DS:[L0D5A],00H
        JE      L0BD3                   ;-- es sind noch zeichen im parameter
        MOV     DX,0FFFFH
        MOV     AH,01H
        JMP     SHORT L0C05
        NOP                             ;-- testet ob file vorhanden ist:
L0BD3:  MOV     DX,OFFSET L0D15         ;-- DS:DX to asciz name of file
        MOV     AL,00H                  ;-- file open for reading
        MOV     AH,3DH                  ;-- open a file
        INT     DOS
        JB      L0C3D                   ;-- file can't open , meldung ausgeben
        MOV     BX,AX                   ;-- file handle in BX
        MOV     AH,3EH                  ;-- close a file
        INT     DOS
        MOV     AL,BYTE PTR DS:[L0D16]
        CMP     AL,3AH                  ;-- #3A = ":"
        JE      L0BFE                   ;-- wenn drive im filenamen gegeben ist
        MOV     AH,19H                  ;-- sonst das aktuelle drive nehmen
        INT     DOS                     ;-- current disk returns in AL
        ADD     AL,41H                  ;-- drive number convert to letter A,B..
        MOV     BYTE PTR DS:[L0D13],AL  ;-- in den filenamen einbauen
        MOV     DX,OFFSET L0D13         ;-- dort fängt der kompl. filenamen an
        MOV     AH,DS:[L0D5B]           ;-- code an int #2F für name in queue
        JMP     SHORT L0C05
        NOP
L0BFE:  MOV     DX,OFFSET L0D15         ;-- dort fängt der koml. filename an
        MOV     AH,DS:[L0D5B]           ;-- code an int #2F für name in queue
L0C05:  CALL    L0C20                   ;-- filenamen an residenten teil geben
        OR      AL,AL
        JE      L0C16                   ;-- noch freie plätze im queue
        MOV     DX,OFFSET L0E6C         ;-- auf "print queue is full"
        MOV     AH,09H                  ;-- print a string
        INT     DOS
        JMP     SHORT L0C16
        NOP
L0C16:  CMP     BYTE PTR DS:[L0D59],00H
        JE      L0C37                   ;-- alle parameter ausgewertet
        JMP     L0B5E                   ;-- núchsten parameter auswerten

                                        ;-- holt adressen vom resident teil
L0C20:  INT     2FH                     ;-- eigener interrupt vector
        MOV     DS:[L0D5C],AH           ;-- anzahl der files im queue
        MOV     DS:[L0D5F],ES           ;-- segment adresse der queue-tabelle
        MOV     DS:[L0D63],ES
        MOV     DS:[L0D5D],BX           ;-- offset adresse des ersten eintrages
        MOV     DS:[L0D61],DX           ;-- offset adresse file printing now
        RET

L0C37:  CALL    L0C87
        JMP     L0B35
L0C3D:  JMP     L0CD7                   ;-- fehler file can't open

;-- filename aus string ab SI lesen und nach DI übertragen ---
;-- ggf. den folgenden switch stehen lassen                ---
;-------------------------------------------------------------------------------
READ_FNAME PROC NEAR
        DEC     BYTE PTR DS:[L0D59]
        LODSB                           ;-- aus dem parameterbereich lesen
        CMP     AL,20H
        JE      L0C6A                   ;-- falls zeichen ein space
        CMP     AL,09H
        JE      L0C6A                   ;-- falls zeichen ein tab
        CMP     AL,DS:[L0D57]
        JE      L0C6A                   ;-- falls switch character
        CMP     AL,60H
        JLE     L0C5D                   ;-->
        CMP     AL,7BH                  ;--> zeichen ist kein kleinbuchstabe
        JNL     L0C5D                   ;-->
        XOR     AL,20H                  ;-- kleinbuchstaben a..z => A..Z
L0C5D:  STOSB
        CMP     BYTE PTR DS:[L0D59],00H ;-- filename zu ende
        JE      L0C6F
        LOOP    READ_FNAME              ;-- max. anzahl wurde in CX übergeben
        JMP     SHORT L0C6F
        NOP
L0C6A:  INC     BYTE PTR DS:[L0D59]     ;-- anzahl der restlichen zeichen
        DEC     SI                      ;-- SI auf den restparamterbereich
L0C6F:  MOV     AL,00H
        STOSB                           ;-- filename in asciz format
        RET
READ_FNAME ENDP

;-- überliest TAB und SPACE zeichen ---
;-------------------------------------------------------------------------------
GOOVER  PROC NEAR
        MOV     AL,[SI]
        CMP     AL,09H                  ;-- vergleich auf TAB = #09
        JNE     L0C82
L0C79:  INC     SI
        DEC     BYTE PTR DS:[L0D59]     ;-- anzahl der noch übrigen zeichen
        JE      L0C86
        JMP     SHORT GOOVER
L0C82:  CMP     AL,20H                  ;-- vergleich auf SPACE = #20
        JE      L0C79
L0C86:  RET                             ;-- SI liegt nun auf einem nichtleeren
GOOVER ENDP

;-- aufruf erfolgte ohne parameter -> ausgabe der namen im queue ---
;-------------------------------------------------------------------------------
L0C87:  MOV     AH,63H
        CALL    L0C20
        CMP     BYTE PTR DS:[L0D5C],00H
        JE      L0CCF                   ;-- keine files im queue
        LES     DI,DWORD PTR DS:[L0D61]
        CMP     DI,-01H
        JE      L0CA9                   ;-- falls kein file im druck
        MOV     SI,OFFSET L0D89         ;-- kopieren in den text unten
        CALL    COPY_DISI               ;-- copierroutine
        MOV     DX,OFFSET L0D7C         ;-- auf "now printing " ...
        MOV     AH,09H                  ;-- print a string
        INT     DOS
L0CA9:  MOV     BX,DI                   ;-- das file printing now merken
        MOV     DI,DS:[L0D5D]           ;-- auf anfang der queue tabelle
        MOV     CX,000AH                ;-- queue hat 10 eintrúge fÞr filenamen
L0CB2:  CMP     DI,BX
        JE      L0CC9                   ;-- dieses file wird gerade gedruckt
        CMP     BYTE PTR ES:[DI],00H
        JE      L0CC9                   ;-- eintrag ist leer, no output
        MOV     SI,OFFSET L0DCE         ;-- dorthin filename copieren
        CALL    COPY_DISI               ;-- copier routine aufrufen
        MOV     DX,OFFSET L0DCE         ;-- ... auf "is in queue"
        MOV     AH,09H                  ;-- print a string
        INT     DOS
L0CC9:  ADD     DI,+42H                 ;-- move pointer to next entry
        LOOP    L0CB2
        RET

L0CCF:  MOV     DX,OFFSET L0D65         ;-- auf "print queue is empty"
        MOV     AH,09H                  ;-- print a string
        INT     DOS
        RET

;-- fehlermeldung wenn falscher filename als parameter ---
;-------------------------------------------------------------------------------
L0CD7:  PUSH    SI                      ;-- register retten
        MOV     SI,OFFSET L0E29         ;-- dorthin soll der filename
        MOV     DI,DX                   ;-- dx ist auf dem filenamen
        CALL    COPY_DISI               ;-- kopiert file name in meldungs text
        MOV     DX,OFFSET L0E1D         ;-- auf "can not open" ...
        MOV     AH,09H                  ;-- print a string, meldung ausgeben
        INT     DOS
        POP     SI                      ;-- register wiederherstellen
        JMP     L0C16                   ;-- zum nächten parameter auswerten

;-- kopiert filename von DI nach SI
;-------------------------------------------------------------------------------
COPY_DISI PROC NEAR
        PUSH    SI                      ;-- register sichern
        PUSH    DI
        PUSH    CX
        MOV     AX,ES
        PUSH    DS
        POP     ES                      ;-- DS,ES austauschen
        MOV     DS,AX
        XCHG    SI,DI                   ;-- SI,DI austauschen
        MOV     CX,0040H                ;-- 62+2 byte lange namen
L0CF9:  LODSB                           ;-- byte load AL:=[SI], SI:=SI+1
        CMP     AL,00H
        JE      L0D04                   ;-- ende des namens
        STOSB                           ;-- byte store [DI]:=AL, DI:= DI+1
        LOOP    L0CF9
        JMP     SHORT L0D09             ;-- fertig mit dem kopieren
        NOP
L0D04:  MOV     AL,00H
L0D06:  STOSB                           ;-- rest mit NUL füllen
        LOOP    L0D06                   ;-- den ganzen namen
L0D09:  MOV     AX,ES
        PUSH    DS
        POP     ES
        MOV     DS,AX                   ;-- DS,ES austauschen
        POP     CX                      ;-- register widerherstellen
        POP     DI
        POP     SI
        RET                             ;-- zurück
COPY_DISI ENDP

;-------------------------------------------------------------------------------

L0D13   DB      ' :'                    ;-- für kompl. filenamen mit driveletter
L0D15   DB      ' '                     ;-- speicher für filenamen
L0D16   DB      3FH DUP ( 20H )
        DB      00H
L0D56   DB      00H                     ;-- FFH wenn output device fehlerhaft
L0D57   DB      00H                     ;-- switch character z.b. "-"
L0D58   DB      00H                     ;-- 01H wenn residenter teil install.
L0D59   DB      00H                     ;-- anzahl der auszuwertenden zeichen
L0D5A   DB      00H
L0D5B   DB      0FFH                    ;-- code an int #2F, filename in queue
L0D5C   DB      00H                     ;-- anzahl der files im queue
L0D5D   DW      0000H                   ;-- arbeitsspeicher
L0D5F   DW      0000H                   ;-- segment adresse der queue tabelle
L0D61   DW      0000H                   ;-- offset adresse file printing now
L0D63   DW      0000H                   ;-- segment adresse der queue tabelle
L0D65   DB      'PRINT queue is empty',0DH,0AH,'$'
L0D7C   DB      'Now printing '
L0D89   DB      40 DUP ( 20H )
        DB      '                        ',0DH,0AH,0DH,0AH,'$'
L0DCE   DB      64 DUP ( 20H )
        DB      ' is in queue'
L0E1A   DB      0DH,0AH,'$'
L0E1D   DB      'Cannot open '
L0E29   DB      64 DUP ( 20H )
        DB      0DH,0AH,'$'
L0E6C   DB      'PRINT queue is full',0DH,0AH,'$'
L0E82   DB      'List output is not assigned to a device',0DH,0AH,'$'
L0EAC   DB      'Resident part of PRINT installed',0DH,0AH,0DH,0AH,'$'
L0ED1   DB      'Name of list device [PRN]: $'
L0EED   DW      OFFSET L0A7F            ;-- letztes byte im residenten Teil
L0EEF   DB      0DH,0AH,'Print Version 1.00.10',0DH,0AH,0DH,0AH,'$'
L0F0B   DB      41H                     ;-- length of keyboard buffer
L0F0C   DB                              ;-- keyboard buffer when read divicename
LAST_DB DB

XSEG    ENDS
        END BEGIN
