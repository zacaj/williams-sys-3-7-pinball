; Laser Ball solenoids
;#DEFINE KICKOUT 		01
;#DEFINE LEFT_KICKER 	02
;#DEFINE DROP_LA			03
;#DEFINE DROP_SER		04
;#DEFINE EJECT_HOLE		05
;#DEFINE DROP_BA			06
;#DEFINE DROP_LL			07
;#DEFINE RIGHT_KICKER	08
;#DEFINE SOUND1			09 ; thru 13
;#DEFINE KNOCKER			14
;#DEFINE	FLASHERS		15
;#DEFINE COIN_LOCKOUT	16

; Hot Tip solenoids
#DEFINE SOL(n,t)	(n<<8)|t
#DEFINE TOP_EJECT 	SOL(01, 24)
#DEFINE DROP_TIP	SOL(02, 100)
#DEFINE DROP_HOT	SOL(03, 100)
#DEFINE LEFT_EJECT	SOL(04, 24)
#DEFINE OUTHOLE		SOL(05, 20)
#DEFINE CHIME_10	SOL(09, 16)
#DEFINE CHIME_100	SOL(10, 16)
#DEFINE CHIME_1000	SOL(11, 16)
#DEFINE CHIME_10k	SOL(12, 16)
#DEFINE CLICKER		SOL(13, 8)
#DEFINE	KNOCKER		SOL(14, 50)
#DEFINE BUZZER		SOL(15, 100)
#DEFINE SHORT_PAUSE 	115

#DEFINE noValidate ldaA 10b\ oraA >state\ staA state
#DEFINE done(v)	\
#DEFCONT	#IF (v==0)
#DEFCONT		\ ldaA 10b
#DEFCONT		\ oraA >state
#DEFCONT		\ staA state
#DEFCONT	\#ENDIF
#DEFCONT	\ jmp afterQueueEvent
	
	
_addScore10N:
	jsr setXToCurPlayer10
	ldaA	1
	jsr _addScoreI
	fireSolenoidA(CHIME_10)
	rts
_addScore100N:
	jsr setXToCurPlayer10
	deX
	ldaA	1
	jsr _addScoreI
	fireSolenoidA(CHIME_100)	
	rts
_addScore1000N:
	jsr setXToCurPlayer10
	deX
	deX
	ldaA	1
	jsr _addScoreI
	fireSolenoidA(CHIME_1000)
	rts
#DEFINE score10() jsr _addScore10N
#DEFINE score100() jsr _addScore100N
#DEFINE score1000() jsr _addScore1000N
#DEFINE score500() \ jsr _addScore100N
#DEFCONT	\ fireSolenoid(CHIME_100)	
#DEFCONT	\ delay(SHORT_PAUSE)
#DEFCONT	\ jsr _addScore100N
#DEFCONT	\ fireSolenoid(CHIME_100)	
#DEFCONT	\ delay(SHORT_PAUSE)
#DEFCONT	\ jsr _addScore100N
#DEFCONT	\ fireSolenoid(CHIME_100)	
#DEFCONT	\ delay(SHORT_PAUSE)
#DEFCONT	\ jsr _addScore100N
#DEFCONT	\ fireSolenoid(CHIME_100)	
#DEFCONT	\ delay(SHORT_PAUSE)
#DEFCONT	\ jsr _addScore100N
#DEFCONT	\ fireSolenoid(CHIME_100)	
#DEFCONT	\ delay(SHORT_PAUSE)

#DEFINE advBonus()	jsr advanceBonus

advanceBonus:
	ldaA	1000b
	bitA	>state
	ifne
		rts
	endif
	inc 	p_Bonus
	lampOff(8,5) ; 1k
	ldaB	2
	fork(64)
	rts
	nop
	nop
	beginFork()
advanceBonus_loop:
	dec	p_Bonus
	jsr 	bonusLights
	inc	p_Bonus
	ldaA	11111110b
	
	pshB
	decB
inner:
	decB
	beq	innerEnd
	seC
	rolA
	bra 	inner
innerEnd:
	pulB
	
	andA	>lc(6)
	staA	lc(6)
	delay(64)
	incB
	cmpB	>p_Bonus
	blt	advanceBonus_loop
	ldaB	>p_Bonus
	jsr 	bonusLights
	endFork()
	
; switch callbacks:

none:	.org $6000 + 192 ; size of callback table
	done(1)
	
bonusLights:
	ldaA	0
	staA	lc(5)
	staA	lc(6)
	tst	>p_Bonus
	beq	bonusLights_done
	
	lampOn(8,5) ; 1k
	
	ldaA	>p_Bonus
bonusLights_loop:
	decA
	beq 	bonusLights_done
	seC
	rol	lc(6)
	bra	bonusLights_loop
	
bonusLights_done

	ldaA	9
	cmpA	>p_Bonus
	ifge	
	else	; bonus >= 10?
		ldaA	10
		staA	p_Bonus
		lampOn(7,5) ; 10k light
	endif
	
	rts
	
	
startBall:
	ldX	>curPlayer
	ldaA	1
	staA	p_Bonus
	lampOn(8,5)
	enablePf
	
	ldaA	0
	staA	p_DropsDown
	ldaA	65
	staA	dropResetTimer
	
	ldaA	0
	staA	dropsDown
	
	fireSolenoid(DROP_HOT)
	delay(150)
	fireSolenoid(DROP_TIP)
	delay(150)
	
	ldaA	$FF
	staA	lastSwitch
	
	; clear lights
	ldX	lampCol1
	ldaA	0b
lClearLights:
	staA	0, X
	staA	flashLampCol1 - lampCol1, X
	inX
	cpX	lc(6) + 1
	bne	lClearLights
	;
	
	; init lights for player data
	ldX	>curPlayer
	ldaA	p_Ejects, X
	staA	lc(4)
	ldaB	p_LampCol2, X
	bitB	lr(2)
	ifne 
		lampOn(2,3)
		andB	11111101b
	endif
	staB	lc(2)
	
	ldaA	lr(7) ; shoot again
	bitA	>lc(8)
	ifne
		lampOn(1,3) ; shoot again
	endif
	
	; flash player light
	ldaA	00001111b ; player up lights
	oraA	>flc(8)
	staA	flc(8)
	
	ldaA	sr(1) ; check outhole
	bitA	>sc(2)
	ifne ; ball in hole
		fireSolenoid(OUTHOLE)
	endif
	
	rts
	
	
startGame:
	lampOn(2,7) ; one player
	
	lampOff(6,8) ; game over
	
	fireSolenoid(CHIME_10)
	delay(SHORT_PAUSE)
	fireSolenoid(CHIME_10)
	delay(SHORT_PAUSE)
	fireSolenoid(CHIME_10)
	delay(200)
	
	fireSolenoid(CHIME_10)
	delay(SHORT_PAUSE)
	fireSolenoid(CHIME_10)
	delay(SHORT_PAUSE)
	fireSolenoid(CHIME_10)
	delay(200)
	
	fireSolenoid(CHIME_10)
	delay(SHORT_PAUSE)
	fireSolenoid(CHIME_10)
	delay(SHORT_PAUSE)
	fireSolenoid(CHIME_100)
	delay(200)
	fireSolenoid(CHIME_1000)
	delay(200)
	fireSolenoid(CHIME_10k)
	delay(150)
	
	; reset scores
	jsr 	resetScores
	
	; reset ball count
	ldaA	$10
	staA	ballCount	

	ldaB	0
	staB	curPlayer + 1
	
	staB	lc(7)
	staB	lc(8)
	staB	flc(7)
	staB	flc(8)
	
	ldX	0
lInitPlayers:
	ldaB	lr(1)
	staB	p_Ejects, X
	ldaB	0
	staB	p_LampCol2, X
	staB	p_EachDropDown, X
	inX
	cpX	4
	bne	lInitPlayers
	
	jsr	startBall
	
	; invalidate playfield
	ldaA	lr(1)
	oraA	>lc(8)
	staA	lc(8)
	
	lampOn(2,7) ; one player
	
	lampOff(6,8) ; game over
	
	rts
	

	
swTilt: 
	lampOn(5,8) ; tilt
	disablePf
	done(0)
	
swStart: 
	ldaA >lc(8)
	bitA lr(6)
	ifne ; in game over
		jsr startGame
	else 
		ldaA	$10
		cmpA	>ballCount
		ifeq ; add player
			ldaA	00011110b
			andA	>lc(7) ; player count lights
			bitA	lr(5)
			ifeq	; if not on P4 already, add player
				aslA
				ldaB	11100001b
				andB	>lc(7)
				staB	lc(7)
				oraA	>lc(7)
				staA	lc(7)
			endif
		else ; restart game
			jsr startGame
		endif		
	endif
	
	jsr refreshPlayerScores
	
	done(0)
	
swOuthole: 
	ldaA	>lc(8) ; !game over
	bitA	lr(6)
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
	delay(600)
	
	; check ballsave
	ldaA	lr(1)
	bitA	>lc(3)
	ifne	; shoot again on
		bitA	>flc(3)
		ifne ; shoot again flashing
			; turn off used special
			ldaA	lr(8) ; right special
			bitA	>lc(2)
			ifne
				lampOff(8,2)
				flashOff(8,2)
			endif
			ldaA	lr(2) ; right special
			bitA	>lc(3)
			ifne
				lampOff(2,3)
				flashOff(2,3)
			endif
			
			; flash player light
			ldaA	00001111b ; player up lights
			oraA	>flc(8)
			staA	flc(8)
		endif
	endif
	
	ldaA	00001111b ; player up lights
	bitA	>flc(8)	; check if any player is flashing
	ifne ; any flashing -> playfield invalid
swOuthole_save:
		lampOff(5,8) ; tilt
		
		enablePf
		fireSolenoid(OUTHOLE)
	else ; none flashing -> playfield valid -> end ball			
swOuthole_bonusLoop:
		score1000()
		ldaA	>lc(2) ; double bonus
		bitA	lr(3)
		ifne 
			delay(100)
			score1000()
		endif
		dec	p_Bonus
		jsr	bonusLights
		delay(200)
		tst	>p_Bonus
		bne	swOuthole_bonusLoop
	
		ldaA	00001111b ; player up lights
		andA	>lc(8) ; remove non-player up lights from col 8 for processing
		ldaB	>lc(3) ; check shoot again light
		bitB	lr(1)
		ifeq ; shoot again not lit
			; store player's data
			ldX	>curPlayer
			ldaB	>lc(4)
			staB	p_Ejects, X
			ldaB	>lc(3)
			andB	lr(2)
			oraB	>lc(2)
			staB	p_LampCol2, X
			ldaB	>dropsDown
			staB	p_EachDropDown, X
			
		
			; go to next player
			aslA
			inc	curPlayer + 1
			bitA	>lc(7)	; is player count < player #
			ifne ; last player
				ldaA	00000001b; ; back to player 1
				ldaB	0
				staB	curPlayer + 1
				
				; increase ball count
				ldaB	>ballCount
				addB	$10
				cmpB	$40
				ifeq ; game over
					lampOn(6,8)
					disablePf
					done(1)
				else
					staB	ballCount
				endif		
			endif
			
			staA	lc(8)
		endif
		
		jsr	startBall
	endif	
	
	clr 	bonusTimer
	
	done(0)
	
swLeftEject:
	ldaA	>lc(8)
	bitA	lr(6)
	ifne ; not in game
		fireSolenoid(LEFT_EJECT)
		done(0)
	endif
		
	advBonus()
	ldaA	lr(3) ; extra ball
	bitA	>lc(3)
	ifne
		fireSolenoid(KNOCKER)
		lampOn(1,3) ; shoot again
		lampOn(7,8)
		lampOff(3,3) ; extra ball
		delay(500)
	else
		jsr	addCollect
		score500()
	endif
	fireSolenoid(LEFT_EJECT)
	
	fork(400)
	done(1)
	beginFork()
	ldaA	11000111b
	andA	>flc(2)
	staA	flc(2)
	endFork()
	
swTopEject:
	advBonus()
	ldaB	>lc(4)
	asrB
	ifeq ; 1k
		score1000()
		delay(200)
		jmp	swTopEject_scored
	endif
	asrB
	ifeq  ; captive
		ldaA	lr(7)
		bitA	>lc(2) ; captive ball
		ifeq	; not lit
			lampOn(7,2)
			flashLamp(7,2)
		else
			lampOff(7,2)
		endif
	score500()
		jmp	swTopEject_scored
	endif
	asrB
	ifne	
		asrB
		ifeq ; double
			ldaA	lr(3)
			bitA	>lc(2) ; double bonus
			ifeq	; not lit
				lampOn(3,2)
				flashLamp(3,2)
			else
				lampOff(3,2)
			endif
		endif
	endif
	score500()
swTopEject_scored:
	flashOff(3,2)
	flashOff(7,2)
	fireSolenoid(TOP_EJECT)
	done(1)
	
swHotTip:
	tst	>dropResetTimer
	ifne
		done(0)
	endif
	
	jsr	addCollect
	ldaA	0
	staA	p_DropsDown
	staA	dropsDown
	ldaA	65
	staA	dropResetTimer
	delay(150)
	fireSolenoid(DROP_HOT)
	delay(150)
	fireSolenoid(DROP_TIP)
	lampOff(4,3) ; spinner
	
	fork(900)
	done(1)
	beginFork()
	ldaA	11000111b
	andA	>flc(2)
	staA	flc(2)
	endFork()
	
swLeftOutlane:
	ldaA	lr(2) ; left special
	bitA	>lc(3)
	ifne
		lampOn(1,3) ; shoot again
		flashLamp(1,3)
		fireSolenoid(BUZZER)
		flashLamp(2,3)
	endif
	advBonus()
	score1000()
	done(1)
	
swRightOutlane:
	ldaA	lr(8) ; right special
	bitA	>lc(2)
	ifne
		lampOn(1,3) ; shoot again
		flashLamp(1,3)
		fireSolenoid(BUZZER)
		flashLamp(8,2)
	endif
	advBonus()
	score1000()
	done(1)
	
swLeftInlane:
swRightInlane:
	advBonus()
	score1000()
	done(1)
sw10pt:
	score10()
	asr	lc(4)
	ifeq ; shifted off the edge
		ldaA	00010000b
		staA	lc(4)
	endif
	done(1)
sw100pt:
	score100()
	done(1)
sw500pt:
	jsr	alternate
	score500()
	done(1)
swPop:
	jsr	alternate
	score100()
	done(1)
swDropTip:
	ldaA	1<<3
	jmp	swDrop
swDropHot:
	ldaA	1<<0
	jmp	swDrop
swDroptIp:
	ldaA	1<<4
	jmp	swDrop
swDrophOt:
	ldaA	1<<1
	jmp	swDrop
swDroptiP:
	ldaA	1<<5
	jmp	swDrop
swDrophoT:
	ldaA	1<<2
	jmp	swDrop
swDrop:
	tst	>dropResetTimer
	ifeq
		bitA	>dropsDown
		ifne
			done(0)
		endif
		oraA	>dropsDown
		
		staA	dropsDown
		inc	p_DropsDown
		ldaA	4
		cmpA	>p_DropsDown
		ifgt
			lampOff(4,3) ; spinner
		else
			lampOn(4,3)
		endif
		
		score10()
		advBonus()
		done(1)
	else
		done(0)
	endif
swAdvBonus:
	advBonus()
	score1000()
	done(1)
swSpinner:
	;ldaA	>sc(4)
	;bitA	sr(6)
	;ifne
	;	score100()
	;	ldaA	$E
	;else
	;	noValidate
	;	ldaA	0
	;endif
	;staA	solenoid1 + CLICKER - 1
	
	ldaA	lr(4) ; spinner
	bitA	>lc(3)
	ifne ; spinner on
		score100()
		fireSolenoid(CLICKER)
	else
		score10()
	endif
	done(1)

swCaptiveRollover:
	ldaA	>lc(2)
	bitA	lr(7)
	ifeq ; light off
		score10()
	else
		score1000()
		ldaA	14 ; captive rollover switch number
		cmpA	>lastSwitch
		ifne
			ldaA	15 ; captive rollover switch number
			cmpA	>lastSwitch
			ifne
				jsr	captiveAward
			endif
		endif
	endif
	done(1)

swCaptiveTarget:
	advBonus()
	ldaA	>lc(2)
	bitA	lr(7)
	ifeq ; light off
		score10()
		jsr	captiveAward
	else
		score1000()
	endif
	done(1)
	
captiveAward:
	fork(10)
	rts
	nop
	nop
	
	beginFork()
	lampOn(8,2) ; right special
	
	ldaA	>lc(2)
	bitA	lr(4) ; shoe 1
	ifeq
		endFork()
	else
		bitA	lr(6)
		ifne
			flashLamp(6,2)
		else
			bitA	lr(5)
			ifne
				flashLamp(5,2)
			else
				flashLamp(4,2)
			endif
		endif
	endif
	
	ldaA	lr(3)
	bitA	>lc(2)
	ifne ; double bonus
		ldaA	>p_Bonus
	else
		ldaA	1
	endif	
	staA	p_BonusLeft
	
captiveAward_bonusLoop:
	score1000()
	dec	p_Bonus
	jsr	bonusLights
	delay(200)
	tst	>p_Bonus
	bne	captiveAward_bonusLoop
	
	ldaA	00111000b
	andA	>flc(2)
	comA
	andA	>lc(2)
	staA	lc(2)
	
	ldaA	>p_BonusLeft
	staA	p_Bonus
	
	endFork()	
	
	
alternate:
	ldaB	0 ; turn on left?
	ldaA	lr(8) ; right special
	bitA	>lc(2)
	ifne
		ldaB	1
		lampOff(8,2) ; right special
	endif
	ldaA	lr(2) ; left special
	bitA	>lc(3)
	ifne
		lampOn(8,2) ; right special
		lampOff(2,3) ; left special
	endif
	tstB
	ifne
		lampOn(2,3) ; left special
	endif
	rts
	
addCollect:
	ldaA	>lc(2)
	bitA	lr(4)
	ifeq
		lampOn(4,2)
		flashLamp(4,2)
	else
		bitA	lr(5)
		ifeq
			lampOn(5,2)
			flashLamp(5,2)
		else
			bitA	lr(6)
			ifeq
				lampOn(6,2)
				flashLamp(6,2)
			else
				score1000()
				lampOn(3,3)
			endif
		endif
	endif
	rts
	
; end callbacks
	.msfirst
; needs to be on $**00 address
callbackTable: 	.org $6000 ; note: TRANSPOSED
	.dw swTilt	\.dw swTilt\.dw swStart	\.dw none\.dw none\.dw none\.dw swTilt\.dw none
	.dw swOuthole	\.dw swTilt\.dw swRightOutlane\.dw swRightInlane\.dw sw10pt\.dw sw500pt\.dw swCaptiveRollover\.dw swCaptiveTarget
	.dw swDropTip	\.dw swDroptIp\.dw swDroptiP\.dw swAdvBonus\.dw sw10pt\.dw swTopEject\.dw sw10pt\.dw none
	.dw swDropHot	\.dw swDrophOt\.dw swDrophoT\.dw sw10pt\.dw swLeftEject\.dw swSpinner\.dw swPop\.dw sw500pt
	.dw swLeftOutlane\.dw swLeftInlane\.dw sw10pt\.dw none\.dw swHotTip\.dw none\.dw none\.dw none
	.dw none	\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none	\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none	\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
; on = how many cycles it must be on for before registering (1 cycle = 64ms (?)) (max 7)
; off = how many cycles it must be off for
; onOnly = if true, don't notify of an off event (also set off = 0 for efficiency)
; gameover = whether the switch is active in gameover + tilt mode (these callbacks must check whether in game over when triggered if they want to act different)
; TRANSPOSED (?)
#define SW(on,off,onOnly,gameover) .db (onOnly<<7)|(gameover<<6)|(on<<3)|(off) 
settleTable: ; must be right after callbackTable
	SW(0,7,1,0)\SW(0,7,1,0)\SW(0,2,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,1,0)\SW(0,7,0,1)
	SW(7,1,1,1)\SW(0,7,1,0)\SW(0,7,1,0)\SW(0,7,1,0)\SW(0,1,1,0)\SW(0,1,1,0)\SW(0,0,1,0)\SW(0,7,1,0)
	SW(0,7,1,0)\SW(0,7,1,0)\SW(0,7,1,0)\SW(0,3,1,0)\SW(0,3,1,0)\SW(4,1,1,1)\SW(0,1,1,0)\SW(0,0,1,0)
	SW(0,7,1,0)\SW(0,7,1,0)\SW(0,7,1,0)\SW(0,1,1,0)\SW(4,1,1,1)\SW(0,0,1,0)\SW(0,0,1,0)\SW(0,1,1,0)
	SW(0,7,1,0)\SW(0,7,1,0)\SW(0,1,1,0)\SW(0,7,0,1)\SW(0,0,1,0)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(7,7,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)