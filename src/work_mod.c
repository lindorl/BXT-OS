#include "put_fun.h"
#include "comment_def.h"

#define IP_CHAR		0x0e

int work_main(int start_mm_pos)
{
	SPACEMM *space_start = (SPACEMM *)start_mm_pos;
	
	//找到给结构对应内存位置
	KEYBUF *keybuf = (KEYBUF *)(space_start -> char_driver);
	MEMORYCTRL *memctrl = (MEMORYCTRL *)(space_start -> mm);
	TIMER	*timer = (TIMER *)(space_start -> block_driver);
	
	for(;;)
	{
		asm volatile("cli");
		
		if(0 == keybuf -> use && 0 != timer -> time_view)
		{
			asm volatile("sti\n\t"
						 "hlt");
		}
		else
		{
			if(0 != keybuf -> use)
			{
				put_char(20,(keybuf -> position) + 1,IP_CHAR,7);
				put_char(20,keybuf -> position,keybuf -> vktochar[keybuf -> data],9);
				keybuf -> position ++; //调整下次显示字符的位置
				keybuf -> use = 0;
			}
			else if(0 == timer -> time_view)
			{
				timer -> time_s = (timer -> time_10mm / 100) % 60;
				timer -> time_m = (timer -> time_10mm / 100 / 60) % 60;
				timer -> time_h = (timer -> time_10mm / 100 / 60 / 60) % 24;

				//秒位显示
				put_char(1,77,keybuf -> vktochar[1 + (timer -> time_s) % 10],8);
				put_char(1,76,keybuf -> vktochar[1 + (timer -> time_s) / 10],8);
				//分位显示
				put_char(1,74,keybuf -> vktochar[1 + (timer -> time_m) % 10],8);
				put_char(1,73,keybuf -> vktochar[1 + (timer -> time_m) / 10],8);
				//时位显示
				put_char(1,71,keybuf -> vktochar[1 + (timer -> time_h) % 10],8);
				put_char(1,70,keybuf -> vktochar[1 + (timer -> time_h) / 10],8);
			}
			
			asm volatile("sti");
		}
	}
	return 0;
}
