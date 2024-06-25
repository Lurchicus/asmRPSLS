; *************************************************************************
; * A Rock Paper Scissors Lizard Spock game in x86 64bit NASM by Dan Rhea *
; * following the rules created by by Sam Kass and Karen Bryla.           *
; *                                                                       *
; * rpsls.asm                                                             *
; *                                                                       *
; * Extended rules (beyond Rock, Paper Scissors)                          *
; * Spock smashes scissors and vaporizes rock                             *
; * Spock is poisoned by lizard and disproven by paper                    *
; * Lizard poisons Spock and eats paper                                   *
; * Lizard is crushed by rock and decapitated by scissors                 *
; *************************************************************************

BITS 64

section	.data

; ************************************************************************
; Constants
; ************************************************************************

NOFLOAT	equ	0	; Non-floating point output for Printf (non-float)
XITCMD	equ	60	; Exit opcode (syscall)
WRITEC	equ	1	; Write syscall
NORMAL	equ	0	; Normal exit flag
STDOUT	equ	1	; Standard output
ADLEN	equ	8	; Address length in bytes
BLEN	equ	1	; Address length in bytes
ONE	equ	1	; One constant
ZERO 	equ	0	; Zero constant

; ************************************************************************
; Command strings (proxies)
; This contains the individual command strings, a byte list of proxy 
; numeric values and a list of addresses for the start of each null 
; terminated string.
; ************************************************************************
	proxrck	db	"rock",0		; 0 
	proxpap	db	"paper",0		; 1
	proxsrs	db	"scissors",0		; 2
	proxliz	db	"lizard",0		; 3
	proxspk	db	"spock",0		; 4

	phelp	db	"help",0		; 5 (help request)
	plice	db	"license",0		; 6 (license info... MIT)
	pscor	db	"score",0		; 7 (score request)
	pdbug	db	"debug",0		; 8 (debug mode)
	pquit	db	"quit",0		; 9 (quit request)
	pend 	db	"end",0			; list end address

	verbnum	db	0, 1, 2, 3, 4, 5, 6, 7, 8, 9

	saddr	dq	$proxrck, $proxpap, $proxsrs, $proxliz, $proxspk
		dq	$phelp, $plice, $pscor, $pdbug, $pquit
	eaddr	dq	$pend

; ************************************************************************
; Action verb text
; This is a list of actions that describe a "combat" resolution (for
; example: rock vs paper, rock "is covered by" paper). 
; The following contains five groups of five strings that describe all the
; possible resolutions and a list of the start addres of each null
; terminated string.
;
; Lookup calculation: addr+(((PLAYERGUESS*5)+COMPGUESS)*ADLEN)
;		      verbadd+(((PLAYERGUESS*5)+COMPGUESS)*8)
; ************************************************************************
;			Rock
	rck_rck	db	"matches",0		; Rock (Computer select)
	rck_pap	db	"is covered by",0	; Paper
	rck_srs	db	"smashes",0		; Scissors
	rck_liz	db	"crushes",0		; Lizard
	rck_spk	db	"is vaporized by",0	; Spock
;			Paper
	pap_rck	db	"covers",0		; Rock
	pap_pap	db	"matches",0		; Paper
	pap_srs	db	"is cut by",0		; Scissors
	pap_liz	db	"is eaten by",0		; Lizard
	pap_spk	db	"disproves",0		; Spock
;			Scissors
	srs_rck	db	"are broken by",0	; Rock
	srs_pap	db	"cuts",0		; Paper
	srs_srs	db	"matches",0		; Scissors
	srs_liz	db	"decapitates",0		; Lizard
	srs_spk	db	"are smashed by",0	; Spock
;			Lizard
	liz_rck	db	"is crushed by",0	; Rock
	liz_pap db	"eats",0		; Paper
	liz_srs	db	"is decapitated by",0	; Scissors
	liz_liz	db	"matches",0		; Lizard
	liz_spk	db	"poisons",0		; Spock
;			Spock
	spk_rck	db	"vaporizes",0		; Rock
	spk_pap	db	"is disproved by",0	; Paper
	spk_srs	db	"smashes",0		; Scissors
	spk_liz	db	"is poisoned by",0	; Lizard
	spk_spk	db	"matches",0		; Spock
	;		End address
	av_end	equ	$
; Array of verb addresses (proxy index * 5)
	verbadd	dq	$rck_rck, $rck_pap, $rck_srs, $rck_liz, $rck_spk
		dq	$pap_rck, $pap_pap, $pap_srs, $pap_liz, $pap_spk
		dq	$srs_rck, $srs_pap, $srs_srs, $srs_liz,	$srs_spk
		dq	$liz_rck, $liz_pap, $liz_srs, $liz_liz,	$liz_spk
		dq	$spk_rck, $spk_pap, $spk_srs, $spk_liz, $spk_spk
		dq	$av_end

; ************************************************************************
; Results map lookup table
; The following table is used to determine a win or loss condition for the
; player (1: player win, -1: Computer win, 0: Tie). The calculation to 
; lookup the action verb above is the same for a lookup into this table.
; Also included is the result text and starting address for each null
; terminated string. 
;
; Lookup calculation: resaddr+(((PLAYERGUESS*5)+COMPGUESS)*BLEN)
;		      outcome+(((PLAYERGUESS*5)+COMPGUESS)*1)
;*************************************************************************
;                        rck pap srs liz spk     byte int
	outcome	db	 0, -1,  1,  1,  1	; Rock
		db	 1,  0, -1, -1,  1	; Paper
		db	-1,  1,  0,  1, -1	; Scissors
		db	-1,  1, -1,  0,  1	; Lizard
		db	 1, -1,  1, -1,  0	; Spock
;			1: Player win, -1: Computer win, 0: Tie
	playwin	db	"Player wins over computer!",0	; 1
	compwin	db	"Player loses to computer!",0	; -1
	bothtie	db	"Player ties with computer!",0	; 0
	rsltend	equ	$
; Result addresss
	rsltadd	dq	$playwin, $compwin, $bothtie, $rsltend

; ************************************************************************
; Score and "round" info
; ************************************************************************
	pscore	dq	0	; Player score
	cscore	dq	0	; Computer score
	ties	dq	0	; Tie results
	rounds	dq	0	; Round counter
	cmdnum	db	0	; Command number

; Flags
	debugf	dq	0	; 0: no debug, 1: debug

; Generic string
	sto	db	"%s",0
	stonl	db	0x1b,"[1;32m"
		db	"%s",10,0
	nlst	db	0x1b,"[1;34m"
		db	"Input string was: "
		db	0x1b,"[1;37m","%s",10,0

					; VT escape code: 
	ltWhite	db	0x1b,"[1;37m"	; Light white
	ltYellow db	0x1b,"[1;33m" 	; Light yellow
	ltBlue	db	0x1b,"[1;34m"	; Light blue
	ltGreen	db	0x1b,"[1;32m"	; Light green
	red 	db	0x1b,"[0;31m"	; Red

; ************************************************************************
; Splash screen, help screen and prompt text  
; ************************************************************************
	splashs	db	0x1b,"[1;34m" 
		db	"RPSLS v1.0 a Rock, Paper, Scissors, Lizard, "
		db	"Spock game by Dan Rhea, 2024",10
		db	"as designed by Sam Kass and Karen Bryla. "
		db	"Licensed under the MIT License.",10,10,0
; Help
	helps	db	0x1b,"[1;34m"
		db	"Enter 'rock' 'paper' 'scissors' 'lizard' or "
		db	"'spock' to play a round or",10
		db	"the commands 'help' 'license' 'score' 'debug' "
		db	"or 'quit'.",10,10,0
; Prompt
	prompts	db	0x1b,"[1;33m"
		db	"rpsls: "
		db	0x1b,"[1;37m"
	plen	equ	$-prompts
; Goodbye
	bye	db	0x1b,"[1;37m"
		db	"Done! Thanks for playing.",10,0

	stest	db	"String: Player selected action verb:'%s'.",10,0

	CGUESS	equ	4
	PGUESS	equ	1

	NL	db	0xa	; newline	
	inlen	equ	32	; Max buffer length

section	.bss

	inbuf	resb	inlen+1	; room for string and a null terminator

section	.text

extern	printf		; Use the c library printf procedure

	global	main
main:
	push	rbp		; prologue
	mov	rbp, rsp

	mov	rax, ZERO	; Init debug toggle off
	mov	[debugf], rax	; Save it

	;mov	rax, NOFLOAT
	;mov	rdi, stest
	;mov	rsi, [verbadd+(((PGUESS*5)+CGUESS)*ADLEN)] 
	;call	printf

; Show splash
splash:
	mov	rax, NOFLOAT	; non-float output
	mov	rdi, sto	; string format (%s)
	mov	rsi, splashs	; text to output
	call	printf

; Show help (basic commands)
help:
	mov	rax, NOFLOAT
	mov	rdi, sto
	mov	rsi, helps
	call	printf

; Show prompt
prompt:
	mov	rax, WRITEC	; Write
	mov	rdi, STDOUT	; Standard out
 	mov	rsi, prompts	; Player prompt
	mov	rdx, plen	; Prompt length
	syscall

; Get input from player
	mov	rdi, inbuf	; Input buffer
	mov	rsi, inlen	; Buffer length
	call	reads

; for now, echo input and exit
	mov	rax, NOFLOAT
	mov	rdi, nlst
	mov	rsi, inbuf
	call	printf

; Convert input to numeric offset (0-4, 5-9) (proxies and commands)

; This starts with traversing the command address table (starts
; at saddr). 
; For now just output the strings the addresses point to.
	mov	rdx, saddr	; Address of command address table
shocmd:	mov	rax, NOFLOAT	; Ascii'ish data
	mov	rdi, stonl	; Output format
	mov	rsi, [rdx]	; Command string
	push	rdx		; Save rdx contents
	call	printf		; Output the string
	pop	rdx		; Restore rdx
	add	rdx, ADLEN	; Bump to the next 64bit address
	cmp	rdx, eaddr	; This the end of the address table?
	je	endit		; Yes, finish
	jmp	shocmd		; No, get the next command string
endit:	jmp	end		; For now

; Get random pick for computer
; Process commands if one is selected
;	5: Show help again (go to help)
dohelp:
	jmp	help		; show help and reprompt

;	6: Show MIT license
; 	7: Show current score
;	8: Toggle debug (verbose info)
debug:
	push	rax		; Save the rax register
	mov	rax, [debugf]	; Get the current debug flag setting
	cmp 	rax, ONE	; Is it a one
	jz	skipoff		; No, go toggle on
	mov	rax, ZERO	; Yes, set toggle off
	jmp	savetg		; skip toggle on
skipoff:
	mov	rax, ONE	; Set toggle on
savetg:	
	mov	[debugf], rax	; Save new toggle value
	pop	rax		; Restore the rax register
	jmp	prompt		; reprompt

;	9: Quit (show score and quit)
quit:
	; show score then exit
	jmp	end
;	0-4: Determine outcome based on proxies
; update scores
; Output round resuts
; Update round
; Go to prompt
	jmp	prompt		; reprompt

end:
	mov	rax, NOFLOAT
	mov	rdi, sto
	mov	rsi, bye
	call	printf

	mov	rsp, rbp	; epilogue
	pop	rbp

	mov	rax, XITCMD	; exit
	mov	rdi, NORMAL	; normal exit
	syscall

; *********************************************************************
; * reads ("safe" string reader), from                                *
; * Beginning x64 Assembly Programming by Jo Van Hoey (Pages 163-165) * 
; * I have redone the comments to insure I understand what the        *
; * procedure does and how it works.                                  *
; *********************************************************************
reads:

section	.data

section	.bss

	.inputc	resb	1	; Single character

section	.text

	push	rbp
	mov	rbp, rsp
	push	r12		; save registers for argument use
	push	r13
	push	r14
	mov	r12, rdi	; Address of input buffer
	mov	r13, rsi	; Max length to r13
	xor	r14, r14	; Character counter
.readc:
	mov	rax, 0		; Read opcode
	mov	rdi, 1		; Set stdin
	lea	rsi, [.inputc]	; Input address
	mov	rdx, 1		; characters to read
	syscall
	mov	al, [.inputc]	; Input...
	cmp	al, byte[NL]	; a newline?
	je	.done		; end of input
	cmp	al, 97		; less than 'a'?
	jl	.readc		; Yes, ignore it
	cmp	al, 122		; Greater than 'z'?
	jg	.readc		; Yes, ignore as well
	inc	r14		; Increment 'valid' input count
	cmp	r14, r13	; max input?
	ja	.readc		; Ignore stuff that would overflow the buffer
	mov	byte [r12], al	; Save safe byte to buffer
	inc	r12		; point to next byte in buffer
	jmp	.readc		; get next character
.done:
	inc	r12		; bump buffer pointer
	mov	byte [r12], 0	; zero terminate the buffer
	pop	r14		; restore registers
	pop	r13
	pop	r12
leave
ret

