void api_putchar(int c);
void api_end(void);

void HariMain(void)
{
	char a[100];
	a[10] = 'A';		/* 这个当然可以 */
	api_putchar(a[10]);
	a[102] = 'B';		/* 这可不妙啊 */
	api_putchar(a[102]);
	a[123] = 'C';		/* 这也不妙啊 */
	api_putchar(a[123]);
	api_end();
}
