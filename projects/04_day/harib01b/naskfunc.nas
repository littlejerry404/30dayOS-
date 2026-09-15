; naskfunc
; TAB=4

[FORMAT "WCOFF"]				; 生成目标文件的模式	
[INSTRSET "i486p"]				; 表示想使用到486的指令为止的描述
[BITS 32]						; 生成32位模式用的机器码
[FILE "naskfunc.nas"]			; 源文件名信息

		GLOBAL	_io_hlt,_write_mem8

[SECTION .text]

_io_hlt:	; void io_hlt(void);
		HLT
		RET

_write_mem8:	; void write_mem8(int addr, int data);
		MOV		ECX,[ESP+4]		; [ESP+4]中存放着addr，所以把它读入ECX
		MOV		AL,[ESP+8]		; [ESP+8]中存放着data，所以把它读入AL
		MOV		[ECX],AL
		RET
