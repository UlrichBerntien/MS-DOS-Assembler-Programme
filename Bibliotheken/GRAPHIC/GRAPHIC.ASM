; MS-Macro-Assembler V1.1 /Wang PC004
;  (c) Ulrich Berntien .06.1985
; Procedure Graphic; Extern;
; Holt die nötigen Daten für die Grafikroutinen
; Die Procedure muß einmal vor benutzung der Grafik aufgerufen werden
; Sie wird bei dem Interface 'Graphic.PIn' automatisch aufgerufen

Data    Segment Public  'Data'
 DGroup Group Data
 Assume DS:DGroup
 Public GGSeg,GGSta,GGOut

        EVEN
GGSeg   DW      ?               ;Segment des Sreen Information Block
GGSta   DW      ?               ;Adresse des 1.Status Bytes
GGOut   DW      ?               ;Ausgabeanschluß für Grafikkarte

Data    EndS

Grafik  Segment Public 'Code'
 Public Graphic

Graphic Proc Far
        Mov     Al,01
        Int     88h             ;Zeiger auf System Information Block
        Mov     GGSeg,ES        ;Segment abspeicher
        Mov     Si,ES:[Bx+0Ah]  ;Zeiger auf Sreen Information Block
        Mov     Dh,ES:[Si+13h]  ;High Byte von Anschluß
        Mov     Dl,10h          ;Low Byte von Anschluß
        Mov     GGOut,Dx        ;Anschlußnummer abspeicher
        Add     Si,8h           ;Zeiger auf Statusbyte der Karte
        Mov     GGSta,Si        ;abspeichern
        Ret
Graphic EndP
Grafik  EndS

        End
