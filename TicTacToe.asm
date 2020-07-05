;these thingies have printf
includelib libcmt.lib
includelib legacy_stdio_definitions.lib

;telling the linker (I think...? That would be the case in C lol) that we have these awesome procedures in other files 
extern printf: PROC
extern board_move: PROC
extern board_isWin: PROC
extern printBoard: PROC
extern mt19937: PROC
extern mt19937_init: PROC
extern mt19937_genFloat: PROC
extern NN_readInput: PROC
extern NN_initialize_weigths: PROC
extern NN_calculateFirstLayer: PROC
extern NN_calculateSecondLayer: PROC
extern NN_calculateThirdLayer: PROC
extern NN_makeMove: PROC
extern NN_calculateOutputError: PROC
extern testo: PROC

;NOTE:
;R15 is reserved for the board:
;low 9 bits are used to store X positions
;bits 10 to 18 are used to store O positions
;side to move is the sign bit
;easy to check using LZCNT 
;draw -> no win && POPCNT = 10 
.data
	gameHistory		QWORD 9 DUP(10)
	moveHistory		QWORD 9 DUP(10)
	result			QWORD 0
	newLine			db 0Dh, 0Ah, 0h ;13,10,0 
	readNum			db "%llu"
	readFloat		db "%f "
	score			db "%d vs %d", 0Dh, 0Ah, 0h
	mov_indx		QWORD 0
	helo			real4 2.0    ;double template for testing, not used I think..?
	NN_wins			qword 0		 ;used for stats
	RND_wins		qword 0
	draws			qword 0
.code


print proc
;rcx - format string for printf
;rdx - value to print 
	;push        rdi		
	;push		rcx			
	;push		rdx			
	;push		rax			
	sub         rsp, 40h	;allocate stack space for printf as it's too dummy to do it itself
	;mov         rdi, rsp	
	call		printf		
	add         rsp, 40h	;get back allocated stack space
	;pop         rax			
	;pop         rdx 
	;pop         rcx 
	;pop         rdi			
ret
print endp


main proc 
	xor R15, R15		
	call mt19937_init
	call NN_initialize_weigths
	xor R8, R8 
	xor R9, R9
play:
	lzcnt rcx, R15		;we now test for side to move
	jnz moveNN			;NN moves as X, which means there are leading zeroes

moveRand:
	push R8
	push R9
	call mt19937
	pop R9
	pop R8
	xor rdx, rdx
	mov rcx, 9
	div rcx
	mov rcx, rdx
	push R8
	push R9
	mov moveHistory[R9],rcx
	call board_move
	pop R9
	pop R8
	cmp rax, 1
	jne moveRand
	jmp finish
moveNN:



	push R8
	push R9
	call NN_makeMove
	pop R9
	pop R8
	mov rcx, rax
	mov moveHistory[R9],rcx
	push R8
	call board_move
	pop R8
finish:
	mov gameHistory[R9], R15	;move the current
	add R9, 8
	push R9
	push R8
	call board_isWin
	pop R8
	pop R9
	mov R14, R15
	cmp rax, 1
	je winX
	cmp rax, 2
	je winO
	cmp rax, 3
	je draw


	;call printBoard
	;lea         rcx, newLine		;arg 1
	;mov			rdx, 0				;no arg 2, set to null, works either way (printf actually seems pretty smart)
	;mov			rax, 1				;seems to work for any value
	;call		print
	jmp play 
draw:
	inc draws
	xor R15, R15
	jmp end_fun
winX:
	inc NN_wins
	xor R15, R15
	jmp end_fun
winO:
	inc RND_wins
	xor R15, R15
end_fun:
	push R8
	mov result, rax
	lea rcx, gameHistory
	lea rdx, moveHistory
	mov r8, result
	;R9 is the max index 
	call NN_calculateOutputError
	pop R8
	inc R8
	xor R9, R9
	xor R15, R15
	cmp R8, 10000
	jne play
	lea rcx, score
	mov rdx, NN_wins
	mov R8, RND_wins
	call print
	mov R15, R14
	call printBoard
	xor R15, R15
	mov NN_wins, 0
	mov RND_wins, 0
	mov R8, 0
	xor R9, R9
	jmp play
	xor rax, rax
	ret
main endp
end 
