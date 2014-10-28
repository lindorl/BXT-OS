;===================================
;	Build: nasm -o boot.bin boot.asm
;===================================
	org  07c00h				; Boot 状态, Bios 将把 Boot Sector 加载到 0:7C00 处并开始执行

	jmp short LABEL_START	; Start to boot.
	nop						; 这个 nop 不可少

	; 下面是 FAT12 磁盘的头
	BS_OEMName		DB 'ForrestY'	; OEM String, 必须 8 个字节
	BPB_BytsPerSec	DW 512			; 每扇区字节数
	BPB_SecPerClus	DB 1			; 每簇多少扇区
	BPB_RsvdSecCnt	DW 1			; Boot 记录占用多少扇区
	BPB_NumFATs		DB 2			; 共有多少 FAT 表
	BPB_RootEntCnt	DW 224			; 根目录文件数最大值
	BPB_TotSec16	DW 2880			; 逻辑扇区总数
	BPB_Media		DB 0xF0			; 媒体描述符
	BPB_FATSz16		DW 9			; 每FAT扇区数
	BPB_SecPerTrk	DW 18			; 每磁道扇区数
	BPB_NumHeads	DW 2			; 磁头数(面数)
	BPB_HiddSec		DD 0			; 隐藏扇区数
	BPB_TotSec32	DD 2880			; 如果 wTotalSectorCount 是 0 由这个值记录扇区数
	BS_DrvNum		DB 0			; 中断 13 的驱动器号
	BS_Reserved1	DB 0			; 未使用
	BS_BootSig		DB 0x29			; 扩展引导标记 (29h)
	BS_VolID		DD 0xffffffff	; 卷序列号
	BS_VolLab		DB 'BXT-OSv0.01'; 卷标, 必须 11 个字节
	BS_FileSysType	DB 'FAT12   '	; 文件系统类型, 必须 8个字节  

LABEL_START:	
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	
	mov	si,	BootMessage
	
DispStr:
	mov	ax, [si]
	add si, 1
	cmp al, 0
	je	Entry
	mov	ah, 0eh
	mov bx, 15
	int 10h
	jmp DispStr

Entry:
	mov	ax, 0
	mov	ss, ax
	mov	sp, 7c00h
	mov	ds, ax
	
	mov	ax, 0820h
	mov	es, ax
	mov	ch, 0
	mov	dh, 0	
	mov	cl, 2		

Readloop:	
	mov	si, 0		
	
Retry:
	mov	ah, 02h	
	mov	al, 1	
	mov	bx, 0
	mov	dl, 0		
	int	13h					;ah = 02h , int 13h 用于读磁盘状态 
	jnc	next			
	add	si, 1			
	cmp	si, 5	
	jae	_error	
	mov	ah, 0
	mov	dl, 0
	int	13h					;ah = 0 , int 13h 用于软盘系统复位
	jmp	Retry
	
next:
	mov	ax, es		
	add	ax, 0020h
	mov	es, ax		
	add	cl, 1	
	cmp	cl, 18		
	jbe	Readloop	
	mov	cl, 1
	add	dh, 1
	cmp	dh, 2
	jb	Readloop	
	mov	dh, 0
	add	ch, 1
	cmp	ch, 10
	jb	Readloop	
	
	mov [0ff0h], ch
	jmp	0c200h

_error:
	mov	si, LoadMessage
	
Putloop:
	mov	al, [si]
	add	si, 1	
	cmp	al, 0
	je	Fin
	mov	ah, 0eh	
	mov	bx, 15		
	int	10h	
	jmp	Putloop

Fin:
	hlt
	jmp	Fin

LoadMessage:
	db	0ah, 0ah
	db	"load error"
	db	0ah
	db	0
	
BootMessage:
	db	0ah, 0ah
	db	"Welcome to my system BXT-OS !"
	db	0ah, 0ah
	db	0

times	510-($-$$)	db	0	; 填充剩下的空间，使生成的二进制代码恰好为512字节
dw	0xaa55					; 结束标志,ps:前512字节后两个需为“aa55”
