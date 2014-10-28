; ==========================================
; Build: nasm load.asm -o load.com
; ==========================================

%include	"load_pm.inc"	; 常量, 宏, 以及一些说明

org	0c200h
	jmp	LABEL_BEGIN

;[SECTION .gdt]
; GDT
;                                段基址,      	   段界限, 	    属性.
LABEL_GDT:			Descriptor	       0,                0, 		    0    ; 空描述符
LABEL_DESC_CODE32:	Descriptor	       0, 		0ffffffffh, DA_CR + DA_32	 ; 非一致代码段, 32
LABEL_DESC_MEMORY:	Descriptor	       0, 		0ffffffffh, DA_CR + DA_32	 ; 非一致代码段, 32
LABEL_DESC_DATA:	Descriptor	       0,      DataLen - 1, 	   DA_DRW	 ; Data
LABEL_DESC_VIDEO:	Descriptor	 0B8000h,           0ffffh, 	   DA_DRW	 ; 显存首地址
; GDT 结束

GdtLen		equ	$ - LABEL_GDT	; GDT长度
GdtPtr		dw	GdtLen - 1		; GDT界限
			dd	0				; GDT基地址

; GDT 选择子
SelectorCode32		equ	LABEL_DESC_CODE32	- LABEL_GDT
SelectorMemory		equ LABEL_DESC_MEMORY	- LABEL_GDT
SelectorData		equ	LABEL_DESC_DATA		- LABEL_GDT
SelectorVideo		equ	LABEL_DESC_VIDEO	- LABEL_GDT
; END of [SECTION .gdt]

; IDT
[SECTION .idt]
ALIGN	32
[BITS	32]
LABEL_IDT:
; 门               目标选择子,              偏移,     DCount, 		 属性.
%rep 32
		Gate	SelectorCode32, 				0,   		0, DA_386IGate
%endrep
.020h:	Gate	SelectorCode32,    	 ClockHandler,   		0, DA_386IGate
.021h:	Gate	SelectorCode32,   KeyBoardHandler,   		0, DA_386IGate
%rep 221
		Gate	SelectorCode32, 				0,   		0, DA_386IGate
%endrep

IdtLen		equ	$ - LABEL_IDT
IdtPtr		dw	IdtLen - 1	; 段界限
			dd	0		; 基地址
; END of [SECTION .idt]

[SECTION .data]; 数据段
ALIGN	32
[BITS	32]
LABEL_DATA:
; 实模式下使用这些符号
_dwMCRNumber:			dd	0	; Memory Check Result
_dwMemSize:				dd	0
; Address Range Descriptor Structure
_ARDStruct:						
	_dwBaseAddrLow:		dd	0
	_dwBaseAddrHigh:	dd	0
	_dwLengthLow:		dd	0
	_dwLengthHigh:		dd	0
	_dwType:			dd	0
; END of _ARDStruct
_MemChkBuf:	times	256	db	0

DataLen		equ	$ - LABEL_DATA
; END of [SECTION .data1]

;[SECTION .s16]
[BITS	16]
LABEL_BEGIN:

	;清理屏幕显示
	mov al, 03h
	mov ah, 0h
	int 10h
	
	; 置光标位置
	mov bh, 0
	mov dh, 24
	mov dl, 80
	mov ah, 2h
	int 10h
	
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h
	
	; 得到内存数
	mov	ebx, 0
	mov	di, _MemChkBuf
.loop:
	mov	eax, 0E820h
	mov	ecx, 20
	mov	edx, 0534D4150h
	int	15h
	jc	LABEL_MEM_CHK_FAIL
	add	di, 20
	inc	dword [_dwMCRNumber]
	cmp	ebx, 0
	jne	.loop
	jmp	LABEL_MEM_CHK_OK
LABEL_MEM_CHK_FAIL:
	mov	dword [_dwMCRNumber], 0
LABEL_MEM_CHK_OK:
	call	GetMemSize
	cmp	dword [_dwMemSize], 01ffd000h	;.a	.a - .e 为验证代码，实际操作可能改变
	je	init_32code						;.b 
.again:									;.c
	hlt									;.d
	jmp .again							;.e
	%include "load_get_mmsize.asm"

init_32code:
	; 初始化 32 位代码段描述符
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE32 + 4], al
	mov	byte [LABEL_DESC_CODE32 + 7], ah

	; 为加载 GDTR 作准备
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT			; eax <- gdt 基地址
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt 基地址
	
	; 为加载 IDTR 作准备
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_IDT			; eax <- idt 基地址
	mov	dword [IdtPtr + 2], eax	; [IdtPtr + 2] <- idt 基地址

	; 加载 GDTR
	lgdt	[GdtPtr]
	
	; 加载 IDTR
	lidt	[IdtPtr]

	; 关中断
	cli

	; 打开地址线A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; 准备切换到保护模式
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; 真正进入保护模式
	jmp	dword SelectorCode32:0	; 执行这一句会把 SelectorCode32 装入 cs, 并跳转到 Code32Selector:0  处
; END of [SECTION .s16]


[SECTION .s32]; 32 位代码段. 由实模式跳入.
[BITS	32]

LABEL_SEG_CODE32:	
	mov	ax, SelectorData
	mov	ds, ax					; 数据段选择子
	mov	ax, SelectorData
	mov	es, ax
	
	mov	ax, SelectorVideo
	mov	gs, ax					; 视频段选择子(目的)
	
	jmp	To_Kernel

	; idt&int 相关函数
	%include "load_idt_int.asm"
	
	; 内存处理相关函数
	%include "load_mem.asm"

KeyBoardToAscii:; 键盘扫描码对应字符
	db	0,'0','1','2','3','4','5','6','7','8','9','0','-','=',0 ;本行第二个参数有待修改
	db	0,'q','w','e','r','t','y','u','i','o','p','[',']',0
	db	0,'a','s','d','f','g','h','j','k','l',';',39
	db	'`',0,92,'z','x','c','v','b','n','m',',','.','/',0,'*'
	db	0,' ',0,0,0,0,0,0,0,0,0,0,0,0,0,
	db	'7','8','9','-','4','5','6','+','1','2','3','0','.'
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

KeyBoardToAscii_Move:; 传送键盘扫描码对应字符至对应位置
	mov esi, KeyBoardToAscii
	mov edi, 0x180000 + 3
	mov ecx, 0x7f / 4
	call	memcpy
	ret
	
Memory_Move:; 传送内存信息
	mov esi, _dwMemSize
	mov edi, 0x180000 + (8 * 1024)
	mov ecx, 4 / 4
	call	memcpy
	ret

Process_Code_Length equ Process_Code_End - Process_Code	
Get_Eip_Length equ Get_Eip_Last - Get_Eip
Process_Code:
	mov ebx, eax
	mov ebx, 0x180000 + 3 * 8 * 1024 + 1 + 8 * 8 * 4
	pushf
	pop eax
	mov [ebx], eax
	add dword ebx, 4
	mov [ebx], cs
	add dword ebx, 4
	call	Get_Eip
	mov [ebx], eax
	mov eax, Get_Eip_Length
	jmp	Get_Eip_Last
Get_Eip:
	pop	eax
	push	eax
	ret
Get_Eip_Last:
	ret
Process_Code_End:

Process_Code_Move:
	add eax, 0x180000 + 8 * 8 * 1024 + 512
	mov esi, Process_Code
	mov edi, eax
	mov ecx, Process_Code_Length + 24 / 4
	call	memcpy
	ret

To_Kernel:
	; 初始化PIC
	call	Init8259A
	sti
	; 初始化PIT，设置定时器频率
	call	InitPIT
	; 传送键盘扫描码对应字符至对应位置
	call	KeyBoardToAscii_Move
	; 传送内存信息
	call	Memory_Move
	; 进程头信息设置
	mov eax, 0 * 1024 * 1024
	call	Process_Code_Move
	mov eax, 1 * 1024 * 1024
	call	Process_Code_Move
	mov eax, 2 * 1024 * 1024
	call	Process_Code_Move
	mov eax, 3 * 1024 * 1024
	call	Process_Code_Move
	mov eax, 4 * 1024 * 1024
	call	Process_Code_Move
	mov eax, 5 * 1024 * 1024
	call	Process_Code_Move
	mov eax, 6 * 1024 * 1024
	call	Process_Code_Move
	mov eax, 7 * 1024 * 1024
	call	Process_Code_Move
	; 记录进程头所需iretd信息
	mov	eax, 0 * 3 * 4
	call	0x180000 + 8 * 8 * 1024 + 512 + 0 * 1024 * 1024
	mov	eax, 1 * 3 * 4
	call	0x180000 + 8 * 8 * 1024 + 512 + 1 * 1024 * 1024
	mov	eax, 2 * 3 * 4
	call	0x180000 + 8 * 8 * 1024 + 512 + 2 * 1024 * 1024
	mov	eax, 3 * 3 * 4
	call	0x180000 + 8 * 8 * 1024 + 512 + 3 * 1024 * 1024
	mov	eax, 4 * 3 * 4
	call	0x180000 + 8 * 8 * 1024 + 512 + 4 * 1024 * 1024
	mov	eax, 5 * 3 * 4
	call	0x180000 + 8 * 8 * 1024 + 512 + 5 * 1024 * 1024
	mov	eax, 6 * 3 * 4
	call	0x180000 + 8 * 8 * 1024 + 512 + 6 * 1024 * 1024
	mov	eax, 7 * 3 * 4
	call	0x180000 + 8 * 8 * 1024 + 512 + 7 * 1024 * 1024
	; 开放中断处理关卡
	call	open_handler
	; 进入内核模块
	call	System_Main

.again:
	hlt
	jmp .again
	
System_Main:


;SegCode32Len	equ	$ - LABEL_SEG_CODE32
; END of [SECTION .s32]

