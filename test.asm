#include "680xlogic.asm"

#include "decls.asm"

#include "util.asm"

#include "game.asm"
	
main:		.org $7800

test:
	
piaSetup:
	ldaA	00000000b	;select direction (3rd bit = 0)
	staA 	displayStrobeC
	ldaA 	00111111b	;set LED pins to outputs
	staA 	displayStrobe
	ldaA 	00000100b 	;select data (3rb bit = 1)
	staA 	displayStrobeC
	ldaA	00000000b
	staA	displayStrobe
	
	ldaA	00000000b	;select direction (3rd bit = 0)
	staA 	displayBcdC
	ldaA 	11111111b	;set display BCD to output
	staA 	displayBcd
	ldaA 	00000100b 	;select data (3rb bit = 1)
	staA 	displayBcdC
	ldaA	00000000b
	staA	displayBcd
	
	ldaA	00000000b	;select direction (3rd bit = 0)
	staA 	lampColC
	ldaA 	11111111b	;set to output
	staA 	lampCol
	ldaA 	00000100b 	;select data (3rb bit = 1)
	staA 	lampColC
	ldaA	00000000b
	staA	lampCol
	
	ldaA	00000000b	;select direction (3rd bit = 0)
	staA 	lampStrobeC
	ldaA 	11111111b	;set to output
	staA 	lampStrobe
	ldaA 	00000100b 	;select data (3rb bit = 1)
	staA 	lampStrobeC
	ldaA	00000000b
	staA	lampStrobe
	
	ldaA	00000000b	;select direction (3rd bit = 0)
	staA 	switchStrobeC
	ldaA 	11111111b	;set to output
	staA 	switchStrobe
	ldaA 	00000100b 	;select data (3rb bit = 1)
	staA 	switchStrobeC
	ldaA	00000000b
	staA	switchStrobe
	
	ldaA	00000000b	;select direction (3rd bit = 0)
	staA 	switchRowC
	ldaA 	00000000b	;set to input
	staA 	switchRow
	ldaA 	00000100b 	;select data (3rb bit = 1)
	staA 	switchRowC
	ldaA	00000000b
	staA	switchRow
	
	ldaA	00000000b	;select direction (3rd bit = 0)
	staA 	solenoidAC
	staA	solenoidBC
	ldaA 	11111111b	;set to output
	staA 	solenoidA
	staA 	solenoidB
	ldaA 	00000100b 	;select data (3rb bit = 1)
	staA 	solenoidAC
	ldaA 	00110100b 	;select data (3rb bit = 1), enable CB2 output low
	staA 	solenoidBC
	

resetRam:
	ldX	RAM
	ldaA	0
resetRamLoop:
	staA	0, X
	inX
	cpX	RAMEnd + 1
	bne	resetRamLoop
	
	
	ldaA 	0
	staA	temp
	ldaA	$FF
	staA	temp + 1
	ldS	>temp
	
;

	ldaA	00
	staB	displayBcd1
	
	ldaA	attractStart >> 8
	staA	attractX
	ldaA	attractStart&$FF
	staA	attractX + 1
	
	ldaA	$FF	
	staA 	displayStrobe

	ldaA	00
	staA	strobe
	staA	displayCol
	
	ldX 	0
	stX		curCol
	
	ldaA	0
	staA	curSwitchRowLsb
	
; fill solenoid status with off
	ldaA	$F
	ldX	solenoid1
lSolDefault:
	staA	0, X
	inX
	cpX	solenoid16
	bne	lSolDefault
	
; clear 8 banks
	ldaA 	0
	ldX	0
lClear8:
	staA	lampCol1, X
	staA	flashLampCol1, X
	staA	waitLeft, X
	inX
	cpX	8
	bne 	lClear8
	
; empty settle
	ldaA	$00
	ldX	settleRow1
lSettleDefault:
	staA	0, X
	inX
	cpX	settleRow8End
	bne	lSettleDefault
	
; empty queue
	ldaA	$FF
	ldX	queue
lEmptyQueue:
	staA	0, X
	inX
	cpX	queueEnd
	bne	lEmptyQueue
	
	ldaA	0
	staA	queueHead + 0
	staA	queueTail + 0
	ldaA	queue
	staA	queueHead + 1
	staA	queueTail + 1
	
; test numbers
	lampOn(6,8) ; game over

	
	jsr resetScores
	
; setup complete
	clI		; enable timer interrupt
	
	
end:
	ldaA	>state
	bitA	100b
	ifne
		; dec wait timers
		ldX	waitLeft - 1
decWaitTimers:
		inX
		ldaA	0, X
		ifne
			decA
			staA	0, X
			ifeq
				ldaA	waitMsb - waitLeft, X
				staA	tempQ
				ldaA	waitLsb - waitLeft, X
				staA	tempQ + 1
				ldaB	waitReg - waitLeft, X
				stX	forkX
				ldX	>tempQ
				jmp	0, X
			endif
		endif
afterFork:
		cpX	waitLeftEnd
		bne	decWaitTimers
		
		
		dec	dropResetTimer
		ifmi
			inc	dropResetTimer
		endif
		
		ldaA	>state		; clear strobe reset bit
		andA	11111011b
		staA	state
	endif

		
; pop queue
	ldaB	>queueTail + 1
	cmpB	>queueHead + 1
	ifeq
		jmp skipQueue
	endif
	
	ldX	>queueHead
	ldaA	0, X	; A now contains the first queue item
	
	tAB
	andB	00111111b ; B = callback index
	
	staB	tempQ + 1
	ldaB	callbackTable >> 8
	staB	tempQ + 0	; callback address LSB / 2
	ldX	>tempQ
	
	ldaB	settleTable - callbackTable, X ; B has settle settings
	bitB 	10000000b ; B.8 set if switch limited to closures
	ifne ; if closure only
		bitA	10000000b ; A.8 set if item was a switch opening
		bne	skipEvent
	endif
	
	bitB	01000000b ; B.7 = active in game over
	ifeq 	 ; not active in game over
		ldaB	>lc(8)	; gameover mask
		bitB	lr(6)
		bne	skipEvent
		ldaB	>lc(8) ; tilt bit
		bitB	lr(5)
		bne	skipEvent
	endif
	
	; checked passed, do callback
	lsl	tempQ + 1 ; double LSB because callback table is 2b wide
	ldX	>tempQ
	ldX	0, X
	jmp	0, X
	; everything trashed
afterQueueEvent:
	jsr 	bonusLights
	
	; update last switch
	ldaA	> tempQ + 1
	lsrA 	; got doubled earlier
	staA	lastSwitch

	ldaA	10b ; no validate bit
	bitA	>state
	ifeq ; validate pf
		; check if playfield invalid
		ldaA	00001111b ; player up
		bitA	>flc(8)
		ifne ; any flashing -> pf invalid
			comA	; turn off flashing
			andA	>flc(8)
			staA	flc(8)
			
			ldaA	lr(1) ; shoot again pf flashing
			bitA	>flc(3)
			ifne
				; turn off ball save
				flashOff(1,3)
				ldaA	lr(7) ; shoot again backbox
				bitA	>lc(8)
				ifeq
					lampOff(1,3) ; shoot again pf
				endif
			else
				lampOff(1,3) ; shoot again
				lampOff(7,8)
			endif
		endif
	else
		; clear don't validate bit
		comA
		andA	>state
		staA	state
	endif
	
skipEvent:
	ldaA	>state
	bitA	100b
	ifeq	; don't process queue if still finishing timers
		ldaB	queueEnd
		cmpB	>queueHead + 1
		ifeq
			ldaB	queue
			staB	queueHead + 1
		else
			inc	queueHead + 1
		endif
	else
		ldX	>forkX
		jmp	afterFork
	endif
				
skipQueue:
				
	
				
	jmp		end
	.dw 0
	.dw 0
	.dw 0
	.dw 0
	.dw 0
		
interrupt:	
	inc	counter
	ldaA	0
	cmpA	>counter
	bne	counterHandled
	
	; attract mode
	ldaA	lr(6) ; gameover
		bitA	> lc(8)
		ifne
		ldX	>attractX
		ldaA	0, X
		staA	lc(2)
		ldaA	1, X
		staA	lc(3)
		ldaA	2, X
		staA	lc(4)
		ldaA	3, X
		staA	lc(5)
		ldaA	4, X
		staA	lc(6)
		ldaA	>attractX + 1
		addA	5
		cmpA	attractEnd&$FF
		ifeq
			ldaA	attractStart&$FF
		endif
		staA	attractX + 1
	endif
	
	inc 	counter2
	ldaA	8
	cmpA	>counter2
	bne	counterHandled
	
	ldaA	10
	cmpA	>p_Bonus
	ifeq
		jsr advanceBonus
	endif
	
	ldaA	0
	staA	counter2
	ldaA	01110111b
	cmpA	>displayBcd1 + 14
	beq	on
	
	ldaA	$F0
	;staA	lampRow1
	ldaA	01110111b
	staA	displayBcd1	 + 14
	bra	counterHandled
on:
	ldaA	$0F
	;staA	lampRow1
	ldaA	00110011b
	staA	displayBcd1	 + 14

counterHandled:
; move switch column
	ldaA	>strobe
	staA	switchStrobe
	
; update display 
	
	ldaA	>$BF
	staA	displayBcd1 + 15
	ldaA	>$6F
	staA	displayBcd1 + 6
	
	ldX	>curCol
	ldaA	>displayCol
	andA	1111b
	ldaB 	$FF
	staB	displayBcd
	staA	displayStrobe
	bitA	00001000b
	ifeq
		ldaB	displayBcd1, X
	else
		ldaB	displayBcd1 + 8, X
	endif
	staB	displayBcd
	
; read switches
	;jmp updateLamps
	ldX	>curCol
	ldaA	>switchRow
	tab
	eorA	switchRow1, X ; A contains any switches that have changed state
	
	ldaB	>curSwitchRowLsb 	;	B now contains LSB of callbackTable row addr
	staB	temp + 1 			; temp = switch / 2
	staB	tempX + 1			; tempX = cRAM
	ldaB	callbackTable >> 8
	staB	temp
	ldaB	cRAM >> 8
	staB	tempX
	
	ldaB	00000001b ; B is the bit of the current switch in row
	
	; temp now contains the beginning of the row in the callbackTable
swNext:
	bitA	00000001b	 ; Z set if switch not different
	ifne		; if bit set, switch different
		pshA ; store changed switches left
		ldX	>tempX
		ldaA	11000b ; want to skip decrementing settle counter 7/8 IRQs
				; but checking 'multiple of 8' would miss 7/8 switch
				; columns completely since they're in sync
				; so instead the lowest bits are empty (so that it'll
				; get all switch cols) and instead it skips 7/8 groups 
				; of 8 IRQs
		bitA	>counter
		beq checkSettled ; counter not multiple of 8, skip settling (multiplies settle time by 8)
			; just check if this is the beginning of the settle
			;  (want to react right away when a switch closes)
			ldaA	0, X ; A now how long the switch has left to settle
			andA	00001111b ; need to remove upper F ( sets Z if A = 0)
			beq 	notSettled; A=0 -> was settled, so can begin
			bra settledEnd
checkSettled:
		ldaA	0, X ; A now how long the switch has left to settle
		andA	00001111b ; need to remove upper F ( sets Z if A = 0)
		beq 	notSettled; A=0 -> settled
		; else A > 0 -> settling
			decA
			staA	0, X	; sets Z if now A = 0
			ifeq ; A=0 -> now settled, fire event
settled:		
				ldX	>curCol
				tBA	; A now the bit in row
				eorA	switchRow1, X ; toggle bit in row
				staA	switchRow1, X ; A now state of row
				
				bitB	>switchRow
				ifne ; switch now on
					ldaA	01000000b
				else
					ldaA	11000000b
				endif
				oraA	>tempX + 1 ; A now contains the event per queue schema
				
				; store event
				ldX	>queueTail
				staA	0, X
				inc	queueTail + 1
				
				; wrap queueTail if necessary
				cpX	queueEnd 
				ifeq
					ldaA	queue 
					staA	queueTail + 1
				endif
			endif
		bra settledEnd
notSettled: ; =0 -> was settled, so now it's not
			; get the settle time
			ldaA	>tempX + 1
			staA	temp + 1 	; get temp in sync with tempX LSB
			ldX	>temp
			
			; temp contains half the address of the callback, so add diff between settleTable and callbackTable
			ldaA	settleTable - callbackTable, X ; A has settle settings
			
			; need to get correct 3 bits from switch settings
			bitB	>switchRow
			ifne ; switch just turned on
				lsrA
				lsrA
			else
				aslA
			endif
			andA	1110b ; A now has 3 bit settle time * 2
						
			ldX	>tempX
			staA	0, X		; start settling	
			beq	settled		; quick out for 0 settle
settledEnd:
			
		pulA
	endif
	inc tempX + 1
	aslB
	lsrA			; pop lowest bit off, set Z if A is empty
	bne		swNext 	; more 'switched' bits, keep processing 
	
	
; update lamps
updateLamps:
	;jmp updateStrobe

	ldX	>curCol
	
	ldaA	$FF	;lamp row is inverted
	staA	lampCol
	ldaA	>strobe
	staA	lampStrobe
	
	ldaB	>counter
	ldaA	lampCol1, X
	bitB	10000000b 
	ifeq
		eorA	flashLampCol1, X
		andA	lampCol1, X
	endif
	comA	; inverted
	
	staA	lampCol
	ldaA	00

; update solenoids
	; if a solenoid is set to <254, --
	; if =255, off, otherwise on
	; else leave it at 254
	
	inc	curCol	; indexed can't use base >255, so temp inc X by 255 (1 MSB)
	ldaA	254
	ldX	>curCol
	; update solenoid in current 'column' (1-8) 
	cmpA	solenoid1 - cRAM, X
	ifge 	; solenoid <=254, turn on
		ifgt	; solenoid < 254, decrement
			dec	solenoid1 - cRAM, X
		endif
		sec
	else
		clc
	endif
	ror	solAStatus ; pushes carry bit (set prev) onto status
	; repeat above for second bank
	cmpA	solenoid9 - cRAM, X
	ifge 	; solenoid <=254, turn on
		ifgt	; solenoid < 254, decrement
			dec	solenoid9 - cRAM, X
		endif
		sec
	else
		clc
	endif
	ror		solBStatus	
	dec		curCol ; undo inc
	
; update strobe	
updateStrobe:
	;ldX		curCol
	;inX 	
	ldaA	8 	; pitch
	addA	>curSwitchRowLsb
	staA	curSwitchRowLsb
	asl	strobe
	inc	displayCol
	ldaA	0
	cmpA	>strobe ; strobe done?  reset
	ifeq		
		ldaA	>solAStatus
		staA	solenoidA
		ldaA	>solBStatus
		staA	solenoidB
	
		ldaA	00000001b
		staA	strobe
		
		;ldX 	#0
		
		ldaA	0
		staA	curCol
		staA	curCol + 1
		staA	curSwitchRowLsb
		staA	solAStatus
		staA	solBStatus
		
		ldaB	>displayCol	; reset display col only if it's > 7 
		oraB	11110000b
		cmpB	$F8	; since it needs to count to 15 instead of 7
		ifgt
			staA	displayCol
		endif
	
		ldaA	>state
		oraA	100b
		staA	state
	else
		inc	curCol + 1
	endif
	
	rti
afterInterrupt:

pointers: 	.org $7FF8  	
	.msfirst
	.dw interrupt			
	.dw interrupt			
	.dw interrupt			
	.dw main
	
	
	.end