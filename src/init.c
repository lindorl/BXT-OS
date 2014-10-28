#include "init.h"
#include "put_fun.h"

void init_main()	// init_main
{	
	char str_title[] = "Title: Welcome to my system world, BXT-OS !";
	char str_link[] = "Power by http://lioulun.howbbs.com";
	char str_qqnum[] = "QQ:313504382";
	char str_usr[] = "<BXT-OS:Lioulun>#";
	char str_author[] = "Author: Lindor.L";
	
	put_char(24, 80, ' ', 0);//隐藏原始光标
	put_string(1, 2, str_title, sizeof(str_title), 6);
	put_string(2, 2, str_link, sizeof(str_link), 8);
	put_string(3, 2, str_qqnum, sizeof(str_qqnum), 8);
	put_string(20, 2, str_usr, sizeof(str_usr), 6);
	put_char(20, 19, IP_CHAR, 8);
	put_char(1, 75, ':', 8);
	put_char(1, 72, ':', 8);
	put_string(23, 62, str_author, sizeof(str_author), 8);
	
	space_main(0x180000);
	work_main(0x180000);
	
	for(;;)
	{
		asm volatile("hlt");
	}
	
	return ;
}

