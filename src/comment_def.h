#define	MOD_UNIT	8 * 1024

typedef struct
{
	char char_driver[MOD_UNIT];//字符驱动
	char mm[MOD_UNIT];//内存管理
	char block_driver[MOD_UNIT];//块驱动
	char process[MOD_UNIT];//进程处理
	char fs[MOD_UNIT];//文件系统
	char include[MOD_UNIT];//头文件
	char lib[MOD_UNIT];//链接库
	char math[MOD_UNIT];//数学协处理
}SPACEMM;//SPACE总空间结构,大小64kb

typedef struct
{
	char use;//是否需要将缓冲区字符打印
	char data;//字符缓冲区
	char position;//字符显示位置
	char vktochar[0x7f];//键盘扫描码与字符的对应
}KEYBUF;//键盘缓存相关结构

typedef struct
{
	int mem_size;//通过bios得到的内存大小
	int mem_base;//自由内存起始位置
	int mem_use[8];//内存是否被使用的标识
	int mem_offset[8];//偏移量
}MEMORYCTRL;//内存管理相关结构

typedef struct
{
	int  time_10mm;//以10mm记录的总时间的存储区
	char time_s;//秒存储器
	char time_m;//分存储器
	char time_h;//时存储器
	char time_view;//判断是否应该被处理，当其为0时处理
}TIMER;//时钟结构

typedef struct
{
	char change_num;
	int	 proc_c00[8],proc_c01[8],proc_c02[8],proc_c03[8],proc_c04[8],proc_c05[8],proc_c06[8],proc_c07[8];
	int  proc_s00[3],proc_s01[3],proc_s02[3],proc_s03[3],proc_s04[3],proc_s05[3],proc_s06[3],proc_s07[3];
	
}PROCESS;//进程表与处理模块


