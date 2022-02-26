; Assemblerroutinen für das Pascalprogramm LifeP
; MS-Macro-Assembler V1.1
; (c) Ulrich Berntien .03.9186
; Type Feld = Array [0..26,0..81] of Byte;
;				      1= lebt / 0= tot
; Procedure Generation( Var A,hilfs :Feld );
; - errechnet die nächste Generation auf dem Feld XX
; Procedure Ausgabe( Var XX :Feld );
; - gibt das Feld auf den Monitor aus, Auto Line Wrap ist auszuschaltet!

Life	Segment Public 'Code'
 Assume Cs :Life
 Public Generation,Ausgabe

Generation Proc Far
	Push	Bp		;Frame Pointer sichern
	Mov	Bp,Sp		;Bp auf stack zeigen
	Mov	Si,8[Bp]	;Adresse des Feldes holen
	Mov	Di,6[Bp]	;Adresse des Hilfsfeldes holen
	Mov	Bx,83		;auf erste Nutzzelle
	XOr	Dl,Dl		;Konstante
	Mov	Dh,1
	Mov	Ah,3
	Mov	Ch,25		;25 Zeilen
GZ:	Mov	Cl,80		;80 Spalten
GS:	Mov	Al,[Bx+Si-83]	   ;aufsummieren der UmZelle
	Add	Al,[Bx+Si-82]
	Add	Al,[Bx+Si-81]
	Add	Al,[Bx+Si-1]
	Add	Al,[Bx+Si+1]
	Add	Al,[Bx+Si+83]
	Add	Al,[Bx+Si+82]
	Add	Al,[Bx+Si+81]
	Cmp	[Si+Bx],Dl	;lebt die Zelle ?
	Jz	Tot		;nein
	Cmp	Al,Ah		;lebt sie weiter?
	Jg	sterben 	;ja
	Cmp	Al,2		;ja,lebt sie weiter?
	Jl	sterben 	;ja
leben:	Mov	[Bx+Di],Dh
	Jmp	Weiter		;nächste Zelle
Tot:	Cmp	Al,Ah		;lebt sie neu?
	Je	leben		;nein
sterben:Mov	[Bx+Di],Dl
Weiter: Inc	Bx		;nächste Zelle
	Dec	Cl		;letzte Spalte ?
	Jnz	GS		;nein
	Inc	Bx		;auf nächsten Zeilenanfang
	Inc	Bx
	Dec	Ch		;Feld fertig ?
	Jnz	GZ		;nein
	Mov	Cx,83*25/2	;ja
	Mov	Bx,82
Lab1:	Mov	Ax,[Bx+Di]	;zurück auf altes Feld
	Mov	[Bx+Si],Ax
	Inc	Bx
	Inc	Bx
	Loop	Lab1
	Pop	Bp		;Frame Pointer herstellen
	Ret	2		;fertig, Stack säubern
Generation EndP

Ausgabe Proc Far
	Push	Bp		;Frame Pointer retten
	Mov	Bp,Sp		;Bp auf Stack zeigen
	Mov	Di,6[Bp]	;Adresse des Feldes holen
	Add	Di,83		;auf erste Nutzzelle
	Mov	Dl,1		;Konstanten
	Mov	Dh,32
	Mov	Si,135
	Mov	Bh,0
	Mov	Ax,0606h
	Mov	Ch,25		;Zeilenzahl
	Jmp	Go
AZ:	Mov	Bl,13		;CR ausgeben
	Mov	Al,Ah		;Nummer für Zeichenausgabe
	Int	88H		;BIOS Aufruf
	Mov	Bl,10		;LF ausgeben
	Mov	Al,Ah		;Nummer für Zeichenausgabe
	Int	88H		;BIOS Aufruf
Go:	Mov	Cl,80		;80 Spalten
AS:	Cmp	[Di],Dl 	;lebende Zelle?
	Jne	Blank		; nein
	Mov	Bx,Si		;Blocksysmbol ausgeben
	Jmp	Aus
Blank:	Mov	Bl,Dh		;Leerzeichen ausgeben
Aus:	Mov	Al,Ah		;Nummer für Zeichenausgabe
	Int	88H		;BIOS Aufruf
	Inc	Di		;nächste Zelle
	Dec	Cl		;letzte Spalte ?
	Jnz	AS		;nein
	Inc	Di		;auf nächsten Zeilenanfang
	Inc	Di
	Dec	Ch		;Feld fertig ?
	Jnz	AZ		;nein
	Pop	Bp		;ja
	Ret	2		;fertig, Stack säubern
Ausgabe EndP

Life	EndS
	End
