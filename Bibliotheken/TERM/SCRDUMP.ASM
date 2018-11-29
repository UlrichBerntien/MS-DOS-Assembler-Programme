; MS-Macro-Assembler V1.1 /Wang PC
;  (c) Ulrich Berntien .07.1988
; Procedure SCRDump;
;  Ausdrucken des Bildschirminhalts (ohne Attribute)

Data    Segment Public 'Data'
 DGroup Group Data
 Assume Ds :DGroup
 Extrn  TTSIB :DWord            ;Segment&Adresse des Screen Information Blocks
Data    EndS

Schrift Segment Public 'Code'
 Assume Cs :Schrift
 Public SCRDump

SCRDump Proc Far
        Mov     Dl,13           ;Carrige return
        Mov     Ah,Bh           ;Print Character
        Int     21H             ;DOS-Call
        Mov     Dl,10           ;Line feed
        Mov     Ah,Bh           ;Print Character
        Int     21H             ;DOS-Call
        LES     Bx,TTSIB        ;Adresse des Sreen Information Blocks
        Mov     Dh,Es:[Bx+13H]  ;High Byte von Anschluß
        Mov     Dl,10H          ;Low Byte des Anschluß
        Mov     Si,Dx           ;in Si sichern
        Mov     Bl,Es:[Bx+08H]  ;1.Statusbyte
        And     Bl,0CH          ;Byte in Bl aufbereiten
        Or      Bl,01H
        Mov     Ax,0f000H       ;Segment des Bildschirmspeichers
        Mov     Es,Ax           ;in Es laden
        Xor     Di,Di           ;Pointer während der Ausgabe
        Mov     Bh,05H          ;Code für Druckerausgabe
L1:     Mov     Cx,79           ;Spalten 1..79 ausdrucken nicht 80
L2:     Mov     Dx,Si           ;Port für Bildschirmspeicherfreigabe
        Mov     Al,Bl           ;Signal für die Freigabe
        Out     Dx,Al           ;senden
        Mov     Dx,Es:[Di]      ;Byte lesen
        Mov     Dl,Dh
        Cmp     Dl,0            ;Nil-Zeichen ?
        Jne     NNil            ; nein
        Mov     Dl,' '          ;Leerzeichen
NNil:   Inc     Di              ;auf nächstes Zeichen
        Inc     Di
        Mov     Ah,Bh           ;Print Character
        Int     21H             ;DOS-Call
        Loop    L2              ;wiederhole bis Spalte fertig
        Inc     Di              ;in nächste Spalte
        Inc     Di
        Mov     Dl,13           ;Carrige return
        Mov     Ah,Bh           ;Print Character
        Int     21H             ;DOS-Call
        Mov     Dl,10           ;Line feed
        Mov     Ah,Bh           ;Print Character
        Int     21H             ;DOS-Call
        Cmp     Di,4000         ;alle Zeilen ausgegeben ?
        Jl      L1              ;zur nächsten Zeile
        Ret

SCRDump EndP
Schrift EndS
        End
