;===================================
;	Build: nasm -o boot.bin boot.asm
;===================================
	org  07c00h				; Boot ״̬, Bios ���� Boot Sector ���ص� 0:7C00 ������ʼִ��

	jmp short LABEL_START	; Start to boot.
	nop						; ��� nop ������

	; ������ FAT12 ���̵�ͷ
	BS_OEMName		DB 'ForrestY'	; OEM String, ���� 8 ���ֽ�
	BPB_BytsPerSec	DW 512			; ÿ�����ֽ���
	BPB_SecPerClus	DB 1			; ÿ�ض�������
	BPB_RsvdSecCnt	DW 1			; Boot ��¼ռ�ö�������
	BPB_NumFATs		DB 2			; ���ж��� FAT ��
	BPB_RootEntCnt	DW 224			; ��Ŀ¼�ļ������ֵ
	BPB_TotSec16	DW 2880			; �߼���������
	BPB_Media		DB 0xF0			; ý��������
	BPB_FATSz16		DW 9			; ÿFAT������
	BPB_SecPerTrk	DW 18			; ÿ�ŵ�������
	BPB_NumHeads	DW 2			; ��ͷ��(����)
	BPB_HiddSec		DD 0			; ����������
	BPB_TotSec32	DD 2880			; ��� wTotalSectorCount �� 0 �����ֵ��¼������
	BS_DrvNum		DB 0			; �ж� 13 ����������
	BS_Reserved1	DB 0			; δʹ��
	BS_BootSig		DB 0x29			; ��չ������� (29h)
	BS_VolID		DD 0xffffffff	; �����к�
	BS_VolLab		DB 'BXT-OSv0.01'; ���, ���� 11 ���ֽ�
	BS_FileSysType	DB 'FAT12   '	; �ļ�ϵͳ����, ���� 8���ֽ�  

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
	int	13h					;ah = 02h , int 13h ���ڶ�����״̬ 
	jnc	next			
	add	si, 1			
	cmp	si, 5	
	jae	_error	
	mov	ah, 0
	mov	dl, 0
	int	13h					;ah = 0 , int 13h ��������ϵͳ��λ
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

times	510-($-$$)	db	0	; ���ʣ�µĿռ䣬ʹ���ɵĶ����ƴ���ǡ��Ϊ512�ֽ�
dw	0xaa55					; ������־,ps:ǰ512�ֽں�������Ϊ��aa55��
