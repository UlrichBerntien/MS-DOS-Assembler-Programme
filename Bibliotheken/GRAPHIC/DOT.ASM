; MS-Macro-Assembler V1.1 /Wang PC004
;  (c) Ulrich Berntien .06.1985
; Procedure Dot(X,Y :Integer); Extern;
; Setzt den Punkt (x/y) auf dem Grafikbildschirm

Data    Segment Public  'Data'
DGroup  Group Data
Assume DS:DGroup
Extrn   GGSeg:Word ,GGSta:Word ,GGOut:Word
                ;GGSeg =Segment des Sreen Information Block
                ;GGSta =Adresse des ersten Status Bytes
                ;GGOut =Ausgabeanschluß für Grafikkarte
Data    EndS

Grafik  Segment Public 'Code'
 Assume  CS: Grafik
 Public  Dot

Dot     Proc Far
        Push    Bp              ;Sichern des Frame Pointers
        Mov     Bp,Sp           ;BP auf Stack
        Mov     Cx,6[Bp]        ;Einlesen der Y-Koordinate
        Cmp     Cx,299          ;Zeilen von 0-299
        JG      Ende            ;ungültige Zeile
        Cmp     Cx,0
        JL      Ende            ;ungültige Zeile
        Mov     Bx,8[Bp]        ;Einlesen der X-Koordinate
        Cmp     Bx,799          ;Spalten 0-799
        JG      Ende            ;ungültige Spalte
        Cmp     Bx,0
        JL      Ende            ;ungültige Spalte
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
        Mov     Dx,Bx           ;Spalte in Dx
        Sar     Dx,1            ;dreimal schieben
        Sar     Dx,1            ;entsprich div. 8
        Sar     Dx,1
        Xor     Dl,01B          ;Hi/Lo-Byteposition in Word
        Add     Di,Dx           ;Adresse in Di
        And     Bx,111B         ;Dx:= Dx mod 8
        Mov     Bl,Byte PTR CS:Table[Bx] ;Zu setzender Punkt in BX
        Mov     Dx,GGOut        ;Ausgang zur Grafikkarte
        Mov     Es,GGSeg
        Mov     Si,GGSta        ;Adresse des 1.Statusbytes der Grafik
        Mov     Al,Es:[Si]      ;Byte in Al
        And     AL,0cH
        Or      AL,01H          ;Signal für Grafik
        Out     Dx,Al           ;Ausgabe
        Mov     Cx,0e000H       ;Grafikspeichersegment
        Mov     Es,Cx
        Or      Es:[Di],Bl      ;Punktsetzen
Ende:   Pop     Bp              ;Frame Pointer setzen
        Ret     4               ;zurück
Table:  DB      10000000B
        DB      01000000B
        DB      00100000B
        DB      00010000B
        DB      00001000B
        DB      00000100B
        DB      00000010B
        DB      00000001B
Dot     EndP
Grafik  EndS
        End
