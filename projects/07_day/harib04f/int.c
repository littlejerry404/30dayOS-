/* 中断相关 */

#include "bootpack.h"
#include <stdio.h>

void init_pic(void)
/* PIC的初始化 */
{
	io_out8(PIC0_IMR,  0xff  ); /* 不接受所有中断 */
	io_out8(PIC1_IMR,  0xff  ); /* 不接受所有中断 */

	io_out8(PIC0_ICW1, 0x11  ); /* 边沿触发模式 */
	io_out8(PIC0_ICW2, 0x20  ); /* IRQ0-7用INT20-27来接收 */
	io_out8(PIC0_ICW3, 1 << 2); /* PIC1通过IRQ2连接 */
	io_out8(PIC0_ICW4, 0x01  ); /* 无缓冲模式 */

	io_out8(PIC1_ICW1, 0x11  ); /* 边沿触发模式 */
	io_out8(PIC1_ICW2, 0x28  ); /* IRQ8-15用INT28-2f来接收 */
	io_out8(PIC1_ICW3, 2     ); /* PIC1通过IRQ2连接 */
	io_out8(PIC1_ICW4, 0x01  ); /* 无缓冲模式 */

	io_out8(PIC0_IMR,  0xfb  ); /* 11111011 除PIC1以外全部禁止 */
	io_out8(PIC1_IMR,  0xff  ); /* 11111111 不接受任何中断 */

	return;
}

#define PORT_KEYDAT		0x0060

struct FIFO8 keyfifo;

void inthandler21(int *esp)
{
	unsigned char data;
	io_out8(PIC0_OCW2, 0x61);	/* 向PIC通知IRQ-01接收完成 */
	data = io_in8(PORT_KEYDAT);
	fifo8_put(&keyfifo, data);
	return;
}

void inthandler2c(int *esp)
/* 来自PS/2鼠标的中断 */
{
	struct BOOTINFO *binfo = (struct BOOTINFO *) ADR_BOOTINFO;
	boxfill8(binfo->vram, binfo->scrnx, COL8_000000, 0, 0, 32 * 8 - 1, 15);
	putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, "INT 2C (IRQ-12) : PS/2 mouse");
	for (;;) {
		io_hlt();
	}
}

void inthandler27(int *esp)
/* 对PIC0不完全中断的对策 */
/* 在Athlon64X2等机器上，由于芯片组的原因，这个中断会在PIC初始化时发生一次 */
/* 这个中断处理函数对该中断什么都不做，直接放过 */
/* 为什么什么都不用做？
	→  这个中断是由于PIC初始化时的电气噪声而产生的，所以
		没有必要认真地做什么处理。									*/
{
	io_out8(PIC0_OCW2, 0x67); /* 向PIC通知IRQ-07接收完成 */
	return;
}
