; MS-Macro-Assembler V1.1 /Wang PC
;  (c) Ulrich Berntien .02.1987
; Procedure Invert;
;  Der Grafikbildschirm wird invertiert.

Data    Segment Public  'Data'
 DGroup  Group Data
 Assume  Ds:DGroup
 Extrn   GGSeg:Word ,GGSta:Word ,GGOut:Word
                 ;GGSeg =Segment des Sreen Information Block
                 ;GGSta =Adresse des ersten Status Bytes
                 ;GGOut =Ausgabeanschluß für Grafikkarte
Data    EndS

Grafik  Segment Public 'Code'
 Assume  Cs:Grafik
 Public  Invert

Invert  Proc Far
        Mov     Di,Bp           ;Frame Pointer retten
        Mov     Dx,GGOut        ;Ausgangs-Nr. für Grafikkarte in Dx
        Mov     Es,GGSeg        ;Speicheradresse des SIB
        Mov     Bp,GGSta        ;Adresse des 1. Statusbytes der Grafik
        Mov     Al,Es:[Bp]      ;Byte in Al
        And     Al,0cH          ;Bitmaske
        Or      Al,01H          ;Signal für Grafikkarte
        Mov     Si,Ds           ;Datensegment in Si sichern
        Mov     Cx,0e000H       ;Speichersegment für Grafik
        Mov     Ds,Cx           ;in Datensegment
        Mov     Bx,30000        ;bei letzten Byte beginnen
Mark:   Out     Dx,Al           ;Freigabe an Karte senden
     x=0
     Rept 10
        Not     Word ptr [Bx-X]   ;invertieren
     X=X+2
     EndM
        Sub     Bx,20           ;20 Bytes weiter
        jge     Mark            ;Schleife
        Mov     Ds,Si           ;Datensegment herstellen
        Mov     Bp,Di           ;Frame Pointer herstellen
        Ret                     ;Rücksprung
Invert  EndP
Grafik  EndS
        End
