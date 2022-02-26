; MS-Macro Assmebler V3.04 / Wang PC
; (c) Ulrich Berntien .12.1986
; Format:  RENV2 <alter Name> <neuer Name>
; Umbenannen mit Hilfe der DOS-2.00-funktion #56 erlaubt, daß
;   Namen in anderen Subdirectoris liegen (aber gleicher Drive)

Code    Segment
 Assume Cs: Code, DS : Code

 Long   EQU Byte PTR Ds:80H
        ORG     100H

        MOV     BX,0081H        ;erstes Zeichen des Parameters
        MOV     DX,BX           ;auch in Dx
        ADD     DL,Long         ;Dx auf letztes Zeichen +1
        JNB     Lop0            ;testen ob Übertrag
        INC     DH
Lop0:   INC     BX              ;nächstes Zeichen
        CMP     BX,DX
        JG      ERR
        CMP     BYTE PTR [BX],' '
        JZ      Lop0            ;solange bis nicht Blank ist
        MOV     ADR1,BX         ;Adresse alten Namens
Lop2:   INC     BX              ;nächstes Zeichen
        CMP     BX,DX
        JG      ERR
        CMP     BYTE PTR [BX],' '
        JNZ     Lop2            ;solange bis Blank
        MOV     BYTE PTR [BX],00 ;Name in ASCIZ Format
Lop3:   INC     BX              ;nächstes Zeichen
        CMP     BX,DX
        JG      ERR
        CMP     BYTE PTR [BX],' '
        JZ      Lop3            ;solange bis kein Blank
        MOV     ADR2,BX         ;Adresse des alten Namns
        MOV     SI,DX
        MOV     BYTE PTR [SI],00 ;Name in ASCIZ Format

        MOV     AH,56H          ;RENAME
        MOV     DX,ADR1         ;alter Name
        MOV     DI,ADR2         ;neuer Name
        INT     21H             ;DOS-Call
        JC      ERRD            ;DOS-fehler
        INT     20H             ;fertig

ERRD:   MOV     CL,AL           ;FehlerCode ischern
        SHR     AL,1
        SHR     AL,1            ;Highnibel
        SHR     AL,1            ;nach LoNibel schieben
        SHR     AL,1
        ADD     AL,'0'          ;in ASCII Wert
        MOV     ET,AL           ;Ausgabestring
        MOV     AL,CL
        AND     AL,0FH          ;LoNibel
        ADD     AL,'0'          ;in ASCII Wert
        MOV     ET+1,AL         ;in Ausgaestring
        Mov     CX,Text2-Text1  ;Läange
        Mov     DX,offset Text1 ;Adresse
        JMP     OUT             ;Ausgabe
ERR:    Mov     CX,ED-Text2     ;Läange
        Mov     DX,offset Text2 ;Adresse
Out:    MOV     AL,0DH          ;Ausgabe auf Monitor
        INT     88H             ;BIOS-Call
        INT     20H             ;DOS-Exit

        EVEN
ADR1    DW
ADR2    DW
Text1   DB 'MS-DOS #'
ET      DB '00'
        DB ' ERROR during work'
Text2   DB 'wrong Parameter'
ED      DB

Code    EndS
        End
