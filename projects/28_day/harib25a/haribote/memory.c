/* 内存相关 */

#include "bootpack.h"

#define EFLAGS_AC_BIT		0x00040000
#define CR0_CACHE_DISABLE	0x60000000

unsigned int memtest(unsigned int start, unsigned int end)
{
	char flg486 = 0;
	unsigned int eflg, cr0, i;

	/* 确认是386，还是486及以后 */
	eflg = io_load_eflags();
	eflg |= EFLAGS_AC_BIT; /* AC-bit = 1 */
	io_store_eflags(eflg);
	eflg = io_load_eflags();
	if ((eflg & EFLAGS_AC_BIT) != 0) { /* 在386上即使把AC设为1也会自动变回0 */
		flg486 = 1;
	}
	eflg &= ~EFLAGS_AC_BIT; /* AC-bit = 0 */
	io_store_eflags(eflg);

	if (flg486 != 0) {
		cr0 = load_cr0();
		cr0 |= CR0_CACHE_DISABLE; /* 禁止缓存 */
		store_cr0(cr0);
	}

	i = memtest_sub(start, end);

	if (flg486 != 0) {
		cr0 = load_cr0();
		cr0 &= ~CR0_CACHE_DISABLE; /* 允许缓存 */
		store_cr0(cr0);
	}

	return i;
}

void memman_init(struct MEMMAN *man)
{
	man->frees = 0;			/* 空余信息的个数 */
	man->maxfrees = 0;		/* 用于观察情况：frees的最大值 */
	man->lostsize = 0;		/* 释放失败的合计大小 */
	man->losts = 0;			/* 释放失败的次数 */
	return;
}

unsigned int memman_total(struct MEMMAN *man)
/* 报告空余大小的合计 */
{
	unsigned int i, t = 0;
	for (i = 0; i < man->frees; i++) {
		t += man->free[i].size;
	}
	return t;
}

unsigned int memman_alloc(struct MEMMAN *man, unsigned int size)
/* 确保 */
{
	unsigned int i, a;
	for (i = 0; i < man->frees; i++) {
		if (man->free[i].size >= size) {
			/* 发现足够大的空余 */
			a = man->free[i].addr;
			man->free[i].addr += size;
			man->free[i].size -= size;
			if (man->free[i].size == 0) {
				/* 因为free[i]没了，所以向前靠拢 */
				man->frees--;
				for (; i < man->frees; i++) {
					man->free[i] = man->free[i + 1]; /* 结构体的赋值 */
				}
			}
			return a;
		}
	}
	return 0; /* 没有空位 */
}

int memman_free(struct MEMMAN *man, unsigned int addr, unsigned int size)
/* 释放 */
{
	int i, j;
	/* 考虑到整理方便，free[]最好按addr顺序排列 */
	/* 所以首先决定应该放在哪里 */
	for (i = 0; i < man->frees; i++) {
		if (man->free[i].addr > addr) {
			break;
		}
	}
	/* free[i - 1].addr < addr < free[i].addr */
	if (i > 0) {
		/* 前面有 */
		if (man->free[i - 1].addr + man->free[i - 1].size == addr) {
			/* 可以合并到前面的空区域 */
			man->free[i - 1].size += size;
			if (i < man->frees) {
				/* 后面也有 */
				if (addr + size == man->free[i].addr) {
					/* 居然和后面也能合并 */
					man->free[i - 1].size += man->free[i].size;
					/* 删除man->free[i] */
					/* 因为free[i]没了，所以向前靠拢 */
					man->frees--;
					for (; i < man->frees; i++) {
						man->free[i] = man->free[i + 1]; /* 结构体的赋值 */
					}
				}
			}
			return 0; /* 成功结束 */
		}
	}
	/* 没能和前面合并 */
	if (i < man->frees) {
		/* 后面有 */
		if (addr + size == man->free[i].addr) {
			/* 可以和后面合并 */
			man->free[i].addr = addr;
			man->free[i].size += size;
			return 0; /* 成功结束 */
		}
	}
	/* 前面和后面都无法合并 */
	if (man->frees < MEMMAN_FREES) {
		/* 把free[i]后面的部分向后挪，腾出空隙 */
		for (j = man->frees; j > i; j--) {
			man->free[j] = man->free[j - 1];
		}
		man->frees++;
		if (man->maxfrees < man->frees) {
			man->maxfrees = man->frees; /* 更新最大值 */
		}
		man->free[i].addr = addr;
		man->free[i].size = size;
		return 0; /* 成功结束 */
	}
	/* 没能向后挪动 */
	man->losts++;
	man->lostsize += size;
	return -1; /* 失败结束 */
}

unsigned int memman_alloc_4k(struct MEMMAN *man, unsigned int size)
{
	unsigned int a;
	size = (size + 0xfff) & 0xfffff000;
	a = memman_alloc(man, size);
	return a;
}

int memman_free_4k(struct MEMMAN *man, unsigned int addr, unsigned int size)
{
	int i;
	size = (size + 0xfff) & 0xfffff000;
	i = memman_free(man, addr, size);
	return i;
}
