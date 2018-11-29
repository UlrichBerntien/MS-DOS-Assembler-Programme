        TITLE *** File - View ***
        PAGE 70,132
;=====================================================================
; MS-Macro-Assembler V1.10 /Wang PC
; (c) Ulrich Berntien .07.1989
;   letzte Änderung 12.07.1989
;
; Aufrufformat: DOSVIEW <switch> <filename>
;
; Gibt alle DOS Aufrufe beim ersten Mal in das Protokollfile.
; Existiert das File <filename> bereits, so wird an diese File angehängt.
; Der Switch -t führt zum Abbruch des Protokolls.
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

;=====================================================================
code    SEGMENT
ASSUME cs : code, ds : nothing, ss : stack, es :nothing

;---------------------------------------------------------------------
        ; Daten für den speicherresidenten Teil
first   = THIS NEAR
f_name  DW    ?                               ;file handle für protokoll
org_psh DW    ?
dos_adr DD    ?
table   DB    '0123456789ABCDEF'

calls   DW    t00,t01,t02,t03,t04,t05,t06,t07,t08,t09,t0A,t0B,t0C,t0D,t0E,t0F
        DW    t10,t11,t12,t13,t14,t15,t16,t17,txx,t19,t1A,txx,txx,txx,txx,txx
        DW    txx,t21,t22,t23,t24,t25,t26,t27,t28,t29,t2A,t2B,t2C,t2D,t2E,t2F
        DW    t30,t31,txx,t33,t34,t35,t36,t37,t38,t39,t3A,t3B,t3C,t3D,t3E,t3F
        DW    t40,t41,t42,t43,t44,t45,t46,t47,t48,t49,t4A,t4B,t4C,t4D,t4E,t4F
        DW    txx,txx,txx,txx,t54,txx,t56,t57,txx,txx,txx,txx,txx,txx,txx,txx
        DW    txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx
        DW    txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx
        DW    txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx
        DW    txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx
        DW    txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx
        DW    txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx
        DW    txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx
        DW    txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx
        DW    txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx
        DW    txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx,txx

txx     DB    'undocumented call',00
t00:    DB    'program terminate',00
t01:    DB    'keyboard input',00
t02:    DB    'screen output',00
t03:    DB    'auxillary input',00
t04:    DB    'auxillary output',00
t05:    DB    'printer output',00
t06:    DB    'direct console i/o',00
t07:    DB    'direct console input',00
t08:    DB    'console input without echo',00
t09:    DB    'print string',00
t0A:    DB    'buffered keyboard input',00
t0B:    DB    'check keyboard status',00
t0C:    DB    'character input with buffer flush',00
t0D:    DB    'disk reset',00
t0E:    DB    'select disk',00
t0F:    DB    'open file (1.25)',00
t10:    DB    'close file (1.25)',00
t11:    DB    'search for first entry',00
t12:    DB    'search for next entry',00
t13:    DB    'delete file (1.25)',00
t14:    DB    'sequential read',00
t15:    DB    'sequential write',00
t16:    DB    'create file (1.25)',00
t17:    DB    'rename file (1.25)',00
t19:    DB    'current disk',00
t1A:    DB    'set disk transfer address',00
t21:    DB    'random read',00
t22:    DB    'random write',00
t23:    DB    'file size',00
t24:    DB    'set random record field',00
t25:    DB    'set interrupt vector',00
t26:    DB    'create new program segement',00
t27:    DB    'random block read',00
t28:    DB    'random block write',00
t29:    DB    'parse filename',00
t2A:    DB    'get date',00
t2B:    DB    'set date',00
t2C:    DB    'get time',00
t2D:    DB    'set time',00
t2E:    DB    'set/reset verify flag',00
t2F:    DB    'get current disk transf.address',00
t30:    DB    'get dos version number',00
t31:    DB    'keep process',00
t33:    DB    'set/get control-c traping',00
t34:    DB    'get dos critical section flag',00
t35:    DB    'get interrupt vector',00
t36:    DB    'get disk free space',00
t37:    DB    'change incomp. config. parameters',00
t38:    DB    'international information',00
t39:    DB    'make directory',00
t3A:    DB    'remove directory',00
t3B:    DB    'change the current directory',00
t3C:    DB    'create a file',00
t3D:    DB    'open a file',00
t3E:    DB    'close a file',00
t3F:    DB    'read a file or device',00
t40:    DB    'write a file or device',00
t41:    DB    'delete a directory entry',00
t42:    DB    'move file read/write pointer',00
t43:    DB    'change write protection',00
t44:    DB    'i/o control for device',00
t45:    DB    'duplicate a file handle',00
t46:    DB    'force a duplicate of a handle',00
t47:    DB    'current directory',00
t48:    DB    'allocate memory',00
t49:    DB    'free allocated memory',00
t4A:    DB    'modify allocated block',00
t4B:    DB    'execute a program',00
t4C:    DB    'exit from a process',00
t4D:    DB    'retrieve the return code',00
t4E:    DB    'find first',00
t4F:    DB    'find next',00
t54:    DB    'get verify flag',00
t56:    DB    'rename',00
t57:    DB    'file times',00

line    DB    'DOS CALL '                     ;die protokoll-zeile
number  DB    'hh (hex)  '
text    DB    50 DUP (space)
line_len = WORD PTR $ - line

; l0100 --------------------------------------------------------------
              ;Über diese procedure wird der int 21H umgeleitet
i_21    PROC NEAR
        push  di
        push  ax
        mov   al,ah
        xor   ah,ah
        mov   di,ax                           ;mit DI die tabelle adressieren
        shl   di,1                            ;words addressieren
        cmp   cs:[calls+di],false
        pop   ax
        pop   di
        je    l0105                           ;alter code
        push  ax                              ;register sichern
        push  bx
        push  cx
        push  dx
        push  si
        push  di
        push  ds
        push  es
        jmp   SHORT new_call
l0105:  jmp   cs:[dos_adr]                    ;weiter im dos
i_21    ENDP

; l0600 --------------------------------------------------------------
              ;neuer call registrieren
new_call PROC NEAR
        mov   di,cs
        mov   ds,di                           ;ds auf code segment
        mov   al,ah
        xor   ah,ah
        mov   di,ax
        shl   di,1                            ;words adressieren
        mov   si,ds:[calls+di]                ;si auf den text
        mov   ds:[calls+di],false             ;call registrieren
        mov   di,offset number + 1            ;den function code ausgeben
        mov   cx,0204H                        ;2 zeichen, 4 bits ein zeichen
l0603:  mov   bx,ax
        and   bl,1111B                        ;4 bits = eine hex ziffer
        mov   bl,ds:[table+bx]                ;wert in zeichen wandeln
        mov   ds:[di],bl
        dec   di
        shr   al,cl                           ;nächste 4 bits
        dec   ch                              ;zählt die zeichen
        jnz   l0603
        mov   di,offset text                  ;den text in die ausgabeeile
        xor   ch,ch
l0601:  mov   cl,ds:[si]
        jcxz  l0602                           ;text hat ascii format
        mov   ds:[di],cl
        inc   di
        inc   si
        jmp   l0601
l0602:  mov   BYTE PTR [di],cr
        inc   di
        mov   BYTE PTR [di],lf
        inc   di
       ;jmp   write_mes
new_call ENDP

; l0700 --------------------------------------------------------------
              ;di auf letztes Zeichen + 1 in der ausgabezeile
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
        mov   dx,OFFSET line                  ;ds:dx auf beginn der daten
        mov   cx,di                           ;anzahl der bytes
        sub   cx,dx
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
l0B00:  mov   al,ds:[di]                      ;den namen Þbertragen
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
        inc   di                              ;nächstes zeichen
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
