displayStrobe: 	.equ $2800
displayBcd: 	.equ $2802
displayStrobeC:	.equ $2801
displayBcdC:	.equ $2803
lampRow:		.equ $2400
lampRowC:		.equ $2401
lampStrobe:		.equ $2402
lampStrobeC:	.equ $2403

RAM:			.equ $0000
cRAM:			.equ $0100
strobe:			.equ RAM + $00
counter:		.equ RAM + $01
temp:			.equ RAM + $02
counter2:		.equ RAM + $03
lampColumn:		.equ RAM + $07
lampRow1:		.equ RAM + $08

displayBcd1:	.equ RAM + $10

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
	
	ldaA	#00
	staB	displayBcd1
	
	ldaA	#$FF	
	staA 	displayStrobe

	ldaA	#00
	staA	lampColumn
	
	ldaA	#$F0
	staA	lampRow1
	
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

	ldaA	#11110000b	
	oraA	strobe	
	ldaB 	#$FF
	staB	displayBcd
	staA	displayStrobe
	ldaB	displayBcd1
	staB	displayBcd
	inc 	strobe
	
	ldaA	#$FF
	staA	lampRow
	ldaA	lampColumn
	staA	lampStrobe
	ldaA	lampRow1
	staA	lampRow
	ldaA	#00
	asl		lampColumn
	cmpA	lampColumn
	bne		lsNotZero
	
	ldaA	#00000001b
	staA	lampColumn
lsNotZero:

	bra		loop
	
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