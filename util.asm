utils:	.org $7B00

; copy players' scores to display 
copyScores13:
	ldX		#displayBcd1
	ldaB	#$FF	; blank(F) until a number >0 is found then 0
copy13Loop:
	ldaA	pA_1m - displayBcd1, X
	cmpA	#$F0 
	ifeq ; if pA score = 0?
		cpX		#displayBcd1 + 4
		ifeq
			andB	#00001111b 
			ldaA	#$0F
		else
			tBA	; replace 0 with blank/0
		endif
	else
		aslA
		aslA
		aslA
		aslA
		andB	#00001111b ; mark upper half of B as 0 since number found
		oraA	#00001111b
	endif
	andA	pC_1m - displayBcd1, X
	bitA	#00001111b
	ifeq ; pC is 0
		bitB	#1111b
		ifne
			cpX		#displayBcd1 + 4
			ifeq
				andB	#11110000b
			else
				oraA	#$F
			endif
		endif
	else
		andB	#11110000b
	endif
	staA	0, X
	
	inX
	cpX		#displayBcd1 + 6
	ble copy13Loop
	
	rts

copyScores24:
	ldX		#displayBcd1 + 8
	ldaB	#$FF	; blank(F) until a number >0 is found then 0
copy24Loop:
	ldaA	pB_1m - (displayBcd1 + 8), X
	cmpA	#$F0 ; is pA score 0?
	ifeq ; if pA score = 0?
		cpX		#displayBcd1 + 8 + 4
		ifeq
			andB	#00001111b 
			ldaA	#$0F
		else
			tBA	; replace 0 with blank/0
		endif
	else
		aslA
		aslA
		aslA
		aslA
		andB	#00001111b ; mark upper half of B as 0 since number found
		oraA	#00001111b
	endif
	andA	pD_1m - (displayBcd1 + 8), X
	bitA	#00001111b
	ifeq ; pC is 0
		bitB	#1111b
		ifne
			cpX		#displayBcd1 + 8 + 4
			ifeq
				andB	#11110000b
			else
				oraA	#$F
			endif
		endif
	else
		andB	#11110000b
	endif
	staA  0, X 
	
	inX
	cpX		#displayBcd1 + 14
	ble copy24Loop	
	
	rts