        PAGE 60,132
        .SALL
;---------------------------------------------------------------------
; Kommentiertes Assembler Listing von COMTOEXE.COM
;       Orginal Copyright (C) 1985 SOFT WAREHOUSE, Inc.
;       im muLisp-86 Paket enthalten
;
; Kommentare (c) Ulrich Berntien .02.1991
;                letzte Änderung .02.1991
;
; DS,CS,ES,SS befinden sich immer auf dem einen "code" Segment.
;---------------------------------------------------------------------
code    SEGMENT
        ASSUME CS :code, DS :code

; Struktur eines FCB's
;---------------------------------------------------------------------
fcb     STRUC
  drive  DB ?              ;drive indicator 0 = default, 1 = Drive A, ..
  name   DB 8 DUP (?)      ;file name; left justified with trailing spaces
  ext    DB 3 DUP (?)      ;extension to file name
  block  DW ?              ;current block
  rcsize DW ?              ;record size (in bytes)
  fsize  DD ?              ;current record size in bytes
  fdate  DW ?              ;date of creation or last write
  ftime  DW ?              ;time of creation or last write
  flags  DB ?
         DW ?              ;disk address of the first alloc. unit of the file
         DW ?              ;disk address of the last alloc. unit of the file
         DB 3 DUP (?)      ;disk adresses
  nextr  DB ?              ;next record, used by sequential read/write
  rcnum  DD ?              ;random record, used by random read/write
fcb     ENDS

cr      EQU 0DH            ;ascii konstanten
lf      EQU 0AH
space   EQU 20H

        ORG 005CH          ;hier beginnt der erste fcb im psh
fcb1    fcb <>
        ORG 006CH
fcb2    fcb <>             ;hier beginnt der zweite fcb im psh

        ORG 0100H          ;hier beginnt der programm-code

start   PROC NEAR
;---------------------------------------------------------------------
;    Programmstart, falls kein Parameter beim Aufruf angegeben, dann
;    wird die Beschreibung des Programms auf die Console ausgegeben
;---------------------------------------------------------------------
        MOV     SP,0100H                        ;stack einrichten
        CALL    printafter
        DB      'COM File to EXE File Conversion Utility (04/01/85)'
        DB      cr,lf,00H

        CALL    printafter
        DB      'Copyright (C) 1985 SOFT WAREHOUSE, Inc.',cr,lf,lf,00H

        CMP     [fcb1.drive],20                 ;drive = space ?
        JE      print                           ;  ja,nur beschreibung ausgegben
        JMP     opencom                         ;  nein, normale arbeit

print:  CALL    printafter
        DB      'To use this utility, you must include the name of the COM file'
        DB      cr,lf,'in the COMTOEXE command.  The destination drive is '
        DB      'an optional',cr,lf,'second argument.  '
        DB      'For example, to generate the file EXPERT.EXE',cr,lf
        DB      'on drive B: from the file EXPERT.COM, enter the '
        DB      'MS-DOS command:',cr,lf,lf
        DB      '      COMTOEXE EXPERT B:',cr,lf,lf
        DB      'Please try again; returning to DOS',cr,lf,00H
        JMP     errtermit                       ;programm beneden
start ENDP

opencom PROC NEAR
;---------------------------------------------------------------------
;    Öffnet das -.COM File, gibt ggf. eine Fehlermeldung aus
;---------------------------------------------------------------------
        MOV     AL,[fcb2.drive]
        MOV     [fcbexe.drive],AL
        CMP     [fcb1.ext],space                ;ist filename ext. ausgefüllt?
        JNE     extis                           ;  ja
        MOV     [fcb1.ext],'C'                  ;  nein, dann mit 'COM'
        MOV     [fcb1.ext+1],'O'
        MOV     [fcb1.ext+2],'M'
extis:  MOV     DX,OFFSET fcb1                  ;ds:dx auf fcb1
        MOV     AH,0FH                          ;open a file
        INT     21H
        CMP     AL,0FFH                         ;file not found ?
        JNE     createexe                       ;  nein, normal weiter

        CALL    printafter                      ;  ja,fehlermeldung ausgeben
        DB      'COM file not found; returning to DOS',cr,lf,00H
        JMP     errtermit                       ;programm benenden
opencom ENDP

createexe PROC NEAR
;---------------------------------------------------------------------
;    Erstellt das -.EXE File, gibt ggf. eine Fehlmeldung aus
;---------------------------------------------------------------------
        MOV     AX,WORD PTR [fcb1.fsize]
        MOV     CX,WORD PTR [fcb1.fsize+2]      ;cx:ax = dateilänge
        ADD     AX,01FFH
        ADC     CX,+00H                         ;cx:ax = länge der -.exe datei
        REPT 9
          SHR     CX,1
          RCR     AX,1
        ENDM                                    ;cx:ax div 512
        INC     AX
        MOV     [lenhigh],AX
        MOV     [fcb1.rcsize],0001H             ;record = byte
        MOV     WORD PTR [fcb1.rcnum],0000H     ;ganz vorne anfangen
        MOV     WORD PTR [fcb1.rcnum+2],0000H
          plus = 0                              ;file name kopieren
        REPT 4
          MOV     AX,WORD PTR [fcb1.name +plus]
          MOV     WORD PTR [fcbexe.name +plus],AX
          plus = plus + 2
        ENDM
        MOV     DX,OFFSET fcbexe                ;ds:dx auf fcb
        MOV     AH,16H                          ;create a file
        INT     21H

        CMP     AL,0FFH                         ;directory full ?
        JNE     writehead                       ;  nein, normal weiter
        CALL    printafter                      ;  ja, fehlermeldung ausgeben
        DB      'Disk directory full; returning to DOS',cr,lf,00H
        JMP     errtermit                       ;programm benenden
createexe ENDP

writehead PROC NEAR
;---------------------------------------------------------------------
;    Öffnet die -.EXE Datei und schreibt den vergeschribenen Kopf
;    in einer promitiven Form, passend um den Code/Daten aus dem
;    -.COM File direkt anzuhängen
;---------------------------------------------------------------------
        MOV     [fcbexe.rcsize],0001H           ;record = byte
        MOV     WORD PTR [fcbexe.rcnum],0000H   ;ganz vorne anfangen
        MOV     WORD PTR [fcbexe.rcnum+2],0000H
        MOV     DX,OFFSET headexe               ;ds:dx auf neue dta
        MOV     AH,1AH                          ;set disk transfer address
        INT     21H
        MOV     CX,0200H                        ;200H bytes kopf schreiben
        MOV     DX,OFFSET fcbexe                ;ds:dx auf opend fcb
        MOV     AH,28H                          ;random block write
        INT     21H
        TEST    AL,AL                           ;schreiben erfolgreich ?
        JNZ     workerr                         ;  nein, fehlerbehandlung
writehead ENDP

copy    PROC NEAR
;---------------------------------------------------------------------
;    Kopiert den Code/Daten aus dem -.COM File in das -.EXE File.
;    Erwartet dabei, daß der frei Speicher im Segment mindestens
;    F000 Bytes lang ist.
;---------------------------------------------------------------------
;;; diser Teil rausnehmen, headexe wird einfach überschrieben
;;;     MOV     DX,OFFSET buffer                ;ds:dx auf neue dta
;;;     MOV     AH,1AH                          ;set disk tranfer address
;;;     INT     21H
copyloop:
        MOV     CX,0F000H                       ;record count
        MOV     DX,OFFSET fcb1                  ;ds:dx auf opend fcb
        MOV     AH,27H                          ;random block read
        INT     21H
        JCXZ    endnormal                       ;falls nichts gelesen wurde
        MOV     DX,OFFSET fcbexe                ;ds:dx auf opend fcb
        MOV     AH,28H                          ;random block write
        INT     21H
        TEST    AL,AL                           ;schreiben erfolgreich ?
        JZ      copyloop                        ;  ja
                                                ;  nein, dann fehlermeldung
copy    ENDP

workerr PROC NEAR
;---------------------------------------------------------------------
;   Löscht (bzw. schließt zuerst) das -.EXE File und benenden
;   dann das Programm nach einer Fehlermeldung
;---------------------------------------------------------------------
        MOV     DX,OFFSET fcbexe                ;ds:dx auf opend fcb
        MOV     AH,10H                          ;close file
        INT     21H
        MOV     DX,OFFSET fcbexe                ;ds:dx auf einen unopend fcb
        MOV     AH,13H                          ;delete file
        INT     21H
        CALL    printafter                      ;fehlermeldugn ausgeben
        DB      'Insufficient disk space for EXE file; returning to DOS'
        DB      cr,lf,00H
        JMP     errtermit                       ;programm beenden
workerr ENDP

endnormal PROC NEAR
;---------------------------------------------------------------------
;   Schließt das -.EXE File und beendet das Programm mit einer
;   Erfolgsmeldung.
;---------------------------------------------------------------------
        MOV     DX,OFFSET fcbexe                ;ds:dx auf opend fcb
        MOV     AH,10H                          ;close file
        INT     21H
        CALL    printafter                      ;meldung ausgeben
        DB      'Conversion complete; EXE file saved; returning to DOS'
        DB      cr,lf,00H
        MOV     AL,00H                          ;return code = 00
        JMP     termit                          ;programm benenden
endnormal ENDP

errtermit PROC NEAR
;---------------------------------------------------------------------
;    Einen BEEP ausgeben und dann Programm benenden
;---------------------------------------------------------------------
        MOV     AL,07H                          ;sound a beep
        CALL    alout
        MOV     AL,01H                          ;return code = 01
errtermit ENDP

termit PROC NEAR
;---------------------------------------------------------------------
;    Programm beenden
; ARGS: AL mit dem Return-Code
; RETS: -
; REGS: -
;---------------------------------------------------------------------
        MOV     AH,4CH                          ;exit form a process
        INT     21H
        INT     20H                             ;program terminate
termit  ENDP

outcrlf PROC NEAR
;---------------------------------------------------------------------
;    Ausgeben von CR & LF  // wird in diesem Programm nicht benutzt
; ARGS: -
; RETS: -
; REGS: alle erhalten
;---------------------------------------------------------------------
        MOV     AL,cr                           ;cr ausgeben
        CALL    alout
        MOV     AL,lf                           ;lf ausgeben
        JMP     alout                           ;alout ist auch near proc
outcrlf ENDP

printafter PROC NEAR
;---------------------------------------------------------------------
; ARGS: auf dem Stack Adresse eines ASCIZ-Strings
; RETS: Springt den Code hinter dem String an
; REGS: alle erhalten
;    Anwendungsbeispiel:
;       CALL printafter
;       DB 'diesen text ausgeben,',00H
;       <hier geht das programm weiter>
;---------------------------------------------------------------------
        MOV     [savbx],BX                      ;register sichern
        POP     BX                              ;adr des strings vom stack
        PUSH    AX
        CALL    printout                        ;text ausgeben
        POP     AX
        PUSH    BX                              ;rücksprung hinter den string
        MOV     BX,[savbx]
        RET
printafter ENDP

outloop:
        CALL    alout

printout PROC NEAR
;---------------------------------------------------------------------
;    Einen ASCIZ String auf Console ausgeben
; ARGS: DS:BX auf den ASCIZ String
; RETS: DS:BX auf das abschließende 00
; REGS: außer AX,BX alle erhalten
;---------------------------------------------------------------------
        MOV     AL,[BX]
        INC     BX
        AND     AL,AL
        JNZ     outloop                         ;solange bis al = 0
        RET
printout ENDP

;---------------------------------------------------------------------
;    // Warten auf Tastendruck ? nicht benutzt, nicht zu Ende programmiert
waitkeyrest:
        CALL    getchar
        JE      waitkeyrest
        RET

getchar PROC NEAR
;---------------------------------------------------------------------
;    Holt Zeichen von Console, wartet nicht auf Tastendruck
;    // wrid in diesem Programm nicht benutzt
; ARGS: -
; RETS: AL Byte von Tastatur, falls keine Taste im Buffer 00H
; REGS: nur AX verändert
;---------------------------------------------------------------------
        PUSH    DX                              ;register sichern
        MOV     DL,0FFH                         ;-> keyboard input character
        MOV     AH,06H                          ;direct console i/o
        INT     21H
        POP     DX                              ;register zurück
        RET
getchar ENDP

alout   PROC NEAR
;---------------------------------------------------------------------
;    Ein Zeichen auf die Console ausgeben
; ARGS: AL mit dem Zeichen
; RETS: -
; REGS: alle erhalten
;---------------------------------------------------------------------
        PUSH    AX
        PUSH    DX                              ;register sichern
        MOV     DL,AL
        MOV     AH,02H                          ;screen output
        INT     21H
        POP     DX
        POP     AX
        RET
alout   ENDP

;---------------------------------------------------------------------
;    D A T E N
;---------------------------------------------------------------------

savbx   DW      ?               ;sichern vom bx innerhalb von printafter

fcbexe EQU THIS BYTE            ;fcb für das -.EXE file
        DB 00H                  ;drive
        DB 8 DUP (space)        ;name
        DB 'EXE'                ;ext

        DB (SIZE fcb + fcbexe - $) DUP (?) ;speicher für den fcb belegen

headexe EQU THIS BYTE           ;kopf eines exe-file
        DB 'MZ'                 ;signature
        DW 0                    ;# bytes contained in the last page
                                ;  low 9 bits of length
lenhigh DW ?                    ;# 512-byte pages in the file including header
        DW 0                    ;# entries in the relocation table
        DW 0020H                ;# 16-byte paragraphes in the header
        DW 0200H                ;minimum # paragraphs required above the end
                                ;  of loaded program
        DW 8000H                ;maximum # paragraphs required above the end
                                ;  of loaded program
        DW 0FFF0H               ;initial value to be loaded into ss
        DW 0100H                ;initial value to be loaded into sp
                                ;  ss:sp wird auf obergrenze des psh gesetzt
        DW 0000H                ;negative sum of all the words in the run file
                                ;  presently ignored
        DW 0100H                ;initial offset to be loaded into ip
        DW 0FFF0H               ;initial value to be loaded into cs
                                ;  mit diesem wert wird ss = SEG psh
                                ;  wie für -.com programme vorgegeben
        DW 0000H                ;relative byte offset of the relocation table
        DW 0000H                ;number of the overlay

        DB (0200H+headexe-$) DUP(0) ;header hat 0200H byte länge

buffer  EQU THIS BYTE           ;ab hier speicher frei
                                ;  Stack liegt ganz klein ab 0100 abwärts
                                ;  und darf nicht in den fcb1 (007D) schreiben
code    ENDS

        END start
