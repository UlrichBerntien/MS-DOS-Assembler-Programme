; MS-Macro-Assembler V1.1 /Wang PC
;  (c) Ulrich Berntien .01.1986
; Procedure Term;
; Die Prozedure wird durch das Interface 'Term.Pin' aufgerufen.
; Sie stellt für folgende Prozeduren die Variablen TT? zur Verfügung,
; löscht den Bilschirm, löscht alle Attribut, lehrt den Tastaturbuffer
; und schaltet den Cursor ein.

Data    Segment Public 'Data'
 DGroup Group Data
 Assume Ds: DGroup
 Public TTSIB, TTSta, TTOut
 TTSIB  DW (?)          ;Segment + Adresse des Screen Information Blocks
        DW (?)
 TTSta  DW (?)
 TTOut  DW (?)
Data    EndS

Schrift Segment Public 'Code'
 Assume CS: Schrift
 Public Term

Term    Proc Far
        Mov     Ax,0C00h        ;keyboard buffer flush
        Int     21h             ;DOS call
        Mov     Ax,0606h        ;clear screen + home
        Mov     Bx,000Ch
        Int     88h             ;BIOS call
        Mov     Al,Ah           ;ESC '[z' ausgeben
        Mov     Bl,01Bh
        Int     88h             ;BIOS call
        Mov     Al,Ah
        Mov     Bl,'['
        Int     88h             ;BIOS call
        Mov     Al,Ah
        Mov     Bl,'z'
        Int     88h             ;BIOS call
        Mov     Al,01           ;Zeiger zum system configuration table
        Int     88h             ;BIOS call
        Mov     TTSIB+2,Es      ;Speichern des Segments
        Mov     Bx,Es:[Bx+0Ah]  ;Adresse des SIB
        Mov     TTSIB,BX        ;und abspeichern
        Mov     Byte PTR Es:[Bx+07],00   ;Attribute löschen
        Mov     Dh,Es:[Bx+13H]  ;High Byte von Anschluß
        Mov     Dl,10H          ;Low Byte
        Mov     TTOut,Dx        ;Portnummer speichern
        Add     Bx,8            ;Zeiger auf Statusbyte der Karte
        Mov     TTSta,Bx        ;abspeichern
        Ret                     ;zurück
Term    EndP
Schrift EndS
        End
