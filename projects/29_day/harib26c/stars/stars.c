#include "apilib.h"

int rand(void);		/* 生成0～32767范围内的随机数 */

void HariMain(void)
{
	char *buf;
	int win, i, x, y;
	api_initmalloc();
	buf = api_malloc(150 * 100);
	win = api_openwin(buf, 150, 100, -1, "stars");
	api_boxfilwin(win,  6, 26, 143, 93, 0 /* 黑 */);
	for (i = 0; i < 50; i++) {
		x = (rand() % 137) +  6;
		y = (rand() %  67) + 26;
		api_point(win, x, y, 3 /* 黄 */);
	}
	for (;;) {
		if (api_getkey(1) == 0x0a) {
			break; /* 如果是Enter就break; */
		}
	}
	api_end();
}
