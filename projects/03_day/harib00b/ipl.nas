; haribote-ipl
; TAB=4

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

		MOV		SI,0			; 计算失败次数的寄存器
retry:
		MOV		AH,0x02			; AH=0x02 : 读取磁盘
		MOV		AL,1			; 1个扇区
		MOV		BX,0
		MOV		DL,0x00			; A驱动器
		INT		0x13			; 调用磁盘BIOS
		JNC		fin				; 如果没有发生错误，就跳转到fin
		ADD		SI,1			; 给SI加1
		CMP		SI,5			; 比较SI和5
		JAE		error			; 如果SI >= 5，就跳转到error
		MOV		AH,0x00
		MOV		DL,0x00			; A驱动器
		INT		0x13			; 驱动器的复位
		JMP		retry

; 读取结束后暂时没有要做的事情，所以休眠

fin:
		HLT						; 让CPU停止，直到有事件发生
		JMP		fin				; 无限循环

error:
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
msg:
		DB		0x0a, 0x0a		; 两个换行
		DB		"load error"
		DB		0x0a			; 换行
		DB		0

		RESB	0x7dfe-$		; 用0x00填充到0x7dfe为止的指令

		DB		0x55, 0xaa
