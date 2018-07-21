; solenoids
#DEFINE SOL(n,t)	(n<<8)|t
#DEFINE TROUGH_KICK		SOL(01, 40)
#DEFINE OUTHOLE 		SOL(02, 40)
#DEFINE BACK_GI 		SOL(03, 40)
#DEFINE UPPER_GI 		SOL(04, 40)
#DEFINE LOWER_GI 		SOL(05, 40)
#DEFINE SLAVE_KICKER	SOL(06, 40)
#DEFINE HIDDEN_KICKER	SOL(07, 40)
#DEFINE UL_DROP			SOL(09, 40)
#DEFINE UR_DROP			SOL(10, 40)
#DEFINE LL_DROP			SOL(11, 40)
#DEFINE LR_DROP			SOL(12, 40)
#DEFINE UPPER_LOCK		SOL(13, 40)
#DEFINE LOWER_LOCK		SOL(14, 40)
#DEFINE BELL			SOL(15, 40)

none:	.org $6000 + 192 ; size of callback table
	done(1)

; send command # (1-31) in A
doSound:
	andA	11111b
	oraA	>solenoidB
	staA	solenoidB
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	andA	11100000b
	staA	solenoidB
	rts
#DEFINE SOUND(n) ldaA n\ jsr doSound
	
_addScore10N:
	tst	>multiball
	ifne
		jsr setXToCurPlayer10
		pshA
		jsr	_addScoreI
		pulA
	endif
	jsr setXToCurPlayer10
	jmp _addScoreI
_addScore100N:
	tst	>multiball
	ifne
		jsr setXToCurPlayer10
		deX
		pshA
		jsr	_addScoreI
		pulA
	endif
	jsr setXToCurPlayer10
	deX
	jmp _addScoreI	
_addScore1000N:
	tst	>multiball
	ifne
		jsr setXToCurPlayer10
		deX
		deX
		pshA
		jsr	_addScoreI
		pulA
	endif
	jsr setXToCurPlayer10
	deX
	deX
	jmp _addScoreI	
_addScore10kN:
	tst	>multiball
	ifne
		jsr setXToCurPlayer10
		deX
		deX
		deX
		pshA
		jsr	_addScoreI
		pulA
	endif
	jsr setXToCurPlayer10
	deX
	deX
	deX
	jmp _addScoreI
_addScore100kN:
	tst	>multiball
	ifne
		jsr setXToCurPlayer10
		deX
		deX
		deX
		deX
		pshA
		jsr	_addScoreI
		pulA
	endif
	jsr setXToCurPlayer10
	deX
	deX
	deX
	deX
	jmp _addScoreI
; AX
#DEFINE score10x(x) ldaA x\ jsr _addScore10N
#DEFINE score100x(x) ldaA x\ jsr _addScore100N
#DEFINE score1000x(x) ldaA x\ jsr _addScore1000N
#DEFINE score10kx(x) ldaA x\ jsr _addScore10kN

#DEFINE advBonus()	jsr advanceBonus


p_Bonus:	.equ RAM + $D0

lowerDrops:	.equ RAM + $D3 ; XRRRXLLL 1 = ignore drop (because it's already down)
upperDrops:	.equ RAM + $D4 ; ^
multiball:	.equ RAM + $D5
bonusAnim:	.equ RAM + $DB ; stores data for bonus anim or 0 if no animation in action

p_Pharaoh:	.equ RAM + $E0 ; + 3  pharaoh letters
p_nextHurryUp:	.equ RAM + $E5 ; + 3  clockwise 0 = upper lock, tomb, lower lock, hidden, slaves
p_lc2:		.equ RAM + $E9 ; + 3 lamp column 2

advanceBonus:
	inc 	p_Bonus
	inc	bonusAnim
	fork(64)
	rts
	nop
	nop
	beginFork()
	ldaB	$FF
	cmpB	>lc(7)
	ifeq
		delay(64)
		lampOff(1,8) ; 9k
advanceBonus_downLoop:
		delay(64)
		lsrB
		staB	lc(7)
		bne	advanceBonus_downLoop

		delay(64)
	else
		ldaB	11111110b
		staB	bonusAnim
advanceBonus_loop:
		dec	p_Bonus
		jsr 	bonusLights
		inc	p_Bonus
		andB	>lc(7)
		cmpB	>lc(7)
		beq	advanceBonus_end
		staB	lc(7)
		seC
		rol	bonusAnim
		delay(64)
		ldaB	>bonusAnim
		bra	advanceBonus_loop
	endif
advanceBonus_end:
	jsr 	bonusLights
	dec	bonusAnim
	endFork()
	
; switch callbacks:
	
; note bonus displayed is double what is in memory
bonusLights:
	pshA
	pshB

	; clear lights
	clr	lc(7)
	ldaA	11100000b
	andA	>lc(8)
	staA	lc(8)

	ldaA	>p_Bonus
	ldaB	1b
	oraB	>lc(8)
	staB	lc(8)

lBonusLights_10:
	cmpA	10
	blt	lBonusLights_1
	; bonus >= 10
	seC
	rol	lc(8)
	ldaB	10
	sBA
	bra	lBonusLights_10

lBonusLights_1:
	tstA
	beq	bonusLights_done

	seC
	rol	lc(7)
	bcs	bonusLights_done
	bra	lBonusLights_1

bonusLights_done:
	tstA
	ifeq
		ldaA	~1b
		andA	>lc(8)
		staA	lc(8)
	endif
	pulB
	pulA
	rts


startBall:
	ldX	>curPlayer
	ldaA	1
	staA	p_Bonus
	enablePf

	;;delay(150)
	
	ldaA	$FF
	staA	lastSwitch
	
	; clear lights col 2-8
	ldX	lampCol1 + 1
lClearLights:
	clr	0, X
	clr	flashLampCol1 - lampCol1, X
	inX
	cpX	lc(8) + 1
	bne	lClearLights
	;
	
	ldaA	01110000b ; UL 3 bank lights
	staA	lc(4)
	ldaA	11111000b ; UR 3 bank lights, GI
	staA	lc(6)

	; init lights for player data
	ldX	>curPlayer
	;ldaA	p_Pharaoh, X
	;andA	11110000b ; PHAR
	;oraA	>lc(3)
	;staA	lc(3)
	;ldaA	p_Pharaoh, X
	;andA	111b ; AOH
	;oraA	>lc(4)
	;staA	lc(4)
	ldaA	p_lc2, X
	staA	lc(2)

	jsr	pharaohLights

	;
	ldaA	01110111b ; lower drops
	staA	lowerDrops
	staA	upperDrops

	fireSolenoid(UL_DROP)
	delay(150)
	fireSolenoid(UR_DROP)
	delay(150)
	fireSolenoid(LL_DROP)
	delay(150)
	fireSolenoid(LR_DROP)
		
	inc	pfInvalid
	clr 	multiball
	delay(350)

	clr	lowerDrops
	clr	upperDrops

	fireSolenoid(TROUGH_KICK)
	;SOUND($0B)
	;delay(700)
	;SOUND($11)
	rts
	
	
startGame:
	ldaA	1
	staA	playerCount
	;SOUND($13)
	
	; reset scores
	jsr 	resetScores

	;SOUND(S_ALIEN_POKER)

	;delay(1300)
	
	; reset ball count
	ldaA	$10 ; ball 1
	staA	ballCount	

	ldaB	0
	staB	curPlayer + 1
	
	; reset backglass lights
	clr	lc(1)
	clr	flc(1)

	ldX	0
lInitPlayers:
	; stuff
	ldaA	1
	staA	p_Pharaoh, X
	staA	p_nextHurryUp, X
	ldaA	00100b; 1 magna save
	staA	p_lc2, X
	inX
	cpX	4
	bne	lInitPlayers
	
	jsr	startBall
	
	rts
	

	
swTilt: 
	;SOUND($0B)
	;SOUND($01)
	lampOn(3,1) ; tilt
	disablePf
	done(0)
	
swStart: 
	ldaA >lc(1) ; game over
	bitA lr(4)
	ifne ; in game over
		ldaA	>sc(5)
		andA	1100000b ; trough switches
		cmpA	1100000b
		ifeq
			jsr startGame
		else
			; missing balls
		endif
	else 
		ldaA	>ballCount
		andA	$F0
		cmpA	$10
		ifeq ; add player if ball 1
			ldaA	4
			cmpA	>playerCount
			ifne	; if not on P4 already, add player
				inc	playerCount
			endif
		else ; restart game
			jsr startGame
		endif		
	endif
	
	jsr refreshPlayerScores
	
	done(0)

collectBonus:
	; start flashing highest x
	ldaA	lr(8) ; 5x
swOuthole_flashX_loop:
	bitA	>lc(8)
	ifne
		oraA	>flc(8)
		staA	flc(8)
	else
		asrA
		bne	swOuthole_flashX_loop
	endif


	ldaB	1111b
	staB	bonusAnim

	; start bonus countdown
	ldaB	>p_Bonus			
swOuthole_bonusLoop:
	score1000x(1)
	ldaA	>lc(8)
	bitA	lr(8)
	ifne
		score1000x(1)
	endif
	;SOUND($02)
	dec	p_Bonus
	jsr	bonusLights
	delay(30)
	ldaA	>bonusAnim
	bitA	1000b
	ifne
		delay(20)
	endif
	ldaA	>bonusAnim
	bitA	100b
	ifne
		delay(20)
	endif
	ldaA	>bonusAnim
	bitA	10b
	ifne
		delay(20)
	endif
	ldaA	>bonusAnim
	bitA	1b
	ifne
		delay(20)
	endif

	tst	>p_Bonus
	bne	swOuthole_bonusLoop

	ldaA	>lc(8) 
	andA	11100000b ; multipliers
	ifne ; still X left to count down
		asr	bonusAnim
		asrA ; lower mult
		asr	flc(2)
		oraA	11111b ; kings
		andA	>lc(8)
		staA	lc(8)
		staB	p_Bonus
		bra	swOuthole_bonusLoop
	endif
	; end loop
	rts

swShooter:
	done(0)
swOuthole:
	fireSolenoid(OUTHOLE)
	clr	multiball
	lampOff(1,3) ; 2x
	done(0)
swTrough1:
	ldaA	>lc(1) ; !game over
	bitA	lr(4)
	ifne ; game over
		done(0)
	endif

	ldaA	sr(6)
	bitA	>sc(5)
	ifne	; trough 2 closed as well
		jsr	endBall
	endif
	done(0)
swTrough2:
	ldaA	>lc(1) ; !game over
	bitA	lr(4)
	ifne ; game over
		done(0)
	endif

	ldaA	sr(7)
	bitA	>sc(5)
	ifne	; trough 1 closed as well
		jsr	endBall
	endif
	done(0)

endBall: 	
	tst	>pfInvalid
	ifne
		lampOff(3,1) ; tilt
		
		enablePf
		fireSolenoid(TROUGH_KICK)
	
		done(0)
	endif

	ldaA	>lc(1) ; shoot again
	bitA	lr(8)
	ifne	; shoot again
		inc	pfInvalid
		fireSolenoid(TROUGH_KICK)
	
		done(0)
	endif

	; wait for any threads to end
	ldX	waitLeft - 1
	ldaB	10000000b; ball end flag
l_endBall_wait:
	inX
	tst	0, X
	ifne ; timer running
		bitB	waitC - waitLeft, X
		ifeq ; kill on ball end
			clr	0, X
		else
			delay(8)
		endif
	endif

	cpX	waitLeftEnd
	bne	l_endBall_wait


	; playfield valid -> end ball

	jsr	collectBonus

	; store player's data
	ldX	>curPlayer
	;ldaA	>lc(3)
	;andA	11110000b ; PHAR
	;staA	p_Pharaoh, X
	;ldaA	>lc(4)
	;andA	111b ; AOH
	;oraA	>p_Pharaoh, X
	;staA	p_Pharaoh, X
	ldaA	>lc(2)
	staA	p_lc2

	ldaB	>lc(1) ; check shoot again light
	bitB	lr(8)
	ifeq ; shoot again not lit
		; go to next player
		inc	curPlayer + 1
		ldaA	playerCount
		cmpA 	>curPlayer + 1
		ifeq ; last player
			clr	curPlayer + 1
			
			; increase ball count
			ldaB	>ballCount
			andB	$F0
			addB	$10
			andB	$F0
			cmpB	$40
			ifeq ; game over
				; wait for any threads to end
				ldX	waitLeft - 1
				ldaB	01000000b; ball end flag
l_endGame_wait:
				inX
				tst	0, X
				ifne ; timer running
					bitB	waitC - waitLeft, X
					ifeq ; kill on game  end
						clr	0, X
					else
						delay(8)
					endif
				endif

				cpX	waitLeftEnd
				bne	l_endGame_wait

				lampOn(4,1) ; game over
				disablePf
				done(0)
			else
				staB	ballCount
			endif		
		endif
	endif
	
	jsr	startBall
	
	done(1)
	
sw10pt:
	score10x(1)
	SOUND($13)

	tst	>multiball
	ifne
		; eject ball
		ldaA	>sc(5)
		bitA	sr(3)
		ifne
			fireSolenoid(LOWER_LOCK)
		else
			fireSolenoid(UPPER_LOCK)
		endif
	endif

	ldaA	>lc(2)
	bitA	lr(7)
	ifne ; left ? lit
		bitA	lr(8)
		ifeq ; right ? not lit
			lampOff(7,2)
			lampOn(8,2)
		endif
	else
		bitA	lr(8)
		ifne
			lampOff(8,2)
			lampOn(7,2)
		endif
	endif
	done(1)
swLeftMagnet:
	ldaA	>sc(2)
	bitA	sr(1)
	ifeq ; released
		jsr	specialOff5
		;ldaA	~111b ; left magnet lights
		;andA	>flc(2)
		;staA	flc(2)

		ldaA	>lc(2)
		andA	~111b ; left magnet lights
		staA	lc(2)
		ldaA	>lc(2)
		andA	111b ; left magnet lights
		decA
		oraA	>lc(2)
		staA	lc(2)

		ldaA	011b ; left magnet ID
		jsr	cancelThreads

		done(0)
	endif

	ldaA	>lc(2)
	bitA	111b ; left magnet lights
	ifeq ; magnet not lit
		done(0)
	endif

	jsr	specialOn5

swLeftMagnet_delay:
	delayC(250, 11000011b) ; left magnet ID
	
	; dec magnet lights
	ldaA	>lc(2)
	andA	~111b ; left magnet lights
	staA	lc(2)
	ldaA	>lc(2)
	andA	111b ; left magnet lights
	decA
	ifne	 ; still magnet left
		oraA	>lc(2)
		staA	lc(2)
	else
		jsr	specialOff5
		bra	swLeftMagnet_delay
	endif

	done(0)
swRightMagnet:
	ldaA	>sc(2)
	bitA	sr(2)
	ifeq ; released
		jsr	specialOff6
		;ldaA	~111b ; left magnet lights
		;andA	>flc(2)
		;staA	flc(2)

		ldaA	>lc(2)
		andA	~111000b ; right magnet lights
		staA	lc(2)
		ldaA	>lc(2)
		andA	111000b ; right magnet lights
		asrA
		asrA
		asrA
		decA
		aslA
		aslA
		aslA
		oraA	>lc(2)
		staA	lc(2)

		ldaA	100b ; right magnet ID
		jsr	cancelThreads

		done(0)
	endif

	ldaA	>lc(2)
	bitA	111000b ; left magnet lights
	ifeq ; magnet not lit
		done(0)
	endif

	jsr	specialOn6

swRightMagnet_delay:
	delayC(250, 11000100b) ; right magnet ID
	
	; dec magnet lights
	ldaA	>lc(2)
	andA	~111000b ; right magnet lights
	staA	lc(2)
	ldaA	>lc(2)
	andA	111000b ; right magnet lights
	asrA
	asrA
	asrA
	decA
	ifne	 ; still magnet left
		aslA
		aslA
		aslA
		oraA	>lc(2)
		staA	lc(2)
	else
		jsr	specialOff6
		bra	swRightMagnet_delay
	endif
	done(0)
swLeftInlane:
	done(1)
swRightInlane:
	done(1)
swLeftOutlane:
	ldaA	>lc(2) ; left ?
	bitA	lr(7)
	ifne ; left outlane lit
		lampOn(8,1) ; shoot again
		flashLamp(8,1)
		flashLamp(7,2)
	else
		ldaA	9 ; left magnet button?
		cmpA	>lastSwitch
		ifeq 
			; laugh
		endif
	endif
	done(1)
swRightOutlane:
	ldaA	>lc(2) ; right ?
	bitA	lr(8)
	ifne ; right outlane lit
		lampOn(8,1) ; shoot again
		flashLamp(8,1)
		flashLamp(8,2)
	else
		ldaA	10 ; right magnet button?
		cmpA	>lastSwitch
		ifeq 
			; laugh
		endif
	endif
	done(1)
swULDropBlue:
	ldaA	1b
	jmp	swUpperDrop
swULDropRed:
	ldaA	100b
	jmp	swUpperDrop
swULDropYellow:
	ldaA	10b
	jmp	swUpperDrop
swURDropBlue:
	ldaA	10000b
	jmp	swUpperDrop
swURDropYellow:
	ldaA	100000b
	jmp	swUpperDrop
swURDropRed:
	ldaA	1000000b
	jmp	swUpperDrop
	; XRRRXLLL
swUpperDrop:
	bitA	>upperDrops
	ifne
		done(0)
	endif

	tAB
	oraB	>upperDrops
	staB	upperDrops

	; turn off any lamps on right bank whose drops are down
	tAB
	aslB
	comB
	andB	>lc(6)
	staB	lc(6)

	; turn off any lamps on left bank whose drops are down
	tAB
	aslB
	aslB
	aslB
	aslB
	comB
	andB	>lc(4)
	staB	lc(4)

	; flash any lamps on left bank that are down on right
	ldaB	>lc(6)
	comB
	andB	11100000b
	lsrB
	andB	>lc(4)
	oraB	>flc(4)
	staB 	flc(4)

	; flash any lamps on right bank that are down on left
	ldaB	>lc(4)
	comB
	andB	01110000b
	aslB
	andB	>lc(6)
	oraB	>flc(6)
	staB	flc(6)

	; check if they match
	andB	11100000b
	ifeq
		ldaB	>flc(4)
		andB	01110000b
		ifeq ; none flashing
			;SOUND
			jsr	incPharoah

			; add second letter if only one drop down
			ldaB	>flc(4)
			andB	01110000b
			cmpB	01000000b
			ifeq
				clrB
			else
				cmpB	00100000b
				ifeq
					clrB
				else
					cmpB	00010000b
					ifeq
						clrB
					endif
				endif
			endif
			tstB
			ifeq
				jsr	incPharoah
				fireSolenoid(BELL)
			endif

			; reset drops
			delay(100)
			fireSolenoid(UL_DROP)
			delay(150)
			fireSolenoid(UR_DROP)
			delay(150)
			clr	upperDrops
		endif
	endif

	done(1)
incPharoah:
	tst	>multiball
	ifne
		rts
	endif

	ldX	>curPlayer
	inc	p_Pharaoh, X
	ldaA	7
	cmpA	p_Pharaoh, X
	ifgt	
		staA	p_Pharaoh, X
	endif

	jsr	pharaohLights

	; inc PHAR
	;ldaA	>lc(3)
	;aslA
	;ifcs ; need to inc OAH as well
	;	ldaB	>lc(4)
	;	andB	11b
	;	seC
	;	rolB
	;	oraB	>lc(4)
	;	staB	lc(4)
	;endif
	;oraA	lr(5)
	;andA	11110000b
	;oraA	>lc(3)
	;staA	lc(3)
	rts
pharaohLights:
	ldaA	11111000b ; ~AOH
	andA	>lc(4)
	staA	lc(4)

	ldX	>curPlayer
	ldaA	p_Pharaoh, X
	cmpA	4
	ifgt
		ldaB	11110000b ; PHAR
		oraB	>lc(3)
		staB	lc(3)

		ldaB	4
		sBA
		clrB
l_pharaohLights_AOH:
		seC
		rolB
		decA
		bne	l_pharaohLights_AOH

		oraB	>lc(4)
		staB	lc(4)
	else
		ldaB	00001111b ; ~PHAR
		andB	>lc(3)
		staB	lc(3)

		ldaB	1111b ; ~PHAR
l_pharaohLights_PHAR:
		seC
		rolB
		decA
		bne	l_pharaohLights_PHAR

		oraB	>lc(3)
		staB	lc(3)
	endif
	rts

swLLDrop1:
	ldaA	1b
	jmp	swLowerDrop
swLLDrop2:
	ldaA	10b
	jmp	swLowerDrop
swLLDrop3:
	ldaA	100b
	jmp	swLowerDrop
swLRDrop1:
	ldaA	10000b
	jmp	swLowerDrop
swLRDrop2:
	ldaA	100000b
	jmp	swLowerDrop
swLRDrop3:
	ldaA	1000000b
	jmp	swLowerDrop
swLowerDrop:
	bitA	>lowerDrops
	ifne
		done(0)
	endif

	tAB
	oraB	>lowerDrops
	staB	lowerDrops

	ldaB	>flc(3)
	bitA	11100000b ; right drops
	ifne ; right drops
		bitB	lr(4) ; right drop
		ifne ; bank already flashing
		else ; bank not flashing
			ldaB	>lc(3)
			bitB	lr(4) ; right drop
			ifeq ; lamp not on
				flashLamp(4,3)
				lampOn(4,3)
				delay(2000)
				flashLampFast(4,3)
				delay(1000)

				ldaB	>flc(3)
				bitB	lr(4)
				ifne ; still flashing, out of time
					flashOff(4,3)
					flashFastOff(4,3)
					lampOff(4,3)

					fireSolenoid(LR_DROP)
					delay(150)
					ldaB	~1110000b
					andB	>lowerDrops
					staB	lowerDrops
				endif
			endif
		endif
		
		; check if all of bank is down
		ldaB	>lowerDrops
		andB	1110000b ; right drops
		cmpB	1110000b
		ifeq ; all of bank is down in time
			flashOff(4,3)
			flashFastOff(4,3)
			fireSolenoid(BELL)
			delay(100)
			fireSolenoid(LR_DROP)
			delay(150)
			ldaB	~11100000b
			andB	>lowerDrops
			staB	lowerDrops
		endif
	else
		bitB	lr(3) ; left drop
		ifne ; bank already flashing
		else ; bank not flashing
			ldaB	>lc(3)
			bitB	lr(3) ; left drop
			ifeq ; lamp not on
				flashLamp(3,3)
				lampOn(3,3)
				delay(2000)
				flashLampFast(3,3)
				delay(1000)

				ldaB	>flc(3)
				bitB	lr(3)
				ifne ; still flashing
					flashOff(3,3)
					flashFastOff(3,3)
					lampOff(3,3)
					
					fireSolenoid(LL_DROP)
					delay(150)
					ldaB	~111b
					andB	>lowerDrops
					staB	lowerDrops
				endif
			endif
		endif
		
		; check if all of bank is down
		ldaB	>lowerDrops
		andB	111b ; left drops
		cmpB	111b
		ifeq ; all of bank is down
			flashOff(3,3)
			flashFastOff(3,3)
			fireSolenoid(BELL)
			delay(100)
			fireSolenoid(LL_DROP)
			delay(150)
			ldaB	~111b
			andB	>lowerDrops
			staB	lowerDrops
		endif
	endif

	tst	>multiball
	ifeq
		; check if both banks are complete
		ldaB	>lc(3)
		andB	1100b ; bank lights
		cmpB	1100b
		ifeq ; both complete
			; light locks
			ldaB	110b ; lock lights
			oraB 	>lc(5)
			staB	lc(5)
		endif
	else
		; todo
	endif

	done(1)
swUpperLock:
	ldaA	>flc(5)
	bitA	lr(2)
	ifne	; flashing -> hurry up
		jsr	awardHurryUp
		flashOff(2,5)

		ldaB	>lc(3)
		andB	1100b ; bank lights
		cmpB	1100b
		ifne ; locks not lit
			lampOff(2,5)
		endif
	endif
	jsr	swLock
	done(1)
swLowerLock:
	ldaA	>flc(5)
	bitA	lr(3)
	ifne	; flashing -> hurry up
		jsr	awardHurryUp
		flashOff(3,5)

		ldaB	>lc(3)
		andB	1100b ; bank lights
		cmpB	1100b
		ifne ; locks not lit
			lampOff(3,5)
		endif
	endif
	jsr	swLock
	done(1)
swLock:
	ldaB	>lc(3)
	andB	1100b ; bank lights
	cmpB	1100b
	ifeq ; locks lit
		;SOUND
		fireSolenoid(TROUGH_KICK)
		inc	multiball
		lampOn(1,3) ; 2x

		; turn off locks
		ldaB	~110b
		andB	>lc(5)
		staB	lc(5)
		ldaB	~1100b
		andB	>lc(3)
		staB	>lc(3)
	else ; lock not lit
		ldaA	>sc(5)
		bitA	sr(2)
		ifne	
			ldaA	0
		else
			ldaA	2
		endif
		jsr	startHurryUp
		
		; eject ball
		ldaA	>sc(5)
		bitA	sr(3)
		ifne
			fireSolenoid(LOWER_LOCK)
		else
			fireSolenoid(UPPER_LOCK)
		endif
	endif
	rts

startHurryUp:
	ldaA	010b ; hurry up
	jsr	cancelThreads

	; 0 temp player if no hurry up in progress
	ldaB	$F0
	cmpB	>pT_10
	ifne
		staB	pT_1m + 0
		staB	pT_1m + 1
		staB	pT_1m + 2
		staB	pT_1m + 3
		staB	pT_1m + 4
		staB	pT_1m + 5

		; flash proper hurry up goal
		ldX	>curPlayer
		ldaB	p_nextHurryUp, X
		ifeq ; 0 = top lock
			cBA
			ifeq	
				incB ; next hole
			else
				lampOn(2,5) ; upper lock
				flashLamp(2,5)
			endif
		endif
		decB
		ifeq ; 1 = tomb
			flashLamp(5,6) ; tomb gi
		endif
		decB
		ifeq ; 2 = lower lock
			cBA
			ifeq	
				incB ; next hole
			else
				lampOn(3,5) ; upper lock
				flashLamp(3,5)
			endif
		endif
		decB
		ifeq ; 3 = hidden
			lampOn(2,3) ; collect bonus
			flashLamp(2,3)
		endif
		decB
		ifeq ; 4 = slaves
			flashLamp(4,6) ; slave gi
		endif

		ldaA	5
		aBA
		cmpA	5
		ifge
			ldaA	0
		endif
		staA	p_nextHurryUp, X
	else ; hurry up in progress

	endif

	ldX	>curPlayer
	ldaB	p_Pharaoh, X

	; add initial score
l_swLock_calcValue:
	ldX	pT_10 - 2 ; thousands
	ldaA	5
	jsr	_addScoreI
	decB
	bne	l_swLock_calcValue

	jsr 	blankTempScoreZeroes

	jsr	syncHurryUpValue

	forkSrC(hurryUp, 2000, 11000010b)
	rts

syncHurryUpValue:
	ldaA	001b ; flash scores id
	jsr	cancelThreads

	; display value
	ldaA	3
	cmpA	>curPlayer + 1
	ifeq ; p4
		ldaA	2
	endif
	jsr 	copyTempScoreToPlayer
	rts
hurryUp:
	; check if value has reached 0
	ldX	pT_1m - 1
l_hurryUp_done:
	inX
	cpX	pT_10 + 1
	ifeq
		jsr	blankTempPlayer
		endFork()
	endif

	; check if number is 0 or blank
	ldaA	0, X
	cmpA	$F0
	beq	l_hurryUp_done
	cmpA	$FF
	beq	l_hurryUp_done

	; if not, subtract 5
	ldaB	5
	ldX	pT_10 - 2
	jsr	_decScoreI

	jsr	syncHurryUpValue

	; start hurry up again
	forkSrC(hurryUp, 200, 11000010b)

	endFork()
awardHurryUp:
	ldaA	>pT_10
	andA	$0F
	jsr	_addScore10N
	delay(150)
	ldaA	>pT_10 - 1
	andA	$0F
	jsr	_addScore100N
	delay(150)
	ldaA	>pT_10 - 2
	andA	$0F
	jsr	_addScore1000N
	delay(150)
	ldaA	>pT_10 - 3
	andA	$0F
	jsr	_addScore10kN
	delay(150)
	ldaA	>pT_10 - 4
	andA	$0F
	jsr	_addScore100kN

	ldaA	010b ; hurry up id
	jsr	cancelThreads

	jsr	blankTempPlayer

	rts

swUpperX:
	lampOn(4,4) ; upper x
	ldaA	>lc(4)
	bitA	lr(8)
	ifne
		lampOff(4,4)
		lampOff(8,4)
		jsr	incBonusX
	endif
	done(1)
swLowerX:
	lampOn(8,4) ; lower x
	ldaA	>lc(8)
	bitA	lr(8)
	ifne
		lampOff(4,4)
		lampOff(8,4)
		jsr	incBonusX
	endif
	done(1)
incBonusX:
	ldaA	>lc(8)
	oraA	11111b
	seC
	rolA
	ifcs ; already maxed
		score10kx(4)
	else
		andA	11100000b ; bonus X
		oraA	>lc(8)
		staA	lc(8)
	endif
	rts
	
swSlaveEject:
	ldaA	>flc(6) ; slave GI
	bitA	lr(4)
	ifne	; hurry up
		jsr	awardHurryUp
		flashOff(4,6)
	else
		jsr 	startHurryUp
	endif
	delay(200)
	fireSolenoid(SLAVE_KICKER)
	done(1)
swHiddenEject:
	ldaA	>flc(3) ; collect bonus
	bitA	lr(2)
	ifne	; hurry up
		jsr	awardHurryUp
		flashOff(2,3)
		lampOff(2,3)
	endif

	ldaA	>lc(6) ; eb
	bitA	lr(3)
	ifne ; eb lit
		ldaA	>lc(2)
		bitA	lr(7)
		ifne ; left ? lit
			bitA	lr(8)
			ifne ; right ? lit
				score10kx(5)
			else
				lampOn(8,2)
			endif
		else
			lampOn(7,2)
		endif
		lampOff(3,6)
	endif

	delay(200)
	fireSolenoid(HIDDEN_KICKER)
	done(1)
swTomb:

	ldaA	>flc(6) ; captive ball gi
	bitA	lr(5)
	ifne	; hurry up
		jsr	awardHurryUp
		flashOff(5,6)
	else
		jsr	incPharoah
		ldX	>curPlayer

		ldaA	8
		cmpA	p_Pharaoh, X
		ifeq ; pharaoh maxed	
			lampOn(3,6) ; eb
		endif

		ldX	>curPlayer
		ldaA	p_Pharaoh, X
l_swTomb:
		score1000x(5)
		decA
		bne	l_swTomb
	endif
;	ldaA	10000b ; P
;l_swTomb_phar:
;	bitA	>lc(3)
;	ifne
;		score1000x(5)
;		clc
;		rolA
;		bcc	l_swTomb_phar
;	endif
;	ldaA	1b ; A
;l_swTomb_aoh:
;	bitA	>lc(4)
;	ifne
;		score1000x(5)
;		clc
;		rolA
;		bitA	1000b ; after H
;		beq	l_swTomb_aoh
;	endif
	
	done(1)

; end callbacks
	.msfirst
; needs to be on $**00 address
callbackTable: 	.org $6000 ; note: TRANSPOSED
	.dw swTilt	\.dw swTilt\.dw swStart	\.dw none\.dw none\.dw none\.dw swTilt\.dw none
	.dw swLeftMagnet\.dw swRightMagnet\.dw none\.dw none\.dw swLeftInlane\.dw swRightInlane\.dw swLeftOutlane\.dw swRightOutlane
	.dw swULDropBlue\.dw swULDropYellow\.dw swULDropRed\.dw sw10pt\.dw swURDropBlue\.dw swURDropYellow\.dw swURDropRed\.dw sw10pt
	.dw swLLDrop1	\.dw swLLDrop2\.dw swLLDrop3\.dw swUpperX\.dw swLRDrop1\.dw swLRDrop2\.dw swLRDrop3\.dw swLowerX
	.dw swSlaveEject\.dw swUpperLock\.dw swLowerLock\.dw swOuthole\.dw none\.dw swTrough2\.dw swTrough1\.dw swShooter
	.dw swTomb	\.dw swTilt\.dw swHiddenEject\.dw sw10pt\.dw none\.dw none\.dw none\.dw none
	.dw none	\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none	\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
; on = how many cycles it must be on for before registering (1 cycle = 64ms (?)) (max 7)
; off = how many cycles it must be off for
; onOnly = if true, don't notify of an off event (also set off = 0 for efficiency)
; gameover = whether the switch is active in gameover + tilt mode (these callbacks must check whether in game over when triggered if they want to act different)
; TRANSPOSED 
#define SW(on,off,onOnly,gameover) .db (onOnly<<7)|(gameover<<6)|(on<<3)|(off) 
#define LANE 	SW(0,3,1,0)
#define HOLE 	SW(5,7,1,1)
#define TEN  	SW(0,3,1,0)
#define TARGET	SW(0,5,1,0)
#define DROP	SW(0,3,1,0)
#DEFINE POP	SW(0,1,1,0)
settleTable: ; must be right after callbackTable
	SW(0,7,1,0)\SW(0,7,1,0)\SW(0,2,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,1,0)\SW(0,7,0,1)
	SW(0,0,0,0)\SW(0,0,0,0)\LANE\LANE\LANE\LANE\LANE\LANE
	DROP\DROP\DROP\TEN\DROP\DROP\DROP\TEN
	DROP\DROP\DROP\TARGET\DROP\DROP\DROP\TARGET
	HOLE\HOLE\HOLE\SW(5,5,1,1)\POP\SW(5,5,1,0)\HOLE\SW(2,2,0,0)
	TEN\SW(0,7,1,0)\HOLE\TEN\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)