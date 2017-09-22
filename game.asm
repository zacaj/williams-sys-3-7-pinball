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
#DEFINE TOP_EJECT 	SOL(01, 32)
#DEFINE DROP_TIP	SOL(02, 100)
#DEFINE DROP_HOT	SOL(03, 100)
#DEFINE LEFT_EJECT	SOL(04, 32)
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

#DEFINE advBonus()
	
; switch callbacks:

none:	.org $6000 + 192 ; size of callback table
	done(1)
	
	
startGame:
	
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
	
	
	enablePf
	
	fireSolenoid(DROP_TIP)
	delay(75)
	fireSolenoid(DROP_HOT)
	delay(125)
	
	; clear lights
	ldX	lampCol1
	ldaA	0b
lClearLights:
	staA	0, X
	staA	flashLampCol1 - lampCol1, X
	inX
	cpX	lampCol8 + 1
	bne	lClearLights
	;
	
	; reset scores
	jsr 	resetScores
	
	; reset ball count
	ldaA	$10
	staA	ballCount

	ldaB	0
	staB	curPlayer + 1
	
	; invalidate playfield
	ldaA	lr(1)
	oraA	>flc(8)
	staA	flc(8)
	oraA	>lc(8)
	staA	lc(8)
	
	lampOn(2,7) ; one player
	
	ldaA	sr(1) ; check outhole
	bitA	>sc(2)
	ifne ; ball in hole
		fireSolenoid(OUTHOLE)
	endif
	
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
	delay(600)
	ldaA	>lc(8) ; !game over
	bitA	lr(6)
	ifeq ; !game over
		ldaA	00001111b ; player up lights
		bitA	>flc(8)	; check if any player is flashing
		ifne ; any flashing -> playfield invalid
			lampOff(5,8) ; tilt
			
			enablePf
			fireSolenoid(OUTHOLE)
		else ; none flashing -> playfield valid -> end ball
			andA	>lc(8)
			ldaB	>lc(3)
			bitB	lr(1)
			ifeq ; shoot again not lit
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
			
			; flash player light
			ldaA	00001111b ; player up lights
			oraA	>flc(8)
			staA	flc(8)
			
			fireSolenoid(DROP_TIP)
			delay(75)
			fireSolenoid(DROP_HOT)
			delay(125)
			
			
			enablePf
			
			fireSolenoid(OUTHOLE)
		endif
	endif		
	done(0)
	
swLeftEject:
	ldaA	>lc(8)
	bitA	lr(6)
	ifeq ; in game
		lampOn(1,3)
		lampOn(7,8)
	endif
	score500()
	fireSolenoid(LEFT_EJECT)
	done(1)
	
swTopEject:
	score500()
	fireSolenoid(TOP_EJECT)
	done(1)
	
swHotTip:
	delay(75)
	fireSolenoid(DROP_HOT)
	delay(75)
	fireSolenoid(DROP_TIP)
	done(1)
swLeftOutlane:
swRightOutlane:
swLeftInlane:
swRightInlane:
	score1000()
	done(1)
sw10pt:
	score10()
	done(1)
sw100pt:
	score100()
	done(1)
sw500pt:
	score500();
	done(1)
swDropTip:
	score10()
	done(1)
swDropHot:
	score10()
	done(1)
swAdvBonus:
	advBonus()
	done(1)
swSpinner:
	ldaA	>sc(4)
	bitA	sr(6)
	ifne
		score100()
		ldaA	$E
	else
		noValidate
		ldaA	0
	endif
	staA	solenoid1 + CLICKER - 1
	done(1)

	
	
; end callbacks
	.msfirst
; needs to be on $**00 address
callbackTable: 	.org $6000 ; note: TRANSPOSED
	.dw swTilt	\.dw swTilt\.dw swStart	\.dw none\.dw none\.dw none\.dw swTilt\.dw none
	.dw swOuthole	\.dw swTilt\.dw swRightOutlane\.dw swRightInlane\.dw sw10pt\.dw sw500pt\.dw none\.dw none
	.dw swDropTip	\.dw swDropTip\.dw swDropTip\.dw swAdvBonus\.dw sw10pt\.dw swTopEject\.dw sw10pt\.dw none
	.dw swDropHot	\.dw swDropHot\.dw swDropHot\.dw sw10pt\.dw swLeftEject\.dw swSpinner\.dw sw100pt\.dw sw500pt
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
	SW(0,7,1,0)\SW(0,7,1,0)\SW(0,7,1,0)\SW(0,3,1,0)\SW(0,1,1,0)\SW(4,1,1,1)\SW(0,1,1,0)\SW(0,0,1,0)
	SW(0,7,1,0)\SW(0,7,1,0)\SW(0,7,1,0)\SW(0,1,1,0)\SW(4,1,1,1)\SW(0,0,0,0)\SW(0,0,1,0)\SW(0,1,1,0)
	SW(0,7,1,0)\SW(0,7,1,0)\SW(0,1,1,0)\SW(0,7,0,1)\SW(0,0,1,0)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(7,7,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)