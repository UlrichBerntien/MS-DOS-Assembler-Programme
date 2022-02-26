; MS-Macro-Assembler V1.1 /Wang PC
; (c) Ulrich Berntien .12.1987
;
; Erweitern der WANG Textverarbeitung für das Setzen von Formeln.
; Der Zeichensatz auf der Grafikkarte wird verändert, griechische
; Zeichen und Symbole für Formeln werden eingebaut.
; Mehrzeilige Formeln können gesetzt/gezeichnet werden, wenn kein
; Zeilenabstand ausgegeben wird.
;

Code    Segment
Assume  Ds : Code, Cs : Code

Prog    Proc Near
;-------------------------------------------------------------
;      Initialisierung
;-------------------------------------------------------------
        Mov     Ax,Cs                   ;Datensegment setzen
        Mov     Ds,Ax
        Mov     Bx,Offset Last /16 +20  ;Speicher für Shuttle
        Add     Bx,Ax
        Mov     Ax,Es
        Sub     Bx,Ax
        Mov     Ah,4AH                  ;modify alloc. memory
        Int     21H                     ;DOS-Call
        Jnc     L0
        Jmp     Error                   ;bei Fehler
L0:     Mov     Ax,Es
        Mov     B1,Ax                   ;B?:= Es
        Mov     B2,Ax                   ;     Segment des PSH
        Mov     Al,01                   ;Zeiger zum system configuration table
        Int     88h                     ;BIOS call
        Mov     TTSIB+2,Es              ;Speichern des Segments
        Mov     Bx,Es:[Bx+0Ah]          ;Adresse des SIB
        Mov     TTSIB,BX                ;und abspeichern
        Mov     Dh,Es:[Bx+13H]          ;High Byte von Anschluß
        Mov     Dl,10H                  ;Least Byte
        Mov     TTOut,Dx                ;Portnummer speichern
        Add     Bx,8                    ;Zeiger auf Statusbyte der Karte
        Mov     TTSta,Bx                ;abspeichern
;-------------------------------------------------------------
;       Starten von WPMAIN
;-------------------------------------------------------------
        Call    InCon                   ;Console umleiten
        Mov     Ax,Cs                   ;Es := CodeSegment
        Mov     Es,Ax
        Mov     Bx,Offset Parame        ;Parameterblock
        Mov     Dx,Offset PName         ;WPMAIN aufrufen
        Mov     Ax,4B00H                ;execute Program
        Mov     StBuf,Sp                ;Stackpointer sichern
        Mov     StBuf+2,Ss
        Int     21H                     ;DOS-Call
        CLI                             ;no interrupt
        Mov     Sp,Cs:StBuf             ;Stack zurück
        Mov     Ss,Cs:StBuf+2
        STI                             ;interrupt
        Mov     Bx,Cs
        Mov     Ds,Bx                   ;Ds := Cs
        Push    Ax                      ;Fehler Code speichern
        Call    ExCon                   ;Console zurück
        Pop     Ax
        Jnc     Ende                    ;kein Fehler
        Jmp     Error
Ende:   Mov     Ax,4C00H                ;Exit from process
        Int     21H                     ;DOS-Call
Prog    EndP

;-------------------------------------------------------------
;       CON-Driver umleiten
;-------------------------------------------------------------
InCon   Proc Near
        Mov     Ax,0040H
        Mov     Es,Ax                   ;Segment des BIOS
        Xor     Bx,Bx                   ;Es:Bx := 0040:0000
I1:     Inc     Bx
        Jno     I2
        Mov     Ax,0FFH
        Jmp     Error
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
        Mov     Word PTR Ads1+2,Es      ;Device Driver gefunden
        Mov     Word PTR Ads2+2,Es
        Mov     Di,Es:[Bx-4]            ;Ads der Enqueue Proc
        Mov     Word PTR Ads1,Di
        Mov     Ax,Es:[Di]              ;5 Bytes retten
        Mov     Mem1,Ax
        Mov     Ax,Es:[Di+2]
        Mov     Mem1+2,AX
        Mov     Al,Es:[Di+4]
        Mov     Byte PTR Mem1+4,Al
        Mov     Ax,Jump1                ;Jump Far implantieren
        Mov     Es:[Di],Ax
        Mov     Ax,Jump1+2
        Mov     Es:[Di+2],Ax
        Mov     Al,Byte PTR Jump1+4
        Mov     Es:[Di+4],Al
        Mov     Di,Es:[Bx-2]            ;Ads der Service Proc
        Mov     Word PTR Ads2,Di
        Mov     Ax,Es:[Di]              ;6 Bytes retten
        Mov     Mem2,Ax
        Mov     Ax,Es:[Di+2]
        Mov     Mem2+2,AX
        Mov     Al,Es:[Di+4]
        Mov     Byte PTR Mem2+4,Al
        Mov     Ax,Jump2                ;Jump Far implantieren
        Mov     Es:[Di],Ax
        Mov     Ax,Jump2+2
        Mov     Es:[Di+2],Ax
        Mov     Al,Byte PTR Jump2+4
        Mov     Es:[Di+4],Al
        Ret
InCon   EndP

;-------------------------------------------------------------
;       CON-Driver restaurieren
;-------------------------------------------------------------
ExCon   Proc Near
        LEs     Di,Ads1                 ;Adr der Enqueue Proc
        Mov     Ax,Mem1                 ;restaurieren
        Mov     Es:[Di],Ax
        Mov     Ax,Mem1+2
        Mov     Es:[Di+2],Ax
        Mov     Al,Byte PTR Mem1+4
        Mov     Es:[Di+4],Al
        LEs     Di,Ads2                 ;Adr der Service Proc
        Mov     Ax,Mem2                 ;restaurieren
        Mov     Es:[Di],Ax
        Mov     Ax,Mem2+2
        Mov     Es:[Di+2],Ax
        Mov     Al,Byte PTR Mem2+4
        Mov     Es:[Di+4],Al
        Ret
ExCon   EndP

;-------------------------------------------------------------
;       neue CON - Enqueue Proc
;-------------------------------------------------------------
QueCon  Proc Far
        PushF                           ;Register sichern
        Push    Ds
        Push    Ax
        Mov     Ax,Cs                   ;Datensegment setzen
        Mov     Ds,Ax
        Mov     Word PTR AdsD,Bx        ;request header Ads
        Mov     Word PTR AdsD+2,Es
        LEs     Bx,Ads1                 ;Adr der Enqueue Proc
        Mov     Ax,Mem1                 ;restaurieren
        Mov     Es:[Bx],Ax
        Mov     Ax,Mem1+2
        Mov     Es:[Bx+2],Ax
        Mov     Al,Byte PTR Mem1+4
        Mov     Es:[Bx+4],Al
        LEs     Bx,AdsD
        DW      1EFFH                   ; == Call FAR [Ads1]
        DW      Offset Ads1             ;alte Proc aufrufen
        LEs     Bx,Ads1
        Mov     Ax,Jump1                ;Jump Far implantieren
        Mov     Es:[Bx],Ax
        Mov     Ax,Jump1+2
        Mov     Es:[Bx+2],Ax
        Mov     Al,Byte PTR Jump1+4
        Mov     Es:[Bx+4],Al
        LEs     Bx,AdsD                 ;Rücksprung
        Pop     Ax
        Pop     Ds
        PopF
        Ret
QueCon  EndP

;-------------------------------------------------------------
;       neue CON - Service Proc
;-------------------------------------------------------------
SerCon  Proc Far
        PushF                           ;Register sichern
        Push    Ds
        Push    Es
        Push    Bx
        Push    Ax
        Mov     Ax,Cs                   ;Datensegment holen
        Mov     Ds,Ax
;-------------------------------------------------------------
;       Zeichen mit lesen ggf. übersetzen
;-------------------------------------------------------------
        LEs     Bx,Ads2                 ;Adr der Service Proc
        Mov     Ax,Mem2                 ;restaurieren
        Mov     Es:[Bx],Ax
        Mov     Ax,Mem2+2
        Mov     Es:[Bx+2],Ax
        Mov     Al,Byte PTR Mem2+4
        Mov     Es:[Bx+4],Al
        LEs     Bx,AdsD
        DW      1EFFH                   ; == Call FAR [Ads2]
        DW      Offset Ads2             ;alte Proc aufrufen
        LEs     Bx,AdsD                 ;request header Ads
        Cmp     Byte PTR Es:[Bx+2],4    ;command: Input ?
        Je      S1                      ;  ja
        Jmp     SE                      ;  nein
;-------------------------------------------------------------
S1:     Push    Di
        LEs     Di,DWord PTR Es:[Bx+14] ;transfer Ads
        Mov     Al,Es:[Di]              ;Zeichen
        Mov     Ah,Mode
        Cmp     Al,07                   ;KTRL & G
        Je      SC
        Cmp     Al,06                   ;KTRL & F
        Je      SC
        Cmp     Al,20                   ;KTRL & T
        Je      SC
        Cmp     Al,18                   ;KTRL & R
        Jne     S2
        Xor     Ah,Ah
        Jmp     SM
S2:     Cmp     Ah,0                    ;Mode normal ?
        Je      SM
        Cmp     Ah,7                    ;Mode Greek ?
        Jne     S3
        Mov     Bx,Offset Greek         ;Übersetzung
        XLAT
        Xor     Ah,Ah                   ;Mode := 0
        Jmp     SM
S3:     Mov     Bx,Offset Symbol        ;Übersetzung
        XLAT
        Cmp     Ah,6                    ;Mode Symbol one
        Jne     SM
        Xor     Ah,Ah                   ;Mode := 0
        Jmp     SM
;-------------------------------------------------------------
;       Abfangsprung einsetzten und Beenden
;-------------------------------------------------------------
SC:     Mov     Ah,Al                   ;Modewechsel
SM:     Mov     Mode,Ah
        Mov     Es:[Di],Al
        Pop     Di
SE:     Mov     Ax,Jump2                ;Jump Far implantieren
        LEs     Bx,Ads2
        Mov     Es:[Bx],Ax
        Mov     Ax,Jump2+2
        Mov     Es:[Bx+2],Ax
        Mov     Al,Byte PTR Jump2+4
        Mov     Es:[Bx+4],Al
        Pop     Ax                      ;Rücksprung
        Pop     Bx
        Pop     Es
        Pop     Ds
        PopF
        Ret
SerCon  EndP

;-------------------------------------------------------------
;       Einfache Fehlermeldung
;-------------------------------------------------------------
Error   Proc Near                       ;DOS-Fehler ausgeben
        Mov     Cl,Al                   ;Fehlercode Sichern
        Mov     Ah,09                   ;print String
        Mov     Dx,Offset ErrT
        Int     21H                     ;DOS-Call
        Mov     DL,CL                   ;Fehlercode in Dl
        ShR     DL,1
        ShR     DL,1                    ;Highnibel
        ShR     DL,1                    ;nach LoNibel schieben
        ShR     DL,1
        Add     DL,'0'                  ;in ASCII Wert
        Mov     Ah,2                    ;Console out
        Int     21H                     ;DOS-Call
        Mov     DL,CL
        And     DL,0FH                  ;LoNibel
        Add     DL,'0'                  ;in ASCII Wert
        Mov     Ah,2                    ;Console out
        Jmp     Ende
ErrT    DB 13,10,10,'DOS-FEHLER hex# $' ;Fehlertext
Error   EndP

;-------------------------------------------------------------
;       Daten
;-------------------------------------------------------------
Greek:  DB 000H,001H,002H,003H,004H,005H,006H,007H,008H,009H,00AH,00BH,00CH,00DH,00EH,00FH
        DB 010H,011H,012H,013H,014H,015H,016H,017H,018H,019H,01AH,01BH,01CH,01DH,01EH,01FH
        DB 020H,021H,022H,023H,024H,025H,026H,027H,028H,029H,02AH,02BH,02CH,02DH,02EH,02FH
        DB 030H,031H,032H,033H,034H,035H,036H,037H,038H,039H,03AH,03BH,03CH,03DH,03EH,03FH
        DB 040H,090H,091H,092H,094H,095H,096H,097H,098H,099H,04AH,09AH,09BH,09CH,09DH,09FH
        DB 0B0H,09EH,0B1H,0B2H,0B3H,0B4H,0B5H,057H,0B6H,0B7H,0B8H,05BH,05CH,05DH,05EH,05FH
        DB 060H,0A0H,0A1H,0A2H,0A4H,0A5H,0A6H,0A7H,0A8H,0A9H,06AH,0AAH,0ABH,0ACH,0ADH,0AFH
        DB 0C0H,0AEH,0C1H,0C2H,0C3H,0C4H,0C5H,077H,0C6H,0C7H,0C8H,07BH,07CH,07DH,07EH,07FH
        DB 080H,081H,082H,083H,084H,085H,086H,087H,088H,089H,08AH,08BH,08CH,08DH,08EH,08FH
        DB 090H,091H,092H,093H,094H,095H,096H,097H,098H,099H,09AH,09BH,09CH,09DH,09EH,09FH
        DB 0A0H,0A1H,0A2H,0A3H,0A4H,0A5H,0A6H,0A7H,0A8H,0A9H,0AAH,0ABH,0ACH,0ADH,0AEH,0AFH
        DB 0B0H,0B1H,0B2H,0B3H,0B4H,0B5H,0B6H,0B7H,0B8H,0B9H,0BAH,0BBH,0BCH,0BDH,0BEH,0BFH
        DB 0C0H,0C1H,0C2H,0C3H,0C4H,0C5H,0C6H,0C7H,0C8H,0C9H,0CAH,0CBH,0CCH,0CDH,0CEH,0CFH
        DB 0D0H,0D1H,0D2H,0D3H,0D4H,0D5H,0D6H,0D7H,0D8H,0D9H,0DAH,0DBH,0DCH,0DDH,0DEH,0DFH
        DB 0E0H,0E1H,0E2H,0E3H,0E4H,0E5H,0E6H,0E7H,0E8H,0E9H,0EAH,0EBH,0ECH,0EDH,0EEH,0EFH
        DB 0F0H,0F1H,0F2H,0F3H,0F4H,0F5H,0F6H,0F7H,0F8H,0F9H,0FAH,0FBH,0FCH,0FDH,0FEH,0FFH

Symbol: DB 000H,001H,002H,003H,004H,005H,006H,007H,008H,009H,00AH,00BH,00CH,00DH,00EH,00FH
        DB 010H,011H,012H,013H,014H,015H,016H,017H,018H,019H,01AH,01BH,01CH,01DH,01EH,01FH
        DB 020H,021H,022H,07FH,024H,025H,026H,087H,028H,029H,0D4H,08DH,02CH,0DCH,0E0H,0D3H
        DB 07CH,0E4H,0FBH,0E3H,0F8H,0F7H,0FAH,0E6H,0F9H,0E5H,0E1H,03BH,0D1H,03DH,0D2H,03FH
        DB 0DFH,0B9H,042H,0CFH,0CDH,0BAH,0E9H,08BH,0F5H,0C9H,0F4H,0F2H,0F6H,0BBH,0BDH,0CAH
        DB 0D7H,08FH,0BFH,0D6H,0DAH,0E2H,0EBH,0D5H,0BEH,0EDH,0CEH,05BH,05CH,05DH,05EH,05FH
        DB 060H,0B9H,042H,0CFH,0CDH,0BAH,0E7H,07CH,0F5H,0CBH,0F3H,0F1H,0F6H,0BBH,0BDH,0CAH
        DB 0D9H,08CH,0BFH,0D6H,0ECH,0E2H,0EAH,0D5H,0BEH,0DDH,0CEH,0DBH,07CH,07DH,07EH,07FH
        DB 08EH,081H,082H,083H,084H,085H,086H,087H,088H,089H,08AH,08BH,08CH,08DH,08EH,08FH
        DB 090H,091H,092H,0FCH,094H,095H,096H,097H,098H,099H,09AH,09BH,09CH,09DH,09EH,09FH
        DB 0A0H,0A1H,0A2H,0FDH,0A4H,0A5H,0A6H,0A7H,0A8H,0A9H,0AAH,0ABH,0ACH,0ADH,0AEH,0AFH
        DB 0B0H,0B1H,0B2H,0B3H,0B4H,0B5H,0B6H,0B7H,0B8H,0B9H,0BAH,0BBH,0F0H,0BDH,0BEH,0BFH
        DB 0C0H,0C1H,0C2H,0C3H,0C4H,0C5H,0C6H,0C7H,0C8H,0C9H,0CAH,0CBH,0EFH,0CDH,0CEH,0CFH
        DB 0D0H,0D1H,0D2H,0D3H,0D4H,0D5H,0D6H,0D7H,060H,0D9H,0DAH,0DBH,0DCH,0DDH,0DEH,0DFH
        DB 0E0H,0E1H,0E2H,0E3H,0E4H,0E5H,0E6H,0E7H,040H,0E9H,0EAH,0EBH,0ECH,0EDH,0EEH,0EFH
        DB 05EH,0F1H,0F2H,0F3H,0F4H,0F5H,0F6H,0F7H,0F8H,0F9H,0FAH,0FBH,0FCH,0FDH,0FEH,0FFH

Mode    DB 0
PName   DB 'WPMAIN.EXE',0               ;Namen der Textverarbeitung
        EVEN
TTSIB   DW (?)                          ;Screen Information Blocks
        DW (?)
TTSta   DW (?)
TTOut   DW (?)
AdsD    DD (?)                          ;Queue Pointer
Jump1   = This Word
        DB 0EAH                         ;== Jmp FAR Code:QueCon
        DW Offset QueCon
        DW Seg Code
        DB 0                            ;füllen auf 6 Bytes
Jump2   = This Word
        DB 0EAH                         ;== Jmp FAR Code:SerCon
        DW Offset SerCon
        DW Seg Code
        DB 0                            ;füllen auf 6 Bytes
Ads1    DD (?)                          ;Adresse der Enqueue Proc
Ads2    DD (?)                          ;Adresse der Service Proc
Mem1    DW 3 Dup (?)                    ;Speicher für Enqueue Proc
Mem2    DW 3 Dup (?)                    ;Speicher für Service Proc
Stbuf   DW (?)                          ;Stackpointer sichern
        DW (?)
Parame  DW 0                            ;Parameterblock für DOS#4B
        DW 0
        DW Seg Code
        DW 5cH
B1      DW (?)
        DW 6cH
B2      DW (?)

Last    Label Near                      ;Letzer Speicherplatz
Code    EndS

Stack   Segment Word Stack              ;Stackbereich
        DB 100 Dup (?)
Stack   EndS

        End Prog
