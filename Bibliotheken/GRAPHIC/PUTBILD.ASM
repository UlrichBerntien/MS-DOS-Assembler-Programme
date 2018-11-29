; MS-Macro-Assembler V1.1 /Wang PC004
;  (c) Ulrich Berntien .03.1986
; Procedure PutBild( Var  GDaten : Bild;
;                         X,Y    : Integer );
; Die Funktion gibt ein Punktmuster auf den Grafikbildschirm mit Hilfe einer
; XOR-Operation aus, d.h. dort wo im Bild ein Punkt gesetzt ist wird der
; Punkt auf dem Grafikbildschirm invertiert. Die Koordinate X,Y bezieht
; sich auf den linken oberen Punkt des Bildes. Im GDaten-Array bedeutet:
;  GDaten[1] = Breite des Bildes in 16er !! Punkten
;  GDaten[2] = Höhe des Bildes ,max. 256 Zeilen
;  GDaten[.] = Bildpunkte ,Zeilenweise

Data    Segment Public  'Data'
 DGroup  Group Data
 Assume  DS:DGroup
 Extrn   GGSeg:Word ,GGSta:Word ,GGOut:Word
                ;GGSeg =Segment des Sreen Information Block
                ;GGSta =Adresse des ersten Status Bytes
                ;GGOut =Ausgabeanschluß für Grafikkarte
        EVEN
MaskH   DW ?    ;Masken zum selektieren der Punkte
MaskL   DW ?    ;in den zwei Wörtern
MemA    DW ?
MemS    DB ?
SchH    DB ?    ;Anzahl der Verschiebungen
SchL    DB ?    ;zur Positionierung
Data    EndS

Grafik  Segment Public 'Code'
 Assume  CS: Grafik
 Public  PutBild

PutBild Proc Far
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
        Jge     Weiter          ;ungültige Spalte
Ende:   Pop     Bp              ;Frame Pointer setzen
        Ret     8               ;zurück
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
        Mov     Dx,Bx           ;Spalte in Dx
        Sar     Dx,1            ;dreimal schieben
        Sar     Dx,1            ;entsprich div. 8
        Sar     Dx,1
        And     Dl,0feH         ;in 16er Schritten
        Add     Di,Dx           ;Adresse in Di
        And     Bx,1111B        ;Bx:= Bx mod 16
        Mov     SchH,Bl         ;nach rechts schieben MSW
        Mov     Al,16
        Sub     Al,Bl           ;SchL:=16-SchH
        Mov     SchL,Al         ;nach links schieben LSW
        Sal     Bx,1            ;mal 2, für Wordadressen
        Mov     Bx,Cs:Table[Bx] ;Punktmaske
        Mov     MaskH,Bx        ;für MSW
        Not     Bx              ;invertieren
        Mov     MaskL,Bx        ;für LSW
        Mov     Dx,GGOut        ;Signalkanal holen
        Mov     Es,GGSeg
        Mov     Si,GGSta        ;Adresse des 1.Statusbytes der Grafik
        Mov     Al,Es:[Si]      ;Byte in Al
        And     AL,0cH
        Or      AL,01H          ;Signal für Grafik
        Mov     Cx,0e000H       ;Grafikspeichersegment
        Mov     Es,Cx
        Mov     Si,10[Bp]       ;Si auf GDaten-Array
        Mov     Bx,[Si]         ;Zahl der Spalten
        Mov     MemS,Bl         ; in MemS
        Sal     Bx,1            ;mal zwei
        Mov     Cx,64H          ;Zeilenoffset in Cx
        Sub     Cx,Bx           ;errechenen für Addition
        Mov     MemA,Cx         ; in MemA
        Mov     Ch,2[Si]        ;Zahl der Zeilen
        Inc     Si              ;Si auf erstes Punktdatenwort -2
        Inc     Si
Zeile:  Mov     Ah,MemS         ;erste Spalte
        XOr     Bp,Bp           ;Bp wird als Punktübertrag genutzt
Spalte: Inc     Si              ;auf erstes Punktdatenwort
        Inc     Si
        Mov     Bx,MaskH
        And     Bx,[Si]         ;Punktmuster in Bx
        Mov     Cl,SchH
        Shr     Bx,Cl           ;verschieben
        Or      Bx,Bp           ;alte Punkte dazu
        Out     Dx,Al           ;Ausgabe
        XOr     Es:[Di],Bx      ;Punkte invertieren
        Mov     Bx,MaskL
        And     Bx,[Si]         ;Punktmuster in Bx
        Mov     Cl,SchL
        Shl     Bx,Cl           ;verschieben
        Mov     Bp,Bx           ;Bildpunkte merken
        Inc     Di              ;ein Wort weiter
        Inc     Di
        Dec     Ah
        Jnz     Spalte          ; nein
        Out     Dx,Al           ;Ausgabe
        XOr     Es:[Di],Bx      ;Punkte invertieren
        Add     Di,MemA         ;eine Zeile tiefer
        Dec     Ch              ;Zeilenzähler
        Jnz     Zeile           ; nein
        Pop     Bp              ;Frame Pointer setzen
        Ret     8               ;zurück

        EVEN
Table:  DW      1111111111111111B
        DW      1111111111111110B
        DW      1111111111111100B
        DW      1111111111111000B
        DW      1111111111110000B
        DW      1111111111100000B
        DW      1111111111000000B
        DW      1111111110000000B
        DW      1111111100000000B
        DW      1111111000000000B
        DW      1111110000000000B
        DW      1111100000000000B
        DW      1111000000000000B
        DW      1110000000000000B
        DW      1100000000000000B
        DW      1000000000000000B
        DW      0000000000000000B
PutBild EndP
Grafik  EndS
        End
