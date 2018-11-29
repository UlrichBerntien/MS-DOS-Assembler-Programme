        PAGE    60,132
;---------------------------------------------------------------------
;       Assmbler Listing von --- PRNMODE.COM ---
;       Kommentare (c) Ulrich Berntien .04.1989
;                      letzte Änderung .04.1989
;---------------------------------------------------------------------
XSEG    SEGMENT
        ASSUME CS:XSEG

DOS     = 21H                                 ;-- dos interrupt function call
N_CHAR  = BYTE PTR 0080H                      ;-- number of chars following
                                              ;-- the command key word
        ORG 0100H
BEGIN:  JMP     START                         ;-- jump to progam start

CODEON  DB    0FCH                            ;-- code für einschalten
CODEOFF DB    0FBH                            ;-- code für ausscahlten
PARA_E  DB    'Parameter is not correct$'
TEXTON  DB    'Transparent mode is on$'
TEXTOFF DB    'Exit from transparent mode$'
DOS_ERR DB    'Function was not completed$'

START:  PUSH  BP                              ;-- backup register
        MOV   BP,SP
        PUSH  AX
        PUSH  BX
        PUSH  CX
        PUSH  DX
        PUSH  DI
        MOV   BH,00H
        MOV   BL,CS:[N_CHAR]                  ;-- number of chars in parameter
        MOV   DI,BX
        CLC
        ADD   DI,OFFSET N_CHAR                ;-- adr of last char of parameter

L_LOOP: CMP   BYTE PTR [DI],'1'               ;-- "1" <=> transparent modus ein
        JE    L_ON
        CMP   BYTE PTR [DI],'0'               ;-- "0" <=> transparent modus aus
        JE    L_OFF
        DEC   DI                              ;-- zum vorherigen zeichen
        CMP   DI,OFFSET N_CHAR +1
        JB    L_EOL                           ;-- kein zeichen mehr da
        JMP   L_LOOP

L_EOL:  MOV   BP,OFFSET PARA_E                ;-- auf fehlermeldungs-text
        JMP   PRINT

L_OFF:  MOV   DX,OFFSET CODEOFF               ;-- dx auf den ausschalt-code
        MOV   BP,OFFSET TEXTOFF               ;-- auf meldungs-text
        JMP   SETMODE

L_ON:   MOV   DX,OFFSET CODEON                ;-- dx auf den einschalt-code
        MOV   BP,OFFSET TEXTON                ;-- auf meldungs-text

SETMODE:MOV   AH,44H                          ;-- i/o control for device.
        MOV   AL,03H                          ;-- write to device control chan.
        MOV   BX,0004H                        ;-- device := standard printer
        MOV   CX,0001H                        ;-- ein byte übertragen
        CLC
        INT   DOS
        JC    DOSERR                          ;-- falls dos einen fehler meldet
        JMP   PRINT

DOSERR: MOV   BP,OFFSET DOS_ERR               ;-- bp auf fehlertext

PRINT:  MOV   AX,0900H                        ;-- print a string
        MOV   DX,BP                           ;-- dx := pointer to text
        INT   DOS

        MOV   AX,0200H                        ;-- good joke !
L_JOKE: DEC   AX
        CMP   AX,0000H
        JE    EXIT
        JMP   L_JOKE

EXIT:   POP   DI                              ;-- restore register
        POP   DX
        POP   CX
        POP   BX
        POP   AX
        POP   BP
        RET   0002H                           ;-- bye, bye

XSEG    ENDS
        END BEGIN
