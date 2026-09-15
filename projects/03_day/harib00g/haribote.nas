; haribote-os
; TAB=4

		ORG		0xc200			; 这个程序会被加载到哪里

		MOV		AL,0x13			; VGA图形、320x200x8bit颜色
		MOV		AH,0x00
		INT		0x10
fin:
		HLT
		JMP		fin
