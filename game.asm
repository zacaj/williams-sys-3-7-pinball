
none:	.org $7D00 + 256
	rts
sw32:
	rts
	
addP2_10:
	ldX		#pB_10
	ldaA	#9
	jmp 	addScore
	
	.msfirst
callbackTable: 	.org $7D00 ; note: TRANSPOSED
	.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none\.dw addP2_10\.dw sw32\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none\.dw none\.dw none\.dw addP2_10\.dw none\.dw none\.dw none\.dw none
	.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
	.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none\.dw none
; on = how many cycles it must be on for before registering (1 cycle = 16ms (?)) (max 7)
; off = how many cycles it must be off for
; onOnly = if true, don't notify of an off event (also set off = 0 for efficiency)
; gameover = whether the switch is active in gameover mode (these callbacks must check whether in game over when triggered)
#define SW(on,off,onOnly,gameover) .db (onOnly<<7)|(gameover<<6)|(on<<3)|(off) 
settleTable: ; must be right after callbackTable
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,0,1,1)\SW(7,0,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(7,7,1,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)
	SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)\SW(0,7,0,1)