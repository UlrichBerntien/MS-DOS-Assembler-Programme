; MS-Macro-Assembler V1.1 /Wang PC /Epson FX-80
;  (c) Ulrich Berntien .08.1986
; Procedure Print;
;  Ausgabe des Grafikbildschirm auf dem FX-80, der Bildschirminhalt wird
;  dazu um 90° gedreht, um auf ca. eine A4-Seite zu passsen

Data    Segment Public  'Data'
 DGroup  Group Data
 Assume  Ds:DGroup
 Extrn   GGSeg:Word ,GGSta:Word ,GGOut:Word
                 ;GGSeg =Segment des Sreen Information Block
                 ;GGSta =Adresse des ersten Status Bytes
                 ;GGOut =Ausgabeanschluß für Grafikkarte
 ma     DB (?)
 Zeile  DB 11 dup (?)
Data    EndS

Grafik  Segment Public 'Code'
 Assume  Cs: Grafik
 Public  Print

OutP    Proc Near               ;Ah ausgeben, Dx,Al benutzt
        Mov     Dx,1020h        ;Parallelstatus-Port
TLoop:  In      Al,Dx           ;lesen in Al
        Test    Al,10h          ;ist Busy ?
        Jnz     TLoop           ; ja
        Mov     Al,Ah
        Mov     Dx,10EAh        ;Parallelausgang
        Out     Dx,Al           ;Ausgeben
        Ret                     ;zurück
OutP    EndP

GInit   Macro
        Mov     Es,GGSeg
        Mov     Si,GGSta        ;;Adresse des 1.Statusbytes der Grafik
        Mov     Al,Es:[Si]      ;;Byte in Al
        And     AL,0cH
        Or      AL,01H          ;;Signal für Grafik
        Mov     ma,Al           ;;Speichern
        Mov     Cx,0e000H       ;;Grafikspeichersegment
        Mov     Es,Cx           ;; in Es
        Mov     Ah,27           ;;ESC ausgeben
        Call    OutP
        Mov     Ah,'1'          ;;'1' ausgeben      ESC 1 -> 7/72 inch
        Call    OutP
        Mov     Si,29900        ;;letze Zeile in erste Spalte
        Mov     Zeile+10,0      ;;Null setzten
        Inc     Si
        Mov     Al,1            ;; für Grafikword -> Druckerbyte
        Push    Ax              ;;
        EndM

GAus    Macro                   ;;Grafikausgeben( Anzahl = Cx )
Local   Lab
        Mov     Al,30           ;;mit 30 multipliziern
        Mul     Cl              ;;Zahl der Punktspalten
        Mov     Cx,Ax           ;;Ergebnis in Cx
        Mov     Ah,27           ;;ESC ausgeben
        Call    OutP
        Mov     Ah,'K'          ;;'K' ausgeben
        Call    OutP
        Mov     Ah,Cl           ;;LByte der Anzahl ausgeben
        Call    OutP
        Mov     Ah,Ch           ;;HByte der Anzahl ausgeben
        Call    OutP
Lab:    Mov     Al,ma           ;;Signalbyte für Grafikkarte
        Mov     Dx,GGout        ;;Adresse der Karte
        Out     Dx,Al           ;;Signal senden
        Mov     Ah,Es:[Di]      ;;Punktmuster lesen
        Sub     Di,64H          ;;nächste Spalte
        Call    OutP
        Loop    Lab             ;;Cx:=Cx-1 ,bis Cx=0
        EndM

BeZeile Macro
Local  Lab,LabA,LabL
        Mov     Cx,12           ;;12 Blanks ausgeben
        Mov     Bl,' '
Lab:    Mov     Ah,Bl           ;;Blank ausgeben
        Call    OutP
        Loop    Lab             ;;Cx:=Cx-1 ,bis Cx=0
        Mov     Di,Si           ;;Grafikspalte in Di
        Mov     Al,ma           ;;Signalbyte für Grafikkarte
        Mov     Dx,GGout        ;;Adresse der Karte
        Xor     Bx,Bx           ;;erste Position
LabA:   Mov     Cx,1e00H        ;;Ch:=30  /Cl:=0
LabL:   Out     Dx,Al           ;;Signal senden
        Or      Cl,Es:[Di]      ;;Punktmuster lesen
        Sub     Di,64H          ;;nächste Spalte
        Dec     Ch              ;;weiterzählen
        Jnz     LabL            ;; nein
        Mov     Zeile[Bx],Cl    ;;gelesene Punkte speichern
        Inc     Bx              ;;nächste Position
        Cmp     Bx,10           ;;fertig?
        Jne     LabA            ;; nein
        Mov     Di,Si           ;;Grafikspalte in Di
        EndM

EnZeile Macro
Local   Lab1,Lab2
        Mov     Ah,0dH          ;;CR ausgeben
        Call    OutP
        Mov     Ah,0aH          ;;LF ausgeben
        Call    OutP
        Pop     Ax
        Cmp     Al,0            ;;erst untere Adresse(Byte) ausgeben
        Jz      Lab1            ;; dafür die Rückschritte
        Dec     Si
        Dec     Al              ;;Al:=0
        Jmp     Lab2
Lab1:   Add     Si,3            ;;nächste Spalte
        Inc     Al              ;;Al:=1
Lab2:   Push    Ax
        EndM

Print   Proc Far
        GInit
LabB:   BeZeile
        Xor     Bx,Bx           ;erste Position
        Xor     Cx,Cx           ;Cx:=0
LabZ:   Cmp     Zeile[Bx],0     ;keine Punkte?
        Jne     LabT            ; nein
        Mov     Cx,5            ;5 Blanks ausgeben
Lab:    Mov     Ah,' '          ;Blank ausgeben
        Call    OutP
        Loop    Lab             ;Cx:=Cx-1 ,bis Cx=0
        Sub     Di,64H*30       ;Grafikadresse mitführen
        Inc     Bx              ;nächste Position
        Jmp     LabW            ;weiter
LabT:   Inc     Bx              ;nächste Position
        Inc     Cx
        Cmp     Zeile[Bx],0     ;keine Punkte?
        Jne     LabT            ; ja
        GAus                    ;die Positionen ausgeben
LabW:   Cmp     Bx,10           ;letzte Position ?
        Jne     LabZ            ; nein
        EnZeile                 ; ja
        Cmp     Si,30000        ;letzte Spalte?
        Jge     LabE            ; ja
        Jmp     LabB            ; nein  /LabB zu weit für Jl
LabE:   Mov     Ah,27           ;ESC ausgeben
        Call    OutP
        Mov     Ah,'2'          ;'2' ausgeben      ;ESC 2 -> 1/6 inch
        Call    OutP
        Pop     Ax              ;Stack säubern
        Ret                     ;zurück
Print   EndP

Grafik  EndS
        End
