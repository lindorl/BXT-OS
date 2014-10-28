; ==========================================
; Build: nasm load.asm -o load.com
; ==========================================

%include	"load_pm.inc"	; ����, ��, �Լ�һЩ˵��

org	0c200h
	jmp	LABEL_BEGIN

;[SECTION .gdt]
; GDT
;                                �λ�ַ,      	   �ν���, 	    ����.
LABEL_GDT:			Descriptor	       0,                0, 		    0    ; ��������
LABEL_DESC_CODE32:	Descriptor	       0, 		0ffffffffh, DA_CR + DA_32	 ; ��һ�´����, 32
LABEL_DESC_MEMORY:	Descriptor	       0, 		0ffffffffh, DA_CR + DA_32	 ; ��һ�´����, 32
LABEL_DESC_DATA:	Descriptor	       0,      DataLen - 1, 	   DA_DRW	 ; Data
LABEL_DESC_VIDEO:	Descriptor	 0B8000h,           0ffffh, 	   DA_DRW	 ; �Դ��׵�ַ
; GDT ����

GdtLen		equ	$ - LABEL_GDT	; GDT����
GdtPtr		dw	GdtLen - 1		; GDT����
			dd	0				; GDT����ַ

; GDT ѡ����
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
; ��               Ŀ��ѡ����,              ƫ��,     DCount, 		 ����.
%rep 32
		Gate	SelectorCode32, 				0,   		0, DA_386IGate
%endrep
.020h:	Gate	SelectorCode32,    	 ClockHandler,   		0, DA_386IGate
.021h:	Gate	SelectorCode32,   KeyBoardHandler,   		0, DA_386IGate
%rep 221
		Gate	SelectorCode32, 				0,   		0, DA_386IGate
%endrep

IdtLen		equ	$ - LABEL_IDT
IdtPtr		dw	IdtLen - 1	; �ν���
			dd	0		; ����ַ
; END of [SECTION .idt]

[SECTION .data]; ���ݶ�
ALIGN	32
[BITS	32]
LABEL_DATA:
; ʵģʽ��ʹ����Щ����
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

	;������Ļ��ʾ
	mov al, 03h
	mov ah, 0h
	int 10h
	
	; �ù��λ��
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
	
	; �õ��ڴ���
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
	cmp	dword [_dwMemSize], 01ffd000h	;.a	.a - .e Ϊ��֤���룬ʵ�ʲ������ܸı�
	je	init_32code						;.b 
.again:									;.c
	hlt									;.d
	jmp .again							;.e
	%include "load_get_mmsize.asm"

init_32code:
	; ��ʼ�� 32 λ�����������
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE32 + 4], al
	mov	byte [LABEL_DESC_CODE32 + 7], ah

	; Ϊ���� GDTR ��׼��
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT			; eax <- gdt ����ַ
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt ����ַ
	
	; Ϊ���� IDTR ��׼��
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_IDT			; eax <- idt ����ַ
	mov	dword [IdtPtr + 2], eax	; [IdtPtr + 2] <- idt ����ַ

	; ���� GDTR
	lgdt	[GdtPtr]
	
	; ���� IDTR
	lidt	[IdtPtr]

	; ���ж�
	cli

	; �򿪵�ַ��A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; ׼���л�������ģʽ
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; �������뱣��ģʽ
	jmp	dword SelectorCode32:0	; ִ����һ���� SelectorCode32 װ�� cs, ����ת�� Code32Selector:0  ��
; END of [SECTION .s16]


[SECTION .s32]; 32 λ�����. ��ʵģʽ����.
[BITS	32]

LABEL_SEG_CODE32:	
	mov	ax, SelectorData
	mov	ds, ax					; ���ݶ�ѡ����
	mov	ax, SelectorData
	mov	es, ax
	
	mov	ax, SelectorVideo
	mov	gs, ax					; ��Ƶ��ѡ����(Ŀ��)
	
	jmp	To_Kernel

	; idt&int ��غ���
	%include "load_idt_int.asm"
	
	; �ڴ洦����غ���
	%include "load_mem.asm"

KeyBoardToAscii:; ����ɨ�����Ӧ�ַ�
	db	0,'0','1','2','3','4','5','6','7','8','9','0','-','=',0 ;���еڶ��������д��޸�
	db	0,'q','w','e','r','t','y','u','i','o','p','[',']',0
	db	0,'a','s','d','f','g','h','j','k','l',';',39
	db	'`',0,92,'z','x','c','v','b','n','m',',','.','/',0,'*'
	db	0,' ',0,0,0,0,0,0,0,0,0,0,0,0,0,
	db	'7','8','9','-','4','5','6','+','1','2','3','0','.'
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

KeyBoardToAscii_Move:; ���ͼ���ɨ�����Ӧ�ַ�����Ӧλ��
	mov esi, KeyBoardToAscii
	mov edi, 0x180000 + 3
	mov ecx, 0x7f / 4
	call	memcpy
	ret
	
Memory_Move:; �����ڴ���Ϣ
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
	; ��ʼ��PIC
	call	Init8259A
	sti
	; ��ʼ��PIT�����ö�ʱ��Ƶ��
	call	InitPIT
	; ���ͼ���ɨ�����Ӧ�ַ�����Ӧλ��
	call	KeyBoardToAscii_Move
	; �����ڴ���Ϣ
	call	Memory_Move
	; ����ͷ��Ϣ����
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
	; ��¼����ͷ����iretd��Ϣ
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
	; �����жϴ���ؿ�
	call	open_handler
	; �����ں�ģ��
	call	System_Main

.again:
	hlt
	jmp .again
	
System_Main:


;SegCode32Len	equ	$ - LABEL_SEG_CODE32
; END of [SECTION .s32]

