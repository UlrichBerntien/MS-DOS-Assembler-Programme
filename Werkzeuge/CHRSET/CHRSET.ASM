; MS-Macro-Assembler V1.1 /Wang PC /Epson FX-80
;  (c) Ulrich Berntien .08.1986
;            erweitert .06.1987
; CHRset <Name ohne Erweiterung>
; Übergibt dem Drucker die Character fronts der Zeichen chr(32) bis
; chr(255) aus dem File <Name ohne Erweiterung>.CHR das mit dem Programm
; CHRedit erstellt sein sollte. Das Programm sucht auch im Pfad \BIN.
;  Format des Files:     DB    'UBC'
;                        DW    checksum
;                        DB    2688 Bytes

Prog    Segment
 Assume Ds :Prog , Cs: Prog
        ORG  80H
Lab:
        ORG 100H
Start:  Cmp     Al,00                   ;Richtiger Drive ?
        Jz      Yes1
        Mov     Di,Offset DriveF
        Jmp     Error                   ;Fehlermeldung
Yes1:   Xor     Bx,Bx
        Mov     Bl,Byte PTR[Lab]        ;Länge des Namens
        Add     Bx,81H                  ;letzes+1 Zeichen
        Mov     Cx,5
        Xor     Di,Di                   ;Di:= 0
Lab2:   Mov     Al,Erw[Di]              ;".CHR"+chr(0)
        Mov     [Bx+Di],Al              ;anhängen um Namen zu bilden
        Inc     Di
        Loop    Lab2
        Mov     Dx,82H                  ;Adresse des Namens
        Mov     Ax,3D00H                ;Open file for reading
        Int     21H                     ;DOS-Call
        Jnc     Yes2                    ;Zugriff richtig
        Cmp     Ax,2                    ;File not found ?
        Je      notF
        Cmp     Ax,4                    ;too many files
        Jle     ManyL
        Jg      weiter
notF:   Mov     Di,4                    ;"\BIN/" vorsetzten
BinL:   Mov     Al,[Bin+Di]
        Mov     [82H-5+Di],Al
        Dec     Di
        Jge     BinL
        Mov     Dx,82H-5                ;Adresse des Namens
        Mov     Ax,3D00H                ;Open file for reading
        Int     21H                     ;DOS-Call
        Jnc     Yes2                    ;Zugriff richtig
        Cmp     Ax,4                    ;File not found ?
        Jl      FoundL
        Jg      weiter
ManyL:  Mov     Di,Offset ManyF
        Jmp     Error
FoundL: Mov     Di,Offset FoundF
        Jmp     Error
weiter: Cmp     Ax,5
        Jg      InvalL
        Mov     Di,Offset DeniF
        Jmp     Error
InvalL: Mov     Di,Offset InvalF
Error:  Mov     Cx,Word PTR[ErrorF-2]   ;Textlänge
        Mov     Dx,Offset ErrorF        ;Testadresse
        Mov     Bx,2                    ;Fehlerausgang
        Mov     Ah,40H
        Int     21H                     ;'ERROR ' ausgeben
        Mov     Dx,Di                   ;Textadresse
        Mov     Cx,[Di-2]               ;Textlänge
        Mov     Ah,40H
        Int     21H                     ;Meldung ausgeben
        Int     20H                     ;Programmabbruch
Yes2:   Mov     Dx,Offset Buffer        ; ja,File offen
        Mov     Bx,Ax                   ;file handel in Bx
        Mov     Cx,2693                 ;alle Bytes
        Mov     Ah,3fH                  ;lesen
        Int     21H                     ;DOS-Call
        Cmp     Word PTR [Buffer],"BU"  ;Id testen
        Jne     IdE                     ; falsch
        Cmp     Byte PTR [Buffer+2],"C" ;Id testen
        Je      Yes3                    ; falsch
IdE:    Mov     Di,Offset IdF           ;Fehlermeldung
        Jmp     Error
Yes3:   Xor     Ax,Ax                   ;Id richtig
        Xor     Bx,Bx
        Mov     Di,Offset Buffer +5
        Mov     Cx,2688                 ;Checksum Test
Lab3:   Add     Al,[Di]                 ;Ax:= Ax + Byte PTR Buffer
        Adc     Ah,Bl
        Inc     Di
        Loop    Lab3
        Cmp     Ax,Word PTR [Buffer+3]
        Je      Send                    ;richtig
        Mov     Di,Offset ChF           ;Fehlermeldung
        Jmp     Error
Send:   Mov     Cx,5                    ;Zusammenstellen der Zeichen
        Mov     Di,Offset Escape        ;für den Drucker
Lab4:   Mov     Al,[Di]
        Mov     [Di+Buffer-Escape],Al
        Inc     Di
        Loop    Lab4
        Mov     Cx,2699                 ;Zahl der Zeichen
        Mov     Di,Offset First         ;Startadresse
Lab5:   Mov     Dx,1020H                ;Statusport
Lab6:   In      Al,Dx                   ;einlesen
        Test    Al,10H                  ;ist Busy ?
        Jnz     Lab6                    ; ja
        Mov     Dx,10eaH                ;Ausgabeport
        Mov     Al,[Di]                 ;Zeichen in Al
        Out     Dx,Al                   ;ausgeben
        Inc     Di                      ;nächstes Zeichen
        Loop    Lab5
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
        DW      IdF-InvalF-2
InvalF  DB      "invalid access"
        DW      ChF-IdF-2
IdF     DB      "Id"
        DW      Erw-ChF
ChF     DB      "checksum"
Erw     DB      ".CHR",0
Bin     DB      "\BIN/"
Escape  DB      27,"&",0,32,255
first   DB      27,"%",1,0,27,"6"
Buffer  DB      (?)

Prog    EndS
        End Start
