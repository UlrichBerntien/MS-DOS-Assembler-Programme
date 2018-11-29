;=====================================================================
; (c) Kommentare Ulrich Berntien .06.1990
;              letzte Änderung 03.06.1990
;
; Disassembler-Listing des Boot Sektors
;=====================================================================

boot    SEGMENT
        ASSUME CS:boot,DS:boot

bpb_f   STRUC
  bps      DW (?)            ;bytes per sector
  spa      DB (?)            ;sectors per allocation unit
  rsrvd    DW (?)            ;reserved sectors (number required by startup)
  fats     DB (?)            ;number of fats
  dirs     DW (?)            ;number of root dir entries
  spl      DW (?)            ;number of sectors per logical image
                             ;    (i.e. number of sectors per floppy)
  mdd      DB (?)            ;media descriptor (i.e. fatid)
  spf      DW (?)            ;number of sectors per fat
  spt      DW (?)            ;number of sectors per track
  hads     DW (?)            ;number of heads
  hids     DW (?)            ;number of hidden sectors
  stups    DW (?)            ;number of sectors reserved for startup+fats+dir
bpb_f   ENDS

DirEntry STRUC
  fname    DB 8 DUP (?)      ;file name
  ext      DB 3 DUP (?)      ;extension
  attr     DB (?)            ;attributes
           DB 10 DUP (0)     ;zero-filled field (for expansion)
  time     DW (?)            ;time of creation or last write
  date     DW (?)            ;date of creation or last write
  alloc    DW (?)            ;first allocation unit
  size     DD (?)            ;file size, in byte (30 bits max)
DirEntry ENDS

FatBuffer = 0200H            ;Offset zum Buffer in den FAT geladen wird
DirBuffer = 1200H            ;Offset zum Buffer in den Rootdir geladen wird
EOFM = 0FFFH                 ;end of file marker in der FAT
ReadErrBit = 80H             ;finden BIOS einen Fehler beim lesen, so ist
                             ;dises Bit in AH bei der Rückkehr gesetzt

;---------------------------------------------------------------------
        ORG 0000H

start:  JMP   booting

sysname DB    'Wang 2.0'

bpb     bpb_f <200H,08,01,02,080H,4C00H,0F9H,08,010H,04,00,019H>

eSysMiss:
        DB    07H,0EH,'***44',0FH
        DB    ' SYSTEM FILES MISSING',00
eDskRead:
        DB    07H,0EH,'***45',0FH
        DB    ' DISK READ ERROR',00
eDfctDsk:
        DB    07H,0EH,'***46',0FH
        DB    ' DEFECTIVE START DISK',00

biosnm  DB    'BIOS    SYS'
dosnm   DB    'MSDOS   SYS'

        DB    00H
        DB    22H
L008D:  DW    2 DUP(0000H)

;---------------------------------------------------------------------
booting PROC NEAR
        MOV   CX,022AH
        MOV   DX,bpb.hids
        MOV   AH,BYTE PTR bpb.hads
        MOV   AL,BYTE PTR bpb.spt
        INT   92H

L00A1:  MOV   SI,FatBuffer                    ;adresse des fat buffers in si
        MOV   BX,bpb.rsrvd                    ;nach den reservierten sect. lesen
        MOV   AL,BYTE PTR bpb.spf
        SHL   AL,1
        MOV   DL,04H                          ;von laufwerk lesen
        INT   91H
L00B1:  TEST  AH,ReadErrBit                   ;fehler beim lesen vom laufwerk ?
        JNZ   L00BC                           ;nein, dann weiter
L00B6:  MOV   SI,OFFSET eDskRead              ;  ja, dann meldung ausgeben
        JMP   error

L00BC:  MOV   SI,DirBuffer                    ;adresse des directory buffers
        MOV   AX,bpb.spf
        MUL   bpb.spa
        ADD   AX,bpb.rsrvd
        MOV   BX,AX
        MOV   AX,bpb.dirs                     ;anzahl der dir.eintrúge
        ADD   AX,0007H
        MOV   CL,03H
        SHR   AX,CL
        MOV   DL,04H                          ;von laufwerk lesen
        INT   91H
L00DA:  TEST  AH,ReadErrBit                   ;fehler beim lesen vom laufwerk ?
        JE    L00B6                           ;ja, dann fehlermeldung ausgeben

        MOV   SI,OFFSET biosnm                ;si auf namen der gesuchten datei
        CALL  dirsearch
        JE    L00EA                           ;sprung, falls name gefunden
        JMP   eSMiss                          ;sonst fehlermeldung ausgeben
L00EA:  CALL  readfile
        MOV   AX,WORD PTR DS:[008BH]
        MOV   WORD PTR DS:[008DH],AX

        MOV   SI,OFFSET dosnm                 ;si auf namen der gewsuchten datei
        CALL  dirsearch
        JE    L00FE                           ;falls name gefunden
        JMP   eSMiss                          ;sonst fehlermeldung ausgeben
L00FE:  MOV   AX,[DI+1CH]
        MOV   WORD PTR DS:[008FH],AX
        CALL  readfile
        MOV   AX,0040H                        ;0040:0000 nach der int.tabelle
        MOV   ES,AX
        MOV   AX,WORD PTR ES:[00A7H]
        XOR   BL,BL                           ;bl := 0
        CMP   AX,0078H
        JE    L0128
        INC   BL
        CMP   AX,0080H
        JE    L0128
        MOV   CL,03H
        SHR   AX,CL
        INC   AL
        OR    AL,10H
        MOV   BL,AL
L0128:  MOV   SI,2200H
        XOR   DI,DI
        MOV   CX,6E00H
        CLI
        CLD
        REPZ MOVSW
        MOV   AX,WORD PTR DS:[008DH]
        SUB   AX,1E00H
        MOV   CL,04H
        SHR   AX,CL
        MOV   CX,DS:[008FH]
    ;;;;JMP   0040H:0000H                     ;ins BIOS
        DB    0EAH,00H,00H,40H,00H
booting ENDP

              ;sucht nach einem Eintrag im Directory
              ;das Directory ist im DirBuffer geladen
              ;ARGS: SI zeigt auf den gesuchten Eintrag
              ;RETS: ZF = 0, wenn Eintrag gefunden
              ;      DX = erste allocation unit des files
              ;      CX = Größe des Files in 128 Kbyte Einheiten
;---------------------------------------------------------------------
dirsearch PROC NEAR
        CLD                                   ;richtung beim suchen positiv
        MOV   CX,bpb.dirs                     ;anzahl der dir.einträge
        MOV   DI,DirBuffer
L014F:  PUSH  CX
        PUSH  SI
        PUSH  DI
        MOV   CX,11                           ;namensfeld 11 zeichen lang
        REPZ CMPSB                            ;vergleich vornehmen
        POP   DI
        POP   SI
        POP   CX
        JE    dfound                          ;falls gefunden
        ADD   DI,+20H                         ;auf nächsten dir.eintrag
        LOOP  L014F                           ;bis ganzes dir durchsucht
dfound: PUSHF                                 ;die (mis-)erfolgsmeldung sichern
        MOV   DX,[DI.alloc]
        MOV   CX,WORD PTR [DI.size+2]
        SHR   CX,1
        INC   CX
        POPF                                  ;die (mis-)erfolgsmeldung zurück
        RET
dirsearch ENDP

              ;ARGS: dx = clusternummer
              ;RETS: dx nummer der nächsten allocation unit
              ;REGS: alle register werden erhalten
;---------------------------------------------------------------------
nextalloc PROC NEAR
        PUSH  AX                              ;sichern der benutzten register
        PUSH  BX
        PUSH  CX
        MOV   AX,DX                           ;ax := clusternummer
        XOR   DX,DX                           ;dx := 0
        MOV   BX,0003H
        MUL   BX
        SHR   AX,1                            ;ax := clusternr * 3/2
        MOV   BX,AX                           ;zur adressierung in der fat
        MOV   DX,[BX+FatBuffer]
        JNC   nEven                           ;sprung falls ungerade clusternr
        MOV   CL,04H
        SHR   DX,CL                           ;obere 12bits ===> untere 12bits
nEven:  AND   DX,0FFFH                        ;die unteren 12bits selektieren
        POP   CX                              ;zurückholen der register
        POP   BX
        POP   AX
        RET
nextalloc ENDP

;---------------------------------------------------------------------
readfile PROC NEAR
        PUSH  CX
        PUSH  DX
        MOV   AX,DX
        MOV   BL,bpb.spa
        XOR   BH,BH
L0199:  CALL  nextalloc
        CMP   DX,EOFM                         ;ende der cluster kette ?
        JE    L01AD
        SUB   CX,BX
        JB    eDfct                           ;fehlermeldung ausgeben
        INC   AX
        CMP   AX,DX
        JNE   L01AF
        JMP   L0199
L01AD:  XOR   CX,CX                           ;cx = 0, d.h. ende des files
L01AF:  POP   BX
        POP   AX
        SUB   AX,CX
        PUSH  CX
        PUSH  DX
        XCHG  AX,BX
        SUB   AX,0002H
        MOV   CL,bpb.spa
        XOR   CH,CH
        MUL   CX
        ADD   AX,DS:[001EH]
        XCHG  AX,BX
        SHL   AL,1
        MOV   SI,DS:[008BH]
        MOV   DL,04H                          ;lesen von laufwerk
        INT   91H
L01D0:  MOV   SI,OFFSET eDskRead              ;pessimist, si auf mögl. fehlertxt
        TEST  AH,ReadErrBit                   ;fehler beim lesen aufgetreten ?
        JNE   L01DA                           ;nein, dann weiter
        JMP   SHORT error                     ;  ja, dann fehlermeldung ausgeben
L01DA:  MOV   BH,AL
        XOR   BL,BL
        ADD   DS:[008BH],BX
        POP   DX
        POP   CX
        OR    CX,CX                           ;ende des files erreicht ?
        JNZ   readfile                        ;nein
        RET
readfile ENDP

eDfct:  MOV   SI,OFFSET eDfctDsk
        JMP   SHORT error

eSMiss: MOV   SI,OFFSET eSysMiss

error:  INT   8BH                             ;ansprung bei fehler
                                              ;si enthält adr vom fehlertext
                                              ;int 8BH = eine ausgabe funktion
        MOV   BX,001EH
        INT   97H

        EXTRN L0FFFEH_0009H:FAR
L01F8:  JMP   L0FFFEH_0009H
L01FD:  DW    0000H
        DB    68H
        DB    0F9H

boot    ENDS

        END start
