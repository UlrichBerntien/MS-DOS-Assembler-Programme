; MS-Macro-Assembler V1.1 /Wang PC
;  (c) Ulrich Berntien .03.1987
; Procedure PutChar( x,y :Integer, c :Char, a :Attribute );
;   Setzt das Zeichen c mit den Attributen a an die Stelle
;   (x,y) des Bildschirmspeichers
; Procedure PutATTR( x,y :Integer, a :Attribute );
;   Gibt dem Zeichen auf der Position (x,y) im Bildschirm-
;   speicher die Attribute a
; Function GetChar( x,y :Integer ): Char;
;   Liest das Zeichen an der Position (x,y) in dem Bild-
;   schirmspeicher

Data    Segment Public  'Data'
DGroup  Group Data
Assume DS:DGroup
Extrn   TTSib:Word ,TTSta:Word ,TTOut:Word
                ;TTSib+2 =Segment des Sreen Information Block
                ;TTSta =Adresse des ersten Status Bytes
                ;TTOut =Ausgabeanschluß für Grafikkarte
Data    EndS

Schrift Segment Public 'Code'
 Assume  CS: Schrift
 Public  GetChar, PutChar, PutATTR

Pos     Proc Near               ;x in Dl / y in Dh => ADR in Bx
        Dec     Dl              ;Testen auf Größe
        Jl      bad
        Dec     Dh
        Jl      bad
        Cmp     Dl,79
        Jg      bad
        Cmp     Dh,24
        Jg      bad
        Xor     Bh,Bh           ;Bh:= 0
        Mov     Bl,Dh           ;Bx:= Y
        Sal     Bl,1
        Sal     Bl,1            ;Bx:= Bx * 4
        Add     Bl,Dh           ;Bx:= Bx * 5
        Sal     Bx,1
        Sal     Bx,1
        Sal     Bx,1
        Sal     Bx,1            ;Bx:= Bx * 80
        XOr     Dh,Dh           ;Dx:= X
        Add     Bx,Dx           ;Bx:= Bx + X
        Sal     Bx,1
good:   ClC                     ;wenn kein Fehler
        Ret
bad:    StC                     ;bei Fehler
        Ret
Pos     EndP


PutChar Proc Far
        Push    Bp              ;Frame Pointer rettern
        Mov     Bp,Sp           ;Bp auf Stack
        Mov     Dh,10[Bp]       ;Dh:= y
        Mov     Dl,12[Bp]       ;Dl:= x
        Call    Pos             ;Adresse berechnen
        Jc      E1              ;bei Fehler
        Mov     Cl,6[Bp]        ;Cl:= Attribut
        Mov     Ch,8[Bp]        ;Ch:= Char
        Mov     Dx,TTOut        ;Ausgang zur Monitorkarte
        Mov     Es,TTSib+2
        Mov     Si,TTSta        ;Adresse des 1.Statusbytes
        Mov     Al,Es:[Si]      ;Byte in Al
        And     AL,0cH
        Or      AL,01H          ;Signal für Monitorkarte
        Out     Dx,Al           ;Ausgabe
        Mov     Ax,0f000H       ;Bildschirmspeicher
        Mov     Es,Ax
        Mov     Es:[Bx],Cx      ;Character setzen
E1:     Pop     Bp
        Ret 8
PutChar EndP

GetChar Proc Far
        Push    Bp              ;Frame Pointer rettern
        Mov     Bp,Sp           ;Bp auf Stack
        Mov     Dh,6[Bp]        ;Dh:= y
        Mov     Dl,8[Bp]        ;Dl:= x
        Xor     Al,0            ;für Rücksprung
        Call    Pos             ;Adresse berechnen
        Jc      E2              ;bei Fehler
        Mov     Dx,TTOut        ;Ausgang zur Monitorkarte
        Mov     Es,TTSib+2
        Mov     Si,TTSta        ;Adresse des 1.Statusbytes
        Mov     Al,Es:[Si]      ;Byte in Al
        And     AL,0cH
        Or      AL,01H          ;Signal für Monitorkarte
        Out     Dx,Al           ;Ausgabe
        Mov     Ax,0f000H       ;Bildschirmspeicher
        Mov     Es,Ax
        Mov     Ax,Es:[Bx]      ;Character lesen
        Mov     Al,Ah           ;Zeichen zurückgeben
E2:     Pop     Bp
        Ret     4
GetChar EndP

PutATTR Proc Far
        Push    Bp              ;Frame Pointer rettern
        Mov     Bp,Sp           ;Bp auf Stack
        Mov     Dh,8[Bp]        ;Dh:= y
        Mov     Dl,10[Bp]       ;Dl:= x
        Call    Pos             ;Adresse berechnen
        Jc      E3              ;bei Fehler
        Mov     Dx,TTOut        ;Ausgang zur Monitorkarte
        Mov     Es,TTSib+2
        Mov     Si,TTSta        ;Adresse des 1.Statusbytes
        Mov     Al,Es:[Si]      ;Byte in Al
        And     AL,0cH
        Or      AL,01H          ;Signal für Monitorkarte
        Out     Dx,Al           ;Ausgabe
        Mov     Ax,0f000H       ;Bildschirmspeicher
        Mov     Es,Ax
        Mov     Cx,Es:[Bx]      ;Character lesen
        Mov     Cl,6[Bp]        ;Cl:= Attribut
        Mov     Es:[Bx],Cx      ;Character setzen
E3:     Pop     Bp
        Ret     6
PutATTR EndP

Schrift EndS
        End
