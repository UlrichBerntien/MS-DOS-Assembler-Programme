        TITLE *** File - View ***
        PAGE 70,132
;=====================================================================
; MS-Macro-Assembler V1.10 /Wang PC
; (c) Ulrich Berntien .06.1989
;   letzte Änderung 12.07.1989
;
; Aufrufformat: FILEVIEW <switch> <filename>
;
; Protokolliert alle File open/File create Aufrufe des DOS in das
; File <filename>.
; Existiert das File <filename> bereits, so wird an diese File angehängt.
; Der Switch Ýt¦ führt zum Abbruch des Protokolls.
; Falls der <filename> ohne Pfad-Angabe ist, darf der Pfad während
; der Laufzeit diese Programms nicht verändert werden.
; Wird FileView aufgerufen nachdem es bereits installiert ist, so wird
; das Protokollfile umbenannt
; Stößt das Programm während der Initialisierung auf einen Fehler, so
; wird Returncode 01 gesetzt. (sonst Returncode 00)
;=====================================================================

space = 20H
lf = 0AH
cr = 0DH
false = 00
true = 01
dos = 21H
err_dev = 0002H
cd_open_1 = 0FH
cd_open_2 = 3DH
cd_create_1 = 16H
cd_create_2 = 3CH

;=====================================================================
code    SEGMENT
ASSUME cs : code, ds : nothing, ss : stack, es :nothing

;---------------------------------------------------------------------
        ; Daten für den speicherresidenten Teil
first   = THIS NEAR
f_name  DW    ?                               ;file handle für protokoll
org_psh DW    ?
mem_ds  DW    ?                               ;zwischenspeicher für ds reg
dos_adr DD    ?
h_o2    DW    'D3'                            ;hexnummern der dos-calls
h_c2    DW    'C3'
h_c1    DW    '61'
h_o1    DW    'F0'
opent   DB    'OPEN  '                        ;funktion im klartext
createt DB    'CREATE'                        ;gerade anzahl von bytes !
len_t = 3
line    DB    '------ '                       ;die protokoll-zeile
number  DB    'hh  '
fname   DB    64 DUP (space)                  ;für den file namen
        DB    cr,lf
line_len = WORD PTR $ - line

; l0100 --------------------------------------------------------------
              ;Über diese Procedure wird der int 21H umgeleitet
i_21    PROC NEAR
        cmp   ah,cd_create_1
        jl    l0101
        je    l0100
        cmp   ah,cd_open_2
        jg    l0105
        je    l0100
        cmp   ah,cd_create_2
        jne   l0105

l0100:  push  ax                              ;gültigen code gefunden
        push  bx                              ;register sichern
        push  cx
        push  dx
        push  si
        push  di
        push  ds
        push  es
        mov   cs:[mem_ds],ds                  ;ds merken für namensauswertung
        mov   cx,cs
        mov   ds,cx
        cmp   ah,cd_create_1                  ;die richtige routine suchen
        jne   l0102
        mov   si,OFFSET createt
        call  copy_t
        mov   ax,ds:[h_c1]
        mov   WORD PTR ds:[number],ax
        jmp   SHORT fcb_name
l0102:  cmp   ah,cd_create_2                  ;create über dos 2.
        jne   l0103
        mov   si,OFFSET createt
        call  copy_t
        mov   ax,ds:[h_c2]
        mov   WORD PTR ds:[number],ax
        jmp   asciz_name
l0103:  cmp   ah,cd_open_1                    ;open über dos 1.
        jne   l0104
        mov   si,OFFSET opent
        call  copy_t
        mov   ax,ds:[h_o1]
        mov   WORD PTR ds:[number],ax
        jmp   SHORT fcb_name
l0104:  mov   si,OFFSET opent                 ;open über dos 2.
        call  copy_t
        mov   ax,ds:[h_o2]
        mov   WORD PTR ds:[number],ax
        jmp   SHORT asciz_name

l0101:  cmp   ah,cd_open_1
        je    l0100
l0105:  jmp   cs:[dos_adr]                    ;weiter im dos
i_21    ENDP

; l0300 --------------------------------------------------------------
copy_t  PROC NEAR
        mov   di,OFFSET line
        mov   cx,len_t
l0301:  mov   ax,[si]
        mov   [di],ax
        inc   di
        inc   di
        inc   si
        inc   si
        loop  l0301
        ret
copy_t  ENDP

; l0500 --------------------------------------------------------------
fcb_name PROC NEAR
        mov   di,OFFSET fname
        mov   es,ds:[mem_ds]
        mov   si,dx                           ;es:si auf fcb
        mov   al,es:[si]                      ;drive indicator
        cmp   al,00
        je    l0501                           ;00 = default drive
        add   al,BYTE PTR 'A'-1               ;01 = drive A
        jmp   SHORT l0502
l0501:  mov   ah,19H                          ;get default drive
        int   dos
        add   al,BYTE PTR 'A'                 ;00 = drive A
l0502:  mov   ds:[di],al                      ;drive schreiben
        inc   di
        mov   ds:[di],BYTE PTR ':'            ;nach drive zeichen ':'
        inc   di
        inc   si
        mov   cx,8                            ;8 zeichen langer filename
        call  copy_c                          ; kopieren
        mov   ds:[di],BYTE PTR '.'            ;'.' zwischen name und extension
        inc   di
        mov   cx,3                            ;3 zeichen extesnsion
        call  copy_c                          ; kopieren
        mov   cx,LENGTH fname - 14
        mov   al,space                        ;den rest der zeilen mit füllen
l0500:  mov   [di],al
        inc   di
        loop  l0500
        jmp   write_mes                       ;zeile ausgeben
fcb_name ENDP

;       --------------------------------------------------------------
copy_c  PROC NEAR
        ;kopiert von es:si nach ds:di cx bytes
l0503:  mov   al,es:[si]
        mov   ds:[di],al                      ;ein zeichen kopiert
        inc   si
        inc   di
        loop  l0503                           ;bis cx null
        ret
copy_c  ENDP

; l0600 --------------------------------------------------------------
asciz_name PROC NEAR
        mov   es,ds:[mem_ds]
        mov   si,dx                           ;es:si auf filename
        mov   di,OFFSET fname                 ;dorthin soll der name
        mov   cx,LENGTH fname                 ;max länge des namens
l0600:  mov   al,es:[si]
        cmp   al,0                            ;filename beende mit 00H
        je    l0601
        mov   [di],al                         ;ein zeichen kopiert
        inc   di
        inc   si
        loop  l0600                           ;max. bis zeile voll
l0601:  jcxz  write_mes
l0602:  mov   al,space                        ;rest der zeile mit space füllen
        mov   [di],al
        inc   di
        loop  l0602
       ;jmp   write_mes                       ;zeile ausgeben
asciz_name ENDP

; l0700 --------------------------------------------------------------
write_mes PROC NEAR
        clc
        lds   dx,DWORD PTR ds:[f_name]        ;ds:dx auf protokollfile-name
        mov   ax,3D01H                        ;open a file for writing
        pushf                                 ;dos-call
        call  cs:[dos_adr]
        jc    l0700                           ;bei fehler, beenden
        mov   cx,cs
        mov   ds,cx                           ;ds := cs
        mov   bx,ax                           ;file handle in bx
        xor   cx,cx
        xor   dx,dx                           ;dx:cx := 0
        mov   ax,4202H                        ;move write pointer to eof
        pushf                                 ;dos-call
        call  ds:[dos_adr]
        jc    l0701                           ;bei Fehler, file schließen
        mov   cx,line_len                     ;anzahl der bytes
        mov   dx,OFFSET line                  ;ds:dx auf beginn der daten
        mov   ah,40H                          ;write a file or device
        pushf                                 ;dos-call
        call  ds:[dos_adr]
        mov   ah,3EH                          ;close a file
l0701:  pushf
        call  ds:[dos_adr]
l0700:  pop   es                              ;register zurück
        pop   ds
        pop   di
        pop   si
        pop   dx
        pop   cx
        pop   bx
        pop   ax
        jmp   cs:[dos_adr]                    ;weiter im dos
write_mes ENDP

need_mem = WORD PTR (($-first) / 16 )+ 11H    ;benötigter speicher in para
                                       ;^^^ runden und 100H bytes PSH

cmp_length = WORD PTR ($-i_21) / 2 -1         ;words für vergleich

;=====================================================================
; Ende des residenten Teils
;=====================================================================

;       in bp wird die segmentadresse von >data< gehalten !

; l0200 --------------------------------------------------------------
main    PROC NEAR
        mov   bp,SEG data
        mov   cs:[org_psh],ds
        call  chk_present                     ;testet ob bereits installiert
        mov   ds,cs:[org_psh]
        mov   cl,ds:[0080H]
        xor   ch,ch                           ;cx := länge parameter
        dec   cx                              ;ohne CR
        mov   di,0081H                        ;ab hier der parameter
        call  switch                          ;ggf. den switch lesen
        mov   es,bp
        cmp   BYTE PTR es:termit,true         ;falls -t gesetzt
        je    l0201
        call  test_file
        mov   ds,bp
        cmp   BYTE PTR ds:present,true        ;nur rename wenn present
        je    l0200
        call  install
        mov   ax,3100H                        ;keep process
        mov   dx,need_mem                     ;paragraphs allocate
        int   dos
        jmp   dos_error                       ;falls Fehler
l0201:  mov   ds,bp
        cmp   BYTE PTR ds:present,true        ;hier: abbruch des protokolls
        jne   l0202
        call  kill
        jmp   l0202
l0200:  call  rename                          ;hier: new filename für protokoll
l0202:  mov   ax,4C00H                        ;exit from a process
        int   dos
        jmp   dos_error                       ;falls Fehler
main    ENDP

; l0400 --------------------------------------------------------------
              ;gibt Fehlermeldung aus und bricht das programm ab
              ;dx pointer auf text in "data", cx die länge des textes
error   PROC NEAR
        mov   ds,bp                           ;ds auf datensegment
        mov   bx,err_dev
        mov   ah,40H                          ;write a file or device
        int   dos
l0400:  mov   ax,4C01H                        ;exit from a process
        int   dos                             ;error code 1
        jmp   l0400
error   ENDP

; l0800 --------------------------------------------------------------
              ;ds:di ab hier filename suchen
              ;cx die zeichen, die noch auszuwerten sind
              ;ggf. file erstellen
test_file PROC NEAR
l0801:  cmp   BYTE PTR ds:[di],space          ;nach erstem zeichen suchen
        jg    l0800
        inc   di
        loop  l0801
        mov   dx,OFFSET name_err              ;keinen namen gefunden
        mov   cx,name_err_len
        jmp   error                           ;fehlermedldung und abbruch
l0800:  mov   dx,di                           ;anfang des namens sichern
        mov   cs:[f_name],dx
        inc   di
l0803:  cmp   BYTE PTR ds:[di],space          ;nach ende des namens suchen
        jle   l0802
        inc   di
        loop  l0803                           ;solange noch zeichen da sind
l0802:  xor   al,al
        mov   ds:[di],al                      ;nach ende des namens 00H
        clc
        mov   ax,3D01H                        ;open file for writing
        int   dos
        jc    l0804                           ;bei fehler, file erstellen
        ret
l0804:  mov   ah,3CH                          ;create file
        xor   cx,cx                           ;no access protection
        int   dos
        jc    l0806                           ;bei fehler
        ret
l0806:  mov   dx,OFFSET file_err              ;fehler meldung und abbruch
        mov   cx,file_err_len
        jmp   dos_error
test_file ENDP

;---------------------------------------------------------------------
              ;meldung ausgeben, wenn dos einen fehler gemeldet hat
              ;und dann programm abbrechen
dos_error PROC NEAR
        mov   dx,OFFSET dos_err               ;fehler bei dos
        mov   cx,dos_err_len
        jmp   error
dos_error ENDP

; l0900 --------------------------------------------------------------
              ; interrupt 21H umleiten über die eigene procedure
install PROC NEAR
        clc
        mov   ax,3521H                        ;get int 21H vector
        int   dos
        jc    dos_error
        mov   ax,cs
        mov   ds,ax
        mov   WORD PTR ds:[dos_adr],bx        ;sprung adresse ins dos setzen
        mov   WORD PTR ds:[dos_adr+2],es
        mov   dx,OFFSET i_21
        mov   ax,2521H                        ;int 21H umleiten auf i_21
        int   dos
        jc    dos_error
        mov   es,ds:[org_psh]                 ;enviroment wird nicht gebraucht
        mov   es,es:[002CH]                   ;seg des enviroments
        mov   ah,49H                          ;free allocated memory
        int   dos
        jc    dos_error
        ret
install ENDP

; l0A00 --------------------------------------------------------------
              ;überprüft ob das programm schon installiert ist
              ;setzt entsprechend die Variable >present<
chk_present PROC NEAR
        clc
        mov   ax,3521H                        ;get int 21H vector in es:bx
        int   dos
        jc    dos_error
        mov   cx,cmp_length                   ;diese words müssen gleich sein
        mov   ax,cs
        mov   ds,ax                           ;ds auf die routine des programs
l0A00:  mov   ax,es:[bx]                      ;wordweise vergleichen
        cmp   ax,ds:[bx]
        jne   l0A01                           ;nicht die gleiche routine
        inc   bx
        inc   bx
        loop  l0A00                           ;bis alle verglichen sind
        mov   ds,bp
        mov   ds:[present],true
        mov   ds:[old_seg],es
l0A01:  ret
chk_present ENDP

; l0B00 --------------------------------------------------------------
              ;übertägt den filenamen in den residenten teil
rename  PROC NEAR
        mov   ds,bp
        mov   di,cs:[f_name]                  ;pointer auf namen
        mov   es,ds:[old_seg]                 ;es auf seg des residenten teils
        mov   es:[f_name],di
        mov   es,es:[org_psh]
        mov   ds,cs:[org_psh]                 ;ds auf psh segment
l0B00:  mov   al,ds:[di]                      ;den namen übertragen
        mov   es:[di],al
        inc   di
        and   al,al                           ;letzte byte ist 00
        jnz   l0B00
        ret
rename  ENDP

; l0C00 --------------------------------------------------------------
              ;abbrechen des protokolls
              ;int 21H vektor wiederherstellen, speicherfreigabe
kill    PROC NEAR
        mov   ds,bp
        mov   es,ds:old_seg                   ;seg des residenten teils
        lds   dx,es:dos_adr
        mov   ax,2521H                        ;int 21H wiederherstellen
        clc
        int   dos
        jnc   l0C01
        jmp   dos_error
l0C01:  mov   es,es:org_psh
        mov   ah,49H                          ;free allocated memory
        int   dos
        jnc   l0C02
        jmp   dos_error
l0C02:  ret
kill    ENDP

; l0D00 --------------------------------------------------------------
              ;liest ggf. den switch aus der parameterzeile
              ;ds:di ab hier suchen
              ;cx die zeichen, die noch auszuwerten sind
switch  PROC NEAR
        clc
        mov   ax,3700H                        ;get dos switch character in DL
        int   dos
        jnc   l0D01
        jmp   dos_error
l0D01:  cmp   BYTE PTR ds:[di],space          ;nach erstem zeichen suchen
        jg    l0D00
        inc   di
        loop  l0D01
        jmp   SHORT l0D02
l0D00:  cmp   BYTE PTR ds:[di],dl             ;switch ?
        jne   l0D02
        inc   di                              ;núchstes zeichen
        dec   cx
        jl    l0D02                           ;falls kein zeichen mehr da
        mov   dl,ds:[di]                      ;den switch lesen
        cmp   dl,'t'                          ;terminate switch
        jne   l0D03
        mov   es,bp
        mov   BYTE PTR es:[termit],true         ;flag zum abbrechen
        inc   di
        dec   cx
        jmp   SHORT l0D02
l0D03:  mov   dx,offset sw_err                ;unbekannter switch
        mov   cx,sw_err_len
        jmp   error
l0D02:  ret
switch  ENDP

code    ENDS

;=====================================================================
data    SEGMENT
file_err DB   'DOS-Fehler beim Filezugriff',CR,LF
file_err_len = $ - file_err
dos_err  DB   'Fehler bei DOS Aufruf',CR,LF
dos_err_len = $ - dos_err
name_err DB   'Filenamen nicht gefunden',CR,LF
name_err_len = $ - name_err
sw_err   DB   'Unbekannter Switch',CR,LF
sw_err_len = $ - sw_err
present DB    false
old_seg DW    ?
termit  DB    false
data    ENDS

;=====================================================================
stack   SEGMENT STACK
        DB 500H dup (?)                       ;platz für stack
stack   ENDS

        END main
