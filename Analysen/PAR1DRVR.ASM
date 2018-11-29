        PAGE    60,132
;---------------------------------------------------------------------
;       Assembler Listing von --- PAR1DRVR.COM ---
;       Kommentare (c) Ulrich Berntien .04.1989
;                      letzte Änderung .05.1989
;---------------------------------------------------------------------
XSEG    SEGMENT
        ASSUME CS:XSEG, DS:XSEG

DOS  = 21H
BIOS = 88H

MYNAME_LEN = 02DH                 ;-- läge von myname
FILEBUF_LEN = 0080H               ;-- buffer für einlesen von prnxlt.com
NAMBUF_LEN  = 8+1+3+1             ;-- buffer für filenamen der tabellen
PORT_DATA = 10EAH                 ;-- port adresse für byte auf centronix
PORT_STA = 1020H                  ;-- port adresse für statusbyte
;------------------ driver head --------------------------------------
        DD    -1                  ;-- pointer to next driver head
        DW    0C000H              ;-- attribute: ioctl , nonibm format
        DW    OFFSET ENQUEUE      ;-- pointer to device enqueue entry point
        DW    OFFSET SERVICE      ;-- pointer to device service entry point
        DB    'PRN     '          ;-- character device name
        DB    00H                 ;-- (for block devices)
;---------------------------------------------------------------------
        DB    13 DUP (00H)
STOREDB DW    0000H          ;0020;-- speicher für pointer to data block
        DW    0000H
FLAG_OC DB    00H
L0025   DB    00H

;------------------ enqueue procedure --------------------------------
ENQUEUE PROC FAR
        MOV   WORD PTR CS:[STOREDB],BX        ;-- pointer to datablock speichern
        MOV   WORD PTR CS:2[STOREDB],ES
        RET                                   ;-- return far
ENQUEUE ENDP

;---------------------------------------------------------------------
JUMPER  DW    OFFSET INIT         ;-- init
        DW    OFFSET MEDIA_CHECK  ;-- media check
        DW    OFFSET BUILT_BPB    ;-- (build bpb)
        DW    OFFSET CTL_INPUT    ;-- ioctl input
        DW    OFFSET INPUT        ;-- input/read
        DW    OFFSET NINPUT       ;-- non destructiv input, no wait
        DW    OFFSET IN_STATUS    ;-- input status
        DW    OFFSET INP_FLUSH    ;-- input flush
        DW    OFFSET OUTPUT       ;-- output/write
        DW    OFFSET OUTPUTV      ;-- output/write with verify
        DW    OFFSET OUT_STATUS   ;-- output status
        DW    OFFSET OUT_FLUSH    ;-- output fluch
        DW    OFFSET CTL_OUTPUT   ;-- ioctl output

;------------------ service procedure --------------------------------
SERVICE PROC FAR
        PUSH  AX                              ;-- backup redister
        PUSH  CX
        PUSH  DX
        PUSH  BP
        PUSH  SI
        PUSH  DI
        PUSH  DS
        PUSH  ES
        CLD
        LDS   BX,CS:[STOREDB]                 ;-- ds:bx := pointer to datablock
        MOV   WORD PTR [BX+03H],0000H         ;-- set status: no error, not done
        MOV   DL,[BX+02H]
        XOR   DH,DH                           ;-- dx := commnd code
        SHL   DL,1                            ;-- zum word addressieren
        MOV   SI,DX
        CALL  CS:[SI+JUMPER]                  ;-- aufruf der procedure
        LDS   BX,CS:[STOREDB]                 ;-- ds:bx := pointer to db
        OR    WORD PTR [BX+03H],0100H         ;-- set status: done und ?
        POP   ES                              ;-- restore register
        POP   DS
        POP   DI
        POP   SI
        POP   BP
        POP   DX
        POP   CX
        POP   BX
        POP   AX
        RET                                   ;-- return far
SERVICE ENDP

;---------------------------------------------------------------------
MEDIA_CHECK PROC NEAR                         ;-- media check
        MOV   WORD PTR [BX+03H],8003H         ;-- set status: error
        RET                                   ;--   err.code: unknown command
MEDIA_CHECK ENDP

;---------------------------------------------------------------------
BUILD_BPB PROC NEAR                           ;-- build bpb
        MOV   WORD PTR [BX+03H],8003H         ;-- set status: error
        RET                                   ;--   err.code: unknown command
BUILD_BPB ENDP

;---------------------------------------------------------------------
CTL_INPUT PROC NEAR                           ;-- i/o control string input
        MOV   CX,[BX+12H]                     ;-- byte count
        LDS   DI,DWORD PTR [BX+0EH]           ;-- ds:di := transfer address
        MOV   AL,CS:[PRNSTA]
        MOV   [DI],AL                         ;-- erstes byte : drucker status
        CMP   CX,+02H
        JNE   L01A5                           ;-- keine zwei bytes
        INC   DI                              ;-- zweites byte :
        MOV   AL,CS:[TMODE]                   ;--    transparentmode = 01
        MOV   [DI],AL
L01A5:  RET
CTL_INPUT ENDP

;---------------------------------------------------------------------
INPUT   PROC NEAR                             ;-- input/read
        CALL  CTL_INPUT
        RET
INPUT   ENDP

;---------------------------------------------------------------------
NINPUT  PROC NEAR                             ;-- non destructiv input
        MOV   AL,CS:[PRNSTA]                  ;-- hole byte aus buffer
        MOV   [BX+0DH],AL                     ;-- in byte read from device
        RET
NINPUT  ENDP

;---------------------------------------------------------------------
IN_STATUS PROC NEAR                           ;-- input status
        RET
IN_STATUS ENDP

;---------------------------------------------------------------------
INP_FLUSH PROC NEAR                           ;-- input flush
        RET
INP_FLUSH ENDP

;---------------------------------------------------------------------
OUTPUT  PROC NEAR                             ;-- output
        MOV   CX,[BX+12H]                     ;-- byte count
        LDS   SI,DWORD PTR [BX+0EH]           ;-- ds:si := transfer address
L01BA:  MOV   AL,[SI]                         ;-- zeichen für ausgabe in al
        PUSH  DS                              ;-- backup register
        PUSH  SI
        PUSH  CX
        PUSH  CS                              ;-- es := cs
        POP   ES
        MOV   CS:[FLAG_OC],01H                ;-- output ruft out_status
        PUSH  AX
L01C8:  CALL  OUT_STATUS
        CMP   BYTE PTR CS:[L0025],01H
        JE    L01C8                           ;-- bis druckerstatus <> 01
        POP   AX
        MOV   CS:[FLAG_OC],00H                ;-- output ruft nicht mehr out_sta
        CMP   CS:[TMODE],01H
        JNE   L01ED
        PUSH  AX                              ;-- transparent mode ist ein
        MOV   AX,CS
        MOV   DS,AX                           ;-- ds := cs
        POP   AX                              ;-- ohne ax zu ändern
        CALL  INBUF
        JMP   SHORT L01F0
L01ED:  CALL  L0B38
L01F0:  POP   CX
        POP   SI
        POP   DS
        INC   SI                              ;-- auf nächstes zeichen
        LOOP  L01BA                           ;-- bis alle zeichen verarbeitet
        CMP   BYTE PTR CS:[L1A72],01H
        JNE   L0210
        TEST  BYTE PTR CS:[PRNSTA],02H
        JE    L0210
        LDS   BX,CS:[STOREDB]                 ;-- ds:bx auf datablock
        MOV   WORD PTR [BX+03H],8009H         ;-- set status: error
L0210:  RET                                   ;--   err.code: out of paper
OUTPUT  ENDP

;---------------------------------------------------------------------
OUTPUTV PROC NEAR                             ;-- output with verify
        CALL  OUTPUT                          ;-- genau wie output ohne verify
        RET
OUTPUTV ENDP

;---------------------------------------------------------------------
OUT_STATUS PROC NEAR                          ;-- output status
        MOV   AX,CS
        MOV   DS,AX
        MOV   ES,AX
        CLD
        CMP   BYTE PTR CS:[OUTSTA],01H
        JE    L0227
        CALL  WRITE_PRN
L0227:  CMP   CS:[TMODE],01H
        JE    L026C                           ;-- falls transparent mode ein
        CMP   BYTE PTR CS:[090BH],01H
        JE    L026C
        CMP   BYTE PTR CS:[066DH],01H
        JE    L0241
        JMP   SHORT L0290
L0241:  CMP   WORD PTR CS:[1924H],0100H
        JNBE  L0277
        CMP   BYTE PTR CS:[066FH],00H
        JNE   L025F
        CMP   BYTE PTR CS:[1253H],01H
        JNE   L0264
        CALL  L1513
        JMP   SHORT L0264
L025F:  CALL  L0C9C
        JMP   SHORT L0277
L0264:  MOV   BYTE PTR CS:[066DH],00H
        JMP   SHORT L0290
L026C:  MOV   DX,CS:[1924H]
        CMP   DX,01F9H
        JB    L0290
L0277:  MOV   BYTE PTR CS:[0025H],01H
        CMP   CS:[FLAG_OC],01H
        JE    L028F                           ;-- output hat aufgerufen
        LDS   BX,DWORD PTR CS:[STOREDB]
        MOV   WORD PTR [BX+03H],0200H
L028F:  RET
L0290:  MOV   BYTE PTR CS:[0025H],00H
        RET
OUT_STATUS ENDP

;---------------------------------------------------------------------
OUT_FLUSH PROC NEAR                           ;-- output flush
        RET
OUT_FLUSH ENDP

MYNAME  DB    'PRN Generalized Printer Driver, CPU  v2.00   ',0DH,0AH,00H

;---------------------------------------------------------------------
CTL_OUTPUT PROC NEAR
        MOV   CX,[BX+12H]                     ;-- byte count
        LDS   SI,DWORD PTR [BX+0EH]           ;-- ds:si := transfer address
        MOV   AL,[SI]                         ;-- erstes bytes lesen

        CMP   AL,0FFH                         ;-- 0FFH <=>
        JNE   L02F6                           ;--       display identify message
        CMP   CX,+07H
        JB    L0339                           ;-- falls länge < 07 abbrechen
        INC   SI                              ;--
        LES   DI,DWORD PTR [SI]               ;-- es:di :=ads buffer für message
        MOV   CX,[SI+04H]                     ;-- cx := läge des buffers
        CMP   CX,MYNAME_LEN
        JBE   L02E7
        MOV   CX,MYNAME_LEN                   ;-- max. den namen übertragen
L02E7:  MOV   [SI+04H],CX                     ;-- setzt anzahl der geschr. bytes
        PUSH  DS                              ;-- backup ds-register
        PUSH  CS
        POP   DS                              ;-- ds:si auf den namen
        MOV   SI,OFFSET MYNAME
        REPZ  MOVSB                           ;-- namen übertragen
        POP   DS                              ;-- restroe ds-register
        JMP   L0339                           ;-- fertig

L02F6:  CMP   AL,0FEH                         ;-- 0EF <=>
        JNE   L0315
        CMP   CX,+05H
        JB    L0339
        INC   SI
        LES   DI,DWORD PTR [SI]               ;-- ds:si :=
        MOV   CS:[L1A72],DI
        MOV   CS:2[L1A72],ES
        MOV   BYTE PTR CS:[L1A76],00H
        JMP   L0339

L0315:  CMP   AL,0FDH                         ;-- 0FDH <=>
        JNE   L0322
        MOV   BYTE PTR CS:[1976H],01H
        JMP   L0339

L0322:  CMP   AL,0FCH                         ;-- 0FCH <=> transparent mode ein
        JNE   L032F
        MOV   CS:[TMODE],01H
        JMP   L0339

L032F:  CMP   AL,0FBH                         ;-- 0FBH <=> transparent mode aus
        JNE   L0339
        MOV   CS:[TMODE],00H
L0339:  RET
CTL_OUTPUT ENDP

L033A:  DW    3 DUP(0000H)
L0340:  DB    'Copyright, Wang Laboratories, Inc., 1985'

PDT     DB    0200H DUP (00H)                 ;-- escape codes
CTT     DB    0200H DUP (00H)                 ;-- character translation table
TMODE   DB    00H                        ;0799;-- = 01 falls transparent modus
        DB    954 DUP (00H)
        DB    07H

        OR      [BP+SI],CX ;DB 09H,0AH
        OR      AL,0DH ;DB 0CH,0DH
        SBB     AX,[BX+SI] ;DB 1BH,00H
        DB      6CH
        ADC     [BP+DI+11H],SI ;DB 11H,73H,11H
        MOVSB ;DB 0A4H
        ADC     SI,CX ;DB 11H,0CEH
        ADC     BX,SI ;DB 11H,0F3H
        ADC     [DI+12H],AX ;DB 11H,45H,12H
        INT     0AH ;DB 0CDH,0AH

L0B38:  PUSH  CS
        POP   DS                              ;-- ds := cs
        CMP   BYTE PTR DS:[1250H],01H
        JNE   L0B50
        CALL  INBUF
        DEC   WORD PTR DS:[1251H]
        JNZ   L0B4F
        MOV   BYTE PTR DS:[1250H],00H
L0B4F:  RET

L0B50:  MOV   BYTE PTR DS:[0915H],AL
        CMP   BYTE PTR DS:[0674H],01H
        JE    L0B98
        MOV   BYTE PTR DS:[0674H],01H
        MOV   BYTE PTR DS:[067AH],01H
        MOV   BX,0038H
        CALL  L1245
        XOR   AL,AL
        MOV   DI,0906H
        MOV   CX,000FH
        REPNZ STOSB
        MOV   BYTE PTR DS:[0678H],01H
        MOV   BYTE PTR DS:[0673H],01H
        CMP   BYTE PTR DS:[066AH],01H
        JNE   L0B8D
        MOV   WORD PTR DS:[0676H],0050H
        JMP   SHORT L0B93
L0B8D:  MOV   ORD PTR DS:[0676H],0084H
L0B93:  MOV   BYTE PTR DS:[0675H],06H
L0B98:  CMP   BYTE PTR DS:[0913H],00H
        JE    L0BA9
        MOV   AL,0AH
        CALL  INBUF
        MOV   BYTE PTR DS:[0913H],00H
L0BA9:  MOV   AL,BYTE PTR DS:[0915H]
        CMP   BYTE PTR DS:[091FH],01H
        JNE   L0BB6
        JMP   L1365
L0BB6:  CMP   AL,20H
        JNB   L0BCE
        MOV   DI,0A23H
        MOV   CX,0007H
        REPNZ SCASB
        MOV   BX,0A24H
        SUB   DI,BX
        SHL   DI,1
        JMP   WORD PTR [DI+0A2AH]
        RET

L0BCE:  CMP   BYTE PTR DS:[0668H],01H
        JNE   L0BEF
        MOV   BX,OFFSET CTT
        XLAT
        MOV   CL,AL
        MOV   AL,BYTE PTR DS:[0915H]
        MOV   AH,01H
        ADD   BX,AX
        MOV   AL,[BX]
        CMP   AL,00H
        JE    L0BED
        MOV   BYTE PTR DS:[066CH],01H
L0BED:  MOV   AL,CL
L0BEF:  CMP   BYTE PTR DS:[090BH],01H
        JNE   L0BFA
        CALL  L1052
        DB    0C3H    ; RET

L0BFA:  CALL  L0BFE
        DB    0C3H    ; RET

L0BFE:  MOV   BYTE PTR DS:[0910H],00H
        MOV   BX,DS:[0906H]
        PUSH  AX
        PUSH  BX
        CMP   BX,+00H
        JNE   L0C29
        CMP   BYTE PTR DS:[066AH],01H
        JNE   L0C29
        CMP   WORD PTR DS:[0676H],0084H
        JNE   L0C29
        MOV   BX,0128H
        CALL  L1245
        MOV   BX,0110H
        CALL  L1245
L0C29:  POP   BX
        POP   AX
        CMP   BX,+00H
        JNE   L0C65
        CMP   BYTE PTR DS:[0911H],00H
        JE    L0C65
        PUSH  AX
        PUSH  CX
        MOV   CL,DS:[0672H]
L0C3D:  MOV   CH,DS:[0671H]
L0C41:  MOV   AL,20H
        MOV   [BX+067BH],AL
        XOR   AL,AL
        MOV   [BX+0754H],AL
        MOV   AL,20H
        MOV   [BX+082DH],AL
        INC   WORD PTR DS:[0906H]
        MOV   BX,DS:[0906H]
        DEC   CH
        JNE   L0C41
        DEC   CL
        JNE   L0C3D
        POP   CX
        POP   AX
L0C65:  MOV   BYTE PTR DS:[090FH],00H
        MOV   [BX+067BH],AL
        MOV   AL,BYTE PTR DS:[0908H]
        MOV   [BX+0754H],AL
        MOV   AL,BYTE PTR DS:[0915H]
        MOV   [BX+082DH],AL
        INC   WORD PTR DS:[0906H]
        MOV   AX,WORD PTR DS:[0676H]
        CMP   AX,DS:[0906H]
        JE    L0C8A
        DB    0C3H    ; RET

L0C8A:  MOV   BYTE PTR DS:[090FH],01H
        CALL  L0D1C
        DB    0C3H    ; RET

L0C93:  ADD   AL,[SI]
        PUSH  ES
        JO    L0CA4
        DEC   BYTE PTR [SI]
        DEC   AX
        OR    AX,3E80H
        DB    6EH
        PUSH  ES ;DB 06H
        ADD   [SI+16H],SI ;DB 01H,74H,16H
        MOV   AL,BYTE PTR DS:[066FH] ;DB 0A0H,6FH,06H
        MOV   DI,0B93H ;DB 0BFH,93H,0BH
        MOV   CX,0003H ;DB 0B9H,03H,00H
        REPNZ SCASB ;DB 0AEH
        MOV   SI,0B94H ;DB 0BEH,94H,0BH
        SUB   DI,SI ;DB 2BH,0FEH
        SHL   DI,1
        JMP   WORD PTR [DI+0B96H]
        JMP   L0FB1
        ADD   AL,[BP+DI]
        ADD   AL,06H
        OR    [SI],CL
        SBB   [BP+SI],CL
        OR    DS:[0405H],AX
        ADD   AX,[BP+SI]
        ADD   [BX+DI],AX
L0CCC:  DW    2 DUP(0000H)
        ADD   [BP+DI],CL ;DB 00H,0BH
        ADD   [BX],AL ;DB 00H,07H
        ADD   [DI],AL ;DB 00H,05H
        ADD   [BP+DI],AL ;DB 00H,03H
        ADD   [BP+SI],AL ;DB 00H,02H
        ADD   [BX+DI],AL ;DB 00H,01H
        ADD   [BX+DI],AL ;DB 00H,01H
        ADD   [BP+DI],CL ;DB 00H,0BH
        OR    AL,[BX] ;DB 0AH,07H
        PUSH  ES
        ADD   AX,0304H
        ADD   AL,[BP+SI]
        ADD   [BX+DI],AX
L0CEA:  DW    0000H
        ADD   [BX+SI+0675H],AH ;DB 00H,0A0H,75H,06H
        MOV   DI,0BBCH ;DB 0BFH,0BCH,0BH
        MOV   CX,0007H ;DB 0B9H,07H,00H
        REPNZ SCASB ;DB 0AEH
        MOV   SI,0BBDH ;DB 0BEH,0BDH,0BH
        SUB   DI,SI ;DB 2BH,0FEH
        SHL   DI,1 ;DB 0D1H,0E7H
        CMP   BYTE PTR DS:[0670H],01H ;DB 80H,3EH,70H,06H,01H
        JNE   L0D07
        DB    0C3H    ; RET

L0D07:  CMP   BYTE PTR DS:[0914H],02H
        JNE   L0D0F
        INC   DI
L0D0F:  MOV   AL,[BX+DI]
        CMP   AL,00H
        JE    L0D1B
        MOV   BYTE PTR DS:[0917H],AL
        CALL  L0EC5
L0D1B:  DB    0C3H    ; RET

L0D1C:  MOV   BX,DS:[0906H]
        MOV   BYTE PTR [BX+067BH],00H
        MOV   BYTE PTR DS:[066EH],00H
        CMP   WORD PTR DS:[0906H],+00H
        JE    L0D9E
        MOV   BYTE PTR DS:[091BH],04H
        MOV   AL,BYTE PTR DS:[0912H]
        AND   AL,04H
        JE    L0D9E
        CMP   BYTE PTR DS:[0914H],00H
        JE    L0D4C
        MOV   BX,0BC3H
        CALL  L0CED
        JMP   SHORT L0D52
L0D4C:  MOV   BX,0BD1H
        CALL  L0CED
L0D52:  MOV   BYTE PTR DS:[0914H],00H
        CMP   BYTE PTR DS:[1253H],01H
        JNE   L0D63
        MOV   BYTE PTR DS:[1254H],01H
L0D63:  MOV   BYTE PTR DS:[066DH],01H
        MOV   BYTE PTR DS:[066FH],02H
        JMP   L0F1B
        CMP   BYTE PTR DS:[0914H],01H
        JNE   L0D8D
        CMP   BYTE PTR DS:[091DH],01H
        JNE   L0D9C
        MOV   BYTE PTR DS:[0917H],01H
        CALL  L0EC5
        MOV   BYTE PTR DS:[091DH],00H
        JMP   SHORT L0DC7
L0D8D:  CMP   BYTE PTR DS:[0675H],18H
        JE    L0D9C
        MOV   BYTE PTR DS:[0917H],01H
        CALL  L0EC5
L0D9C:  JMP   SHORT L0DC7
L0D9E:  CMP   BYTE PTR DS:[0914H],00H
        JE    L0DAD
        MOV   BX,0BDFH
        CALL  L0CED
        JMP   SHORT L0DC7
L0DAD:  CMP   BYTE PTR DS:[0673H],01H
        JE    L0DC7
        CMP   BYTE PTR DS:[090EH],01H
        JE    L0DC7
        CMP   BYTE PTR DS:[090DH],01H
        JE    L0DC7
        MOV   AL,0AH
        CALL  INBUF
L0DC7:  MOV   BYTE PTR DS:[0673H],00H
        MOV   BYTE PTR DS:[0914H],00H
        MOV   AL,BYTE PTR DS:[067BH]
        CMP   AL,00H
        JNE   L0DDB
        JMP   L0E6F
L0DDB:  MOV   BYTE PTR DS:[0918H],01H
        MOV   BYTE PTR DS:[091BH],06H
        CMP   BYTE PTR DS:[1253H],01H
        JNE   L0DF1
        MOV   BYTE PTR DS:[1254H],01H
L0DF1:  MOV   BYTE PTR DS:[066DH],01H
        MOV   BYTE PTR DS:[066FH],04H
        JMP   L0F1B
L0DFE:  MOV   BYTE PTR DS:[0918H],00H
        CMP   BYTE PTR DS:[0914H],01H
        JNE   L0E1E
        CMP   BYTE PTR DS:[091DH],01H
        JNE   L0E1E
        MOV   BYTE PTR DS:[0917H],01H
        CALL  L0EC5
        MOV   BYTE PTR DS:[091DH],00H
L0E1E:  MOV   BYTE PTR DS:[091BH],02H
        MOV   AL,BYTE PTR DS:[0912H]
        AND   AL,02H
        JNE   L0E2C
        JMP   SHORT L0E6F
L0E2C:  CMP   BYTE PTR DS:[0914H],01H
        JE    L0E3B
        MOV   BYTE PTR DS:[0917H],01H
        CALL  L0EC5
L0E3B:  MOV   BYTE PTR DS:[0914H],00H
        MOV   BYTE PTR DS:[066FH],06H
        JMP   L0F1B
        CMP   BYTE PTR DS:[0914H],01H
        JE    L0E56
        MOV   BYTE PTR DS:[0914H],01H
        JMP   SHORT L0E6F
L0E56:  MOV   BYTE PTR DS:[0914H],02H
        CMP   BYTE PTR DS:[091DH],01H
        JNE   L0E6F
        MOV   BYTE PTR DS:[0917H],01H
        CALL  L0EC5
        MOV   BYTE PTR DS:[091DH],00H
L0E6F:  CMP   BYTE PTR DS:[0916H],01H
        JNE   L0E9B
        MOV   AL,0CH
        CALL  INBUF
        MOV   BYTE PTR DS:[0916H],00H
        CMP   BYTE PTR DS:[066AH],01H
        JNE   L0E9B
        CMP   WORD PTR DS:[0676H],0084H
        JNE   L0E9B
        MOV   BX,0128H
        CALL  L1245
        MOV   BX,0110H
        CALL  L1245
L0E9B:  MOV   BYTE PTR DS:[066CH],00H
        MOV   AL,BYTE PTR DS:[0908H]
        MOV   BYTE PTR DS:[0912H],AL
        MOV   WORD PTR DS:[0906H],0000H
        MOV   BYTE PTR DS:[067BH],00H
        MOV   BYTE PTR DS:[066FH],00H
        DB    0C3H    ; RET

L0EB7:  JS    L0EB9
L0EB9:  JO    L0EBB
L0EBB:  DB    68H
        ADD   AL,BL ;DB 00H,0D8H
        ADD   AL,DL ;DB 00H,0D0H
        ADD   [BX+SI+00H],AH ;DB 00H,60H,00H
        DB    0C8H
        ADD   [BP+DI+51H],DL ;DB 00H,53H,51H
        PUSH  SI ;DB 56H
        PUSH  DI ;DB 57H
        MOV   BX,00E0H ;DB 0BBH,0E0H,00H
        CALL  L1245 ;DB 0E8H,76H,03H
        CMP   BYTE PTR DS:[091DH],01H ;DB 80H,3EH,1DH,09H,01H
        JNE   L0EE6 ;DB 75H,10H
        MOV   BX,00C0H ;DB 0BBH,0C0H,00H
        CALL  L1245 ;DB 0E8H,69H,03H
        CMP   DL,00H
        JNE   L0EEC
        MOV   BYTE PTR DS:[091DH],00H
L0EE6:  MOV   BX,00C8H
        CALL  L1245
L0EEC:  MOV   BH,DS:[0917H]
        MOV   AL,0AH
L0EF2:  CALL  INBUF
        DEC   BH
        JNE   L0EF2
        MOV   BX,00E0H
        CALL  L1245
        MOV   BYTE PTR DS:[0670H],01H
        CALL  L0CED
        MOV   BYTE PTR DS:[0670H],00H
        MOV   BX,0DB7H
        MOV   DX,[BX+DI]
        MOV   BX,DX
        CALL  L1245
        POP   DI
        POP   SI
        POP   CX
        POP   BX
        DB    0C3H    ; RET

L0F1B:  MOV   BYTE PTR DS:[0919H],00H
        MOV   BYTE PTR DS:[091AH],0FFH
        MOV   BYTE PTR DS:[091EH],00H
        MOV   CX,DS:[0906H]
        XOR   BX,BX
        MOV   BYTE PTR DS:[091CH],00H
L0F35:  MOV   AL,[BX+0754H]
        CMP   BYTE PTR DS:[0918H],01H
        JNE   L0F48
        TEST  AL,DS:[091BH]
        JNE   L0F6D
        JMP   SHORT L0F4E
L0F48:  TEST  AL,DS:[091BH]
        JE    L0F6D
L0F4E:  CMP   BYTE PTR DS:[0919H],01H
        JNE   L0F61
        CALL  L10BB
        CMP   AL,00H
        JE    L0F71
        CALL  L1052
        JMP   SHORT L0F71
L0F61:  CALL  L1232
        MOV   AL,[BX+067BH]
        CALL  L1052
        JMP   SHORT L0F71
L0F6D:  INC   BYTE PTR DS:[091CH]
L0F71:  INC   BX
        LOOP  L0F35
        CMP   BYTE PTR DS:[0919H],00H
        JE    L0F82
        CMP   BYTE PTR DS:[091EH],00H
        JE    L0F8C
L0F82:  MOV   AL,0DH
        CALL  INBUF
        MOV   BYTE PTR DS:[091EH],00H
L0F8C:  MOV   AL,BYTE PTR DS:[0912H]
        AND   AL,49H
        JNE   L0FAB
        CMP   BYTE PTR DS:[066CH],00H
        JNE   L0FAB
        CMP   BYTE PTR DS:[0918H],01H
        JNE   L0FB0
        MOV   AL,BYTE PTR DS:[0912H]
        AND   AL,02H
        JNE   L0FB0
        JMP   L0DFE
L0FAB:  MOV   BYTE PTR DS:[066EH],01H
L0FB0:  DB    0C3H    ; RET

L0FB1:  MOV   CX,DS:[0906H]
        XOR   BX,BX
        INC   BYTE PTR DS:[091AH]
        MOV   BYTE PTR DS:[091CH],00H
        MOV   BYTE PTR DS:[0919H],01H
        CMP   BYTE PTR DS:[091AH],00H
        JNE   L0FD8
        TEST  BYTE PTR DS:[0912H],01H
        JNE   L1042
        MOV   BYTE PTR DS:[091AH],02H
L0FD8:  CMP   BYTE PTR DS:[091AH],02H
        JNE   L0FEB
        TEST  BYTE PTR DS:[0912H],08H
        JNE   L1042
        MOV   BYTE PTR DS:[091AH],05H
L0FEB:  CMP   BYTE PTR DS:[091AH],05H
        JNE   L1009
        CMP   BYTE PTR DS:[0668H],01H
        JE    L0FFB
        JMP   SHORT L1004
L0FFB:  CMP   BYTE PTR DS:[066CH],00H
        JE    L1004
        JMP   SHORT L1042
L1004:  MOV   BYTE PTR DS:[091AH],0BH
L1009:  CMP   BYTE PTR DS:[091AH],06H
        JNE   L101C
        TEST  BYTE PTR DS:[0912H],01H
        JNE   L1042
        MOV   BYTE PTR DS:[091AH],08H
L101C:  CMP   BYTE PTR DS:[091AH],09H
        JNE   L102F
        TEST  BYTE PTR DS:[0912H],01H
        JNE   L1042
        MOV   BYTE PTR DS:[091AH],0BH
L102F:  CMP   BYTE PTR DS:[091AH],0BH
        JNE   L1042
        TEST  BYTE PTR DS:[0912H],40H
        JNE   L1042
        MOV   BYTE PTR DS:[091AH],0EH
L1042:  CMP   BYTE PTR DS:[091AH],0EH
        JE    L104C
        JMP   L0F35
L104C:  MOV   BYTE PTR DS:[066EH],00H
        DB    0C3H    ; RET

L1052:  CMP     BYTE PTR DS:[0668H],01H
        JNE     L108D
        CMP     AL,10H
        JNB     L1070
        PUSH    BX
        MOV     BL,AL
        XOR     BH,BH
        MOV     AL,1BH
        CALL    INBUF
        MOV     AL,[BX+CTT]
        CALL    INBUF
        POP     BX
        DB      0C3H    ; RET

L1070:  CMP     AL,80H
        JB      L108D
        CMP     BYTE PTR DS:[CTT],01H
        JNE     L108D
        PUSH    AX
        MOV     AL,0EH
        CALL    INBUF
        POP     AX
        AND     AL,7FH
        CALL    INBUF
        MOV     AL,0FH
        CALL    INBUF
        DB      0C3H    ; RET

L108D:  CALL    INBUF
        DB      0C3H    ; RET

L1091:  ADD     [BX+DI],AL
        ADD     AL,[BP+DI]
        ADD     AL,05H
        PUSH    ES
        POP     ES
        OR      [BX+DI],CL
        OR      CL,[BP+DI]
        OR      AL,0DH
        AAD      ;0FH
        AAD      ;0FH
        IN      AL,DX
        DB      0FH
        OR      AX,0D10H ;DB 0DH,10H,0DH
        ADC     [BX+SI],DH ;DB 10H,30H
        ADC     [BP+DI+10H],AL ;DB 10H,43H,10H
        INC     BX ;DB 43H
        ADC     [BP+10H],BL ;DB 10H,5EH,10H
        JNBE    L10C3 ;DB 77H,10H
        JNBE    L10C5 ;DB 77H,10H
        CBW ;DB 98H
        ADC     AL,AH ;DB 10H,0E0H
        ADC     AL,AH
        ADC     [BX+SI+51H],DL
        MOV     AL,BYTE PTR DS:[091AH]
        MOV     DI,0F91H
L10C3:  MOV     CX,000EH
        REPNZ   SCASB
        POP     CX
        POP     AX
        MOV     SI,0F92H
        SUB     DI,SI
        SHL     DI,1
        JMP     WORD PTR [DI+0F9FH]
        AND     AL,01H
        JE      L10E5
        CALL    L1232
        INC     BYTE PTR DS:[091EH]
        MOV     AL,[BX+067BH]
        DB      0C3H    ; RET

L10E5:  INC     BYTE PTR DS:[091CH]
        XOR     AL,AL
        DB      0C3H    ; RET

L10EC:  AND     AL,08H
        JE      L1106
        CALL    L1232
        INC     BYTE PTR DS:[091EH]
        CMP     BYTE PTR DS:[0668H],01H
        JNE     L1103
        MOV     AL,BYTE PTR DS:[04C7H]
        JMP     SHORT L1105
L1103:  MOV     AL,5FH
L1105:  DB      0C3H    ; RET

L1106:  INC     BYTE PTR DS:[091CH]
        XOR     AL,AL
        DB      0C3H    ; RET

L110D:  AND     AL,09H
        CMP     AL,09H
        JNE     L1129
        CALL    L1232
        INC     BYTE PTR DS:[091EH]
        CMP     BYTE PTR DS:[0668H],01H
        JNE     L1126
        MOV     AL,BYTE PTR DS:[04C7H]
        JMP     SHORT L1128
L1126:  MOV     AL,5FH
L1128:  DB      0C3H    ; RET

L1129:  INC     BYTE PTR DS:[091CH]
        XOR     AL,AL
        DB      0C3H    ; RET

L1130:  CALL    L1211
        AND     AL,0FH
        JE      L113C
        MOV     SI,AX
        JMP     L121E
L113C:  INC     BYTE PTR DS:[091CH]
        XOR     AL,AL
        DB      0C3H    ; RET

L1143:  CALL    L1211
        AND     AL,0FH
        JE      L1157
        MOV     SI,AX
        MOV     AL,[BX+0754H]
        AND     AL,01H
        JE      L1157
        JMP     L121E
L1157:  INC     BYTE PTR DS:[091CH]
        XOR     AL,AL
        DB      0C3H    ; RET

L115E:  CALL    L1211
        AND     AL,0F0H
        JE      L1170
        MOV     CL,04H
        ROR     AL,CL
        ADD     AL,10H
        MOV     SI,AX
        JMP     L121E
L1170:  INC     BYTE PTR DS:[091CH]
        XOR     AL,AL
        DB      0C3H    ; RET

L1177:  CALL    L1211
        AND     AL,0F0H
        JE      L1191
        MOV     CL,04H
        ROR     AL,CL
        ADD     AL,10H
        MOV     SI,AX
        MOV     AL,[BX+0754H]
        AND     AL,01H
        JE      L1191
        JMP     L121E
L1191:  INC     BYTE PTR DS:[091CH]
        XOR     AL,AL
        DB      0C3H    ; RET

L1198:  AND     AL,40H
        JE      L11D9
        CMP     BYTE PTR DS:[0675H],18H
        JE      L11D9
        CMP     BYTE PTR DS:[0675H],0CH
        JE      L11D9
        CMP     BYTE PTR DS:[0914H],01H
        JE      L11C3
        MOV     BYTE PTR DS:[0914H],01H
        MOV     BYTE PTR DS:[091DH],01H
        MOV     BYTE PTR DS:[0917H],01H
        CALL    L0EC5
L11C3:  CALL    L1232
        INC     BYTE PTR DS:[091EH]
        CMP     BYTE PTR DS:[0668H],01H
        JNE     L11D6
        MOV     AL,BYTE PTR DS:[04C7H]
        JMP     SHORT L11D8
L11D6:  MOV     AL,5FH
L11D8:  DB      0C3H    ; RET

L11D9:  INC     BYTE PTR DS:[091CH]
        XOR     AL,AL
        DB      0C3H    ; RET

L11E0:  AND     AL,41H
        CMP     AL,41H
        JNE     L120A
        CMP     BYTE PTR DS:[0675H],18H
        JE      L120A
        CMP     BYTE PTR DS:[0675H],0CH
        JE      L120A
        CALL    L1232
        INC     BYTE PTR DS:[091EH]
        CMP     BYTE PTR DS:[0668H],01H
        JNE     L1207
        MOV     AL,BYTE PTR DS:[04C7H]
        JMP     SHORT L1209
L1207:  MOV     AL,5FH
L1209:  DB      0C3H    ; RET

L120A:  INC     BYTE PTR DS:[091CH]
        XOR     AL,AL
        DB      0C3H    ; RET

L1211:  MOV     AL,[BX+082DH]
        MOV     AH,01H
        MOV     SI,AX
        MOV     AL,[SI+CTT]
        DB      0C3H    ; RET

L121E:  MOV     AL,[SI+CTT]
        XOR     AH,AH
        MOV     SI,AX
        CALL    L1232
        INC     BYTE PTR DS:[091EH]
        MOV     AL,[SI+CTT]
        DB      0C3H    ; RET

L1232:  CMP     BYTE PTR DS:[091CH],00H
        JE      L1244
L1239:  MOV     AL,20H
        CALL    INBUF
        DEC     BYTE PTR DS:[091CH]
        JNE     L1239
L1244:  DB      0C3H    ; RET

L1245:  XOR     DL,DL                         ;-- dl := 0
L1247:  MOV     AL,[BX+PDT]
        CMP     AL,0FEH
        JE      L1266
        CMP     BYTE PTR DS:[067AH],00H
        JE      L125E
        CMP     AL,11H
        JNE     L125E
        INC     BYTE PTR DS:[0679H]
L125E:  CALL    INBUF
        MOV     DL,01H
        INC     BX
        JMP     SHORT L1247
L1266:  MOV     BYTE PTR DS:[067AH],00H
        RET

L126C:  MOV     BX,OFFSET STOREDB
        CALL    L1245
        DB      0C3H    ; RET

L1273:  CMP     BYTE PTR DS:[090BH],01H
        JE      L12A3
        CMP     BYTE PTR DS:[0911H],00H
        JNE     L12A3
        MOV     AX,WORD PTR DS:[0906H]
        MOV     CL,08H
        DIV     CL
        MOV     AL,AH
        MOV     AH,08H
        SUB     AH,AL
        XOR     CX,CX
        MOV     CL,AH
L1292:  MOV     AX,WORD PTR DS:[0906H]
        INC     AX
        CMP     AX,DS:[0676H]
        JE      L12A3
        MOV     AL,20H
        CALL    L0BFE
        LOOP    L1292
L12A3:  DB      0C3H    ; RET

L12A4:  CMP     BYTE PTR DS:[090BH],01H
        JNE     L12B8
        CMP     BYTE PTR DS:[090DH],01H
        JE      L12B7
        MOV     AL,0AH
        CALL    INBUF
L12B7:  DB      0C3H    ; RET

L12B8:  MOV     BYTE PTR DS:[0910H],00H
        CMP     BYTE PTR DS:[090EH],01H
        JE      L12C8
        CALL    L0D1C
        DB      0C3H    ; RET

L12C8:  MOV     BYTE PTR DS:[090EH],00H
        DB      0C3H    ; RET

L12CE:  CMP     BYTE PTR DS:[090BH],01H
        JNE     L12DB
        MOV     AL,0CH
        CALL    INBUF
        DB      0C3H    ; RET

L12DB:  MOV     BYTE PTR DS:[0910H],00H
        MOV     BYTE PTR DS:[090EH],00H
        MOV     BYTE PTR DS:[0916H],01H
        CALL    L0D1C
        MOV     BYTE PTR DS:[0673H],01H
        DB      0C3H    ; RET

L12F3:  CMP     BYTE PTR DS:[090BH],01H
        JNE     L130C
        MOV     AL,0DH
        CALL    INBUF
        CMP     BYTE PTR DS:[0678H],01H
        JE      L1344
        MOV     AL,0AH
        CALL    INBUF
        DB      0C3H    ; RET

L130C:  CMP     BYTE PTR DS:[0910H],01H
        JE      L133A
        CMP     BYTE PTR DS:[090FH],01H
        JE      L132F
        CALL    L0D1C
        MOV     BYTE PTR DS:[090EH],01H
        CMP     BYTE PTR DS:[0678H],01H
        JE      L1344
        MOV     BYTE PTR DS:[0913H],01H
        DB      0C3H    ; RET

L132F:  MOV     BYTE PTR DS:[090FH],00H
        MOV     BYTE PTR DS:[090EH],01H
        DB      0C3H    ; RET

L133A:  MOV     BYTE PTR DS:[0910H],00H
        MOV     BYTE PTR DS:[090EH],01H
L1344:  DB      0C3H    ; RET

L1345:  MOV     BYTE PTR DS:[091FH],01H
        MOV     BYTE PTR DS:[0A20H],00H
        DB      0C3H    ; RET

L1350:  DW      3 DUP(0000H)
L1356:  DB      '0123456789+-;[]'
L1365:  MOV     DI,1256H ;DB 0BFH,56H,12H
        MOV     CX,000FH ;DB 0B9H,0FH,00H
        REPNZ   SCASB ;DB 0AEH
        JE      L1387 ;DB 74H,18H
L136F:  DB      '< v%<Ar!<Zv'
        OR      [SI],BH ;DB 08H,3CH
        DB      61H
        JB      L1398 ;DB 72H,19H
        CMP     AL,7AH ;DB 3CH,7AH
        JNBE    L1398 ;DB 77H,15H
        CALL    L13D5 ;DB 0E8H,4FH,00H
        DB      0C3H    ; RET

L1387:  MOV     BL,DS:[0A20H]
        XOR     BH,BH
        MOV     DI,BX
        MOV     BX,0920H
        MOV     [BX+DI],AL
        INC     BYTE PTR DS:[0A20H]
L1398:  DB      0C3H    ; RET

L1399:  DB      'c[d[e[o[h[l[m[n[a[z[b[v[w[k[  '
        POPF ;DB 9DH
        ADC     SI,BP ;DB 13H,0F5H
        ADC     BX,[DI+0914H] ;DB 13H,9DH,14H,09H
        ADC     AX,15A0H ;DB 15H,0A0H,15H
        DB      0CAH,15H,0EEH   ; RETF

L13C4:  ADC     AL,[BP+SI+13H]
        SBB     DL,DS:[1622H]
        AND     AL,16H
        XOR     AL,16H
        DEC     DI
        PUSH    SS
        JNB     L13E9
        TEST    DL,DS:[20BBH]
        OR      [BP+SI+0BF27H],CX
        CWD
        ADC     BH,[BX+DI+000FH]
        REPNZ   SCASW
        MOV     BX,129BH
        SUB     DI,BX
        JMP     WORD PTR [DI+12B7H]
L13EB:  JMP     SHORT L143C
        NOP
        CALL    L178A
        MOV     CL,DS:[0A21H]
        AND     CL,CL
        JE    L13EB
        XOR   BX,BX
        XOR   CH,CH
        SHR   CX,1
L13FF:  PUSH  CX
        MOV   AX,[BX+0920H]
        MOV   DL,0F9H
        AND   AL,AL
        JE    L1410
        MOV   DL,80H
        MOV   CL,AL
        ROL   DL,CL
L1410:  OR    DS:[0908H],DL
        OR    DS:[0912H],DL
        TEST  DL,08H
        JE    L1422
        MOV   BYTE PTR DS:[0909H],0FFH
L1422:  TEST  DL,40H
        JE    L1436
        MOV   BYTE PTR DS:[090AH],0FFH
        OR    BYTE PTR DS:[0908H],08H
        OR    BYTE PTR DS:[0912H],08H
L1436:  POP   CX
        ADD   BX,+02H
        LOOP  L13FF
L143C:  JMP   L1784
L143F:  JMP   L149A
        CALL  L178A
        MOV   CL,DS:[0A21H]
        AND   CL,CL
        JE    L143F
        XOR   CH,CH
        SHR   CX,1
        XOR   BX,BX
L1453:  PUSH  CX
        MOV   AX,[BX+0920H]
        XOR   DL,DL
        AND   AL,AL
        JE    L1464
        MOV   DL,7FH
        MOV   CL,AL
        ROL   DL,CL
L1464:  AND   DS:[0908H],DL
        TEST  DL,08H
        JNE   L147E
        MOV   BYTE PTR DS:[0909H],00H
        CMP   BYTE PTR DS:[090AH],0FFH
        JNE   L147E
        OR    BYTE PTR DS:[0908H],08H
L147E:  TEST  DL,40H
        JNE   L1494
        MOV   BYTE PTR DS:[090AH],00H
        CMP   BYTE PTR DS:[0909H],0FFH
        JE    L1494
        AND   BYTE PTR DS:[0908H],0F7H
L1494:  POP   CX
        ADD   BX,+02H
        LOOP  L1453
L149A:  JMP   L1784
        CALL  L178A
        MOV   AX,WORD PTR DS:[0920H]
        CMP   BYTE PTR DS:[0A21H],00H
        JNE   L14AD
        MOV   AX,0000H
L14AD:  MOV   DX,0000H
        MOV   CX,01F4H
        DIV   CX
        MOV   DL,AL
        MOV   AX,WORD PTR DS:[0676H]
        MOV   I,13E1H
        MOV   CX,0014H
        REPNZ SCASB
        MOV   DH,[DI]
        CMP   DL,00H
        JE    L14D9
        MOV   BYTE PTR DS:[0911H],01H
        MOV   DS:[0671H],DH
        MOV   DS:[0672H],DL
        JMP   L1784
L14D9:  MOV   BYTE PTR DS:[0911H],00H
        JMP   L1784
        SUB   [BP+DI],AL
        INC   DX
        ADD   DX,[BX+SI+05H]
        TEST  AL,[DI]
        DB    60H
        PUSH  ES ;DB 06H
        SAHF ;DB 9EH
        PUSH  ES ;DB 06H
        JS    L14F7 ;DB 78H,08H
        MOV   BYTE PTR [BX+SI],84H ;DB 0C6H,08H,84H
        OR    CL,BL ;DB 08H,0D9H
        OR    [BX+SI+0B3EH],AL ;DB 08H,80H,3EH,0BH
        OR    [BX+DI],AX ;DB 09H,01H
        JE    L1522 ;DB 74H,26H
        CMP   BYTE PTR DS:[090FH],01H
        JE    L1522
        MOV   BYTE PTR DS:[1253H],01H
        CALL  L12A4
        CMP   BYTE PTR DS:[1254H],00H
        JE    L1518
        DB    0C3H    ; RET

L1513:  MOV   BYTE PTR DS:[1254H],00H
L1518:  MOV   BYTE PTR DS:[1253H],00H
        MOV   BYTE PTR DS:[0910H],01H
L1522:  MOV   BYTE PTR DS:[090DH],00H
        MOV   BX,00E0H
        CALL  L1245
        CALL  L178A
        MOV   AX,WORD PTR DS:[0920H]
        CMP   BYTE PTR DS:[0A21H],00H
        JNE   L153D
        MOV   AX,00A6H
L153D:  XOR   BX,BX
L153F:  CMP   AX,[BX+146DH]
        JB    L1568
        ADD   BX,+02H
        MOV   AL,[BX+146DH]
        MOV   BYTE PTR DS:[0675H],AL
        ADD   BX,+02H
        MOV   BX,[BX+146DH]
        CALL  L1245
        CMP   BYTE PTR DS:[0675H],00H
        JNE   L1565
        MOV   BYTE PTR DS:[090DH],01H
L1565:  JMP   L1784
L1568:  ADD   BX,+06H
        JMP   SHORT L153F
        REPNZ ADD     [BP+SI],AX
        ADD   [BX+SI+00H],BH
        DEC   SP
        ADD   [BP+DI],AX
        ADD   [BX+SI+00H],DH
        STC
        ADD   [SI],AL
        ADD   [BX+SI+00H],CH
        CMPSB
        ADD   DS:[0D800H],AL
        ADD   [DI+00H],BH
        OR    [BX+SI],AL
        ROL   B,[BX+SI],1
        ADD   DS:[SI],CL
        ADD   [BX+SI+00H],AH
        POP   DS
        ADD   [BX+SI],BL
        ADD   AL,CL
L1596:  DW    2 DUP(0000H)
        ADD   AL,CL ;DB 00H,0C8H
        ADD   [BP+DI+01B0H],BH ;DB 00H,0BBH,0B0H,01H
        CALL  L1245 ;DB 0E8H,0A2H,0FCH
        CALL  L178A ;DB 0E8H,0E4H,01H
        MOV   AX,WORD PTR DS:[0920H] ;DB 0A1H,20H,09H
        CMP   BYTE PTR DS:[0A21H],00H ;DB 80H,3EH,21H,0AH,00H
        JNE   L15B3 ;DB 75H,03H
        MOV   AX,2AF8H ;DB 0B8H,0F8H,2AH
L15B3:  XOR   BX,BX ;DB 33H,0DBH
L15B5:  CMP   AX,[BX+14CDH]
        JB    L15C8
        ADD   BX,+02H
        MOV   BX,[BX+14CDH]
        CALL  L1245
        JMP   L1784
L15C8:  ADD   BX,+04H
        JMP   L15B5
        MOVSB
        CMP   [BX+SI+0BC01H],CH
        XOR   AL,0A0H
        ADD   SP,DX
        XOR   [BX+SI+0EC01H],BL
        SUB   AL,90H
        ADD   [SI],AX
        SUB   [BX+SI+1C01H],CX
        AND   AX,0180H
        XOR   AL,21H
        JS    L15EA
        DEC   SP
L15EA:  SBB   AX,0170H
        DB    64H
        SBB   [BX+SI+01H],BP ;DB 19H,68H,01H
        JL    L1608 ;DB 7CH,15H
        DB    60H
        ADD   [SI+5811H],DX ;DB 01H,94H,11H,58H
        ADD   [SI+500DH],BP ;DB 01H,0ACH,0DH,50H
        ADD   SP,AX ;DB 01H,0C4H
        OR    [BX+SI+01H],CX ;DB 09H,48H,01H
        ESC   20,[DI] ;DB 0DCH,05H
        INC   AX ;DB 40H
        ADD   [BX+SI],AX ;DB 01H,00H
        ADD   [BX+SI],BH ;DB 00H,38H
L1608:  ADD   [BP+DI+0120H],DI ;DB 01H,0BBH,20H,01H
        CALL  L1245
        MOV   BYTE PTR DS:[090BH],00H
        CALL  L178A
        MOV   AX,WORD PTR DS:[0920H]
        CMP   BYTE PTR DS:[0A21H],00H
        JNE   L1624
        MOV   AX,0064H
L1624:  XOR   BX,BX
L1626:  CMP   AX,[BX+1570H]
        JB    L166B
        CMP   AX,003CH
        JNB   L1638
        MOV   BYTE PTR DS:[090BH],01H
        JMP   L1640
L1638:  PUSH  BX
        MOV   BX,0128H
        CALL  L1245
        POP   BX
L1640:  CMP   BYTE PTR DS:[066AH],01H
        JE    L164A
        ADD   BX,+02H
L164A:  ADD   BX,+02H
        MOV   AX,[BX+1570H]
        MOV   WORD PTR DS:[0676H],AX
        CMP   BYTE PTR DS:[066AH],01H
        JNE   L165E
        ADD   BX,+02H
L165E:  ADD   BX,+02H
        MOV   BX,[BX+1570H]
        CALL  L1245
        JMP   L1784

L166B:  ADD   BX,+08H
        JMP   SHORT L1626
        DB    0C8H
        ADD   [BX+SI],CH ;DB 00H,28H
        ADD   [BP+SI+00H],AL ;DB 00H,42H,00H
        DB    0F0H    ; LOCK
        ADD   [SI+00H],AH
        PUSH  AX
        ADD   [SI+0F800H],AL
        ADD   [BP+DI+00H],DL
        DB    60H
        ADD   [BP+0000H],BL ;DB 00H,9EH,00H,00H
        ADD   [BP+SI+00H],AX ;DB 01H,42H,00H
        JS    L168C ;DB 78H,00H
L168C:  MOV   BYTE PTR [BX+SI],08H ;DB 0C6H,00H,08H
        ADD   [SI],DI ;DB 01H,3CH
        ADD   [SI+0D900H],AL ;DB 00H,84H,00H,0D9H
        ADD   [BX+SI],DL ;DB 00H,10H
        ADD   [BX+SI],AX ;DB 01H,00H
        ADD   [BX+SI+00H],DL ;DB 00H,50H,00H
        TEST  AL,[BX+SI]
        SBB   [BX+DI],AL
        CALL  L178A
        CMP   BYTE PTR DS:[0A21H],00H
        JE    L16C7
        XOR   CH,CH
        MOV   CL,DS:[0A21H]
        SHR   CX,1
        XOR   BX,BX
L16B4:  MOV   AX,[BX+0920H]
        ADD   BX,+02H
        CMP   AX,0001H
        JNE   L16C5
        MOV   BYTE PTR DS:[0678H],00H
L16C5:  LOOP  L16B4
L16C7:  JMP   L1784

        CALL  L178A
        CMP   BYTE PTR DS:[0A21H],00H
        JE    L1717
        XOR   CH,CH
        MOV   CL,DS:[0A21H]
        SHR   CX,1
        XOR   BX,BX
L16DE:  MOV   AX,[BX+0920H]
        ADD   BX,+02H
        CMP   AX,0001H
        JNE   L16F2
        MOV   BYTE PTR DS:[0678H],01H
        JMP   L1715

L16F2:  CMP   AX,0000H
        JNE   L1715
        CMP   BYTE PTR DS:[1255H],01H
        JE    L1715
        MOV   BYTE PTR DS:[0A22H],01H
        OR    BYTE PTR DS:[PRNSTA],08H
        CALL  L1ADC
        INC   BYTE PTR DS:[090CH]
        MOV   BX,0030H
        CALL  L1245
L1715:  LOOP  L16DE
L1717:  JMP   L1784

L171A:  MOV   BYTE PTR DS:[0674H],00H
        JMP   L1784

        JMP   L171A

        CMP   BYTE PTR DS:[027AH],00H
        JE    L1731
        MOV   BX,01D0H
        CALL  L1245
L1731:  JMP   L1784
        CMP   BYTE PTR DS:[027AH],00H
        JE    L174C
        MOV   BX,01C8H
        CALL  L1245
        CALL  L178A
        MOV   AX,WORD PTR DS:[0920H]
        ADD   AL,30H
        CALL  INBUF
L174C:  JMP   L1784
        CMP   BYTE PTR DS:[027AH],00H
        JE    L1770
        MOV   BX,01C0H
        CALL  L1245
        CALL  L178A
        MOV   CL,04H
        MOV   AX,WORD PTR DS:[0920H]
        ROL   AL,CL
        MOV   CL,AL
        MOV   AX,WORD PTR DS:[0922H]
        OR    AL,CL
        CALL  INBUF
L1770:  JMP   L1784
        CALL  L178A
        MOV   AX,WORD PTR DS:[0920H]
        MOV   WORD PTR DS:[1251H],AX
        MOV   BYTE PTR DS:[1250H],01H
        JMP   L1784
L1784:  MOV   BYTE PTR DS:[091FH],00H
        RET

L178A:  MOV   BYTE PTR DS:[0A21H],00H
        MOV   BX,0920H
        INC   BX
        MOV   CL,DS:[0A20H]
        XOR   CH,CH
        DEC   CX
        XOR   SI,SI
L179C:  CMP   SI,CX
        JNB   L17FE
        MOV   AL,[BX+SI]
        MOV   DH,00H
        CMP   AL,2DH
        JNE   L17AE
        MOV   DH,01H
        INC   SI
        JMP   L17B3
L17AE:  CMP   AL,2BH
        JNE   L17B3
        INC   SI
L17B3:  PUSH  SI
L17B4:  MOV   DI,1256H
        PUSH  CX
        MOV   CX,000AH
        MOV   AL,[BX+SI]
        REPNZ SCASB
        POP   CX
        JE    L17CD
        CMP   AL,3BH
        JE    L17D0
        CMP   SI,CX
        JE    L17D0
        POP   DX
        JMP   L179C
L17CD:  INC   SI
        JMP   L17B4
L17D0:  MOV   DI,SI
        DEC   DI
        POP   SI
        PUSH  BX
        PUSH  DX
        CALL  L1801
        POP   DX
        POP   BX
        AND   DH,DH
        JE    L17E1
        NEG   AX
L17E1:  MOV   SI,DI
        PUSH  BX
        XOR   BH,BH
        MOV   BL,DS:[0A21H]
        MOV   [BX+0920H],AL
        INC   BX
        MOV   [BX+0920H],AH
        POP   BX
        ADD   BYTE PTR DS:[0A21H],02H
        ADD   SI,+02H
        JMP   L179C
L17FE:  RET

L17FF:  OR    AL,[BX+SI]
L1801:  XOR   AX,AX
        DEC   SI
L1804:  INC   SI
        MUL   WORD PTR DS:[16FFH]
        JB    L181A
        AND   BYTE PTR [BX+SI],0FH
        ADD   AL,[BX+SI]
        ADC   AH,00H
        JS    L181A
        CMP   SI,DI
        JNE   L1804
        RET
L181A:  MOV   AX,7FFFH
        RET

L181E:  DW    0000H

;---------------------------------------------------------------------
PRNBUF_LEN = 0200H                ;-- buffer für ausgabe auf den druckerport

PRNBUF  DB    PRNBUF_LEN DUP (00H)            ;-- bufffer für druckerport
BUF_O   DW    0000H                           ;-- dort lesen aus buffer
BUF_I   DW    0000H                           ;-- dort schreiben in buffer
BUF_IN  DW    0000H                           ;-- count bytes in buffer

;-- zeichen in al in den buffer für die druckerausgabe
;-- wartet falls buffer voll ist
;-- verändert kein register
;---------------------------------------------------------------------
INBUF  PROC NEAR
        CMP   DS:[BUF_IN],PRNBUF_LEN
        JE    INBUF                           ;-- warte bis buffer nicht voll
        PUSH  BX
        MOV   DI,OFFSET OUTBUF                ;-- basis adresse des buffers
        MOV   BX,DS:[BUF_I]
        MOV   [BX+DI],AL                      ;-- speichern
        INC   DS:[BUF_I]                      ;-- auf nächstes byte
        INC   DS:[BUF_IN]                     ;-- ein char mehr im buffer
        AND   DS:[BUF_I],PRNBUF_LEN-1         ;-- zyklisches speichern
        POP   BX
        RET
INBUF  ENDP

;-- liest ein byte aus dem buffer in al
;-- al = 0FFH wenn buffer leer ist
;---------------------------------------------------------------------
OUTBUF  PROC NEAR
        CMP   WORD PTR DS:[BUF_IN],+00H
        JE    L1A69                           ;-- buffer ist leer
        MOV   SI,OFFSET PRNBUF                ;-- basis adresse des buffers
        MOV   BX,DS:[BUF_O]
        MOV   AL,[BX+SI]                      ;-- char aus buffer holen
        XOR   AH,AH
        INC   DS:[BUF_O]                      ;-- auf nächtes char für ausgabe
        DEC   DS:[BUF_IN]                     ;-- ein char weniger im buffer
        AND   DS:[BUF_O],PRNBUF_LEN-1         ;-- zyklisches speichern
        RET
L1A69:  MOV   AH,0FFH                         ;-- code für leere buffer
        RET
OUTBUF  ENDP

;---------------------------------------------------------------------
L1A6C:  DW    0000H
L1A6E:  DW    0000H
OUTSTA  DB    00H                             ;-- 01 wenn zeichen ausgeben wurde
PRNSTA  DB    00H                             ;-- status des druckers (siehe H-9
L1A72   DD    00000000H
L1A76   DB    01H

;-- aufruf über bios event trap : parallel port output char ready
;---------------------------------------------------------------------
PUT_PRNREADY PROC FAR
        MOV   AX,CS
        MOV   DS,AX                           ;-- ds := cs
        MOV   DX,PORT_STA
        IN    AL,DX                           ;-- drucker status holen
        TEST  AL,80H
        JE    L1A8A                           ;-- falls printer deselected
        MOV   DX,10ECH
        OUT   DX,AL
        CALL  WRITE_PRN                       ;-- ein zeichen ausgeben
L1A8A:  RETF
PUT_PRNREADY ENDP

;-- druckerstatus setzen
;-- aufruf alle 0.5sec über bios event trap
;---------------------------------------------------------------------
GET_PRNSTATUS PROC FAR
L1A8B:  MOV   AX,CS
        MOV   DS,AX                           ;-- ds := cs
        MOV   ES,AX                           ;-- es := cs
        CLD
        MOV   DX,PORT_STA
        IN    AL,DX                           ;-- drucker status holen
        AND   AL,68H
        CMP   AL,28H
        JE    L1ABB                           ;-- alles ok
        TEST  AL,08H
        JNE   L1AA5
        OR    BYTE PTR DS:[PRNSTA],08H        ;-- printer deselected
L1AA5:  TEST  AL,40H
        JE    L1AAE
        OR    BYTE PTR DS:[PRNSTA],02H        ;-- paper out
L1AAE:  TEST  AL,20H
        JNE   L1AB7
        OR    BYTE PTR DS:[PRNSTA],04H        ;-- fault (neg acknowlage)
L1AB7:  CALL  L1ADC
        RET
L1ABB:  MOV   BYTE PTR DS:[PRNSTA],00H        ;-- alles ok
        CALL  L1ADC
        RET
GET_PRNSTATUS ENDP

;---------------------------------------------------------------------
WRITE_PRN PROC NEAR                           ;-- zeichen aus buffer auf port
        CALL  OUTBUF                          ;-- hole zeichen aus buffer
        CMP   AH,0FFH
        JE    L1AD6                           ;-- falls buffer leer
        MOV   BYTE PTR DS:[OUTSTA],01H
        MOV   DX,PORT_DATA
        OUT   DX,AL                           ;-- ausgaben auf drucker
        RET
L1AD6:  MOV   BYTE PTR DS:[OUTSTA],00H
        RET
WRITE_PRN ENDP

;---------------------------------------------------------------------
L1ADC:  CMP   BYTE PTR DS:[L1A76],01H
        JE    L1AEF
        PUSH  ES
        LES   SI,DWORD PTR DS:[L1A72]
        MOV   AL,BYTE PTR DS:[PRNSTA]
        MOV   ES:[SI],AL
        POP   ES
L1AEF:  RET

;--------------------------------------------------------------------
;-- ende des residenten teils
;--------------------------------------------------------------------

;--------------------------------------------------------------------
INIT    PROC NEAR
        MOV   AX,CS
        MOV   DS,AX                           ;-- ds := cs
        MOV   ES,AX                           ;-- es := cs
        CLD
        MOV   SI,OFFSET MYNAME
        CALL  SCR_WRITE                       ;-- vorstellung
        MOV   DX,OFFSET FNAME                 ;-- auf 'PRNXLT.COM'
        MOV   AX,3D00H                        ;-- open a file for reading
        INT   DOS
        CALL  CHK_FILE                        ;-- testen auf fehler
        MOV   BX,AX                           ;-- bx := file handle
        MOV   DX,OFFSET FILEBUF               ;-- in buffer lesen
        MOV   CX,FILEBUF_LEN                  ;-- länge des buffers
        MOV   AH,3FH                          ;-- read a file
        INT   DOS
        CALL  CHK_FILE                        ;-- testen auf fehler
        MOV   AH,3EH                          ;-- close a file
        INT   DOS
        CALL  CHK_FILE                        ;-- testen auf fehler
        MOV   SI,OFFSET FILEBUF               ;-- pdt file.name
        MOV   DI,OFFSET NAMBUF
        MOV   CX,NUMBUF_LEN
        REPZ  MOVSB                           ;-- in den file-name buffer
        CMP   DS:[NUMBUF],00H
        JNE   L1B35                           ;-- name ist ungültig
        MOV   AL,02H                          ;-- also file not found error
        CALL  L1C0B
L1B35:  MOV   DX,OFFSET NAMBUF
        MOV   AX,3D00H                        ;-- open a file for reading
        INT   DOS
        CALL  CHK_FILE                        ;-- testen auf felher
        MOV   BX,AX                           ;-- bx := file handle
        MOV   DX,OFFSET PDT
        MOV   CX,0200H                        ;-- number of bytes to read
        MOV   AH,3FH                          ;-- read a file
        INT   DOS
        CALL  CHK_FILE                        ;-- testen auf fehler
        MOV   AH,3EH                          ;-- close a file
        INT   DOS
        CALL  CHK_FILE                        ;-- testen auf fehler
        MOV   DX,OFFSET NAMBUF                ;-- file-name ausgeben
        MOV   AH,09H                          ;-- print a string
        INT   DOS
L1B5D:  CMP   DS:76[FILEBUF],01H
        JNE   L1B9F                           ;-- keine ctt vorhanden
        MOV   SI,OFFSET FILEBUF
        ADD   SI,+40H                         ;-- ctt file-name
        MOV   DI,OFFSET NAMBUF                ;-- in den filename-buffer
        MOV   CX,NAMBUF_LEN
        REPZ  MOVSB                           ;-- kopieren
        MOV   DX,OFFSET NAMBUF
        MOV   AX,3D00H                        ;-- open a file for reading
        INT   DOS
L1B7A:  CALL  CHK_FILE                        ;-- testen auf fehler
        MOV   BX,AX
        MOV   DX,OFFET CTT                    ;-- tabelle einlesen
        MOV   CX,0200H                        ;-- number of bytes to read
        MOV   AH,3FH                          ;-- read a file
        INT   DOS
L1B89:  CALL  CHK_FILE                        ;-- testen auf fehler
        MOV   AH,3EH                          ;-- close a file
        INT   DOS
L1B90:  CALL  CHK_FILE                        ;-- testen auf fehler
        MOV   DX,OFFSET NAMBUF
        MOV   AH,09H                          ;-- filenamen ausgeben
        INT   DOS
L1B9A:  MOV   BYTE PTR DS:[0668H],01H
L1B9F:  MOV   AL,BYTE PTR DS:[0278H]
        MOV   BYTE PTR DS:[066AH],AL
        MOV   AL,BYTE PTR DS:[0279H]
        MOV   BYTE PTR DS:[TMODE],AL
        MOV   BX,01C2H
        MOV   AL,23H
        MOV   [BX],AL
        XOR   AL,AL
        INC   BX
        MOV   [BX],AL
        INC   BX
        MOV   [BX],AL
        XOR   BX,BX                           ;-- event index => 10ms timer
        MOV   CX,0032H                        ;-- nach 0,5 sec
        MOV   AX,CS
        MOV   DS,AX                           ;-- ds:dx adresse der procedure
        LEA   DX,DS:[GET_PRNSTATUS]
        MOV   AL,02H                          ;-- set event trap
        INT   BIOS
L1BCB:  MOV   BX,0005H                        ;-- event index => prallel port
        XOR   CX,CX                           ;--           output char ready
        MOV   AX,CS
        MOV   DS,AX                           ;-- ds:dx adresse der procedure
        LEA   DX,DS:[PUT_PRNREADY]
        MOV   AL,02H                          ;-- set event trap
        INT   BIOS
L1BDC:  MOV   DX,1024H
        MOV   AL,02H
        OUT   DX,AL
L1BE2:  LDS   BX,DS:[STOREDB]                 ;-- ds:bx auf datablock
        MOV   AX,OFFSET INIT
        MOV   [BX+0EH],AX                     ;-- break address offset
        MOV   AX,CS
        MOV   [BX+10H],AX                     ;-- break address segement
        RET
INIT    ENDP

;---------------------------------------------------------------------
SCR_WRITE PROC NEAR                           ;-- print asciz ab ds:si
        XOR   BH,BH                           ;-- default screen
        MOV   BL,0AH                          ;-- CR
        MOV   AL,06H                          ;-- send to screen
        INT   BIOS
L1BFA:  MOV   BL,[SI]                         ;-- get char for screen output
        AND   BL,BL
        JE    L1C07                           ;-- 00H terminiert den string
        MOV   AL,06H                          ;-- send to screen
        INC   SI                              ;-- point to next charcater
        INT   BIOS
        JMP   L1BFA                           ;-- schleife
L1C07:  RET
SCR_WRITE ENDP

;-- testet auf einen fehler nach einem dos aufruf
;-- bei dem es sich um einen dateizugriff handelte
;---------------------------------------------------------------------
CHK_FILE PROC NEAR
        JC    L1C0B
        RET                                   ;-- alles in ordnung, zurück
L1C0B:  MOV   BL,AL                           ;-- bl := errorcode
        MOV   DX,OFFSET ERR_T                 ;-- auf fehlertext
        MOV   AH,09H                          ;-- print a string
        INT   DOS
L1C14:  MOV   AL,BL                           ;-- al := errorcode
        CMP   AL,02H                          ;-- file not found error ?
        JNE   L1C23
        MOV   DX,OFFSET ERR1_T                ;-- "'file not found'"
        MOV   AH,09H                          ;-- print a string
        INT   DOS
L1C21:  JMP   SHORT L1C2A
L1C23:  MOV   DX,OFFSET ERR2_T                ;-- auf fehlertext
        MOV   AH,09H                          ;-- print a string
        INT   DOS
L1C2A:  POP   AX                              ;-- stack säubern (call aufruf)
        JMP   L1BE2
CHK_FILE ENDP

FILEBUF DB    FILEBUF_LEN DUP (00H)
FNAME   DB    'PRNXLT.COM',00H
ERR_T   DB    'DIVER INSTALLATION ABORTED',0DH,0AH,'$'
ERR2_T  DB    ' boot disk or root directory missing INDEX, FUNCTION '
        DB    'or TRANSLATE table',0DH,0AH,'$'
ERR3_T  DB    ' file access error',0DH,0AH,'$'
L1D35:  DW    0000H
NAMBUF  DB    NUMBUF_LEN DUP (00H)
        DB    0DH,0AH,'$'                     ;-- nambuf als string
L1D47:  DW    0000H

XSEG    ENDS
        END
