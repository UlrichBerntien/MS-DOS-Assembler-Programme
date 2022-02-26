Title   Fig-Forth 8086 Ver 1.0
Page 66,80

;**********************************************
;*                                            *
;*          Fig-Forth for the 8086            *
;*               Version 1.0                  *
;*                 05.1985                    *
;*                                            *
;*           Contains interface for           *
;*                MS-DOS 2.01                 *
;*                                            *
;**********************************************

;All publications of the Forth Interest Group
;are public domain. They may be further
;distributed by the inclusion of this credit
;notice:
;This publication has been made available by
;       Forth Interest Group
;       P.O. Box 1105
;       San Carlos, CA 94070
;Acknowledgements:
;       John Cassady
;       Kim Harris
;       Georg Flammer
;       Robt. D. Villwock

;       Release & Version Numbers
figrel  equ    1       ;Fig Release #
figrev  equ    0       ;Fig Revision #
usever  equ    0       ;User Version #
;       ASCII Characters used
ABl     equ    20H     ;Blank
ACR     equ    0dH     ;Carriage Return
ADot    equ    02eH    ;Period
Bell    equ    07H     ;^G
BsIn    equ    08H     ;Input Delete Char
BsOut   equ    08H     ;Output Backspace
DLe     equ    10H     ;^P
LF      equ    0aH     ;Line Feed
FF      equ    0cH     ;Form Feed
;       Memory Allocations
EM      equ    4000H   ;End of Memory +1
NScr    equ    1       ;1024 Byte per Screen
KbBuf   equ    1024    ;Bytes per Disk Buf
Us      equ    40H     ;User Variables
RtS     equ    0a0H    ;Return Stk&Term Buff.

CO      equ    kbbuf+4 ;Disk Buffer +4 Bytes
NBuf    equ    nscr*1024/kbbuf ;No. of Buffers
Buf1    equ    em-co*nbuf      ;first Disk Buf
InitR0  equ    buf1-us         ;R0
InitS0  equ    initr0-rts      ;S0

Code    Segment 'Stack'
Assume  CS:Code,DS:Code
Orig    DB     90H     ;Nop Instuction
Begin:  Jmp    cld     ;Vector to Cold Start
        Nop
        Jmp    wrm     ;Vector to Warm Start

        DB     figrel
        DB     figrev
        DB     usever
        DB     0eH     ;Version Attributres
        DW     task-7  ;Top Word in Forth-Voc
        DW     bsin
        DW     initr0  ;Init up
;       Following used by 'Cold' Word
        DW     inits0
        DW     initr0
        DW     inits0
        DW     32      ;Init Width
        DW     0       ;Init Warning
        DW     initdp  ;Init Fence
        DW     initdp  ;Init DP
        DW     Forth+6 ;Init Voc-Link
;       End Data used by 'Cold' Word
;       Following the CPU's Name
        DW     05H,0b326H

Up      DW     initr0  ;User Area Pointer
RPP     DW     initr0  ;Return Stack Pointer

;----------------------------------------------
;Forth Registers
;Forth  8086   Forth Preservation Rules
;IP     SI     Interpreter Pointer
;              must be preserved across words
;W      DX     Working Register
;              jump to 'dpush' will push the
;              contents onto the parameter
;              before executing 'apush'
;SP     SP     Parameter Stack Pointer
;              must be preserved across words
;RP     BP     Return Stack
;              must be preserved across words
;----------------------------------------------
;Comment Conversation
; =     means  is equal to
; <-    means  assignment
; name  =      adress of name
; (name)=      contents at name
;((name))=     indirect contents
; cfa   =      address of code field
; lfa   =      address of link field
; nfa   =      addr of name field
; pfa   =      addr of parameter field
; s1    =      parameter stack: 1.Word
; s2    =      parameter stack: 2.Word
; r1    =      return stack: 1.Word
; r2    =      return stack: 2.Word
; lsb   =      last significant bit
; msb   =      most significant bit
; lb    =      low byte
; hb    =      high byte
; lw    =      low word
; hw    =      high word
;----------------------------------------------
;       ++ next ++
;       ++ dpush ++
;       ++ apush ++
DPush:  Push   DX
APush:  Push   AX
Next:   LodsW          ;AX<-(ip)
        Mov    BX,AX
Next1:  Mov    DX,BX   ;(w)<-(ip)
        Inc    DX      ;(w)<-(w-1)
        Jmp    Word PTR [BX]  ;to cfa
;----------------------------------------------
;       Dirctionary Words Starts Here
;----------------------------------------------
;       ++ lit ++
DP0     DB     3+80H
        DB     'li','t'+80H
        DW     0       ;Start of Dirctionary
Lit:    DW     $+2     ;(s1)<-(ip)
        LodsW          ;AX<-Literal
        Jmp    apush   ;to top of stack

;       ++ execute ++
        DB     7+80H
        DB     'execut','e'+80H
        DW     lit-6
exec    dw     $+2
        Pop    BX      ;get cfa
        Jmp    next1   ;execute next

;       ++ branch ++
        DB     6+80H
        DB     'branc','h'+80H
        DW     exec-0aH
bran    DW     $+2     ;(ip)<-(ip)+((ip))
bran1:  Add    SI,[SI]
        Jmp    next    ;jump to offset

;       ++ 0branch ++
        DW     87H
        DB     '0branc','h'+80H
        DW     bran-9
zbran   DW     $+2
        Pop    AX      ;get stack value
        Or     AX,AX   ;zero?
        Jz     bran1   ;yes, branch
        Inc    SI      ;no, continue
        Inc    SI
        Jmp    next

;       ++ (loop) ++
        DB     86H
        DB     '(loop',')'+80H
        DW     zbran-0aH
xloop   DW     $+2
        Mov    BX,01   ;increment
xloo1:  Add    [BP],BX ;index=index+incr
        Mov    AX,[BP] ;get new index
        Sub    AX,2[BP];compare with limit
        Xor    AX,BX   ;test sign (bit-16)
        Js     bran1   ;keep looping
               ;end of 'do' loop
        Add    BP,4    ;adj. return stack
        Inc    SI
        Inc    SI      ;bypass branch offset
        Jmp    Next    ;continue

;       ++ (+Loop) ++
        DB     87H
        DB     '(+loop',')'+80H
        DW     xloop-9
sploo   DW     $+2
        Pop    BX      ;get loop value
        Jmp    xloo1

;       ++ (do) ++
        DB     84H
        DB     '(do',')'+80H
        DW     sploo-0aH
xdo     DW     $+2
        Pop    DX      ;initial index value
        Pop    AX      ;linit value
        XChg   BP,SP   ;get return stack
        Push   AX
        Push   DX
        XChg   BP,SP   ;get parameter stack
        Jmp    Next

;       ++ i ++
        DB     81H
        DB     'i'+80H
        DW     xdo-7
IDo     DW     $+2     ;(si)<-(r1)
        Mov    AX,[BP] ;get index value
        Jmp    APush   ;to parameter stack

;       ++ digit ++
        DB     85H
        DB     'digi','t'+80H
        DW     ido-4
digit   DW     $+2
        Pop    DX      ;number base
        Pop    AX      ;assci digit
        Sub    AL,'0'
        Jb     digit2  ;number error
        Cmp    AL,9
        Jbe    digit1  ;number =0 thru 9
        Sub    AL,7
        Cmp    AL,10   ;number 'A' thru 'Z'
        Jb     digit2  ;no
Digit1: Cmp    AL,DL   ;compare number to base
        Jae    Digit2  ;number error
        Sub    DX,DX   ;zero
        Mov    DL,AL   ;new binary number
        Mov    Al,1    ;true flag
        Jmp    DPush   ;add to stack
Digit2: Sub    AX,AX   ;false flag
        Jmp    APush   ;bye

;       ++ (find) ++
        DB     86H
        DB     '(find',')'+80H
        DW     digit-8
pfind   DW     $+2
        Mov    AX,DS
        Mov    ES,AX   ;ES=DS
        Pop    BX      ;nfa
        Pop    CX      ;string addr
;search loop
pfin1:  Mov    DI,CX   ;get addr
        Mov    AL,[BX] ;get word lenght
        Mov    DL,AL   ;svae lenght
        Xor    AL,[DI]
        And    AL,3fH  ;check lengths
        Jnz    pfin5   ;lenght differ
;lenght match,check each character in name
pfin2:  Inc    BX
        Inc    DI      ;next char of name
        Mov    AL,[BX]
        Xor    AL,[DI] ;compare names
        Jz     pfin5   ;no match
        Jnb    pfin2   ;match so far,loop
;found end of name (bit-8 set),a match
        Add    BX,5    ;bx=pfa
        Push   BX      ;(s3)<-pfa
        Mov    AX,1    ;true flag
        Sub    DH,DH   ;clear high length
        Jmp    DPush
;no name field match,try another
;get next link field addr (lfa)
; (zero=first word of directory)
pfin5:  Inc    BX      ;next addr
        Jb     pfin6   ;end of name
        Mov    AL,[BX] ;get next char
        Add    AL,AL   ;set/reset carry
        Jmp    pfin5   ;loop until found
pfin6:  Mov    BX,[BX] ;get link field addr
        Or     BX,BX   ;start of dict. (0)?
        Jnz    pfin1   ;no, look some more
        Mov    AX,0    ;false flag
        Jmp    APush   ;done (no match found)

;       ++ enclose ++
        DB     87H
        DB     'enclos','e'+80H
        DW     pfind-9;
encl    DW     $+2
        Pop    AX      ;si-terminator char.
        Pop    BX      ;s2-text addr
        Push   BX      ;addr back to stack
        Mov    AH,0    ;zero
        Mov    DX,-1   ;char offset counter
        Dec    BX      ;addr-1
;scan to first non-terminator char
encl1:  Inc    BX      ;addr+1
        Inc    DX      ;count+1
        Cmp    AL,[BX]
        Jz     encl1   ;wait for non-terminator
        Push   DX      ;offset to 1st text chr
        Cmp    AH,[BX] ;null char?
        Jnz    encl2   ;no
;found null before 1st non-terminator char.
        Mov    AX,DX   ;copy counter
        Inc    DX      ;+1
        Jmp    DPush
;found 1st text char,count the charecters
encl2:  Inc    BX      ;addr+1
        Inc    DX      ;count+1
        Cmp    AL,[BX] ;terminator char?
        Jz     encl4   ;yes
        Cmp    AH,[BX] ;null cahr
        Jnz    encl2   ;no,loop again
;found null at end of text
encl3:  Mov    AX,DX   ;counters are equal
        Jmp    DPush
;found terminator character
encl4:  Mov    AX,DX
        Inc    AX      ;count +1
        Jmp    DPush

;       ++ emit ++
        DB     84H
        DB     'emi','t'+80H
        DW     encl-0aH
emit    DW     docol
        DW     permit
        DW     one,outt
        DW     psout,semis

;       ++ key ++
        DB     83H
        DB     'ke','y'+80H
        DW     Emit-7
key     DW     $+2
        Jmp    pkey

;       ++ ?terminal ++
        DB     89H
        DB     '?termina','l'+80H
        DW     key-6
qterm   DW     $+2
        Jmp    pqter

;       ++ cr ++
        DB     82H
        DB     'c','r'+80H
        DW     qterm-0cH
cr      DW     $+2
        Jmp    pcr

;       ++ cmove ++
        DB     85H
        DB     'cmov','e'+80H
        DW     cr-5
CMove   DW     $+2
        CLD            ;inc direction
        Mov    BX,SI   ;save ip
        Pop    CX      ;count
        Pop    DI      ;destination
        Pop    SI      ;source
        Mov    AX,DS
        Mov    ES,AX   ;ES->DS
        Rep    MovsB   ;thats the move
        Mov    SI,BX;get back ip
        Jmp    next

;       ++ u* ++
        DB     82H
        DB     'u','*'+80H
        DW     cmove-8
UStar   DW     $+2
        Pop    AX
        Pop    BX
        Mul    BX      ;unsignet
        XChg   AX,DX   ;AX now= msw
        Jmp    dpush   ;store duoble word

;       ++ u/ ++
        DB     82H
        DB     'u','/'+80H
        DW     ustar-5
USlas   DW     $+2
        Pop    BX      ;divisor
        Pop    DX      ;msw of divident
        Pop    AX      ;lsw of divident
        Cmp    DX,BX   ;divide by zero
        Jnb    dzero   ;zero divide, no way
        Div    BX      ;16 bit divide
        Jmp    dpush   ;store quot/rem
;divide by zero error
DZero:  Mov    AX,-1
        Mov    DX,AX
        Jmp    dpush

;       ++ and ++
        DB     83H
        DB     'an','d'+80H
        DW     uslas-5
andd    DW     $+2     ;(s1)<-(s1) and (s2)
        Pop    AX
        Pop    BX
        And    AX,BX
        Jmp    apush

;       ++ or ++
        DB     82H
        DB     'o','r'+80H
        DW     andd-6
orr     DW     $+2     ;(s1)<-(s1) or (s2)
        Pop    AX
        Pop    BX
        Or     AX,BX
        Jmp    apush

;       ++ xor ++
        DB     83H
        DB     'xo','r'+80H
        DW     orr-5
xorr    DW     $+2     ;(s1)<-(s1) xor (s2)
        Pop    AX
        Pop    BX
        Xor    AX,BX
        jmp    apush

;       ++ sp@ ++
        DB     83H
        DB     'sp','@'+80H
        DW     xorr-6
SpAt    DW     $+2     ;(s1)<-(sp)
        Mov    AX,SP
        Jmp    apush

;       ++ sp! ++
        DB     83H
        DB     'sp','!'+80H
        DW     spat-6
SpSto   DW     $+2
        Mov    BX,up   ;user var base addr
        Mov    SP,6[BX];reset param. stack pt.
        Jmp    next

;       ++ rp@ ++
        DB     83H
        DB     'rp','@'+80H
        DW     spsto-6
RpAt    DW     $+2     ;(si)<-(bp)
        Mov    AX,BP   ;return stack addr
        Jmp    apush

;       ++ rp! ++
        DB     83H
        DB     'rp','!'+80H
        DW     rpat-6
RpSto   DW     $+2
        Mov    BX,up   ;(AX)<-usr var. base
        Mov    Bp,8[BX];reset return stack pt.
        Jmp    next

;       ++ ;s ++
        DB     82H
        DB     ';','s'+80H
        DW     rpsto-6
semis   DW     $+2
        Mov    SI,[BP] ;(ip)<-(r1)
        Inc    BP
        Inc    BP      ;adjust stack
        Jmp    next

;       ++ leave ++
        DB     85H
        DB     'leav','e'+80H
        DW     semis-5
leave   DW     $+2     ;limit<-index
        Mov    AX,[BP] ;get index
        Mov    2[BP],AX;store it at limit
        jmp    next

;       ++ >r ++
        DB     82H
        DB     '>','r'+80H
        DW     leave-8
ToR     DW     $+2     ;(r1)<-(s1)
        Pop    BX      ;get stack parameter
        Dec    BP
        Dec    BP      ;move return stack down
        Mov    [BP],BX ;onto return stack
        Jmp    next

;       ++ r> ++
        DB     82H
        DB     'r','>'+80H
        DW     tor-5
FromR   DW     $+2     ;(s1)<-(r1)
        Mov    AX,[BP] ;get return stack value
        Inc    BP      ;delete from stack
        Inc    BP
        Jmp    apush

;       ++ r ++
        DB     81H
        DB     'r'+80H
        DW     fromr-5
rr      DW     ido+2

;       ++ 0= ++
        DB     82H
        DB     '0','='+80H
        DW     rr-4
ZEqu    DW     $+2
        Pop    AX
        Or     AX,AX   ;do test
        Mov    AX,1    ;true
        JZ     zequ1   ;its zero
        Dec    AX      ;false
ZEqu1:  Jmp    apush

;       ++ 0< ++
        DB     82H
        DB     '0','<'+80H
        DW     zequ-5
ZLess   Dw     $+2
        Pop    AX
        Or     AX,AX   ;do test
        Mov    AX,1    ;true
        Js     zless1
        Dec    AX      ;false
ZLess1: Jmp    apush

;       ++ + ++
        DB     81H
        DB     '+'+80H
        DW     zless-5
Plus    DW     $+2     ;(s1)<-(s1)+(s2)
        Pop    AX
        Pop    BX
        Add    AX,BX
        Jmp    apush

;       ++ d+ ++
;XLW XHW  YLW YHL -> SLW SHW
;s4  s3   s2  s1     s2  s1
        DB     82H
        DB     'd','+'+80H
        DW     plus-4
DPlus   DW     $+2
        Pop    AX      ;yhw
        Pop    DX      ;ylw
        Pop    BX      ;xhw
        Pop    CX      ;xlw
        Add    DX,CX   ;slw
        Adc    AX,BX   ;shw
        Jmp    dpush

;       ++ minus ++
        DB     85H
        DB     'minu','s'+80H
        DW     dplus-5
Minus   DW     $+2
        Pop    AX
        Neg    AX
        Jmp    apush

;       ++ dminus ++
        DW     86H
        DB     'dminu','s'+80H
        DW     minus-8
DMinu   DW     $+2
        Pop    BX
        Pop    CX
        Sub    AX,AX   ;zero
        Mov    DX,AX
        Sub    DX,CX   ;make 2's complement
        Sbb    AX,BX   ;high word
        Jmp    dpush

;       ++ over ++
        DB     84H
        DB     'ove','r'+80H
        DW     dminu-9
Over    DW     $+2
        Pop    DX
        Pop    AX
        Push   AX
        Jmp    dpush

;       ++ drop ++
        DB     84H
        DB     'dro','p'+80H
        DW     over-7
Drop    DW     $+2
        Pop    AX
        Jmp    Next

;       ++ swap ++
        DB     84H
        DB     'swa','p'+80H
        DW     drop-7
Swap    DW     $+2
        Pop    DX
        Pop    AX
        Jmp    dpush

;       ++ dup ++
        DB     83H
        DB     'du','p'+80H
        DW     swap-7
Dupp    DW     $+2
        Pop    AX
        Push   AX
        Jmp    apush

;       ++ 2dup ++
        DB     84H
        DB     '2du','p'+80H
        DW     dupp-6
TDup    DW     $+2
        Pop    AX
        Pop    DX
        Push   DX
        Push   AX
        Jmp    dpush

;       ++ +! ++
        DB     82H
        DB     '+','!'+80H
        DW     tdup-7
PStor   DW     $+2     ;((s1))<-((s1))+(s2)
        Pop    BX      ;address
        Pop    DX      ;increment
        Add    [BX],DX
        Jmp    next

;       ++ toggle ++
        DB     86H
        DB     'toggl','e'+80H
        DW     pstor-5
Toggl   DW     $+2
        Pop    AX      ;bit pattern
        Pop    BX      ;addr
        XOr    [BX],AL
        Jmp    next

;       ++ @ ++
        DB     81H
        DB     '@'+80H
        DW     toggl-9
At      DW     $+2     ;(s1)<-((s1))
        Pop    BX
        Mov    Ax,[BX]
        Jmp    apush

;       ++ c@ ++
        DB     82H
        DB     'c','@'+80H
        DW     at-4
CAt     DW     $+2     ;(s1)<-((s1))PTR Byte
        Pop    BX
        Mov    AL,[BX]
        Sub    AH,AH
        Jmp    next

;       ++ 2@ ++
        DB     82H
        DB     '2','@'+80H
        DW     cat-5
TAt     DW     $+2
        Pop    BX      ;addr
        Mov    AX,[BX] ;MSW
        Mov    AX,2[BX];LSW
        Jmp    dpush

;       ++ ! ++
        DB     81H
        DB     '!'+80H
        DW     tat-5
Store   DW     $+2     ;((s1))<-(s2)
        Pop    BX      ;addr
        Pop    AX      ;data
        Mov    [BX],AX
        jmp    next

;       ++ c! ++
        DB     82H
        DB     'c','!'+80H
        DW     store-4
CStor   DW     $+2     ;((s1))Ptr Byte<-(s2)LB
        Pop    BX      ;addr
        Pop    AX      ;data
        Mov    [BX],AL
        Jmp    next

;       ++ 2! ++
        DB     82H
        DB     '2','!'+80H
        DW     cstor-5
TStor   DW     $+2
        Pop    BX      ;addr
        Pop    AX      ;data (HW)
        Mov    [BX],AX
        Pop    AX      ;data (LW)
        Mov    [BX],AX
        Jmp    Next

;       ++ : ++
        DB     0c1H
        DB     ':'+81
        DW     tstor-2
Colon   DW     docol
        DW     qexec
        DW     scsp
        DW     curr
        DW     at
        DW     cont
        DW     store
        DW     creat
        DW     rbrac
        DW     pscod
DoCol:  Inc    DX      ;w=w+1
        Dec    BP
        Dec    BP      ;(rp)<-(rp)-2
        Mov    [BP],SI ;r1<-(rp)
        Mov    SI,DX   ;(ip)<-(w)
        Jmp    next

;       ++ ; ++
        DB     0c1H
        DB     ';'+80H
        DW     colon-4
Semi    DW     docol
        DW     qcsp
        DW     comp
        DW     semis
        DW     smudg
        DW     lbrac
        DW     semis

;       ++ noop ++
        DB     84H
        DB     'noo','p'+80H
        DW     semi-4
Noop    DW     docol
        DW     semis

;       ++ constant ++
        DB     88H
        DB     'constan','t'+80H
        DW     noop-7
Con     DW     docol
        DW     creat
        DW     smudg
        DW     comma
        DW     pscod
DoCon:  Inc    DX      ;pfa
        Mov    BX,DX
        Mov    AX,[BX] ;get data
        Jmp    apush

;       ++ variable ++
        DB     88H
        DB     'variabl','e'+80H
        DW     con-0bH
Var     DW     docon
        DW     con
        DW     pscod
DoVar:  Inc    DX      ;(DE)<-pfa
        Push   DX      ;(s1)<-pfa
        Jmp    next

;       ++ user ++
        DB     84H
        DB     'use','r'+80H
        DW     var-0bH
user    DW     docol
        DW     con
        DW     pscod
DoUse:  Inc    DX      ;pfa
        Mov    BX,DX
        Mov    BL,[BX]
        Sub    BH,BH
        Mov    DI,up   ;user variable addr
        Lea    AX,[BX+DI] ;addr of variable
        Jmp    apush

;       ++ 0 ++
        DB     81H
        DB     '0'+80H
        DW     user-7
zero    DW     docon
        DW     0

;       ++ 1 ++
        DB     81H
        DB     '1'+80H
        DW     zero-4
one     DW     docon
        DW     1

;       ++ 2 ++
        DB     81H
        DB     '2'+80H
        DW     one-4
two     DW     docon
        DW     2

;       ++ 3 ++
        DB     81H
        DB     '3'+80H
        DW     two-4
three   DW     docon
        DW     3

;       ++ bl ++
        DB     82H
        DB     'b','l'+80H
        DW     three-4
bls     DW     docon
        DW     20H

;       ++ c/l ++
        DB     83H     ;characters/line
        DB     'c','l'+80H
        DW     bls-5
csll    DW     docon
        DW     64

;       ++ first ++
        DB     85H
        DB     'firs','t'+80H
        DW     csll-6
first   DW     docon
        DW     buf1

;       ++ limit ++
        DB     85H
        DB     'limi','t'+80H
        DW     first-8
limit   DW     docon
        DW     em

;       ++ b/buf ++
        DB     85H     ;bytes/buffer
        DB     'b/bu','f'+80H
        DW     limit-8
bbuf    DW     docon
        DW     kbbuf

;       ++ b/scr ++
        DB     85H
        DB     'b/sc','r'+80H
        DW     bbuf-8
bscr    DW     docon
        DW     400H/kbbuf

;       ++ +origin ++
        DB     87H
        DB     '+origi','n'+80H
        DW     bscr-8
porig   DW     docol
        DW     lit
        DW     orig
        DW     plus
        DW     semis

;========= User Variables =====================

;       ++ s0 ++
        DB     82H
        DB     's','0'+80H
        DW     porig-0aH
szero   DW     douse
        DW     6

;       ++ r0 ++
        DB     82H
        DB     'r','0'+80H
        DW     szero-5
rzero   DW     douse
        DW     8

;       ++ tib ++
        DB     83H
        DB     'ti','b'+80H
        DW     rzero-5
tib     DW     douse
        DW     0aH

;       ++ width ++
        DB     85H
        DB     'widt','h'+80H
        DW     tib-6
widtt   DW     douse
        DW     0cH

;       ++ warning ++
        DB     87H
        DB     'warnin','g'+80H
        DW     widtt-8
warn    DW     douse
        DW     0eH

;       ++ fence ++
        DB     85H
        DB     'fenc','e'+80H
        DW     warn-0aH
fence   DW     douse
        DW     10H

;       ++ dp ++
        DB     82H
        DB     'd','p'+80H
        DW     fence-8
dp      DW     douse
        DW     12H

;       ++ voc-link ++
        DB     88H
        DB     'voc-lin','k'+80H
        DW     dp-5
vocl    DW     douse
        DW     14H

;       ++ blk ++
        DB     83H
        DB     'bl','k'+80H
        DW     vocl-0bH
blk     DW     douse
        DW     16H

;       ++ in ++
        DB     82H
        DB     'i','n'+80H
        DW     blk-6
inn     DW     douse
        DW     18H

;       ++ out ++
        DB     83H
        DB     'ou','t'+80H
        DW     inn-5
outt    DW     douse
        DW     1aH

;       ++ scr ++
        DB     83H
        DB     'sc','r'+80H
        Dw     outt-6
scr     DW     douse
        DW     1cH

;       ++ offset ++
        DB     86H
        DB     'offse','t'+80H
        DW     scr-6
ofset   DW     douse
        DW     1eH

;       ++ context ++
        DB     87H
        DB     'contex','t'+80H
        DW     ofset-9
cont    DW     douse
        DW     20H

;       ++ current ++
;       DB     87H
        DB     'curren','t'+80H
        DW     cont-0aH
curr    DW     douse
        DW     22H

;       ++ state ++
        DB     85H
        DB     'stat','e'+80H
        DW     curr-0aH
state   DW     douse
        DW     24H

;       ++ base ++
        DB     84H
        DB     'bas','e'+80H
        DW     state-8
base    DW     douse
        DW     26H

;       ++ dpl ++
        DB     83H
        DB     'dp','l'+80H
        DW     base-7
dpl     DW     douse
        DW     28H

;       ++ fld ++
        DB     83H
        DB     'fl','d'+80H
        DW     dpl-6
fld     DW     douse
        DW     2aH

;       ++ csp ++
        DB     83H
        DB     'cs','p'+80H
        DW     fld-6
cspp    DW     douse
        DW     2cH

;       ++ r# ++
        DB     82H
        DB     'r','#'+80H
        DW     cspp-6
rnum    DW     douse
        DW     2eH

;       ++ hld ++
        DB     83H
        DB     'hl','d'+80H
        DW     rnum-5
hld     DW     douse
        DW     30H

;========= End Of User Variables ==============

;       ++ 1+ ++
        DB     82H
        DB     '1','+'+80H
        DW     hld-6
onep    DW     docol
        DW     one
        DW     plus
        DW     semis

;       ++ 2+ ++
        DB     82H
        DB     '2','+'+80H
        DW     onep-5
twop    DW     docol
        DW     two
        DW     plus
        DW     semis

;       ++ here ++
        DB     84H
        DB     'her','e'+80H
        DW     twop-5
here    DW     docol
        DW     dp
        DW     at
        DW     semis

;       ++ allot ++
        DB     85H
        DB     'allo','t'+80H
        DW     here-7
allot   DW     docol
        DW     dp
        DW     pstor
        DW     semis

;       ++ , ++
        DB     81H
        DB     ','+80H
        DW     allot-8
comma   DW     docol
        DW     here
        DW     store
        DW     two
        DW     allot
        DW     semis

;       ++ c, ++
        DB     82H
        DB     'c',','+80H
        DW     comma-4
ccomm   DW     here
        DW     cstor
        DW     one
        DW     allot
        DW     semis

;       ++ - ++
        DB     81H
        DB     '-'+80h
        DW     ccomm-5
subb    DW     $+2
        Pop    DX      ;S1
        Pop    AX      ;S2
        Sub    AX,DX   ;AX:=S1-S2
        Jmp    apush

;       ++ = ++
        DB     81H
        DB     '='+80h
        DW     subb-4
equal   DW     docol
        DW     subb
        DW     zequ
        DW     semis

;       ++ < ++
        DB     81H
        DB     '<'+80H ; X  <  Y
        DW     equal-4 ; S2 <  S1
less    DW     $+2
        Pop    DX      ;S1
        Pop    AX      ;S2
        Mov    BX,DX
        XOR    BX,AX   ;test for equal signs
        JS     les1    ;signs not the same
        Sub    AX,DX
les1:   Or     AX,AX   ;test sign bit
        Mov    AX,0    ;assume false condition
        JNS    les2    ;not less then
        Inc    AX      ;true (1)
les2:   Jmp    apush

;       ++ u< ++

