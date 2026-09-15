/* 中断相关 */

#include "bootpack.h"

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
