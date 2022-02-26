Name Wortgitter
Title Wortgitter-ASM-Routinen V2.1
;   (c) Ulrich Berntien .04.1984
;   MS-Macro Assembler V1.10 /Wang PC004
;
Code     Segment   'Code'
Assume	 CS:Code
Public	 ZSuche,SSuche,ZTest,STest,ZCopy,SCopy
;------------------------------------------------------------------------
Next     DW (?)                        ;Sprungadresse
Weiter   DW (?)
XWert	 DW (?) 		       ;Startwert-X
Merke	 DB (?)
ZNext	 Proc Near		       ;1 Zeichen im Gitter weiter
	 Sbb	   DL,DL
         Inc       BX
	 Mov	   AH,[BX][DI]
	 Or	   AH,AH
         Jnz       ZNextR
	 Inc	   DL		       ;Zeilenende
	 Sbb	   BX,BX
         Inc       CX
	 Add	   DI,82
	 Mov	   AH,[DI]
	 Or	   AH,AH
         Jnz       ZNextR
	 Sbb	   CX,CX	       ;Spaltenende
         Mov       DI,6[BP]
	 Mov	   AH,[DI]
ZNextR:  Cmp	   DI,SI	       ;Feldend?
         Jnz       Lab0
	 Cmp	   BX,[XWert]
	 Jnz	   Lab0
	 Inc	   [Merke]
	 Cmp	   [Merke],2
	 Jnz	   Lab0
	 Sbb	   AX,AX
	 Pop	   DX
Lab0:	 Ret
ZNext    EndP
;
SNext	 Proc Near		       ;1 Zeichen im Gitter weiter
	 Sbb	   DL,DL
         Inc       CX
	 Add	   DI,82
	 Mov	   AH,[BX][DI]
	 Or	   AH,AH
         Jnz       SNextR
	 Inc	   DL		       ;Spaltenende
	 Mov	   DI,6[BP]
	 Sbb	   CX,CX
	 Inc	   BX
	 Mov	   AH,[BX][DI]
	 Or	   AH,AH
         Jnz       SNextR
	 Sbb	   BX,BX	       ;Zeilenende
	 Mov	   AH,[DI]
SNextR:  Cmp	   DI,SI	       ;Feldend?
         Jnz       Lab1
	 Cmp	   BX,[XWert]
	 Jnz	   Lab1
	 Inc	   [Merke]
	 Cmp	   [Merke],2
	 Jnz	   Lab1
	 Sbb	   AX,AX
	 Pop	   DX
Lab1:	 Ret
SNext	 EndP
;
Suche    Proc Near
	 Mov	   [Merke],0
         Mov       SI,6[BP]            ;Einlesen der Parameter
         Mov       DI,8[BP]
	 Mov	   CX,[DI]	       ;y-Wert in CX
	 Dec	   CX
         Mov       DI,10[BP]
	 Mov	   BX,[DI]	       ;x-Wert in BX
	 Dec	   BX
         Mov       AX,CX
	 Mov	   DL,82	       ;Zeilenlaenge
         Mul       DL
         Add       SI,AX
	 Mov	   DI,SI	       ;Startzeile in DI
	 Call	   [Next]
	 Mov	   [XWert],BX	       ;Startwerte fuer Abbruch
	 Mov	   SI,DI
	 Mov	   [Merke],0
	 Jmp	   Begin2
Begin:	 Call	   [Next]
Begin2:  Cmp	   AH,' '
	 Jng	   Begin	       ;Suche nach Wortanfang>Blank
	 Push	   DI
	 Mov	   DI,8[BP]	       ;Speichern der Werte
	 Inc	   CX
	 Mov	   [DI],CX	       ;y-Wert aus CX
	 Mov	   DI,10[BP]
	 Inc	   BX
	 Mov	   [DI],BX	       ;x-Wert aus BX
	 Dec	   BX
	 Dec	   CX
	 Pop	   DI
	 Sbb	   AL,AL	       ;Absuchen des Wortes
	 Sbb	   DH,DH
Wort:	 Cmp	   AH,'*'	       ;Stern -> unbekanntes Wort
         Jnz       Lab2
	 Inc	   DH
Lab2:	 Inc	   AL
         Call      [Next]
	 Cmp	   DL,01
	 Jz	   Ende
	 Cmp	   AH,' '	       ;Wortende?
	 Jg	   Wort
Ende:	 Cmp	   AL,01	       ;andere Richtung?
	 Jz	   Begin2
	 Or	   DH,DH	       ;bekannt?
	 Jz	   Begin2
SucheR:  Ret
Suche    EndP
;
;Function SSuche(Var x,y:Integer; Gitter:Feld):Byte;
; senkrechtes Durchsuchen des Gitters nach freien Woertern
;
SSuche   Proc Far
	 Push	   BP		       ;Frame-Pointer retten
	 Mov	   BP,SP
	 Mov	   [Next],offset SNext ;Pointer auf sekrechtes Next
	 Call	   Suche
	 Pop	   BP
	 Ret	   6		       ;Parameter von Stack entfernen
SSuche   EndP
;
;Function ZSuche(Var x,y:Integer; Gitter:Feld):Byte;
; waagerechtes Durchsuchen des Gitters nach freien Woertern
;
ZSuche   Proc Far
	 Push	   BP
	 Mov	   BP,SP
	 Mov	   [Next],offset ZNext ;Pointer auf waagerechtes Next
	 Call	   Suche
	 Pop	   BP
	 Ret	   6
ZSuche   EndP
;------------------------------------------------------------------------
Test     Proc Near                     ;testen eines Wortes
	 Mov	   DI,6[BP]	       ;Gitteranfang
	 Mov	   SI,8[BP]	       ;Wortanfang
	 Mov	   AX,10[BP]	       ;y-Wert in AX
	 Dec	   AX
	 Mov	   BX,12[BP]	       ;x-Wert in BX
	 Dec	   BX
         Add       DI,BX               ;DI auf Gitter(x,y)
	 Mov	   DL,82
	 Mul	   DL		       ;AX:=AL*DL
         Add       DI,AX
	 Jmp	   Lab3
Lab4:	 Call	   [Weiter]
Lab3:	 Mov	   AL,[DI]
	 Cmp	   AL,'*'	       ;immer richtig
	 Jz	   Lab4
	 Cmp	   AL,' '	       ;Wortende=Blank
	 Jng	   True
	 Cmp	   AL,[SI]
	 Jz	   Lab4
False:	 Sbb	   AL,AL
	 Ret
True:	 Mov	   AL,01
         Ret
Test     EndP
;
SWeiter  Proc Near
	 Inc	   SI
	 Add	   DI,82
	 Ret
SWeiter  EndP
;
ZWeiter  Proc Near
	 Inc	   SI
	 Inc	   DI
	 Ret
ZWeiter  EndP
;
;Function ZTest(x,y :Integer; Var Test :Zeile; Var Gitter :Feld):Boolean;
; true,wenn das Wort ab Position x,y senkrecht in das Gitter passt
;
ZTest    Proc Far
	 Push	   BP
	 Mov	   BP,SP
	 Mov	   [Weiter],offset ZWeiter ;Pointer auf senkrechtes Weiter
         Call      Test
         Pop       BP
         Ret       8
ZTest	 EndP
;
;Function STest(x,y :Integer; Var Test :Zeile; Var Gitter :Feld):Boolean;
; true,wenn das Wort ab Position x,y waagerecht in das Gitter passt
;
STest    Proc Far
	 Push	   BP
	 Mov	   BP,SP
	 Mov	   [Weiter],offset SWeiter ;Pointer auf waagerechtes Weiter
         Call      Test
         Pop       BP
         Ret       8
STest    EndP
;------------------------------------------------------------------------
Copy	 Proc Near
	 Mov	   DI,6[BP]	       ;Gitteranfang
	 Mov	   SI,8[BP]	       ;Wortanfang
	 Mov	   AX,10[BP]	       ;y-Wert in AX
	 Dec	   AX
	 Mov	   BX,12[BP]	       ;x-Wert in BX
	 Dec	   BX
	 Add	   DI,BX	       ;DI auf Gitter(x,y)
	 Mov	   DL,82
	 Mul	   DL		       ;AX:=AL*DL
	 Add	   DI,AX
	 Jmp	   Lab8
CopyW:	 Mov	   [DI],AL	       ;einstezen in Gitter
	 Call	   [Weiter]
Lab8:	 Mov	   AL,[SI]
	 Cmp	   AL,' '	       ;Wortende=Blank
	 Jg	   CopyW
	 Ret
Copy	 EndP
;
;Function ZCopy(x,y :Integer; Var Test :Zeile; Var Gitter :Feld):Boolean;
; setzt das Wort waagerecht in das Gitter ein
;
ZCopy	 Proc Far
	 Push	   BP
	 Mov	   BP,SP
	 Mov	   [Weiter],offset ZWeiter ;Pointer auf senkrechtes Weiter
	 Call	   Copy
	 Pop	   BP
	 Ret	   8
ZCopy	 EndP
;
;Function SCopy(x,y :Integer; Var Test :Zeile; Var Gitter :Feld):Boolean;
; setzt das Wort senkrecht in das Gitter ein
;
SCopy	 Proc Far
	 Push	   BP
	 Mov	   BP,SP
	 Mov	   [Weiter],offset SWeiter ;Pointer auf waagerechtes Weiter
	 Call	   Copy
	 Pop	   BP
	 Ret	   8
SCopy	 EndP
;------------------------------------------------------------------------
Code	 EndS
	 End
