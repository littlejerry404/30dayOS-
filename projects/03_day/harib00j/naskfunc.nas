; naskfunc
; TAB=4

[FORMAT "WCOFF"]				; 生成目标文件的模式	
[BITS 32]						; 生成32位模式用的机器码


; 用于目标文件的信息

[FILE "naskfunc.nas"]			; 源文件名信息

		GLOBAL	_io_hlt			; 这个程序包含的函数名


; 下面是实际的函数

[SECTION .text]		; 在目标文件中先写这个，再写程序

_io_hlt:	; void io_hlt(void);
		HLT
		RET
