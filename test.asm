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
colNum:			.equ RAM + $00
counter:		.equ RAM + $01
temp:			.equ RAM + $02
counter2:		.equ RAM + $03
strobe:			.equ RAM + $07
lampRow1:		.equ RAM + $08
lampRow8:		.equ lampRow1 + 7 
displayBcd1:	.equ RAM + $10

switchRow1:		.equ RAM + $20
switchRow8:		.equ switchRow1 + 7 
solenoid1:		.equ RAM + $30
solenoid8:		.equ solenoid1 + 7
solenoid16:		.equ solenoid1 + 15
curLampRow:		.equ RAM + $50
curSwitchRow:	.equ RAM + $52


main:		.org $7800
	
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
	
	ldaA	#$F0
	staA	lampRow1
	
	ldX 	#lampRow1
	stX		curLampRow
	
	ldX		#switchRow1
	stX		curSwitchRow
	
; fill solenoid status with off
	ldaA		#255
	ldX		#solenoid1
lSolDefault:
	staA	0, X
	inX
	cpX		#solenoid16
	ble		lSolDefault
	
; setup complete
	
loop:
	inc		counter
	ldaA	#0
	cmpA	counter
	bne		counterHandled
	inc 	counter2
	cmpA	counter2
	bne		counterHandled
	
	ldaA	#$F0
	cmpA	lampRow1
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
	oraA	colNum	
	ldaB 	#$FF
	staB	displayBcd
	staA	displayStrobe
	ldaB	displayBcd1
	staB	displayBcd
	
; read switches
	ldaA	switchRow
	ldX		curSwitchRow
	staA	0, x
	
	comA
	staA	lampRow1 ; for debugging
	
; update lamps
	ldaA	#$FF
	staA	lampRow
	ldaA	strobe
	staA	lampStrobe
	ldaA	lampRow1
	staA	lampRow
	ldaA	#00

; update solenoids
	; if a solenoid is set to <254, --
	; if =255, off, otherwise on
	; leave it at 254
	ldX		#solenoid1
	
	ldaB	#00000000b ; new solenoid state
lSolUpdate:
	lsrB	
	ldaA	#254
	cmpA	0, X
	ifgt
		dec 0, X
	endif
	cmpA	0, X
	ifge ; turn on solenoid
		addB	#10000000b;
	endif
	cpX		#solenoid8
	ifeq ;save first bank, reset for second
		staB	solenoidA
		ldaB	#00000000b ; new solenoid state
	endif
	
	inX
	cpX		#solenoid16
	ble		lSolUpdate ; end loop
	staB	solenoidB
	
; update strobe	
	inc 	colNum
	inc		curLampRow+1
	inc		curSwitchRow+1
	ldaA	#0
	asl		strobe
	cmpA	strobe ; strobe done?  reset
	ifeq		
		ldaA	#00000001b
		staA	strobe
		
		ldX 	#lampRow1
		stX		curLampRow
		
		ldX		#switchRow1
		stX		curSwitchRow
	endif
	jmp		loop
	
end:
	bra		end
	
	
interrupt:	
	rti

pointers: 	.org $7FF8  	; is this right?
	.msfirst
	.dw interrupt			
	.dw interrupt			
	.dw interrupt			
	.dw main
	
	
	.end