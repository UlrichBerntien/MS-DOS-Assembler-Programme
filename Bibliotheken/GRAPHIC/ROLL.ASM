; MS-Macro-Assembler V1.1 /Wang PC
;  (c) Ulrich Berntien .02.1987
; Procedure Roll( R :Integer );
;  Der Grafikbildschirm wird gerollt
;  1 - up , 2 - right , 3 - down , 4 - left

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
 Public  Roll

Roll    Proc Far
        Push    Bp              ;Frame Pointer retten
        Mov     Dx,GGOut        ;Ausgangs-Nr. für Grafikkarte in Dx
        Mov     Es,GGSeg        ;Speicheradresse des SIB
        Mov     Bp,GGSta        ;Adresse des 1. Statusbytes der Grafik
        Mov     Al,Es:[Bp]      ;Byte in Al
        And     Al,0cH          ;Bitmaske
        Or      Al,01H          ;Signal für Grafikkarte
        Mov     Si,Ds           ;Datensegment in Si sichern
        Mov     Cx,0e000H       ;Speichersegment für Grafik
        Mov     Ds,Cx           ;in Datensegment
        Xor     Bx,Bx           ;bei erstem Byte beginnen
        Mov     Bp,Sp           ;auf Stack
        Mov     Ah,6[Bp]        ;Parameter einladen
        Cmp     Ah,1            ;up ?
        Jne     N3
        Jmp     Up
N3:     Cmp     Ah,3            ;down ?
        Jne     N4
        Jmp     down
N4:     Jmp     ende

Up:     Mov     Bx,98           ;Am Ende beginnen
L1u:    Out     Dx,Al           ;Signal an Grafikkarte
        X=0
        Rept 5
          Mov     Di,[Bx-X]     ;erste Zeile retten
          Mov     Cs:[Bx+Mem-X],Di
        X=X+2
        EndM
        Sub     Bx,10           ;10 Bytes weiter
        Jg      L1u             ;bis bei erstem Word
        Mov     Bx,100          ;zweite Zeile
        Mov     Cx,1500-5       ;Zahl der restliche Zeilen /10
L2u:    Out     Dx,Al           ;Signal an Grafikkarte
        X=0
        Rept 10
          Mov     Di,[Bx+X]     ;Word in höhere Zeile
          Mov     [Bx-100+X],Di
        X=X+2
        EndM
        Add     Bx,20           ;20 Bytes Weiter
        Loop    L2u             ;zälen in Cx
        Mov     Bx,29998        ;Ende der letzen Zeile
        Mov     Cx,10           ;50 Words per line /5
L3u:    Out     Dx,Al           ;Signal an Grafikkarte
        X=0
        Rept 5
          Mov     Di,Cs:[Bx+Mem-29900-X] ;erste Zeile übertragen
          Mov     [Bx-X],Di
        X=X+2
        EndM
        Sub     Bx,10           ;10 Bytes weiter
        Loop    L3u             ;zählen in Cx
        Jmp     Ende            ;fertig mit UP

down:   Mov     Bx,29998        ;Ende der letzen Zeile
        Mov     Cx,10           ;50 Words per line /5
L1d:    Out     Dx,Al           ;Signal an Grafikkarte
        X=0
        Rept 5
          Mov     Di,[Bx-X]     ;letzte Zeile retten
          Mov     Cs:[Bx+Mem-29900-X],Di
        X=X+2
        EndM
        Sub     Bx,10           ;10 Bytes weiter
        Loop    L1d             ;zählen in Cx
L2d:    Out     Dx,Al           ;Signal an Grafikkarte
        X=0
        Rept 10
          Mov     Di,[Bx-X]     ;Word in tiefere Zeile
          Mov     [Bx+100-X],Di
        X=X+2
        EndM
        Sub     Bx,20           ;20 Bytes weiter
        Jg      L2d             ;bis Anfang erster Zeile
        Mov     Bx,98           ;Ende erster Zeile
L3d:    Out     Dx,Al           ;Signal an Grafikkarte
        X=0
        Rept 5
          Mov     Di,Cs:[Bx+Mem-X] ;erste Zeile übertragen
          Mov     [Bx-X],Di
        X=X+2
        EndM
        Sub     Bx,10           ;10 Bytes weiter
        Jg      L3d             ;bis Anfang der Zeile
        Jmp     Ende            ;fertig mit Down

Ende:   Mov     Ds,Si           ;Datensegment herstellen
        Pop     Bp              ;Frame Pointer herstellen
        Ret     2               ;Rücksprung

Mem     DW 50 Dup (?)

Roll    EndP
Grafik  EndS
        End
