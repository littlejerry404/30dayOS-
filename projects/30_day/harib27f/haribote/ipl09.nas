; haribote-ipl
; TAB=4

CYLS	EQU		9				; 读取到哪里

		ORG		0x7c00			; 这个程序会被加载到哪里

; 以下是标准FAT12格式软盘的相关描述

		JMP		entry
		DB		0x90
		DB		"HARIBOTE"		; 启动扇区的名称可以随意填写（8字节）
		DW		512				; 1个扇区的大小（必须设为512）
		DB		1				; 簇的大小（必须设为1个扇区）
		DW		1				; FAT从哪里开始（通常从第1个扇区开始）
		DB		2				; FAT的个数（必须设为2）
		DW		224				; 根目录区域的大小（通常设为224个目录项）
		DW		2880			; 该驱动器的大小（必须设为2880个扇区）
		DB		0xf0			; 介质类型（必须设为0xf0）
		DW		9				; FAT区域的长度（必须设为9个扇区）
		DW		18				; 每个磁道有多少个扇区（必须设为18）
		DW		2				; 磁头的数量（必须设为2）
		DD		0				; 因为没有使用分区，所以这里必须为0
		DD		2880			; 再写一次该驱动器的大小
		DB		0,0,0x29		; 虽然不太清楚，但保持这个值就行了
		DD		0xffffffff		; 大概是卷序列号
		DB		"HARIBOTEOS "	; 磁盘的名称（11字节）
		DB		"FAT12   "		; 格式的名称（8字节）
		RESB	18				; 先预留18字节

; 程序主体

entry:
		MOV		AX,0			; 寄存器初始化
		MOV		SS,AX
		MOV		SP,0x7c00
		MOV		DS,AX

; 读取磁盘

		MOV		AX,0x0820
		MOV		ES,AX
		MOV		CH,0			; 柱面0
		MOV		DH,0			; 磁头0
		MOV		CL,2			; 扇区2
		MOV		BX,18*2*CYLS-1	; 想要读取的合计扇区数
		CALL	readfast		; 高速读取

; 读取完成，执行haribote.sys！

		MOV		BYTE [0x0ff0],CYLS	; 记录IPL读到了哪里
		JMP		0xc200

error:
		MOV		AX,0
		MOV		ES,AX
		MOV		SI,msg
putloop:
		MOV		AL,[SI]
		ADD		SI,1			; 给SI加1
		CMP		AL,0
		JE		fin
		MOV		AH,0x0e			; 显示单个字符的功能
		MOV		BX,15			; 颜色代码
		INT		0x10			; 调用视频BIOS
		JMP		putloop
fin:
		HLT						; 让CPU停止，直到有事件发生
		JMP		fin				; 无限循环
msg:
		DB		0x0a, 0x0a		; 两个换行
		DB		"load error"
		DB		0x0a			; 换行
		DB		0

readfast:	; 用AL尽量批量读取
;	ES:读取地址, CH:柱面, DH:磁头, CL:扇区, BX:读取扇区数

		MOV		AX,ES			; < 把ES到AL的最大值计算 >
		SHL		AX,3			; 相当于把AX除以32，再把结果放入AH（SHL是左移指令）
		AND		AH,0x7f			; AH是AH除以128的余数（512*128=64K）
		MOV		AL,128			; AL = 128 - AH; 到最近的64KB边界为止最多能容纳多少个扇区
		SUB		AL,AH

		MOV		AH,BL			; < 把BX到AL的最大值计算到AH >
		CMP		BH,0			; if (BH != 0) { AH = 18; }
		JE		.skip1
		MOV		AH,18
.skip1:
		CMP		AL,AH			; if (AL > AH) { AL = AH; }
		JBE		.skip2
		MOV		AL,AH
.skip2:

		MOV		AH,19			; < 把CL到AL的最大值计算到AH >
		SUB		AH,CL			; AH = 19 - CL;
		CMP		AL,AH			; if (AL > AH) { AL = AH; }
		JBE		.skip3
		MOV		AL,AH
.skip3:

		PUSH	BX
		MOV		SI,0			; 计算失败次数的寄存器
retry:
		MOV		AH,0x02			; AH=0x02 : 读取磁盘
		MOV		BX,0
		MOV		DL,0x00			; A驱动器
		PUSH	ES
		PUSH	DX
		PUSH	CX
		PUSH	AX
		INT		0x13			; 调用磁盘BIOS
		JNC		next			; 如果没有发生错误，就跳转到next
		ADD		SI,1			; 给SI加1
		CMP		SI,5			; 比较SI和5
		JAE		error			; 如果SI >= 5，就跳转到error
		MOV		AH,0x00
		MOV		DL,0x00			; A驱动器
		INT		0x13			; 驱动器的复位
		POP		AX
		POP		CX
		POP		DX
		POP		ES
		JMP		retry
next:
		POP		AX
		POP		CX
		POP		DX
		POP		BX				; 用BX接收ES的内容
		SHR		BX,5			; 把BX从16字节单位换算成512字节单位
		MOV		AH,0
		ADD		BX,AX			; BX += AL;
		SHL		BX,5			; 把BX从512字节单位换算成16字节单位
		MOV		ES,BX			; 这样就变成 ES += AL * 0x20;
		POP		BX
		SUB		BX,AX
		JZ		.ret
		ADD		CL,AL			; 把AL加到CL
		CMP		CL,18			; 比较CL和18
		JBE		readfast		; 如果CL <= 18，就跳转到readfast
		MOV		CL,1
		ADD		DH,1
		CMP		DH,2
		JB		readfast		; 如果DH < 2，就跳转到readfast
		MOV		DH,0
		ADD		CH,1
		JMP		readfast
.ret:
		RET

		RESB	0x7dfe-$		; 用0x00填充到0x7dfe为止的指令

		DB		0x55, 0xaa
