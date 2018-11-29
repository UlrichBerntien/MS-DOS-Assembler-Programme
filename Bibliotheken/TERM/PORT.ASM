; MS-Macro-Assembler V1.1 /Wang PC
;  (c) Ulrich Berntien .08.1986
;      letzte Änderung .06.1988
; Procedure WriteP( Was : Char );
;   Direkte Ausgabe des Charakters Was auf dem Parallelausgang. Vor der Ausgabe
;   wird auf das BUSY-signal des Druckers gewartet.
; Procedure ReadP : Byte;
;   Liest das Statusbyte der Parallelschnittstelle ein. Es begeuten:
;   Bit 4 (10h) = Busy
;   Bit 5 (20h) = negiertes Acknowlage
;   Bit 6 (40h) = End of Paper [meist zusammen mit Busy]
; Procedure PortOut( Nr : Word; x : Byte );
;   Gibt x auf den Ausgang Nr

Schrift Segment Public  'Code'
 Assume Cs : Schrift
 Public WriteP, ReadP, PortOut

WriteP  Proc Far
        Pop     Di              ;Rücksprungadresse
        Pop     Si
        Mov     Dx,1020h        ;Parallelstatus-Port
Lab:    In      Al,Dx           ;lesen in Al
        Test    Al,10H          ;ist Busy ?
        Jnz     Lab             ; ja
        Mov     Dx,10EAh        ;Parallelausgang
        Pop     Ax              ;Was in Al
        Out     Dx,Al           ;Ausgeben
        Push    Si
        Push    Di
        Ret                     ;zurück
WriteP  EndP

ReadP   Proc Far
        Mov     Dx,1020h        ;Parallelstatus-Port
        In      Al,Dx           ;lesen in AL
        Ret                     ;zurück
ReadP   EndP

PortOut Proc Far
        Pop     Di              ;Rücksprungadresse
        Pop     Si
        Pop     Ax              ;Wert
        Pop     Dx              ;Ausgang
        Out     Dx,Al           ;Ausgeben
        Push    Si
        Push    Di
        Ret                     ;zurück
PortOut EndP

Schrift EndS
        End
