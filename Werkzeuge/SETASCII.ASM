; Das Programm schaltet den Transparentmodus ein
; und setzt den Drucker in ASCII-Format
; MS-Macro-Assembler V1.1 /Wang PC /Epson FX-80
; (c) Ulrich Berntien .10.1985

Stack Segment Stack
 Assume SS:Stack
           DB 20 dup (?)
Stack EndS

Prog Segment
 Assume CS: Prog , Ds: Prog
        ORG 100H
Start:  Mov     Ax,Cs
        Mov     Ds,Ax
        Mov     mem,0fcH
        Call    Trans          ;Transparentmodus ein
        Mov     Dl,1bH
        Call    Print          ;drucken von ESC
        Mov     Dl,'R'
        Call    Print          ;drucken von 'R'
        Mov     Dl,00H
        Call    Print          ;drucken von chr(00H)
        Mov     Dx,Offset text1
        Mov     Ah,9h
        Int     21h            ;Bestätigung ausgeben
        Mov     Ah,4cH
        Int     21H            ;Quit
Trans:                         ;Transparentmodus ein/aus
        Mov     Dx, Offset mem
        Mov     Ax,4403H
        Mov     Bx,0004H
        Mov     Cx,0001H
        Int     21H
        Ret
Print:                          ;Zeichen DL auf Drucker
        Mov     Ah,05H
        Int     21H
        Ret
mem     DB ?
text1   DB 'ASCII-print-mode is on$'
Prog EndS

End Start
