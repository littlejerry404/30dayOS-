[FORMAT "WCOFF"]				; 生成目标文件的模式	
[INSTRSET "i486p"]				; 表示想使用到486的指令为止的描述
[BITS 32]						; 生成32位模式用的机器码
[FILE "a_nask.nas"]				; 源文件名信息

		GLOBAL	_api_putchar

[SECTION .text]

_api_putchar:	; void api_putchar(int c);
		MOV		EDX,1
		MOV		AL,[ESP+4]		; c
		INT		0x40
		RET
