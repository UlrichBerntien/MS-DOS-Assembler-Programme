; MS-Macro-Assembler V1.1 /Wang PC
;  (c) Ulrich Berntien .02.1986
; Ausgabe eines Files, wobei nicht druckbare Zeichen als chr(129)
; geschrieben werden. ( CR,LF wird ausgegeben )
; Format:  LIST filename

Prog    Segment
 Assume Ds :Prog , Cs: Prog
        ORG  80H
Lab:
        ORG 100H
Start:  Cmp     Al,00                   ;Richtiger Drive ?
        Jz      Yes1
        Mov     Bp,Offset DriveF
        Jmp     Error                   ;Fehlermeldung
Yes1:   Mov     Bx,0
        Mov     Bl,Byte PTR[Lab]        ;Länge des Namens
        Add     Bx,81H                  ;letzes+1 Zeichen
        Mov     Byte PTR[Bx],0          ;-> ASCIZ-format
        Mov     Dx,82H                  ;Adresse des Namens
        Mov     Ax,3D00H                ;Open file for reading
        Int     21H                     ;DOS-Call
        Jnc     Yes2                    ;Zugriff richtig?
        Cmp     Ax,4                    ; nein,Fehlermeldung
        Jl      FoundL
        Jg      weiter
        Mov     Bp,Offset ManyF
        Jmp     Error
FoundL: Mov     Bp,Offset FoundF
        Jmp     Error
weiter: Cmp     Ax,5
        Jg      InvalL
        Mov     Bp,Offset DeniF
        Jmp     Error
InvalL: Mov     Bp,Offset InvalF
Error:  Mov     Cx,Word PTR[ErrorF-2]   ;Textlänge
        Mov     Dx,Offset ErrorF        ;Testadresse
        Mov     Bx,2                    ;Fehlerausgang
        Mov     Ah,40H
        Int     21H                     ;'ERROR ' ausgeben
        Mov     Dx,Bp                   ;Textadresse
        Mov     Cx,Ds:[Bp-2]            ;Textlänge
        Mov     Ah,40H
        Int     21H                     ;Meldung ausgeben
        Int     20H                     ;Programmabbruch
Yes2:   Mov     Dx,Offset Buffer        ; ja,File offen
        Mov     Cx,1
        Mov     Bx,Ax
        Mov     Bp,1
        XChg    Bx,Bp
Loop:   XChg    Bx,Bp
        Mov     Ah,3fH
        Int     21H                     ;1 Byte lesen
        XChg    Bx,Bp
        Cmp     Ax,0
        Je      Ende                    ;Fileende erreicht
        Cmp     Byte PTR[Buffer],20H    ;druckbares Zeichen?
        Jge     Druck                   ; ja,ausgeben
        Cmp     Byte PTR[Buffer],13               ;CR ?
        Jne     NoChar                  ; ja
        Mov     Ah,40H
        Int     21H                     ;Buffer ausgeben
        Mov     Byte PTR[Buffer],10     ;LF in Buffer
        Jmp     Druck
noChar: Mov     Byte PTR[Buffer],81H    ;chr(129) in Buffer
Druck:  Mov     Ah,40H
        Int     21H                     ;Buffer ausgeben
        Jmp     Loop                    ;nächstes Zeichen
Ende:   Mov     Byte PTR[Buffer],13     ;CR in buffer
        Mov     Ah,40H
        Int     21H                     ;CR ausgeben
        Mov     Byte PTR[Buffer],10     ;LF in Buffer
        Mov     Ah,40H
        Int     21H                     ;LF ausgeben
        Int     20H                     ;Programmende

        DW      DriveF-ErrorF-2
ErrorF  DB      "ERROR "
        DW      FoundF-DriveF-2
DriveF  DB      "invalid drive"
        DW      ManyF-FoundF-2
FoundF  DB      "file not found"
        DW      DeniF-ManyF-2
ManyF   DB      "too many open files"
        DW      InvalF-DeniF-2
DeniF   DB      "access denied"
        DW      Buffer-InvalF
InvalF  DB      "invalid access"
Buffer  DB      (?)

Prog    EndS
        End Start
