        TITLE *** MODUL prg ***
        PAGE 70,132
        .SALL
;=====================================================================
; MS-Macro-Assembler V1.10 /Wang PC
; (c) Ulrich Berntien .07.1989
;   letzte Änderung 11.12.1989
;
; Starten eines Childprograms und Kommunikation mit ihm.
; Die PRG_SEND_* Procs übernehmen die Aufgabe der Tastatur.
;
; PRG_INIT : NEAR
;       initialisieren
;
; PRG_START : NEAR
;       -> DI:DX - auf ASCIZ - filename
;          ES:BX - auf command-line
;       startet ein Childprogram, fängt Tastatusabfragen auf
;
; PRG_RUN : NEAR
;       -> DI:DX - auf ASCIZ - filename
;          ES:BX - auf command-line
;       läßt ein Childprogram normal laufen
;
; PRG_STATUS : NEAR
;       <- AX - Status des Programms
;       00 = nicht aktiv
;       01 = wartet auf eine Zeichen
;       02 = wartet auf eine Zeile (mit CR abgeschlossen)
;       gibt den Status des Moduls an
;
; PRG_SEND_CHR : NEAR
;       -> DL - Zeichen
;       sendet das Zeichen an das childprogram
;
; PRG_SEND_FKT : NEAR
;       -> DL - Code von Fkt.taste
;       sendet den code einer funktionstaste an das childprogam
;
; PRG_SEND_LINE : NEAR
;       -> ES:DX - auf Zeichenkette
;          CX    - Länge der Zeichenkette
;       sendet die Zeichenkette an das childprogram.
;       falls dieses auf eine Zeile wartet, so wird ein CR angehängt
;
;=====================================================================
; Die Register (ohne Flags) werden bei allen Procs erhalten.
; DS immer auf das DATA segment
; CS immer auf das CODE segment
; alle Procs sind vom Typ NEAR
; trift eine Proc auf einen DOS-Fehler, so wird er i.a. über Carry
; weitergmeldet und der error-code aus AX in err_status abgelegt.
;=====================================================================

dos = 21H                    ;bios interface
bios = 88H                   ;dos interface
fkt_key_code = 31
cr = 0DH
space = 20H
false = 00
true = 01

;=====================================================================
data    SEGMENT WORD PUBLIC 'data'

para_block STRUC             ;parameterblock
        env_seg DW ?                          ;seg address of enviroment
        com_line DD ?                         ;pointer to commandline
        fcb_1 DD ?                            ;pointer to default fcb
        fcb_2 DD ?
para_block ENDS

status  DW ?                 ;status von prg
to_screen DB ?               ;true, wenn die eingehden zeichen auf sreen sollen
buffer  DD ?                 ;hier adresse des buffers für dos function call 0AH
fcb     DB 0
        DB 11 DUP (space)
        DB 4 DUP (0)         ;ein leerer fcb
block   para_block < 0,?,fcb,fcb >
data    ENDS


; --------------------------------------------------------------------
push_reg MACRO regs
        IRP reg,<regs>
          push reg
        ENDM
        ENDM

; --------------------------------------------------------------------
pop_reg MACRO regs
        IRP reg,<regs>
          pop reg
        ENDM
        ENDM

;=====================================================================
code    SEGMENT WORD PUBLIC 'code'
ASSUME  cs : code, ds : data, es : nothing

PUBLIC prg_init, prg_start, prg_run, prg_status
PUBLIC prg_send_chr, prg_send_fkt, prg_send_line

; --------------------------------------------------------------------
my_sp   DW ?                 ; speicher für stack von parentprogram
my_ss   DW ?
child_sp DW ?                ;speicher für stack von childprogram
child_ss DW ?
dos_vec DD ?                 ;hier orginal dos interrupt vector speichern
mem_ax  DW ?
traping DB ?                 ;wird true gesetzt, wenn Tastatur abgefangen wird

; l0000 --------------------------------------------------------------
prg_init PROC NEAR
        push_reg <ax,es>
        xor   ax,ax
        mov   status,ax                       ;nicht aktiv
        mov   es,ax                           ;segment mit den int.vectors
        mov   ax,es:[dos*4]
        mov   WORD PTR cs:dos_vec,ax
        mov   ax,es:[dos*4+2]
        mov   WORD PTR cs:dos_vec+2,ax        ;dos vector speichern
        pop_reg <es,ax>
        ret
prg_init ENDP

; l0100 --------------------------------------------------------------
prg_start PROC NEAR
        mov   traping,true
l0100:  pushf                                 ;parent-register sichern
        push_reg <ax,bx,cx,dx,bp,di,si,ds,es>
        cli
        mov   bp,ss                           ;parent-stack sichern
        mov   si,sp
        sti
        mov   cs:my_ss,bp
        mov   cs:my_sp,si
        mov   status,00
        mov   WORD PTR block.com_line,bx      ;pointer to command line
        mov   WORD PTR block.com_line+2,es
        mov   ax,ds
        mov   es,ax
        mov   bx,OFFSET block                 ;es:bx auf den parameterblock
        mov   ds,di                           ;ds:dx auf filename
        mov   ax,4B00H                        ;load and execute program
        cmp   traping,true                    ;soll tastatus getrapt werden ?
        jne   l0101
        call  set_my_i                        ;int dos umleiten
l0101:  int   dos
        mov   di,cs:my_ss                     ;parent-stack holen
        mov   si,cs:my_sp
        cli
        mov   ss,di
        mov   sp,si
        sti
        pop_reg <es,ds>                       ;parent register holen
        cmp   traping,true                    ;soll tastatur getrapt werden ?
        jne   l0102
        call  reset_my_i                      ;int dos wiederherstellen
l0102:  mov   status,00
        pop_reg <si,di,bp,dx,cx,bx,ax>
        popf
        ret
prg_start ENDP

; l0100 --------------------------------------------------------------
prg_run PROC NEAR
        mov   traping,false
        jmp   l0100
prg_run ENDP

; l0200 --------------------------------------------------------------
prg_status PROC NEAR
        mov   ax,status
        ret
prg_status ENDP

; l0300 --------------------------------------------------------------
prg_send_chr PROC NEAR
        cmp   status,01                       ;ist er aktive ?
        jl    l0300                           ;nein
        je    l0301
        jmp   in_buf                          ;eine zeile wird gerade gelesen
l0301:  cmp   to_screen,true
        jne   l0302                           ;keine bildschirmausgabe
        push_reg <ax,bx>
        mov   al,06H                          ;send char to screen
        xor   bh,bh                           ;0 = default screen
        mov   bh,dl
        int   bios
        pop_reg <bx,ax>
l0302:  mov   BYTE PTR mem_ax,dl              ;zeichen in dl zurückgeben
        jmp   to_child
l0300:  ret
prg_send_chr ENDP

; l0400 --------------------------------------------------------------
prg_send_fkt PROC NEAR
        push  dx
        mov   dl,fkt_key_code                 ;code für funktionstaste
        call  prg_send_chr
        pop   dx                              ;die funktionstaste selbst
        call  prg_send_chr
        ret
prg_send_fkt ENDP

; l0500 --------------------------------------------------------------
prg_send_line PROC NEAR
        push_reg <cx,dx,di>
        mov   di,dx                           ;di als pointer für die zeichen
        jcxz  l0501                           ;falls keine zeichen auszugeben
l0500:  mov   dl,es:[di]
        call  prg_send_chr                    ;ein zeichen ausgeben
        inc   di                              ;nächstes zeichen
        loop  l0500                           ;bis alle zeichen ausgegeben
l0501:  cmp   status,02                       ;eine zeile erwartet ?
        jne   l0502
        mov   dl,cr
        call  prg_send_chr                    ;ziele beenden
l0502:  pop_reg <di,dx,cx>
        ret
prg_send_line ENDP

; l0600 --------------------------------------------------------------
              ;hierüber wird der interrupt 21H umgeleitet
              ;die anfragen an die tastatur werden abgefangen
              ;und dann zum parent-programm verzweigt
my_i21  PROC NEAR
        pushf
        push  ax
        cmp   ah,0CH                          ;die function calls
        ja    l0600
        jb    l0601                           ; 01,06,07,08,0A,0B,0C
        mov   ah,al                           ; werden getrapt
l0601:  cmp   ah,06H
        jb    l0602
        ja    l0603
        cmp   dl,0FFH
        jne   l0600
        jmp   SHORT trap
l0603:  cmp   ah,09
        je    l0600
        cmp   ah,0BH
        je    l060B
        jmp   SHORT trap
l0602:  cmp   ah,01H
        je    trap
l0600:  pop   ax
        popf
        jmp   cs:[dos_vec]
l060B:  pop   ax                              ;für function 0BH
        popf
        mov   al,0FFH                         ;tastatus hat zeichen bereit
        iret
my_i21  ENDP

; l0700 --------------------------------------------------------------
trap    PROC NEAR
        push_reg <bx,cx,dx,bp,di,si,ds,es>    ;child-register sichern
        cli
        mov   di,ss
        mov   si,sp
        sti
        mov   cs:child_ss,di                  ;child-stack sichern
        mov   cs:child_sp,si
        mov   di,ds                           ;ds in di zwischenspeichern
        mov   di,cs:my_ss                     ;parent-stack holen
        mov   si,cs:my_sp
        cli
        mov   ss,di
        mov   sp,si
        sti
        pop_reg <es,ds>                       ;parent-register holen
        mov   cs:mem_ax,ax                    ;ax abspeichern
        cmp   ah,0AH                          ;0A = bufferd keyboard input
        jne   l0701
        mov   to_screen,true
        mov   status,02
        mov   WORD PTR buffer,dx              ;addresse des buffers sichern
        mov   WORD PTR buffer+2,di            ;ds war in di zwischen gespeichert
        jmp   SHORT l0700
l0701:  cmp   ah,01
        jne   l0702
        mov   to_screen,true                  ;01 = keyboard input
        jmp   SHORT l0703
l0702:  mov   to_screen,false
l0703:  mov   status,01
l0700:  call  reset_my_i
        pop_reg <si,di,bp,dx,cx,bx,ax>
        popf
        ret                                   ;weiter im parent-program
trap    ENDP

; l0800 --------------------------------------------------------------
              ;interrupt 21H auf die eigene proc my_i21 umleiten
set_my_i PROC NEAR
        push_reg <ax,bx,ds>
        xor   ax,ax
        mov   ds,ax                           ;ds auf seg der int.vectoren
        mov   bx,cs
        mov   ax,OFFSET my_i21                ;bx:ax auf umleitung für int dos
        cli
        mov   ds:[dos*4],ax                   ;int dos ändern
        mov   ds:[dos*4+2],bx
        sti
        pop_reg <ds,bx,ax>
        ret
set_my_i ENDP

; l0900 --------------------------------------------------------------
              ;interrupt 21H wieder auf die orginal adresse
reset_my_i PROC NEAR
        push_reg <ax,bx,ds>
        xor   ax,ax
        mov   ds,ax                           ;ds auf seg der int.vectoren
        mov   bx,WORD PTR cs:dos_vec +2
        mov   ax,WORD PTR cs:dos_vec          ;bx:ax auf orginal vector
        cli
        mov   ds:[dos*4],ax                   ;int dos úndern
        mov   ds:[dos*4+2],bx
        sti
        pop_reg <ds,bx,ax>
        ret
reset_my_i ENDP

; l0A00 --------------------------------------------------------------
in_buf  PROC NEAR
        push_reg <ax,bx,si,es>
        les   si,buffer                       ;es:si pointer to buffer
        mov   bl,es:[si+01]                   ;anzahl der zeichen im buffer
        inc   bl
        xor   bh,bh                           ;bx := anzahl zeichen + 1
        cmp   bl,es:[si]                      ;max. anzahl der zeichen
        je    l0A00
        mov   es:[si+bx+1],dl                 ;das zeichen in den buffer
        cmp   dl,cr                           ;cr wird nicht gezählt
        je    l0A01
        mov   es:[si+01],bl                   ;neue anzahl der zeichen
        jmp   SHORT l0A01
l0A00:  cmp   dl,cr                           ;der buffer ist voll
        jne   l0A02
        mov   es:[si+bx+1],dl                 ;das zeichen in den buffer
l0A01:  mov   bl,dl                           ;bh=0,bl = zeichen für ausgabe
        mov   al,06                           ;send char to screen
        int   bios
l0A02:  pop_reg <es,si,bx,ax>
        cmp   dl,cr
        je    to_child                        ;zeile ist beendet
        ret
in_buf  ENDP

; l0B00 --------------------------------------------------------------
to_child PROC NEAR
        pushf                                 ;parent-register sichern
        push_reg <ax,bx,cx,dx,bp,di,si,ds,es>
        cli
        mov   di,ss                           ;parent-stack sichern
        mov   si,sp
        sti
        mov   cs:my_ss,di
        mov   cs:my_sp,si
        mov   status,00
        call  set_my_i                        ;int dos umleiten
        mov   di,cs:child_ss                  ;child-stack holen
        mov   si,cs:child_sp
        cli
        mov   ss,di
        mov   sp,si
        sti
        pop_reg <es,ds,si,di,bp,dx,cx,bx,ax>  ;child-register holen
        mov   ax,cs:mem_ax                    ;für übergabe werte
        popf
        iret                                  ;int ist bearbeitet
to_child ENDP

code    ENDS

;=====================================================================
        END
