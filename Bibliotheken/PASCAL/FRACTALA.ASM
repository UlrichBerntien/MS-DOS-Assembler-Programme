; MS-Macro-Assembler V1.1 /Wang PC mit 8087
;  (c) Ulrich Berntien .08.1986
;  Anpassung für Druckergrafik .06.1987
; Procedure Inner;
; Version 2.0

Data	Segment Public 'Data'
 DGroup Group Data
 Assume Ds : DGroup
 Extrn	CI :Word, AnfangR :Word, StepR :Word   ; :Real8
 Extrn	Grenze :Word, Iter :Word, Y :Word      ; :Word/Integer
	EVEN
 Help	DW (?)
 Counter  DW (?)
 X	DW (?)
Data	EndS

Extrn  DotXY : Far

Code	Segment Public 'Code'
 Assume CS : Code
 Public Inner

Inner Proc Far
	DW 06DDh		;Fld CI
	DW Offset dgroup:CI
	Wait
	DW 06DDh		;Fld AnfangR (= CR)
	DW Offset dgroup:AnfangR
	Wait
	Xor Ax,Ax
	Mov X, Ax		;X:= 0

Start:	Mov Bx, Grenze
	DW 0C0D9h		;FLD ST
	Wait			; ZR := CR
	DW 0C2D9h		;FLD ST(2)
	Wait			; ZI := CI
	Mov Ax, Iter		; Counter:= Iter
Weiter: DW 0C0D9h		;FLD ST
	Wait
	DW 0C9D8h		;FMUL ST,ST(1)
	Wait			; ZquadI:= ZI * ZI
	DW 0C2D9h		;FLD ST(2)
	Wait
	DW 0CBD8h		;FMUL ST,ST(3)
	Wait			; ZquadR:= ZR * ZR
	DW 0CAD9H		;FXCH ST(2)
	Wait
	DW 0CBD8h		;FMUL ST,ST(3)
	Wait
	DW 0C0D8h		;FADD ST,ST(0)
	Wait
	DW 0C5D8H		;FADD ST,ST(5)
	Wait
	DW 0CAD9H		;FXCH ST(2)
	Wait			; ZI:= ( ZR * ZI )+( ZR * ZI )+ CI
	DW 0C0D9h		;FLD ST
	Wait
	DW 0E2D8h		;FSUB ST,ST(2)
	Wait
	DW 0C5D8h		;FADD ST,ST(5)
	Wait
	DW 0CCD9h		;FXCH ST(5)
	Wait			; ZR:= ZquadR - ZquadI + CR
	DW 1EDFh		;FISTP Help
	DW Offset dgroup:Help	       ; altes ZR löschen
	Wait
	DW 0C1DEh		;FADDP ST(1),ST
	Wait			; ZquadI + ZquadR
	DW 1EDFh		;FISTP Help
	DW Offset dgroup:Help
	Wait
	DEC AX			; Counter:= Counter - 1
	JZ Lab2 		; Counter = 0 ?
	Cmp Help,Bx		; ZquadI + ZquadR > Grenze ?
	Jl Weiter		; nein

	Mov Counter, Ax 	; Couter retten
	Test Al,0001B		; Counter mod 4 = 1 ?
	Jz Lab1 		; nein
	Push X
	Push Y
	Call DotXY		; Punkt( X,Y ) setzen
Lab1:	Test Byte PTR Counter,0010B	 ; Counter mod 4 = 2 oder 3
	Jz Lab2 		; nein
	Mov Ax, X
	Inc Ax
	Push Ax
	Push Y
	Call DotXY		; Punkt( X+1,Y ) setzen

Lab2:	DW 1EDFh		;FISTP Help
	DW Offset dgroup:Help	       ; ZI löschen
	Wait
	DW 1EDFh		;FISTP Help
	DW Offset dgroup:Help	       ; ZR löschen
	Wait
	Mov Ax, X
	Inc Ax
	Inc Ax			; X:= X +2;
	Cmp Ax, 847		; Ax >= 847 = X_Max -1
	Jge Ende		; ja
	Mov X, Ax
	DW 06DCh		;FADD StepR
	DW Offset dgroup:StepR	       ; CR:= CR + StepR
	Wait
	Jmp Start		; nein

Ende:	DW 0E3DBh		;FINIT
	Wait
	Ret			; zurück

Inner	EndP
Code	EndS
	End
