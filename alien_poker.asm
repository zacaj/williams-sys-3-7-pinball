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

; A
clearDrops:
	ldaA	~00001000b
	andA	>solenoidAC
	staA	solenoidAC
	delay(20)
	ldaA	00001000b
	oraA	>solenoidAC
	staA	solenoidAC
	rts
	
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
; AX
#DEFINE score10x(x) ldaA x\ jsr _addScore10N
#DEFINE score100x(x) ldaA x\ jsr _addScore100N
#DEFINE score1000x(x) ldaA x\ jsr _addScore1000N
#DEFINE score10kx(x) ldaA x\ jsr _addScore10kN

#DEFINE advBonus()	jsr advanceBonus


p_Bonus:	.equ RAM + $B0
dropsDown:	.equ RAM + $B1 ; XXXXX000, where X is 1 if that drop is down
p_drops:	.equ RAM + $B4 ; - 7  col 3
p_kings:	.equ RAM + $B8 ; + 3 col 2+4 upper half
p_curDrop:	.equ RAM + $BC ; + 3 bit for the current drop, correspond to lamps in col 3

; trashes B?
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

; resets bank with all drops below flashing down
resetDrops:
	jsr	clearDrops

	ldaA	11111000b
	staA	dropsDown

	ldaA	111b
	ldaB	> flc(3)
	bitB	1000b
	bne 	startGame_drop1
	bitB	10000b
	bne	startGame_drop2
	bitB	100000b
	bne	startGame_drop3
	bitB	1000000b
	bne	startGame_drop4
	bra	startGame_drop5
startGame_drop1:
	fireSolenoid(DROP_1)
	oraA	00001000b
startGame_drop2:
	fireSolenoid(DROP_2)
	oraA	00010000b
startGame_drop3:
	fireSolenoid(DROP_3)
	oraA	00100000b
startGame_drop4:
	fireSolenoid(DROP_4)
	oraA	01000000b
startGame_drop5:
	fireSolenoid(DROP_5)
	oraA	10000000b
	tAB
	delay(50)
	comB
	staB	dropsDown

	rts

startBall:
	ldX	>curPlayer
	ldaA	1
	staA	p_Bonus
	lampOn(8,5)	; 1k bonus
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
	;
	
	; init lights for player data
	ldX	>curPlayer
	ldaA	p_drops, X
	staA	lc(3)
	ldaA	p_kings, X
	staA	lc(2)
	staA	lc(4)
	ldaA	p_curDrop, X
	staA	flc(3)


	jsr	resetDrops
		
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
	
	; reset scores
	jsr 	resetScores

	SOUND(S_ALIEN_POKER)
	
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
	ldaA	11111000b ; cards on, x off
	staA	p_drops, X
	clr	p_kings, X
	ldaA	00001000b ; drop 1/ 10 card
	staA	p_curDrop, X
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
		clr 	bonusTimer
	
		done(0)
	endif

	; none flashing -> playfield valid -> end ball
	ldaB	>p_Bonus			
swOuthole_bonusLoop:
	score1000x(2)
	dec	p_Bonus
	jsr	bonusLights
	delay(25)
	ldaA	>lc(2)
	bitA	1000b
	ifeq
		delay(25)
	endif
	ldaA	>lc(2)
	bitA	100b
	ifeq
		delay(25)
	endif
	ldaA	>lc(2)
	bitA	10b
	ifeq
		delay(25)
	endif
	ldaA	>lc(2)
	bitA	1b
	ifeq
		delay(25)
	endif

	tst	>p_Bonus
	bne	swOuthole_bonusLoop
	ldaA	>lc(2) ; 2x light
	andA	1111b ; multipliers
	ifne
		asrA ; lower mult
		oraA	11110000b ; kings
		andA	>lc(2)
		staA	lc(2)
		staB	p_Bonus
		bra	swOuthole_bonusLoop
	endif
	; end loop

	ldaA	00001111b ; player up lights
	andA	>lc(8) ; remove non-player up lights from col 8 for processing
	ldaB	>lc(3) ; check shoot again light
	bitB	lr(1)
	ifeq ; shoot again not lit
		; store player's data
		ldX	>curPlayer
		ldaA	>lc(3)
		staA	p_drops, X
		ldaA	>lc(2)
		andA	11110000b ; kings
		staA	p_kings, X
		ldaA	>flc(3)
		staA	p_curDrop, X
		
	
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
	
	clr 	bonusTimer
	
	done(0)
	
sw10pt:
	score10x(1)
	SOUND($10)
	done(1)

swDrop1:
	ldaA	1000b
	jmp	swDrop
swDrop2:
	ldaA	10000b
	jmp	swDrop
swDrop3:
	ldaA	100000b
	jmp	swDrop
swDrop4:
	ldaA	1000000b
	jmp	swDrop
swDrop5:
	ldaA	10000000b
	jmp	swDrop
swDrop:
	bitA	>dropsDown
	ifne
		done(0)
	endif
	tAB
	score1000x(1)
	tBA

	bitA	>flc(3)
	ifne	; correct drop
		oraB	>dropsDown
		staB	dropsDown
		lsl	flc(3)
		ifeq	; last drop
			jsr	doDropCollect

			; collect done
			ldaA	1000b ; 10 card
			staA	flc(3)
			ldaA	11111000b
			staA	lc(3)
			jsr	resetDrops
		else 
			SOUND($0C)
		endif
		nop
	else
		; A + B = drop bit

		; turn on drop to reset it
		oraB	>solenoidA
		staB	solenoidA
		tAB
		lampOn(4,3)
		flashLamp(4,3)
		delay(20)
		comB	; invert drop bit to turn it off again
		tBA	; A + B = inverse drop bit

		; turn off drop coil
		andB	>solenoidA
		staB	solenoidA

		; turn off drop light
		andA	>lc(3)
		staA	lc(3)
		SOUND($05)
	endif
				
	done(1)

doDropCollect:
	ldaB	10000000b
	staB	flc(3)
l_swDrop_collect:	
	ldaB	>flc(3)
	bitB	>lc(3)
	ifne
		SOUND($01)
		score10kx(2)
		delay(500)
		ldaA	>lc(3)
		bitA	1b ; 2x
		beq	swDrop_collect_dropDone
		SOUND($01)
		score10kx(2)
		delay(300)
		ldaA	>lc(3)
		bitA	10b ; 3x
		beq 	swDrop_collect_dropDone
		SOUND($01)
		score10kx(2)
		delay(200)
		ldaA	>lc(3)
		bitA	100b ; 3x
		beq 	swDrop_collect_dropDone
		SOUND($01)
		score10kx(2)
		delay(200)
swDrop_collect_dropDone:
		ldaA	>flc(3)
		comA
		andA	>lc(3)
		staA	lc(3)
	endif
	lsr	flc(3)
	ldaA	11111000b
	bitA	>flc(3)
	bne	l_swDrop_collect
	rts

swLeftOutlane:
	done(1)
swRightOutlane:
	done(1)
swLeftEject:
	ldaA	lr(6) ; game over
	bitA	>lc(8)
	ifne ; in game over
		fireSolenoid(LEFT_EJECT)
		done(0)
	endif

	score1000x(5)

	ldaA	lr(4) ; advance royal flush
	bitA	>lc(4)
	ifne	
		ldaA	lr(4)
swLeftEject_adv_loop:
		bitA	>lc(3)
		ifeq
			oraA	>lc(3)
			staA	lc(3)
			lampOff(4,4)
		else
			aslA
			bne	swLeftEject_adv_loop
		endif
		; end loop
	endif

	ldaA	lr(2) ; ace of spades (left eject)
	bitA	>lc(4)
	ifeq
		lampOn(2,4)
		flashLamp(2,4)
		jsr	checkEjectsComplete
	else
	endif

	delay(200)
	fireSolenoid(LEFT_EJECT)
	fork(500)
	done(1)

	beginFork()
	flashOff(2,4)
	endFork()
swRightEject:
	ldaA	lr(6) ; game over
	bitA	>lc(8)
	ifne ; in game over
		fireSolenoid(RIGHT_EJECT)
		done(0)
	endif

	score1000x(5)

	ldaA	lr(1) ; ace of hearts (right eject)
	bitA	>lc(4)
	ifeq
		lampOn(1,4)
		flashLamp(1,4)
		jsr	checkEjectsComplete
	endif

	delay(200)
	fireSolenoid(RIGHT_EJECT)
	fork(500)
	done(1)

	beginFork()
	flashOff(1,4)
	endFork()
	done(1)
swTopEject:
	ldaA	lr(6) ; game over
	bitA	>lc(8)
	ifne ; in game over
		fireSolenoid(TOP_EJECT)
		done(0)
	endif

	score1000x(5)

	ldaA	lr(3) ; ace of clubs (top eject)
	bitA	>lc(4)
	ifeq
		lampOn(3,4)
		flashLamp(3,4)
		jsr	checkEjectsComplete
	endif

	delay(200)
	fireSolenoid(TOP_EJECT)
	fork(500)
	done(1)

	beginFork()
	flashOff(3,4)
	endFork()
	done(1)
checkEjectsComplete:
	ldaA	>lc(4)
	comA
	bitA	111b ; ace lamps
	ifeq 	; all were lit
		; turn them off
		ldaA	11111000b
		andA	>lc(4)
		staA	lc(4)

		; turn on a special
		ldaA	110b ; special lights
		bitA	>lc(1)
		ifeq	; specials aren't on
			lampOn(2,1) ; left special
			flashLamp(2,1)
			fork(500)
			rts
			nop
			nop
			beginFork()
			flashOff(2,1)
			flashOff(3,1)
			endFork()
		endif
	endif
	rts

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
	SW(7,1,1,1)\DROP\LANE\LANE\TEN\TARGET\HOLE\TARGET
	SW(0,0,1,0)\DROP\TEN\TARGET\TEN\HOLE\LANE\LANE
	LANE\DROP\LANE\TEN\HOLE\TARGET\SW(0,7,1,0)\LANE
	TEN\DROP\POP\POP\POP\POP\TEN\TEN
	TEN\DROP\SW(0,2,1,0)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)