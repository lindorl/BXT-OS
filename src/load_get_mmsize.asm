
;---------------------------------------------------------------------------------------
; 获取内存大小
;---------------------------------------------------------------------------------------
GetMemSize:
	push	esi
	push	edi
	push	ecx
	
	mov	esi, _MemChkBuf
	mov	ecx, [_dwMCRNumber]	  ;for(int i=0;i<[MCRNumber];i++) // 每次得到一个ARDS(Address Range Descriptor Structure)结构
.loop:					 					  ;{
	mov	edx, 5				 			  ;		for(int j=0;j<5;j++)	// 每次得到一个ARDS中的成员，共5个成员
	mov	edi, _ARDStruct		 		  ;		{			// 依次显示：BaseAddrLow，BaseAddrHigh，LengthLow，LengthHigh，Type
.1:							 				  ;
	mov	dword eax, [esi]	 		  ;
	stosd					 				  ;			ARDStruct[j*4] = MemChkBuf[j*4];
	add	esi, 4				 			  ;
	dec	edx					 			  ;
	cmp	edx, 0				 			  ;
	jnz	.1					 				  ;		}
	cmp	dword [_dwType], 1	 	  ;		if(Type == AddressRangeMemory) // AddressRangeMemory : 1, AddressRangeReserved : 2
	jne	.2					 				  ;		{
	mov	eax, [_dwBaseAddrLow]   ;
	add	eax, [_dwLengthLow]	 	  ;
	cmp	eax, [_dwMemSize]	 	  ;			if(BaseAddrLow + LengthLow > MemSize)
	jb	.2					 					  ;		
	mov	[_dwMemSize], eax	 	  ;			MemSize = BaseAddrLow + LengthLow;
.2:							 				  ;		}
	loop	.loop			 					  ;}
	
	pop	ecx
	pop	edi
	pop	esi
	ret
; END of GetMemSize --------------------------------------------------------------------