        TITLE *** MODUL scr ***
        PAGE 70,132
        .SALL
;=====================================================================
; MS-Macro-Assembler V1.10 /Wang PC
; (c) Ulrich Berntien .07.1989
;   letzte Änderung 11.12.1989
;
; Zugriff auf den Bilschirm und Cursor Position
;
; Bildschimkoordinate = Word mit LowByte = Zeile  0..24
;                               HighByte = Spalte 0..79
;
; Bildschirmzeichen = Word mit LowByte = Attribut
;                             HighByte = Zeichen (wiscii)
;
; SCR_INIT : NEAR
;       keine Parameter
;       Initialisierung des Moduls.
;
; SCR_GET : NEAR
;       -> AX - Bildschirmkoordiante
;       <- DX - Bildschirmzeichen
;       Lesen aus dem Bildschirmspeicher
;
; SCR_PUT : NEAR
;       -> AX - Bildschrimkoordinate
;          DX - Bildschirmzeichen
;       Schreiben in den Bildschirmspeicher
;
; SCR_GOTO : NEAR
;       -> AX - Bildschirmkoordinate
;       Setzen der Cursorposition
;
; SCR_LOC : NEAR
;       <- AX - Bildschrimkoordinate
;       Lesen der Cursorposition
;
; SCR_GET_LN : NEAR
;       -> AX    - Bildschrimkoordinate
;          ES:DX - auf Buffer mit Words
;          CX    - Anzahl der Words im Buffer
;       Lesen aus dem Bildschirmspeicher
;
; SCR_PUT_LN : NEAR
;       -> AX    - Bildschrimkoordinate
;          ES:DX - auf Buffer mit Words
;          CX    - Anzahl der Words im Buffer
;       Schreiben in den Bildschirmspeicher
;
; SCR_PRINT : NEAR
;       -> AX    - Bildschrimkoordinate
;          ES:DX - auf Buffer mit Zeichen + erste Byte Bildschirmattribut
;          CX    - Anzahl der Zeichen im Buffer
;       Schreiben in den Bildschirmspeicher
;
; SCR_READ : NEAR
;       -> AX    - Bildschrimkoordinate
;          ES:DX - auf Buffer mit Zeichen
;          CX    - Anzahl der Zeichen im Buffer
;       Lesen aus dem Bildschirmspeicher
;
;=====================================================================
; Die Register (ohne Flags) werden bei allen Procs erhalten.
; DS immer auf das DATA segment
; CS immer auf das CODE segment
; alle Procs sind vom Typ NEAR
; trift eine Proc auf einen DOS-Fehler, so wird er i.a. über Carry
; weitergmeldet und der error-code aus AX in err_status abgelegt.
;=====================================================================

bios = 88H                 ;bios interface interrupt vector
screen_seg = 0F000H        ;segment des bildschrimspeichers

;=====================================================================
data    SEGMENT WORD PUBLIC 'data'
        EVEN
status  DW 0008H           ;adresse des 1.statusbytes der karte
sib_seg DW ?               ;segment des system information blocks
port    DW 0010H           ;anschluß der bildschirmkarte
rowtable = THIS WORD
        x = 0              ;zeilen adressierung
      REPT 25
        DW x
        x = x + 80 * 2     ;;80 zeichen pro zeile mit je 2 bytes
      ENDM
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

PUBLIC  scr_init, scr_get, scr_put, scr_goto, scr_loc
PUBLIC  scr_get_ln, scr_put_ln, scr_print, scr_read

; l0100 --------------------------------------------------------------
scr_init PROC NEAR
        push_reg <ax,bx,es>
        mov   al,01                           ;es:bx auf system information
        int   bios                            ;              block
        mov   sib_seg,es                      ;segment des sib sichern
        mov   bx,es:[bx+0AH]                  ;bx auf sreen inf.block
        mov   ah,es:[bx+13H]                  ;high byte von anschluß
        mov   BYTE PTR [port+1],ah            ;speichern (low byte = 10H)
        add   status,bx                       ;status := 0008H + bx
        pop_reg <es,bx,ax>
        ret
scr_init ENDP

; l0600 --------------------------------------------------------------
              ;erwartet in ax bildschrimkoordinate
              ;adresse für bildschrimzugriff in es:bx wird zurückgegeben
              ;karte ist für zugriff bereit gemacht
              ;die register ax,dx,di werden verändert
pre     PROC NEAR
        mov   bl,al
        xor   bh,bh                           ;bx := zeile
        mov   al,ah
        mov   ah,bh                           ;ax := spalte
        shl   bx,1                            ;mit zeilen# words adressieren
        mov   bx,[rowtable+bx]
        shl   ax,1                            ;jede spalte ein word
        add   bx,ax
        les   di,DWORD PTR status
        mov   dx,port
        mov   al,es:[di]                      ;status holen
        and   al,0CH
        or    al,01H
        out   dx,al                           ;signal an karte
        mov   di,screen_seg
        mov   es,di                           ;es:bx nun auf position
        ret                                   ;dx,al für out richtig
pre     ENDP

; l0200 --------------------------------------------------------------
scr_get PROC NEAR
        push_reg <ax,bx,di,es>
        call  pre
        mov   dx,es:[bx]                      ;zeichen lesen
        pop_reg <es,di,bx,ax>
        ret
scr_get ENDP

; l0300 --------------------------------------------------------------
scr_put PROC NEAR
        push_reg <ax,bx,di,es>
        push  dx
        call  pre
        pop   dx
        mov   es:[bx],dx                      ;zeichen schreiben
        pop_reg <es,di,bx,ax>
        ret
scr_put ENDP

; l0400 --------------------------------------------------------------
scr_goto PROC NEAR
        push_reg <bx,es>                      ;register sichern
        push  es
        les   bx,DWORD PTR status             ;cusor position in sib
        mov   es:[bx-0003H],ax                ;3 bytes unter dem statusbyte
        pop_reg <es,bx>
        ret
scr_goto ENDP

; l0500 --------------------------------------------------------------
scr_loc PROC NEAR
        push_reg <bx,es>
        les   bx,DWORD PTR status             ;cusor position in sib
        mov   ax,es:[bx-0003H]                ;3 bytes unter dem statusbyte
        pop_reg <es,bx>
        ret
scr_loc ENDP

; l0700 --------------------------------------------------------------
scr_get_ln PROC NEAR
        jcxz  l0701
        push_reg <ax,bx,cx,dx,di,si,ds>       ;register sichern
        push  es
        mov   si,dx                           ;si für adressierung
        call  pre                             ;dx,al und es:bx holen
        pop   ds                              ;ds:si nun auf den buffer
        sub   bx,si
l0700:  out   dx,al                           ;signal an karte
        mov   di,es:[bx+si]                   ;zeichen lesen
        mov   [si],di
        inc   si                              ;nächstes zeichen
        inc   si
        loop  l0700                           ;bis alle fertig
        mov   ax,ds
        mov   es,ax                           ;es wiederherstellen
        pop_reg <ds,si,di,dx,cx,bx,ax>
l0701:  ret
scr_get_ln ENDP

; l0800 --------------------------------------------------------------
scr_put_ln PROC NEAR
        jcxz  l0801
        push_reg <ax,bx,cx,dx,di,si,ds>
        push  es
        mov   si,dx                           ;si für adressierung
        call  pre                             ;dx,al und es:bx holen
        pop   ds                              ;ds:si nun auf den buffer
        sub   bx,si
l0800:  out   dx,al                           ;signal an karte
        mov   di,[si]
        mov   es:[bx+si],di                   ;zeichen schreiben
        inc   si                              ;nächstes zeichen
        inc   si
        loop  l0800                           ;bis alle fertig
        mov   ax,ds
        mov   es,ax                           ;es wiederherstellen
        pop_reg <ds,si,di,dx,cx,bx,ax>
l0801:  ret
scr_put_ln ENDP

; l0900 --------------------------------------------------------------
scr_print PROC NEAR
        jcxz  l0901
        push_reg <ax,bx,cx,dx,si,di,ds>
        push  es
        mov   si,dx                           ;si für adressierung
        call  pre                             ;dx,al und es:bx holen
        pop   ds                              ;ds:si nun auf den buffer
        mov   di,bx
        mov   bl,[si]                         ;erstes Byte enthält Attribut
        inc   si
l0900:  out   dx,al                           ;signal an karte
        mov   bh,[si]
        mov   es:[di],bx                      ;zeichen schreiben
        inc   di
        inc   di
        inc   si                              ;nächstes zeichen
        loop  l0900                           ;bis alle fertig
        mov   ax,ds
        mov   es,ax                           ;es wiederherstellen
        pop_reg <ds,si,di,dx,cx,bx,ax>
l0901:  ret
scr_print ENDP

; l0A00 --------------------------------------------------------------
scr_read PROC NEAR
        jcxz  l0A01
        push_reg <ax,bx,cx,dx,si,di,ds>
        push  es
        mov   si,dx                           ;si für adressierung
        call  pre                             ;dx,al und es:bx holen
        pop   ds                              ;ds:si nun auf den buffer
        mov   di,bx
l0A00:  out   dx,al                           ;signal an karte
        mov   bx,es:[di]                      ;zeichen lesen
        mov   [si],bh
        inc   di
        inc   di
        inc   si                              ;nächstes zeichen
        loop  l0A00                           ;bis alle fertig
        mov   ax,ds
        mov   es,ax                           ;es wiederherstellen
        pop_reg <ds,si,di,dx,cx,bx,ax>
l0A01:  ret
scr_read ENDP

code    ENDS

;=====================================================================
        END
