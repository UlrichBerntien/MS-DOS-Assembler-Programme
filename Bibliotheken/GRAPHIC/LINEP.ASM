; MS-Macro-Assembler V1.10 /Wang PC004
;  (c) Ulrich Berntien .02.1986
; Procedure LineP( X1,Y1,X2,Y2 :Integer );
; Zieht eine Linie von Punkt( X1,Y1 ) nach Punkt( X2,Y2 )

Data    Segment Public  'Data'
 DGroup  Group Data
 Assume  DS:DGroup
 Extrn   GGSeg:Word ,GGSta:Word ,GGOut:Word
                ;GGSeg =Segment des Sreen Information Block
                ;GGSta =Adresse des ersten Status Bytes
                ;GGOut =Ausgabeanschluß für Grafikkarte
        EVEN
 mem    DW (?)
Data    EndS

Grafik  Segment Public 'Code'
 Assume Cs : Grafik
 Public LineP

; Variablen XS    YS    X1  X2  Y1  Y2  XD   YD  S  dP
; Register  Ah 1B Ah 2B                 mem  Cx  Si Bp

LineP   Proc Far
        Push    Bp              ;Frame Pointer retten
        Mov     Bp,Sp           ;Bp auf Stack zeigen
        Mov     Dx,12[Bp]       ; X1 - Dx
        Mov     Cx,10[Bp]       ; Y1 - Cx
        Mov     Ax,08[Bp]       ; X2 - Ax
        Mov     Si,06[Bp]       ; Y2 - Si
        Cmp     Cx,0            ;Bereichskontrollen
        Jl      Ende            ; X := 0 - 799
        Cmp     Dx,0            ; Y := 0 - 299
        Jl      Ende
        Cmp     Ax,0
        Jl      Ende
        Cmp     Si,0
        Jl      Ende
        Cmp     Dx,799
        Jg      Ende
        Cmp     Cx,299
        Jg      Ende
        Cmp     Ax,799
        Jg      Ende
        Cmp     Si,300
        Jl      Weiter
Ende:   Pop     Bp              ;Frame Pointer herstellen
        Ret     8               ;zurück und säubern
Weiter: Sal     Cx,1            ;Di := Cx * 100
        Sal     Cx,1            ;schneller als Mul-Befehl
        Mov     Ax,Cx           ;durch '*2' und '+'
        Sal     Cx,1            ;errechnen des Zeilenoffset
        Sal     Cx,1
        Add     Ax,Cx
        Mov     Di,Ax
        Sal     Ax,1
        Sal     Ax,1
        Add     Di,Ax
        Mov     Bx,Dx           ;X1 in Bx
        Sar     Dx,1            ;dreimal schieben
        Sar     Dx,1            ;entsprich div. 8
        Sar     Dx,1
        And     Dl,0feH         ;in 16er Schritten
        Add     Di,Dx           ;Adresse in Di
        And     Bx,1111B        ;Bx:= Bx mod 16
        Sal     Bx,1            ;mal 2 für Wordadresse
        Mov     Bx,CS:Table[Bx] ;Zu setzender Punkt in Bx
        Mov     Es,GGSeg
        Mov     Si,GGSta        ;Adresse des 1.Statusbytes der Grafik
        Mov     Al,Es:[Si]      ;Byte in Al
        And     AL,0cH
        Or      AL,01H          ;Signal für Grafik
        Mov     Cx,0e000H       ;Grafikspeichersegment
        Mov     Es,Cx
        Mov     Si,0            ;S:=0
        Mov     Ah,11B          ;xs:=1  ys:=1
        Mov     Dx,08[Bp]       ;xd:=X2-X1
        Sub     Dx,12[Bp]
        Jnz     Lab1
        Dec     Si              ;If X1=X2 then S:=-1
        Jmp     Lab2
Lab1:   Jg      Lab2
        And     Ah,10B          ;If xd <0 then xs:=-1
        Neg     Dx              ;              xd:=-(xd)
Lab2:   Mov     Cx,06[Bp]       ;yd:= Y2-Y1
        Sub     Cx,10[Bp]
        Jge     Begin
        And     Ah,01B          ;If yd <0 then ys:=-1
        Neg     Cx              ;              yd:=-(yd)
Begin:  Mov     Bp,Dx
        Add     Bp,Cx           ;Zahl der Punkte im
        Mov     mem,Dx          ;xd abspeichern
        Mov     Dx,GGout        ;Dx für Grafik-Out
Loop:   Out     Dx,Al           ;Signal
        Or      Es:[Di],Bx      ;Punkt setzen
        Dec     Bp              ;ein Punkt weniger
        Jl      Ende            ;alle gesetzt
        Cmp     Si,0
        Jge     Else            ;If s<0 then
        Add     Si,mem          ;  S:=S+xd
        Test    Ah,10B          ;Richtung ?
        Jz      up
down:   Add     Di,64H          ;eine Zeile tiefer
        Jmp     Loop
up:     Sub     Di,64H          ;eine Zeile höher
        Jmp     Loop
Else:   Sub     Si,Cx           ;  S:=S-yd
        Test    Ah,01B          ;Richtung ?
        Jz      left
right:  Ror     Bx,1            ;ein Punkt nach rechts
        Jnc     Loop            ;in nächstes Word
        Inc     Di              ;Adresse um ein Wort höher
        Inc     Di
        Jmp     Loop
left:   Rol     Bx,1            ;ein Punkt nach links
        Jnc     Loop            ;in nächstes Word
        Dec     Di              ;Adresse um ein Word tiefer
        Dec     Di
        Jmp     Loop
        EVEN
Table:  DW      1000000000000000B
        DW      0100000000000000B
        DW      0010000000000000B
        DW      0001000000000000B
        DW      0000100000000000B
        DW      0000010000000000B
        DW      0000001000000000B
        DW      0000000100000000B
        DW      0000000010000000B
        DW      0000000001000000B
        DW      0000000000100000B
        DW      0000000000010000B
        DW      0000000000001000B
        DW      0000000000000100B
        DW      0000000000000010B
        DW      0000000000000001B
LineP   EndP
Grafik  EndS
        End
