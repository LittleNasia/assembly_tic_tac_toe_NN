extern print: PROC
.data
	ticToeSquare	db "[%c]", 0h
	playerX			db 88 ;char X 
	playerO			db 79 ;char O
	playerNONE		db 32 ;char space
	newLine			db 0Dh, 0Ah, 0h ;13,10,0 


.code
;rcx is the index of the square 
;0   ...    000 000 000      000 000 000
;side		O positions		 X positions
board_move proc
	cmp rcx, 0
	jl	miku			;vocaloids are cool
	cmp rcx, 9
	jge	miku			;vocaloids are cool
	mov rdx, 1
	shl rdx, cl
	test R15, rdx		;is X placed there
	jnz miku			;vocaloids are cool 
	shl rdx, 9			
	test R15, rdx		;is O placed there
	jnz miku			;vocaloids are cool 

	lzcnt rcx, R15		;we now test for side to move
	jz move			;O moves if the sign bit is 1 (meaning no leading zeroes)
	shr rdx, 9			;if X moves, we bring rdx back to point at X squares
move:
	or R15, rdx			;our move is now placed!
	mov rcx, 9223372036854775808	;pow(2,63)
	xor R15, rcx
	mov rax, 1			;success
	ret
miku:
xor rax, rax			;return 0
ret
board_move endp

;compare our board state with preset bit masks to see if a win condition is cleared
;returns 1 if X won, 2 if O won, 3 if draw, 0 otherwise, done this way so we can both use this procedure as a bool (nonzero if game over) or to get the exact game result 
board_isWin proc
	mov rcx, R15
	and rcx, 7
	cmp rcx, 7
	je winX

	mov rcx, R15
	and rcx, 56
	cmp rcx, 56
	je winX

	mov rcx, R15
	and rcx, 448
	cmp rcx, 448
	je winX

	mov rcx, R15
	and rcx, 273
	cmp rcx, 273
	je winX

	mov rcx, R15
	and rcx, 84
	cmp rcx, 84
	je winX

	mov rcx, R15
	and rcx, 73
	cmp rcx, 73
	je winX

	mov rcx, R15
	and rcx, 146
	cmp rcx, 146
	je winX

	mov rcx, R15
	and rcx, 292
	cmp rcx, 292
	je winX





	mov rcx, R15
	and rcx, 43008
	cmp rcx, 43008
	je winO

	mov rcx, R15
	and rcx, 3584
	cmp rcx, 3584
	je winO

	mov rcx, R15
	and rcx, 28672
	cmp rcx, 28672
	je winO

	mov rcx, R15
	and rcx, 229376
	cmp rcx, 229376
	je winO

	mov rcx, R15
	and rcx, 139776
	cmp rcx, 139776
	je winO

	mov rcx, R15
	and rcx, 37376
	cmp rcx, 37376
	je winO

	mov rcx, R15
	and rcx, 74752
	cmp rcx, 74752
	je winO

	mov rcx, R15
	and rcx, 149504
	cmp rcx, 149504
	je winO

	popcnt rcx, R15
	cmp	rcx,10
	je draw

	xor rax,rax
	jmp end_fun
draw:
	mov rax, 3
	jmp end_fun
winX:
	mov rax,1
	jmp end_fun
winO:
	mov rax,2
end_fun:
ret
board_isWin endp

;ONLY TO BE CALLED FROM WITHIN printBoard
;returns the character ('X', 'O', ' ') placed currently on the square with coordinates (R10, R11)
placecurrChar proc
;R10 should be the current row
;and R11 should be the current column
;thus the character we place
;is equivalent to:
;if R11 + R10*3 is not 0 then X
;eventually then shifted left by 9 to check for O
;if there is no X and there is no O, then it defaults to playerNONE (const char playerNONE = ' ')
mov rax, R10
xor rdx, rdx
mov rcx, 3
mul rcx
add rax, R11

mov rcx, rax
mov rax, 1
shl rax, cl
mov dl, playerNONE


test R15, rax
jz isO
mov	dl, playerX			
jmp end_f
isO:
shl rax, 9
test R15, rax
jz end_f
mov	dl, playerO			
end_f:
ret
placecurrChar endp

printBoard proc
;nested loops, calls print repeatedly
	push R15
	mov R10, 0 ;row
	mov R11, 0 ;col
	
	;while(row<3)
row:
	cmp			R10, 3 
	je			endLoop
	mov			R11, 0
	;while(col<3)
col:
	cmp R11, 3
	je		endCol
	;prepare arguments for my print function call
	call		placecurrChar
	lea         rcx, ticToeSquare	;arg1
	mov			rax, 1				;seems to work for any value
	push		R10					;printf modifies those and doesnt restore them
	push		R11					;would be sad to lose a row or col counter
	;args ready!
	call		print
	pop			R11
	pop			R10
	inc			R11
	jmp			col
endCol:
	;prepare arguments for my print function call
	lea         rcx, newLine		;arg 1
	mov			rdx, 0				;no arg 2, set to null, works either way (printf actually seems pretty smart)
	mov			rax, 1				;seems to work for any value
	push		R10					;printf modifies those and doesnt restore them
	push		R11					;would be sad to lose a row or col counter
	;args ready!
	call		print
	pop			R11
	pop			R10
	inc			R10
	jmp			row
endLoop:
	xor eax,eax
	pop R15
	ret
printBoard endp

end