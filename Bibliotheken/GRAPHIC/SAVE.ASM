; MS-Macro-Assembler V1.1 /Wang PC004
;  (c) Ulrich Berntien .08.1985
; Function Save(Var Name :String): Boolean;
;  Der Grafikbildschirm wird unter der Bezeichnung NAME abgespeichert.
;  Tritt ein Fehler bei der Abarbeitung des Unterprogrammes auf, wird
;  der Wert FALSE zurückgegeben.

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
 Public  Save

Save    Proc Far
        Push    Bp              ;Frame Pointer retten
        Mov     Bp,Sp           ;Bp auf Stack zeigen
        Mov     Dx,6[Bp]        ;Adresse des Strings in Dx
        Mov     Bx,Dx           ;auch in Bx
        Mov     Si,8[Bp]        ;Länge in Si
        Xor     Di,Di           ;Di:= 0
        XChg    [Bx+Si],Di      ;Schlußbyte =0
        Xor     Cx,Cx           ;no protection
        Mov     Ah,3cH          ;Funktionsnummer für File erstellen
        Int     21H             ;Betriebssystem Aufruf
        XChg    [Bx+Si],Di      ;orginal Bytes
        Jc      false1          ;Fehler bei Eröffnung?
        Mov     Bx,Ax           ;file handle nach Bx
        Mov     Di,GGOut        ;Ausgangs-Nr. für Grafikkarte in Di sichern
        Mov     Es,GGSeg        ;Speicheradresse des SIB
        Mov     Bp,GGSta        ;Adresse des 1. Statusbytes der Grafik
        Mov     Al,Es:[Bp]      ;Byte in Al
        And     Al,0cH          ;Bitmaske
        Or      Al,01H          ;Signal für Grafikkarte
        Mov     Si,Ax           ;in Si sichern
        Mov     Ax,Ds           ;Datensegment in
        Mov     Es,Ax           ;Extrasegment sichern
        Mov     Ax,0e000H       ;Speichersegment für Grafik
        Mov     Ds,Ax           ;in Datensegment
        Xor     Dx,Dx           ;bei erstem Byte beginnen
        Mov     Cx,50           ;immer 50 Bytes übertragen
Mark1:  XChg    Dx,Di           ;Ausgabe für Grafikkarte
        Mov     Ax,Si           ;Signalbyte für Grafikkarte
        Out     Dx,Al           ;an Karte senden
        XChg    Dx,Di           ;Zeiger wieder in Dx
        Mov     AH,40H          ;Funktionsnummer für Schreiben in File
        Int     21H             ;Betriebsystem Aufruf
        Jc      false2          ;fehlerhaftes Abspeichern?
        Add     Dx,Cx           ;nächste 50 Bytes
        Cmp     Dx,30000        ;letzte Bytes gspeichert?
        Jl      Mark1           ;nein
        Mov     Ah,3eH          ;Funktionsnummer für File schließen
        Int     21H             ;Betriebsfunktions Aufruf
        Jc      false2          ;Fehler beim Schließen
        Mov     Al,01           ;True zurückgeben
Ende2:  Mov     Cx,Es           ;Extrasegment = Datensegment(log.)
        Mov     Ds,Cx           ;in Datensegment
Ende1:  Pop     Bp              ;Frame Pointer wiederholen
        Ret     2               ;Rücksprung
False2: Xor     Al,Al           ;False Ausgeben
        Jmp     Ende2
False1: Xor     Al,Al           ;False ausgeben
        Jmp     Ende1
Save    EndP
Grafik  EndS
        End
