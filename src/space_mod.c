#include "comment_def.h"

int space_main(int start_mm_pos)
{
	SPACEMM *space_start = (SPACEMM *)start_mm_pos;
	int i;
	
	//给结构进行内存分配
	KEYBUF	*keybuf = (KEYBUF *)(space_start -> char_driver);
	MEMORYCTRL	*memctrl = (MEMORYCTRL *)(space_start -> mm);
	TIMER	*timer = (TIMER *)(space_start -> block_driver);
	PROCESS *process = (PROCESS *)(space_start -> process);
	
	//初始化按键缓冲区结构体
	keybuf -> use = 0;
	keybuf -> position = 19;

	//初始化内存管理相关结构体
	memctrl -> mem_base = 0x180000 + 8 * 8 * 1024 + 512;
	for(i = 0;i < 8;i++)
	{
		memctrl -> mem_use[i] = 0;
		memctrl -> mem_offset[i] = memctrl -> mem_base + i * 1024 * 1024;
	}
	
	//初始化时钟结构体
	timer -> time_10mm = 0;
	timer -> time_s = 0;
	timer -> time_m = 0;
	timer -> time_h = 0;
	timer -> time_view = 0;
	
	//初始化“进程表与处理模块”结构体
	process -> change_num = 0;
	
	return 0;
}
