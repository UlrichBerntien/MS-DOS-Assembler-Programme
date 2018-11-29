; MS-MAcro-Assembler V1.1 /Wang PC
;  (c) Ulrich Berntien .06.1986
; Der Disknamen wird geändert. Format: RenVol <Disk:><neuerName>

Prog    Segment
 Assume Ds :Prog, Cs :Prog

Drive   EQU Byte PTR DS:005cH
Long    EQU Byte PTR DS:0080H
        ORG 100H

        Mov     Al,drive        ;Laufwerksnummer einladen
        Cmp     Al,0            ;default drive ?
        Jne     Lab1            ; nein
        Mov     Ah,19H          ;Drive ermitteln
        Int     21H             ;DOS-Call
        Inc     Al              ;in Format wie FCB
        Mov     NAdr,81H        ;Adresse des Namens
        Mov     Cl,Long         ;Länge vorberiten
        Inc     Cl
        Inc     Cl
        Mov     Long,Cl
Lab1:   Dec     Al              ;in Format für Calls
        Mov     Drive,Al        ;Drivenummer sichern
        Mov     Bx,Offset Buffer;Bufferbereich
        Mov     Dx,05           ;ab Sektor 5
        Mov     Cx,06           ;6 Sektoren
        Int     25H             ;lesen
        Jc      Err             ;bei Fehler
        Mov     Ax,08E5H        ;Volumen-ID und Leer-ID
        Mov     Si,offset Buffer;starten der Suchroutine
Lop1:   Cmp     [Si+0bH],Ah     ;Volumen-ID ?
        Je      Lab2            ; ja
        Cmp     [Si],Al         ;leeres Feld?
        Je      Lab2            ; ja
        Cmp     [Si],Byte PTR 0 ;leeres Feld?
        Je      Lab2            ; ja
        Add     Si,32           ;nächster Eintrag
        Cmp     Si,6*512+offset Buffer
        Jl      Lop1            ;noch nicht am Ende
        Jmp     Err             ;nichts frei und kein Name
Lab2:   Mov     Di,NAdr         ;Adresse des Parameter
        Xor     Bx,Bx           ;Zeiger auf erstes Zeichen
        Mov     Cx,Bx           ;Cx:= 0
        Mov     Cl,Long         ;Länge des Namens
        Sub     Cl,3
        Jg      Lab             ;kein Name
        Mov     [Si],Al         ;löschen
        Jmp     Write
Lab:    Cmp     Cl,11           ;max. 11 Zeichen
        Jg      Err             ;Fehler
        Mov     Dl,Cl           ;Länge auch in Dl
Lop2:   Mov     Al,[Bx+Di]      ;laden eines Zeichens
        And     Al,11011111B    ;in Großbuchstaben
        Mov     [Bx+Si],Al      ;speichern des Zeichens
        Inc     Bx              ;auf nächstes Zeichen
        Loop    Lop2            ;bis alle gespeichert
        Jmp     Lab3            ;weiter
Lop3:   Mov     [Bx+Si],Byte PTR 20H ;mit Blanks füllen
        Inc     Bx              ;nächstes Zeichen
Lab3:   Inc     Dl
        Cmp     Dl,12           ;alle Zeichen ?
        Jl      Lop3            ; nein
        Mov     [Si+0bH],Ah     ;Volume-ID
Write:  Mov     Al,Drive        ;Drivenummer holen
        Mov     Bx,Offset Buffer;Bufferbereich
        Mov     Dx,05           ;ab Sektor 5
        Mov     Cx,06           ;6 Sektoren
        Int     26H             ;schreiben
        Jnc     Ende            ;kein Fehler
Err:    Mov     Cx,Buffer-Text  ;Länge des Textes
        Mov     Dx,Offset Text  ;Adresse des Textes
        Mov     Al,0dH          ;Ausgebe auf Monitor
        Int     88H             ;BIOS-Call
Ende:   Int     20H

NAdr    DW 0084H
Text    DB 'ERROR during work'
Buffer  DB

Prog    EndS
        End
