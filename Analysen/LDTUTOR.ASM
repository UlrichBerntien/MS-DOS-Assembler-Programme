        PAGE    60,132
;---------------------------------------------------------------------
; Kommentiertes Assembler-Listing von LdTutor.EXE
; Orginal (c) Wang
; Kommentare (c) Ulrich Berntien .02.1991
;                letzte Änderung .02.1991
;---------------------------------------------------------------------

; ASCII Konstanten

bell    EQU 07H
lf      EQU 0AH
ff      EQU 0CH
cr      EQU 0DH
escape  EQU 1BH

code    SEGMENT WORD 'code'
;---------------------------------------------------------------------
        ASSUME cs : code, ds :data

main    PROC FAR
;---------------------------------------------------------------------
;    Hauptprozedur
;---------------------------------------------------------------------
        MOV     AX,SEG data
        MOV     DS,AX                           ;ds := seg data
        MOV     AX,ES
        MOV     SS,AX
        MOV     SP,0100H                        ;stack in den psh legen
        MOV     AH,0EH                          ;select disk
        MOV     DL,00H                          ;disk drive A <= 00H
        INT     21H
        CALL    tutor_einlegen
        MOV     BX,SEG stack                    ;ende des benutzten speichers
        MOV     AX,ES                           ;segment des psh
        SUB     BX,AX                           ;anzahl benutzte paragraphs
        ADD     BX,+08H
        MOV     AH,4AH                          ;modify allocated block
        INT     21H                             ;  ungenutzter speicher abgeben
        JB      mem_error                       ;falls fehler aufgetreten
        MOV     DI,0080H                        ;es:di auf cmdline länge
        MOV     BYTE PTR ES:[DI],00H            ;länge auf null setzen
        INC     DI                              ;es:di auf cmdline zeichen
        MOV     BYTE PTR ES:[DI],cr             ;nur das abschlußzeichen cr
        MOV     AX,DS
        MOV     WORD PTR [adscmd+1],AX          ;adscmd auf cmdline setzen
        MOV     AX,OFFSET cmdline
        MOV     WORD PTR [adscmd],AX
        MOV     AX,ES                           ;ax := segment des psh
        MOV     WORD PTR [adsfcb1+2],AX         ;adsfcb1 und adsfcb1 auf die
        MOV     WORD PTR [adsfcb2+2],AX         ;  eigenen fcbs setzen
        MOV     DX,OFFSET txt1                  ;ds:dx auf execute-filename
        MOV     BX,OFFSET par_block             ;es:bx auf parameterblock
        PUSH    ES                              ;ds,es sichern
        PUSH    DS
        MOV     CS:[stackm],SS                  ;stack sichern
        MOV     CS:[stackm+2],SP
        PUSH    DS
        POP     ES                              ;es := ds
        MOV     AX,4B00H                        ;execute child program
        INT     21H
        JB      exec_error                      ;falls fehler aufgetreten
        MOV     AX,CS:[stackm]                  ;stack zurückholen
        MOV     SS,AX
        MOV     AX,CS:[stackm+2]
        MOV     SP,AX
        POP     DS                              ;ds,es zurück holen
        POP     ES
        CALL    install_einlegen
        JMP     exit_process

stackm  DW      2 DUP (?)                       ;speicher für ss,sp

main    ENDP

cls     PROC NEAR
;---------------------------------------------------------------------
;    Löscht den Bildschirm
; ARGS: -
; RETS: -
; REGS: außer AH,DL alle erhalten
;---------------------------------------------------------------------
        MOV     AH,02H                          ;sends char to screen
        MOV     DL,ff                           ;clear screen
        INT     21H
        RET
cls     ENDP

mem_error PROC NEAR
;---------------------------------------------------------------------
;    Aufruf falls Speicher für das Ladeprogramm zu klein ist
;    Meldung ausgeben, auf Taste warten, Programm benenden
; ARGS: DS = SEG data erwartet
; RETS: -
; REGS: -
;---------------------------------------------------------------------
        CALL    cls                             ;clear screen
        MOV     DX,OFFSET txt5                  ;ds:dx auf meldung
        CALL    printstring                     ;  nicht genug speicher
        MOV     AX,0C08H                        ;buffer flush
        INT     21H                             ;  & console input without echo
        JMP     exit_process
mem_error ENDP

exec_error PROC NEAR
;---------------------------------------------------------------------
;    Fehlerbehandlung nach DOS-Fehler bei 'execute child program'
;    Fehlermeldung ausgeben, auf Taste warten, Programm beenden
; ARGS: auf dem Stack DS,ES / DS = SEG data erwartet
; RETS: -
; REGS: -
;---------------------------------------------------------------------
        CALL    cls                             ;clear screen
        MOV     DX,OFFSET txt6                  ;ds:dx auf meldung
        CALL    printstring                     ;  kann programm nicht laden
        MOV     AX,0C08H                        ;buffer flush
        INT     21H                             ; & console input without echo

        MOV     AX,CS:[stackm]                  ;stack restaurieren, wozu ?
        MOV     SS,AX
        MOV     AX,CS:[stackm+2]
        MOV     SP,AX
        POP     DS                              ;register vom stack holen
        POP     ES
        JMP     exit_process                    ;programm benenden
exec_error ENDP

printstring PROC NEAR
;---------------------------------------------------------------------
;    Einen String (terminiert mit '$') auf Console ausgeben
; ARGS: DS:DX auf den character string
; RETS: -
; REGS: außer AH alle erhalten
;---------------------------------------------------------------------
        MOV     AH,09H                          ;print a string
        INT     21H
        RET
printstring ENDP

tutor_einlegen PROC NEAR
;---------------------------------------------------------------------
;    Aufforderung die Tutor-Diskette einzulegen
;    Abwarten bis Bestätigung oder Abbruch
;       die Funktionstastencodes werden nicht vollständig ausgewertet
;       das Byte E0 bzw. C5 könnten auch eine normale Taste bedeuten.
;    Überprüfen ob TUTOR.EXE verfügbar ist
;---------------------------------------------------------------------
        CALL    cls
        MOV     DX,OFFSET txt3                  ;ds:dx auf meldung
        CALL    printstring                     ;  tutor disk in 'A' einlegen
        MOV     AX,0C08H                        ;buffer flush
        INT     21H                             ;  & concole input without echo
        JMP     L01C8

L01C4:  MOV     AH,08H                          ;console input without echo
        INT     21H

L01C8:  CMP     AL,1FH                          ;dead key code (function key) ?
        JE      L01C4                           ;  ja, einfach ignorieren
        CMP     AL,0E0H                         ;cancel key (second byte)
        JE      exit_process                    ;bei cancel programm verlassen
        CMP     AL,0C5H                         ;execute key (second byte) ?
        JNE     tutor_einlegen                  ;  nein,aufforderung wiederholen
                                                ;  ja, überprüfen:
        MOV     DX,OFFSET txt1                  ;ds:dx auf file name
        MOV     AX,3D00H                        ;open a file for reading
        INT     21H
        JNB     L01E6                           ;falls kein Fehler aufgetreten
                                                ;  bei fehler:
        MOV     DX,OFFSET txt7                  ;ds:dx auf bell-string
        CALL    printstring
        JMP     tutor_einlegen                  ;aufforderung wiederholen

L01E6:  MOV     BX,AX                           ;file handle in bx
        MOV     AH,3EH                          ;close a file
        INT     21H
        CALL    cls                             ;clear screen
        RET                                     ;zurück, tutor.exe verfügbar
tutor_einlegen ENDP

install_einlegen PROC NEAR
;---------------------------------------------------------------------
;    Aufforderung die Installations-Diskette einzulegen
;    Abwarten bis Bestätigung oder Abbruch
;       die Funktionstastencodes werden nicht vollständig ausgewertet
;       das Byte C5 könnten auch eine normale Taste bedeuten.
;    Überprüfen ob INSTALL.EXE verfügbar ist
;---------------------------------------------------------------------
        CALL    cls
        MOV     DX,OFFSET txt4                  ;ds:dx auf meldung
        CALL    printstring                     ;  installations disk einlegen
        MOV     AX,0C08H                        ;buffer flush
        INT     21H                             ;  & input without echo
        JMP     L0205

L0201:  MOV     AH,08H                          ;console input without echo
        INT     21H

L0205:  CMP     AL,1FH                          ;dead key code (function key) ?
        JE      L0201                           ;  ja, einfach ignorieren
        CMP     AL,0C5H                         ;execute key
        JNE     install_einlegen                ;  nein,aufforderung wiederholen
        MOV     DX,OFFSET txt2                  ;ds:dx to asciz file name
        MOV     AX,3D00H                        ;open file for reading
        INT     21H
        JNB     L021F                           ;falls kein Fehler aufgetreten
                                                ;  bei fehler:
        MOV     DX,OFFSET txt7                  ;ds:dx auf bell-string
        CALL    printstring
        JMP     install_einlegen                ;aufforderung wiederholen

L021F:  MOV     BX,AX                           ;file handle in bx
        MOV     AH,3EH                          ;close a file
        INT     21H
        CALL    cls                             ;clear screen
        RET                                     ;zurück, install.exe verfügbar
install_einlegen ENDP

exit_process PROC NEAR
;---------------------------------------------------------------------
;    Programm beenden
;---------------------------------------------------------------------
        MOV     AH,4CH                          ;exit from a process
        INT     21H
        ;und weiter ?                           ;vertrauen aufs DOS
exit_process ENDP

code    ENDS

;---------------------------------------------------------------------
data    SEGMENT WORD 'data'

txt0    DB      'VERS 1.00'
txt1    DB      'TUTOR.EXE',00H
txt2    DB      'INSTALL.EXE',00H
        DB      00H
txt3    DB      escape,'[1m',escape,'[20;23H'
        DB      'WANG Tutor Disk in Laufw.A einlegen'
        DB      escape,'[22;15H'
        DB      '<AUSF>  Fortfahren     <ANNULLIER>  Zurück zum Menü$'
txt4    DB      escape,'[20;19H',escape,'[1m'
        DB      'Installations-Disk in Laufwerk A einlegen  '
        DB      escape,'[22;30H'
        DB      '<AUSF>  Fortfahren   $'
txt5    DB      escape,'[23;01H'
        DB      'Nicht genug Speicher zum Programmladen',cr,lf
        DB      '<Leer>  Zurück    $'
txt6    DB      escape,'[23;01H'
        DB      'Kann nicht Programm laden',cr,lf
        DB      '<Leer>  Zurück      $'
txt7    DB      bell,'$'

par_block EQU THIS BYTE                 ;parameter block für execute a program'
        DW      0000H                   ;das alte enviroment benutzen
adscmd  DD      00000000H               ;ads der command line
adsfcb1 DD      0000005CH               ;ads des erste fcb's
adsfcb2 DD      0000006CH               ;ads des zweiten fcb's

cmdline DB      00H                     ;länge der command line
        DB      cr                      ;in dem cmdline nur cr zum abschluß

                                ;die aufgerufenen Programme bekommen die FCB's
                                ;dieses Programms und i.a. nicht dazu passende
                                ;leere Kommando-Zeile
data    ENDS

;---------------------------------------------------------------------
stack   SEGMENT STACK WORD
                                        ;kein Stack bei Programmstart !!
stack   ENDS

        END main
