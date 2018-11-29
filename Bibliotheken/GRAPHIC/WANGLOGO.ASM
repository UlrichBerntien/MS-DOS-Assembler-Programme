; MS-Macro Assembler V1.1 /Wang PC
; (c) Ulrich Berntien .03.1987
; benutzt WangLogo.Pic

Extrn  Load :Far, Roll :Far, Invert :Far, Graphic :Far
DGroup Group Data, Stack
Assume Cs : Prog
Assume Ds : DGroup
Assume Ss : DGroup

Prog    Segment Public 'Code'

Start:  Mov     Ax,Seg DGroup           ;Datensegment
        Mov     Ds,Ax
        Call    Graphic                 ;Screen output
        Mov     Ah,09                   ;String Out
        Mov     Dx,Offset DGroup: Text
        Int     21H                     ;DOS-Call
        Mov     Ax,Offset DGroup:FileN
        Push    Ax
        Call    Load                    ;Picture laden
        Cmp     Al,01                   ;true ?
        Je      L1                      ; ja,weiter
        Mov     Ah,09                   ;String Out
        Mov     Dx,Offset DGroup: ErrT
Ende:   Int     21H                     ;DOS-Call
        Mov     Ah,4CH                  ;Return
        Int     21H                     ;DOS-Call
L1:     Mov     Ah,06                   ;Direct console I/O
        Mov     Dl,0FFH                 ;Character input
        Int     21H                     ;DOS-Call
        Cmp     Al,3                    ;KTRL-C
        Je      Ende
        Cmp     Al,'2'                  ;Blinken schalten ?
        Jne     O1                      ; nein
        Not     Blink                   ; ja
O1:     Cmp     Al,'1'                  ;nach unten ?
        Jne     O2                      ; nein
        Mov     Richt,3                 ; ja
O2:     Cmp     Al,'4'                  ;stoppen ?
        Jne     O3                      ; nein
        Mov     Richt,0                 ; ja
O3:     Cmp     Al,'7'                  ;nach oben ?
        Jne     M1                      ; nein
        Mov     Richt,1                 ; ja
M1:     Cmp     Blink,0                 ;Invertieren ?
        Je      M2                      ; nein
        Call    Invert
M2:     Cmp     Richt,0                 ;rollen ?
        Je      L1                      ; nein
        Push    Richt
        Call    Roll
        Jmp     L1                      ;Schleife
Prog    EndS

Data    Segment Word Public 'Data'

Blink   DW 0
Richt   DW 0
ErrT    DB 13,10,'Fehler beim laden von WangLogo.Pic',13,10,'$'
FileN   DB 'WANGLOGO.PIC', 0
Text    DB 12,9,9,'Tasten : 1,4,7,2, KTRL/C',27,'[5h$'
Data    EndS

Stack   Segment Word Stack 'Stack'
        DB 200 Dup (?)
Stack   EndS

        End     Start                   ;Start Label
