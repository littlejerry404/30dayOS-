[INSTRSET "i486p"]
[BITS 32]
		MOV		EAX,1*8			; OS用的段号
		MOV		DS,AX			; 把这个放进DS
		MOV		BYTE [0x102600],0
		RETF
