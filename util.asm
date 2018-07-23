utils:	.org $7800 + $500
; call at end of switch handler to jump back to loop
#DEFINE noValidate ldaA 10b\ oraA >state\ staA state
#DEFINE done(v)	\
#DEFCONT	#IF (v==0)
#DEFCONT		\ ldaA 10b
#DEFCONT		\ oraA >state
#DEFCONT		\ staA state
#DEFCONT	\#ENDIF
#DEFCONT	\ jmp afterQueueEvent

; copy players' scores to display 
copyScores13:
	ldX	displayBcd1 + 1 + eRAM ; start at strobe 2
	ldaB	$FF	; blank(F) until a number >0 is found then 0
copy13Loop:
	ldaA	(pA_1m-eRAM) - (displayBcd1+1), X
	andA	$0F
	cmpA	$00 
	ifeq ; if pA score = 0?
		cpX	(displayBcd1+1+eRAM) + 5 ; at strobe 7
		ifeq
			; change B from F (blank) to 0 (0)
			andB	00001111b 
			ldaA	$0F
		else
			tBA	; replace 0 with blank/0
		endif
	else
		aslA
		aslA
		aslA
		aslA
		andB	00001111b ; mark upper half of B as 0 since number found
		oraA	00001111b
	endif
	andA	pC_1m-eRAM - (displayBcd1+1), X
	
	;andA	$F0
	bitA	00001111b
	ifeq ; pC is 0
		bitB	1111b
		ifne
			cpX	(displayBcd1+1+eRAM) + 5
			ifeq
				andB	11110000b
			else
				oraA	$F
			endif
		endif
	else
		andB	11110000b
	endif
	staA	0, X
	
	inX
	cpX	displayBcd1+eRAM + 8
	bne 	copy13Loop
	
	rts

copyScores24:
	ldX	displayBcd1 + 9 + eRAM
	ldaB	$FF	; blank(F) until a number >0 is found then 0
copy24Loop:
	ldaA	pB_1m-eRAM - (displayBcd1 + 9), X
	andA	$0F
	cmpA	$00 ; is pA score 0?
	ifeq ; if pA score = 0?
		cpX	displayBcd1 + 9 + 5 + eRAM
		ifeq
			andB	00001111b 
			ldaA	$0F
		else
			tBA	; replace 0 with blank/0
		endif
	else
		aslA
		aslA
		aslA
		aslA
		andB	00001111b ; mark upper half of B as 0 since number found
		oraA	00001111b
	endif
	andA	pD_1m-eRAM - (displayBcd1 + 9), X
	bitA	00001111b
	ifeq ; pC is 0
		bitB	1111b
		ifne
			cpX	displayBcd1 + 9 + 5 + eRAM
			ifeq
				andB	11110000b
			else
				oraA	$F
			endif
		endif
	else
		andB	11110000b
	endif
	staA  0, X 
	
	inX
	cpX	displayBcd1 + 16 + eRAM
	bne copy24Loop	
	
	rts
	
blankNonPlayerScores:
	ldaB	>lc(1) ; gameover
	bitB	lr(4)
	ifne
		rts
	endif
	
	ldaB	>playerCount ; 1 can play
	cmpB	1
	beq	blankP2
	cmpB	2
	beq	blankP3
	cmpB	3
	beq	blankP4
	cmpB	4
	beq	blankDone
	bra	blankP1
blankP1:
	ldaA	$F0
	oraA	>displayBcd1 + 6
	staA	displayBcd1 + 6
	ldaA	$F0
	oraA	>displayBcd1 + 7
	staA	displayBcd1 + 7
blankP2:
	ldaA	$F0
	oraA	>displayBcd1 + 15 - 1
	staA	displayBcd1 + 15 - 1
	ldaA	$F0
	oraA	>displayBcd1 + 16 - 1
	staA	displayBcd1 + 16 - 1
blankP3:
	ldaA	$0F
	oraA	>displayBcd1 + 6
	staA	displayBcd1 + 6
	ldaA	$0F
	oraA	>displayBcd1 + 7
	staA	displayBcd1 + 7
blankP4:
	ldaA	$0F
	oraA	>displayBcd1 + 15 - 1
	staA	displayBcd1 + 15 - 1
	ldaA	$0F
	oraA	>displayBcd1 + 16 - 1
	staA	displayBcd1 + 16 - 1
blankDone:
	rts
	
refreshPlayerScores:
	jsr copyScores13
	jsr copyScores24
	
	jmp blankNonPlayerScores
	
	
; add score instantly
; X = place in p*_1* to add the score to
; A = amount to add (max 9)
; trashes AX
_addScoreI:
	addA	0, X
	oraA	11110000b
	ifcs ; overflowed, need to increment next number
		addA	6	; adjust A back into BCD
		oraA	$F0
		staA	0, X
addScore_carryOver:		; loop to propagate carry
		deX	; go to next decimal place
		ldaA	0, X	
		oraA	11110000b
		cmpA	$F9
		ifeq			; if it's already a 9, reset it and carry again
			clr	0, X
			beq addScore_carryOver
		else			; otherwise ++ it and done
			inc	0, X
		endif	
	else
		cmpA	$F9
		ifgt ; >9 -> need to adjust back into BCD
			addA	6
			oraA	$F0
			staA	0, X
addScore_carryDa:
			deX
			ldaA	0, X
			oraA	11110000b
			cmpA	$F9
			ifeq
				clr	0, X
				beq 	addScore_carryDa
			else
				inc	0, X
			endif	
		else
			oraA	$F0
			staA	0, X
		endif
	endif
	rts
; B: amount to subtract
_decScoreI:
	ldaA	0, X
	andA	$0F
	sBA ; A = score - B
	ifmi ; went below 0
decScore_rolled:
		ldaB	10
		aBA	; A += 10
		oraA	$F0
		staA	0, X
		deX
		ldaA	0, X
		andA	$0F
		decA
		ifmi
			bra	decScore_rolled
		else
			oraA	$F0
			staA	0, X
		endif
	else
		oraA	$F0
		staA	0, X
	endif

	rts

	
; t X
setXToCurPlayer10:
	pshA
	ldaA	>curPlayer + 1
	cmpA	0
	bne	_addScore10N_p2
	ldX	pA_10
	pulA
	rts
_addScore10N_p2:
	cmpA	1
	bne	_addScore10N_p3
	ldX	pB_10
	pulA
	rts
_addScore10N_p3:
	cmpA	2
	bne	_addScore10N_p4
	ldX	pC_10
	pulA
	rts
_addScore10N_p4:
	ldX	pD_10
	pulA
	rts

; blanks any leading zeroes in the temp score except the last 2
; t X
blankTempScoreZeroes:
	ldX	pT_1m
l_blankTempScoreZeroes:
	ldaA	0, X
	oraA	$F0
	cmpA	$F0
	ifeq
		ldaA	$FF
		staA	0, X
	else
		rts
	endif
	inX
	cpX	pT_10 - 1
	bne	l_blankTempScoreZeroes
	
	rts

; A: player number to overwrite
; t X
copyTempScoreToPlayer:
	bitA	1b
	ifeq ; bit 0 clear -> player 1/3
		ldX	displayBcd1 + 1 + eRAM
	else ; bit 1 set -> player 2/4
		ldX	displayBcd1 + 9 + eRAM
	endif
l_copyTempScoreToPlayer:
	bitA	10b
	ifeq ; player 1/2 -> replace higher bits
		ldaB	0, X
		andB	$0F
		aslB
		aslB
		aslB
		aslB
		bitA	1b
		ifeq ; bit 0 clear -> player 1/3
			ldaB	pT_1m - (displayBcd1 + 1 + eRAM), X
		else
			ldaB	pT_1m - (displayBcd1 + 9 + eRAM), X
		endif
		bitB 	1b



		rolB
		rolB
		rolB
		rolB

		staB	0, X
		bitA	1b
		ifeq ; bit 0 clear -> player 1/3
			ldaB	pT_1m - (displayBcd1 + 1 + eRAM), X
		else
			ldaB	pT_1m - (displayBcd1 + 9 + eRAM), X
		endif
		seC
		rolB
		rolB
		rolB
		rolB
		oraB	0, X
		staB	0, X
	else
		ldaB	0, X
		andB	$F0
		ifeq ; bit 0 clear -> player 1/3
			oraB	pT_1m - (displayBcd1 + 1 + eRAM), X
		else
			oraB	pT_1m - (displayBcd1 + 9 + eRAM), X
		endif
		staB	0, X
	endif
	inX

	bitA	1b
	ifeq ; bit 0 clear -> player 1/3
		cpX	displayBcd1 + 8 + eRAM
	else
		cpX	displayBcd1 + 16 + eRAM
	endif
	bne l_copyTempScoreToPlayer

	bitA	1b
	ifeq ; bit 0 clear -> player 1/3
		ldaB	>displayBcd1+7
		andB	$F0
		staB	displayBcd1+7
	else
		ldaB	>displayBcd1+15
		andB	$F0
		staB	displayBcd1+15
	endif
	rts


; suspends execution for A ms and returns to queue processor
; stores B in waitC
; should only be called from switch callbacks
; trashes X, condition codes
_delay:	
	ldX	waitLeft - 1
delay_findEmptyLoop:
	inX
	tst	0, X
	bne 	delay_findEmptyLoop 
	
	; X = first waitLeft that = 0
	staB	waitC - waitLeft, X

	pulB	; B = MSB of PC
	staB	waitMsb - waitLeft, X

	pulB	; B = LSB of PC
	staB	waitLsb - waitLeft, X

	staA	0, X

	pulB	; B = B before delay() call
	staB	waitB - waitLeft, X

	pulB	; B = A before delay() call
	staB	waitA - waitLeft, X

	tPA
	staA	waitC - waitLeft, X

	; time and add stored
	jmp skipEvent
	
_fork:	
	ldX	waitLeft - 1
fork_findEmptyLoop:
	inX
	tst	0, X
	bne 	fork_findEmptyLoop 
	
	; X = first waitLeft that = 0
	staB	waitC - waitLeft, X

	pulB	; B = MSB of PC
	staB	waitMsb - waitLeft, X

	pulB	; B = LSB of PC
	addB	3
	ifcs
		inc	waitMsb - waitLeft, X
	endif
	staB	waitLsb - waitLeft, X

	staA	0, X

	pulB	; B = B before delay() call
	staB	waitB - waitLeft, X

	pulA	; B = A before delay() call
	staA	waitA - waitLeft, X

	; time and add stored
	subB	3
	pshB
	ldaB	waitMsb - waitLeft, X
	ifcs
		decB
	endif
	pshB
	rts

; queues timer to jump to X after A ms
; B = control bytes
_forkSr:
	stX	waitX
	ldX	waitLeft - 1
forkSr_findEmptyLoop:
	inX
	tst	0, X
	bne 	forkSr_findEmptyLoop 
	
	; X = first waitLeft that = 0
	staB	waitC - waitLeft, X
	staA	0, X

	ldaA	>waitX + 0
	staA	waitMsb - waitLeft, X
	ldaA	>waitX + 1
	staA	waitLsb - waitLeft, X

	deS ; need to skip over return address
	deS

	pulB	; B = B before delay() call
	staB	waitB - waitLeft, X

	pulA	; B = A before delay() call
	staA	waitA - waitLeft, X

	pshA
	pshB

	inS
	inS

	rts
	
; cancels all waiting threads with the given id
; A: 3 bit thread id
cancelThreads:
	pshB
	ldX	waitLeft - 1
l_cancelThread:
	inX
	ldaB	waitC - waitLeft, X
	andB	111b
	cBA
	ifeq
		clr	0, X
	endif
	cpX	waitLeftEnd
	bne 	l_cancelThread 

	pulB
	rts
	
resetScores:
	ldaA	$F0
	ldX	pA_1m
_zeroScores:
	staA	0, X
	inX
	cpX	pD_10 + 1
	bne	_zeroScores
	
	ldaA	$00
	staA	curPlayer
	staA	curPlayer + 1
	ldaA	$FF
	staA	displayBcd1 + 6
	staA	displayBcd1 + 14
	staA	displayBcd1 + 15
	
	jsr	refreshPlayerScores
	rts

blankTempPlayer:
	; clear player
	ldaA	$FF
	staA	pT_1m + 0
	staA	pT_1m + 1
	staA	pT_1m + 2
	staA	pT_1m + 3
	staA	pT_1m + 4
	staA	pT_1m + 5
	rts

specialOn5:

	rts
specialOff5:

	rts
specialOn6:

	rts
specialOff6:

	rts


; trash AX
; delay for ms (8-2000)
#DEFINE delay(ms) pshA\ pshB\ ldaA ms/8\ clrB\ jsr _delay
#DEFINE delayC(ms,C) pshA\ pshB\ ldaA ms/8\ ldaB C\ jsr _delay
; makes a second thread that will skip the next (3b) instructions after \ms ms
#DEFINE fork(ms) pshA\ pshB\ ldaA ms/8\ clrB\ jsr _fork
#DEFINE forkC(ms,C) pshA\ pshB\ ldaA ms/8\ ldaB C\ jsr _fork
#DEFINE beginFork()	
#DEFINE endFork()	ldX >forkX\ jmp afterFork

#DEFINE forkSrC(label,ms,C) pshA\ pshB\ ldX label\ ldaA ms/8\ ldaB C\ jsr _forkSr\ pulB\ pulA
	
; trashes B (max 104ms)
#DEFINE fireSolenoid(s)	ldaB ((s&$FF)/8)|$F0\ staB solenoid1+(s>>8)-1 
#DEFINE fireSolenoidA(s)	ldaA ((s&$FF)/8)|$F0\ staA solenoid1+(s>>8)-1 

; trashes AX
; place: 1-5 = 10s thru 100ks
; amount: 1-9
#DEFINE addScoreI(place,amount)		ldX pB_10-place+1\ ldaA 0+amount\ jsr _addScoreI
#DEFINE addScoreI_T(place,amount)	ldX pB_10-place+1\ ldaA 0+amount\ jmp _addScoreI
#DEFINE addScore(place,amount)		ldX pB_10-place+1\ ldaA 0+amount\ jsr _addScore
#DEFINE addScore_T(place,amount)	ldX pB_10-place+1\ ldaA 0+amount\ jmp _addScore
#DEFINE addScoreN(place,amount)		ldX pB_10-place+1\ ldaA 0+amount\ jsr _addScoreN
#DEFINE addScoreN_T(place,amount)	ldX pB_10-place+1\ ldaA 0+amount\ jmp _addScoreN

#define disablePf ldaA 	>solenoidBC\ andA 11110111b\ staA solenoidBC
#define enablePf ldaA 	>solenoidBC\ oraA 00111000b\ staA solenoidBC

#define lampOn(r,c) ldaA lr(r)\ oraA >lc(c)\ staA lc(c)
#define flashLamp(r,c) ldaA lr(r)\ oraA >flc(c)\ staA flc(c)
#define flashLampFast(r,c) ldaA lr(r)\ oraA >fflc(c)\ staA fflc(c)
#define lampOff(r,c) ldaA ~lr(r)\ andA >lc(c)\ staA lc(c)
#define flashOff(r,c) ldaA ~lr(r)\ andA >flc(c)\ staA flc(c)
#define flashFastOff(r,c) ldaA ~lr(r)\ andA >fflc(c)\ staA fflc(c)

#include "attract.asm"
