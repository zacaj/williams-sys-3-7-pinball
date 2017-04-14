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

; switch callbacks:

none:	.org $7D00 + 256
	rts
sw32:
	rts
	
addP2_10:
	;ldX		#pB_10
	;ldaA	#9
	;jmp 	addScore
	addScore_T(1,9)
	
swStart:
	ldaA 1000b
	oraA state
	
	ldaA 	#00001000b ; enable kickers 	
	oraA 	solenoidBC
	rts
	
swOuthole:
	fireSolenoid(KICKOUT)
	rts
	
swEjectHole:
	fireSolenoid(EJECT_HOLE)
	rts
	
swRKicker:
	fireSolenoid(RIGHT_KICKER)
	rts
	
; end callbacks
	.msfirst
callbackTable: 	.org $7D00 ; note: TRANSPOSED
	.dw none		\.dw none		\.dw swStart	\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw swOuthole	\.dw addP2_10	\.dw sw32		\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none		\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none		\.dw none\.dw none\.dw addP2_10\.dw none\.dw none\.dw none\.dw swEjectHole
	.dw none		\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw swRKicker	\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none		\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none		\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
; on = how many cycles it must be on for before registering (1 cycle = 16ms (?)) (max 7)
; off = how many cycles it must be off for
; onOnly = if true, don't notify of an off event (also set off = 0 for efficiency)
; gameover = whether the switch is active in gameover mode (these callbacks must check whether in game over when triggered)
#define SW(on,off,onOnly,gameover) .db (onOnly<<7)|(gameover<<6)|(on<<3)|(off) 
settleTable: ; must be right after callbackTable
	SW(0,7,0,1)\SW(0,7,0,1)\SW(4,7,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(7,7,1,1)\SW(0,0,1,1)\SW(7,0,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(7,7,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(7,7,1,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(7,7,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)