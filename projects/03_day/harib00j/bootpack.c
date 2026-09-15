/* 告诉C编译器：有其他文件中创建的函数 */

void io_hlt(void);

/* 明明是函数声明，却没有{}直接写;的话，
	就变成“因为在其他文件里，请多关照”的意思。 */

void HariMain(void)
{

fin:
	io_hlt(); /* 这样就执行了naskfunc.nas的_io_hlt */
	goto fin;

}
