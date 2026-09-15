; haribote-os boot asm
; TAB=4

[INSTRSET "i486p"]

VBEMODE	EQU		0x105			; 1024 x 768 x 8bit颜色
; （画面模式一览）
;	0x100 : 640 x 400 x 8bit颜色
;	0x101 : 640 x 480 x 8bit颜色
;	0x103 : 800 x 600 x 8bit颜色
;	0x105 : 1024 x 768 x 8bit颜色
;	0x107 : 1280 x 1024 x 8bit颜色

BOTPAK	EQU		0x00280000		; bootpack的加载目标
DSKCAC	EQU		0x00100000		; 磁盘缓存的位置
DSKCAC0	EQU		0x00008000		; 磁盘缓存的位置（实模式）

; BOOT_INFO相关
CYLS	EQU		0x0ff0			; 由启动扇区设置
LEDS	EQU		0x0ff1
VMODE	EQU		0x0ff2			; 关于颜色数的信息。是多少位颜色？
SCRNX	EQU		0x0ff4			; 分辨率的X
SCRNY	EQU		0x0ff6			; 分辨率的Y
VRAM	EQU		0x0ff8			; 图形缓冲区的起始地址

		ORG		0xc200			; 这个程序会被加载到哪里

; VBE存在确认

		MOV		AX,0x9000
		MOV		ES,AX
		MOV		DI,0
		MOV		AX,0x4f00
		INT		0x10
		CMP		AX,0x004f
		JNE		scrn320

; VBE的版本检查

		MOV		AX,[ES:DI+4]
		CMP		AX,0x0200
		JB		scrn320			; if (AX < 0x0200) goto scrn320

; 获取画面模式信息

		MOV		CX,VBEMODE
		MOV		AX,0x4f01
		INT		0x10
		CMP		AX,0x004f
		JNE		scrn320

; 确认画面模式信息

		CMP		BYTE [ES:DI+0x19],8
		JNE		scrn320
		CMP		BYTE [ES:DI+0x1b],4
		JNE		scrn320
		MOV		AX,[ES:DI+0x00]
		AND		AX,0x0080
		JZ		scrn320			; 因为模式属性的bit7为0，所以放弃

; 画面模式的切换

		MOV		BX,VBEMODE+0x4000
		MOV		AX,0x4f02
		INT		0x10
		MOV		BYTE [VMODE],8	; 记录画面模式（供C语言引用）
		MOV		AX,[ES:DI+0x12]
		MOV		[SCRNX],AX
		MOV		AX,[ES:DI+0x14]
		MOV		[SCRNY],AX
		MOV		EAX,[ES:DI+0x28]
		MOV		[VRAM],EAX
		JMP		keystatus

scrn320:
		MOV		AL,0x13			; VGA图形、320x200x8bit颜色
		MOV		AH,0x00
		INT		0x10
		MOV		BYTE [VMODE],8	; 记录画面模式（供C语言引用）
		MOV		WORD [SCRNX],320
		MOV		WORD [SCRNY],200
		MOV		DWORD [VRAM],0x000a0000

; 向BIOS询问键盘的LED状态

keystatus:
		MOV		AH,0x02
		INT		0x16 			; keyboard BIOS
		MOV		[LEDS],AL

; 让PIC不接受任何中断
;	按照AT兼容机的规格，如果要初始化PIC，
;	这个如果不赶在CLI之前做，有时会挂起
;	PIC的初始化稍后再做

		MOV		AL,0xff
		OUT		0x21,AL
		NOP						; 因为似乎有些机型连续执行OUT指令会出问题
		OUT		0xa1,AL

		CLI						; 进一步在CPU层面也禁止中断

; 为了让CPU能够访问1MB以上的内存，设置A20GATE

		CALL	waitkbdout
		MOV		AL,0xd1
		OUT		0x64,AL
		CALL	waitkbdout
		MOV		AL,0xdf			; enable A20
		OUT		0x60,AL
		CALL	waitkbdout

; 切换到保护模式

		LGDT	[GDTR0]			; 设置临时GDT
		MOV		EAX,CR0
		AND		EAX,0x7fffffff	; 把bit31设为0（为了禁止分页）
		OR		EAX,0x00000001	; 把bit0设为1（为了切换到保护模式）
		MOV		CR0,EAX
		JMP		pipelineflush
pipelineflush:
		MOV		AX,1*8			;  可读写段32bit
		MOV		DS,AX
		MOV		ES,AX
		MOV		FS,AX
		MOV		GS,AX
		MOV		SS,AX

; bootpack的传输

		MOV		ESI,bootpack	; 传输源
		MOV		EDI,BOTPAK		; 传输目标
		MOV		ECX,512*1024/4
		CALL	memcpy

; 顺便把磁盘数据也转移到原本的位置

; 首先从启动扇区开始

		MOV		ESI,0x7c00		; 传输源
		MOV		EDI,DSKCAC		; 传输目标
		MOV		ECX,512/4
		CALL	memcpy

; 剩余全部

		MOV		ESI,DSKCAC0+512	; 传输源
		MOV		EDI,DSKCAC+512	; 传输目标
		MOV		ECX,0
		MOV		CL,BYTE [CYLS]
		IMUL	ECX,512*18*2/4	; 把柱面数换算成字节数/4
		SUB		ECX,512/4		; 扣除IPL的部分
		CALL	memcpy

; 因为asmhead中必须做的事情已经全部做完了，
;	剩下的交给bootpack

; bootpack的启动

		MOV		EBX,BOTPAK
		MOV		ECX,[EBX+16]
		ADD		ECX,3			; ECX += 3;
		SHR		ECX,2			; ECX /= 4;
		JZ		skip			; 没有应该传输的东西
		MOV		ESI,[EBX+20]	; 传输源
		ADD		ESI,EBX
		MOV		EDI,[EBX+12]	; 传输目标
		CALL	memcpy
skip:
		MOV		ESP,[EBX+12]	; 栈初始值
		JMP		DWORD 2*8:0x0000001b

waitkbdout:
		IN		 AL,0x64
		AND		 AL,0x02
		IN		 AL,0x60 		; 读取（为了不让接收缓冲区捣乱）
		JNZ		waitkbdout		; 如果AND的结果不为0，就跳转到waitkbdout
		RET

memcpy:
		MOV		EAX,[ESI]
		ADD		ESI,4
		MOV		[EDI],EAX
		ADD		EDI,4
		SUB		ECX,1
		JNZ		memcpy			; 如果相减结果不为0，就跳转到memcpy
		RET
; memcpy只要不忘记加上地址大小前缀，也可以用字符串指令来写

		ALIGNB	16
GDT0:
		RESB	8				; 空选择器
		DW		0xffff,0x0000,0x9200,0x00cf	; 可读写段32bit
		DW		0xffff,0x0000,0x9a28,0x0047	; 可执行段32bit（bootpack用）

		DW		0
GDTR0:
		DW		8*3-1
		DD		GDT0

		ALIGNB	16
bootpack:
