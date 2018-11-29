; MS-Macro-Assembler V1.1 /Wang PC mit 8087
;  (c) Ulrich Berntien .07.1988
; Pseudozufallszahlengenerator
;  Function RND4 : Real4;

Schrift Segment Public 'User'
 Assume Cs: Schrift, Ds: Schrift
 Public RND4

RND4    Proc Far
        Mov     Ax,Cs
        Mov     Si,Ds
        Mov     Ds,Ax           ;Ds auf Code Segment
        Mov     Ax,I1
        Mov     Dx,Ax
        Mov     Bx,I1+2
        Mov     Cx,I2+2
        Add     Ax,Cx
        Adc     Bx,I2           ;beide alte Werte aufaddieren
        Mov     I2+2,Ax
        Mov     I1,Bx
        And     Bh,01111111B    ;Absolutwert
        Mov     I2+4,Bx
        DB      0DBH,006H       ;FILD DWord PTR [IA]
        DW      Offset I2+2
        Mov     I1+2,Cx
        Wait
        DB      0DAH,036H       ;FIDIV DWord PTR [IM]
        DW      Offset IM
        Mov     I2,Dx
        Mov     Ds,Si           ;Ds wieder auf das Datensegment
        Mov     Ax,Bp           ;Frame Pointer sichern
        Mov     Bp,Sp           ;Bp auf Stack
        Mov     Si,[Bp+04]      ;Speicherzelle für Rückgabe
        Wait
        DB      0D9H,01CH       ;FSTP DWord PTR [SI]
        Mov     Bp,Ax           ;Frame Pointer zurück
        Mov     Ax,Si           ;Adresse des übergeben Werts
        Wait
        Ret     2               ;zurück und Stack säubern
RND4    EndP

I1      equ This Word
        DB 'anja'               ;Initialwerte
I2      equ This Word
        DB 'strm'
        DW (?)                  ;Zwischenspeicher für die Summe
IM      DD 7FFFFFFFH            ;Maxint4

Schrift EndS
        End
