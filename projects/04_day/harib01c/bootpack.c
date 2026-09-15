void io_hlt(void);

void HariMain(void)
{
	int i; /* 变量声明。变量i是32位整数型 */
	char *p; /* 变量p是BYTE [...]用的地址 */

	for (i = 0xa0000; i <= 0xaffff; i++) {

		p = i; /* 赋值地址 */
		*p = i & 0x0f;

		/* 这样就可以代替 write_mem8(i, i & 0x0f); */
	}

	for (;;) {
		io_hlt();
	}
}
