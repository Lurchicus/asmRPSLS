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

NOFLOAT	equ	0	; Non-floating point output for Printf (non-float)
XITCMD	equ	60	; Exit opcode (syscall)
WRITEC	equ	1	; Write syscall
NORMAL	equ	0	; Normal exit flag
STDOUT	equ	1	; Standard output
ADLEN	equ	8	; Address length in bytes
ONEW	equ	0x0000000000000001
ONEB	equ	0x0001
ZEROW	equ	0x0000000000000000
ZEROB	equ	0x0000

; Character proxies (input strings) and commands
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

	verbnum	db	0, 1, 2, 3, 4, 5, 6, 7, 8, 9

; Input address array
	saddr	dq	$proxrck, $proxpap, $proxsrs, $proxliz, $proxspk
		dq	$phelp, $plice, $pscor, $pdbug, $pquit

; Action verb text	Rock (player select)
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

; Array of verb addresses (proxy index * 5)
	verbadd	dq	$rck_rck, $rck_pap, $rck_srs, $rck_liz, $rck_spk
		dq	$pap_rck, $pap_pap, $pap_srs, $pap_liz, $pap_spk
		dq	$srs_rck, $srs_pap, $srs_srs, $srs_liz,	$srs_spk
		dq	$liz_rck, $liz_pap, $liz_srs, $liz_liz,	$liz_spk
		dq	$spk_rck, $spk_pap, $spk_srs, $spk_liz, $spk_spk
	
; Results map           rck pap srs liz spk     byte int
	outcome	db	 0, -1,  1,  1,  1	; Rock
		db	 1,  0, -1, -1,  1	; Paper
		db	-1,  1,  0,  1, -1	; Scissors
		db	-1,  1, -1,  0,  1	; Lizard
		db	 1, -1,  1, -1,  0	; Spock
;			1: Player win, -1: Computer win, 0: Tie

	playwin	db	"Player loses to computer!",0	; -1
	compwin	db	"Player wins over computer!",0	; 1
	bothtie	db	"Player ties with computer!",0	; 0

; Result addresss
	rsltadd	dq	$playwin, $compwin, $bothtie

; Score
	pscore	dq	0	; Player score
	cscore	dq	0	; Computer score
	ties	dq	0	; Tie results
	rounds	dq	0	; Round counter

; Flags
	debugf	dq	0	; 0: no debug, 1: debug

; Generic string
	sto	db	"%s",0
	nlst	db	"\n%s\n",0

; Splash screen
	splashs	db	"RPSLS v1.0 a Rock, Paper, Scissors, Lizard, Spock game by Dan Rhea, 2024",10
		db	"as designed by Sam Kass and Karen Bryla. Licensed under the MIT License.",10,10,0

; Help
	helps	db	"Enter 'rock' 'paper' 'scissors' 'lizard' or 'spock' to play a round or",10
		db	"the commands 'help' 'license' 'score' 'debug' or 'quit'.",10,10,0

; Prompt
	prompts	db	"rpsls: ",0
	plen	equ	$-prompts

	stest	db	"String: Player selected action verb:'%s'.",10,0

	CGUESS	equ	4
	PGUESS	equ	1

	NL	db	0xa	; newline
	inlen	equ	32	; Max buffer length

section	.bss

	inbuf	resb	inlen+1	; add room for string and a null terminator

section	.text

extern	printf		; We will be using the c library printf procedure

	global	main
main:
	push	rbp		; prologue
	mov	rbp, rsp

	;mov	rax, NOFLOAT
	;mov	rdi, stest
	;mov	rsi, [verbadd+((PGUESS*5)+CGUESS)*ADLEN] 
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
; Prompt doesn't seem to want to work with printf so I will try it with a
; stdout syscall... it worked!
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
;	lea	rsi, [inbuf]	; Didn't help
	mov	rsi, inbuf
	call	printf

	jmp	end		; For now

; Convert input to numeric offset (0-4, 5-9) (proxies and commands)
; Get random pick for computer
; Process commands if one is selected
;	5: Show help again (go to help)
dohelp:
	jmp	help		; show help and reprompt

;	6: Show MIT license
; 	7: Show current score
;	8: Toggle debug (verbose info)
debug:
	push	rax
	mov	rax, debugf
	and	rax, 0x0000000000000001
	jz	seton
	mov	rax, 0x0000000000000000
	mov	[debugf], rax
	jmp	setoff
seton:
	mov	rax, 0x0000000000000001
	mov	[debugf], rax
setoff:
	pop	rax
	jmp	prompt

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
	mov	r14, r14	; Character counter
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

