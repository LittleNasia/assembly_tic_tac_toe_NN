extern mt19937_genFloat: PROC	
extern mt19937: PROC
extern board_move: PROC 

.data
	LAYER_INPUT_SIZE		equ	27
	LAYER_FIRST_SIZE		equ	18
	LAYER_SECOND_SIZE		equ	9
	LAYER_OUTPUT_SIZE		equ	9
	one						real4 1.0
	
	learningRate			real4 0.09

	INPUT					db    LAYER_INPUT_SIZE DUP(0.0)
	LAYER_FIRST				real4 LAYER_FIRST_SIZE DUP(0.0)
	LAYER_SECOND			real4 LAYER_SECOND_SIZE DUP(0.0)
	LAYER_OUTPUT			real4 LAYER_OUTPUT_SIZE DUP(0.0)


	LAYER_FIRST_SIGMOIDLESS			real4 LAYER_FIRST_SIZE DUP(0.0)		;called 
	LAYER_SECOND_SIGMOIDLESS		real4 LAYER_SECOND_SIZE DUP(0.0)
	LAYER_OUTPUT_SIGMOIDLESS		real4 LAYER_OUTPUT_SIZE DUP(0.0)

	LAYER_FIRST_BIAS		real4 LAYER_FIRST_SIZE DUP(0.1)
	LAYER_SECOND_BIAS		real4 LAYER_SECOND_SIZE DUP(0.1)
	LAYER_OUTPUT_BIAS		real4 LAYER_OUTPUT_SIZE DUP(0.1)

	LAYER_FIRST_WEIGHTS		real4 LAYER_FIRST_SIZE * LAYER_INPUT_SIZE DUP(0.0)
	LAYER_SECOND_WEIGHTS	real4 LAYER_SECOND_SIZE * LAYER_FIRST_SIZE DUP(0.0)
	LAYER_OUTPUT_WEIGHTS	real4 LAYER_OUTPUT_SIZE * LAYER_SECOND_SIZE DUP(0.0)

	LAYER_FIRST_WEIGHTS_ERROR		real4 LAYER_FIRST_SIZE * LAYER_INPUT_SIZE DUP(0.0)
	LAYER_SECOND_WEIGHTS_ERROR	real4 LAYER_SECOND_SIZE * LAYER_FIRST_SIZE DUP(0.0)
	LAYER_OUTPUT_WEIGHTS_ERROR	real4 LAYER_OUTPUT_SIZE * LAYER_SECOND_SIZE DUP(0.0)

	LAYER_FIRST_ERROR		real4 LAYER_FIRST_SIZE DUP(0.0)
	LAYER_SECOND_ERROR		real4 LAYER_SECOND_SIZE DUP(0.0)
	LAYER_OUTPUT_ERROR		real4 LAYER_OUTPUT_SIZE DUP(0.0)

	ANSWERS					real4 LAYER_OUTPUT_SIZE DUP(0.0)

	
	teste					real4 0.0
.code	

NN_activationFunction proc
;ReLU
;push rax
;	mov rax, 0 
;	movq xmm1, rax
;	movaps xmm2, xmm0
;	comiss   xmm0, xmm1
;	ja bringBack
;	movq xmm0, rax
;	jmp endFun
;bringBack:
;	movaps xmm0, xmm2
;endFun:
;pop rax

;""sigmoid""
push rax
movss xmm2, xmm0
mov rax, 2147483647
movd xmm1, rax
andps xmm2, xmm1
addss xmm2, one
divss xmm0, xmm2
pop rax
ret
NN_activationFunction endp

NN_activationFunctionDerivative proc
;""sigmoid"" derivative
mov rax, 2147483647
movd xmm1, rax
andps xmm0, xmm1
movd xmm1, one
addss xmm0, xmm1
mulss xmm0, xmm0
divss xmm1, xmm0
movss xmm0,xmm1
ret

NN_activationFunctionDerivative endp


NN_readInput proc
	xor rcx, rcx
	
begin_loop:
	cmp rcx, 18
	je end_first_loop
	mov rax, R15
	mov rdx, 1
	shl rdx, cl
	inc rcx
	and rax, rdx
	jnz adding
	mov INPUT[rcx], 0
	jmp begin_loop
adding:
	mov INPUT[rcx], 1
	jmp begin_loop

end_first_loop:
xor rcx, rcx
xor R8, R8
mov R9, 18
begin_second_loop:
	cmp rcx, 9
	je end_loop
	mov rdx, 1
	shl rdx, cl
	or R8, rdx
	shl rdx, 9
	or R8, rdx
	mov rax, R15
	and rax, R8
	jnz adding_second_loop
	mov INPUT[R9], 1
	inc R9
	inc rcx
	jmp begin_second_loop
adding_second_loop:
	mov INPUT[R9], 0
	inc R9
	inc rcx
	jmp begin_second_loop
end_loop:
ret
NN_readInput endp

NN_initialize_weigths proc
	mov rcx, 0

loop_first_begin:
	cmp rcx, LAYER_FIRST_SIZE * LAYER_INPUT_SIZE * 4
	je loop_first_end
	push rcx
	call mt19937_genFloat
	pop rcx
	;movd  teste, xmm0
	;mov eax, teste
	movd  LAYER_FIRST_WEIGHTS[rcx], xmm0
	add rcx, 4
	jmp loop_first_begin
loop_first_end:
	mov rcx, 0
loop_second_begin:
	cmp rcx, LAYER_SECOND_SIZE * LAYER_FIRST_SIZE * 4
	je loop_second_end
	push rcx
	call mt19937_genFloat
	pop rcx
	movd  LAYER_SECOND_WEIGHTS[rcx], xmm0
	add rcx, 4
	jmp loop_second_begin
loop_second_end:
	mov rcx, 0
loop_third_begin:
	cmp rcx, LAYER_OUTPUT_SIZE * LAYER_SECOND_SIZE * 4
	je finale
	push rcx
	call mt19937_genFloat
	pop rcx
	;movd  teste, xmm0
	movd  LAYER_OUTPUT_WEIGHTS[rcx], xmm0
	add rcx, 4
	jmp loop_third_begin

finale:
ret

NN_initialize_weigths endp

NN_calculateFirstLayer proc
	mov R8, 0		;go through each of current Layer neurons
start_curr:
	mov rax, 0
	movq xmm0, rax
	cmp R8, LAYER_FIRST_SIZE
	jge end_curr
	mov R9, 0		;go through each of prev layer neurons
start_prev:			;sum each of previous layer values times its weight
	cmp R9, LAYER_INPUT_SIZE		;if we ran out of columns we go to the next row
	jge end_prev
	mov rax, R8						;prepare to multiply
	mov rcx, LAYER_INPUT_SIZE		;multiply by number of input neurons (which is the number of columns)
	xor rdx, rdx					;zero the rdx to not ecounter any surprises during multiply
	mul rcx							;multiply
	add rax, R9						;add the current column
	mov rcx, 4						;multiply by 4 (sizeof(float))
	mul rcx							;go watch madoka
	movd xmm1, LAYER_FIRST_WEIGHTS[rax]
	xor rax, rax 
	mov al, INPUT[R9]
	movd xmm2, eax
	cvtdq2ps xmm2, xmm2


	mulps xmm1, xmm2 
	addss xmm0, xmm1
	
	inc R9
	jmp start_prev
end_prev:
mov rax, R8
xor rdx, rdx 
mov rcx, 4 ;sizeof(float)
mul rcx 
addss xmm0, LAYER_FIRST_BIAS[rax]
movd LAYER_FIRST_SIGMOIDLESS[rax], xmm0
call NN_activationFunction
movd LAYER_FIRST[rax], xmm0
inc R8

jmp start_curr
end_curr:
ret
NN_calculateFirstLayer endp

NN_calculateSecondLayer proc
	mov R8, 0		;go through each of current Layer neurons
start_curr:
	mov rax, 0
	movq xmm0, rax
	cmp R8, LAYER_SECOND_SIZE
	jge end_curr
	mov R9, 0		;go through each of prev layer neurons
start_prev:			;sum each of previous layer values times its weight
	cmp R9, LAYER_FIRST_SIZE	;if we ran out of columns we go to the next row
	jge end_prev
	mov rax, R8						;prepare to multiply
	mov rcx, LAYER_FIRST_SIZE		;multiply by number of input neurons (which is the number of columns)
	xor rdx, rdx					;zero the rdx to not ecounter any surprises during multiply
	mul rcx							;multiply
	add rax, R9						;add the current column
	mov rcx, 4						;multiply by 4 (sizeof(float))
	mul rcx							;go watch madoka
	movd xmm1, LAYER_SECOND_WEIGHTS[rax]
	xor rax, rax 
	mov rax, R9
	mov rcx, 4
	mul rcx
	mov eax, LAYER_FIRST[rax]
	movd xmm2, eax
	;cvtdq2ps xmm2, xmm2


	mulps xmm1, xmm2 
	addss xmm0, xmm1
	inc R9
	jmp start_prev
end_prev:
mov rax, R8
xor rdx, rdx 
mov rcx, 4 ;sizeof(float)
mul rcx
addss xmm0, LAYER_SECOND_BIAS[rax]
movd LAYER_SECOND_SIGMOIDLESS[rax], xmm0
call NN_activationFunction
movd LAYER_SECOND[rax], xmm0
inc R8

jmp start_curr
end_curr:
ret
NN_calculateSecondLayer endp

NN_calculateThirdLayer proc
	mov R8, 0		;go through each of current Layer neurons
start_curr:
	mov rax, 0
	movq xmm0, rax
	cmp R8, LAYER_OUTPUT_SIZE
	jge end_curr
	mov R9, 0		;go through each of prev layer neurons
start_prev:			;sum each of previous layer values times its weight
	cmp R9, LAYER_SECOND_SIZE	;if we ran out of columns we go to the next row
	jge end_prev
	mov rax, R8						;prepare to multiply
	mov rcx, LAYER_SECOND_SIZE		;multiply by number of input neurons (which is the number of columns)
	xor rdx, rdx					;zero the rdx to not ecounter any surprises during multiply
	mul rcx							;multiply
	add rax, R9						;add the current column
	mov rcx, 4						;multiply by 4 (sizeof(float)), since sizeof(float) is 4 and "operator[]" in assembly accesses specific *byte*, not index in array, we need to calculate the byte which is index *  4
	mul rcx							;go watch madoka
	movd xmm1, LAYER_OUTPUT_WEIGHTS[rax]
	xor rax, rax 
	mov rax, R9
	mov rcx, 4
	mul rcx
	mov eax, LAYER_SECOND[rax]
	movd xmm2, eax
	;cvtdq2ps xmm2, xmm2


	mulps xmm1, xmm2 
	addss xmm0, xmm1
	inc R9
	jmp start_prev
end_prev:
mov rax, R8
xor rdx, rdx 
mov rcx, 4 ;sizeof(float)
mul rcx
addss xmm0, LAYER_OUTPUT_BIAS[rax]
movd LAYER_OUTPUT_SIGMOIDLESS[rax], xmm0
call NN_activationFunction
movd LAYER_OUTPUT[rax], xmm0
inc R8

jmp start_curr
end_curr:
ret
NN_calculateThirdLayer endp

NN_makeMove proc
	call NN_readInput
	call NN_calculateFirstLayer
	call NN_calculateSecondLayer
	call NN_calculateThirdLayer
	push rbx
	mov rcx, 0
	movq xmm0, rcx
movFindingLoop: ;finds the first possible move, used as a safety measure so that function always returns a viable square
	cmp rcx, 9
	je	endFun
	push rcx
	push R15
	call board_move
	pop R15
	pop rcx
	inc rcx
	cmp rax, 0		;has move failed
	je movFindingLoop	;if it did, discard the move
	mov rbx, 4
	mov rax, rcx
	mul rbx
	mov ebx, LAYER_OUTPUT[rax]
	movd xmm0, ebx
	mov R8, rcx
	dec R8
startLoop:
	cmp rcx, 9
	jge endFun
	xor rdx, rdx
	mov rbx, 4
	mov rax, rcx
	mul rbx
	mov ebx, LAYER_OUTPUT[rax]
	movd xmm1, ebx
	movaps xmm2, xmm0
	comiss xmm0, xmm1
	jb new_biggest
	movaps xmm0, xmm2
	inc rcx
	jmp startLoop
new_biggest:
	push R15		;copy of the board
	push rcx
	call board_move
	pop rcx
	pop R15
	inc rcx
	cmp rax, 0		;has move failed
	je startLoop	;if it did, discard the move
	movaps xmm0,xmm1 
	mov R8, rcx
	dec R8				;rcx was incremented before
	jmp startLoop
endFun:
mov rax, R8
pop rbx
ret
NN_makeMove endp

NN_calculateOutputError proc
;arguments are as follows:
;rcx - pointer to gameHistory, changed to rbx later
;rdx - pointer to moveHistory
;r8 -  result of the game
;r9 - max index of move

mov rbx, rcx

xor rcx, rcx
;we loop through each of the board states
;in which we calculate the result based on the move played
gameLoop:
	cmp rcx, R9
	je endFun
	mov R15, [rbx][rcx]	;rbx has the boards, rcx is the array index
	;with our boardPos in memory, let's calculate the output values
	push rcx
	push rdx
	push R8 
	push R9
	call NN_readInput
	call NN_calculateFirstLayer
	call NN_calculateSecondLayer
	call NN_calculateThirdLayer
	pop r9
	pop R8
	pop rdx
	pop rcx
	;we now loop through the outputs and prepare the answers vector
	mov R10, 0
	mov R11, [rdx][rcx] ;rdx has the moves, rcx is the array byte
	moveLoop:
		cmp R10, LAYER_OUTPUT_SIZE ;did we reach the end of the layer
		je doneAnswer
		cmp R10, R11	;is it our move
		je setMove

		;CASE 1 : the move was not played, we have no basis to evaluate it
		push rdx  ;save it, it has the move vector
		push R10  ;save the index of move
		xor rdx, rdx 
		mov rax, R10 ;prepare for multiply, since sizeof(float) is 4 and "operator[]" in assembly accesses specific *byte*, not index in array, we need to calculate the byte which is index *  4
		mov R12, 4   ;sizeof(float)
		mul R12
		mov R10, rax
		mov eax, LAYER_OUTPUT[R10]
		mov ANSWERS[R10], eax
		pop R10
		pop rdx
		inc R10
		jmp moveLoop
		setMove:

		;CASE 2 : the move was played, we set the answer as the result of the game 
		push rdx  ;save it, it has the move vector
		push R10  ;save the index of move
		xor rdx, rdx 
		mov rax, R10 ;prepare for multiply
		mov R12, 4   ;sizeof(float)
		mul R12
		mov R10, rax
		cmp r8, 1
		je winX
		cmp r8, 2
		je winO
		cmp r8, 3
		je draw

		winX:
		mov ANSWERS[R10],1073741824 ;1.0f (or that was the intent, could be something completely else)
		pop R10
		pop rdx
		inc R10
		jmp moveLoop
		winO:
		mov ANSWERS[R10],3212836864 ;-1.0 f (or that was the intent, could be something completely else)
		pop R10
		pop rdx
		inc R10
		jmp moveLoop
		draw:
		mov ANSWERS[R10],0 ;0 float
		pop R10
		pop rdx
		inc R10
		jmp moveLoop


doneAnswer:
;with our answers vector ready, now it's time to calculate the error
;at first, for each layer activation we subtract the answer
;in case of an unplayed move the error will be 0, otherwise there will be some error
;unless the network successfully predicted the correct score, in which case yay
push rcx ;it's used in the main game loop
xor rcx, rcx

subtraction:
cmp rcx, LAYER_OUTPUT_SIZE*4 ;sizeof(float)
je endOfErrorCalculation
movd xmm0, LAYER_OUTPUT[rcx]
movd xmm1, ANSWERS[rcx]
subss xmm0, xmm1 ;xmm0 now has our result, now we need to multiply it by
;the derivative of the activation function
;from the value of sigmoidless layer activation
movss xmm4, xmm0
movd xmm0, LAYER_OUTPUT_SIGMOIDLESS[rcx]
call NN_activationFunctionDerivative
mulss xmm0, xmm4

movd LAYER_OUTPUT_ERROR[rcx], xmm0	;set the error to that value
add rcx, 4
jmp subtraction
endOfErrorCalculation:
;we now have our output error ready, time to calculate second layer error
;this one is tricky, we gotta do:
;loop through columns, for each column we:
;-multiply next layer weights column[x] by next_layer_error[x]
;-sum the results from all columns
;-apply the derivative shenanigans, store the result as the [y] index of current layer error
;I use R12 and R13 as the row and column thingies
;because they aren't used anywhere in the entire program
;and I ain't gonna screw around with rcx anymore to not lose track of our awesome
;game counter
xor R12, R12 ;"offset" for R13, used as the column number
;LAYER_OUTPUT_WEIGHTS	real4 LAYER_OUTPUT_SIZE * LAYER_SECOND_SIZE DUP(0.0)
column:
cmp R12, LAYER_SECOND_SIZE*4 
je endSecondLoop
xor R13, R13
xorps xmm0,xmm0 ;xmm0 stores the current total weighted sum
row:
cmp R13, LAYER_SECOND_SIZE*LAYER_OUTPUT_SIZE * 4
jge endRow

mov rax, R12
add rax, R13 ;get current weight matrix index, which is column + current row

movd xmm1, LAYER_OUTPUT_WEIGHTS[rax]	

push rdx
push rbx
xor rdx, rdx
mov rax, R13
mov rbx, LAYER_SECOND_SIZE
div rbx
pop rbx
pop rdx
movd xmm2, LAYER_OUTPUT_ERROR[rax]		;rax = row * LAYER_SECOND_SIZE * 4 / LAYER_SECOND_SIZE 
mulss xmm1, xmm2
addss xmm0, xmm1
add R13, LAYER_SECOND_SIZE*4 ;go to the next row
jmp row
endRow:
movss xmm4, xmm0
movd xmm0, LAYER_SECOND_SIGMOIDLESS[R12]
call NN_activationFunctionDerivative
mulss xmm0, xmm4
movd LAYER_SECOND_ERROR[R12], xmm0	;set the error to that value


add R12, 4
jmp column
endSecondLoop:



xor R12, R12 ;"offset" for R13, used as the column number
;LAYER_SECOND_WEIGHTS	real4 LAYER_SECOND_SIZE * LAYER_FIRST_SIZE DUP(0.0)
column_first:
cmp R12, LAYER_FIRST_SIZE*4 
je endSecondLoop_first
xor R13, R13
xorps xmm0,xmm0 ;xmm0 stores the current total weighted sum
row_first:
cmp R13, LAYER_FIRST_SIZE*LAYER_SECOND_SIZE * 4
jge endRow_first

mov rax, R12
add rax, R13 ;get current weight matrix index, which is column + current row

movd xmm1, LAYER_SECOND_WEIGHTS[rax]	
push rdx
push rbx
xor rdx, rdx
mov rax, R13
mov rbx, LAYER_FIRST_SIZE
div rbx
pop rbx
pop rdx
movd xmm2, LAYER_SECOND_ERROR[rax]		;rax = row * LAYER_FIRST_SIZE * 4 / LAYER_FIRST_SIZE 
mulss xmm1, xmm2
addss xmm0, xmm1
add R13, LAYER_FIRST_SIZE*4 ;go to the next row
jmp row_first
endRow_first:
movss xmm4, xmm0
movd xmm0, LAYER_FIRST_SIGMOIDLESS[R12]
call NN_activationFunctionDerivative
mulss xmm0, xmm4
movd LAYER_FIRST_ERROR[R12], xmm0	;set the error to that value
add R12, 4
jmp column_first

endSecondLoop_first:



;	LAYER_FIRST_WEIGHTS		real4 LAYER_FIRST_SIZE * LAYER_INPUT_SIZE DUP(0.0)
xor R13, R13
WeightsErrorInput:
cmp R13,LAYER_INPUT_SIZE * 4
jge endWeightsErrorInput

xor R12, R12
WeightsErrorOutput:
cmp R12, LAYER_FIRST_SIZE * 4
jge endWeigthsErrorOutput
xor rax, rax
push rdx
xor rdx, rdx
mov rax, R13
push rbx
mov rbx, 4
div rbx
pop rbx
pop rdx
mov al, INPUT[rax]
movd xmm0, eax
cvtdq2ps xmm0, xmm0
movd xmm1, LAYER_FIRST_ERROR[R12]
mulss xmm0, xmm1

mov rax, R12
push rbx
push rdx
xor rdx, rdx
mov rbx, LAYER_INPUT_SIZE 
mul rbx
pop rdx
pop rbx
add rax, R13

movd LAYER_FIRST_WEIGHTS_ERROR[rax], xmm0
add R12, 4
jmp WeightsErrorOutput
endWeigthsErrorOutput:
add R13, 4
jmp WeightsErrorInput
endWeightsErrorInput:




;LAYER_SECOND_WEIGHTS_ERROR	real4 LAYER_SECOND_SIZE * LAYER_FIRST_SIZE DUP(0.0)
xor R13, R13
WeightsErrorInput_second:
cmp R13,LAYER_FIRST_SIZE * 4
jge endWeightsErrorInput_second

xor R12, R12
WeightsErrorOutput_second:
cmp R12, LAYER_SECOND_SIZE * 4
jge endWeigthsErrorOutput_second
xor rax, rax
mov rax, R13
mov eax, LAYER_FIRST[rax]
movd xmm0, eax
movd xmm1, LAYER_SECOND_ERROR[R12]
mulss xmm0, xmm1

mov rax, R12
push rbx
push rdx
xor rdx, rdx
mov rbx, LAYER_FIRST_SIZE 
mul rbx
pop rdx
pop rbx
add rax, R13

movd LAYER_SECOND_WEIGHTS_ERROR[rax], xmm0
add R12, 4
jmp WeightsErrorOutput_second
endWeigthsErrorOutput_second:
add R13, 4
jmp WeightsErrorInput_second
endWeightsErrorInput_second:





;LAYER_SECOND_WEIGHTS_ERROR	real4 LAYER_SECOND_SIZE * LAYER_OUTPUT_WEIGHTS_ERROR DUP(0.0)
xor R13, R13
WeightsErrorInput_third:
cmp R13,LAYER_SECOND_SIZE * 4
jge endWeightsErrorInput_third

xor R12, R12
WeightsErrorOutput_third:
cmp R12, LAYER_OUTPUT_SIZE * 4
jge endWeigthsErrorOutput_third
xor rax, rax
mov rax, R13
mov eax, LAYER_SECOND[rax]
movd xmm0, eax
movd xmm1, LAYER_OUTPUT_ERROR[R12]
mulss xmm0, xmm1

mov rax, R12
push rbx
push rdx
xor rdx, rdx
mov rbx, LAYER_SECOND_SIZE 
mul rbx
pop rdx
pop rbx
add rax, R13

movd LAYER_OUTPUT_WEIGHTS_ERROR[rax], xmm0
add R12, 4
jmp WeightsErrorOutput_third
endWeigthsErrorOutput_third:
add R13, 4
jmp WeightsErrorInput_third
endWeightsErrorInput_third:


;done done done done done done done done done done 
;update weigths and biases!!!!
;	LAYER_SECOND_WEIGHTS	real4 LAYER_SECOND_SIZE * LAYER_FIRST_SIZE DUP(0.0)
	
call NN_UpdateWeights


pop rcx
add rcx, 4
jmp gameLoop
endFun:

ret

NN_calculateOutputError endp


NN_UpdateWeights proc


xor R13, R13
;LAYER_FIRST_WEIGHTS		real4 LAYER_FIRST_SIZE * LAYER_INPUT_SIZE DUP(0.0)
;	LAYER_SECOND_WEIGHTS	real4 LAYER_SECOND_SIZE * LAYER_FIRST_SIZE DUP(0.0)
;	LAYER_OUTPUT_WEIGHTS	real4 LAYER_OUTPUT_SIZE * LAYER_SECOND_SIZE DUP(0.0)
;
;	LAYER_FIRST_WEIGHTS_ERROR		real4 LAYER_FIRST_SIZE * LAYER_INPUT_SIZE DUP(0.0)
;	LAYER_SECOND_WEIGHTS_ERROR	real4 LAYER_SECOND_SIZE * LAYER_FIRST_SIZE DUP(0.0)
;	LAYER_OUTPUT_WEIGHTS_ERROR	real4 LAYER_OUTPUT_SIZE * LAYER_SECOND_SIZE DUP(0.0)

CurrLoop:
cmp R13, LAYER_FIRST_SIZE * LAYER_INPUT_SIZE * 4
jge nextLoop
movd xmm0, LAYER_FIRST_WEIGHTS[R13]
movd xmm1, LAYER_FIRST_WEIGHTS_ERROR[R13]
mulss xmm1, learningRate
subss xmm0,xmm1
movd LAYER_FIRST_WEIGHTS[R13],xmm0
add R13, 4
jmp CurrLoop
nextLoop:
xor R13, R13

CurrLoop1:
cmp R13, LAYER_SECOND_SIZE * LAYER_FIRST_SIZE * 4
jge nextLoop1
movd xmm0, LAYER_SECOND_WEIGHTS[R13]
movd xmm1, LAYER_SECOND_WEIGHTS_ERROR[R13]
mulss xmm1, learningRate
subss xmm0,xmm1
movd LAYER_SECOND_WEIGHTS[R13],xmm0
add R13, 4
jmp CurrLoop1
nextLoop1:
xor R13, R13

CurrLoop2:
cmp R13, LAYER_OUTPUT_SIZE * LAYER_SECOND_SIZE * 4
jge nextLoop2
movd xmm0, LAYER_OUTPUT_WEIGHTS[R13]
movd xmm1, LAYER_OUTPUT_WEIGHTS_ERROR[R13]
mulss xmm1, learningRate

subss xmm0,xmm1
movd LAYER_OUTPUT_WEIGHTS[R13],xmm0
add R13, 4
jmp CurrLoop2
nextLoop2:
xor R13, R13

CurrLoop3:
cmp R13, LAYER_OUTPUT_SIZE * 4
jge nextLoop3
movd xmm0, LAYER_OUTPUT_BIAS[R13]
movd xmm1, LAYER_OUTPUT_ERROR[R13]
mulss xmm1, learningRate

subss xmm0,xmm1
movd LAYER_OUTPUT_BIAS[R13],xmm0
add R13, 4
jmp CurrLoop3
nextLoop3:
xor R13, R13

CurrLoop4:
cmp R13, LAYER_SECOND_SIZE * 4
jge nextLoop4
movd xmm0, LAYER_SECOND_BIAS[R13]
movd xmm1, LAYER_SECOND_ERROR[R13]
mulss xmm1, learningRate

subss xmm0,xmm1
movd LAYER_SECOND_BIAS[R13],xmm0
add R13, 4
jmp CurrLoop4
nextLoop4:

xor R13, R13
CurrLoop5:
cmp R13, LAYER_FIRST_SIZE * 4
jge nextLoop5
movd xmm0, LAYER_FIRST_BIAS[R13]
movd xmm1, LAYER_FIRST_ERROR[R13]
mulss xmm1, learningRate

subss xmm0,xmm1
movd LAYER_FIRST_BIAS[R13],xmm0
add R13, 4
jmp CurrLoop5
nextLoop5:

ret

NN_UpdateWeights endp






testo proc
mov R8, 0
xor rax, rax
beg:
cmp R8, 27
je endpo
mov al, INPUT[R8]
add R8, 1
jmp beg
endpo:
ret
testo endp
end

