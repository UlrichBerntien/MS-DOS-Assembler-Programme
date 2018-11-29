        TITLE *** FFT ***
        PAGE 68,132
        .SALL
;=====================================================================
; MS-Macro-Assmebler V1.10 /Wang PC
; (c) Ulrich Berntien .06.1990
;   letzte Änderung 01.07.1990
;
; Fast Fourier Transformation (FFT)
;
; Algorithmus:  J.Stoer : Numerische Mathematik I
;                 (4.Auflage) Springer, Berlin
; siehe auch :  B.Jähne : Digitale Bildverarbeitung
;                 Springer, Berlin
;               J.F.Palmer, S.P.Morse : Die math. Grundlagen der
;                       Numerik-Prozessoren 8087/80287
;                 te-wi, München
;               K.D.Brinkmann, H.W.Eisermann : Aufbereitung von Bildern
;                 in mc Mai 1988
;
;  TYPE complex4 = RECORD r,i : real4; END;
;
;  TYPE vc4 = SUPER ARRAY[0..*] OF complex4;
;
;  PROCEDURE fft4( n : integer; VARS f : vc4 ); EXTREN;
;     Länge des Vektors f ist 2^n, d.h. f[0] .. f[(2^n)-1]
;
; Algorithmus von Cooley,Tukey in Pseudo-Algol (Stoer) :
;
; f[] mit einer Permutation der Zeitfunktionswerte initialisiert
;
; FOR m:= 1 STEP 1 UNTIL n DO BEGIN
;   FOR k := 0 STEP 1 UNTIL 2^(m-1) -1 DO BEGIN
;     e := exp( -2*pi*i*k / 2^m );
;     FOR r := 0 STEP 2^m UNTIL 2^n - 1 DO BEGIN
;       u := f[r+k];      u := f[r+k+2^(m-1)] * e;
;       f[r+k] := u + v;  f[r+k+2^(m-1)] := u - v;
;     END;
;   END;
; END;
;
; jetzt: f[] = 2^n * Werte der Frequenzfunktion
;
;=====================================================================

debug = 1

                       ;aus der ms-pascal/fortran runtime-lib
                       ;bei aufruf darf keine zahl im fstack stehen
EXTRN sndrqq : FAR     ;FUNCTION sndrqq( CONSTS x : real8 ): real8
                       ;sinus funktion
EXTRN cndrqq : FAR     ;FUNCTION cndrqq( CONSTS x : real8 ): real8
                       ;cosinus funktion

IFDEF debug

; wait für CPU ,dann die FPU Instruktion
;---------------------------------------------------------------------
fp      MACRO opcods
          wait
          IRP x,<opcods>
            DB 0&&x
          ENDM
        ENDM

ELSE

fp      MACRO opcods
          wait
          IRP x,<opcods>
            DB 0&&x
          ENDM
          call fsshow
        ENDM

ENDIF

; Shift left
;---------------------------------------------------------------------
sleft   MACRO reg,count
          REPT count
            sal reg,1
          ENDM
        ENDM

;=====================================================================
asm_cod1      SEGMENT PUBLIC WORD 'CODE'

IFDEF debug
  EXTRN fsshow : NEAR
ENDIF

ASSUME cs : asm_cod1

PUBLIC fftvc4

n       EQU WORD PTR [bp+12]
frel    EQU WORD PTR [bp+06]
f       EQU DWORD PTR [bp+06]

r_end   EQU WORD PTR [bp-02]
m       EQU WORD PTR [bp-04]
k       EQU WORD PTR [bp-08]
k_end   EQU WORD PTR [bp-10]
r_step  EQU WORD PTR [bp-12]
adder   EQU WORD PTR [bp-14]
x       EQU QWORD PTR [bp-22]
sinx    EQU QWORD PTR [bp-30]
cosx    EQU QWORD PTR [bp-38]
buffer  EQU WORD PTR [bp-42]

lsize = 42

;---------------------------------------------------------------------
fftvc4  PROC FAR
        push  bp                              ;save frame pointer
        mov   bp,sp
        sub   sp,lsize                        ;lokaler speicher
        push  ds
        lds   si,f                            ;ds:si := ads f[0]
        mov   ax,01
        mov   m,ax                            ;m := 1, startwert für mloop
        mov   buffer,ax                       ;startwert für mloop
        mov   cx,n
        mov   bx,cx                           ;n wird in ploop gebraucht
        sal   ax,cl                           ;ax := 2^n
        dec   ax
        mov   r_end,ax                        ;r_end := 2^n-1
        mov   adder,8                         ;startwert für mloop
        mov   r_step,2
        mov   k_end,0

;---------------------------------------------------------------------
        mov   dx,1                            ;dx für indizierung
ploop:  add   si,08                           ;si := offset f[dx]
        xor   di,di                           ;di := 0
        mov   ax,dx                           ;index in ax
        mov   cx,bx                           ;cx := #bits im index = n
p001:   shr   ax,1
        rcl   di,1                            ;bit-reverse-shuffling
        loop  p001
        sub   di,dx                           ;bit-reversal index > index ?
        jle   p002                            ;kein vertauschen nötig
        sleft di,3
        add   di,si                           ;di = offset f[revers ax]
        count = 0
        REPT 4                                ;;vertauschen von 8 word = 2 real4
          mov   ax,[si+count]
          xchg  [di+count],ax
          mov   [si+count],ax
          count = count + 2
        ENDM
p002:   inc   dx                              ;index =+ 1
        cmp   dx,r_end                        ;until index >= 2^n
        jle   ploop

;---------------------------------------------------------------------
mloop:  xor   ax,ax
        mov   k,ax                            ;k := 0, startwert für kloop

kloop:  fp <D9h,EBh>    ; fldpi
        fp <D9h,E0h>    ; fchs
        push  ss
        fp <DEh,4Eh,-8> ; fimul  k
        lea   ax,x
        push  ax
        fp <DEh,76h,-42>; fidiv  buffer       ;weil: buffer = 2^m / 2
        lea   ax,sinx
        push  ax
        fp <DDh,5Eh,-22>; fstp   x            ;x := -2*pi*k / m
        wait                                  ;sndrqq benötigt x
        call  sndrqq                          ;sinx := sin( x )
        push  ss
        lea   ax,x
        push  ax
        lea   ax,cosx
        push  ax
        call  cndrqq                          ;cosx := cos( x )
        fp <DDh,46h,-38>; fld    cosx
        mov   bx,frel
        mov   dx,adder
        fp <DDh,46h,-30>; fld    sinx
        mov   cx,k                            ;cx (=r) := k, startwert für rloop
rloop:  mov   ax,cx
        sleft ax,3                            ;ax := (r+k)*8 = offset im array
        add   ax,bx
        mov   di,ax                           ;di := offset f[r+k]
        add   ax,dx
        mov   si,ax                           ;si:= offset f[r+k+2^(m-1)]
        fp <D9h,04h>    ; fld    DWORD PTR [si]
        fp <D9h,C0h>    ; fld    st(0)
        fp <D8h,CAh>    ; fmul   st,st(2)
        fp <D9h,44h,4>  ; fld    DWORD PTR [si+04]
        fp <D9h,C0h>    ; fld    st(0)
        fp <D8h,CDh>    ; fmul   st,st(5)
        fp <DEh,C2h>    ; faddp  st(2),st
        fp <D8h,CBh>    ; fmul   st,st(3)
        fp <D9h,CAh>    ; fxch   st(2)
        fp <D8h,CCh>    ; fmul   st,st(4)
        fp <DEh,E2h>    ; fsubp  st(2),st

        fp <D9h,45h,4>  ; fld    DWORD PTR [di+04]
        fp <D9h,C0h>    ; fld    st(0)
        fp <D8h,E2h>    ; fsub   st,st(2)
        fp <D9h,5Ch,4>  ; fstp   DWORD PTR [si+04]
        fp <DEh,C1h>    ; faddp  st(1),st
        fp <D9h,5Dh,4>  ; fstp   DWORD PTR [di+04]

        fp <D9h,05h>    ; fld    DWORD PTR [di]
        fp <D9h,C0h>    ; fld    st(0)
        fp <D8h,E2h>    ; fsub   st,st(2)
        fp <D9h,1Ch>    ; fstp   DWORD PTR [si]
        fp <DEh,C1h>    ; faddp  st(1),st
        add   cx,r_step
        cmp   cx,r_end
        fp <D9h,1Dh>    ; fstp   DWORD PTR [di]
        jg    l000
        jmp   rloop
l000:   fp <DEh,D9h>    ; fcompp st(1)        ;zwei vom fstack nehmen
        mov   ax,k
        inc   ax                              ;k := k + 1
        cmp   ax,k_end                        ;until k > 2^(m-1)-1
        jg    l001
        mov   k,ax                            ;k aktuaklisieren
        jmp   kloop
l001:   mov   ax,m
        inc   ax                              ;m := m + 1
        cmp   ax,n                            ;until m > n
        jg    a001
        mov   m,ax                            ;m aktualisieren
        mov   ax,r_step
        mov   buffer,ax                       ;buffer := 2^m / 2
        mov   dx,ax
        dec   dx
        mov   k_end,dx                        ;k_end := 2^(m-1) - 1
        sal   ax,1
        mov   r_step,ax                       ;r_step := 2^m
        sleft ax,2
        mov   adder,ax                        ;adder := 2^(m-1) * 8
        jmp   mloop

;---------------------------------------------------------------------
a001:   fp <DFh,46h,12> ; fild n
        mov   si,bx
        mov   cx,r_end                        ;cx := 2^n - 1
        fp <D9h,E0h>    ; fchs
        inc   cx                              ;cx := 2^n
        sal   cx,1                            ;cx := 2* #element im array
aloop:  fp <D9h,04h>    ; fld DWORD PTR [si]
        fp <D9h,FDh>    ; fscale              ;f[] := f[] / 2^n
        mov   di,si                           ;merken zum rückschreiben
        add   si,04                           ;auf nächste zahl
        fp <D9h,1Dh>    ; fstp DWORD PTR [di]
        loop  aloop
        fp <DDh,C0h>    ; ffree st(0)         ;den letzten vom fstack nehmen
        pop   ds                              ;data segment zurück
        add   sp,lsize                        ;lokaler speicher freigeben
        pop   bp                              ;load frame pointer
        wait
        ret   08                              ;zurück und stack säubern
fftvc4  ENDP

asm_cod1      ENDS
        END
