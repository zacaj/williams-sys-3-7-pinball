utils:	.org $7800 + $400

; copy players' scores to display 
copyScores13:
	ldX	displayBcd1
	ldaB	$FF	; blank(F) until a number >0 is found then 0
copy13Loop:
	ldaA	pA_1m - displayBcd1, X
	andA	$0F
	cmpA	$00 
	ifeq ; if pA score = 0?
		cpX	displayBcd1 + 5
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
	andA	pC_1m - displayBcd1, X
	
	;andA	$F0
	bitA	00001111b
	ifeq ; pC is 0
		bitB	1111b
		ifne
			cpX	displayBcd1 + 5
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
	cpX	displayBcd1 + 6
	bne 	copy13Loop
	
	rts

copyScores24:
	ldX	displayBcd1 + 8
	ldaB	$FF	; blank(F) until a number >0 is found then 0
copy24Loop:
	ldaA	pB_1m - (displayBcd1 + 8), X
	andA	$0F
	cmpA	$00 ; is pA score 0?
	ifeq ; if pA score = 0?
		cpX	displayBcd1 + 8 + 5
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
	andA	pD_1m - (displayBcd1 + 8), X
	;andA	$F0
	bitA	00001111b
	ifeq ; pC is 0
		bitB	1111b
		ifne
			cpX	displayBcd1 + 8 + 5
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
	cpX	displayBcd1 + 14
	bne copy24Loop	
	
	rts
	
blankNonPlayerScores:
	ldaB	>lc(8) ; gameover
	bitB	lr(6)
	ifne
		rts
	endif
	
	ldaB	>lc(7)
	bitB	lr(2)
	bne	blankP2
	bitB	lr(3)
	bne	blankP3
	bitB	lr(4)
	bne	blankP4
	bitB	lr(5)
	bne	blankDone
	bra	blankP1
blankP1:
	ldaA	$F0
	oraA	>displayBcd1 + 4
	staA	displayBcd1 + 4
	ldaA	$F0
	oraA	>displayBcd1 + 5
	staA	displayBcd1 + 5
blankP2:
	ldaA	$F0
	oraA	>displayBcd1 + 12
	staA	displayBcd1 + 12
	ldaA	$F0
	oraA	>displayBcd1 + 13
	staA	displayBcd1 + 13
blankP3:
	ldaA	$0F
	oraA	>displayBcd1 + 4
	staA	displayBcd1 + 4
	ldaA	$0F
	oraA	>displayBcd1 + 5
	staA	displayBcd1 + 5
blankP4:
	ldaA	$0F
	oraA	>displayBcd1 + 12
	staA	displayBcd1 + 12
	ldaA	$0F
	oraA	>displayBcd1 + 13
	staA	displayBcd1 + 13
blankDone:
	rts
	
refreshPlayerScores:
	jsr copyScores13
	jsr copyScores24
	
	ldaA	$F0
	cmpA	>pA_1m
	bne	refresh_1m
	cmpA	>pB_1m
	bne	refresh_1m	
	cmpA	>pC_1m
	bne	refresh_1m
	cmpA	>pD_1m
	bne	refresh_1m
	
	ldX	displayBcd1
refresh_10xloop:
	ldaA	1, X
	staA	0,X
	ldaA	8 + 1, X
	staA	8, X
	inX
	cpX	displayBcd1+5
	bne	refresh_10xloop
	ldaA	0
	staA	displayBcd1 + 5
	staA	displayBcd1 + 5 + 8
	jmp blankNonPlayerScores
refresh_1m:
	jmp blankNonPlayerScores
	
	
; add score instantly
; X = place in p*_1* to add the score to
; A = amount to add (max 9)
; tail call
_addScoreI:
	addA	0, X
	oraA	11110000b
	ifcs ; overflowed, need to increment next number
		addA	6	; adjust A back into BCD
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
			staA	0, X
		endif
	endif

	jmp refreshPlayerScores
	
	rts
	
; t A,X
setXToCurPlayer10:
	ldaA	>lc(8)
	bitA	0001b
	beq	_addScore10N_p2
	ldX	pA_10
	rts
_addScore10N_p2:
	bitA	0010b
	beq	_addScore10N_p3
	ldX	pB_10
	rts
_addScore10N_p3:
	bitA	0100b
	beq	_addScore10N_p4
	ldX	pC_10
	rts
_addScore10N_p4:
	ldX	pD_10
	rts

; suspends execution for A ms and returns to queue processor
; should only be called from switch callbacks
; trashes everything but B
_delay:	
	ldX	waitLeft - 1
findEmptyLoop:
	inX
	tst	0, X
	bne 	findEmptyLoop 
	
	; X = first waitLeft that = 0
	staB	waitReg - waitLeft, X
	pulB	; A = MSB of PC
	staB	waitMsb - waitLeft, X
	pulB	; A = LSB of PC
	staB	waitLsb - waitLeft, X
	staA	0, X
	; time and add stored
	jmp skipEvent
	
resetScores:
	ldaA	00
	ldX	pA_1m
_zeroScores:
	staA	0, X
	inX
	cpX	pD_10 + 1
	bne	_zeroScores
	
	ldaA	0
	staA	curPlayer
	staA	curPlayer + 1
	ldaA	$FF
	staA	displayBcd1 + 6
	staA	displayBcd1 + 14
	staA	displayBcd1 + 15
	
	jsr	refreshPlayerScores
	rts

; trash ~B
; delay for ms (8-2000)
#DEFINE delay(ms) ldaA ms/8\ jsr _delay
	
; trashes B (max 104ms)
#DEFINE fireSolenoid(s)	ldaB (s&$FF)/8\ staB solenoid1+(s>>8)-1 
#DEFINE fireSolenoidA(s)	ldaA (s&$FF)/8\ staA solenoid1+(s>>8)-1 

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
#define lampOff(r,c) ldaA ~lr(r)\ andA >lc(c)\ staA lc(c)
#define flashOff(r,c) ldaA ~lr(r)\ andA >flc(c)\ staA flc(c)

#include "attract.asm"
