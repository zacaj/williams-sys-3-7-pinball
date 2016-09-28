#include "680xlogic.asm"

displayStrobe: 	.equ $2800
displayBcd: 	.equ $2802
displayStrobeC:	.equ $2801
displayBcdC:	.equ $2803
lampRow:		.equ $2400
lampRowC:		.equ $2401
lampStrobe:		.equ $2402
lampStrobeC:	.equ $2403
switchStrobe:	.equ $3002
switchStrobeC:	.equ $3003
switchRow:		.equ $3000
switchRowC:		.equ $3001
solenoidA:		.equ $2200
solenoidAC		.equ $2201
solenoidB:		.equ $2202
solenoidBC:		.equ $2203

RAM:			.equ $0000
cRAM:			.equ $0100
temp:			.equ RAM + $00
counter:		.equ RAM + $02
counter2:		.equ RAM + $03
strobe:			.equ RAM + $07
lampRow1:		.equ RAM + $08
lampRow8:		.equ lampRow1 + 7 
displayBcd1:	.equ RAM + $10

switchRow1:		.equ RAM + $20
switchRow8:		.equ switchRow1 + 7 
solAStatus:		.equ RAM + $28
solBStatus:		.equ RAM + $29
solenoid1:		.equ cRAM + $00
solenoid8:		.equ solenoid1 + 7
solenoid9:		.equ solenoid1 + 8
solenoid16:		.equ solenoid1 + 15
curCol:			.equ RAM + $50
curSwitchRowLsb	.equ RAM + $52

none:	.org $6000 + 128
	rts
	
	.msfirst
switchTable: 	.org $6000
	.dw none \.dw none \.dw none \.dw none \.dw none \.dw none \.dw none \.dw none
	.dw none \.dw none \.dw none \.dw none \.dw none \.dw none \.dw none \.dw none
	.dw none \.dw none \.dw none \.dw none \.dw none \.dw none \.dw none \.dw none
	.dw none \.dw none \.dw none \.dw none \.dw none \.dw none \.dw none \.dw none
	.dw none \.dw none \.dw none \.dw none \.dw none \.dw none \.dw none \.dw none
	.dw none \.dw none \.dw none \.dw none \.dw none \.dw none \.dw none \.dw none
	.dw none \.dw none \.dw none \.dw none \.dw none \.dw none \.dw none \.dw none
	.dw none \.dw none \.dw none \.dw none \.dw none \.dw none \.dw none \.dw none
main:		.org $7800
	
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
	staA 	solenoidBC
	
;

	ldaA	#00
	staB	displayBcd1
	
	ldaA	#$FF	
	staA 	displayStrobe

	ldaA	#00
	staA	strobe
	
	ldX 	#0
	
	ldaA	#0
	staA	curSwitchRowLsb
	
; fill solenoid status with off
	ldaA	#$FF
	stX		curCol	;save old X
	ldX		#solenoid1
lSolDefault:
	staA	0, X
	inX
	cpX		#solenoid16
	ble		lSolDefault
	
	ldX		curCol ; restore X
	
; setup complete
	clI		; enable timer interrupt
	
	
end:
	jmp		end
	.dw 0
	.dw 0
	.dw 0
	.dw 0
	.dw 0
		
interrupt:	
	ldX		curCol
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
	staA	lampRow1
	ldaA	#01110111b
	staA	displayBcd1	
	bra		counterHandled
on:
	ldaA	#$0F
	staA	lampRow1
	ldaA	#00110011b
	staA	displayBcd1	

counterHandled:
; move switch column
	ldaA	strobe
	staA	switchStrobe
	
; update display 
	ldaA	#11110000b	
	oraA	counter
	ldaB 	#$FF
	staB	displayBcd
	staA	displayStrobe
	ldaB	displayBcd1
	staB	displayBcd
	
; read switches
	ldaA	switchRow
	tab
	eorA	switchRow1, X ; A contains any switches that have changed state
	staB	switchRow1, X
	staB	temp
	andA	temp	; A contains any switches that have turned on
	
	;stX		curCol	
	;ldaA	curCol + 1
	;bne		swNext		; skip add if A = 0
	;ldaB	#0
;swAddRow:
	;addB	#16
	;decA
	;bne		swAddRow	; loop will A = 0
	ldaB	curSwitchRowLsb 	;	B now contains LSB of switchTable row addr
	staB	temp + 1
	ldaB	#switchTable >> 8
	staB	temp
	; temp now contains the beginning of the row in the switchTable
swNext:
	bitA	#00000001b ; Z set if switch not turned on
	ifne		; if bit set, switch turned on
		ldX		temp	
		ldX		0, X
		jsr		0, X
	endif
	inc temp + 1
	inc temp + 1
	asrA			; pop lowest bit off, set Z if A is empty
	bne		swNext 	; more on bits, keep processing 
	
	ldX		curCol
	
; update lamps
	ldaA	#$FF	;lamp row is inverted
	staA	lampRow
	ldaA	strobe
	staA	lampStrobe
	ldaA	lampRow1, X
	staA	lampRow
	ldaA	#00

; update solenoids
	; if a solenoid is set to <254, --
	; if =255, off, otherwise on
	; leave it at 254
	
	inc		curCol
	ldX		curCol
	ldaA	#254
	ldaB	solenoid1 - cRAM, X
	cmpA	solenoid1 - cRAM, X
	ifge 	; solenoid <=254, turn on
		ifgt	; solenoid < 254, decrement
			dec		solenoid1 - cRAM, X
		endif
		sec
	else
		clc
	endif
	ror		solAStatus
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
	dec		curCol
	ldX		curCol
	
; update strobe	
	inX 	
	ldaA	#16
	addA	curSwitchRowLsb
	staA	curSwitchRowLsb
	asl		strobe
	ldaA	#0
	cmpA	strobe ; strobe done?  reset
	ifeq		
		ldaA	solAStatus
		staA	solenoidA
		ldaA	solBStatus
		staA	solenoidB
	
		ldaA	#00000001b
		staA	strobe
		
		ldX 	#0
		
		ldaA	#0
		staA	curSwitchRowLsb
		staA	solAStatus
		staA	solBStatus
	endif
	
	stX		curCol
	rti

pointers: 	.org $7FF8  	
	.msfirst
	.dw interrupt			
	.dw interrupt			
	.dw interrupt			
	.dw main
	
	
	.end