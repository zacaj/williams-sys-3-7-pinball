utils:	.org $7B00

; copy players' scores to display 
copyScores:
copyScores13:
	ldX		#displayBcd1
copy13Loop:
	ldaA	pA_1m - displayBcd1, X
	aslA
	aslA
	aslA
	aslA
	oraA	#00001111b
	andA	pC_1m - displayBcd1, X
	staA	0, X
	
	inX
	cpX		#displayBcd1 + 6
	ble copy13Loop
copyScores24:
	ldX		#displayBcd1 + 8
copy24Loop:
	ldaA	pB_1m - (displayBcd1 + 8), X
	aslA
	aslA
	aslA
	aslA
	oraA	#00001111b
	andA	pD_1m - (displayBcd1 + 8), X
	staA	0, X
	
	inX
	cpX		#displayBcd1 + 14
	ble copy24Loop	
	rts