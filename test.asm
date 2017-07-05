#include "680xlogic.asm"

#include "decls.asm"

#include "util.asm"

#include "game.asm"

.org	$6000
	nop
	
main:		.org $7800
resetRam:
	ldX		#RAM
	ldaA	#0
resetRamLoop:
	staA	0, X
	inX
	cpX		#RAMEnd + 1
	bne		resetRamLoop
	
	
	ldaA 	#0
	staA	temp
	ldaA	#$FF
	staA	temp + 1
	ldS		temp

test:
	
piaSetup:
	ldaA	#00000000b	;select direction (3rd bit = 0)
	staA 	displayStrobeC
	ldaA 	#00111111b	;set LED pins to outputs
	staA 	displayStrobe
	ldaA 	#00000100b 	;select data (3rb bit = 1)
	staA 	displayStrobeC
	
	ldaA	#00000000b	;select direction (3rd bit = 0)
	staA 	displayBcdC
	ldaA 	#11111111b	;set display BCD to output
	staA 	displayBcd
	ldaA 	#00000100b 	;select data (3rb bit = 1)
	staA 	displayBcdC
	
	ldaA	#00000000b	;select direction (3rd bit = 0)
	staA 	lampRowC
	ldaA 	#11111111b	;set to output
	staA 	lampRow
	ldaA 	#00000100b 	;select data (3rb bit = 1)
	staA 	lampRowC
	
	ldaA	#00000000b	;select direction (3rd bit = 0)
	staA 	lampStrobeC
	ldaA 	#11111111b	;set to output
	staA 	lampStrobe
	ldaA 	#00000100b 	;select data (3rb bit = 1)
	staA 	lampStrobeC
	
	ldaA	#00000000b	;select direction (3rd bit = 0)
	staA 	switchStrobeC
	ldaA 	#11111111b	;set to output
	staA 	switchStrobe
	ldaA 	#00000100b 	;select data (3rb bit = 1)
	staA 	switchStrobeC
	
	ldaA	#00000000b	;select direction (3rd bit = 0)
	staA 	switchRowC
	ldaA 	#00000000b	;set to input
	staA 	switchRow
	ldaA 	#00000100b 	;select data (3rb bit = 1)
	staA 	switchRowC
	
	ldaA	#00000000b	;select direction (3rd bit = 0)
	staA 	solenoidAC
	staA	solenoidBC
	ldaA 	#11111111b	;set to output
	staA 	solenoidA
	staA 	solenoidB
	ldaA 	#00000100b 	;select data (3rb bit = 1)
	staA 	solenoidAC
	ldaA 	#00110100b 	;select data (3rb bit = 1), enable CB2 output low
	staA 	solenoidBC
	
;

	ldaA	#00
	staB	displayBcd1
	
	ldaA	#$FF	
	staA 	displayStrobe

	ldaA	#00
	staA	strobe
	staA	displayCol
	
	ldX 	#0
	stX		curCol
	
	ldaA	#0
	staA	curSwitchRowLsb
	
; fill solenoid status with off
	ldaA	#0
	ldX		#solenoid1
lSolDefault:
	staA	0, X
	staA	waitLeft - solenoid1, X
	inX
	cpX		#solenoid16
	bne		lSolDefault
	
; clear 8 banks
	ldaA 	#0
	ldX	#0
lClear8:
	staA	lampRow1, X
	staA	flashLampRow1, X
	staA	waitLeft, X
	inX
	cpX	#8
	bne 	lClear8
	
; empty settle
	ldaA	#$00
	ldX		#settleRow1
lSettleDefault:
	staA		0, X
	inX
	cpX		#settleRow8 + 7
	bne		lSettleDefault
	
; empty queue
	ldaA	#$FF
	ldX		#queue
lEmptyQueue:
	staA		0, X
	inX
	cpX		#queueEnd
	bne		lEmptyQueue
	
	ldaA	#0
	staA	queueHead + 0
	staA	queueTail + 0
	ldaA	#queue
	staA	queueHead + 1
	staA	queueTail + 1
	
; test numbers
	ldaA	#00010001b
	staA	flashLampRow1 + 2
	ldaA	#$FF
	staA	lampRow1 + 2
	
	; game over
	ldaA	#10000000b
	oraA	lr(6)
	staA	lr(6)

	
	jsr resetScores
	
; setup complete
	clI		; enable timer interrupt
	
	
end:
	ldaA	state
	bitA	#100b
	ifne
		; dec wait timers
		ldX	#waitLeft - 1
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
				ldX	tempQ
				jmp	0, X
			endif
		endif
		cpX	#waitLeftEnd
		bne	decWaitTimers
		
		ldaA	state		; clear strobe reset bit
		andA	#11111011b
		staA	state
	endif

		
; pop queue
	ldaB	queueTail + 1
	cmpB	queueHead + 1
	beq 	skipQueue
	
	ldX		queueHead
	ldaA	0, X	; A now contains the first queue item
	
	tAB
	andB	#00111111b ; B = callback index
	
	staB	tempQ + 1
	ldaB	#callbackTable >> 8
	staB	tempQ + 0	; callback address LSB / 2
	ldX		tempQ
	
	ldaB	settleTable - callbackTable, X ; B has settle settings
	andB 	#10000000b ; B set if switch limited to closures
	ifne
		ldX		queueHead
		andB	0, X	; B set if switch limited to closures and event was not a closure
		bne		skipEvent
	endif
	
	ldaB	#10000000b	; gameover mask
	bitB	lr(6)
	bne	inGameover
	ldaB	#10000000b ; tilt bit
	bitB	lampRow1 + 4
	bne	inGameover
	bra gameoverPassed
inGameover:
	bitA 	#01000000b
	beq	skipEvent	; skip if callback not active in game over
gameoverPassed:
	
	; checked passed, do callback
	lsl		tempQ + 1 ; double LSB because callback table is 2b wide
	ldX		tempQ
	ldX		0, X
	jmp		0, X
	; everything trashed
afterQueueEvent:
	ldaA	#10b ; no validate bit
	bitA	state
	ifeq ; validate
		ldX	curPlayer
		ldaA	#10000000b ; player up
		bitA	flashLampRow1, X
		ifne ; flashing -> invalid
			comA
			andA	flashLampRow1, X
			staA	flashLampRow1, X
		endif
	else
		; clear don't validate bit
		comA
		andA	state
		staA	state
	endif
	
skipEvent:
	ldaA	state
	bitA	#100b
	ifeq	; don't process queue if still finishing timers
		ldaB	#queueEnd
		cmpB	queueHead + 1
		ifeq
			ldaB	#queue
			staB	queueHead + 1
		else
			inc	queueHead + 1
		endif
	endif
				
skipQueue:
				
	
				
	jmp		end
	.dw 0
	.dw 0
	.dw 0
	.dw 0
	.dw 0
		
interrupt:	
	inc		counter
	ldaA	#0
	cmpA	counter
	bne		counterHandled
	inc 	counter2
	ldaA	#4
	cmpA	counter2
	bne		counterHandled
	
	ldaA	#0
	staA	counter2
	ldaA	#01110111b
	cmpA	displayBcd1
	beq		on
	
	ldaA	#$F0
	;staA	lampRow1
	ldaA	#01110111b
	staA	displayBcd1	
	bra		counterHandled
on:
	ldaA	#$0F
	;staA	lampRow1
	ldaA	#00110011b
	staA	displayBcd1	

counterHandled:
; move switch column
	ldaA	strobe
	staA	switchStrobe
	
; update display 
	
	ldX	curCol
	ldaA	displayCol
	ldaB 	#$FF
	staB	displayBcd
	staA	displayStrobe
	bitA	#00001000b
	ifeq
		ldaB	displayBcd1, X
	else
		ldaB	displayBcd1 + 8, X
	endif
	staB	displayBcd
	
; read switches
	;jmp updateLamps
	ldX		curCol
	ldaA	switchRow
	tab
	eorA	switchRow1, X ; A contains any switches that have changed state
	
	ldaB	curSwitchRowLsb 	;	B now contains LSB of callbackTable row addr
	staB	temp + 1 			; temp = switch / 2
	staB	tempX + 1			; tempX = cRAM
	ldaB	#callbackTable >> 8
	staB	temp
	ldaB	#cRAM >> 8
	staB	tempX
	
	ldaB	#00000001b ; B is the bit of the current switch in row
	
	; temp now contains the beginning of the row in the callbackTable
swNext:
	bitA	#00000001b	 ; Z set if switch not different
	ifne		; if bit set, switch different
		pshA ; store changed switches left
		ldX		tempX
		ldaA	#11000b
		bitA	counter
		beq checkSettled ;  skip settling (multiplies settle time by 8)
			; just check if it's currently settled
			ldaA	0, X ; A now how long the switch has left to settle
			andA	#00001111b ; need to remove upper F ( sets Z if A = 0)
			beq 	notSettled; A=0 -> settled
			bra settledEnd
checkSettled:
		ldaA	0, X ; A now how long the switch has left to settle
		andA	#00001111b ; need to remove upper F ( sets Z if A = 0)
		beq 	notSettled; A=0 -> settled
		; else A > 0 -> settling
			decA
			staA	0, X	; sets Z if now A = 0
			ifeq ; A=0 -> now settled, fire event
settled:		
				ldX		curCol
				tBA	; A now the bit in row
				eorA	switchRow1, X ; toggle bit in row
				staA	switchRow1, X ; A now state of row
				
				bitB	switchRow
				ifne ; switch now on
					ldaA	#01000000b
				else
					ldaA	#11000000b
				endif
				oraA	tempX + 1 ; A now contains the event per queue schema
				
				; store event
				ldX		queueTail
				staA	0, X
				inc		queueTail + 1
				
				; wrap queueTail if necessary
				cpX		#queueEnd 
				ifeq
					ldaA	#queue 
					staA	queueTail + 1
				endif
			endif
		bra settledEnd
notSettled: ; =0 -> was settled, so now it's not
			; get the settle time
			ldaA	tempX + 1
			staA	temp + 1 	; get temp in sync with tempX LSB
			ldX		temp
			
			; temp contains half the address of the callback, so add diff between settleTable and callbackTable
			ldaA	settleTable - callbackTable, X ; A has settle settings
			
			; need to get correct 3 bits from switch settings
			bitB	switchRow
			ifne ; switch just turned on
				lsrA
				lsrA
			else
				aslA
			endif
			andA	#1110b ; A now has 3 bit settle time * 2
						
			ldX		tempX
			staA	0, X		; start settling	
			beq		settled		; quick out for 0 settle
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

	ldX		curCol
	
	ldaA	#$FF	;lamp row is inverted
	staA	lampRow
	ldaA	strobe
	staA	lampStrobe
	
	ldaB	counter2
	ldaA	lampRow1, X
	bitB	#1b 
	ifeq
		eorA	flashLampRow1, X
		andA	lampRow1, X
	endif
	comA	; inverted
	
	staA	lampRow
	ldaA	#00

; update solenoids
	; if a solenoid is set to <254, --
	; if =255, off, otherwise on
	; else leave it at 254
	
	inc		curCol	; indexed can't use base >255, so temp inc X by 255 (1 MSB)
	ldaA	#254
	ldX		curCol
	ldaB	solenoid1 - cRAM, X
	; update solenoid in current 'column' (1-8) 
	cmpA	solenoid1 - cRAM, X
	ifge 	; solenoid <=254, turn on
		ifgt	; solenoid < 254, decrement
			dec		solenoid1 - cRAM, X
		endif
		sec
	else
		clc
	endif
	ror		solAStatus ; pushes carry bit (set prev) onto status
	; repeat above for second bank
	cmpA	solenoid9 - cRAM, X
	ifge 	; solenoid <=254, turn on
		ifgt	; solenoid < 254, decrement
			dec		solenoid9 - cRAM, X
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
	ldaA	#8 	; pitch
	addA	curSwitchRowLsb
	staA	curSwitchRowLsb
	asl		strobe
	inc		displayCol
	ldaA	#0
	cmpA	strobe ; strobe done?  reset
	ifeq		
		ldaA	solAStatus
		staA	solenoidA
		ldaA	solBStatus
		staA	solenoidB
	
		ldaA	#00000001b
		staA	strobe
		
		;ldX 	#0
		
		ldaA	#0
		staA	curCol
		staA	curCol + 1
		staA	curSwitchRowLsb
		staA	solAStatus
		staA	solBStatus
		
		ldaB	displayCol	; reset display col only if it's > 7 
		cmpB	#$F8	; since it needs to count to 15 instead of 7
		ifgt
			staA	displayCol
		endif
	
		ldaA	state
		oraA	#100b
		staA	state
	else
		inc	curCol + 1
	endif
	
	rti

pointers: 	.org $7FF8  	
	.msfirst
	.dw interrupt			
	.dw interrupt			
	.dw interrupt			
	.dw main
	
	
	.end