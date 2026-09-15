; haribote-os
; TAB=4

; BOOT_INFO相关
CYLS	EQU		0x0ff0			; 由启动扇区设置
LEDS	EQU		0x0ff1
VMODE	EQU		0x0ff2			; 关于颜色数的信息。是多少位颜色？
SCRNX	EQU		0x0ff4			; 分辨率的X
SCRNY	EQU		0x0ff6			; 分辨率的Y
VRAM	EQU		0x0ff8			; 图形缓冲区的起始地址

		ORG		0xc200			; 这个程序会被加载到哪里

		MOV		AL,0x13			; VGA图形、320x200x8bit颜色
		MOV		AH,0x00
		INT		0x10
		MOV		BYTE [VMODE],8	; 记录画面模式
		MOV		WORD [SCRNX],320
		MOV		WORD [SCRNY],200
		MOV		DWORD [VRAM],0x000a0000

; 向BIOS询问键盘的LED状态

		MOV		AH,0x02
		INT		0x16 			; keyboard BIOS
		MOV		[LEDS],AL

fin:
		HLT
		JMP		fin
