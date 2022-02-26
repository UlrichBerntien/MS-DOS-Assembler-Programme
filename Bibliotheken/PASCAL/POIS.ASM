; MS-Macro-Assembler V1.1 /Wang PC
;  (c) Ulrich Berntien .04.1988

; Grosses Integer4 Array x = 0..350 , y = 0..255
; Procedure InitAry;					 initialisieren
; Procedure InAry( x,y : Integer; w : Integer4 );	 abspeichern
; Function OutAry( x,y : Integer ) : Integer4;		 zurückholen
; Procedure Calc;

Data	Segment Public 'Data'
 DGroup Group Data
 Assume Ds: DGroup
 Mem  DW (?)			 ;tiefstes nicht genutzte Segment
Data	EndS

BigAry Segment Public 'Code'
 Assume Cs: BigAry
 Public InitAry,InAry,OutAry, Calc

InitAry Proc Far
	Mov	Ax,SS
	Add	Ax,4091 	;tiefster von Pascal nicht genutzter Par.
	Mov	Mem,Ax		;speichern
	Ret			;zurück
InitAry EndP

InAry	Proc Far
	Mov	Si,Bp		;Frame Pointer retten
	Mov	Bp,Sp		;Bp auf Stack zeigen
	Mov	Ax,10[Bp]	;X laden
	Sal	Ax,1
	Sal	Ax,1
	Sal	Ax,1
	Sal	Ax,1
	Sal	Ax,1
	Sal	Ax,1		;Ax:= ( X * 256 ) * 4 div 16
	Add	Ax,Mem		;Basisadresse laden
	Mov	Es,Ax		;in Es
	Mov	Di,8[Bp]	;Y laden
	Sal	Di,1
	Sal	Di,1		;Di:= Y * 4
	Mov	Ax,4[Bp]
	Mov	Es:[Di],Ax	;store LSW
	Mov	Ax,6[Bp]
	Mov	Es:[Di+2],Ax	;store MSW
	Mov	Bp,Si		;Frame Pointer zurück
	Ret 8			;zurück,Stack säubern
InAry	EndP

OutAry	Proc Far
	Mov	Si,Bp		;Frame Pointer retten
	Mov	Bp,Sp		;Bp auf Strack zeigen
	Mov	Ax,6[Bp]	;X laden
	Sal	Ax,1
	Sal	Ax,1
	Sal	Ax,1
	Sal	Ax,1
	Sal	Ax,1
	Sal	Ax,1		;Ax:= ( X * 256 ) * 4 div 16
	Add	Ax,Mem		;Basisadresse laden
	Mov	Es,Ax
	Mov	Di,4[Bp]	;Y laden
	Sal	Di,1
	Sal	Di,1		;Di:= Y * 4
	Mov	Ax,Es:[Di]
	Mov	Dx,Es:[Di+2]
	Mov	Bp,Si		;Frame Pointer zurück
	Ret 4			;zurück Stack säubern
OutAry	EndP

Calc	Proc Far
	Push	Ds		;Datensegment sichern
	Mov	Si,Mem
	Mov	Cx,Si
	Add	Cx,64*349	;349
	Mov	Di,1024+(4*255) ;255

L2:	Mov	Ds,Si		;Segment in Ds
	Mov	Bx,1024+4	;Bx = Offset

	Mov	Ax,[Bx-4]	;Ax least Word
	Mov	Dx,[Bx-2]	;Dx most Word

L1:	Add	Ax,[Bx+4]
	Adc	Dx,[Bx+6]

	Add	Ax,[Bx+1024]
	Adc	Dx,[Bx+1026]

	Add	Ax,[Bx-1024]
	Adc	Dx,[Bx-1022]	;Summe aller umgebenden Felder

	Clc
	Rcr	Dx,1
	Rcr	Ax,1
	Clc
	Rcr	Dx,1
	Rcr	Ax,1		;32-Bit Division durch 4

	Mov	[Bx],Ax
	Mov	[Bx+2],Dx

	Add	Bx,04
	Cmp	Bx,Di
	JB	L1

	Add	Si,64
	Cmp	Si,Cx
	JB	L2

	Pop	Ds		;Datensegment zurück
	Ret
Calc	EndP

BigAry	EndS
	End
