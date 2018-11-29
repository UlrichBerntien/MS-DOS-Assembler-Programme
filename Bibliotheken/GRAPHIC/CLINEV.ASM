; MS-Macro-Assembler V1.1 /Wang PC004
;  (c) Ulrich Berntien .07.1985
; Procedure CLineV(Y1,Y2,X :Integer); Extern;
; Löscht eine Linie vertikal von (Y1,X) bis (Y2,X)

Data    Segment Public  'Data'
 DGroup  Group Data
 Assume DS:DGroup
 Extrn   GGSeg:Word ,GGSta:Word ,GGOut:Word
                ;GGSeg =Segment des Sreen Information Block
                ;GGSta =Adresse des ersten Status Bytes
                ;GGOut =Ausgabeanschluß für Grafikkarte
Data    EndS

Grafik  Segment Public 'Code'
 Assume  CS:Grafik
 Public  CLineV

CLineV  Proc Far
        Push    Bp              ;Frame Pointer retten
        Mov     Bp,Sp           ;Bp auf Stack
        Mov     Cx,10[Bp]       ;Y1 in Cx
        Mov     Si,8[Bp]        ;Y2 in Si
        Mov     Bx,6[Bp]        ;X in Bx
        Cmp     Cx,299          ;Zeilen von 0 bis 299
        JG      Ende            ;ungültige Zeile
        Cmp     Cx,0
        JL      Ende            ;ungültige Zeile
        Cmp     Si,299          ;Zeilen von 0 bis 299
        JG      Ende            ;ungültige Zeile
        Cmp     Si,0
        JL      Ende            ;ungültige Zeile
        Cmp     Bx,799          ;Spalten von 0 bis 799
        JG      Ende            ;ungültige Spalte
        Cmp     Bx,0
        JL      Ende            ;ungültige Spalte
        Cmp     Si,Cx           ;von ? bis ?
        JG      Lab1            ;von Cx nach Si
        XChg    Si,Cx           ;tauschen
Lab1:   Sub     Si,Cx           ;Zeilendifferenz in Si
        Sal     Cx,1            ;Di := Cx * 100
        Sal     Cx,1            ;schneller als Mul-Befehl
        Mov     Ax,Cx           ;durch '*2' und '+'
        Sal     Cx,1            ;errechnen des Zeilenoffset
        Sal     Cx,1
        Add     Ax,Cx
        Mov     Di,Ax
        Sal     Ax,1
        Sal     Ax,1
        Add     Di,Ax
        Mov     Dx,Bx           ;Spalten auch in Dx
        Sar     Dx,1            ;dreimal verschieben
        Sar     Dx,1            ;Bx:=Bx div 8
        Sar     Dx,1
        And     Dl,0feH         ;in 16er Schritten Bit0:=0
        Add     Di,Dx           ;Adresse in Ax
        And     Bx,1111B        ;Bx:=Bx mod 16
        Sal     Bx,1            ;mal 2, für Word
        Mov     Bx,CS:Table[Bx] ;Zu löschender Punkt in Bx
        Mov     Dx,GGOut        ;Ausgang zur Grafikkarte
        Mov     Es,GGSeg        ;Segment von SIB
        Mov     Bp,GGSta        ;Adresse des 1.Statusbytes
        Mov     Al,Es:[Bp]      ;Byte in Al
        And     Al,0cH
        Or      Al,01H          ;Signal für Karte in Al
        Push    Ds              ;Datensegment retten
        Mov     Cx,0e000H       ;Grafikspeichersegment
        Mov     Ds,Cx           ;in Ds
        Mov     Cx,Si           ;Anzahl der Zeilen in Cx
        Inc     Cx              ;plus 1
        Mov     Si,064H         ;Konstante
Lab2:   Out     Dx,Al           ;Signal an Grafikkarte
        And     [Di],Bx         ;Punkt setzen
        Add     Di,Si           ;eine Zeile tiefer
        Loop    Lab2            ;Cx:=Cx-1. bis Cx=0
        Pop     Ds              ;Datensegment setzen
Ende:   Pop     Bp              ;Frame Pointer setzen
        Ret     6               ;zurück
        EVEN
Table:  DW      0111111111111111B
        DW      1011111111111111B
        DW      1101111111111111B
        DW      1110111111111111B
        DW      1111011111111111B
        DW      1111101111111111B
        DW      1111110111111111B
        DW      1111111011111111B
        DW      1111111101111111B
        DW      1111111110111111B
        DW      1111111111011111B
        DW      1111111111101111B
        DW      1111111111110111B
        DW      1111111111111011B
        DW      1111111111111101B
        DW      1111111111111110B
CLineV  EndP
Grafik  EndS
        End
