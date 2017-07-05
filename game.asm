; Laser Ball solenoids
#DEFINE KICKOUT 		01
#DEFINE LEFT_KICKER 	02
#DEFINE DROP_LA			03
#DEFINE DROP_SER		04
#DEFINE EJECT_HOLE		05
#DEFINE DROP_BA			06
#DEFINE DROP_LL			07
#DEFINE RIGHT_KICKER	08
#DEFINE SOUND1			09 ; thru 13
#DEFINE KNOCKER			14
#DEFINE	FLASHERS		15
#DEFINE COIN_LOCKOUT	16

#DEFINE done jmp afterQueueEvent
#DEFINE noValidate ldaA #10b\ oraA state\ staA state
; switch callbacks:

none:	.org $7E00 + 256 ; size of callback table
	done
	
startGame:
	ldaA ~10000000b
	andA lr(6)
	staA lr(6)
	enablePf
	
	fireSolenoid(2)
	fireSolenoid(3)
	
	; clear lights
	ldX	#lampRow1
	ldaA	#0b
lClearLights:
	staA	0, X
	staA	flashLampRow1 - lampRow1, X
	inX
	cpX	#lampRow8 + 1
	bne	lClearLights
	
	jsr 	resetScores
	
	
	ldaA	#1
	staA	ballCount

	ldX	curPlayer
	
	; invalid playfield
	ldaA	#10000000b ; player up lights
	oraA	flashLampRow1, X
	staA	flashLampRow1, X
	oraA	lampRow1, X
	staA	lampRow1, X
	
	ldaA	#01000000b ; player count light
	oraA	lr(2)
	staA	lr(2)
	
	ldaA	#01000000b ; check outhole
	bitA	switchRow1
	ifne ; ball in hole
		fireSolenoid(5)
	endif
	
	rts
	
	

sw32:
	done
	
addP2_10:
	;ldX		#pB_10
	;ldaA	#9
	;jmp 	addScore
	delay(1000)
	addScore(1,9)
	done
	
swTilt: noValidate
	ldaA	#1000000b ; tilt
	oraA	lampRow1 + 4
	staA	lampRow1 + 4
	disablePf
	done
	
swStart: noValidate
	ldaA #10000000b
	bitA lr(6)
	ifne ; in game over
		jsr startGame
	else 
		ldaA	#1
		cmpA	ballCount
		ifeq ; add player
			ldaA	#01000000b ; player count light
			bitA	lr(3)
			ifne
				oraA	lr(3)
				staA	lr(3)
				bra	playerAdded
			endif
			bitA	lr(4)
			ifne
				oraA	lr(4)
				staA	lr(4)
				bra	playerAdded
			endif
			oraA	lr(4)
			staA	lr(4)
playerAdded:
		else ; restart game
			jsr startGame
		endif		
	endif
	
	done
	
swOuthole: noValidate
	ldaA	#10000000b ; !game over
	bitA	lr(6)
	ifeq ; !game over
		ldX	curPlayer
		ldaA	#10000000b ; player up lights
		bitA	flashLampRow1, X
		ifeq ; playfield invalid
			ldaA	#01111111b 	; turn off tilt
			andA	lampRow1 + 4
			staA	lampRow1 + 4
			
			enablePf
			
			fireSolenoid(5)
		else
			; turn off that player light
			comA
			andA	lampRow1, X
			staA	lampRow1, X
			
			; go to next player
			inX
			ldaB	#01000000b ; player count
			bitB	1, X
			ifeq	; was last player
				ldX	#0
				inc ballCount
				ldaB	#4
				cmpB	ballCount
				ifeq ; game over
					ldaA	#10000000b
					andA	lr(6)
					staA	lr(6)
					disablePf
					done
				endif					
			endif
			
			; player up
			comA
			oraA	lampRow1, X
			staA	lampRow1, X
			oraA	flashLampRow1, X
			staA	flashLampRow1, X
			
			enablePf
			
			fireSolenoid(5)
		endif
	endif		
	done
	
swEjectHole:
	fireSolenoid(EJECT_HOLE)
	done
	
swLeftEject:
	fireSolenoid(4)
	done
	
swTopEject:
	fireSolenoid(1)
	done
	
swRKicker:
	fireSolenoid(RIGHT_KICKER)
	done
	
; end callbacks
	.msfirst
callbackTable: 	.org $7E00 ; note: TRANSPOSED
	.dw swTilt		\.dw swTilt		\.dw swStart	\.dw none\.dw none\.dw none\.dw swTilt\.dw none
	.dw swOuthole	\.dw swTilt	\.dw sw32		\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none		\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none		\.dw none\.dw none\.dw addP2_10\.dw none\.dw none\.dw none\.dw swEjectHole
	.dw none		\.dw none\.dw none\.dw swLeftEject\.dw none\.dw none\.dw none\.dw none
	.dw swRKicker	\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none		\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none		\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
; on = how many cycles it must be on for before registering (1 cycle = 64ms (?)) (max 7)
; off = how many cycles it must be off for
; onOnly = if true, don't notify of an off event (also set off = 0 for efficiency)
; gameover = whether the switch is active in gameover or tilt mode (these callbacks must check whether in game over when triggered if they want to act different)
#define SW(on,off,onOnly,gameover) .db (onOnly<<7)|(gameover<<6)|(on<<3)|(off) 
settleTable: ; must be right after callbackTable
	SW(0,7,1,0)\SW(0,7,1,0)\SW(1,2,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,1,0)\SW(0,7,0,1)
	SW(7,7,1,1)\SW(0,7,1,0)\SW(7,0,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(7,7,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(7,7,1,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(7,7,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)