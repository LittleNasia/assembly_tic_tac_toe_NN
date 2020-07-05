.data
	lowerMask		QWORD 0
	upperMask		QWORD 432345568522534911
	mt19937_arr		QWORD 624 DUP(624)
	mt19337_indx	WORD 624


.code
mt19937 proc
push rbx
	mov rbx,8
	cmp mt19337_indx, 624		;sotto, hiraita doa no, mukou ni
	jl dontTwist				;kowaresou na, sekai wa aru
	call mt19937_twist			;asu ga, kuru no ka
dontTwist:						;yoru ni, naru no ka
	xor rdx, rdx				;mayorinagara, hirari wa horokobite
	mov dx, mt19337_indx		;koe ga, yobu made wa, mou sukoshi asobou
	mov rax, rdx				;hana, no you ni, mawaru toki wo kurikaeshi
	xor rdx, rdx				;
	mul rbx						;yume wa, kono heya no naka de
	mov rdx, rax				;yasashii uta wo zutto, kimi ni, utatteita
	mov rax, mt19937_arr[rdx]  	;nani ga honto no koto nano
								;ichiban tsuyoku shinjirareru, sekai wo oikakete
	mov rcx, rax				;kimi no gin no niwa e
	shr rcx, 11					;
	mov rdx, 1099511627542		;michi ni, mayotta ano ko, ga kyou mo
	and rcx, rdx				;ichiban, hayaku, kaeritsuita
	xor rax, rcx				;tadashisa yori mo, akarui basho wo
								;mitsuke, nagara, hashireba iin da ne
	mov rcx, rax				;osanai, nemuri wo, mamoritai bannin
	shl rcx, 7					;otona ni naru, mon wa, kataku tozarasete
	mov rdx, 675053731862		;
	and rcx, rdx				;kimi wa, kizuiteita kana
	xor rax, rcx				;honto no koto nante
	mov rcx, rax				;itsumo, kako ni shika nai
								;mirai ya kibou wa subete
	shl rcx, 15					;dareka ga egaku tooi, niwa no
	mov rdx, 1029819072534		;wagamama na monogatari
	and rcx, rdx				;mada daremo shiranai
	xor rax, rcx				;
								
	mov rcx, rax				
	shr rcx, 1					
	xor rax, rcx				
	inc mt19337_indx			
	xor rdx, rdx
	mov eax, eax
	pop rbx
	ret
mt19937 endp


mt19937_init proc
	mov lowerMask,1
	shl lowerMask,31			;r = 31, 
	sub lowerMask,1
	mov rax, lowerMask
	mov upperMask, rax	
	not upperMask
	mov eax, 0
	sub eax, 1					;0xFFFFFFFF word size = 32
	and upperMask, rax			;lowest 32 bits of not lowerMask
	rdtsc
	mov eax, eax
	mov mt19937_arr[0], rax
	mov rcx,8					;rcx is the loop index
	mov R13, 1
loop_states:
	cmp rcx, 624 * 8
	je endLoop

	;mov rax, mt19937_arr[rcx-8];MT[i-1] (Line actually not needed as prev val is in rax every single time), optimization pog
	mov rdx, rax				;MT[i-1]
	shr rdx, 30					;MT[i-1] >> (w-2)
	xor rax, rdx				;MT[i-1] xor (MT[i-1] >> (w-2))

	mov rbx, 1812433253
	xor rdx, rdx
	mul rbx 					;f * (MT[i-1] xor (MT[i-1] >> (w-2))) for f=1812433253
	add rax, R13 				;(f * (MT[i-1] xor (MT[i-1] >> (w-2))) + i)
	mov eax, eax
	mov mt19937_arr[rcx], rax	;MT[i] := lowest 32 bits of (f * (MT[i-1] xor (MT[i-1] >> (w-2))) + i)
	add rcx, 8
	add R13, 1
	jmp loop_states
endLoop:
	xor rax, rax
	
mt19937_init endp

mt19937_twist proc
	push rbx				;system reserved (or so I thought xd)
	mov rcx,0					;rcx is the loop index
loop_states:
	cmp rcx, 624 * 8
	je endLoop

	mov R8, mt19937_arr[rcx];MT[i]
	and R8, upperMask		;(MT[i] and upper_mask)
	mov rax, rcx
	add rax, 8
	xor rdx,rdx 
	mov rbx, 624 * 8
	div rbx					;mod is in rdx currently
	
	mov R9, mt19937_arr[rdx];MT[(i+1) mod n]
	and R9, lowerMask		;(MT[(i+1) mod n] and lower_mask)
	add R8,R9				;int x
	mov R9, R8
	shr R9, 1				;int xA := x >> 1
	test R8, 1				
	jz end_if
	xor R9, 9908B0DFh
	end_if:
	mov rax, rcx
	add rax, 156 * 4
	xor rdx, rdx
	mov rbx, 624 * 4
	div rbx
	mov rax, mt19937_arr[rdx]
	xor rax, R9
	mov mt19937_arr[rcx], rax
	add rcx, 8
	jmp loop_states
endLoop:
mov mt19337_indx, 0
pop rbx						;better to be safe 
ret
mt19937_twist endp


mt19937_genFloat proc
	call mt19937				;shizuka ni yorisotte
	movd		xmm0, eax
	mov			rax, 80000000h	;doko ni mo yukanaide
	cvtdq2ps	xmm0,xmm0
	movd		xmm1, eax		 ;madobe de saezutte
	cvtdq2ps	xmm1,xmm1
	divss		xmm0, xmm1		;nani wo nakushitatte
	mov			rax,2			;multiply weight by 2 to get a number between -2 to 2 instead, was a test if it changes anything (it doesn't)
	movd		xmm1, rax
	cvtdq2ps	xmm1,xmm1
	mulss		xmm0, xmm1

	;movd		eax, xmm0 
ret
mt19937_genFloat endp
end
 