        PAGE    60,132
;---------------------------------------------------------------------
; Kommentiertes Assembler Listing von RDIR.EXE
; Orginal (c) Wang
; Kommentare (c) Ulrich Berntien .02.1991
;                letzte Änderung .02.1991
; Lit + MC April 1990, Seiten 134 ff.
;       Peter Göretz : DOS-Speicher offengelegt
;     + MC November 1989, Seiten 68 ff.
;       Hans-Georg Joepgen : Viren, Minen und Trojaner
;---------------------------------------------------------------------
; nicht dokumentierte DOS-Funktionen üner INT 21H
; AH = 52H : liefert Zeiger ES:BX aus den DSO Informations Block
;
; AH = 50H : BX = Segment eines Programm Codes
;                 z.B. dem Segment des Parent Programms
;            Files dir geöffnet/geschlossen werden, werden ab jetzt
;            dem Programm mit dem übergeben Segment zugeordnet
;---------------------------------------------------------------------

false   EQU 000H                        ;konstanten
true    EQU 0FFH
space   EQU 020H                        ;ascii konstanten

code    SEGMENT PUBLIC WORD 'code'
code    ENDS

;---------------------------------------------------------------------
data    SEGMENT PUBLIC WORD 'data'

segpsh  DW      ?                             ;segment des psh hier sichern
rdthis  DB      ?                             ;diesen handle umleiten

txtdev  DB      '/DEV/'
txtdevlen EQU $ - txtdev

buffer  DB      80 DUP(?)

txts    DB      'INP','OUT','ERR','AUX'       ;liste der gültigen device namen
devcount EQU 5                                ;  anzahl der namen
devlen   EQU 3                                ;  länge der namen

txtprn  DB      'PRN'                         ;dieser gehört auch noch zu liste
txtprnlen EQU $ - txtprn                      ;wird aber auch getrennt benötigt

pflag   DB      false                         ;merker ob p-switch gefunden

txt1    DB      0DH,0AH,'Invalid device or file name specified',0DH,0AH,'$'
txt2    DB      0DH,0AH,'Redirection complete',0DH,0AH,'$'
txt3    DB      0DH,0AH,'Invalid parameters, redirection not possible'
        DB      0DH,0AH,'$'

data    ENDS

;---------------------------------------------------------------------
code    SEGMENT PUBLIC WORD 'code'

        ASSUME cs : code, ds :data

main    PROC FAR
;---------------------------------------------------------------------
;    Hauptprozedur
;---------------------------------------------------------------------
        CLD                                   ;feld immer aufwärts abarbeiten
        MOV     AX,SEG data
        MOV     DS,AX                         ;ds auf data segment
        MOV     [segpsh],ES                   ;segment des psh sichern
        MOV     BX,ES:[000CH]                 ;bx := seg des aufrufenden
        MOV     AH,50H                        ;      programms
        INT     21H

        PUSH    ES
        POP     DS                            ;ds := segment des psh
        MOV     AX,SEG data
        MOV     ES,AX                         ;es auf segment data
        MOV     AX,3700H                      ;get dos switch character
        INT     21H
        MOV     AL,DL                         ;switch char in AL merken
        XOR     CX,CX
        MOV     CL,DS:[0080H]                 ;cx := #zeichen in der cmdline
        OR      CX,CX                         ;zeile leer ?
        JE      L0196                         ;  ja,
        PUSH    CX                            ;zeilenlänge sichern
        MOV     DI,0081H
L012F:  CMP     AL,[DI]                       ;suche switch character
        JE      switch                        ;falls switch gefunden
        INC     DI                            ;auf nächstes zeichen
        LOOP    L012F                         ;schleife über die zeile
        POP     CX                            ;zeilenlänge zurück
        JMP     L015D
                                              ;einen switch gefunden:
switch: POP     CX                            ;zeilenlänge zurück
        INC     DI                            ;ds:di auf eigentlichen switch
        MOV     AL,[DI]                       ;switch lesen
        AND     AL,0DFH                       ;in großbuchtaben wandeln
        CMP     AL,'P'                        ;ist es p-switch ?
        JNE     L015D                         ;  nein
        MOV     ES:[pflag],true               ;  ja, dann merken
        CALL    searchprn                     ;sucht nach dem prn device
        OR      AX,AX                         ;prn gefunden ?
        JZ      L0154                         ;  ja, dann den prn umleiten
        JMP     fertig                        ;  nein, programm sofort benenden

L0154:  MOV     ES:[rdthis],04H               ;prn soll umgeleitet werden
        JMP     mrdir                         ;mit der umleitung beginnen

L015D:  MOV     SI,0081H                      ;ds:si auf anfang der cmdline
        CLD                                   ;feld immer aufwärts abarbeiten
L0161:  LODSB                                 ;zeichen aus cmdline lesen
        CMP     AL,space                      ;ein füllzeichen ?
        JA      L016B                         ;  nein, auswerten
        LOOP    L0161                         ;schleife über die ganze cmdline
        JMP     L0196                         ;keinen parmeter gefunden

L016B:  CMP     AL,'0'                        ;ist es ein Device handle ?
        JB      L0196                         ;  nein, fehlermeldung
        CMP     AL,'4'
        JBE     L017F                         ;  ja, die ziffer auswerten
        CMP     CX,05
        JB      L0196                         ;  fehlermeldung
        CALL    gethandle
        CMP     AL,0FFH                       ;war der name gültig ?
        JE      L0196                         ;  nein, fehlermeldung
L017F:  AND     AL,07H                        ;dezimal ziffer in wert wandeln
        MOV     ES:[rdthis],AL                ;dises soll umgeleitet werden
        LODSB                                 ;char hinter namen lesen
        CMP     AL,space                      ;ein füllzeichen ?
        JNBE    L0196                         ;  nein, fehlermeldung
        LOOP    L018F
        JMP     L0196                         ;fehlermeldung, nur ein parameter

L018F:  LODSB                                 ;zeichen aus cmdline lesen
        CMP     AL,space                      ;ein füllzeichen
        JNB     L019D                         ;  nein
        LOOP    L018F                         ;  ja, dann weitersuchen
                                              ;falls parameter falsch sind:
L0196:  LEA     DX,txt1                       ;dx auf fehlermeldung
        JMP     SHORT fertig
                                              ;filename aus cmdline lesen
L019D:  LEA     DI,buffer                     ;es:di auf den buffer
        DEC     SI                            ;ds:si auf anfang zweiter param.
L01A2:  LODSB                                 ;zeichen aus cmdline lesen
        CMP     AL,space                      ;ein füllzeichen ?
        JBE     mrdir                         ;  ja, d.h. ende des filenamens
        STOSB                                 ;char in den buffer übertragen
        LOOP    L01A2                         ;schleife solange cmdline

;    In dem [buffer] steht nun der Name des Files/Device in den der
;    File-handle in [rdthis] umgeleitet werden soll.

mrdir:  PUSH    ES
        POP     DS                            ;ds := seg data
        MOV     AX,3C00H                      ;create a file
        LEA     DX,buffer
        XOR     CX,CX                         ;cx := 0, no file protection
        INT     21H
        LEA     DX,txt1                       ;dx auf fehlermeldung
        JB      fertig                        ;falls dos-fehler aufgetreten

        MOV     BX,AX                         ;file handle in bx, old handle
        XOR     CX,CX                         ;cx := 0, the new handle
        MOV     CL,[rdthis]
        MOV     AH,46H                        ;force a dupl. of a file handle
        INT     21H

L01C9:  LEA     DX,txt2                       ;dx auf erfolgsmeldung

fertig: PUSH    ES
        POP     DS                            ;ds := SEG data
        MOV     BX,[segpsh]                   ;bx := segment des psh
        MOV     AH,50H
        INT     21H
        CMP     [pflag],false                 ;ausgabe verhindert ?
        JNE     exit                          ;  ja, dann fertig
        MOV     AH,09H                        ;print a string (<- ds:dx)
        INT     21H
exit:   MOV     AX,4C00H                      ;exit form process
        INT     21H
main    ENDP

gethandle PROC NEAR
;---------------------------------------------------------------------
;    Gibt ein Device Handle zu einem Device Namen,
;    der Name kann gemischt Groß-/Kleinbuchstaben erhalten
;    gibt Fehlercode 0FFH zurück falls Device Name falsch ist.
; ARGS: DS:SI auf device namen mit space abgeschlossen
; RETS: AL = handle des device
;       oder AL = 0FFH, falls device name nicht erkannt
; REGS: Segmente, CX,DX,BP erhalten
;---------------------------------------------------------------------
        PUSH    CX                            ;register sichern
        DEC     SI                            ;ds:si vor den namen
        MOV     BX,SI                         ;in bx den pointer merken
        LEA     DX,txts                       ;liste der device names
        MOV     CX,devcount                   ;fünf devices in der liste

L01F2:  MOV     SI,BX                         ;si auf zeichen vor den namen
        PUSH    CX                            ;position in der liste merken
        MOV     CX,devlen                     ;devicename drei zeichen lang
        MOV     DI,DX                         ;di auf den namen in der liste
        ADD     DX,CX                         ;dx auf nächsten namen in liste

L01FC:  LODSB                                 ;char aus name lesen
        AND     AL,0DFH                       ;in großbuchstaben wandlen
        SCASB                                 ;mit char aus liste vergleichen
        LOOPZ   L01FC                         ;schleife über einen dev.namen

        POP     CX                            ;position in der liste zurück
        JE      L020C                         ;falls namen übereinstimmen
        LOOP    L01F2                         ;schleife über alle dev.namen

        MOV     AL,0FFH                       ;namen nicht erkannt
        JMP     L0212                         ;zum ende der proc

L020C:  MOV     AL,devcount                   ;anzahl der dev. in der liste
        SUB     AL,CL                         ;al := nummer des devices
        JMP     SHORT L0212                   ;zum ende der proc

L0212:  POP     CX                            ;register zurück
        RET
gethandle ENDP

searchprn PROC NEAR
;---------------------------------------------------------------------
;    Such die Liste des Device Driver ab, ob das RPN device driver
;    existiert, falls ja, dann in den buffer '/DEV/PRN     ' schreiben
; ARGS: -
; RETS: AX = 0000H falls prn device driver existiert
;       AX > 0000H falls prn device driver nicht existiert
; REGS: Segmentregister, DX, BP erhalten
;---------------------------------------------------------------------
        PUSH    DS
        PUSH    ES                            ;segment-register sichern
        MOV     AX,SEG data
        MOV     DS,AX                         ;ds := seg data
        MOV     AH,52H                        ;get dos information block
        INT     21H                           ;  es:bx auf den info.block

        LES     BX,DWORD PTR ES:[BX+17H]      ;es:bx auf ersten device driver

L0223:  TEST    WORD PTR ES:[BX+04H],8000H    ;character device ?
        JZ      L0232                         ;  nein
        CALL    chkprn                        ;  ja, ist es prn device ?
        OR      AX,AX
        JZ      L023D                         ;  ja, prn device gefunden
L0232:  CMP     WORD PTR ES:[BX],-01H         ;letzes device in der liste
        JE      L023D                         ;  ja, dann proc beenden
        LES     BX,DWORD PTR ES:[BX]          ;zum nächsten device driver
        JMP     L0223                         ;schleife über alle drivers

L023D:  POP     ES                            ;segment-register zurück
        POP     DS
        RET
searchprn ENDP

chkprn  PROC NEAR
;---------------------------------------------------------------------
;   Prüft ob der DDH den Namen 'PRN' trägt ;
;   wenn ja, dann schreibt in den buffer '/DEV/PRN     '
; ARGS: ES:BX auf einen Device Driver Header
;       DS = SEG data
; RETS: AX = 0000H falls prn gefunden
;       AX > 0000H falls prn nicht gefunden
; REGS: Segmentregister, DX, BP erhalten
;---------------------------------------------------------------------
        MOV     CX,txtprnlen                  ;länge des namens string
        MOV     DI,BX                         ;es:di auf den device driver
        ADD     DI,+0AH                       ;es:di auf den namen des drivers
        LEA     SI,txtprn                     ;ds:si auf 'prn'
        REPZ    CMPSB
        JNE     noprn                         ;falls name nicht übereinstimmt
        MOV     AX,space*100H + space         ;al,ah := space
        SCASB                                 ;es dürfen nur noch spaces folgen
        JE      noprn                         ;falls dev.name länger ist
        SCASW
        JNE     noprn
        SCASW
        JNE     noprn
        XOR     AX,AX                         ;ax := 0, prn drive gefunden
        PUSH    ES                            ;es sichern
        PUSH    DS
        POP     ES                            ;es := SEG data
        LEA     DI,buffer                     ;ds:di auf den buffer
        LEA     SI,txtdev                     ;es:si auf '/dev/'
        MOV     CX,txtdevlen                  ;länge des txtdev präfix
        REPZ    MOVSB                         ;in den buffer kopieren
        POP     ES                            ;es zurückholen
        PUSH    DS                            ;ds,es sichern
        PUSH    ES
        MOV     SI,BX                         ;es:si auf den device driver
        ADD     SI,+0AH                       ;es:si auf den namen des drivers
        MOV     CX,0004H                      ;device name 8 words lang
        PUSH    DS                            ;ds <-> es ,austauschen
        PUSH    ES                            ;  nun ds:si auf den driver name
        POP     DS                            ;  und es:di auf buffer
        POP     ES
        REPZ    MOVSW                         ;device name in den buffer kopiern
        POP     ES                            ;ds,es auf die alten segmente
        POP     DS
        JMP     SHORT L0286                   ;zurück

noprn:  MOV     AX,0FFFFH                     ;fehlerausgang, nicht prn drive

L0286:  RET
chkprn  ENDP

code    ENDS

;---------------------------------------------------------------------
stack   SEGMENT STACK WORD 'stack'
        DB 0100H DUP (?)
stack   ENDS

        END main
