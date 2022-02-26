; MS-Macro-Assembler V1.1
;  (c) Ulrich Berntien .05.1985
; Procedure SetTrans;
;  Die Procedure schaltet den Transparentmodus ein,
;  d.h. alle Zeichen zum Drucker werden ohne Code-
;  wandlung übertragen
; Procedure DelTrans;
;  Die Procedure hebt den Transparentmodus auf

Data	Segment Public 'Data'
 DGroup Group Data
 Assume Ds:DGroup
 mem	DB (?)
Data	EndS

Drucker Segment Public 'Code'
 Assume CS:Drucker
 Public SetTrans,DelTrans

SetTrans	  Proc Far
		  Mov mem,0fcH
		  Lea DX,mem
		  Mov AX,4403H
		  Mov BX,0004H
		  Mov CX,0001H
		  Int 21H
		  Ret		      ;Quit
SetTrans	  EndP

 DelTrans	  Proc Far
		  Mov mem,0fbH
		  Lea DX,mem
		  Mov AX,4403H
		  Mov BX,0004H
		  Mov CX,0001H
		  Int 21H
		  Ret		      ;Quit
DelTrans	  EndP

Drucker EndS
	End
