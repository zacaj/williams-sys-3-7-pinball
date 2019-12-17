; solenoids
#DEFINE SOL(n,t)	(n<<8)|t
#DEFINE OUTHOLE 	SOL(01, 40)
; #DEFINE LEFT_EJECT	SOL(02, 16)
; #DEFINE RIGHT_EJECT	SOL(03, 24)
#DEFINE RED_RESET		SOL(04, 40)
#DEFINE YELLOW_RESET		SOL(05, 40)
#DEFINE EJECT		SOL(06, 40)
; #DEFINE DROP_4		SOL(07, 32)
; #DEFINE DROP_5		SOL(08, 32)
#DEFINE SOUND_1		SOL(09, 08)
#DEFINE SOUND_2		SOL(10, 08)
#DEFINE SOUND_3		SOL(11, 08)
#DEFINE SOUND_4		SOL(12, 08)
#DEFINE SOUND_5		SOL(13, 08)
#DEFINE	KNOCKER		SOL(14, 50)
#DEFINE BLACKOUT	SOL(15, 255) 

; lamps
#define LAMP(n,r,c) n: .equ (((r)<<8)|c)
LAMP(BONUS_1,2,1)
LAMP(BONUS_7,8,1)
LAMP(SHOOT_AGAIN_PF,1,1)
LAMP(BONUS_8,1,2)
LAMP(BONUS_9,2,2)
LAMP(BONUS_10,4,2)
LAMP(BONUS_20,1,7)
LAMP(BONUS_2X,5,2)
LAMP(BONUS_3X,6,2)
LAMP(BONUS_4X,7,2)
LAMP(BONUS_5X,8,2)
LAMP(GREEN_1,1,3)
LAMP(GREEN_2,2,3)
LAMP(GREEN_3,3,3)
LAMP(GREEN_4,4,3)
LAMP(GREEN_5,5,3)
LAMP(RED_1,6,1)
LAMP(RED_2,7,1)
LAMP(RED_3,8,1)
LAMP(POP_RIGHT,1,4)
LAMP(POP_LEFT,2,4)
LAMP(POP_BOTTOM,3,4)
LAMP(LANE_1,4,4)
LAMP(LANE_2,5,4)
LAMP(LANE_3,6,4)
LAMP(LEFT_INLANE,7,4)
LAMP(RIGHT_INLANE,8,4)
LAMP(YELLOW_1,6,5)
LAMP(YELLOW_2,7,5)
LAMP(YELLOW_3,8,5)
LAMP(P1_UP,1,8)
LAMP(P2_UP,2,8)
LAMP(P3_UP,3,8)
LAMP(P4_UP,4,8)
LAMP(ONE_PLAYER,2,7)
LAMP(TWO_PLAYERS,3,7)
LAMP(THREE_PLAYERS,4,7)
LAMP(FOUR_PLAYERS,5,7)
LAMP(TILT,5,8)
LAMP(CENTER_SPINNER,1,6)
LAMP(RIGHT_SPINNER,2,6)
LAMP(GAME_OVER,6,8)
LAMP(LEFT_OUTLANE,7,6)
LAMP(RIGHT_OUTLANE,8,6)
LAMP(EJECT_GREEN,3,6)
LAMP(EJECT_YELLOW,4,6)
LAMP(EJECT_RED,5,6)
LAMP(EJECT_BLACK,6,6)
LAMP(LOOP_5K,1,5)
LAMP(LOOP_10K,2,5)
LAMP(LOOP_15K,3,5)
LAMP(LOOP_20K,4,5)


; sounds:
; 1: bwaaaaaa...
; 2: BWEEAaaaa...
; 3: Chuchuchaa....
; 4: weeoooweeeooh!
; 5: beah! (startup x5?)
; 6: CHew....
; 7: chun
; 8: you fold.  I deal. 
; 9: (quiet) BUH BH buh bh 
; A: Chew chew buhnuhu!
; B: stop all sounds
; C: beyoop
; D: yayayayayayayah...
; E: Dnnnnnnnewwwwwwww...
; F: rocket increasing
; 10: chic
; 11: background sound
; 12: ?
; 13: ?
; 14: shoot decaying rocket
; 15: jungle lord background sound
; 16: you raise.
; 17: I deal joker
; 18: alien poker.  you deal.
; 19: you win jackpot
; 1A: million jackpot.  I raise a million
; 1B: you fold. I win.
; 1C: raise jack pot
; 1D: royal flush
; 1E: I fold. you win.  
; 1F: big jackpot. big winner. big deal.
#DEFINE S_ALIEN_POKER 	$18
#DEFINE S_KILL 		$0B
#DEFINE S_ROYAL_FLUSH	$1D
#DEFINE S_JACKPOT	$19
#DEFINE S_BG		$11

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
	jsr setXToCurPlayer10
	jmp _addScoreI
_addScore100N:
	jsr setXToCurPlayer10
	deX
	jmp _addScoreI	
_addScore1000N:
	jsr setXToCurPlayer10
	deX
	deX
	jmp _addScoreI	
_addScore10kN:
	jsr setXToCurPlayer10
	deX
	deX
	deX
	jmp _addScoreI
_addScore100kN:
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
#DEFINE score1kx(x) ldaA x\ jsr _addScore1000N
#DEFINE score10kx(x) ldaA x\ jsr _addScore10kN

#DEFINE advBonus()	jsr advanceBonus

p_Col3_6: 	.equ GRAM + $00 ; thru $0F 
p_Bonus:	.equ GRAM + $10
drops:		.equ GRAM + $11 ; XRRRXLLL 1 = ignore drop (because it's already down)
bonusAnim:	.equ GRAM + $12 ; stores temp data for bonus animations
bonusTimer:	.equ GRAM + $13 ; extended settle timer for outhole 

p_Targets:	.equ GRAM + $20 ; thru $23 XXXGGGGG (targets collected, matches lamp matrix)

; max GRAM + $27
advanceBonus:
	inc 	p_Bonus
	inc 	bonusAnim
	;jsr 	bonusLights
	fork(64)
	rts
	nop
	nop
	beginFork()
	ldaB	>lc(BONUS_10)
	bitB	lr(BONUS_9)
	
	ifne ; 9 is on, count off 1->9 and turn on ten
		ldaB	~lr(BONUS_1)
advanceBonus_downLoop:
		andB	~lr(BONUS_1)
		tBA
		andA	>lc(BONUS_1)
		staA	lc(BONUS_1)
		delay(64)
		seC
		rolB
		bcs	advanceBonus_downLoop

		lampOff(BONUS_8) ; 8k
		delay(64)
		lampOff(BONUS_9) ; 9k
		delay(64)
	else ; not at 9 yet
		ldaB 	lr(BONUS_1)
advanceBonus_loop:
		bitB	>lc(BONUS_7)
		beq	advanceBonus_end
		tBA
		eorB	>lc(BONUS_1)
		staB	lc(BONUS_1)
		delay(64)
		tAB
		oraB	>lc(BONUS_1)
		staB	lc(BONUS_1)
		tAB
		aslB
		bcc advanceBonus_loop

		lampOff(BONUS_8) ; 8k
		delay(64)
advanceBonus_end:
	endif
	clr		bonusAnim
	jsr 	bonusLights
	endFork()
	
; switch callbacks:

none:	.org $6000 + 192 ; size of callback table
	done(1)

bonusLights:
	pshA
	pshB

	; clear lights
	lampOff(BONUS_20)
	ldaB	~(lr(BONUS_8)|lr(BONUS_9)|lr(BONUS_10))
	andB	>lc(BONUS_10)
	staB	lc(BONUS_10)

	ldaB	>p_Bonus

lBonusLights_10:
	cmpB	30
	ifge	
		lampOn(BONUS_10)
		lampOn(BONUS_20)
		cmpB	39
		ifge
			ldaB	39
		endif
		subB	30
	else
		cmpB	10
		ifge	
			cmpB 	20
			ifge
				lampOn(BONUS_20)
				subB	20
			else
				lampOn(BONUS_10)
				subB	10
			endif
		endif
	endif
	; A now <10
	cmpB	9	
	ifeq	
		; bonus = 9
		lampOn(BONUS_9)
		decB
	endif
	tBA
	ldaB	lr(SHOOT_AGAIN_PF)
	andB	>lc(BONUS_1)
	clr 	lc(BONUS_1)
	incA ; add 1 since there's a shoot again in front to fill
lBonusLights_1:
	tstA
	beq	bonusLights_done
	decA
	seC
	rol		lc(BONUS_1)
	bcc		lBonusLights_1
	lampOn(BONUS_8)
bonusLights_done:
	ldaA	~lr(SHOOT_AGAIN_PF)
	andA	>lc(BONUS_1)
	staA	lc(BONUS_1)
	oraB 	>lc(BONUS_1) ; restore shoot again
	staB 	lc(BONUS_1)
	pulB
	pulA
	rts


startBall:
	ldX	>curPlayer
	ldaA	7
	staA	p_Bonus
	enablePf

	;;delay(150)
	
	ldaA	$FF
	staA	lastSwitch
	
	; clear lights thru col 6
	ldX	lampCol1
lClearLights:
	clr	0, X
	clr	flashLampCol1 - lampCol1, X
	inX
	cpX	lc(6) + 1
	bne	lClearLights

	lampOff(BONUS_20) ; in col 7
	;

	

	; init lights for player data
	ldX	>curPlayer
	ldaA	1
	staA	p_Bonus
	jsr	bonusLights
	ldaA	p_Col3_6 + 0, X
	staA	lc(3)
	ldaA	p_Col3_6 + 4, X
	staA	lc(4)
	ldaA	p_Col3_6 + 8, X
	staA	lc(5)
	ldaA	p_Col3_6 + 12, X
	staA	lc(6)

	;
	ldaA	01110111b ; ignore drops while resetting
	staA	drops

	fireSolenoid(RED_RESET)
	delay(150)
	fireSolenoid(YELLOW_RESET)
		
	;inc	pfInvalid
	; flash player light
	ldaA	00001111b ; player up lights
	oraA	>flc(8)
	staA	flc(8)
	clr		drops

	fireSolenoid(OUTHOLE)
	;SOUND($0B)
	;delay(700)
	;SOUND($11)
	rts
	
	
startGame:
	lampOn(2,7) ; one player
	SOUND($13)
	
	; reset scores
	jsr 	resetScores

	;SOUND(S_ALIEN_POKER)

	;delay(1300)
	
	; reset ball count
	ldaA	$10 ; ball 1
	staA	ballCount	

	ldaB	0
	staB	curPlayer + 1

	ldaA	pA_1m - dispData + 1
	staA	dispOffsets + 0

	clr	dispOffsets + 1
	clr	dispOffsets + 2
	clr	dispOffsets + 3
	
	; reset backglass lights
	clr	lc(7)
	clr	lc(8)
	clr	flc(7)
	clr	flc(8)
	
	ldX	0
lInitPlayers:
	; stuff
	ldaA	lr(GREEN_1)|lr(RED_1)
	staA	p_Col3_6 + 0, X
	ldaA	0
	staA	p_Col3_6 + 4, X
	ldaA	lr(YELLOW_1)
	staA	p_Col3_6 + 8, X
	ldaA	0
	staA	p_Col3_6 + 12, X
	clr		p_Targets, X
	inX
	cpX	4
	bne	lInitPlayers
	
	jsr	startBall
	
	; invalidate playfield
	lampOn(P1_UP)
	
	lampOn(ONE_PLAYER) ; one player
	
	lampOff(GAME_OVER) ; game over

	ldaA	1
	staA	playerCount
	
	rts
	
swPlayfieldValidated:
	lampOff(SHOOT_AGAIN_PF) ; shoot again
	;lampOff(8,1)

	; turn off flashing outlane
	ldaA	>flc(LEFT_OUTLANE) 
	andA	lr(LEFT_OUTLANE)|lr(RIGHT_OUTLANE)
	comA
	andA	>lc(LEFT_OUTLANE)
	staA	lc(LEFT_OUTLANE)
	rts
	
swTilt: 
	;SOUND($0B)
	;SOUND($01)
	lampOn(TILT) ; tilt
	disablePf
	done(0)
	
swStart: 
	checkLamp(GAME_OVER)
	ifne ; in game over
		jsr startGame
	else 
		ldaA	>ballCount
		andA	$F0
		cmpA	$10
		ifeq ; add player if ball 1
			checkLamp(FOUR_PLAYERS)
			ifeq	; if not on P4 already, add player
				aslA
				andA	lr(ONE_PLAYER)|lr(TWO_PLAYERS)|lr(THREE_PLAYERS)|lr(FOUR_PLAYERS)
				oraA	>lc(FOUR_PLAYERS)
				staA	lc(FOUR_PLAYERS)
				inc 	playerCount
			endif
		else ; restart game
			jsr startGame
		endif		
	endif
	
	;jsr refreshPlayerScores
	
	done(0)

collectBonus:
	; start flashing highest x
	ldaA	lr(BONUS_5X) ; 5x
swOuthole_flashX_loop:
	bitA	>lc(BONUS_5X)
	ifne
		oraA	>flc(BONUS_5X)
		staA	flc(BONUS_5X)
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

	checkLamp(BONUS_2X)
	ifne ; still X left to count down
		asr		bonusAnim
		asr 	lc(BONUS_5X) 
		asr		flc(BONUS_5X)
		staB	p_Bonus
		bra	swOuthole_bonusLoop
	endif

	clr		bonusAnim
	; end loop
	rts

swOuthole: 
	;inc	$C0
	checkLamp(GAME_OVER)
	ifne ; game over
		done(0)
	endif
	
	tst	>bonusTimer
	ifne
		done(0)
	else
		ldaA	127
		staA	bonusTimer
	endif
	delay(300)
	SOUND($13)
	
	; check ballsave
	ldaA	lr(SHOOT_AGAIN_PF) ; shoot again
	bitA	>lc(SHOOT_AGAIN_PF)
	ifne	; shoot again on
		bitA	>flc(SHOOT_AGAIN_PF)
		ifne ; shoot again flashing -> ball save
			; turn off flashing ball save
			ldaA	>flc(LEFT_OUTLANE)
			andA	lr(LEFT_OUTLANE)|lr(RIGHT_OUTLANE)
			comA
			andA	>lc(LEFT_OUTLANE)
			staA	lc(LEFT_OUTLANE)
			
			; flash player light
			ldaA	lr(P1_UP)|lr(P2_UP)|lr(P3_UP)|lr(P4_UP) ; player up lights
			oraA	>flc(P1_UP)
			staA	flc(P1_UP)
		endif
	endif
	
	ldaA	lr(P1_UP)|lr(P2_UP)|lr(P3_UP)|lr(P4_UP)  ; player up lights
	bitA	>flc(P1_UP)	; check if any player is flashing
	ifne ; any flashing -> playfield invalid
		lampOff(TILT) ; tilt
		
		enablePf
		fireSolenoid(OUTHOLE)
		clr 	bonusTimer
	
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
		ifne ; kill on ball end
			clr	0, X
		else
			delay(8)
		endif
	endif

	cpX	waitLeftEnd
	bne	l_endBall_wait


	; none flashing -> playfield valid -> end ball

	jsr	collectBonus

	; store player's data
	ldX		>curPlayer
	ldaA	>lc(3)
	staA	p_Col3_6+0, X
	ldaA	>lc(4)
	staA	p_Col3_6+4, X
	ldaA	>lc(5)
	staA	p_Col3_6+8, X
	ldaA	>lc(6)
	staA	p_Col3_6+12, X
	

	ldaA	lr(P1_UP)|lr(P2_UP)|lr(P3_UP)|lr(P4_UP) ; player up lights
	andA	>lc(P1_UP) ; remove non-player up lights from col 8 for processing
	ldaB	>lc(SHOOT_AGAIN_PF) ; check shoot again light
	bitB	lr(SHOOT_AGAIN_PF)
	ifeq ; shoot again not lit
		; go to next player
		aslA
		inc	curPlayer + 1
		bitA	>lc(ONE_PLAYER)	; is player count < player #
		ifne ; last player
			ldaA	lr(P1_UP); ; back to player 1
			clr		curPlayer + 1
			
			; increase ball count
			ldaB	>ballCount
			andB	$F0
			addB	$10
			andB	$F0
			cmpB	$40
			ifeq ; game over
				; wait for any threads to end
				ldX	waitLeft - 1
				ldaB	01000000b; game end flag
l_endGame_wait:
				inX
				tst	0, X
				ifne ; timer running
					bitB	waitC - waitLeft, X
					ifne ; kill on game  end
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
		
		staA	lc(8)
	endif
	
	jsr	startBall
	
	clr 	bonusTimer
	
	done(0)
	
sw10pt:
	score10x(1)
	SOUND($13)
	done(1)

swLeftOutlane:
	score1kx(2)
	checkLamp(LEFT_OUTLANE)
	ifne
		flashLamp(LEFT_OUTLANE)
		flashLamp(SHOOT_AGAIN_PF)
		lampOn(SHOOT_AGAIN_PF)
	endif
	done(0)
swRightOutlane:
	score1kx(2)
	checkLamp(RIGHT_OUTLANE)
	ifne
		flashLamp(RIGHT_OUTLANE)
		flashLamp(SHOOT_AGAIN_PF)
		lampOn(SHOOT_AGAIN_PF)
	endif
	done(0)

swGreen1:
	ldaB	lr(GREEN_1)<<0
	jmp swGreen
swGreen2:
	ldaB	lr(GREEN_1)<<1
	jmp swGreen
swGreen3:
	ldaB	lr(GREEN_1)<<2
	jmp swGreen
swGreen4:
	ldaB	lr(GREEN_1)<<3
	jmp swGreen
swGreen5:
	ldaB	lr(GREEN_1)<<4
	jmp swGreen
swGreen:
	ldX		>curPlayer
	bitB	flc(GREEN_1)
	ifne ; lamp flashing
		score10kx(1)
		cmpB	lr(GREEN_1)
		ifne
			tBA
			asrA
			oraA	>p_Targets, X
			staA	p_Targets, X
		endif
		cmpB	lr(GREEN_5)
		ifne
			tAB
			lslA
			oraA	>p_Targets, X
			staA	p_Targets, X
		endif
	endif
	bitB	lc(GREEN_1)
	ifne ; lamp on
		score1kx(3)
	endif
	score1kx(2)
	tBA
	oraA	>p_Targets, X
	staA	p_Targets, X

	andA	lr(GREEN_1)|lr(GREEN_2)|lr(GREEN_3)|lr(GREEN_4)|lr(GREEN_5)
	cmpA	lr(GREEN_1)|lr(GREEN_2)|lr(GREEN_3)|lr(GREEN_4)|lr(GREEN_5)
	ifeq
		lampOn(EJECT_GREEN)
		flashLamp(EJECT_GREEN)
		jsr checkEjectLamps
	endif
	done(1)

swLeftSpinner:
	ldaA	lr(LOOP_20K)
lLeftSpinner:
	bitA	lc(LOOP_5K)
	ifne
		score100x(5)
	endif
	asrA
	bcc lLeftSpinner

	done(1)

swCenterSpinnerStandup:
swLeftSpinnerStandup:
	score10x(5)
	advBonus()
	done(1)

swTarget:
	score1kx(1)
	done(1)

swRightPop:
	checkLamp(POP_RIGHT)
	jmp swPop
swLeftPop:
	checkLamp(POP_LEFT)
	jmp swPop
swBottomPop:
	checkLamp(POP_BOTTOM)
	jmp swPop
swPop:
	ifne
		score1kx(1)
	else
		score100x(1)
	endif
	done(1)
swRed1:
	ldaB	lr(RED_1)<<0
	jmp swRed
swRed2:
	ldaB	lr(RED_1)<<1
	jmp swRed
swRed3:
	ldaB	lr(RED_1)<<2
	jmp swRed
swRed:
	; check if already down
	tBA
	aslA
	aslA
	aslA
	aslA
	bitA	>drops
	ifne ; already down
		done(0)
	endif
	oraA	>drops
	staA	drops

	bitB	>lc(RED_1)
	ifne ; lamp lit
		bitB	>flc(RED_1)
		ifne ; lamp flashing -> combo
			flashOff(RED_1)
			flashOff(RED_2)
			flashOff(RED_3)
			delay(200)
			jmp swRedAll
		endif
		score1kx(5)
	else
		score1kx(2)
	endif	
	tBA
	oraA	>lc(RED_1)
	staA	lc(RED_1)

	; check if all down
	ldaA	>drops
	andA	01110000b
	cmpA	01110000b
	ifeq ; all down
		jmp swRedAll
	endif
	done(1)
swRedAll:
	fireSolenoid(RED_RESET)
	lampOn(EJECT_RED)
	ldaA	>flc(EJECT_RED)
	andA	lr(EJECT_GREEN)|lr(EJECT_YELLOW)
	cmpA	lr(EJECT_GREEN)|lr(EJECT_YELLOW)
	ifeq ; green and yellow flashing
		flashLamp(EJECT_RED)
	else
		ldaA	>flc(EJECT_RED)
		andA	~(lr(EJECT_GREEN)|lr(EJECT_YELLOW))
		staA	flc(EJECT_RED)
	endif
	jsr checkEjectLamps
	delay(200)

	ldaA 	~01110000b
	andA	>drops
	staA	drops
	done(1)
swYellow1:
	ldaB	lr(YELLOW_1)<<0
	jmp swYellow
swYellow2:
	ldaB	lr(YELLOW_1)<<1
	jmp swYellow
swYellow3:
	ldaB	lr(YELLOW_1)<<2
	jmp swYellow
swYellow:
	; check if already down
	tBA
	bitA	>drops
	ifne ; already down
		done(0)
	endif
	oraA	>drops
	staA	drops

	bitB	>lc(YELLOW_1)
	ifne ; lamp lit
		score1kx(5)
		lampOn(YELLOW_1)
		lampOn(YELLOW_2)
		lampOn(YELLOW_3)
		jmp swYellowAll
	else
		score1kx(2)
	endif	
	tBA
	oraA	>lc(YELLOW_1)
	staA	lc(YELLOW_1)

	; check if all down
	ldaA	>drops
	andA	0111b
	cmpA	0111b
	ifeq ; all down
		jmp swYellowAll
	endif
	done(1)
swYellowAll:
	fireSolenoid(YELLOW_RESET)
	lampOn(EJECT_YELLOW)
	ldaA	>flc(EJECT_RED)
	andA	lr(EJECT_GREEN)
	cmpA	lr(EJECT_GREEN)
	ifeq ; green and yellow flashing
		flashLamp(EJECT_YELLOW)
	else
		flashOff(EJECT_GREEN)
	endif
	jsr checkEjectLamps
	delay(200)

	ldaA 	~0111b
	andA	>drops
	staA	drops
	done(1)
swLane1:
	ldaB	lr(LANE_1)
	jmp swLane
swLane2:
	ldaB	lr(LANE_2)
	jmp swLane
swLane3:
	ldaB	lr(LANE_3)
	jmp swLane
swLane:
	score1kx(1)

	; light lane
	tBA
	oraA	>lc(LANE_1)
	staA	lc(LANE_1)

	; check if all 3
	andA	lr(LANE_1)|lr(LANE_2)|lr(LANE_3)
	cmpA	lr(LANE_1)|lr(LANE_2)|lr(LANE_3)
	ifeq
		; increase X
		ldaA	>lc(BONUS_2X)
		oraA	lr(BONUS_2X)>>1
		asrA
		andA	lr(BONUS_2X)|lr(BONUS_3X)|lr(BONUS_4X)|lr(BONUS_5X)
		oraA	>lc(BONUS_2X)
		staA	lc(BONUS_2X)

		delay(200)
		lampOff(LANE_1)
		lampOff(LANE_2)
		lampOff(LANE_3)
	endif

	done(1)

swRightSpinner:
	checkLamp(RIGHT_SPINNER)
	ifne
		checkFlash(RIGHT_SPINNER)
		ifne
			score1kx(5)
		else
			score1kx(1)
		endif
	else
		score100x(1)
	endif
	done(1)

swCenterSpinner:
	checkLamp(CENTER_SPINNER)
	ifne
		checkFlash(CENTER_SPINNER)
		ifne
			score1kx(5)
		else
			score1kx(1)
		endif
	else
		score100x(1)
	endif
	done(1)
.org	$7000
awardTempScore:
	ldaA	>pT_1 - 1
	andA	$0F
	jsr	_addScore10N
	delay(150)
	ldaA	>pT_1 - 2
	andA	$0F
	jsr	_addScore100N
	delay(150)
	ldaA	>pT_1 - 3
	andA	$0F
	jsr	_addScore1000N
	delay(150)
	ldaA	>pT_1 - 4
	andA	$0F
	jsr	_addScore10kN
	delay(150)
	ldaA	>pT_1 - 5
	andA	$0F
	jsr	_addScore100kN
	rts

; adds B to temp in thousands slowly
; trash A
incTempScore:
lIncTempScore:
	ldaA	1
	ldX	pT_1 - 3
	jsr	_addScoreI
	decB
	delay(150)
	bne lIncTempScore

	rts

swEject:
	checkLamp(GAME_OVER)
	ifne
		fireSolenoid(EJECT)
		done(0)
	endif

	checkLamp(EJECT_BLACK)
	ifne
		onSolenoid(BLACKOUT)
	endif

	
	;ldX	pT_1m
	;jsr 	blankLeadingScoreZeroes

	; display value
	ldaA	3
	cmpA	>curPlayer + 1
	ifeq ; p4
		ldaA	pT_1m - dispData + 1
		staA	dispOffsets + 2
	else
		ldaA	pT_1m - dispData + 1
		staA	dispOffsets + 3
	endif

	checkLamp(EJECT_GREEN)
	ifne
		checkFlash(EJECT_GREEN)
		ifne
			ldaB	25
		else
			ldaB	5
		endif
	else
		clrB
	endif
	tstB
	ifne
		jsr incTempScore
		lampOff(EJECT_GREEN)
		flashOff(EJECT_GREEN)
		delay(500)
	endif

	checkLamp(EJECT_YELLOW)
	ifne
		checkFlash(EJECT_YELLOW)
		ifne
			ldaB	50
		else
			ldaB	5
		endif
	else
		clrB
	endif
	tstB
	ifne
		jsr incTempScore
		lampOff(EJECT_YELLOW)
		flashOff(EJECT_YELLOW)
		delay(500)
	endif

	checkLamp(EJECT_RED)
	ifne
		checkFlash(EJECT_RED)
		ifne
			ldaB	100
		else
			ldaB	5
		endif
	else
		clrB
	endif
	tstB
	ifne
		jsr incTempScore
		lampOff(EJECT_RED)
		flashOff(EJECT_RED)
		delay(500)
	endif

	checkLamp(EJECT_BLACK)
	ifne
		flashLamp(EJECT_BLACK)
		ldaB	100
		jsr incTempScore

		lampOff(EJECT_BLACK)
		flashOff(EJECT_BLACK)
		ldaB	10
lBlackout:
		offSolenoid(BLACKOUT)
		delay(150)
		onSolenoid(BLACKOUT)
		delay(150)
		decB
		bne lBlackout
	endif


	jsr awardTempScore	

	jsr	fixDispOffsets
	offSolenoid(BLACKOUT)

	fireSolenoid(EJECT)
	done(1)

swLeftInlane:
	checkLamp(LEFT_INLANE)
	ifne
		score1kx(3)
		ldaB	>lc(CENTER_SPINNER)
		andB	lr(CENTER_SPINNER)|lr(RIGHT_SPINNER)
		ifeq ; no spinner lit
			; randomly light one
			ldaA	1b
			bitA	>counter
			ifeq
				lampOn(CENTER_SPINNER)
			else
				lampOn(RIGHT_SPINNER)
			endif
		endif

		; flash lit spinner(s)
		ldaA	>flc(CENTER_SPINNER)
		oraA	lr(CENTER_SPINNER)|lr(RIGHT_SPINNER)
		staA	flc(CENTER_SPINNER)

		delay(2000)
		delay(2000)
		delay(2000)

		; restore spinner state
		ldaA	>lc(CENTER_SPINNER)
		andA	~(lr(CENTER_SPINNER)|lr(RIGHT_SPINNER))
		staA	lc(CENTER_SPINNER)
		oraB	>lc(CENTER_SPINNER)
		staB	lc(CENTER_SPINNER)

		ldaA	>flc(CENTER_SPINNER)
		andA	~(lr(CENTER_SPINNER)|lr(RIGHT_SPINNER))
		staA	flc(CENTER_SPINNER)
	else
		score1kx(2)
	endif
	done(1)
swRightInlane:
	checkLamp(RIGHT_INLANE)
	ifne
		score1kx(3)
		ldaB	>lc(RED_1)
		andB	lr(RED_1)|lr(RED_2)|lr(RED_3)
		ldaA	>lc(RED_1)
		oraA	lr(RED_1)|lr(RED_2)|lr(RED_3)
		staA	lc(RED_1)
		ldaA	>flc(RED_1)
		oraA	lr(RED_1)|lr(RED_2)|lr(RED_3)
		staA	flc(RED_1)

		delay(2000)
		delay(2000)
		delay(2000)

		; restore state
		ldaA	>lc(RED_1)
		andA	~(lr(RED_1)|lr(RED_2)|lr(RED_3))
		staA	lc(RED_1)
		oraB	>lc(RED_1)
		staB	lc(RED_1)

		ldaA	>flc(RED_1)
		andA	~(lr(RED_1)|lr(RED_2)|lr(RED_3))
		staA	flc(RED_1)
	else
		score1kx(2)
	endif
	done(1)


checkEjectLamps:
	ldaA	>lc(EJECT_GREEN)
	andA	lr(EJECT_GREEN)|lr(EJECT_YELLOW)|lr(EJECT_RED)
	cmpA	lr(EJECT_GREEN)|lr(EJECT_YELLOW)|lr(EJECT_RED)
	ifeq
		lampOn(EJECT_BLACK)
		flashLamp(EJECT_BLACK)
	endif
	rts

swLaneChange:
	clrB
	ldaA	>lc(LANE_1)
	aslA
	ifcs ; right inlane was lit
		incB
	endif
	bitA	lr(LANE_1)
	ifne  ; bottom jet was lit
		oraA	lr(POP_RIGHT)
	endif
	bitA	lr(LEFT_INLANE)
	ifne ; 3 was lit
		oraA	lr(LANE_1)
	endif
	andA	~lr(LEFT_INLANE)
	tstB
	ifne ; right inlane was lit
		oraA	lr(LEFT_INLANE)
	endif
	staA	lc(LANE_1)
	done(0)


; end callbacks
	.msfirst
; needs to be on $**00 address
callbackTable: 	.org $6000 ; note: TRANSPOSED
	.dw swTilt	\.dw swTilt\.dw swStart	\.dw none\.dw none\.dw none\.dw swTilt\.dw none
	.dw swOuthole\.dw swLeftOutlane\.dw swGreen1\.dw swGreen2\.dw swGreen3\.dw swGreen4\.dw swGreen5\.dw none
	.dw none\.dw swLeftSpinner\.dw swLeftSpinnerStandup\.dw swTarget\.dw swRightPop\.dw swLeftPop\.dw swBottomPop\.dw none
	.dw swRed1	\.dw swRed2\.dw swRed3\.dw none\.dw swLane1\.dw swLane2\.dw swLane3\.dw swTilt
	.dw swYellow1\.dw swYellow2\.dw swYellow3\.dw none\.dw swRightSpinner\.dw swCenterSpinnerStandup\.dw swCenterSpinner\.dw swEject
	.dw swRightOutlane	\.dw swRightInlane\.dw sw10pt\.dw sw10pt\.dw swLeftInlane\.dw swLaneChange\.dw none\.dw none
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
#define FAST    SW(0,0,1,0)
settleTable: ; must be right after callbackTable
	SW(0,7,1,0)\SW(0,7,1,0)\SW(0,2,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,1,0)\SW(0,7,0,1)
	SW(7,1,1,1)\LANE\TARGET\TARGET\TARGET\TARGET\TARGET\TARGET
	SW(0,0,1,0)\FAST\TARGET\TARGET\POP\POP\POP\LANE
	TARGET\TARGET\TARGET\HOLE\LANE\LANE\LANE\SW(0,7,1,0)
	TARGET\TARGET\TARGET\HOLE\FAST\TARGET\FAST\HOLE
	LANE\LANE\TARGET\TARGET\LANE\TARGET\DROP\TARGET
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)