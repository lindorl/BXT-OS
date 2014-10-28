
void put_char(int h,int l,char cz,char color)
{

	int i;
	char *p;
	
	i = 0xB8000 + (80 * h + l) * 2;
	p = (char *)i;
	
	*p = cz;
	*(p + 1) = color;
	
}
void put_string(int h,int l,char *str,int size,char color)
{
	int i;

	for(i = 0; i < size; i++)
	{
		put_char(h,l + i,str[i],color);
	}
}