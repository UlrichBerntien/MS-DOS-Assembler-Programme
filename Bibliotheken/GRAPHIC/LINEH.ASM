; MS-Macro-Assembler V1.1 /Wang PC004
;  (c) Ulrich Berntien .12.1985
; Procedure LineH(X1,X2,Y :Integer); Extern;
; Zieht ein Linie horizontal von (X1/Y) bis (X2/Y)

Data    Segment Public  'Data'
DGroup  Group Data
Assume  DS:DGroup
Extrn   GGSeg:Word ,GGSta:Word ,GGOut:Word
                ;GGSeg =Segment des Sreen Information Block
                ;GGSta =Adresse des ersten Status Bytes
                ;GGOut =Ausgabeanschluß für Grafikkarte
Data    EndS

Grafik  Segment Public 'Code'
Assume  CS:Grafik
Public  LineH

LineH   Proc Far
        Push    Bp              ;Frame Pointer retten
        Mov     Bp,Sp           ;Bp auf Stack
        Mov     Cx,6[Bp]        ;Y in Cx
        Cmp     Cx,299          ;Zeilen von 0 bis 299
        JG      Ende            ;Zeile ungültig
        Cmp     Cx,0
        JL      Ende            ;Zeile ungültig
        Mov     Si,8[Bp]        ;X2 in Si
        Cmp     Si,799          ;Spalten von 0 bis 799
        JG      Ende            ;ungültige Spalte
        Cmp     Si,0
        JL      Ende            ;ungültige Spalte
        Mov     Bx,10[Bp]       ;X1 in Bx
        Cmp     Bx,799          ;Spalten von 0 bis 799
        JG      Ende            ;ungültige Spalte
        Cmp     Bx,0
        JGE     Weiter          ;ungültige Spalte
Ende:   Pop     Bp              ;Frame Pointer setzen
        Ret     6               ;zurück
Weiter: Sal     Cx,1            ;Di := Cx * 100
        Sal     Cx,1            ;schneller als Mul-Befehl
        Mov     Ax,Cx           ;durch '*2' und '+'
        Sal     Cx,1            ;errechnen des Adressenoffset
        Sal     Cx,1
        Add     Ax,Cx
        Mov     Di,Ax
        Sal     Ax,1
        Sal     Ax,1
        Add     Di,Ax
                                ;für Ausgabe  folgt
        Mov     Dx,GGOut        ;Ausgang zur Grafikkarte
        Mov     Es,GGSeg        ;Speichersegment des SIB
        Mov     Bp,GGsta        ;Adresse des 1.Statusbytes der Grafik
        Mov     Al,Es:[Bp]      ;Byte in Al
        And     Al,0cH          ;Bitmaske
        Or      Al,01H          ;Signal für Grafikkarte
        Push    Ds              ;Datensegment retten
        Mov     Cx,0e000H       ;Speichersegment der Grafik
        Mov     Ds,Cx           ;in Datensegmentregister
                                ;
        Cmp     Si,Bx           ;von ? nach ?
        JG      Lab1            ;von Bx nach Dx
        XChg    Si,Bx           ;tauschen
Lab1:   Mov     Es,Bx           ;Bx in Es sichern
        Sar     Bx,1            ;dreimal schieben
        Sar     Bx,1            ;Bx:=Bx div 8
        Sar     Bx,1
        And     Bl,0feH         ;in 16er Schritten
        Add     Di,Bx           ;Adresse in Di
        Mov     Bx,Es           ;1.X wiederholen
        Xor     Bx,Si
        And     Bx,0fff0H
        Mov     Bx,Es           ;1.X wiederholen
        Jne     Lab
        Sub     Si,Bx           ;Zahl der Punkte
        Mov     Bx,15           ;max. Anzahl
        Sub     Bx,Si           ;Adresse für Table
        Sal     Bx,1            ;Bx mal 2, weil Wort adressiert
        Mov     Si,Cs:Table[Bx] ;Punkte holen in Si
        Mov     Cx,Es           ;1.X wiederholen
        And     Cx,01111B       ;Cx:=Cx mod 16
        Sar     Bx,1            ;Bx durch 2 =altes Bx
        Sub     Bx,Cx           ;Anzahl der Verschiebungen
        Mov     Cl,Bl           ;in Cl
        Sal     Si,Cl           ;Verschieben
        Out     Dx,Al           ;Signal für Grafikkarte
        Or      [Di],Si         ;Punkte setzen
Ende1:  Pop     Ds              ;Datensegment setzen
        Pop     Bp              ;Frame Pointer setzen
        Ret     6               ;zurück

Lab:    Sub     Si,Bx           ;Zahl der Punkte
        Inc     Si              ; plus 1.Punkt
        And     Bx,01111B       ;Bx:=Bx mod 16
        Jz      Lab2E           ;noch keine Punkte zu setzen
        Sub     Si,16
        Add     Si,Bx           ;noch zu setzende Punkte
        Sal     Bx,1            ;Bx mal 2 ,weil Word adressiert
        Mov     Bx,Cs:Table[Bx] ;Zu setzende Punkte in Bx
        Out     Dx,Al           ;Signal zur Grafikkarte
        Or      [Di],Bx         ;Punkte setzen
        Inc     Di
        Inc     Di              ;Di auf nächstes Word
Lab2E:  Mov     Bx,16           ;Konstanten für Lab2
        Mov     Cx,0ffffH       ;
Lab2:   Sub     Si,Bx           ;16 Punkte werden gestzt
        JL      Lab3            ;weniger als 15 Punkte
        Out     Dx,Al           ;Signal für Grafikkarte
        Mov     Word PTR[Di],Cx ;16 Punkte setzen
        Jz      Ende1           ;alle gesetzt
        Inc     Di
        Inc     Di              ;auf nächstes Word
        Jmp     Lab2            ;nächste setzten
Lab3:   Add     Bx,Si           ;zu setzende Punke in Bx
        Sal     Bx,1            ;Bx mal 2 ,weil Word adressiert
        Mov     Bx,CS:Table[Bx] ;zu setzende Punkte in Bx
        Not     Bx              ;Punktmuster invertieren
        Out     Dx,Al           ;Signal an Grafikkarte
        Or      [Di],Bx         ;Punkte setzen
        Jmp     Ende1           ;Ende
        EVEN
Table:  DW      1111111111111111B
        DW      0111111111111111B
        DW      0011111111111111B
        DW      0001111111111111B
        DW      0000111111111111B
        DW      0000011111111111B
        DW      0000001111111111B
        DW      0000000111111111B
        DW      0000000011111111B
        DW      0000000001111111B
        DW      0000000000111111B
        DW      0000000000011111B
        DW      0000000000001111B
        DW      0000000000000111B
        DW      0000000000000011B
        DW      0000000000000001B
        DW      0000000000000000B
LineH   EndP
Grafik  EndS
        End
