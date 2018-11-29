        PAGE 60,132
;---------------------------------------------------------------------
;       Assembler Listing von SER1DRVR.COM
;       (c) Kommentare Ulrich Berntien .05.1989
;                      letzte Änderung .05.1989
;---------------------------------------------------------------------
XSEG    SEGMENT
        ASSUME CS:XSEG, DS:XSEG

;---------------------------------------------------------------------
DOS     = 021H          ;Interrupt Calls zum Betriebssystem
BIOS    = 088H

CTRL_S  = 013H          ;codes im v.24 protokoll
CTRL_Q  = 011H

;---------------------- ports der V.24 -------------------------------
OUT_01  = 1088H         ;daten auf serielle schnittstelle ausgaben
OUT_02  = 108CH         ;einstellen der schnittstellen parameter
OUT_03  = 108EH         ;kommandos an schnittstelle
IN_01   = 1080H         ;daten von schnittstelle einlesen
IN_02   = 1082H         ;status der schnittstelle
IN_03   = 1086H

;---------------------- driver head ----------------------------------
        DD    -1                  ;pointer to next driver head
        DW    0C000H              ;attribute : ioctl , nonibm format
        DW    OFFSET ENQUEUE      ;pointer to device enqueue entry point
        DW    OFFSET SERVICE      ;pointer to device service entry point
        DB    'PRN1    '          ;character device name
        DB    00H                 ;(for block devices)
;---------------------------------------------------------------------
        DB   13 DUP (00H)
STOREDB DD   00000000h              ;speicher für pointer to data block
        DB   00H
        DB   00H

;------------------ enqueue procedure --------------------------------
ENQUEUE PROC FAR
        MOV   WORD PTR CS:[STOREDB],BX        ;pointer to datablock speichern
        MOV   WORD PTR CS:2[STOREDB],ES
        RET                                   ;return far
ENQUEUE ENDP

;---------------------------------------------------------------------
JUMPER  DW    OFFSET INIT         ;init
        DW    OFFSET MEDIA_CHECK  ;media check
        DW    OFFSET BUILT_BPB    ;(build bpb)
        DW    OFFSET CTL_INPUT    ;ioctl input
        DW    OFFSET INPUT        ;input/read
        DW    OFFSET NINPUT       ;non destructiv input, no wait
        DW    OFFSET IN_STATUS    ;input status
        DW    OFFSET INP_FLUSH    ;input flush
        DW    OFFSET OUTPUT       ;output/write
        DW    OFFSET OUTPUTV      ;output/write with verify
        DW    OFFSET OUT_STATUS   ;output status
        DW    OFFSET OUT_FLUSH    ;output fluch
        DW    OFFSET CTL_OUTPUT   ;ioctl output

;------------------ service procedure --------------------------------
SERVICE PROC FAR
        PUSH  AX                              ;backup register
        PUSH  BX
        PUSH  CX
        PUSH  DX
        PUSH  BP
        PUSH  SI
        PUSH  DI
        PUSH  DS
        PUSH  ES
        CLD
        LDS   BX,CS:[STOREDB]                 ;DS:BX auf den datenblock
        MOV   WORD PTR [BX+03H],0000H         ;status := 0
        MOV   DL,[BX+02H]                     ;command code
        XOR   DH,DH                           ;DX := DL
        SHL   DL,1                            ;zur word adressierung
        MOV   SI,DX
        CALL  CS:[SI+JUMPER]
        LDS   BX,CS:[STOREB]                  ;DS:BX auf den datenblock
        OR    WORD PTR [BX+03H],0100H         ;im status done := true
        POP   ES                              ;register restore
        POP   DS
        POP   DI
        POP   SI
        POP   BP
        POP   DX
        POP   CX
        POP   BX
        POP   AX
        RET                                   ;return far
SERVICE ENDP

;---------------------------------------------------------------------
MEDIA_CHECK PROC NEAR                         ;media check
        MOV   WORD PTR [BX+03H],8003H         ;status: error, unknown command
        RET
MEDIA_CHECK ENDP

;---------------------------------------------------------------------
BUILT_BPB PROC NEAR                           ;(build bpb)
        MOV   WORD PTR [BX+03H],8003H         ;status: error, unkonown command
        RET
BUILT_BPB ENDP

;---------------------------------------------------------------------
CTL_INPUT PROC NEAR                           ;ioctl input
        MOV   CX,[BX+12H]
        LDS   DI,DWORD PTR [BX+0EH]
        MOV   AL,BYTE PTR CS:[PRN_STATUS]
        MOV   [DI],AL
        CMP   CX,+02H
        JNE   L01A5
        INC   DI
        MOV   AL,BYTE PTR CS:[0669H]
        MOV   [DI],AL
L01A5:  RET
CTL_INPUT ENDP

;---------------------------------------------------------------------
INPUT   PROC NEAR                             ;input/read
        CALL  CTL_INPUT
        RET
INPUT   ENDP

;---------------------------------------------------------------------
NINPUT  PROC NEAR                             ;non destructiv input ,no wait
        MOV   AL,BYTE PTR CS:[PRN_STATUS]
        MOV   [BX+0DH],AL                     ;byte read from device
        RET
NINPUT  ENDP

;---------------------------------------------------------------------
IN_STATUS PROC NEAR                           ;input status
        RET
IN_STATUS endp

;---------------------------------------------------------------------
INP_FLUSH PROC NEAR                           ;input flush
        RET
INP_FLUSH ENDP

;---------------------------------------------------------------------
OUTPUT  PROC NEAR                             ;output/write
        MOV   CX,[BX+12H]
        LDS   SI,DWORD PTR [BX+0EH]
L01BA:  MOV   AL,[SI]
        PUSH  DS
        PUSH  SI
        PUSH  CX
        PUSH  CS
        POP   ES
        MOV   BYTE PTR CS:[0024H],01H
        PUSH  AX
L01C8:  CALL  OUT_STATUS
        CMP   BYTE PTR CS:[0025H],01H
        JE    L01C8
        POP   AX
        MOV   BYTE PTR CS:[0024H],00H
        CMP   BYTE PTR CS:[0669H],01H
        JNE   L01ED
        PUSH  AX
        MOV   AX,CS
        MOV   DS,AX
        POP   AX
        CALL  IN_BUFFER
        JMP   SHORT L01F0
L01ED:  CALL  L0B38
L01F0:  POP   CX
        POP   SI
        POP   DS
        INC   SI
        LOOP  L01BA
        CMP   BYTE PTR CS:[1976H],01H
        JNE   L0210
        TEST  BYTE PTR CS:[PRN_STATUS],02H
        JE    L0210
        LDS   BX,CS:[STOREDB]
        MOV   WORD PTR [BX+03H],8009H
L0210:  RET
OUTPUT ENDP

;---------------------------------------------------------------------
OUTPUTV PROC NEAR                             ;output/write with verify
        CALL  OUTPUT
        RET
OUTPUTV ENDP

;---------------------------------------------------------------------
OUT_STATUS PROC NEAR                          ;output status
        MOV   AX,CS
        MOV   DS,AX                           ;DS := CS
        MOV   ES,AX                           ;ES := CS
        CLD
        CMP   BYTE PTR CS:[1970H],01H
        JE    L0227
        CALL  L1A80
L0227:  CMP   BYTE PTR CS:[0669H],01H
        JE    L026C
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
        CMP   BYTE PTR CS:[0024H],01H
        JE    L028F
        LDS   BX,CS:[STOREDB]
        MOV   WORD PTR [BX+03H],0200H
L028F:  RET
L0290:  MOV   BYTE PTR CS:[0025H],00H
        RET
OUT_STATUS ENDP

;---------------------------------------------------------------------
OUT_FLUSH PROC NEAR                           ;output flush
        RET
OUT_FLUSH ENDP

MY_NAME DB    'PRN1 Generalized Printer Driver, CPU  v2.00   ',0DH,0AH,00H

;---------------------------------------------------------------------
CTL_OUTPUT PROC NEAR                          ;ioctl output
        MOV   CX,[BX+12H]
        LDS   SI,DWORD PTR [BX+0EH]
        MOV   AL,[SI]
        CMP   AL,0FFH
        JNE   L02F7
        CMP   CX,+07H
        JB    L033A
        INC   SI
        LES   DI,DWORD PTR [SI]
        MOV   CX,[SI+04H]
        CMP   CX,+2EH
        JBE   L02E8
        MOV   CX,002EH
L02E8:  MOV   [SI+04H],CX
        PUSH  DS
        PUSH  CS
        POP   DS
        MOV   SI,OFFSET MY_NAME
        REPZ  MOVSB
        POP   DS
        JMP   SHORT L033A
        NOP
L02F7:  CMP   AL,0FEH
        JNE   L0316
        CMP   CX,+05H
        JB    L033A
        INC   SI
        LES   DI,DWORD PTR [SI]
        MOV   CS:[1972H],DI
        MOV   CS:[1974H],ES
        MOV   BYTE PTR CS:[1976H],00H
        JMP   SHORT L033A
        NOP
L0316:  CMP   AL,0FDH
        JNE   L0323
        MOV   BYTE PTR CS:[1976H],01H
        JMP   SHORT L033A
        NOP
L0323:  CMP   AL,0FCH
        JNE   L0330
        MOV   BYTE PTR CS:[0669H],01H
        JMP   SHORT L033A
        NOP
L0330:  CMP   AL,0FBH
        JNE   L033A
        MOV   BYTE PTR CS:[0669H],00H
L033A:  RET
CTL_OUTPUT ENDP

L033B:  DW    2 DUP(0000H)
        DB    00H
L0342:  DB    'Copyright, Wang Laboratories, Inc., 1985'
L0368:  DW    989 DUP(0000H)
        DB    00H,07H
        DB    09H,0AH
        DB    0CH,0DH
        DB    1BH,00H
        DB    6CH
        DB    11H,73H,11H
        DB    0A4H
        DB    11H,0CEH
        DB    11H,0F3H
        DB    11H,45H,12H
        DB    0CDH,0AH

L0B38:  PUSH  CS
        POP   DS
        CMP   BYTE PTR [1250H],01H
        JNE   L0B50
        CALL  IN_BUFFER
        DEC   WORD PTR [1251H]
        JNE   L0B4F
        MOV   BYTE PTR [1250H],00H
L0B4F:  RET

L0B50:  MOV   BYTE PTR [0915H],AL
        CMP   BYTE PTR [0674H],01H
        JE    L0B98
        MOV   BYTE PTR [0674H],01H
        MOV   BYTE PTR [067AH],01H
        MOV   BX,0038H
        CALL  L1245
        XOR   AL,AL
        MOV   DI,0906H
        MOV   CX,000FH
        REPNZ STOSB
        MOV   BYTE PTR [0678H],01H
        MOV   BYTE PTR [0673H],01H
        CMP   BYTE PTR [066AH],01H
        JNE   L0B8D
        MOV   WORD PTR [0676H],0050H
        JMP   SHORT L0B93
L0B8D:  MOV   WORD PTR [0676H],0084H
L0B93:  MOV   BYTE PTR [0675H],06H
L0B98:  CMP   BYTE PTR [0913H],00H
        JE    L0BA9
        MOV   AL,0AH
        CALL  IN_BUFFER
        MOV   BYTE PTR [0913H],00H
L0BA9:  MOV   AL,BYTE PTR [0915H]
        CMP   BYTE PTR [091FH],01H
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

L0BCE:  CMP   BYTE PTR [0668H],01H
        JNE   L0BEF
        MOV   BX,0468H
        XLAT
        MOV   CL,AL
        MOV   AL,BYTE PTR [0915H]
        MOV   AH,01H
        ADD   BX,AX
        MOV   AL,[BX]
        CMP   AL,00H
        JE    L0BED
        MOV   BYTE PTR [066CH],01H
L0BED:  MOV   AL,CL
L0BEF:  CMP   BYTE PTR [090BH],01H
        JNE   L0BFA
        CALL  L1052
        RET

L0BFA:  CALL  L0BFE
        RET

L0BFE:  MOV   BYTE PTR [0910H],00H
        MOV   BX,[0906H]
        PUSH  AX
        PUSH  BX
        CMP   BX,+00H
        JNE   L0C29
        CMP   BYTE PTR [066AH],01H
        JNE   L0C29
        CMP   WORD PTR [0676H],0084H
        JNE   L0C29
        MOV   BX,0128H
        CALL  L1245
        MOV   BX,0110H
        CALL  L1245
L0C29:  POP   BX
        POP   AX
        CMP   BX,+00H
        JNE   L0C65
        CMP   BYTE PTR [0911H],00H
        JE    L0C65
        PUSH  AX
        PUSH  CX
        MOV   CL,[0672H]
L0C3D:  MOV   CH,[0671H]
L0C41:  MOV   AL,20H
        MOV   [BX+067BH],AL
        XOR   AL,AL
        MOV   [BX+0754H],AL
        MOV   AL,20H
        MOV   [BX+082DH],AL
        INC   WORD PTR [0906H]
        MOV   BX,[0906H]
        DEC   CH
        JNE   L0C41
        DEC   CL
        JNE   L0C3D
        POP   CX
        POP   AX
L0C65:  MOV   BYTE PTR [090FH],00H
        MOV   [BX+067BH],AL
        MOV   AL,BYTE PTR [0908H]
        MOV   [BX+0754H],AL
        MOV   AL,BYTE PTR [0915H]
        MOV   [BX+082DH],AL
        INC   WORD PTR [0906H]
        MOV   AX,WORD PTR [0676H]
        CMP   AX,[0906H]
        JE    L0C8A
        RET

L0C8A:  MOV   BYTE PTR [090FH],01H
        CALL  L0D1C
        RET

L0C93:  ADD   AL,[SI]
        PUSH  ES
        JO    L0CA4
        DEC   BYTE PTR [SI]
        DEC   AX
        OR    AX,3E80H
        DB    6EH
        PUSH  ES ;DB 06H
        ADD   [SI+16H],SI ;DB 01H,74H,16H
        MOV   AL,BYTE PTR [066FH] ;DB 0A0H,6FH,06H
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
        OR    [0405H],AX
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
        CMP   BYTE PTR [0670H],01H ;DB 80H,3EH,70H,06H,01H
        JNE   L0D07
        DB    0C3H    ;RET

L0D07:  CMP   BYTE PTR [0914H],02H
        JNE   L0D0F
        INC   DI
L0D0F:  MOV   AL,[BX+DI]
        CMP   AL,00H
        JE    L0D1B
        MOV   BYTE PTR [0917H],AL
        CALL  L0EC5
L0D1B:  RET

L0D1C:  MOV   BX,[0906H]
        MOV   BYTE PTR [BX+067BH],00H
        MOV   BYTE PTR [066EH],00H
        CMP   WORD PTR [0906H],+00H
        JE    L0D9E
        MOV   BYTE PTR [091BH],04H
        MOV   AL,BYTE PTR [0912H]
        AND   AL,04H
        JE    L0D9E
        CMP   BYTE PTR [0914H],00H
        JE    L0D4C
        MOV   BX,0BC3H
        CALL  L0CED
        JMP   SHORT L0D52
L0D4C:  MOV   BX,0BD1H
        CALL  L0CED
L0D52:  MOV   BYTE PTR [0914H],00H
        CMP   BYTE PTR [1253H],01H
        JNE   L0D63
        MOV   BYTE PTR [1254H],01H
L0D63:  MOV   BYTE PTR [066DH],01H
        MOV   BYTE PTR [066FH],02H
        JMP   L0F1B
        CMP   BYTE PTR [0914H],01H
        JNE   L0D8D
        CMP   BYTE PTR [091DH],01H
        JNE   L0D9C
        MOV   BYTE PTR [0917H],01H
        CALL  L0EC5
        MOV   BYTE PTR [091DH],00H
        JMP   SHORT L0DC7
L0D8D:  CMP   BYTE PTR [0675H],18H
        JE    L0D9C
        MOV   BYTE PTR [0917H],01H
        CALL  L0EC5
L0D9C:  JMP   SHORT L0DC7
L0D9E:  CMP   BYTE PTR [0914H],00H
        JE    L0DAD
        MOV   BX,0BDFH
        CALL  L0CED
        JMP   SHORT L0DC7
L0DAD:  CMP   BYTE PTR [0673H],01H
        JE    L0DC7
        CMP   BYTE PTR [090EH],01H
        JE    L0DC7
        CMP   BYTE PTR [090DH],01H
        JE    L0DC7
        MOV   AL,0AH
        CALL  IN_BUFFER
L0DC7:  MOV   BYTE PTR [0673H],00H
        MOV   BYTE PTR [0914H],00H
        MOV   AL,BYTE PTR [067BH]
        CMP   AL,00H
        JNE   L0DDB
        JMP   L0E6F
L0DDB:  MOV   BYTE PTR [0918H],01H
        MOV   BYTE PTR [091BH],06H
        CMP   BYTE PTR [1253H],01H
        JNE   L0DF1
        MOV   BYTE PTR [1254H],01H
L0DF1:  MOV   BYTE PTR [066DH],01H
        MOV   BYTE PTR [066FH],04H
        JMP   L0F1B
L0DFE:  MOV   BYTE PTR [0918H],00H
        CMP   BYTE PTR [0914H],01H
        JNE   L0E1E
        CMP   BYTE PTR [091DH],01H
        JNE   L0E1E
        MOV   BYTE PTR [0917H],01H
        CALL  L0EC5
        MOV   BYTE PTR [091DH],00H
L0E1E:  MOV   BYTE PTR [091BH],02H
        MOV   AL,BYTE PTR [0912H]
        AND   AL,02H
        JNE   L0E2C
        JMP   SHORT L0E6F
L0E2C:  CMP   BYTE PTR [0914H],01H
        JE    L0E3B
        MOV   BYTE PTR [0917H],01H
        CALL  L0EC5
L0E3B:  MOV   BYTE PTR [0914H],00H
        MOV   BYTE PTR [066FH],06H
        JMP   L0F1B
        CMP   BYTE PTR [0914H],01H
        JE    L0E56
        MOV   BYTE PTR [0914H],01H
        JMP   SHORT L0E6F
L0E56:  MOV   BYTE PTR [0914H],02H
        CMP   BYTE PTR [091DH],01H
        JNE   L0E6F
        MOV   BYTE PTR [0917H],01H
        CALL  L0EC5
        MOV   BYTE PTR [091DH],00H
L0E6F:  CMP   BYTE PTR [0916H],01H
        JNE   L0E9B
        MOV   AL,0CH
        CALL  IN_BUFFER
        MOV   BYTE PTR [0916H],00H
        CMP   BYTE PTR [066AH],01H
        JNE   L0E9B
        CMP   WORD PTR [0676H],0084H
        JNE   L0E9B
        MOV   BX,0128H
        CALL  L1245
        MOV   BX,0110H
        CALL  L1245
L0E9B:  MOV   BYTE PTR [066CH],00H
        MOV   AL,BYTE PTR [0908H]
        MOV   BYTE PTR [0912H],AL
        MOV   WORD PTR [0906H],0000H
        MOV   BYTE PTR [067BH],00H
        MOV   BYTE PTR [066FH],00H
        RET

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
        CMP   BYTE PTR [091DH],01H ;DB 80H,3EH,1DH,09H,01H
        JNE   L0EE6 ;DB 75H,10H
        MOV   BX,00C0H ;DB 0BBH,0C0H,00H
        CALL  L1245 ;DB 0E8H,69H,03H
        CMP   DL,00H
        JNE   L0EEC
        MOV   BYTE PTR [091DH],00H
L0EE6:  MOV   BX,00C8H
        CALL  L1245
L0EEC:  MOV   BH,[0917H]
        MOV   AL,0AH
L0EF2:  CALL  IN_BUFFER
        DEC   BH
        JNE   L0EF2
        MOV   BX,00E0H
        CALL  L1245
        MOV   BYTE PTR [0670H],01H
        CALL  L0CED
        MOV   BYTE PTR [0670H],00H
        MOV   BX,0DB7H
        MOV   DX,[BX+DI]
        MOV   BX,DX
        CALL  L1245
        POP   DI
        POP   SI
        POP   CX
        POP   BX
        RET

L0F1B:  MOV   BYTE PTR [0919H],00H
        MOV   BYTE PTR [091AH],0FFH
        MOV   BYTE PTR [091EH],00H
        MOV   CX,[0906H]
        XOR   BX,BX
        MOV   BYTE PTR [091CH],00H
L0F35:  MOV   AL,[BX+0754H]
        CMP   BYTE PTR [0918H],01H
        JNE   L0F48
        TEST  AL,[091BH]
        JNE   L0F6D
        JMP   SHORT L0F4E
L0F48:  TEST  AL,[091BH]
        JE    L0F6D
L0F4E:  CMP   BYTE PTR [0919H],01H
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
L0F6D:  INC   BYTE PTR [091CH]
L0F71:  INC   BX
        LOOP  L0F35
        CMP   BYTE PTR [0919H],00H
        JE    L0F82
        CMP   BYTE PTR [091EH],00H
        JE    L0F8C
L0F82:  MOV   AL,0DH
        CALL  IN_BUFFER
        MOV   BYTE PTR [091EH],00H
L0F8C:  MOV   AL,BYTE PTR [0912H]
        AND   AL,49H
        JNE   L0FAB
        CMP   BYTE PTR [066CH],00H
        JNE   L0FAB
        CMP   BYTE PTR [0918H],01H
        JNE   L0FB0
        MOV   AL,BYTE PTR [0912H]
        AND   AL,02H
        JNE   L0FB0
        JMP   L0DFE
L0FAB:  MOV   BYTE PTR [066EH],01H
L0FB0:  RET

L0FB1:  MOV   CX,[0906H]
        XOR   BX,BX
        INC   BYTE PTR [091AH]
        MOV   BYTE PTR [091CH],00H
        MOV   BYTE PTR [0919H],01H
        CMP   BYTE PTR [091AH],00H
        JNE   L0FD8
        TEST  BYTE PTR [0912H],01H
        JNE   L1042
        MOV   BYTE PTR [091AH],02H
L0FD8:  CMP   BYTE PTR [091AH],02H
        JNE   L0FEB
        TEST  BYTE PTR [0912H],08H
        JNE   L1042
        MOV   BYTE PTR [091AH],05H
L0FEB:  CMP   BYTE PTR [091AH],05H
        JNE   L1009
        CMP   BYTE PTR [0668H],01H
        JE    L0FFB
        JMP   SHORT L1004
L0FFB:  CMP   BYTE PTR [066CH],00H
        JE    L1004
        JMP   SHORT L1042
L1004:  MOV   BYTE PTR [091AH],0BH
L1009:  CMP   BYTE PTR [091AH],06H
        JNE   L101C
        TEST  BYTE PTR [0912H],01H
        JNE   L1042
        MOV   BYTE PTR [091AH],08H
L101C:  CMP   BYTE PTR [091AH],09H
        JNE   L102F
        TEST  BYTE PTR [0912H],01H
        JNE   L1042
        MOV   BYTE PTR [091AH],0BH
L102F:  CMP   BYTE PTR [091AH],0BH
        JNE   L1042
        TEST  BYTE PTR [0912H],40H
        JNE   L1042
        MOV   BYTE PTR [091AH],0EH
L1042:  CMP   BYTE PTR [091AH],0EH
        JE    L104C
        JMP   L0F35
L104C:  MOV   BYTE PTR [066EH],00H
        RET

L1052:  CMP   BYTE PTR [0668H],01H
        JNE   L108D
        CMP   AL,10H
        JNB   L1070
        PUSH  BX
        MOV   BL,AL
        XOR   BH,BH
        MOV   AL,1BH
        CALL  IN_BUFFER
        MOV   AL,[BX+0468H]
        CALL  IN_BUFFER
        POP   BX
        RET

L1070:  CMP   AL,80H
        JB    L108D
        CMP   BYTE PTR [0468H],01H
        JNE   L108D
        PUSH  AX
        MOV   AL,0EH
        CALL  IN_BUFFER
        POP   AX
        AND   AL,7FH
        CALL  IN_BUFFER
        MOV   AL,0FH
        CALL  IN_BUFFER
        RET

L108D:  CALL  IN_BUFFER
        RET

L1091:  ADD   [BX+DI],AL
        ADD   AL,[BP+DI]
        ADD   AL,05H
        PUSH  ES
        POP   ES
        OR    [BX+DI],CL
        OR    CL,[BP+DI]
        OR    AL,0DH
        AAD    ;0FH
        AAD    ;0FH
        IN    AL,DX
        DB    0FH
        OR    AX,0D10H ;DB 0DH,10H,0DH
        ADC   [BX+SI],DH ;DB 10H,30H
        ADC   [BP+DI+10H],AL ;DB 10H,43H,10H
        INC   BX ;DB 43H
        ADC   [BP+10H],BL ;DB 10H,5EH,10H
        JNBE  L10C3 ;DB 77H,10H
        JNBE  L10C5 ;DB 77H,10H
        CBW ;DB 98H
        ADC   AL,AH ;DB 10H,0E0H
        ADC   AL,AH
        ADC   [BX+SI+51H],DL
        MOV   AL,BYTE PTR [091AH]
        MOV   DI,0F91H
L10C3:  MOV   CX,000EH
        REPNZ SCASB
        POP   CX
        POP   AX
        MOV   SI,0F92H
        SUB   DI,SI
        SHL   DI,1
        JMP   WORD PTR [DI+0F9FH]
        AND   AL,01H
        JE    L10E5
        CALL  L1232
        INC   BYTE PTR [091EH]
        MOV   AL,[BX+067BH]
        RET

L10E5:  INC   BYTE PTR [091CH]
        XOR   AL,AL
        RET

L10EC:  AND   AL,08H
        JE    L1106
        CALL  L1232
        INC   BYTE PTR [091EH]
        CMP   BYTE PTR [0668H],01H
        JNE   L1103
        MOV   AL,BYTE PTR [04C7H]
        JMP   SHORT L1105
L1103:  MOV   AL,5FH
L1105:  RET

L1106:  INC   BYTE PTR [091CH]
        XOR   AL,AL
        RET

L110D:  AND   AL,09H
        CMP   AL,09H
        JNE   L1129
        CALL  L1232
        INC   BYTE PTR [091EH]
        CMP   BYTE PTR [0668H],01H
        JNE   L1126
        MOV   AL,BYTE PTR [04C7H]
        JMP   SHORT L1128
L1126:  MOV   AL,5FH
L1128:  RET

L1129:  INC   BYTE PTR [091CH]
        XOR   AL,AL
        RET

L1130:  CALL  L1211
        AND   AL,0FH
        JE    L113C
        MOV   SI,AX
        JMP   L121E
L113C:  INC   BYTE PTR [091CH]
        XOR   AL,AL
        RET

L1143:  CALL  L1211
        AND   AL,0FH
        JE    L1157
        MOV   SI,AX
        MOV   AL,[BX+0754H]
        AND   AL,01H
        JE    L1157
        JMP   L121E
L1157:  INC   BYTE PTR [091CH]
        XOR   AL,AL
        RET

L115E:  CALL  L1211
        AND   AL,0F0H
        JE    L1170
        MOV   CL,04H
        ROR   AL,CL
        ADD   AL,10H
        MOV   SI,AX
        JMP   L121E
L1170:  INC   BYTE PTR [091CH]
        XOR   AL,AL
        RET

L1177:  CALL  L1211
        AND   AL,0F0H
        JE    L1191
        MOV   CL,04H
        ROR   AL,CL
        ADD   AL,10H
        MOV   SI,AX
        MOV   AL,[BX+0754H]
        AND   AL,01H
        JE    L1191
        JMP   L121E
L1191:  INC   BYTE PTR [091CH]
        XOR   AL,AL
        RET

L1198:  AND   AL,40H
        JE    L11D9
        CMP   BYTE PTR [0675H],18H
        JE    L11D9
        CMP   BYTE PTR [0675H],0CH
        JE    L11D9
        CMP   BYTE PTR [0914H],01H
        JE    L11C3
        MOV   BYTE PTR [0914H],01H
        MOV   BYTE PTR [091DH],01H
        MOV   BYTE PTR [0917H],01H
        CALL  L0EC5
L11C3:  CALL  L1232
        INC   BYTE PTR [091EH]
        CMP   BYTE PTR [0668H],01H
        JNE   L11D6
        MOV   AL,BYTE PTR [04C7H]
        JMP   SHORT L11D8
L11D6:  MOV   AL,5FH
L11D8:  RET

L11D9:  INC   BYTE PTR [091CH]
        XOR   AL,AL
        RET

L11E0:  AND   AL,41H
        CMP   AL,41H
        JNE   L120A
        CMP   BYTE PTR [0675H],18H
        JE    L120A
        CMP   BYTE PTR [0675H],0CH
        JE    L120A
        CALL  L1232
        INC   BYTE PTR [091EH]
        CMP   BYTE PTR [0668H],01H
        JNE   L1207
        MOV   AL,BYTE PTR [04C7H]
        JMP   SHORT L1209
L1207:  MOV   AL,5FH
L1209:  RET

L120A:  INC   BYTE PTR [091CH]
        XOR   AL,AL
        RET

L1211:  MOV   AL,[BX+082DH]
        MOV   AH,01H
        MOV   SI,AX
        MOV   AL,[SI+0468H]
        RET

L121E:  MOV   AL,[SI+0468H]
        XOR   AH,AH
        MOV   SI,AX
        CALL  L1232
        INC   BYTE PTR [091EH]
        MOV   AL,[SI+0468H]
        RET

L1232:  CMP   BYTE PTR [091CH],00H
        JE    L1244
L1239:  MOV   AL,20H
        CALL  IN_BUFFER
        DEC   BYTE PTR [091CH]
        JNE   L1239
L1244:  RET

L1245:  XOR   DL,DL
L1247:  MOV   AL,[BX+0268H]
        CMP   AL,0FEH
        JE    L1266
        CMP   BYTE PTR [067AH],00H
        JE    L125E
        CMP   AL,CTRL_Q
        JNE   L125E
        INC   BYTE PTR [0679H]
L125E:  CALL  IN_BUFFER
        MOV   DL,01H
        INC   BX
        JMP   SHORT L1247
L1266:  MOV   BYTE PTR [067AH],00H
        RET

L126C:  MOV   BX,0020H  ;OFFSET STOREDB ??;
        CALL  L1245
        RET

L1273:  CMP   BYTE PTR [090BH],01H
        JE    L12A3
        CMP   BYTE PTR [0911H],00H
        JNE   L12A3
        MOV   AX,WORD PTR [0906H]
        MOV   CL,08H
        DIV   CL
        MOV   AL,AH
        MOV   AH,08H
        SUB   AH,AL
        XOR   CX,CX
        MOV   CL,AH
L1292:  MOV   AX,WORD PTR [0906H]
        INC   AX
        CMP   AX,[0676H]
        JE    L12A3
        MOV   AL,20H
        CALL  L0BFE
        LOOP  L1292
L12A3:  RET

L12A4:  CMP   BYTE PTR [090BH],01H
        JNE   L12B8
        CMP   BYTE PTR [090DH],01H
        JE    L12B7
        MOV   AL,0AH
        CALL  IN_BUFFER
L12B7:  RET

L12B8:  MOV   BYTE PTR [0910H],00H
        CMP   BYTE PTR [090EH],01H
        JE    L12C8
        CALL  L0D1C
        RET

L12C8:  MOV   BYTE PTR [090EH],00H
        RET

L12CE:  CMP   BYTE PTR [090BH],01H
        JNE   L12DB
        MOV   AL,0CH
        CALL  IN_BUFFER
        RET

L12DB:  MOV   BYTE PTR [0910H],00H
        MOV   BYTE PTR [090EH],00H
        MOV   BYTE PTR [0916H],01H
        CALL  L0D1C
        MOV   BYTE PTR [0673H],01H
        RET

L12F3:  CMP   BYTE PTR [090BH],01H
        JNE   L130C
        MOV   AL,0DH
        CALL  IN_BUFFER
        CMP   BYTE PTR [0678H],01H
        JE    L1344
        MOV   AL,0AH
        CALL  IN_BUFFER
        RET

L130C:  CMP   BYTE PTR [0910H],01H
        JE    L133A
        CMP   BYTE PTR [090FH],01H
        JE    L132F
        CALL  L0D1C
        MOV   BYTE PTR [090EH],01H
        CMP   BYTE PTR [0678H],01H
        JE    L1344
        MOV   BYTE PTR [0913H],01H
        RET

L132F:  MOV   BYTE PTR [090FH],00H
        MOV   BYTE PTR [090EH],01H
        RET

L133A:  MOV   BYTE PTR [0910H],00H
        MOV   BYTE PTR [090EH],01H
L1344:  RET

L1345:  MOV   BYTE PTR [091FH],01H
        MOV   BYTE PTR [0A20H],00H
        RET

L1350:  DW    3 DUP(0000H)
L1356:  DB    '0123456789+-;[]'
L1365:  MOV   DI,1256H ;DB 0BFH,56H,12H
        MOV   CX,000FH ;DB 0B9H,0FH,00H
        REPNZ SCASB ;DB 0AEH
        JE    L1387 ;DB 74H,18H
L136F:  DB    '< v%<Ar!<Zv'
        OR    [SI],BH ;DB 08H,3CH
        DB    61H
        JB    L1398 ;DB 72H,19H
        CMP   AL,7AH ;DB 3CH,7AH
        JNBE  L1398 ;DB 77H,15H
        CALL  L13D5 ;DB 0E8H,4FH,00H
        DB    0C3H    ;RET

L1387:  MOV   BL,[0A20H]
        XOR   BH,BH
        MOV   DI,BX
        MOV   BX,0920H
        MOV   [BX+DI],AL
        INC   BYTE PTR [0A20H]
L1398:  RET

L1399:  DB    'c[d[e[o[h[l[m[n[a[z[b[v[w[k[  '
        POPF
        ADC   SI,BP ;DB 13H,0F5H
        ADC   BX,[DI+0914H] ;DB 13H,9DH,14H,09H
        ADC   AX,15A0H ;DB 15H,0A0H,15H
        RETF

L13C4:  ADC   AL,[BP+SI+13H]
        SBB   DL,[1622H]
        AND   AL,16H
        XOR   AL,16H
        DEC   DI
        PUSH  SS
        JNB   L13E9
        TEST  DL,[20BBH]
        OR    [BP+SI+0BF27H],CX
        CWD
        ADC   BH,[BX+DI+000FH]
        REPNZ SCASW
        MOV   BX,129BH
        SUB   DI,BX
        JMP   WORD PTR [DI+12B7H]
L13EB:  JMP   SHORT L143C
        NOP
        CALL  L178A
        MOV   CL,[0A21H]
        AND   CL,CL
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
L1410:  OR    [0908H],DL
        OR    [0912H],DL
        TEST  DL,08H
        JE    L1422
        MOV   BYTE PTR [0909H],0FFH
L1422:  TEST  DL,40H
        JE    L1436
        MOV   BYTE PTR [090AH],0FFH
        OR    BYTE PTR [0908H],08H
        OR    BYTE PTR [0912H],08H
L1436:  POP   CX
        ADD   BX,+02H
        LOOP  L13FF
L143C:  JMP   L1784
L143F:  JMP   SHORT L149A
        NOP
        CALL  L178A
        MOV   CL,[0A21H]
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
L1464:  AND   [0908H],DL
        TEST  DL,08H
        JNE   L147E
        MOV   BYTE PTR [0909H],00H
        CMP   BYTE PTR [090AH],0FFH
        JNE   L147E
        OR    BYTE PTR [0908H],08H
L147E:  TEST  DL,40H
        JNE   L1494
        MOV   BYTE PTR [090AH],00H
        CMP   BYTE PTR [0909H],0FFH
        JE    L1494
        AND   BYTE PTR [0908H],0F7H
L1494:  POP   CX
        ADD   BX,+02H
        LOOP  L1453
L149A:  JMP   L1784
        CALL  L178A
        MOV   AX,WORD PTR [0920H]
        CMP   BYTE PTR [0A21H],00H
        JNE   L14AD
        MOV   AX,0000H
L14AD:  MOV   DX,0000H
        MOV   CX,01F4H
        DIV   CX
        MOV   DL,AL
        MOV   AX,WORD PTR [0676H]
        MOV   DI,13E1H
        MOV   CX,0014H
        REPNZ SCASB
        MOV   DH,[DI]
        CMP   DL,00H
        JE    L14D9
        MOV   BYTE PTR [0911H],01H
        MOV   [0671H],DH
        MOV   [0672H],DL
        JMP   L1784
L14D9:  MOV   BYTE PTR [0911H],00H
        JMP   L1784
        SUB   [BP+DI],AL
        INC   DX
        ADD   DX,[BX+SI+05H]
        TEST  AL,[DI]
        DB    60H
        PUSH  ES ;DB 06H
        SAHF
        PUSH  ES ;DB 06H
        JS    L14F7 ;DB 78H,08H
        MOV   BYTE PTR [BX+SI],84H ;DB 0C6H,08H,84H
        OR    CL,BL ;DB 08H,0D9H
        OR    [BX+SI+0B3EH],AL ;DB 08H,80H,3EH,0BH
        OR    [BX+DI],AX ;DB 09H,01H
        JE    L1522 ;DB 74H,26H
        CMP   BYTE PTR [090FH],01H
        JE    L1522
        MOV   BYTE PTR [1253H],01H
        CALL  L12A4
        CMP   BYTE PTR [1254H],00H
        JE    L1518
        RET

L1513:  MOV   BYTE PTR [1254H],00H
L1518:  MOV   BYTE PTR [1253H],00H
        MOV   BYTE PTR [0910H],01H
L1522:  MOV   BYTE PTR [090DH],00H
        MOV   BX,00E0H
        CALL  L1245
        CALL  L178A
        MOV   AX,WORD PTR [0920H]
        CMP   BYTE PTR [0A21H],00H
        JNE   L153D
        MOV   AX,00A6H
L153D:  XOR   BX,BX
L153F:  CMP   AX,[BX+146DH]
        JB    L1568
        ADD   BX,+02H
        MOV   AL,[BX+146DH]
        MOV   BYTE PTR [0675H],AL
        ADD   BX,+02H
        MOV   BX,[BX+146DH]
        CALL  L1245
        CMP   BYTE PTR [0675H],00H
        JNE   L1565
        MOV   BYTE PTR [090DH],01H
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
        ADD   [0D800H],AL
        ADD   [DI+00H],BH
        OR    [BX+SI],AL
        ROL   B,[BX+SI],1
        ADD   [SI],CL
        ADD   [BX+SI+00H],AH
        POP   DS
        ADD   [BX+SI],BL
        ADD   AL,CL
L1596:  DW    2 DUP(0000H)
        ADD   AL,CL ;DB 00H,0C8H
        ADD   [BP+DI+01B0H],BH ;DB 00H,0BBH,0B0H,01H
        CALL  L1245 ;DB 0E8H,0A2H,0FCH
        CALL  L178A ;DB 0E8H,0E4H,01H
        MOV   AX,WORD PTR [0920H] ;DB 0A1H,20H,09H
        CMP   BYTE PTR [0A21H],00H ;DB 80H,3EH,21H,0AH,00H
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
        JMP   SHORT L15B5
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
        MOV   BYTE PTR [090BH],00H
        CALL  L178A
        MOV   AX,WORD PTR [0920H]
        CMP   BYTE PTR [0A21H],00H
        JNE   L1624
        MOV   AX,0064H
L1624:  XOR   BX,BX
L1626:  CMP   AX,[BX+1570H]
        JB    L166B
        CMP   AX,003CH
        JNB   L1638
        MOV   BYTE PTR [090BH],01H
        JMP   SHORT L1640
L1638:  PUSH  BX
        MOV   BX,0128H
        CALL  L1245
        POP   BX
L1640:  CMP   BYTE PTR [066AH],01H
        JE    L164A
        ADD   BX,+02H
L164A:  ADD   BX,+02H
        MOV   AX,[BX+1570H]
        MOV   WORD PTR [0676H],AX
        CMP   BYTE PTR [066AH],01H
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
        DB    0F0H    ;LOCK
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
        CMP   BYTE PTR [0A21H],00H
        JE    L16C7
        XOR   CH,CH
        MOV   CL,[0A21H]
        SHR   CX,1
        XOR   BX,BX
L16B4:  MOV   AX,[BX+0920H]
        ADD   BX,+02H
        CMP   AX,0001H
        JNE   L16C5
        MOV   BYTE PTR [0678H],00H
L16C5:  LOOP  L16B4
L16C7:  JMP   L1784
        CALL  L178A
        CMP   BYTE PTR [0A21H],00H
        JE    L1717
        XOR   CH,CH
        MOV   CL,[0A21H]
        SHR   CX,1
        XOR   BX,BX
L16DE:  MOV   AX,[BX+0920H]
        ADD   BX,+02H
        CMP   AX,0001H
        JNE   L16F2
        MOV   BYTE PTR [0678H],01H
        JMP   SHORT L1715
        NOP
L16F2:  CMP   AX,0000H
        JNE   L1715
        CMP   BYTE PTR [1255H],01H
        JE    L1715
        MOV   BYTE PTR [0A22H],01H
        OR    BYTE PTR [PRN_STATUS],08H
        CALL  L1C30
        INC   BYTE PTR [090CH]
        MOV   BX,0030H
        CALL  L1245
L1715:  LOOP  L16DE
L1717:  JMP   SHORT L1784
        NOP
L171A:  MOV   BYTE PTR [0674H],00H
        JMP   SHORT L1784
        NOP
        JMP   SHORT L171A
        CMP   BYTE PTR [027AH],00H
        JE    L1731
        MOV   BX,01D0H
        CALL  L1245
L1731:  JMP   SHORT L1784
        NOP
        CMP   BYTE PTR [027AH],00H
        JE    L174C
        MOV   BX,01C8H
        CALL  L1245
        CALL  L178A
        MOV   AX,WORD PTR [0920H]
        ADD   AL,30H
        CALL  IN_BUFFER
L174C:  JMP   SHORT L1784
        NOP
        CMP   BYTE PTR [027AH],00H
        JE    L1770
        MOV   BX,01C0H
        CALL  L1245
        CALL  L178A
        MOV   CL,04H
        MOV   AX,WORD PTR [0920H]
        ROL   AL,CL
        MOV   CL,AL
        MOV   AX,WORD PTR [0922H]
        OR    AL,CL
        CALL  IN_BUFFER
L1770:  JMP   SHORT L1784
        NOP
        CALL  L178A
        MOV   AX,WORD PTR [0920H]
        MOV   WORD PTR [1251H],AX
        MOV   BYTE PTR [1250H],01H
        JMP   SHORT L1784
        NOP
L1784:  MOV   BYTE PTR [091FH],00H
        RET

L178A:  MOV   BYTE PTR [0A21H],00H
        MOV   BX,0920H
        INC   BX
        MOV   CL,[0A20H]
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
        JMP   SHORT L17B3
        NOP
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
        JMP   SHORT L179C
L17CD:  INC   SI
        JMP   SHORT L17B4
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
        MOV   BL,[0A21H]
        MOV   [BX+0920H],AL
        INC   BX
        MOV   [BX+0920H],AH
        POP   BX
        ADD   BYTE PTR [0A21H],02H
        ADD   SI,+02H
        JMP   SHORT L179C
L17FE:  RET

L17FF:  OR    AL,[BX+SI]
L1801:  XOR   AX,AX
        DEC   SI
L1804:  INC   SI
        MUL   WORD PTR [16FFH]
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

L181E:     DW   0000h
;---------------------------------------------------------------------
BUFFER_LEN = 0200H                            ;länge des ausgabebuffers
BUFFER     DB BUFFER_LEN DUP(00H)             ;ausgabebuffer
FREE_PTR   DW 0000H                           ;rel. zeiger auf freies zeichen
OUT_PTR    DW 0000H                           ;rel. zeiger auf zeichen für out
NUM_IN_BUF DW 0000H                           ;anzahl der zeichen im buffer

;zeichen aus AL in buffer einspeichern
;---------------------------------------------------------------------
IN_BUFFER PROC NEAR
        CMP   [NUM_IN_BUF],BUFFER_LEN
        JE    IN_BUFFER                       ;warte bis platz im buffer ist
        PUSH  BX
        MOV   DI,OFFSET BUFFER                ;basis adresse des buffers
        MOV   BX,[FREE_PTR]                   ;offset auf nächte freie position
        MOV   [BX+DI],AL                      ;zeichen speichern
        INC   [FREE_PTR]                      ;zeiger weiter
        INC   [NUM_IN_BUF]                    ;ein zeichen mehr in buffer
        AND   [FREE_PTR],BUFFER_LEN-1         ;zyklische speicherung
        POP   BX
        RET
IN_BUFFER ENDP

;zeichen aus buffer in AL geben, 0FFH falls buffer leer
;---------------------------------------------------------------------
OUT_BUFFER PROC NEAR
        CMP   [NUM_IN_BUF],+00H               ;buffer leer ?
        JE    B_LEER                          ;  ja
        MOV   SI,OFFSET BUFFER                ;basis adresse des buffers
        MOV   BX,[OUT_PTR]                    ;offset zum nächsten ausgabe char
        MOV   AL,[BX+SI]                      ;zeichen
        XOR   AH,AH                           ;  in AX
        INC   [OUT_PTR]                       ;zieger auf nächstes zeichen
        DEC   [NUM_IN_BUF]                    ;ein zeichen weniger im buffer
        AND   [OUT_PTR],BUFFER_LEN-1          ;zyklische speicherung
        RET
B_LEER: MOV   AH,0FFH                         ;buffer ist leer
        RET
OUT_BUFFER ENDP

L1A6C:  DW    5 DUP(0000H)

PRN_STATUS DB 01H  ;L1971
STOP_FLAG  DB 00H  ;L1977                     ;gestzt falls CTRL_S empfangen

L1A78:  DW    4 DUP(0000H)
;---------------------------------------------------------------------

L1A80:  CMP   [STOP_FLAG],01H                 ;ausgabe unterbrochen ?
        JE    L1A99                           ; ja
        CMP   BYTE PTR [1978H],01H
        JE    L1A99
        CMP   WORD PTR [1924H],+00H
        JE    L1A99
        CALL  L1BC1
        RET
L1A99:  RET

;trap handler für aufruf alle 0.5 sec
;---------------------------------------------------------------------
TIMED:  MOV   AX,CS
        MOV   DS,AX                           ;DS := CS
        MOV   ES,AX                           ;ES := CS
        CLD
        CMP   BYTE PTR [1970H],01H
        JE    L1AB2
        CMP   WORD PTR [1924H],+00H
        JE    L1AB2
        CALL  L1A80
L1AB2:  CALL  L1C30
        RETF

;trap handler für Ýserial port input character ready¦
;             und Ýserial port output character ready¦
;---------------------------------------------------------------------
SER_TRAP PROC FAR
        MOV   AX,CS
        MOV   DS,AX                           ;DS := CS
        MOV   ES,AX                           ;ES := CS
        CLD
        MOV   DX,IN_02
        IN    AL,DX                           ;status von aux abfragen
        TEST  AL,00000010B                    ;zeichen empfangen ?
        JE    OUT_READY                       ;nein
        MOV   DX,IN_01                        ;byte von aux lesen
        IN    AL,DX
        CMP   BYTE PTR [197DH],01H
        JE    L1AE8
        AND   AL,01111111B                    ;maske für 7 bit übertragung
        CMP   AL,CTRL_S
        JNE   L1AEC
        MOV   [STOP_FLAG],01H                 ;ausgabe stopppen
        CMP   BYTE PTR [197EH],01H
        JNE   L1AE7
        MOV   BYTE PTR [197FH],01H
L1AE7:  RET
L1AE8:  CALL  L1BFB
        RET
L1AEC:  CMP   AL,CTRL_Q
        JNE   L1B0B
        CMP   [STOP_FLAG],00H                 ;ist ausgabe freigegeben ?
        JNE   L1AFD                           ; ja
        MOV   BYTE PTR [1978H],00H
        RET
L1AFD:  MOV   [STOP_FLAG],00H                 ;ausgabe freigeben
        AND   [PRN_STATUS],0FBH               ;lösche "paper out, fault"
        CALL  L1BC1
        RET
L1B0B:  CMP   AL,02H                          ;???
        JNE   L1B15
        MOV   BYTE PTR [197DH],01H
        RET
L1B15:  CMP   AL,15H                          ;15H = negative acknowlage
        JNE   L1B1E
        OR    [PRN_STATUS],04H                ;setze "fault"
L1B1E:  RET

OUT_READY:
        CMP   BYTE PTR [1979H],01H
        JNE   L1B2A
        CALL  L1B7A
        RET
L1B2A:  CMP   [STOP_FLAG],01H
        JNE   L1B35
        CALL  L1BEF
        RET
L1B35:  CALL  OUT_BUFFER
        CMP   AH,0FFH
        JE    L1B41
        CALL  L1B45
        RET
L1B41:  CALL  L1BEF
        RET
SER_TRAP ENDP

;---------------------------------------------------------------------
L1B45:  CMP   AL,CTRL_Q
        JNE   L1B5D
        CMP   BYTE PTR [0679H],00H
        JE    L1B8D
        DEC   BYTE PTR [0679H]
        MOV   BYTE PTR [1978H],01H
        CALL  L1BEF
        RET

L1B5D:  CMP   AL,CTRL_S
        JNE   L1B8D
        CMP   BYTE PTR [090CH],00H
        JE    L1B8D
        MOV   BYTE PTR [1255H],01H
        DEC   BYTE PTR [090CH]
        MOV   BYTE PTR [1979H],01H
        CALL  L1BEF
        RET

L1B7A:  CMP   BYTE PTR [197AH],01H
        JE    L1B92
        MOV   BYTE PTR [197AH],01H
        MOV   AL,BYTE PTR [0290H]
        CALL  L1B8D
        RET

L1B8D:  MOV   DX,OUT_01
        OUT   DX,AL
        RET

L1B92:  CMP   BYTE PTR [197BH],01H
        JE    L1BA5
        MOV   BYTE PTR [197BH],01H
        MOV   AL,BYTE PTR [0291H]
        CALL  L1B8D
        RET

L1BA5:  CMP   BYTE PTR [197CH],01H
        JE    L1BB8
        MOV   BYTE PTR [197CH],01H
        MOV   AL,BYTE PTR [0292H]
        CALL  L1B8D
        RET

L1BB8:  MOV   BYTE PTR [1978H],01H
        CALL  L1BEF
        RET

L1BC1:  MOV   BYTE PTR [1970H],01H
        MOV   DX,OUT_03
        MOV   AL,27H
        OUT   DX,AL
        CMP   BYTE PTR [0A22H],01H
        JE    L1BEE
        CMP   BYTE PTR [197FH],01H
        JNE   L1BEE
        MOV   BYTE PTR [197EH],00H
        MOV   BYTE PTR [197FH],00H
        AND   [PRN_STATUS],0F7H
        MOV   BYTE PTR [1255H],00H
L1BEE:  RET

L1BEF:  MOV   BYTE PTR [1970H],00H
        MOV   DX,OUT_03
        MOV   AL,26H
        OUT   DX,AL
        RET

L1BFB:  MOV   BYTE PTR [197AH],00H
        MOV   BYTE PTR [197BH],00H
        MOV   BYTE PTR [197CH],00H
        MOV   BYTE PTR [197DH],00H
        AND   AL,[027CH]
        JE    L1C2A
        MOV   BYTE PTR [0A22H],00H
        MOV   BYTE PTR [197EH],01H
        MOV   BYTE PTR [1979H],00H
        MOV   BYTE PTR [1978H],00H
        RET

L1C2A:  MOV   BYTE PTR [1978H],00H
        RET

L1C30:  CMP   BYTE PTR [1976H],01H
        JE    L1C43
        PUSH  ES
        LES   SI,DWORD PTR [1972H]
        MOV   AL,[PRN_STATUS]
        MOV   ES:[SI],AL
        POP   ES
L1C43:  RET

L1C44:  DW    6 DUP(0000H)
;---------------------------------------------------------------------
;      ende des residenten teils
;---------------------------------------------------------------------

;---------------------------------------------------------------------
INIT    PROC NEAR
        JMP   SHORT L1C6A

L1C52:  DW    0000H
L1C54:  DB    0FFH,00H
        DB    01H,0FFH
        DB    02H,03H
        DB    04H,0FFH
        DB    05H,06H,07H
        DB    08H,0AH
        DB    0BH,0CH
        DB    0DH,0EH,0FFH
        DB    0FH
L1C67:  DW    0FFFFH
        DB    0FFH

L1C6A:  MOV   AX,CS
        MOV   DS,AX
        MOV   ES,AX
        CLD
        MOV   SI,OFFSET MY_NAME
        CALL  PRINT_SI
        MOV   DX,OFFSET F_NAME
        MOV   AX,3D00H                      ;open a file for reading
        INT   DOS
        CALL  CHK_DOS
        MOV   BX,AX                         ;file handle
        MOV   DX,OFFSET BUFFER              ;DS:DX address of buffer
        MOV   CX,0080H                      ;number of bytes to read
        MOV   AH,3FH                        ;read a file
        INT   DOS
        CALL  CHK_DOS
        MOV   AH,3EH                        ;close a file
        INT   DOS
        CALL  CHK_DOS
        MOV   SI,OFFSET BUFFER
        ADD   SI,+10H
        MOV   DI,OFFSET NAMBUF
        MOV   CX,000DH
        REPZ  MOVSB
        CMP   BYTE PTR [NAMBUF],00H
        JNE   L1CB2
        MOV   AL,02H
        CALL  L1E5B
L1CB2:  MOV   DX,OFFSET NAMBUF              ;DS:DX to file name (asciz)
        MOV   AX,3D00H                      ;open a file for reading
        INT   DOS
        CALL  CHK_DOS
        MOV   BX,AX                         ;file handle
        MOV   DX,0268H                      ;DS:DX address of buffer
        MOV   CX,0200H                      ;bytes to read
        MOV   AH,3FH                        ;read a file
        INT   DOS
        CALL  CHK_DOS
        MOV   AH,3EH                        ;close a file
        INT   DOS
        CALL  CHK_DOS
        MOV   DX,OFFSET NAMBUF              ;DS:DX address of the string
        MOV   AH,09H                        ;print a string
        INT   DOS
        CMP   BYTE PTR [1E0AH],01H
        JNE   L1D1C
        MOV   SI,OFFSET BUFFER
        ADD   SI,+50H
        MOV   DI,OFFSET NAMBUF
        MOV   CX,000DH
        REPZ  MOVSB
        MOV   DX,OFFSET NAMBUF              ;DS:DX to file name (asciz)
        MOV   AX,3D00H                      ;open a file for reading
        INT   DOS
L1CF7:  CALL  CHK_DOS

        MOV   BX,AX                         ;file handle
        MOV   DX,0468H                      ;DS:DX address of buffer
        MOV   CX,0200H                      ;number of bytes
        MOV   AH,3FH                        ;read a file
        INT   DOS
L1D06:  CALL  CHK_DOS

        MOV   AH,3EH                        ;close a file
        INT   DOS
        CALL  CHK_DOS
        MOV   DX,OFFSET NAMBUF              ;DS:DX to string
        MOV   AH,09H                        ;print a string
        INT   DOS
L1D17:  MOV   BYTE PTR [0668H],01H
L1D1C:  MOV   BYTE PTR [FIRST],01H
        MOV   BYTE PTR [SECND],30H
        XOR   BX,BX
        MOV   BL,[0268H]
        CMP   BYTE PTR [BX+1B54H],0FFH
        JE    TO_ERR
        MOV   AL,[BX+1B54H]
        OR    [SECND],AL
        CMP   BYTE PTR [0269H],03H
        JNE   L1D49
        OR    BYTE PTR [FIRST],08H
        JMP   SHORT L1D55
L1D49:  CMP   BYTE PTR [0269H],04H
        JNE   TO_ERR
        OR    BYTE PTR [FIRST],0CH
L1D55:  CMP   BYTE PTR [026AH],01H
        JNE   L1D63
        OR    BYTE PTR [FIRST],00H
        JMP   SHORT L1D82
L1D63:  CMP   BYTE PTR [026AH],02H
        JNE   L1D71
        OR    BYTE PTR [FIRST],10H
        JMP   SHORT L1D82
L1D71:  CMP   BYTE PTR [026AH],03H
        JNE   TO_ERR
        OR    BYTE PTR [FIRST],30H
        JMP   SHORT L1D82
TO_ERR: CALL  PARAM_ERR                        ;serial port parameter error
L1D82:  CMP   BYTE PTR [026BH],01H
        JNE   L1D90
        OR    BYTE PTR [FIRST],40H
        JMP   SHORT L1DAA
L1D90:  CMP   BYTE PTR [026BH],02H
        JNE   L1D9E
        OR    BYTE PTR [FIRST],80H
        JMP   SHORT L1DAA
L1D9E:  CMP   BYTE PTR [026BH],03H
        JNE   TO_ERR
        OR    BYTE PTR [FIRST],0C0H
L1DAA:  MOV   AL,BYTE PTR [026CH]
        MOV   BYTE PTR [066BH],AL
        MOV   AL,BYTE PTR [0278H]
        MOV   BYTE PTR [066AH],AL
        MOV   AL,BYTE PTR [0279H]
        MOV   BYTE PTR [0669H],AL
        MOV   BX,01C3H
        MOV   AL,23H
        MOV   [BX],AL
        INC   BX
        MOV   AL,BYTE PTR [027BH]
        CMP   AL,01H
        JE    L1DD1
        XOR   AL,AL
        MOV   [BX],AL
        JMP   SHORT L1DD5
L1DD1:  MOV   AL,80H
        MOV   [BX],AL
L1DD5:  MOV   AL,BYTE PTR [027AH]
        CMP   AL,01H
        JNE   L1DDF
        OR    BYTE PTR [BX],40H
L1DDF:  INC   BX
        XOR   AL,AL
        MOV   [BX],AL
        XOR   BX,BX                             ;BX := 0, also 10ms timer
        MOV   CX,0032H                          ;anzahl der events bis traping
        MOV   AX,CS                             ;   alle 1/2 Sekunde
        MOV   DS,AX                             ;DS := CS
        LEA   DX,[TIMED]                        ;DS:DX addresse of trap handler
        MOV   AL,02H                            ;set event trap
        INT   BIOS
        MOV   BX,0001H                          ;serial port input char ready
        XOR   CX,CX                             ;CX := 0, d.h. goto hardware
        MOV   AX,CS
        MOV   DS,AX                             ;DS := CS
        LEA   DX,[SER_TRAP]                     ;DS:DX address of trap handler
        MOV   AL,02H                            ;set event trap
        INT   BIOS
        MOV   BX,0002H                          ;serial port output char ready
        XOR   CX,CX                             ;CX := 0, d.h. goto hardware
        MOV   AX,CS
        MOV   DS,AX                             ;DS := CS
        LEA   DX,[SER_TRAP]                     ;DS:DX address of trap handler
        MOV   AL,02H                            ;set event trap
        INT   BIOS
        MOV   DX,OUT_03                         ;port zur aux
        MOV   AL,22H
        OUT   DX,AL
        MOV   DX,OUT_03
        MOV   AL,22H
        OUT   DX,AL
        MOV   DX,IN_03
        IN    AL,DX
        MOV   DX,OUT_02                       ;port für die parameter setzen
        MOV   AL,BYTE PTR [FIRST]             ;erstes parameter byte zur aux
        OUT   DX,AL
        MOV   AL,BYTE PTR [SECND]
        OUT   DX,AL                           ;zweites parameter byte zur aux
I_END:  LDS   BX,DWORD PTR [STOREDB]
        MOV   AX,OFFSET INIT
        MOV   [BX+0EH],AX                     ;setze letzes byte im driver
        MOV   AX,CS
        MOV   [BX+10H],AX
        RET
INIT    ENDP

;gibt asciz string ab DS:SI auf bildschirm aus
;---------------------------------------------------------------------
PRINT_SI PROC NEAR
        XOR   BH,BH                           ;default screen
        MOV   BL,0AH                          ;line feed
        MOV   AL,06H                          ;send char to scr
        INT   BIOS
RUND0:  MOV   BL,[SI]                         ;char aus string lesen
        AND   BL,BL                           ;00H terminiert den string
        JE    ENDE0
        MOV   AL,06H                          ;send char to scr
        INC   SI                              ;next char
        INT   BIOS
        JMP   RUND0
ENDE0:  RET                                   ;fertig
PRINT_SI ENDP

;falls von DOS ein Fehler vorliegt wird abgebrochen
;---------------------------------------------------------------------
CHK_DOS PROC NEAR
        JB    DOS_E                           ;fehler kontrolle nach dos call
        RET                                   ;kein fehler
DOS_E:  MOV   BL,AL                           ;dos fehler gefunden
        MOV   DX,OFFSET ERR00                 ;"installation aborted"
        MOV   AH,09H                          ;print a string
        INT   DOS
        MOV   AL,BL                           ;fehlercode wieder in al
        CMP   AL,02H                          ;02H = file not found
        JNE   L1E73
        MOV   DX,OFFSET ERR01                 ;"missing index"
        MOV   AH,09H                          ;print a string
        INT   DOS
        JMP   SHORT E_END
L1E73:  MOV   DX,OFFSET ERR02                 ;"file access error"
        MOV   AH,09H                          ;pritn a string
        INT   DOS
E_END:  POP   AX                              ;adresse von 'call' wegnehmen
        JMP   I_END
CHK_DOS ENDP

;gibt fehlmeldung bei falschen schnittstellen paramatern
;---------------------------------------------------------------------
PARAM_ERR PROC NEAR                           ;wird auch über 'call' aufgerufen
        MOV   DX,OFFSET ERR00                 ;"installation aborted"
        MOV   AH,09H                          ;print a string
        INT   DOS
        MOV   DX,OFFSET ERR03                 ;"invalid serial port parameter"
        MOV   AH,09H                          ;print a string
        INT   DOS
        JMP   E_END                           ;zum beenden
PARAM_ERR ENDP

;---------------------------------------------------------------------
BUFFER  DW    64 DUP(0000H)
F_NAME  DB    'PRNXLT.COM',00H
ERR00   DB    'DRIVER INSTALLATION ABORTED',0DH,0AH,'$'
ERR01   DB    ' boot disk or root directory missing INDEX, FUNCTION '
        DB    'or TRANSLATE table',0DH,0AH,'$'
ERR02   DB    ' file access error',0DH,0AH,'$'
ERR03   DB    ' invalid serial port parameter',0DH,0AH,'$'
L1FB6:  DW    0000H
NAMBUF  DB    8+1+3+1 DUP(00H)
        DB    0DH,0AH,'$'
L1FC8:  DW    0000H

XSEG    ENDS
        END
