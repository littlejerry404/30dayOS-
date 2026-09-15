/* FIFO库 */

#include "bootpack.h"

#define FLAGS_OVERRUN		0x0001

void fifo8_init(struct FIFO8 *fifo, int size, unsigned char *buf)
/* FIFO缓冲区的初始化 */
{
	fifo->size = size;
	fifo->buf = buf;
	fifo->free = size; /* 空余 */
	fifo->flags = 0;
	fifo->p = 0; /* 写入位置 */
	fifo->q = 0; /* 读取位置 */
	return;
}

int fifo8_put(struct FIFO8 *fifo, unsigned char data)
/* 把数据送入FIFO并存储 */
{
	if (fifo->free == 0) {
		/* 没有空位而溢出了 */
		fifo->flags |= FLAGS_OVERRUN;
		return -1;
	}
	fifo->buf[fifo->p] = data;
	fifo->p++;
	if (fifo->p == fifo->size) {
		fifo->p = 0;
	}
	fifo->free--;
	return 0;
}

int fifo8_get(struct FIFO8 *fifo)
/* 从FIFO取出一个数据 */
{
	int data;
	if (fifo->free == fifo->size) {
		/* 缓冲区为空时，暂时返回-1 */
		return -1;
	}
	data = fifo->buf[fifo->q];
	fifo->q++;
	if (fifo->q == fifo->size) {
		fifo->q = 0;
	}
	fifo->free++;
	return data;
}

int fifo8_status(struct FIFO8 *fifo)
/* 报告积攒了多少数据 */
{
	return fifo->size - fifo->free;
}
