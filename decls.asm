
displayStrobe: 	.equ $2800 ;		CB2=1 special solenoid 6
displayBcd: 	.equ $2802
displayStrobeC:	.equ $2801
displayBcdC:	.equ $2803
lampCol:		.equ $2400 ;		CA2=1 special solenoid 2
lampColC:		.equ $2401 ; 		CB2=1 special solenoid 1
lampStrobe:		.equ $2402
lampStrobeC:	.equ $2403
switchStrobe:	.equ $3002
switchStrobeC:	.equ $3003
switchRow:		.equ $3000 ; 		CB2=1 special solenoid 3
switchRowC:		.equ $3001 ;		CA2=1 special solenoid 4
solenoidA:		.equ $2200 ; todo: 	CB2=1 enable special solenoids, flippers
solenoidAC		.equ $2201 ;      	CA2=1 special solenoid 5
solenoidB:		.equ $2202
solenoidBC:		.equ $2203

RAM:			.equ $0000
cRAM:			.equ $0100
RAMEnd:			.equ $01FF
temp:			.equ RAM + $00 ; 01
counter:		.equ RAM + $02
counter2:		.equ RAM + $03
strobe:			.equ RAM + $07
lampCol1:		.equ RAM + $08
lampCol8:		.equ lampCol1 + 7 
#DEFINE lc(x) 		lampCol1 + (x-1)
#DEFINE lr(x)		((1 << (x-1))
curSwitchRowLsb:	.equ RAM + $10 
; 
curPlayer:		.equ RAM + $12 ; + 0-3
;;;
switchRow1:		.equ RAM + $20
switchRow8:		.equ switchRow1 + 7 
#DEFINE sc(x) 		switchRow1 + x - 1
#DEFINE sr(x)		(1 << (x-1))
solAStatus:		.equ RAM + $28 ; solenoid PIA is updated once every 8 IRQ
solBStatus:		.equ RAM + $29 ; one solenoid bit is generated per IRQ and pushed on
attractX:		.equ RAM + $2A ; +
forkX			.equ RAM + $2C ; +
curCol:			.equ RAM + $50 ; +
tempX:			.equ RAM + $52 ; +
queueHead:		.equ RAM + $54 ; +
queueTail:		.equ RAM + $56 ; +
tempQ:			.equ RAM + $58 ; +
queue:			.equ RAM + $60	; opened | switch? | number#6
queueEnd:		.equ RAM + $6D
;
displayBcd1:	.equ RAM + $70
displayBcd16:	.equ RAM + $7F
ballCount:		.equ displayBcd1 + 7
waitLeft: 		.equ RAM + $80 ; dec every 8ms
waitLeftEnd:		.equ RAM + $87
waitMsb:		.equ RAM + $88 ; -> 8F
waitLsb:		.equ RAM + $90 ; -> 97
waitReg:		.equ RAM + $98 ; -> 9F
flashLampCol1:		.equ RAM + $A0
flashLampCol8:		.equ RAM + $A7
#DEFINE flc(x) 		flashLampCol1 + (x - 1)
lastSwitch:		.equ RAM + $A8
dropResetTimer:		.equ RAM + $A9 ; max 127
dropsDown		.equ RAM + $AA
p_Bonus:		.equ RAM + $B0
p_Ejects:		.equ RAM + $B1 ; -> B4
p_DropsDown:		.equ RAM + $B5
p_LampCol2:		.equ RAM + $B6 ; -> B9
spinnerTimer:		.equ RAM + $BA 

p_BonusLeft:		.equ RAM + $BE
bonusTimer:		.equ RAM + $BF ; counts down from 127 during bonus



settleRow1:		.equ cRAM + $00 ;must be at 0
settleRow8End:		.equ settleRow1+  (8*8)-1
solenoid1:		.equ cRAM + $40		; set to E to turn solenoid on permanently
solenoid8:		.equ solenoid1 + 7	; otherwise (<E), decremented every 8ms till reaches 0
solenoid9:		.equ solenoid1 + 8	; F = solenoid off, otherwise on
solenoid16:		.equ solenoid1 + 15 ; set to pulse time / 8ms to fire solenoid (5-7 reccomended)
#DEFINE s(n) 		(0 + n)
pA_1m:			.equ cRAM + $50	; note reverse order to match displays
pA_10:			.equ pA_1m + 5
pB_1m:			.equ pA_10 + 1
pB_10:			.equ pB_1m + 5
pC_1m:			.equ pB_10 + 1
pC_10:			.equ pC_1m + 5
pD_1m:			.equ pC_10 + 1
pD_10:			.equ pD_1m + 5 
; 
displayCol:		.equ cRAM + $6A
state:			.equ cRAM + $6B	; _ | strobe reset | don't validate | _

instant:		.equ 4
debounce:		.equ 1
slow:			.equ 2

switchSettle:	.equ cRAM + $30
; through $7F ?