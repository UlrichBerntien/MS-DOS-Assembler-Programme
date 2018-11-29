        PAGE  60,132
;=====================================================================
; (c) Kommentare Ulrich Berntien .06.1990
;              letzte Änderung 08.06.1990
;
; Disassembler-Listing von RECOVER.COM
;
; Die COM Version entstand vermutlich aus einer EXE Version mit EXE2BIN
;=====================================================================

dosversion = 0314H                     ;akzeptierte dos version 3.20
space = 20H
tab = 09H
cr = 0DH

emo = 0580H                            ;offset für absolute adressen
                                       ;entsteht durch exe file wandlung

com     SEGMENT
        ASSUME cs : com, ds : com

        ORG   0100H

start:  JMP   e2b

        DB    'Converted'

;---------------------------------------------------------------------
; Execute File Header
;---------------------------------------------------------------------
        DB    4 DUP (00)               ;füllen auf einen paragraph
        DB    'MZ'                     ;hallo "Mark Zbikovski"
e_lm512 DW    0131H                    ;number of bytes in last page
e_pages DW    0009H                    ;number of 512-bytes pages, incl. header
e_relc  DW    0002H                    ;number of entries in relocation table
e_parh  DW    0020H                    ;number of 16-byte paragraphs in header
e_mins  DW    0000H                    ;minimum #paragraphs required above eop
e_maxs  DW    0FFFFH                   ;0FFFFH => locate as low as possible
e_spss  DD    01EA00CEH                ;initial value to be loaded in ss:sp
e_chks  DW    0E20DH                   ;negativ sum of all words in the run file
e_ipcs  DW    estart - emo             ;initial value to be loaded in cs:ip
        DW    0027H
e_rtab  DW    e_tab - 0110H            ;relative byte offset of relocation table
e_ov    DW    0000H                    ;number of the overlay, 0 = resident part
        DW    0001H
e_tab   DD    002701E0H                ;relocation table
        DD    002701E9H
        DB    474 DUP (00)             ;fill the 512-byte header
;---------------------------------------------------------------------

        DB    01H
        DB    10 DUP (00)
L031B:  DB    ' 0123456789ABCDEFabcdef'
L0332:  DW    12 DUP(0000H)
        DB    00H,15H,00H

L034F:  PUSH  AX
        PUSH  BX
        PUSH  CX
        PUSH  BX
        PUSH  AX
        PUSH  DI
        PUSH  SI
        PUSH  ES
        PUSH  DS
        MOV   BP,SP
        PUSH  CS
        POP   ES
        MOV   DI,0026H
        MOV   BP,[BP+16H]
        MOV   SI,DS:[BP+00H]
        XOR   BX,BX
        CALL  L0563
L0369:  LODSB
        CMP   AL,25H
        JE    L039E
        OR    AL,AL
        JE    L0377
        CALL  L0532
        JMP   L0369
L0377:  CALL  L0553
        POP   DS
        POP   ES
        POP   SI
        POP   DI
        POP   AX
        POP   BX
        POP   CX
        POP   DX
        POP   BP
        POP   CS:[0022H]                      ;rücksprung adresse sichern
        POP   CS:[0024H]
        POP   AX                              ;flags vom stack
        PUSH  WORD PTR CS:[0024H]             ;rücksprungadresse auf den stack
        PUSH  WORD PTR CS:[0022H]
        RETF                                  ;== iret ohne flags restaurierung

L0399:  CALL  L0532
        JMP   L0369
L039E:  LODSB
        CMP   AL,25H
        JE    L0399
L03A3:  CMP   AL,2DH
        JE    L03E6
        CMP   AL,2BH
        JE    L03F2
        CMP   AL,4CH
        JE    L03ED
        CMP   AL,6CH
        JE    L03ED
        CMP   AL,30H
        JE    L03F4
        CMP   AL,39H
        JA    L03F4
        CMP   AL,30H
        JNE   L03CD
        CMP   WORD PTR CS:[0007H],+00H
        JNE   L03CD
        MOV   BYTE PTR CS:[000BH],30H
L03CD:  PUSH  AX
        MOV   AX,000AH
        MUL   WORD PTR CS:[0007H]
        MOV   WORD PTR CS:[0007H],AX
        POP   AX
        XOR   AH,AH
        SUB   AL,30H
        ADD   CS:[0007H],AX
        JMP   SHORT L03F2
        INC   BYTE PTR CS:[0002H]
        JMP   SHORT L03F2
        INC   BYTE PTR CS:[0003H]
L03F2:  JMP   SHORT L039E
L03F4:  CMP   AL,58H
        JE    L041E
        CMP   AL,61H
        JE    L0402
        CMP   AL,7AH
        JNLE  L0402
        AND   AL,0DFH
L0402:  CMP   AL,58H
        JE    L0418
        CMP   AL,44H
        JE    L0428
        CMP   AL,43H
        JE    L0437
        CMP   AL,53H
        JE    L0432
        CALL  L0563
        JMP   L0369
L0418:  MOV   BYTE PTR CS:[0005H],06H
        MOV   WORD PTR CS:[0009H],0010H
        JMP   L04A2
L0428:  MOV   WORD PTR CS:[0009H],000AH
        JMP   L04A2
        INC   BYTE PTR CS:[0006H]
        PUSH  SI
        MOV   SI,BX
        ADD   BX,+02H
        MOV   SI,DS:[BP+SI+02H]
        CMP   BYTE PTR CS:[0006H],00H
        JNE   L0453
        LODSB
        CMP   AL,00H
        JE    L0489
        CALL  L0532
        JMP   SHORT L0489
L0453:  MOV   CX,CS:[0007H]
        OR    CX,CX
        JE    L0469
        CMP   BYTE PTR CS:[0002H],00H
        JNE   L0469
        PUSH  SI
        CALL  L0490
        POP   SI
L0469:  PUSH  SI
L046A:  LODSB
        CMP   AL,00H
        JE    L0474
        CALL  L0532
        JMP   SHORT L046A
L0474:  POP   SI
        CMP   BYTE PTR CS:[0002H],00H
        JE    L0489
        MOV   CX,CS:[0007H]
        OR    CX,CX
        JE    L0489
        CALL  L0490
L0489:  CALL  L0563
        POP   SI
        JMP   L0369
L0490:  XOR   DX,DX
L0492:  LODSB
        OR    AL,AL
        JE    L049A
        INC   DX
        JMP   SHORT L0492
L049A:  SUB   CX,DX
        JBE   L04A1
        CALL  L0522
L04A1:  RET

L04A2:  PUSH  SI
        MOV   SI,BX
        ADD   BX,+02H
        MOV   AX,DS:[BP+SI+02H]
        CMP   BYTE PTR CS:[0003H],00H
        JE    L04BF
        MOV   SI,BX
        ADD   BX,+02H
        MOV   DX,DS:[BP+SI+02H]
        JMP   SHORT L04C1
L04BF:  XOR   DX,DX
L04C1:  PUSH  BX
        MOV   SI,CS:[0009H]
        MOV   CX,CS:[0007H]
        CALL  L04DA
        CALL  L0522
        CALL  L0563
        POP   BX
        POP   SI
        JMP   L0369
L04DA:  DEC   CX
        PUSH  AX
        MOV   AX,DX
        XOR   DX,DX
        DIV   SI
        MOV   BX,AX
        POP   AX
        DIV   SI
        XCHG  BX,DX
        PUSH  AX
        OR    AX,DX
        POP   AX
        JE    L04F6
        PUSH  BX
        CALL  L04DA
        POP   BX
        JMP   SHORT L0501
L04F6:  CMP   BYTE PTR CS:[0002H],00H
        JNE   L0501
        CALL  L0522
L0501:  MOV   AX,BX
        CMP   AL,0AH
        JB    L0514
        CMP   BYTE PTR CS:[0004H],00H
        JNE   L0514
        ADD   AL,CS:[0005H]
L0514:  MOV   BX,000CH
        PUSH  DS
        PUSH  CS
        POP   DS
        XLAT
        POP   DS
        PUSH  CX
        CALL  L0532
        POP   CX
        RET

;---------------------------------------------------------------------
L0522:  OR    CX,CX
        JLE   L0531
        MOV   AL,BYTE PTR CS:[000BH]
L052A:  PUSH  CX
        CALL  L0532
        POP   CX
        LOOP  L052A
L0531:  RET

;---------------------------------------------------------------------
L0532:  STOSB
        CMP   DI,003AH
        JE    L053A
L0539:  RET

L053A:  MOV   CX,0014H                        ;number of bytes for i/o
L053D:  PUSH  BX
        MOV   BX,CS:[0000H]                   ;file handle
        PUSH  DS
        PUSH  CS
        POP   DS                              ;ds := cs
        MOV   DX,0026H                        ;ds:dx address of a buffer
        MOV   AH,40H                          ;write a file
        INT   21H
        POP   DS
        POP   BX
        MOV   DI,0026H
        RET

;---------------------------------------------------------------------
L0553:  CMP   DI,0026H
        JE    L0539
        SUB   DI,0026H
        MOV   CX,DI
        CALL  L053D
        RET

;---------------------------------------------------------------------
L0563:  XOR   AX,AX                           ;ein haufen nullen
        MOV   BYTE PTR CS:[0002H],AL
        MOV   BYTE PTR CS:[0003H],AL
        MOV   BYTE PTR CS:[0005H],AL
        MOV   WORD PTR CS:[0007H],AX
        MOV   BYTE PTR CS:[000BH],20H
        MOV   BYTE PTR CS:[0006H],AL
        RET

;---------------------------------------------------------------------
estart: JMP   main                            ;start des execute programs

L0583:  DB    'Vers 2.00'
L058C:  DW    4 DUP(0000H)
        DB    00H,2FH
        DB    00H,2FH
L0598:  DW    98 DUP(0000H)

;---------------------------------------------------------------------
L065C:  MOV   BX,0CC0H
        CMP   WORD PTR DS:[0CBAH],0FF8H
        JB    L0670
        MOV   SI,AX
        ADD   SI,AX
        MOV   BX,[BX+SI]
        JMP   L0685
L0670:  PUSH  AX
        MOV   SI,AX
        SAR   AX,1
        PUSHF
        ADD   SI,AX
        MOV   BX,[BX+SI]
        POPF
        JNB   L0681
        MOV   CL,04H
        SHR   BX,CL
L0681:  AND   BH,0FH
        POP   AX
L0685:  MOV   CX,DS:[0CB0H]
        RET

;---------------------------------------------------------------------
L068A:  MOV   BX,0CC0H
        CMP   WORD PTR DS:[0CBAH],0FF8H
        JB    L069E
        MOV   SI,AX
        ADD   SI,AX
        MOV   [BX+SI],DX
        JMP   L06BE
L069E:  PUSH  AX
        PUSH  DX
        MOV   SI,AX
        SAR   AX,1
        PUSHF
        ADD   SI,AX
        MOV   AX,[BX+SI]
        POPF
        JNB   L06B5
        AND   AX,000FH
        MOV   CL,04H
        SHL   DX,CL
        JMP   SHORT L06B8
L06B5:  AND   AX,0F000H
L06B8:  OR    AX,DX
        MOV   [BX+SI],AX
        POP   DX
        POP   AX
L06BE:  RET

; wartet bis eine beliebige Taste gedrück wird,
; dabei ein CTRL-C Abbruch möglich
;---------------------------------------------------------------------
waiting PROC NEAR
        MOV   AX,0C08H                        ;buffer flush, consol input
        INT   21H                             ;              without echo
        MOV   AX,0C00H                        ;buffer flush
        INT   21H
L06C9:  RET
waiting ENDP

;---------------------------------------------------------------------
L06CA:  CMP   BYTE PTR DS:[000CH],00H
        JNE   L06C9
        MOV   BYTE PTR DS:[000CH],01H
        PUSH  DS
        PUSH  CS
        POP   DS
        MOV   DX,0956H
        CALL  L0765
        POP   DS
        CALL  waiting
        MOV   AL,BYTE PTR CS:[0014H]
        CMP   AL,01H
        JNBE  L06F5
        PUSH  DS
        MOV   BX,0050H
        MOV   DS,BX
        MOV   BYTE PTR DS:[0004H],AL
        POP   DS
L06F5:  RET

;---------------------------------------------------------------------
L06F6:  MOV   DX,DS:[0CA2H]
        MOV   AL,BYTE PTR DS:[0C9FH]
        MOV   BYTE PTR DS:[0C9EH],AL
        MOV   AL,BYTE PTR DS:[0014H]
        MOV   CX,DS:[0CA0H]
        MOV   BX,0CC0H
L070A:  RET

L070B:  CALL  L06F6
L070E:  CALL  L0C20
        CMP   WORD PTR DS:[0C9AH],+00H
        JNE   L071C
        MOV   DS:[0C9AH],DX
L071C:  CMP   WORD PTR [BX+01H],-01H
        JE    L070A
        ADD   DX,CX
        DEC   BYTE PTR DS:[0C9EH]
        JNE   L070E
        MOV   DX,DS:[0C9AH]
        OR    DX,DX
        JE    L070B
        CALL  L0C20
        RET

L0736:  CALL  L06F6
L0739:  PUSH  AX
        PUSH  BX
        PUSH  CX
        PUSH  DX
        CALL  L0C05
        POP   DX
        POP   CX
        POP   BX
        POP   AX
        ADD   DX,CX
        DEC   BYTE PTR DS:[0C9EH]
        JNE   L0739
        RET

L074D:  CMP   BX,DS:[0CBAH]
        JBE   L075A
        CMP   BL,0F7H
        JE    L075A
        STC
        RET

L075A:  CLC
        RET

L075C:  PUSH  DX
        EXTRN L0000H_003DH:FAR
        CALL  L0000H_003DH
L0762:  MOV   DX,08E9H
L0765:  PUSH  DX
        EXTRN L0000H_003DH:FAR
        CALL  L0000H_003DH
        RET

; Program Ende wie eprog, jedoch ohne den Int. 24H wieder herzustellen
; DS:DX zeigt auf einen FEhlertext, der Ausgeben wird
;---------------------------------------------------------------------
eprog2: PUSH  CS
        POP   DS                              ;ds := cs
        PUSH  DX
        MOV   DL,DS:[0013H]                   ;altes drive auswählen
        MOV   AH,0EH                          ;select disk
        INT   21H
        POP   DX
        CALL  L075C
        MOV   AL,0FFH
        JMP   xprog                           ;zum program ende

L0780:  MOV   BL,ES:[DI+18H]
        XOR   BH,BH
        PUSH  AX
        PUSH  BX
        MOV   AH,52H                          ;dos infoblock holen
        INT   21H                             ;  es:bx auf den dib
        LES   DI,DWORD PTR ES:[BX+1AH]        ;es:di auf file table
        LEA   DI,[DI+06H]
        POP   BX
        PUSH  DX
        MOV   AX,0035H
        MUL   BX
        ADD   DI,AX
        POP   DX
        POP   AX
        RET

;---------------------------------------------------------------------
main    PROC FAR
L079F:  PUSH  AX
        MOV   AH,30H                          ;get dos version number in al,ah
        INT   21H
        XCHG  AH,AL                           ;erste ziffer in ah
        CMP   AX,dosversion
        JB    L07B0                           ;falsch dos version
        CMP   AX,dosversion
        JBE   L07BE                           ;nur diese dos version erlaubt
L07B0:  PUSH  CS
        POP   DS                              ;ds := cs
        MOV   DX,fvers - emo                  ;ds:dx auf fehler text
        MOV   AH,09H                          ;print  string
        INT   21H
        PUSH  ES
        XOR   AX,AX
        PUSH  AX
        RET  ;RETF                            ;jmp psp:0000 ,programm ende

L07BE:  PUSH  ES
        MOV   AX,3524H                        ;get interrupt vektor 24H
        INT   21H
        MOV   CS:[000DH],BX                   ;alter vektor sichern
        MOV   CS:[000FH],ES
        POP   ES
        MOV   AH,19H                          ;get current disk
        INT   21H
        MOV   BYTE PTR CS:[0013H],AL          ;current disk abspeicher
        POP   AX
        CMP   AL,0FFH                         ;ungültiges drive bei parameter
        JE    L07F4                           ;  ja
        MOV   SI,0080H                        ;es:si auf #zeichen im parameter
        LODSB                                 ;in al laden
        OR    AL,AL                           ;keine zeichen da
        JE    L07F1
L07E4:  LODSB                                 ;zeichen aus parameter laden
        CMP   AL,space                        ;leerziechen überlesen
        JE    L07E4
        CMP   AL,09H                          ;tab's überlesen
        JE    L07E4
        CMP   AL,cr                           ;cr am ende der partmeter zeile
        JNE   L07F7
L07F1:  JMP   L090F
L07F4:  JMP   L08BB
L07F7:  MOV   AH,0DH                          ;disk reset, flush all buffers
        INT   21H
        MOV   BX,005CH
        MOV   AL,[BX]
        DEC   AL
        CMP   AL,0FFH
        JNE   L080A
        MOV   AL,BYTE PTR CS:[0013H]          ;drive bei program start holen
L080A:  PUSH  AX
        PUSH  BX
        PUSH  DX
        MOV   BL,AL
        INC   BL
        MOV   AX,4409H                        ;i/o control for device
        INT   21H
        JB    L0826                           ;sprung falls dosfehler (carry=1)
        TEST  DX,1200H
        JE    L0826
        PUSH  CS
        POP   DS                              ;ds := cs
        MOV   DX,0A6DH
        JMP   eprog2                          ;progam beenden
L0826:  POP   DX
        POP   BX
        POP   AX
        MOV   BYTE PTR CS:[0014H],AL
        ADD   CS:[095AH],AL
        ADD   CS:[07BAH],AL
        MOV   SI,005CH
        PUSH  CS
        POP   ES
        MOV   DI,0C7AH
        MOV   CX,0020H
        REPZ  MOVSB
        MOV   AX,3700H                        ;get dos switch character in dl
        INT   21H
        CMP   DL,'/'
        JNE   L085A
        MOV   BYTE PTR CS:[0015H],5CH
        MOV   BYTE PTR CS:[0017H],5CH
L085A:  MOV   SI,0081H                        ;si auf anfang parameter zeile
        MOV   DI,005CH
        XOR   CX,CX                           ;cx := 0
L0862:  LODSB
        CMP   AL,tab                          ;tab's überlesen
        JE    L0862
        CMP   AL,space                        ;leerzeichen überlesen
        JE    L0862
        CMP   AL,cr                           ;cr beendet parameter zeile
        JNE   L0872
        JMP   L090F
L0872:  STOSB
        INC   CX
        LODSB
        CMP   AL,space
        JE    L0881
        CMP   AL,tab
        JE    L0881
        CMP   AL,cr
        JNE   L0872
L0881:  MOV   BYTE PTR [DI],00H               ;parameter durch 00 abschließen
        DEC   DI
        PUSH  CS
        POP   DS                              ;ds := cs
        MOV   AL,BYTE PTR DS:[0015H]
        STD
        REPNZ SCASB
        CLD
        JE    L0893
        JMP   L0901
L0893:  JCXZ  L089A
        CMP   BYTE PTR [DI],':'
        JNE   L089F
L089A:  MOV   BYTE PTR DS:[0011H],01H
L089F:  INC   DI
        MOV   AL,00H
        STOSB
        PUSH  DI
        MOV   BYTE PTR DS:[0012H],01H
        MOV   DL,DS:[0C7AH]
        OR    DL,DL
        JE    L08C1                           ;dl = 0, default drive
        DEC   DL
        MOV   AH,0EH                          ;select disk
        INT   21H
        CMP   AL,0FFH
        JNE   L08C1
L08BB:  MOV   DX,0A1CH
        JMP   eprog2                          ;programm beenden
L08C1:  CALL  L06CA
        MOV   AH,47H                          ;return current directory
        MOV   DL,00H
        MOV   SI,0018H                        ;ds:si auf 64 byte buffer
        INT   21H
        CMP   BYTE PTR DS:[0011H],01H
        MOV   DX,0015H
        JE    L08DA
        MOV   DX,005CH                        ;ds:dx to asciz-name of a path
L08DA:  MOV   AH,3BH                          ;change current directory
        INT   21H
        MOV   DX,0A1CH
        JNB   L08E6
        JMP   eprog2                          ;programm beenden
L08E6:  MOV   AX,2523H                        ;set interrupt vector 23H
        MOV   DX,eprog - emo                  ;to the address ds:dx
        INT   21H
        MOV   AX,2524H                        ;set interrupt vector 24H
        MOV   DX,h24h - emo                   ;to the address ds:dx
        INT   21H
        PUSH  CS
        POP   ES                              ;es := cs
        POP   SI
        MOV   DI,0C7AH
        MOV   AX,2901H                        ;parse file name
        INT   21H
L0901:  MOV   BX,0C7AH
        CMP   BYTE PTR [BX+01H],space
        JNE   L091A
        CMP   BYTE PTR [BX],00H
        JNE   L091A
L090F:  PUSH  CS
        POP   DS
        MOV   DX,0A1CH
        CALL  L075C
        JMP   eprog                           ;program bebenden
L091A:  CALL  L06CA
        PUSH  DS
        MOV   DL,DS:[0014H]
        INC   DL
        MOV   AH,32H                          ;
        INT   21H
        CMP   AL,0FFH
        JE    L090F
        MOV   AX,[BX+02H]
        PUSH  AX
        MOV   CL,[BX+04H]
        XOR   CH,CH
        INC   CX
        MOV   CS:[0CA6H],CX
        MUL   CX
        MOV   WORD PTR CS:[0CB0H],AX
        MOV   BP,[BX+0BH]
        MOV   DX,[BX+10H]
        MOV   SI,[BX+06H]
        MOV   CL,[BX+0FH]
        MOV   DI,[BX+0DH]
        MOV   CH,[BX+08H]
        MOV   BX,[BX+09H]
        POP   AX
        POP   DS
        MOV   DS:[0CAAH],BX
        MOV   DS:[0CA2H],SI
        MOV   DS:[0CACH],BP
        MOV   DS:[0CAEH],DX
        MOV   DS:[0CA0H],CL
        MOV   DS:[0CBCH],DI
        MOV   DS:[0CBAH],DI
        MOV   DS:[0C9FH],CH
        XOR   CH,CH
        MUL   CX
        ADD   DS:[0CBEH],AX
        MOV   DI,DS:[0CBEH]
        MOV   AX,0E5E5H
        MOV   CL,04H
        SHL   BX,CL
        MOV   CX,BX
        REPZ  STOSW
        CALL  L070B
        MOV   BX,0C7AH
        CMP   BYTE PTR [BX+01H],20H
        JE    L099E
        JMP   L0A9C
L099E:  MOV   DI,DS:[0CBEH]
        MOV   WORD PTR DS:[0CA4H],0002H
        MOV   AX,WORD PTR DS:[0CA4H]
L09AB:  CALL  L065C
        CALL  L074D
        JB    L09B6
        JMP   L0A5D
L09B6:  MOV   WORD PTR DS:[0CB6H],0000H
        MOV   WORD PTR DS:[0CB8H],0000H
        MOV   DX,DS:[0CBAH]
        MOV   WORD PTR DS:[0CA8H],AX
L09C9:  ADD   DS:[0CB6H],CX
        ADC   WORD PTR DS:[0CB8H],+00H
        MOV   AX,0002H
L09D5:  CALL  L065C
        CMP   BX,DS:[0CA8H]
        JNE   L09E3
        MOV   WORD PTR DS:[0CA8H],AX
        JMP   L09C9
L09E3:  INC   AX
        CMP   AX,DX
        JBE   L09D5
        INC   WORD PTR DS:[0C9CH]
        MOV   AX,WORD PTR DS:[0CAAH]
        CMP   DS:[0C9CH],AX
        JNBE  L0A6D
        MOV   SI,0C61H
L09F8:  INC   BYTE PTR [SI]
        CMP   BYTE PTR [SI],39H
        JLE   L0A05
        MOV   BYTE PTR [SI],30H
        DEC   SI
        JMP   L09F8
L0A05:  MOV   AH,2AH                          ;get date in cx:dx
        INT   21H
L0A09:  SUB   CX,07BCH
        ADD   DH,DH
        ADD   DH,DH
        ADD   DH,DH
        ADD   DH,DH
        ADD   DH,DH
        RCL   CL,1
        OR    DH,DL
        MOV   DS:[0C72H],DH
        MOV   DS:[0C73H],CL
        MOV   AH,2CH                          ;get time
        INT   21H
        SHR   DH,1
        ADD   CL,CL
        ADD   CL,CL
        ADD   CL,CL
        RCL   CH,1
        ADD   CL,CL
        RCL   CH,1
        ADD   CL,CL
        RCL   CH,1
        OR    DH,CL
        MOV   DS:[0C70H],DH
        MOV   DS:[0C71H],CH
        MOV   AX,WORD PTR DS:[0CB6H]
        MOV   WORD PTR DS:[0C76H],AX
        MOV   AX,WORD PTR DS:[0CB8H]
        MOV   WORD PTR DS:[0C78H],AX
        MOV   AX,WORD PTR DS:[0CA8H]
        MOV   WORD PTR DS:[0C74H],AX
        MOV   SI,0C5AH
        MOV   CX,0020H
        REPZ  MOVSB
L0A5D:  INC   WORD PTR DS:[0CA4H]
        MOV   AX,WORD PTR DS:[0CA4H]
        CMP   AX,DS:[0CBAH]
        JNBE  L0A77
        JMP   L09AB
L0A6D:  DEC   WORD PTR DS:[0C9CH]
        MOV   DX,097FH
        CALL  L075C
L0A77:  MOV   AL,BYTE PTR DS:[0014H]
        MOV   DX,DS:[0CAEH]
        MOV   CX,DS:[0CACH]
        SUB   CX,DX
        MOV   BX,DS:[0CBEH]
        CALL  L0C05
        MOV   DX,09A0H
        MOV   SI,DS:[0C9CH]
        MOV   DS:[09A2H],SI
        CALL  L075C
        JMP   L0BB0
L0A9C:  MOV   DX,0C7AH                        ;ds:dx to an unopend fcb
        MOV   AH,0FH                          ;open file
        INT   21H
        INC   AL
        JNE   L0AB0
        MOV   DX,0A33H
        CALL  L075C
        JMP   L0BB0
L0AB0:  MOV   WORD PTR DS:[0CBCH],0001H
        MOV   DI,0C7AH
        MOV   AX,[DI+10H]
        MOV   WORD PTR DS:[0CB6H],AX
        MOV   WORD PTR DS:[0CB2H],AX
        MOV   AX,[DI+12H]
        MOV   WORD PTR DS:[0CB8H],AX
        MOV   WORD PTR DS:[0CB4H],AX
        PUSH  ES
        PUSH  DI
        CALL  L0780
        MOV   AX,ES:[DI+0BH]
        POP   DI
        POP   ES
        MOV   WORD PTR DS:[0CA4H],AX
        OR    AX,AX
        JNE   L0AE0
L0ADD:  JMP   L0BA3
L0AE0:  MOV   BX,DS:[0CA4H]
        CALL  L074D
        JB    L0ADD
        MOV   CX,DS:[0CA6H]
        MOV   AX,WORD PTR DS:[0CA4H]
        DEC   AX
        DEC   AX
        MUL   CX
        ADD   AX,DS:[0CACH]
        MOV   DX,AX                           ;beginnig logical record number
        MOV   BX,DS:[0CBEH]                   ;ds:dx transfer address
        MOV   AL,BYTE PTR DS:[0014H]          ;drive number (a=0,b=1,..)
        INT   25H                             ;absolute disk read
        POP   DI
        MOV   DI,0C7AH
        JNB   L0B7D
        MOV   AX,WORD PTR DS:[0CA4H]
        CALL  L065C
        CMP   WORD PTR DS:[0CBCH],+01H
        JNE   L0B2D
        CALL  L074D
        JNB   L0B1D
        XOR   BX,BX
L0B1D:  PUSH  ES
        PUSH  DI
        PUSH  BX
        CALL  L0780
        POP   BX
        MOV   ES:[DI+0BH],BX
        POP   DI
        POP   ES
        JMP   L0B35
L0B2D:  MOV   DX,BX
        MOV   AX,WORD PTR DS:[0CBCH]
        CALL  L068A
L0B35:  MOV   AX,WORD PTR DS:[0CA4H]
        MOV   DX,0FFF7H
        CALL  L068A
        MOV   AX,WORD PTR DS:[0CB0H]
        CMP   WORD PTR DS:[0CB4H],+00H
        JNE   L0B51
        CMP   DS:[0CB2H],AX
        JNBE  L0B51
        MOV   AX,WORD PTR DS:[0CB2H]
L0B51:  PUSH  ES
        PUSH  DI
        CALL  L0780
        SUB   ES:[DI+11H],AX
        SBB   WORD PTR ES:[DI+13H],+00H
        SUB   DS:[0CB2H],AX
        SBB   WORD PTR DS:[0CB2H],+00H
        AND   WORD PTR ES:[DI+05H],0FFBFH
        POP   DI
        POP   ES
        SUB   [DI+10H],AX
        SBB   WORD PTR [DI+12H],+00H
        MOV   AX,WORD PTR DS:[0CBCH]
        JMP   L0B99
L0B7D:  MOV   AX,WORD PTR DS:[0CB0H]
        SUB   DS:[0CB2H],AX
        SBB   WORD PTR DS:[0CB4H],+00H
        JNB   L0B93
        XOR   AX,AX
        MOV   WORD PTR DS:[0CB2H],AX
        MOV   WORD PTR DS:[0CB4H],AX
L0B93:  MOV   AX,WORD PTR DS:[0CA4H]
        MOV   WORD PTR DS:[0CBCH],AX
L0B99:  CALL  L065C
        MOV   DS:[0CA4H],BX
        JMP   L0AE0
L0BA3:  MOV   DX,0C7AH                        ;ds:dx point to an open fcb
        MOV   AH,10H                          ;close a file
        INT   21H
        CALL  L0762
        CALL  L0C92
L0BB0:  MOV   AH,0DH                          ;disk reset, fluch all buffers
        INT   21H
        CALL  L0736
                                              ;ende des programms
eprog:  CALL  cleaning
        XOR   AL,AL                           ;al := 0, return code
xprog:  MOV   AH,4CH                          ;exit from a process
        INT   21H
main    ENDP

; Aufräumen vor Programm Ende
; + Interrupt 24H (Fatal error abort) zurücksetzen
; + auf altes Driver umschalten
;---------------------------------------------------------------------
cleaning PROC NEAR
        CMP   BYTE PTR DS:[0012H],00H
        JE    L0BD9
        MOV   AX,2524H                        ;set interrupt vector 24H
        LDS   DX,DWORD PTR DS:[000DH]         ;die alte adresse
        INT   21H
        PUSH  CS
        POP   DS                              ;ds := cs
        MOV   DX,0017H                        ;ds:dx to asciz path name
        MOV   AH,3BH                          ;change current directory
        INT   21H
L0BD9:  MOV   DL,DS:[0013H]                   ;das alte drive auswählen
        MOV   AH,0EH                          ;select disk
        INT   21H
        RET
cleaning ENDP

; handler für den Interrupt 24H, Fatal Error Abort Vector
;---------------------------------------------------------------------
nadr    DW    L0BF6 - emo

h24h    PROC FAR
        PUSHF
        PUSH  CS
        PUSH  WORD PTR CS:[nadr-emo]          ;simuliert interruput aufruf
        PUSH  WORD PTR CS:[000FH]             ;den alten inter. 24H handler
        PUSH  WORD PTR CS:[000DH]             ;anspringen
        RET  ;RETF                            ;sprung nach DWORD PTR [CS:000D]

L0BF6:  CMP   AL,02H                          ;02 = abort program
        JNE   L0C03                           ;sonst wieter machaen
        PUSH  CS
        POP   DS                              ;ds := cs
        CALL  cleaning
        MOV   AH,4CH                          ;exit from a process
        INT   21H                             ; mit error code = 02

L0C03:  IRET                                  ;zurÞck, weiter im program

h24h    ENDP
;---------------------------------------------------------------------

        DB    00H

L0C05:  PUSH  AX
        PUSH  BX
        PUSH  CX
        PUSH  DX
        INT   26H                             ;absolut disk write
        MOV   BYTE PTR DS:[0684H],AL
        INC   SP
        INC   SP
        POP   DX
        POP   CX
        POP   BX
        POP   AX
        JNB   L0C1F
        MOV   SI,07A2
        CALL  L0C3B
        JE    L0C05
        CLC
        RET

L0C20:  PUSH  AX
        PUSH  BX
        PUSH  CX
        PUSH  DX
        INT   25H                             ;absolute disk read
L0C26:  MOV   BYTE PTR DS:[0684H],AL
        INC   SP
        INC   SP
        POP   DX
        POP   CX
        POP   BX
        POP   AX
        JNB   L0C1F
        MOV   SI,078DH
        CALL  L0C3B
        JE    L0C20
        CLC
        RET

L0C3B:  PUSH  AX
        PUSH  BX
        PUSH  CX
        PUSH  DX
        PUSH  DI
        PUSH  ES
        MOV   AL,BYTE PTR DS:[0684H]
        CMP   AL,0CH
        JBE   L0C4A
        MOV   AL,0CH
L0C4A:  XOR   AH,AH
        MOV   DI,AX
        SHL   DI,1
        MOV   DX,[DI+0759H]
        MOV   DS:[0787H],DX
        MOV   DS:[0789H],SI
        MOV   DX,0785H
        CALL  L075C
L0C62:  MOV   DX,08E4H
        CALL  L0765
        MOV   AX,0C01H                        ;buffer flush, keyboard input
        INT   21H
        PUSH  AX
        CALL  L0762
        POP   AX
        OR    AL,20H
        CMP   AL,DS:[0740H]
        JE    L0C89
        CMP   AL,DS:[0741H]
        JE    L0C8B
        CMP   AL,DS:[0742H]
        JNE   L0C62
        JMP   eprog                           ;program beenden
L0C89:  OR    AL,AL
L0C8B:  POP   ES
        POP   DI
        POP   DX
        POP   CX
        POP   BX
        POP   AX
        RET

L0C92:  MOV   DX,09CAH
        MOV   SI,[DI+10H]
        MOV   DS:[09CCH],SI
        MOV   DI,[DI+12H]
        MOV   DS:[09CEH],DI
        MOV   SI,DS:[0CB6H]
        MOV   DS:[09D0H],SI
        MOV   DI,DS:[0CB8H]
        MOV   DS:[09D2H],DI
        CALL  L075C
        RET

L0CB7:  DW    4 DUP(0000H)
        DB    00H,69H,77H,61H
fvers:  DB    'Falsche DOS Version',0DH,0AH,'$'
        DB    0BCH,07H,0DCH
        DB    07H
        DB    0FDH
        DB    07H
        DB    10H,08H
        DB    25H,08H,31H
        DB    08H,4BH,08H
        DB    61H
        DB    08H,74H,08H
        DB    8AH,08H
        DB    98H
L0CEE:  DB    08H,0A6H,08H,0B1H
        DB    08H
L0CF4:  DB    '%s %s Laufwerk %c'
        DB    00H,73H,07H
L0D07:  DW    2 DUP(0000H)
        DB    0BAH,07H,62H
L0D0E:  DB    'Beim Lesevorgang von',00
        DB    'beim Schreibvorgang auf',00
        DB    'A',00H
L0D3C:  DB    'Fehler!  Datei schreibgeschützt',00
        DB    'Ungültige Gerätenummer angegeben',00
        DB    'Gerät nicht bereit',00
        DB    'Unzulässiger Befehl ',00
        DB    'Datenfehler',00
        DB    'Unzulässiges Aufrufformat',00
        DB    'Positionierungsfehler',00
        DB    'keine DOS-Diskette',00
        DB    'Sektor nicht gefunden',00
        DB    'Druckerfehler',00
        DB    'Schreibfehler',00
        DB    'Lesefehler',00
        DB    'Plattenfehler',00
        DB    'Abrechen, Wiederholen, Ignorieren? ',00
        DB    0BFH,08H,0DH
        DB    0AH,00H
        DB    0E6H,08H
L0E6B:  DB    0DH,0AH,'Starten Sie durch Drücken einer be-',0DH,0AH,
        DB    'liebigen Taste die Wiederherstellung',0Dh,0AH,
        DB    'der Datei(en) auf Laufwerk %s',00H
        DB    0EBH
        DB    08H,5AH,09H
L0EDA:  DB    'A: ',0DH,0AH,0DH,0AH,00H
L0EE3:  DB    0DH,0AH,'Warnung - Katalog ist voll',00H
        DB    62H,09H
L0F01:  DB    '%d Datei(en) wiederhergestellt',00H
        DB    81H,09H,00H,00H
L0F24:  DB    0DH,0AH,'%ld von %ld Bytes wiederhergestellt',00
        DB    0A4H,09H,00H
L0F4D:  DB    7 DUP(00H)
        DB    55H,6EH
        DB    'Ungültige Anzahl von Parametern',00
        DB    'T',00
        DB    'Ungültige Datei- oder Laufwerksangabe',00
        DB    'v',00
        DB    'Datei nicht gefunden',00
        DB    1EH,0AH,4EH
L0FB6:  DB    'Netzwerk-Dateien können nicht wieder hergestellt werden',0
        DW    0A35H
        DB    00H
L0FF0:  DW    245 DUP(0000H)
L11DA:  DB    'FILE0000REC'
L11E5:  DW    44 DUP(0000H)
        DB    00H,0C0H
        DB    0CH,00H

m1      DW    0000H
m2      DW    0000H
m3      DW    0000H
m4      DW    0000H

;---------------------------------------------------------------------
; Register bei Programmstart, gestzt vom Betriebssystem:
; + CS,DS,ES,SS sind auf das Segment
; + bei Programmstart wird in den Register AL und Ah die Gültigkeit
;   der Laufwerksangabe des ersten bzw. zweiten Parameters übergeben
;   0FFH => kein gültiges Laufwerk, 000H => gültige Angabe
;---------------------------------------------------------------------
e2b     PROC NEAR
        CALL  mtrick
mtrick: POP   BX                              ;bx := ip = diese adresse
        PUSH  AX                              ;sichern der drive designations
        MOV   AX,ES
        ADD   AX,0010H                        ;ax = segment des exe-headers
        MOV   CX,DS:[011EH]                   ;benötigter speicher
        ADD   CX,AX                           ;obere speichergrenze
        MOV   [BX+m4-main],CX                 ;ins dw direkt vor der main proc
        MOV   CX,DS:[0126H]
        ADD   CX,AX
        MOV   [BX+m2-main],CX
        MOV   CX,DS:[0120H]
        MOV   [BX+m3-main],CX
        MOV   CX,DS:[0124H]
        MOV   [BX+m1-main],CX
        MOV   DI,DS:[0128H]                   ;di auf relocation tabel
        MOV   DX,DS:[0118H]                   ;header größe in paragraphs
        MOV   CL,04H
        SHL   DX,CL                           ;paragraphs in byte wandeln
        MOV   CX,DS:[0116H]                   ;#relocations
        JCXZ  mnloop                          ;falls keine relocations
mloop:  LDS   SI,DWORD PTR ES:[DI+0110H]      ;dword pointer auf eine relocation
        ADD   DI,+04H                         ;auf nächsten eintrag in reloc tab
        MOV   BP,DS
        ADD   BP,ES:[0118H]
        ADD   BP,+01H
        ADD   BP,AX
        MOV   DS,BP
        ADD   [SI],AX                         ;das relocieren
        LOOP  mloop
mnloop: PUSH  CS
        POP   DS                              ;ds := cs
        MOV   DI,0100H                        ;di auf beginn des speichers
        MOV   SI,DX
        ADD   SI,0110H                        ;si auf beginn des exe-programs
        MOV   CX,BX                           ;dort begint exe2bin implantat
        SUB   CX,SI                           ;cx := #bytes im exe-program
        REPZ  MOVSB                           ;programm an anfang des speichers
        POP   AX                              ;drive designations zurück holen
        CLI
        MOV   SS,[BX+m4-main]                 ;stack oberhalb benutzen speicher
        MOV   SP,[BX+m3-main]
        STI
        JMP   DWORD PTR [BX-0BH]              ;der exe-program start
e2b     ENDP

com     ENDS

        END start
