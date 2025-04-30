; Globals
zText EQU $FE               ; 16-bit pointer to text string

; ROM Entry Points
COUT  EQU $FDED
TEXT  EQU $FB39
HOME  EQU $FC58

        ORG $800

Main    JSR TEXT
        JSR HOME

PassByGlobal
        LDX #>TextG         ; High byte 16-bit address
        LDY #<TextG         ; Low  byte 16-bit address
        STX zText+1
        STY zText+0
        JSR PrintString

PassByRegs
        LDX #>TextR         ; High byte 16-bit address
        LDY #<TextR         ; Low  byte 16-bit address
        JSR PrintStringXY

PassByStack
        LDA #>TextS         ; Pass args like any high level language
        PHA                 ; such as C, Pascal, etc.
        LDA #<TextS
        PHA
        JSR PrintStringStack
        PLA                 ; Don't forget to remove 16-bit address
        PLA                 ; else we leak stack memory!

PassByPC
        JSR PrintStringPC_RTS
        ASC "Interleave RTS.",8D,00
        JSR PrintStringPC_AbsJMP
        ASC "Interleave ABS JMP.",8D,00
        JSR PrintStringPC_IndJMP
        ASC "Interleave Ind JMP.",8D,00

PassBySelfCaller
        LDX #>TextM         ; High byte 16-bit address
        LDY #<TextM         ; Low  byte 16-bit address
        STX PrintSM+2       ; *** SELF-MODIFIES --->+ ***
        STY PrintSM+1       ; *** SELF-MODIFIES --->+ ***
        JSR PrintStringAbs  ;                       |

PassBySelfCallee
        LDX #>Text2         ; High 16-bit address   |
        LDY #<Text2         ; Low  16-bit address   |
        JSR PrintStringMod  ;                       |
                            ;                       |
        RTS                 ;                       v

;============================                       |
; ON ENTRY:                                         |
;     X = Hi address of string to print             |
;     Y = Lo address of string to print             |
;============================                       |
PrintStringMod              ;                       |
        STX PrintSM+2       ; *** SELF-MODIFIES --->+ ***
        STY PrintSM+1       ; *** SELF-MODIFIES --->+ ***
        ; **INTENTIONAL FALL INTO PrintStringAbs    v

;============================                       |
; ON ENTRY                                          |
;    PrintSM+1,+2 has string address                |
;============================                       |
PrintStringAbs              ;                       |
        LDY #0              ;                       |
PrintSM LDA $C0DE,y         ;     SELF-MODIFIED <---+
        BEQ :Done
        JSR COUT
        INY
        BNE PrintSM
:Done   RTS

;============================
; ON ENTRY:
;     PC+1 = String to print
;============================
PrintStringPC_RTS
        PLA                 ; A = [S] = low
        TAY                 ; JSR pushes PC-1 onto stack
        INY                 ; Skip high byte of JSR in "xxxx:20 lo hi  JSR func"
        PLA                 ; A = [S] = hi
        TAX                 ; X,Y = string
        JSR PrintStringXY
FixRetAddrRTS
        LDA zText+1         ; push high return address
        PHA
        TYA
        CLC                 ; DONT'T skip NULL terminator at end of string
        ADC zText+0         ; Since RTS returns to address-1 on the stack
        PHA                 ; push low return address
        RTS                 ; Simulate JMP

;============================
; ON ENTRY:
;     PC+1 = String to print
;============================
PrintStringPC_AbsJMP
        PLA                 ; A = [S] = low
        TAY                 ; JSR to us pushes PC-1 onto stack
        INY                 ; Skip high byte of JSR in "xxxx:20 lo hi  JSR func"
        PLA                 ; A = [S] = hi
        TAX                 ; X,Y = string
        JSR PrintStringXY
FixRetAddrAbsJMP
        TYA
        SEC                 ; Skip NULL terminator at end of string
        ADC zText+0
        STA :Done+1         ; *** SELF-MODIFIES *** Fixup return address low
        BNE :SamePage
        INC zText+1
:SamePage
        LDA zText+1
        STA :Done+2         ; *** SELF-MODIFIES *** Fixup return address high
:Done   JMP $C0DE           ; **SELF-MODFIED**

;============================
; ON ENTRY:
;     PC+1 = String to print
;============================
PrintStringPC_IndJMP
        PLA                 ; A = [S] = low
        TAY                 ; JSR to us pushes PC-1 onto stack
        INY                 ; Skip high byte of JSR in "xxxx:20 lo hi  JSR func"
        PLA                 ; A = [S] = hi
        TAX                 ; X,Y = string
        JSR PrintStringXY
FixRetAddrIndJMP
        TYA
        SEC                 ; Skip NULL terminator at end of string
        ADC zText+0
        STA zText+0
        BNE :SamePage
        INC zText+1
:SamePage
        JMP (zText)

;============================
; ON ENTRY:
;     [Stack] = 16-bit address of string to print
;============================
PrintStringStack            ;      $100    S+1   S+2   S+3   S+4       $1FF
        TSX                 ; S = [Bot ... RetLo RetHi TxtLo TxtHi ... Top]
        LDA: $104,X         ; A = texthi
        LDY: $103,X         ; Y = textlo
        TAX
        ; **INTENTIONAL FALL INTO PrintStringXY

;============================
; ON ENTRY:
;     X = Hi address of string to print
;     Y = Lo address of string to print
;============================
PrintStringXY
        STX zText+1
        STY zText+0
        ; ***INTENTIONALL FALL INTO PrintString**

;============================
; ON ENTRY:
;     zText+0 = Lo address of string to print
;     zText+1 = Hi address of string to print
; ON EXIT:
;     A = 00
;     Y = String Length (not counting NULL terminator)
;============================
PrintString
        LDY #0
]Print  LDA (zText),y
        BEQ :Done
        JSR COUT
        INY
        BNE ]Print
:Done   RTS

TextG   ASC "Global Var." ,8D,00
TextR   ASC "Reg passing.",8D,00
TextS   ASC "Stack pass." ,8D,00
TextM   ASC "SM Caller. " ,8D,00
Text2   ASC "SM Callee. " ,8D,00
