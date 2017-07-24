utils:	.org $7800 + $2FF

; copy players' scores to display 
copyScores13:
	ldX	displayBcd1
	ldaB	$FF	; blank(F) until a number >0 is found then 0
copy13Loop:
	ldaA	pA_1m - displayBcd1, X
	andA	$0F
	cmpA	$00 
	ifeq ; if pA score = 0?
		cpX	displayBcd1 + 4
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
	;andA	pC_1m - displayBcd1, X
	
	andA	$F0
	bitA	00001111b
	ifeq ; pC is 0
		bitB	1111b
		ifne
			cpX	displayBcd1 + 4
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
		cpX	displayBcd1 + 8 + 4
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
	;andA	pD_1m - (displayBcd1 + 8), X
	andA	$F0
	bitA	00001111b
	ifeq ; pC is 0
		bitB	1111b
		ifne
			cpX	displayBcd1 + 8 + 4
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
	ldaB	lc(7)
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
	jsr blankNonPlayerScores
	rts
	
; X = place in p*_1* to add the score to
; A = amount to add (max 9)
; tail call
_addScore:
	addA	0, X
	ifcs ; overflowed, need to increment next number
		addA	6	; adjust A back into BCD
		staA	0, X
addScore_carryOver:		; loop to propagate carry
		deX	; go to next decimal place
		ldaA	0, X	
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

_delay:	
	ldX	waitLeft - 1
findEmptyLoop:
	inX
	ldaA	0, X
	bne 	findEmptyLoop ; ld sets Z if = 0
	; X = first waitLeft that = 0
	pulA	; A = MSB of PC
	staA	waitMsb - waitLeft, X
	pulA	; A = LSB of PC
	staA	waitLsb - waitLeft, X
	staB	0, X
	; time and add stored
	jmp afterQueueEvent
	
resetScores:
	ldaA	00
	ldX	pA_10
_zeroScores:
	staA	0, X
	inX
	cpX	pD_1m + 1
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

; trash all
; delay for ms (16-4000)
#DEFINE delay(ms) ldaB ms/16\ jsr _delay
	
; trashes B (max 104ms)
#DEFINE fireSolenoidFor(n,ms)	ldaB ms/8\ staB solenoid1+n-1 
#DEFINE fireSolenoid(n)			fireSolenoidFor(n, 32)

; trashes AX
; place: 1-5 = 10s thru 100ks
; amount: 1-9
#DEFINE addScore(place,amount)		ldX pB_10-place+1\ ldaA 0+amount\ jsr _addScore
#DEFINE addScore_T(place,amount)	ldX pB_10-place+1\ ldaA 0+amount\ jmp _addScore

#define disablePf ldaA 	>solenoidBC\ andA 11110111b\ staA solenoidBC
#define enablePf ldaA 	>solenoidBC\ oraA 00111000b\ staA solenoidBC

#define lampOn(r,c) ldaA lr(r)\ oraA >lc(c)\ staA lc(c)
#define lampOff(r,c) ldaA ~lr(r)\ andA >lc(c)\ staA lc(c)
