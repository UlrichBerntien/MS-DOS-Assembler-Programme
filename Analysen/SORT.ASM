        PAGE    60,132
        .SALL
;---------------------------------------------------------------------
; Kommentiertes Assmebler Listing von SORT.EXE
; Orginal (c) Wang
; Kommentare (c) Ulrich Berntien .02.1991
;                letzte Änderung .02.1991
;---------------------------------------------------------------------

code    SEGMENT WORD
        ASSUME cs : code, ds : code, ss : stack

exitadr DW      0000H                         ;exit adresse im psh
swchar  DB      '/'                           ;switch character

;---------------------------------------------------------------------
;    Hauptprozedur
;---------------------------------------------------------------------
main    PROC FAR
        MOV     AH,30H                        ;get dos version number
        INT     21H
        XCHG    AH,AL                         ;version in ah, revision in al
        CMP     AX,0200H
        JNB     start                         ;läuft ab dos version 2.00
        MOV     DX,OFFSET txtver              ;ds:dx auf fehlermeldung
        PUSH    CS
        POP     DS                            ;ds := seg code
        MOV     AH,09H                        ;print a string
        INT     21H

L0117:  PUSH    ES                            ;segment des psh auf den stack
        PUSH    CS:[exitadr]                  ;psh:0000 anspringen = int 20H
        RET                                   ;programm beenden

main    ENDP

start:  MOV     AL,00H                        ;get switch character
        MOV     AH,37H                        ;get incompatible config parameter
        INT     21H
        MOV     CS:[swchar],DL                ;switch char abspeichern
        MOV     SI,0080H                      ;auf anfang der command line (len)
        CLD                                   ;richtung aufwärts
        XOR     CX,CX                         ;cx := 0
        LODSB                                 ;al := längen byte der cmdline
        MOV     CL,AL                         ;cx := länge der command line
L0132:  CALL    L0177                         ;zeichen aus cmdline lesen
        CMP     AL,CS:[swchar]                ;al = switch character ?
        JNE     L0132                         ;  nein, einfach ignorieren
        CALL    L0177                         ;  ja, nächstes zeichen lesen
        CMP     AL,'+'
        JE      L0152
        OR      AL,20H                        ;in kleinbuchstaben wandeln
        CMP     AL,'r'
        JNE     L0132
        MOV     BYTE PTR CS:[L02A2],72H       ;JNB zu einem JB machen
        NOP
        JMP     L0132                         ;schleife über cmdline

L0152:  MOV     WORD PTR CS:[0000H],0000H
L0159:  CALL    L0177                         ;zeichen aus cmdline lesen
        SUB     AL,'0'                        ;ascii ziffer in wert wandeln
        JB      L0132                         ;keine ziffer
        CMP     AL,09H
        JNBE    L0132                         ;keine ziffer
        CBW                                   ;ax := al, vorzeichen richtig
        MOV     BX,AX                         ;letzte ziffer in bx merken
        MOV     AX,10                         ;die basis ist 10
        MUL     WORD PTR CS:[0000H]           ;alte stellen schieben
        ADD     AX,BX                         ;und neue stelle addieren
        MOV     WORD PTR CS:[0000H],AX        ;zwischen speichern
        JMP     L0159                         ;schleife über alle ziffern

L0177:  JCXZ    L017C                         ;falls cmdline abgearbeitet
        DEC     CX                            ;zeichen weiterzählen
        LODSB                                 ;aus cmdline lesen
        RET

L017C:  POP     AX                            ;stack säubern
        ADD     WORD PTR CS:[0000H],+02H
        CMP     WORD PTR CS:[0000H],+02H
        JE      L0190
        DEC     WORD PTR CS:[0000H]
L0190:  MOV     BX,1000H                      ;1000H paragraphs memory anfordern
L0193:  MOV     AH,48H                        ;allocate memory
        INT     21H
        JNB     L01A0                         ;alles in ordnung
        OR      BX,BX                         ;kein speicher verfügbar ?
        JNE     L0193                         ;  ja, fehlermeldung
        JMP     L01CE                         ;  nein, dann nehme was möglich

L01A0:  MOV     DS,AX                         ;ds,es auf das neue segment
        MOV     ES,AX
        MOV     CL,04H                        ;größe von para. in bytes wandlen
        SHL     BX,CL                         ;bx := bx * 16
        MOV     CX,0080H
        MOV     AX,2020H
        MOV     DI,0000H
        REPZ    STOSW
        MOV     DX,0102H
        MOV     CX,BX
        SUB     CX,0102H
L01BC:  XOR     BX,BX                         ;standart input device
        MOV     AH,3FH                        ;read a file
        INT     21H

L01C2:  ADD     DX,AX
        SUB     CX,AX
        JE      L01CE                         ;date größer als speicherplatz
        OR      AX,AX
        JNE     L01BC
        JMP     SHORT L01E5

L01CE:  MOV     SI,OFFSET txtmem              ;ds:si auf fehlermeldung

errormes PROC NEAR
;---------------------------------------------------------------------
;    Fehlermeldung ausgeben / Programm beenden
; ARGS: code:SI auf Fehlermeldung
;       erstes Word der Meldung ist die Länge in Bytes
;       dann folgt der Fehlertext
; RETS: -
; REGS: -
;---------------------------------------------------------------------
        PUSH    CS                            ;   speicherplatz fehlt
        POP     DS                            ;ds := seg code
        LODSW                                 ;länge der fehlermeldung lesen
        MOV     CX,AX                         ;anzahl der bytes in cx
        MOV     DX,SI                         ;ds:dx auf den eigentlichen text
        MOV     BX,0002H                      ;auf standart error message device
        MOV     AH,40H                        ;write a file
        INT     21H                           ;  fehlermeldung ausgeben
        MOV     AL,01H                        ;return code 01
        MOV     AH,4CH                        ;exit form a process
        INT     21H                           ;  programm benenden
errormes ENDP

L01E5:  MOV     BX,DX
        MOV     CX,DX
        SUB     CX,0102H
        MOV     AL,1AH
        MOV     DI,0102H
        REPNZ   SCASB
        JNE     L01F7
        DEC     BX
L01F7:  SUB     BX,CX
        SUB     BX,+02H
        CMP     WORD PTR [BX],0A0DH
        JE      L020A
        ADD     BX,+02H
        CMP     [BX],AL
        JE      L020A
        INC     BX
L020A:  MOV     BP,BX
        MOV     WORD PTR DS:[BP+00H],0000H
        MOV     BX,0100H
        MOV     DI,0102H
L0218:  MOV     AL,0DH
        MOV     CX,BP
        SUB     CX,DI
        INC     CX
L021F:  REPNZ   SCASB
        JNE     L0228
        CMP     BYTE PTR [DI],0AH
        JNE     L021F
L0228:  MOV     AX,DI
        DEC     AX
        PUSH    AX
        SUB     AX,BX
        MOV     [BX],AX
        POP     BX
        INC     DI
        JCXZ    L0236
        JMP     L0218
L0236:  MOV     WORD PTR [BX],0000H
        LEA     BP,[BX+02H]
        MOV     DI,0100H
L0240:  MOV     BX,DI
        MOV     SI,BX
        CMP     WORD PTR [BX],+00H
        JNE     L024C
        JMP     L02E9

L024C:  ADD     SI,[SI]
        MOV     AX,[SI]
        OR      AX,AX
        JE      L02A8
        PUSH    SI
        PUSH    DI
        MOV     DI,BX
        SUB     AX,CS:[0000H]
        JNBE    L0265
        MOV     SI,0000H
        MOV     AX,0100H
L0265:  MOV     DX,[DI]
        SUB     DX,CS:[0000H]
        JNBE    L0274
        MOV     DI,0000H
        MOV     DX,0100H
L0274:  MOV     CX,AX
        CMP     AX,DX
        JB      L027C
        MOV     CX,DX
L027C:  ADD     DI,CS:[0000H]
        ADD     SI,CS:[0000H]
        PUSH    BX
        PUSH    AX
        MOV     BX,OFFSET table
L028B:  LODSB
        XLAT    CS:BYTE PTR $
        MOV     AH,AL
        MOV     AL,ES:[DI]
        INC     DI
        XLAT    CS:BYTE PTR $
        CMP     AH,AL
        LOOPZ   L028B
        POP     AX
        POP     BX
        POP     DI
        POP     SI
        JNE     L02A2
        CMP     AX,DX
L02A2:  JNB     L024C
        MOV     BX,SI
        JMP     L024C
L02A8:  MOV     SI,BX
        CMP     SI,DI
        JE      L02E4
        MOV     DX,[SI]
        PUSH    SI
        PUSH    DI
        STD
        MOV     CX,BP
        SUB     CX,DI
        MOV     SI,BP
        DEC     SI
        MOV     DI,SI
        ADD     DI,DX
        REPZ    MOVSB
        CLD
        POP     DI
        POP     SI
        PUSH    DI
        ADD     SI,DX
        PUSH    SI
        MOV     CX,DX
        REPZ    MOVSB
        POP     SI
        POP     DI
        PUSH    DI
        MOV     CX,BP
        ADD     CX,DX
        SUB     CX,SI
        INC     CX
        SHR     CX,1
        MOV     DI,SI
        ADD     SI,DX
        REPZ    MOVSW
        POP     DI
        MOV     WORD PTR DS:[BP-02H],0000H
L02E4:  ADD     DI,[DI]
        JMP     L0240

L02E9:  MOV     DI,0100H
        MOV     CX,[DI]
L02EE:  ADD     DI,CX
        MOV     CX,[DI]
        MOV     WORD PTR [DI],0A0DH
        CMP     CX,+00H
        JNE     L02EE
        MOV     DX,0102H
        MOV     CX,BP
        SUB     CX,DX
        MOV     BX,0001H                      ;standart output device
        MOV     AH,40H                        ;write a file
        INT     21H
        JB      L030F                         ;falls fehler aufgetreten
        CMP     AX,CX                         ;alle bytes geschrieben ?
        JE      L0315                         ;  ja

L030F:  MOV     SI,OFFSET txtdisk
        JMP     errormes

L0315:  XOR     AL,AL                         ;al := 0, return code
        MOV     AH,4CH                        ;exit form a process
        INT     21H                           ;dos call

;---------------------------------------------------------------------
; D a t e n t e i l
;---------------------------------------------------------------------

txtver  DB      'SORT: Incorrect DOS version',0DH,0AH,'$'

txtmem  DW      txtmem_len
        DB      'SORT: Insufficient memory',0DH,0AH
  txtmem_len EQU $ - txtmem - 2

txtdisk DW      txtdisk_len
        DB      'SORT: Insufficient disk space',0DH,0AH
  txtdisk_len EQU $ - txtdisk - 2

; Das Macro erzeugt die Bytes  von,von+1,von+2,...,bis
;---------------------------------------------------------------------
fill    MACRO von,bis
        LOCAL count
  count EQU von
        REPT bis - von + 1
          DB count
          count = count + 1
        ENDM
        ENDM

table EQU THIS BYTE
        fill 000H, 060H
        fill 041H, 05AH
        fill 07BH, 0FFH

        DB      0E9H DUP(00H)

code    ENDS

;---------------------------------------------------------------------
stack   SEGMENT WORD STACK
        DB 00E0H DUP (?)
stack   ENDS

        END main
