; MS-Macro-Assembler V1.1 /Wang PC004
;  (c) Ulrich Berntien .07.1985
; Procedure LineV(Y1,Y2,X :Integer);
; Zieht eine Linie vertikal von (Y1,X) bis (Y2,X)

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
 Public  LineV

LineV   Proc Far
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
        Mov     Dx,Bx           ;Spalte auch in Dx
        Sar     Dx,1            ;dreimal verschieben
        Sar     Dx,1            ;Dx:=Dx div 8
        Sar     Dx,1
        Xor     Dl,01B          ;Hi/Lo-Byteposition in Word
        Add     Di,Dx           ;Adresse in Di
        And     Bx,111B         ;Bx:=Bx mod 8
        Mov     Bl,Byte PTR CS:Table[Bx] ;Zu setzende Punkt in Bx
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
        Out     Dx,Al           ;Signal an Grafikkarte
Lab2:   Or      [Di],Bl         ;Punkt setzen
        Add     Di,Si           ;eine Zeile tiefer
        Loop    Lab2            ;Cx:=Cx-1, bis Cx=0
        Pop     Ds              ;Datensegment setzen
Ende:   Pop     Bp              ;Frame Pointer setzen
        Ret     6               ;zurück
Table:  DB      10000000B
        DB      01000000B
        DB      00100000B
        DB      00010000B
        DB      00001000B
        DB      00000100B
        DB      00000010B
        DB      00000001B
LineV   EndP
Grafik  EndS
        End
