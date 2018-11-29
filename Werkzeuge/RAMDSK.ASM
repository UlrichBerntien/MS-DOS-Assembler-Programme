        PAGE    60,132
;---------------------------------------------------------------------
;       Assembler Listing von -- RAMDISK.COM --
;       Kommantare (c) Urich Berntien .04.1989
;                     letzte Änderung .04.1989
;       siehe dazu auch "Program development tools", Kapitel E
;---------------------------------------------------------------------
;     * Umbenenung im RAMDSK.COM
;     * keine Unit wenn ein Fehler auftritt
;     * Einbau: Anfrage der Ramdisk-größe in der Bootphase
;       falls Parameter 'D' gesetzt ist, wird über CON angefragt
;       dort muß dann der gleiche Text eingegeben werden wie auch
;       in der config.sys datei
;---------------------------------------------------------------------
XSEG    SEGMENT
        ASSUME CS:XSEG
        ORG 0000H

DOS  = 21H                      ;-- interrupts
BIOS = 88H
SECTOR_SIZE = 0200H             ;-- bytes per sector

;------------------ drive header -------------------------------------
START:  JMP   EXIT              ;-- jump to exit routine
        DB    00H               ;-- bricht sofort ab, falls ramdisk als Programm
                                ;-- aufgerufen wird
                                ;-- wird in init auf -1 gesetzt
        DW    2000H             ;-- attributes: nonibm format, block device,
                                ;--             no i/o-control strings
        DW    OFFSET ENQUEUE    ;-- device enqueue entry point
        DW    OFFSET SERVICE    ;-- device service entry point
        DB    'RAMDSK  '        ;-- device name
        DB    00H               ;-- number of units (set by sysinit)

;---------------------------------------------------------------------
FREEUSE DW    0000H             ;-- F:   0 Kbytes für disk reservieren
REST    DW    0080H             ;-- R: 128 Kbytes reserviert für rest
PROZENT DW    1B77H             ;-- P: 70.31 % für disk vom übrigen speicher
B_SEG   DW    0000H             ;-- B_SEG:0000 auf erstes ramdisk data byte
WORDPS  DW    SECTOR_SIZE / 2   ; words per sector

;------------------ bpb ----------------------------------------------
BPS     DW      SECTOR_SIZE     ;-- bytes per sector
        DB      02H             ;-- sectors per allocation unit
        DW      0000H           ;-- reserved sectors for startup
        DB      01H             ;-- number of fat's
        DW      0040H           ;-- number of root directory entries
N_SEC   DW      0000H           ;-- number of sectros in logical image
        DB      0FFH            ;-- media deskriptor
N_FAT   DW      0000H           ;-- number of fat sectors

P_BPB   DW      OFFSET BPS      ;-- bpb pointer array angeben bei init

;------------------ jump table ---------------- command --------------
JUMPER  DW    OFFSET INIT                     ;-- init
        DW    OFFSET CHECK                    ;-- media check
        DW    OFFSET BUILT                    ;-- build bpb
        DW    OFFSET QRET                     ;-- ioctl input
        DW    OFFSET INPUT                    ;-- input (read)
        DW    OFFSET QRET                     ;-- nondestructive input no wait
        DW    OFFSET QRET                     ;-- input status
        DW    OFFSET QRET                     ;-- input flush
        DW    OFFSET OUTPUT                   ;-- output (write)
        DW    OFFSET OUTPUT                   ;-- ouptut (write) with verify
        DW    OFFSET QRET                     ;-- output status
        DW    OFFSET QRET                     ;-- output flush
        DW    OFFSET QRET                     ;-- ioctl output

STOREDB DD    00000000H                       ;-- pointer to the data block

        EVEN    ; für das word-weise umkopieren (siehe init-proc)
;------------------ enqueue routine ----------------------------------
ENQUEUE PROC FAR
        MOV   WORD PTR [CS:STOREDB],BX        ;-- save pointer to data block
        MOV   WORD PTR 2[CS:STOREDB],ES
        PUSH  DS                              ;-- backup register
        PUSH  ES
        PUSH  AX
        PUSH  BX
        PUSH  CX
        PUSH  DX
        PUSH  SI
        PUSH  DI
        MOV   AX,CS                           ;-- DS := CS
        MOV   DS,AX
        LES   SI,DS:[STOREDB]                 ;-- pointer to data block laden
        MOV   BL,ES:[SI+02H]                  ;-- command code aus dem srh
        XOR   BH,BH                           ;-- bx := bl
        SHL   BX,1                            ;-- bx := bx *2
        CALL  DS:[BX+JUMPER]                  ;-- verzweige laut command code
        POP   DI                              ;-- restore register
        POP   SI
        POP   DX
        POP   CX
        POP   BX
        POP   AX
        POP   ES
        POP   DS
        RET                                   ;-- return
ENQUEUE ENDP

;------------------ service routine ----------------------------------
SERVICE PROC FAR
        RET                                   ;-- dummy
SERVICE ENDP

;---------------------------------------------------------------------
CHECK   PROC NEAR                             ;-- media check
        MOV     BYTE PTR ES:[SI+0EH],01H      ;-- media has not been changed
        MOV     WORD PTR ES:[SI+03H],0100H    ;-- set status: done, no error
        RET
CHECK   ENDP

;---------------------------------------------------------------------
QRET    PROC NEAR
        RET
QRET    ENDP

;---------------------------------------------------------------------
BUILT   PROC NEAR                             ;-- build bpb
        MOV   BYTE PTR ES:[SI+0DH],0FFH       ;-- set media diskriptor
        MOV   WORD PTR ES:[SI+12H],OFFSET BPS ;-- pointer to bpb ,offset
        MOV   ES:[SI+14H],DS                  ;--                ,segment
        MOV   WORD PTR ES:[SI+03H],0100H      ;-- set status: done, no error
        RET
BUILT   ENDP

;---------------------------------------------------------------------
INPUT   PROC NEAR                             ;-- input (read)
        CLD
        MOV   BX,ES:[SI+14H]                  ;-- bx := starting sector#
        MOV   AX,ES:[SI+12H]                  ;-- ax := sector count
        OR    AX,AX
        JE    ERR01                           ;-- keine sectoren => fehler
        MOV   CX,AX
        ADD   CX,BX                           ;-- cx := last sector# to read
        CMP   CX,DS:[N_SEC]
        JNBE  ERR01                           ;-- über die grenze
        MUL   DS:WORDPS                       ; ax := ax * sector größe in words
        PUSH  ES                              ;-- backup register
        PUSH  SI
        PUSH  DS
        LES   DI,DWORD PTR ES:[SI+0EH]        ;-- es:di := transfer address
        MOV   CX,AX                           ; cx := count in words
        MOV   AX,SECTOR_SIZE / 0010H          ;-- sector size in paragraphs
        MUL   BX                              ;-- ax := segement der daten
        ADD   AX,DS:[B_SEG]                   ;--       in der ramdisk
        MOV   DS,AX
        XOR   SI,SI                           ;-- si := 0
        REPZ  MOVSW                           ;-- from ds:si to transfer address
        POP   DS                              ;-- restore register
        POP   SI
        POP   ES
        MOV   WORD PTR ES:[SI+03H],0100H      ;-- set status: done, no error
        RET
ERR01:  MOV   WORD PTR ES:[SI+03H],810CH      ;-- set status: error, done,
                                              ;--     err.code general failure
        MOV   WORD PTR ES:[SI+12H],0000H      ;-- set count : 00
        RET
INPUT   ENDP

;---------------------------------------------------------------------
OUTPUT  PROC NEAR                             ;-- mit und ohne verify
        CLD
        MOV   BX,ES:[SI+14H]                  ;-- bx := starting sector#
        MOV   AX,ES:[SI+12H]                  ;-- ax := sector count
        OR    AX,AX
        JE    ERR02                           ;-- falls ax = 0
        MOV   CX,AX
        ADD   CX,BX                           ;-- cx := last sector#
        CMP   CX,DS:[N_SEC]
        JA    ERR02                           ;-- über die grenze
        MUL   DS:WORDPS                       ; ax := size in words
        PUSH  ES                              ;-- backup register
        PUSH  SI
        PUSH  DS
        LDS   SI,DWORD PTR ES:[SI+0EH]        ;-- ds:si := transfer address
        MOV   CX,AX                           ; cx := size in words
        MOV   AX,SECTOR_SIZE / 0010H          ;-- sector size in paragrphs
        MUL   BX                              ;-- ax := segment der daten
        ADD   AX,CS:[B_SEG]                   ;--       in der ramdisk
        MOV   ES,AX
        XOR   DI,DI                           ;-- di := 0
        REPZ  MOVSW                           ;-- from transfer address to es:si
        POP   DS                              ;-- restore register
        POP   SI
        POP   ES
        MOV   WORD PTR ES:[SI+03H],0100H      ;-- set status: done, no error
        RET
ERR02:  MOV   WORD PTR ES:[SI+03H],810CH      ;-- set status: error, done
                                              ;--  error code: general failure
        MOV   WORD PTR ES:[SI+12H],0000H      ;-- set count : 00
        RET
OUTPUT  ENDP

;------------------ init routine -------------------------------------
INIT    PROC FAR
        MOV   WORD PTR DS:[START],0FFFFH      ;-- ponter to next := -1
        MOV   WORD PTR DS:2[START],0FFFFH
        PUSH  ES                              ;-- backup pointer to db
        PUSH  SI
        MOV   AX,CS                           ;-- ES := CS + 0400
        ADD   AX,0400H
        MOV   ES,AX
              ; die enqueue-proc wird für den Rücksprung benötigt !
        MOV   CX,OFFSET LAST - OFFSET ENQUEUE ;-- länge der init routine
        SHR   CX,1                            ;--  in words
        MOV   SI,OFFSET ENQUEUE
        MOV   DI,SI
        REPZ  MOVSW                           ;-- mov to ES:DI
        PUSH  ES                              ;-- segement
        MOV   AX,OFFSET INIT2                 ;-- offset der verschobenen proc
        PUSH  AX
        RET                                   ;-- RETF => JMP INIT2
INIT    ENDP

INIT2   PROC NEAR
        POP   SI                              ;-- pointer zum db wiederholen
        POP   ES
        MOV   BYTE PTR ES:[SI+0DH],00H
                 ; number of units := 00
                 ; bei 0 units wird der driver nicht installiert
                 ; wird nicht angesprungen
        MOV   WORD PTR ES:[SI+0EH],OFFSET JUMPER ; breakaddress, falls später
        MOV   WORD PTR ES:[SI+10H],DS            ;    einfehler auftritt
        PUSH  WORD PTR ES:[SI+12H]            ;-- pointer auf den aufruf-text
        PUSH  WORD PTR ES:[SI+14H]            ;--  sichern
        MOV   WORD PTR ES:[SI+12H],OFFSET P_BPB ;-- pointer to bpb pointer array
        MOV   ES:[SI+14H],DS                    ;--   offset and segment
        MOV   DX,OFFSET HELLO                 ;-- to "RANDISK ....
        MOV   AH,09H                          ;-- print a string
        INT   DOS
        CLD
        POP   ES                              ;-- ES:DI auf den aufruf-text
        POP   DI
HANGUP: MOV   CX,MY_NAME_LEN                  ;-- länge des textes
        MOV   SI,OFFSET MYNAME                ;-- pointer to "RAMDISK.COM"
        PUSH  DI
        REPZ  CMPSB                           ;-- vergleiche ob name stimmt
        POP   DI                              ;-- di bleibt unverändert
        JE    L02D5                           ;-- sind gleich
        INC   DI
        CMP   BYTE PTR ES:[DI],0DH            ;-- zeilenende ?
        JE    L02E1                           ;-- aufrufzeile ist leer
        JMP   HANGUP                          ;-- erhängt sich wenn name falsch
L02D5:  ADD   DI,MY_NAME_LEN                  ;-- di hinter name
        CMP   BYTE PTR ES:[DI],0DH
        JE    L02E1                           ;-- keine parameter
        CALL  WERTEAUS                        ;-- parameter auswerten
L02E1:  MOV   AL,01H                          ;-- set es:bx to
        INT   BIOS                            ;--   system configuration table
        MOV   DX,ES:[BX+02H]                  ;-- dx := size of memory in para.
        MOV   DI,DX
        MOV   CL,06H                          ;-- dx := dx DIV 64
        SHR   DX,CL                           ;-- dx := memory size in Kbytes
        CMP   WORD PTR DS:[FREEUSE],+00H
        JNE   NOCALC                          ;-- falls absolutwert angegeben
        SUB   DX,DS:[REST]                    ;-- dx := kbytes für ramdisk
        JA    LOK01
        MOV   DX,OFFSET TOOMUCH               ;-- "to much memory reserved"
        JMP   I_ERR

LOK01:  MOV   AX,DX
        MOV   BX,DS:[PROZENT]
        MUL   BX                              ;-- ax := frei * prozent(10tel)
        ADD   AX,1388H                        ;-- plus 0.5 Kbytes (effektiv)
        ADC   DX,+00H
        MOV   BX,2710H                        ;-- bx := 10000dez
        DIV   BX                              ;-- ax := kbytes für ramdisk
        MOV   WORD PTR DS:[FREEUSE],AX        ;-- speichern
NOCALC: CMP   WORD PTR DS:[FREEUSE],+20H      ;-- min 32Kbyte für ramdisk
        JNB   LOK02
        MOV   DX,OFFSET SMALL                 ;-- "computed size to small"
        JMP   I_ERR

LOK02:  MOV   AX,DI                           ;-- ax := size of memory in para
        MOV   BX,DS                           ;-- bx := schon vergebener platz
        SUB   AX,BX                           ;-- jetzt noch freier speicher
        ADD   AX,003FH                        ;-- (+63) aufrunden auf Kbytes
        MOV   CL,06H
        SHR   AX,CL                           ;-- ax := freier speicher in Kb
        SUB   AX,DS:[FREEUSE]
        JNA   L034B                           ;-- zu wenig speicher
        CMP   AX,0020H
        JNB   LOK03                           ;-- ramdisk über 32 Kbytes
L034B:  MOV   DX,OFFSET NOMEM                 ;-- "not enougth free space"
        JMP   I_ERR                           ;-- print a string

LOK03:  MOV   DX,DS:[FREEUSE]
        SHL   DX,1                            ;-- dx := size in 512 bytes
        MOV   DS:[N_SEC],DX                   ;--     = anzahl der sectoren
        SHR   DX,1
        MOV   AX,DX
        XOR   DX,DX                           ;-- dx := 0
        MOV   BX,0155H                        ;-- 341
        DIV   BX
        INC   AX                              ;-- aufrunden
        MOV   WORD PTR DS:[N_FAT],AX          ;-- ergibt anzahl der fat's
        MOV   DI,DS:[FREEUSE]                 ;-- speicher für disk daten
        MOV   CL,06H                          ;-- in paragrpahs
        SHL   DI,CL
        MOV   DX,OFFSET INIT                  ;-- platz für disk programm
        ADD   DX,+0FH                         ;-- aufrunden
        MOV   CL,04H                          ;-- in paragraphs
        SHR   DX,CL
        MOV   AX,DS                           ;-- aktuelles segment
        ADD   AX,DX                           ;--  + data + programm in para.
        ADD   DI,AX                           ;--  = segment der break address
        LES   SI,DS:[STOREDB]                 ;-- es:si auf data block
        MOV   WORD PTR ES:[SI+0EH],0000H      ;-- set break address
        MOV   ES:[SI+10H],DI
        MOV   BYTE PTR ES:[SI+0DH],01H        ;-- set number of units: 01
        MOV   WORD PTR DS:[B_SEG],AX          ;-- anfang der ramdisk speichern
        MOV   ES,AX
        XOR   DI,DI                           ;-- di := 00
        MOV   CX,1000H                        ;-- 1000H words setzen
        XOR   AX,AX                           ;-- ax := 00
        REPZ  STOSW                           ;-- alles mit 0000 füllen
        MOV   AX,0FFFFH
        XOR   DI,DI                           ;-- di := 00
        STOSW
        STOSB                                 ;-- erste drei bytes := 0FFH
        MOV   AX,WORD PTR DS:[FREEUSE]
        CALL  DEZ_AX                          ;-- ausgeben wieviel kbytes
        MOV   AX,CS
        MOV   DS,AX
        MOV   DX,OFFSET ALLOC                 ;-- ds:dx auf "K allocated"
        MOV   AH,09H                          ;-- print a string
        INT   DOS
        RET

I_ERR:  MOV   AH,09H                          ; print a string
        INT   DOS
        RET
INIT2   ENDP

;------------------ ax dezimal ausgeben ------------------------------
DEZ_AX  PROC NEAR
        XOR   DX,DX                           ;-- dx := 0
        MOV   BX,000AH                        ;-- bx := 10
        DIV   BX                              ;-- ax := ax,dx div bx
                                              ;-- dx := ax,dx mod bx
        OR    AX,AX                           ;-- ax = 0 ?
        JE    DEZEND                          ;-- je, es war höchste stelle
        PUSH  DX                              ;-- merke die ziffer
        CALL  DEZ_AX                          ;-- rekursion
        POP   DX                              ;-- nächste ziffer ausgeben
DEZEND: OR    DL,'0'                          ;-- in ascii ziffer
        MOV   AH,02H                          ;-- char in dl screen output
        INT   DOS
        RET
DEZ_AX  ENDP

;------------------ Parameter auswerten ------------------------------
        ; falls Angaben nicht vorhanden oder falsch, so beliben
        ; die standartwerte erhalten
WERTEAUS PROC NEAR                            ;-- es:di zeigt auf parameter
        MOV   AL,ES:[DI]
        INC   DI                              ;-- auf nächstes zeichen
        CMP   AL,0DH
        JNE   TESTF
        RET                                   ;-- zeilenende erreicht

TESTF:  CMP   AL,'F'                          ;-- speicherangabe in Kbytes
        JNE   TESTR
        CALL  READ_AX                         ;-- gewünschte größe einlesen
        JC    WERTEAUS                        ;-- falls fehler
        CMP   AX,0380H
        JAE   WERTEAUS                        ;-- über 896 Kbyte nicht annehmen
        MOV   WORD PTR DS:[FREEUSE],AX        ;-- wert speichern
        JMP   WERTEAUS

TESTR:  CMP   AL,'R'                          ;-- angabe des frei zu bleibenden
                                              ;-- speichers in Kbytes
        JNE   TESTD
        CALL  READ_AX                         ;-- wert einlesen
        JC    WERTEAUS                        ;-- falls fehler
        CMP   AX,0380H
        JAE   WERTEAUS                        ;-- falls über 896 Kbyte
        MOV   WORD PTR DS:[REST],AX           ;-- wert speichern
        JMP   WERTEAUS

TESTD:  CMP   AL,'D'                          ; parameter einlesen über CON
        JNE   TESTP
        MOV   DX,OFFSET PROMPT                ; promt text ausgeben
        MOV   AH,09H                          ; print a string
        INT   DOS
        MOV   DX,OFFSET LSTRING               ; den parametertext einlesen
        MOV   AH,0AH                          ; buffered keyboard input
        INT   DOS
        MOV   DL,0AH                          ; line feed
        MOV   AH,02H                          ; screen output
        INT   DOS
        MOV   AX,DS                           ; es:di auf den neuen parameter
        MOV   ES,AX
        MOV   DI,OFFSET STRING
        JMP   WERTEAUS                        ; den neuen text lesen

TESTP:  CMP   AL,'P'                          ;-- prozentuale Angabe
        JNE   WERTEAUS                        ;-- nicht auswertbares ziechen
        CALL  READ_AX                         ;-- lesen den zahlenwert
        JC    WERTEAUS                        ;-- falls fehler
        CMP   AX,100D
        JA    LNO10                           ;-- > 100, also 10tel prozent
        MOV   BL,64H
        MUL   BL                              ;-- auch in 10tel prozent wandeln
LNO10:  CMP   AX,10000D
        JA    WERTEAUS                        ;-- > 100.00%, geht nicht
        MOV   WORD PTR DS:[PROZENT],AX        ;-- wert speichern
        JMP   WERTEAUS
WERTEAUS ENDP

;------------------ zahl einlesen ------------------------------------
READ_AX PROC NEAR                             ;-- lese integerwert in ax
        CALL  GOOVER                          ;--        CF falls fehler
        CMP   CL,'0'
        JB    READE                           ;-- falls keine ziffer
        CMP   CL,'9'
        JBE   READB                           ;-- falls ziffer
READE:  DEC   DI
        STC                                   ;-- set carry <=> fehler
        RET
READB:  XOR   AX,AX                           ;-- ax := 0
READL:  MOV   BX,10D
        MUL   BX                              ;-- ax := ax * 10
        XOR   CH,CH                           ;-- cx := cl
        SUB   CL,'0'                          ;-- ziffersymbol in wert
        ADD   AX,CX                           ;-- ax := ax + neue ziffer
        CALL  GOOVER                          ;-- überlesen von space,tab
        CMP   CL,'0'
        JB    READS                           ;-- keine ziffer mehr
        CMP   CL,'9'
        JBE   READL                           ;-- nächste ziffer
READS:  DEC   DI
        CLC                                   ;-- kein fehler gefunden
        RET
READ_AX ENDP

;---------------------------------------------------------------------
GOOVER  PROC NEAR
        MOV   CL,ES:[DI]
        INC   DI                              ;-- überliest
        CMP   CL,20H                          ;--   leerzeichen
        JE    GOOVER
        CMP   CL,09H                          ;--   tab's
        JE    GOOVER
        RET
GOOVER  ENDP

;---------------------------------------------------------------------
STRLEN = 40
LSTRING DB    STRLEN                          ; max länge des strings
        DB    (?)                             ; wirkliche länge
STRING  DB    STRLEN DUP ( 20H )              ; buffer für string
PROMPT  DB    'D> $'
HELLO   DB    'RAMDSK (UB) v1.00 - $'
ALLOC   DB    ' K allocated',0DH,0AH,'$'
TOOMUCH DB    'Too much memory reserved',0DH,0AH,'$'
NOMEM   DB    'Not enough free space',0DH,0AH,'$'
SMALL   DB    'Computed size is too small!',0DH,0AH,'$'
MYNAME  DB    'RAMDSK.COM'

;------------------ abbruch nach "normalem" aufruf -------------------
EXIT:   MOV   AX,4C00H                        ;-- exit from process
        INT   DOS                             ;--     error code 00

MY_NAME_LEN = OFFSET EXIT - OFFSET MYNAME

LAST    DB      00H

XSEG    ENDS
        END
