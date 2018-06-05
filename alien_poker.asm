; solenoids
#DEFINE SOL(n,t)	(n<<8)|t
#DEFINE OUTHOLE 	SOL(01, 20)
#DEFINE LEFT_EJECT	SOL(02, 24)
#DEFINE RIGHT_EJECT	SOL(03, 24)
#DEFINE DROP_1		SOL(04, 24)
#DEFINE DROP_2		SOL(05, 24)
#DEFINE DROP_3		SOL(06, 24)
#DEFINE DROP_4		SOL(07, 24)
#DEFINE DROP_5		SOL(08, 24)
#DEFINE SOUND_1		SOL(09, 08)
#DEFINE SOUND_2		SOL(10, 08)
#DEFINE SOUND_3		SOL(11, 08)
#DEFINE SOUND_4		SOL(12, 08)
#DEFINE SOUND_5		SOL(13, 08)
#DEFINE	KNOCKER		SOL(14, 50)
#DEFINE TOP_EJECT	SOL(15, 24)

clearDrops:
	ldaA	~00001000b
	andA	>solenoidAC
	staA	solenoidAC
	delay(20)
	ldaA	00001000b
	oraA	>solenoidAC
	staA	solenoidAC
	
_addScore10N:
	jsr setXToCurPlayer10
	tBA
	jsr _addScoreI
	rts
_addScore100N:
	jsr setXToCurPlayer10
	deX
	tBA
	jsr _addScoreI	
	rts
_addScore1000N:
	jsr setXToCurPlayer10
	deX
	deX
	tBA
	jsr _addScoreI
	rts
; ABX
#DEFINE score10x(x) ldaB x\ jsr _addScore10N
#DEFINE score100x(x) ldaB x\ jsr _addScore100N
#DEFINE score1000x(x) ldaB x\ jsr _addScore1000N

#DEFINE advBonus()	jsr advanceBonus


p_Bonus:		.equ RAM + $B0

advanceBonus:
	;ldaA	1000b
	;bitA	>state
	;ifne
	;	rts
	;endif
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
	
; note bonus displayed is double what is in memory
; A
bonusLights:
	ldaA	11111000b
	andA	>lc(5)
	staA	lc(5)
	clr	lc(6)
	tst	>p_Bonus
	beq	bonusLights_done
	
	ldaA	10
	subA	>p_Bonus




	lampOn(8,5) ; 1k

	; turn on 20k,10k,1k if necessary
	ldaA	19
	cmpA	>p_Bonus
	ifge	
		ldaA	9
		cmpA	>p_Bonus
		ifge	; bonus < 10
			ldaA	0
		else	; bonus >= 10?
			lampOn(6,5) ; 10k light
			ldaA	10
		endif
	else	; bonus >= 20?
		lampOn(6,5) ; 10k light
		lampOn(7,5) ; 20k light
		ldaA	20
	endif
	cmpA	>p_Bonus
	ifge
	else
		lampOn(8,5) ; 1k
	endif
	
	ldaA	>p_Bonus
bonusLights_loop:
	decA
	beq 	bonusLights_done
	seC
	rol	lc(6)
	ifcs ; 9k already lit, reset 2-9 lights
		clr	lc(6)
		decA 		; skip next '1'
	endif
	bra	bonusLights_loop
	
bonusLights_done	
	rts
	
	
startBall:
	ldX	>curPlayer
	ldaA	1
	staA	p_Bonus
	lampOn(8,5)	; 1k bonus
	enablePf
	
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
	;
	
	; init lights for player data
	ldX	>curPlayer
		
	; flash player light
	ldaA	00001111b ; player up lights
	oraA	>flc(8)
	staA	flc(8)
	
	ldaA	sr(1) ; check outhole
	bitA	>sc(2)
	;ifne ; ball in hole
		fireSolenoid(OUTHOLE)
	;endif
	
	rts
	
	
startGame:
	lampOn(2,7) ; one player
	
	lampOff(6,8) ; game over
	
	; reset scores
	jsr 	resetScores
	
	; reset ball count
	ldaA	$10 ; ball 1
	staA	ballCount	

	ldaB	0
	staB	curPlayer + 1
	
	; reset backglass lights
	clr	lc(7)
	clr	lc(8)
	clr	flc(7)
	clr	flc(8)
	
	ldX	0
lInitPlayers:
	; stuff
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
		ifeq ; add player if ball 1
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
	inc	$C0
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
	ldaA	lr(1) ; shoot again
	bitA	>lc(1)
	ifne	; shoot again on
		bitA	>flc(1)
		ifne ; shoot again flashing
			; turn off used special
			ldaA	lr(3) ; right special
			bitA	>lc(1)
			ifne
				lampOff(3,1)
				flashOff(1,3)
			endif
			ldaA	lr(2) ; left special
			bitA	>lc(1)
			ifne
				lampOff(2,1)
				flashOff(2,1)
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
		lampOff(5,8) ; tilt
		
		enablePf
		fireSolenoid(OUTHOLE)
	else ; none flashing -> playfield valid -> end ball			
swOuthole_bonusLoop:
		score1000x(2)
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
	
sw10pt:
	score10x(1)
	done(1)

swDrop1:
	done(1)
swDrop2:
	done(1)
swDrop3:
	done(1)
swDrop4:
	done(1)
swDrop5:
	done(1)
swLeftOutlane:
	done(1)
swRightOutlane:
	done(1)
swLeftEject:
	done(1)
swRightEject:
	done(1)
swTopEject:
	done(1)
swLeftInlane:
	done(1)
swLLJoker:
	done(1)
swMLJoker:
	done(1)
swULJoker:
	done(1)
swRJoker:
	done(1)
swSpinner:
	done(1)
swLane1:
	done(1)
swLane2:
	done(1)
swLane3:
	done(1)
swLane4:
	done(1)
swPop1:
	done(1)
swPop2:
	done(1)
swPop3:
	done(1)
swPop4:
	done(1)
swLaneChange:
	done(1)


; end callbacks
	.msfirst
; needs to be on $**00 address
callbackTable: 	.org $6000 ; note: TRANSPOSED
	.dw swTilt	\.dw swTilt\.dw swStart	\.dw none\.dw none\.dw none\.dw swTilt\.dw none
	.dw swOuthole	\.dw swDrop5\.dw swLeftOutlane\.dw swLeftInlane\.dw sw10pt\.dw swLLJoker\.dw swLeftEject\.dw swMLJoker
	.dw swSpinner	\.dw swDrop4\.dw sw10pt\.dw swULJoker\.dw sw10pt\.dw swRightEject\.dw swLane1\.dw swLane2
	.dw swLane3	\.dw swDrop3\.dw swLane4\.dw sw10pt\.dw swTopEject\.dw swRJoker\.dw swTilt\.dw swRightOutlane
	.dw sw10pt	\.dw swDrop2\.dw swPop2\.dw swPop1\.dw swPop4\.dw swPop3\.dw sw10pt\.dw sw10pt
	.dw sw10pt	\.dw swDrop1\.dw swLaneChange\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none	\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none	\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
; on = how many cycles it must be on for before registering (1 cycle = 64ms (?)) (max 7)
; off = how many cycles it must be off for
; onOnly = if true, don't notify of an off event (also set off = 0 for efficiency)
; gameover = whether the switch is active in gameover + tilt mode (these callbacks must check whether in game over when triggered if they want to act different)
; TRANSPOSED (?)
#define SW(on,off,onOnly,gameover) .db (onOnly<<7)|(gameover<<6)|(on<<3)|(off) 
#define LANE 	SW(0,3,1,0)
#define HOLE 	SW(5,7,1,1)
#define TEN  	SW(0,3,1,0)
#define TARGET	SW(0,5,1,0)
#define DROP	SW(0,3,1,0)
#DEFINE POP	SW(0,1,1,0)
settleTable: ; must be right after callbackTable
	SW(0,7,1,0)\SW(0,7,1,0)\SW(0,2,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,1,0)\SW(0,7,0,1)
	SW(7,1,1,1)\DROP\LANE\LANE\TEN\TARGET\HOLE\TARGET
	SW(0,0,1,0)\DROP\TEN\TARGET\TEN\HOLE\LANE\LANE
	LANE\DROP\LANE\TEN\HOLE\TARGET\SW(0,7,1,0)\LANE
	TEN\DROP\POP\POP\POP\POP\TEN\TEN
	TEN\DROP\SW(0,2,1,0)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)