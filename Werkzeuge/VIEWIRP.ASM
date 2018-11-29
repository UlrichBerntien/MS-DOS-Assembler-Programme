        TITLE *** VIEW INTERRUPT ***
        PAGE 60,132
        .SALL
;=====================================================================
; MS-Macro-Assembler V1.10
; Ulrich Berntien .02.1990
; letzte Änderung 06.03.1990
;
;   ViewInterrupt
;
;   Testen, welche Interrupts ein Program benutzt
;   Aufrufformat: VIEWIRP switch progname comandline
;   Schalter möglich
;      -name   =>  Ausgabe in log.File name
;   progname   :  Name des auszuführenden Programms
;   comandline :  Kommandozeile für das Programm
;
;=====================================================================
; alle Prozeduren erhalten die Register
;=====================================================================

std_out = 1
std_err = 2
cr = 0DH
lf = 0AH
space = 20H
zero = 00H
true = 01H
false = 00H
my_irp = 28H                     ; dieser interrupt zur überwachung benutzen

;=====================================================================
data    SEGMENT WORD 'data'

para_block STRUC
  env_seg   DW 0                 ; segment address of enviroment
  com_line  DD ?                 ; pointer to command line
  first_fcb DD ?                 ; pointer to first default fcb
  secnd_fcb DD ?                 ; pointer to second default fcb
para_block ENDS

fcb     STRUC
  drive     DB 0                 ; drive indicator
  name      DB 8 DUP (space)     ; file name
  ext       DB 3 DUP (space)     ; extension to file name
  curblk    DW ?                 ; current block
  recsize   DW 128               ; record size
  fsize     DD ?                 ; file size
  date      DW ?                 ; date of creation or last write
  time      DW ?                 ; time of creation or last write
  flag      DB ?                 ; flags
  adrfirst  DW ?                 ; disk address of first alloc unit
  adrlast   DW ?                 ; disk address of last alloc unit
  adr       DB 3 dup (?)         ; disk address of unit last accessed
  next      DB ?                 ; next record
  rec       DD ?                 ; random record
fcb     ENDS

len     MACRO was
        len_&was = $ - was - 2
        ENDM

;---------------------------------------------------------------------
last_seg DW SEG last             ; erstes freies segment
high_seg DW ?                    ; höchst mögliches seg vom child

out_dev DW std_out               ; gerät für ergebnis ausgabe

save_irp DD ?                    ; alte interrupt speichern

name_ptr DD ?                    ; ads des childprogramm namens

mem_irp DD 100H DUP (?)          ; speicher für die interrupts
chg_irp DD 100H DUP (?)
change  DB 100H DUP (false)      ; true => interrupt wurde geändert
inrange DB 100H DUP (false)      ; true => irp im bereich last_seg..high_seg

fcb_1   fcb <>
fcb_2   fcb <>

block   para_block <>

hex_table DB '0123456789ABCDEF'

hline   DW len_hline
        DB 'ViewInterrupt - (c) .02.1990 Ulrich Berntien',cr,lf
      len hline
etext   DW len_etext
        DB 'Testen, welche Interrupts ein Program benutzt',cr,lf,lf
        DB 'Aufrufformat: VIEWIRP switch progname comandline',cr,lf,lf
        DB 'Schalter möglich',cr,lf
        DB '   -name   =>  Ausgabe in log.File name',cr,lf,lf
        DB 'progname   :  Name des auszuführenden Programms',cr,lf
        DB 'comandline :  Kommandozeile für das Programm',cr,lf,lf
      len etext
derr    DW len_derr
        DB 'DOS-Fehlercode #'
derr1   DB '????',cr,lf
        DB 'in der Nähe von CS:'
derr2   DB '????',cr,lf
      len derr
pseg    DW len_pseg
        DB 'Der frei Speicher beginnt ab Segement #'
pseg1   DB '????',cr,lf,lf
      len pseg
cuit    DW len_cuit
        DB 'Interrupt geändert und im Bereich des Programmes',cr,lf
      len cuit
ct      DW len_ct
        DB 'Interrupt geändert aber nicht im Bereich des Programmes',cr,lf
      len ct
it      DW len_it
        DB 'Interrupt nicht geändert aber im Bereich des Programmes',cr,lf
      len it
cuitl   DW len_cuitl
        DB '  '
cuitl1  DB '?? H von '
cuitl2  DB '????:???? auf '
cuitl3  DB '????:????',cr,lf
      len cuitl
itl     DW len_itl
        DB '  '
itl1    DB '?? H auf '
itl2    DB '????:????',cr,lf
      len itl

data    ENDS

;=====================================================================
code    SEGMENT WORD 'code'
ASSUME cs:code ,ds:data ,es:nothing ,ss:stack

; DOS über Int 21H aufrufen ; ggf. Fehlerbehandlung
;---------------------------------------------------------------------
dos_call MACRO
        LOCAL no_error
        clc
        int   21H                             ;;dos call
        jnc   no_error                        ;;wenn kein fehler
        call  doserr
no_error:
        ENDM

; Register auf Stack sichern
;---------------------------------------------------------------------
push_regs MACRO regs
        IRP reg,<regs>
          push reg
        ENDM
        ENDM

; Register von Stack holen
;---------------------------------------------------------------------
pop_regs MACRO regs
        IRP reg,<regs>
          pop reg
        ENDM
        ENDM

;---------------------------------------------------------------------
data_seg DW SEG data             ; segment adresse vom data segment
mem_ss   DW ?                    ; speicher zum sichern der stack ads
mem_sp   DW ?

; DOS Fehler behandeln
;-----------------------------------------------------------------0100
doserr  PROC NEAR
        mov   ds,data_seg
        mov   di,OFFSET derr1
        call  outax                           ;dos-fehlercode in zeile
        mov   di,OFFSET derr2
        pop   ax                              ;return adresse holen
        call  outax
        mov   cx,[derr]                       ;länge der zeile
        mov   dx,OFFSET derr+2                ;adresse der zeile
        mov   bx,std_err                      ;file handle
        mov   ah,40H                          ;write a file
        int   21H
l0100:  mov   ax,4C02H                        ;beenden, Returncode = 02
        int   21H
        jmp   l0100
doserr  ENDP

; Hilfsprozedur für pzeile
; Such ab ES:SI nach Zeichen <= space in einer Zeile
; ersetzt es durch zero
; CX enthält die Anzahl der Zeichen, die noch in der Zeile sind
;-----------------------------------------------------------------0200
L0202   PROC NEAR
        jcxz  l0203
l0204:  cmp   es:[si],BYTE PTR space
        jle   l0203
        inc   si
        loop  l0204
l0203:  mov   es:[si],BYTE PTR zero
        ret
L0202   ENDP

; Hilfsprozedur für pzeile
; Such ab ES:SI nach Zeichen > space in einer Zeile
; CX enthält die Anzahl der Zeichen, die noch in der Zeile sind
;-----------------------------------------------------------------0200
L0201   PROC NEAR
        jcxz  l0205
l0206:  cmp   es:[si],BYTE PTR space
        jg    l0205
        inc   si
        loop  l0206
l0205:  ret
L0201   ENDP

; Hilfprozedur für pzeile
; ES:SI zeigt auf einen switch, den switch auswerten
; SI und CX wird verändert
;-----------------------------------------------------------------0200
L0200   PROC NEAR
        push_regs <dx,ax>
        inc   si
        dec   cx
        jnz   l020D
        jmp   l0208                           ;kein zeichen nach switch
l020D:  mov   ax,es
        mov   ds,ax
        mov   dx,si                           ;ds:dx auf filename
        call  l0202                           ;filename in asciz format
        mov   ah,3CH                          ;create a file
        push  cx
        xor   cx,cx                           ;no file attributes
        dos_call
        pop   cx
        mov   ds,data_seg                     ;ds restaurieren
        mov   out_dev,ax
        pop_regs  <ax,dx>
        ret
L0200   ENDP

; Hilfsprocedure für pzeile
; Kommandozeile generieren
;-----------------------------------------------------------------0200
L0209   PROC NEAR
        push_regs <ax>
        mov   al,cl                           ;erstes byte länge
l020A:  xchg  al,es:[si]                      ;den rest der zeile
        inc   si                              ;  um ein byte verschieben
        loop  l020A
        mov   ah,cr                           ;zeile mit cr abschließen
        mov   es:[si],ax
        pop_regs  <ax>
        ret
L0209   ENDP

; Parameterzeile auswerten
;-----------------------------------------------------------------0200
pzeile  PROC NEAR
        push_regs <si,dx,cx,ax>
        mov   cl,es:[0080H]
        xor   ch,ch                           ;cx := länge der parameterzeile
        mov   si,0081H                        ;es:si auf erstes zeichen
        call  l0201                           ;füllziechen lesen
        jcxz  l0208
        mov   ax,3700H                        ;get switch charcter
        dos_call
        cmp   dl,es:[si]
        jne   l0207
        call  l0200                           ;switch auswerten
        call  l0201                           ;füllzeichen lesen
        jcxz  l0208
l0207:  mov   WORD PTR name_ptr,si            ;child name gefunden
        mov   WORD PTR name_ptr+2,es
        call  l0202                           ;in asciz format bringen
        call  l0201                           ;füllzeichen lesen
        cmp   cx,0
        jg    l020B                           ;falls comzeile übergeben
        inc   si
        mov   es:[si],WORD PTR cr*0100H       ; = DB 00,cr
l020B:  mov   WORD PTR block.com_line,si      ;commandline für child gefunden
        mov   WORD PTR block.com_line+2,es
        jcxz  l020C
        call  l0209                           ;in commandline format bringen
l020C:  pop_regs  <ax,cx,dx,si>
        ret
l0208:  mov   dx,OFFSET etext                 ;erklärung ausgeben
        call  outline
        mov   ax,4C01H                        ;abbrechen, returncode = 01
        dos_call
        call  doserr
pzeile  ENDP

; Interrupt für Beobachtung installieren
;-----------------------------------------------------------------0300
set_irp PROC NEAR
        push_regs <es,bx,ax>
        xor   ax,ax
        mov   es,ax                           ;segment der irp-tabelle
        mov   ax,es:[my_irp*4]
        mov   bx,es:[my_irp*4+2]
        mov   WORD PTR [save_irp],ax          ;alter irp sichern
        mov   WORD PTR [save_irp+2],bx
        mov   ax,OFFSET view
        mov   bx,cs                           ;ads meiner irp-routine
        mov   es:[my_irp*4],ax                ;irp setzten
        mov   es:[my_irp*4+2],bx
        pop_regs <ax,bx,es>
        ret
set_irp ENDP

; Den Beobachtungsinterrupt zurücksetzen
;-----------------------------------------------------------------0400
reset_irp PROC NEAR
        push_regs <es,bx,ax>
        xor   ax,ax
        mov   es,ax                           ;segment der interrupttable
        mov   ax,WORD PTR [save_irp]
        mov   bx,WORD PTR [save_irp+2]
        mov   es:[my_irp*4],ax                ;alter irp setzten
        mov   es:[my_irp*4+2],bx
        pop_regs <ax,bx,es>
        ret
reset_irp ENDP

; Die FCB's vorbereiten für child program
; block.com_line muß schon zugewiesen sein
;-----------------------------------------------------------------0500
make_fcb PROC NEAR
        push_regs <es,si,di,ax>
        mov   ax,ds
        mov   es,ax
        mov   si,WORD PTR block.com_line      ;ds:si auf commandozeile
        mov   di,OFFSET fcb_1                 ;es:di auf ersten fcb
        mov   ah,29H                          ;parse file name
        int   21H                             ;fehler interessieren nicht
        mov   di,OFFSET fcb_2                 ;es:di auf zweiten fcb
        mov   ah,29H
        int   21H                             ;fehler interessieren nicht
        mov   ax,ds                           ;pointer im block auf die fcb's
        mov   WORD PTR block.first_fcb,OFFSET fcb_1
        mov   WORD PTR block.first_fcb+2,ax
        mov   WORD PTR block.secnd_fcb,OFFSET fcb_2
        mov   WORD PTR block.secnd_fcb+2,ax
        pop_regs  <ax,di,si,es>
        ret
make_fcb ENDP

; Die Interrupt-Tabelle kopieren für spätere Vergleiche
;-----------------------------------------------------------------0500
copy_irp PROC NEAR
        push_regs  <ds,es,si,di,cx>
        mov   cx,200H                         ;anzahl der words in irp-tabelle
        mov   di,OFFSET mem_irp
        mov   si,ds
        mov   es,si                           ;es:di auf mem_irp
        xor   si,si
        mov   ds,si                           ;ds:si auf irp tabelle
        cld
        rep movsw
        pop_regs   <cx,di,si,es,ds>
        ret
copy_irp ENDP

; Diese Procedure wird über Interruput my_irp angesprungen
; Überprüft die Interrupt Tabelle
;-----------------------------------------------------------------0600
view    PROC NEAR
        push_regs <ds,es,di,si,bp,dx,cx,bx,ax>
        xor   ax,ax
        mov   es,ax
        mov   si,0FFH*4                       ;es:si auf letzten irp
        mov   ds,data_seg                     ;       in der tabelle
        mov   di,0FFH*4+OFFSET mem_irp        ;ds:di auf letzen irp
        mov   bx,0FFH                         ;    in meinem speicher
        mov   bp,last_seg
        mov   cx,high_seg                     ;childprogram zwischen cx,bp
l0603:  mov   ax,es:[si+2]
        cmp   ax,cx
        ja    l0604                           ;oberhalb des child bereiches
        cmp   ax,bp
        jb    l0604                           ;unterhalb des child bereiches
        mov   [inrange+bx],true
l0604:  cmp   ax,[di+2]
        jne   l0605                           ;segment des irp vektors ungleich
l0601:  mov   ax,es:[si]
        cmp   ax,[di]
        je    l0602                           ;offset des irp vektors gleich
l0605:  mov   [change+bx],true
        mov   ax,es:[si]
        mov   WORD PTR [chg_irp+si],ax
        mov   ax,es:[si+2]
        mov   WORD PTR [chg_irp+2+si],ax
l0602:  sub   si,4
        sub   di,4
        dec   bx                              ;alles einen irp tiefer
        jns   l0603                           ;wenn bx positiv, weiter machen
        pop_regs  <ax,bx,cx,dx,bp,si,di,es,ds>
        iret
view    ENDP

; Eine Text in log. File out_dev geben
; DX auf Länge des Textes, DX+2 auf den Text selbst
;-----------------------------------------------------------------0800
outline PROC NEAR
        push_regs <dx,cx,bx,ax>
        mov   bx,dx
        mov   cx,[bx]                         ;länge in cx
        mov   bx,out_dev                      ;file handle in bx
        inc   dx
        inc   dx                              ;dx auf anfang des textes
        mov   ah,40H                          ;write a file
        dos_call
        pop_regs  <ax,bx,cx,dx>
        ret
outline ENDP

; Hilfsprocedure für outal
; LowNible in BL wird in ASCII gewandelt ausgegeben in [DI]
; verändert das BL Register, paßt DI an
;-----------------------------------------------------------------0B00
L0B00   PROC NEAR
        and   bx,000FH                        ;nur low nible auswerten
        mov   bl,[hex_table+bx]               ;in ascii zeichen wandeln
        mov   [di],bl
        inc   di
        ret
L0B00   ENDP

; Das Byte in AL ab DI schreiben
; DI wird aktualisiert
;-----------------------------------------------------------------0B00
outal   PROC NEAR
        push_regs <bx,ax>
        mov   ah,al
        REPT 4
         sar al,1
        ENDM
        mov   bl,al                           ;high nible ausgeben
        call  L0B00
        mov   bl,ah                           ;low nible ausgeben
        call  L0B00
        pop_regs  <ax,bx>
        ret
outal   ENDP

; Das Word in AX ab DI schreiben
; DI wird aktualisiert
;-----------------------------------------------------------------0A00
outax   PROC NEAR
        xchg  al,ah
        call  outal                           ;ah ausgeben
        xchg  ah,al
        call  outal                           ;al ausgeben
        ret
outax   ENDP

; Eine Segmentierte Adresse DWORD PTR [SI] ab DI schreiben
; DI wird aktualisiert
;-----------------------------------------------------------------0900
outads  PROC NEAR
        push_regs <ax>
        mov   ax,[si+2]                       ;segment
        call  outax                           ;  ausgeben
        mov   [di],BYTE PTR ':'
        inc   di
        mov   ax,[si]                         ;offset
        call  outax                           ;  ausgeben
        pop_regs  <ax>
        ret
outads  ENDP

; Hilfsprocedure für print
; si := si + bx * 4
;-----------------------------------------------------------------0700
L0702   PROC NEAR
        push_regs <bx>
        REPT 2
         sal bx,1
        ENDM                                  ; bx := bx * 4
        add   si,bx
        pop_regs  <bx>
        ret
L0702   ENDP

; Hilfsprocedure für print
; Ausgabe der Zeile für Änderung am Interrupt
; BX enthält die Nummer des Interrupts
;-----------------------------------------------------------------0700
L0703   PROC NEAR
        push_regs <si,di,dx,ax>
        mov   al,bl
        mov   di,OFFSET cuitl1
        call  outal                           ;irp-nummer schreiben
        mov   si,OFFSET mem_irp
        call  L0702
        mov   di,OFFSET cuitl2                ;ads von irp schreiben
        call  outads
        mov   si,OFFSET chg_irp
        call  L0702
        mov   di,OFFSET cuitl3
        call  outads
        mov   dx,OFFSET cuitl
        call  outline                         ;die zeile ausgeben
        pop_regs  <ax,dx,di,si>
        ret
L0703   ENDP

; Hilfsprocedure für print
; Ausgabe der Zeile für keine Änderung am Interrupt
; BX enthält die Nummer des Interrupts
;-----------------------------------------------------------------0700
L0704   PROC NEAR
        push_regs <si,di,dx,ax>
        mov   al,bl
        mov   di,OFFSET itl1
        call  outal                           ;irp-nummer schreiben
        mov   si,OFFSET mem_irp
        call  L0702
        mov   di,OFFSET itl2                  ;ads von irp schreiben
        call  outads
        mov   dx,OFFSET itl
        call  outline                         ;die zeile ausgeben
        pop_regs  <ax,dx,di,si>
        ret
L0704   ENDP

; Hilfsprocedure für print
; Durchsuchen der Daten nach gefordertem Muster
; AL = Vorgabe für inrange; AH = Vorgabe für change
; DX = PROC NEAR aufrufen bei zutrefen
;      bei dem Aufruf muß BX die Interruptnummer enthalten
;-----------------------------------------------------------------0700
L0701   PROC NEAR
        push_regs <cx,bx>
        xor   bx,bx                           ;bei int 00 anfangen
        mov   cx,100H                         ;soviele irp prüfen
l0706:  cmp   al,[inrange+bx]
        jne   l0705
        cmp   ah,[change+bx]
        jne   l0705
        call  dx
l0705:  inc   bx
        loop  l0706
        pop_regs  <bx,cx>
        ret
L0701   ENDP

; Ausgabe der Ergebnisse
;-----------------------------------------------------------------0700
print   PROC NEAR
        push_regs <di,dx,ax>
        mov   dx,OFFSET hline
        call  outline                         ;kopfzeile ausgeben
        mov   ax,last_seg
        mov   di,OFFSET pseg1
        call  outax
        mov   dx,offset pseg
        call  outline                         ;segment vom freien speicher
        mov   dx,offset cuit
        call  outline                         ;geändert und im bereich
        mov   al,true
        mov   ah,true
        mov   dx,OFFSET L0703
        call  L0701
        mov   dx,offset it
        call  outline                         ;im bereich
        mov   al,true
        mov   ah,false
        mov   dx,OFFSET L0703
        call  L0701
        mov   dx,offset ct
        call  outline                         ;wurde geändert
        mov   al,false
        mov   ah,true
        mov   dx,OFFSET L0703
        call  L0701
        pop_regs  <ax,dx,di>
        ret
print   ENDP

; Speicher freigeben
;-----------------------------------------------------------------0B00
freemem PROC NEAR
        push_regs <es,bx,ax>
        mov   bx,last_seg
        mov   ax,es
        sub   bx,ax                           ;soviele paragraphs benötigt
        mov   ah,4AH                          ;modify allocated block
        dos_call
        mov   bx,0FFFFH
        mov   ah,48H                          ;allocate memory
        int   21H                             ; nun ax = memory size
        add   bx,last_seg
        mov   high_seg,bx                     ;höchstes verfügbare segment
        mov   es,es:[002CH]                   ;segement des enviroments
        mov   ah,49H                          ;free allocated memory
        dos_call
        pop_regs  <ax,bx,es>
        ret
freemem ENDP

; Hauptroutine
;-----------------------------------------------------------------0000
main    PROC FAR
        mov   ds,data_seg
        call  pzeile
        call  make_fcb
        call  freemem
        call  copy_irp
        call  set_irp
        mov   ax,ds
        mov   es,ax
        mov   bx,OFFSET block                 ;es:bx to parameter block
        lds   dx,name_ptr                     ;ds:dx to child name
        mov   cs:mem_ss,ss
        mov   cs:mem_sp,sp
        mov   ax,4B00H                        ;start child program
        clc
        int   21H
        cli
        mov   ss,cs:mem_ss
        mov   sp,cs:mem_sp
        sti
        pushf
        mov   ds,data_seg
        call  reset_irp
        popf
        jnc   L0000
        call  doserr
l0000:  call  print
        mov   ax,4C00H                        ;beenden, Returncode = 00
        dos_call
        call  doserr
main    ENDP

code    ENDS

;=====================================================================
stack   SEGMENT WORD stack 'stack'
        DB 200H DUP (?)
stack   ENDS

;=====================================================================
last    SEGMENT WORD 'memory'
last    ENDS

        END main
