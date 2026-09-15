void io_hlt(void);
void io_cli(void);
void io_out8(int port, int data);
int io_load_eflags(void);
void io_store_eflags(int eflags);

/* 其实即使写在同一个源文件里，如果在定义之前使用的话，
	果然还是必须预先声明。 */

void init_palette(void);
void set_palette(int start, int end, unsigned char *rgb);

void HariMain(void)
{
	int i; /* 变量声明。变量i是32位整数型 */
	char *p; /* 变量p是BYTE [...]用的地址 */

	init_palette(); /* 设置调色板 */

	p = (char *) 0xa0000; /* 赋值地址 */

	for (i = 0; i <= 0xffff; i++) {
		p[i] = i & 0x0f;
	}

	for (;;) {
		io_hlt();
	}
}

void init_palette(void)
{
	static unsigned char table_rgb[16 * 3] = {
		0x00, 0x00, 0x00,	/*  0:黑 */
		0xff, 0x00, 0x00,	/*  1:明亮的红色 */
		0x00, 0xff, 0x00,	/*  2:明亮的绿色 */
		0xff, 0xff, 0x00,	/*  3:明亮的黄色 */
		0x00, 0x00, 0xff,	/*  4:明亮的蓝色 */
		0xff, 0x00, 0xff,	/*  5:明亮的紫色 */
		0x00, 0xff, 0xff,	/*  6:明亮的浅蓝色 */
		0xff, 0xff, 0xff,	/*  7:白 */
		0xc6, 0xc6, 0xc6,	/*  8:明亮的灰色 */
		0x84, 0x00, 0x00,	/*  9:暗红色 */
		0x00, 0x84, 0x00,	/* 10:暗绿色 */
		0x84, 0x84, 0x00,	/* 11:暗黄色 */
		0x00, 0x00, 0x84,	/* 12:暗蓝色 */
		0x84, 0x00, 0x84,	/* 13:暗紫色 */
		0x00, 0x84, 0x84,	/* 14:暗浅蓝色 */
		0x84, 0x84, 0x84	/* 15:暗灰色 */
	};
	set_palette(0, 15, table_rgb);
	return;

	/* static char 指令虽然只能用于数据，但相当于DB指令 */
}

void set_palette(int start, int end, unsigned char *rgb)
{
	int i, eflags;
	eflags = io_load_eflags();	/* 记录中断许可标志的值 */
	io_cli(); 					/* 把许可标志设为0，禁止中断 */
	io_out8(0x03c8, start);
	for (i = start; i <= end; i++) {
		io_out8(0x03c9, rgb[0] / 4);
		io_out8(0x03c9, rgb[1] / 4);
		io_out8(0x03c9, rgb[2] / 4);
		rgb += 3;
	}
	io_store_eflags(eflags);	/* 把中断许可标志恢复原状 */
	return;
}
