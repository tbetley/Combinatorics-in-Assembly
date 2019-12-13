TITLE program6b

;// Author:	Tyler Betley
;// OSU Email: betleyt@oregonstate.edu
;// CS271-400
;// Program 6B
;// Due: 12/10/2019
;// Description: This program is a combonitronics game. The user is asked to calculate 
;//		the number of combinations of R items taken from a set of N items. The program 
;//		uses low level IO operations to recieve input from the keyboard, convert it to
;//		numerical form, and verify the input. The program also uses recursion to determine
;//		the given combinations.

;// include directories
INCLUDE Irvine32.inc

;// ************************
;// ******** MACROS ********
;// ************************

;// ******** mWriteString *********
;// Description: Write a string using IRVINE WriteString
;// Registers Used: None
;// Preconditions: Pass OFFSET of the desired string as a parameter.
mWriteString	MACRO string
		push	edx
		mov		edx, string
		call	WriteString
		pop		edx
ENDM


;// constants
minN	EQU 3		;// minimum and maximum sizes of N
maxN	EQU 12


;// ********************************
;// ********** Data Block **********
;// ********************************
.data
intro_1		BYTE	"Combinations Calculator", 0
intro_2		BYTE	"Implementation by Tyler Betley", 0
instruct	BYTE	"Combination problems will be displayed, enter your answer after each prompt.", 0
ex_prompt	BYTE	"**EC: Numbers Problems and Keeps Score", 0
n			DWORD	?	;// number of elements in the set
r			DWORD	?	;// number of elements to choose from the set n
probNum		DWORD	1	;// accumulator for problem number
score		DWORD	0	;// accumulator for the score
result		DWORD	?	;// calculated result of the combination
answer		DWORD	?	;// user entered answer
prob_1		BYTE	"Problem: ", 0
prob_2		BYTE	"Number of elements in the set: ", 0
prob_3		BYTE	"Number of elements to choose from set: ", 0
prompt_1	BYTE	"How many ways can you choose? ", 0
buffer		BYTE	6 DUP (?)	;// buffer holds user input from ReadString
error_1		BYTE	"Error, Invalid input - Try Again: ", 0
res_1		BYTE	"There are ", 0
res_2		BYTE	" combinations of ", 0
res_3		BYTE	" items from a set of ", 0
res_win		BYTE	"Correct!!!", 0
res_lose	BYTE	"Incorrect!", 0
res_score1	BYTE	"Total Number of Questions: ", 0
res_score2  BYTE	"Number of Questions You Answered Correctly: ", 0
cont_prmpt	BYTE	"Would you like to play again? (y/n): ", 0
cont_flag	DWORD	?	;// set to 1 when user requests to exit program, else 0


;// ***************************************
;// ********** Instruction Block **********
;// ***************************************
.code
main PROC

	call	Randomize			;// generate random seed for future use

	push	OFFSET ex_prompt
	push	OFFSET intro_1
	push	OFFSET intro_2
	push	OFFSET instruct
	call	Introduction		;// write program instructions to screen

	call	crlf

NewProblem:
	;// show new problem
	push	probNum
	push	OFFSET prob_1
	push	OFFSET prob_2
	push	OFFSET prob_3
	push	OFFSET n
	push	OFFSET r
	call	showProblem

	;// get user input and validate
	;// reset answer
	push	OFFSET error_1
	push	OFFSET buffer
	push	OFFSET prompt_1
	push	OFFSET answer
	call	getData

	;// calculate the factorial
	push	n
	push	r
	push	OFFSET result
	call	Combination

	;// compare result to user answer
	push	OFFSET score
	push	n
	push	r
	push	answer
	push	result
	push	OFFSET res_1
	push	OFFSET res_2
	push	OFFSET res_3
	push	OFFSET res_win
	push	OFFSET res_lose
	call	showResults

	;// prompt user to continue
	push	OFFSET probNum
	push	OFFSET cont_prmpt
	push	OFFSET cont_flag
	call	continuePrompt			;// sets cont_flag for exit condition
	cmp		cont_flag, 0
	je		NewProblem

	;// display final results
	push	OFFSET res_score1
	push	OFFSET res_score2
	push	probNum
	push	score
	call	DisplayResults

exit
main ENDP



;// ********************************
;// ********** PROCEDURES **********
;// ********************************

;// ********** Introduction **********
;// Description: Displays intro text.
;// Recieves: offsets to strings of text to display
;//			[ebp + 24] = extra credit info
;//			[ebp + 20] = intro_1
;//			[ebp + 16] = intro_2
;//			[ebp + 12] = instructions
;// Returns: none
;// Preconditions: none
;// Post Conditions: none
;// Registers Changed: none
Introduction PROC USES edx
		push	ebp
		mov		ebp, esp

		mWriteString [ebp + 20]
		call	crlf
		mWriteString [ebp + 16]
		call	crlf
		mWriteString [ebp + 12]
		call	crlf
		call	crlf
		mWriteString [ebp + 24]
		call	crlf

		pop		ebp
		ret		12
Introduction ENDP



;// ********** showProblem **********
;// Description: Display problem information, set random numbers for r and n.
;// Recieves: offsets to strings of text to display, offset to r and n to store data
;//			[ebp + 36] = probNum
;//			[ebp + 32] = prob_1
;//			[ebp + 28] = prob_2
;//			[ebp + 24] = prob_3
;//			[ebp + 20] = n
;//			[ebp + 16] = r
;// Returns: none
;// Preconditions: none
;// Post Conditions: none
;// Registers Changed: none
showProblem PROC USES eax ebx
		push	ebp
		mov		ebp, esp

		;// write current problem number
		mWriteString [ebp + 32]
		mov		eax, [ebp + 36]
		call	WriteDec
		call	crlf

		;// get random number for n, set n, show n
		mov		eax, maxN
		sub		eax, minN
		call	RandomRange
		add		eax, minN
		mov		ebx, [ebp + 20]
		mov		[ebx], eax			;// sets n
		mWriteString [ebp + 28]	    ;// print display info for n
		call	WriteDec			;// prints n
		call	crlf

		;// get random number for r, set r, show r
		call	RandomRange			;// eax = n 
		inc		eax
		mov		ebx, [ebp + 16]
		mov		[ebx], eax			;// set r
		mWriteString [ebp + 24]		;// print display info for r
		call	WriteDec			;// print r
		call	crlf

		pop		ebp
		ret		24
showProblem ENDP



;// ********** getData **********
;// Description: Get and validate user data.
;// Recieves: offsets to strings of text to display, offset answer to store user data
;//			[ebp + 52] = error_1
;//			[ebp + 48] = buffer
;//			[ebp + 44] = prompt_1
;//			[ebp + 40] = answer
;// Returns: none
;// Preconditions: none
;// Post Conditions: none
;// Registers Changed: none
getData PROC
		pushad					;// save all registers, add 32 to base pointer
		push	ebp
		mov		ebp, esp
		
		;// reset buffer
		mov		ecx, 6
		mov		edi, [ebp + 48]
		mov		al, 0
		cld
		rep		stosb
		;// reset answer
		mov		eax, [ebp + 40]
		mov		ebx, 0
		mov		[eax], ebx

		mWriteString [ebp + 44]		;// display the prompt to the user
	
	tryInput:
		;// get input
		mov		edx, [ebp + 48]			;// edx points to the buffer
		mov		ecx, 6					;// ecx is the counter of the size of the buffer
		call	ReadString				;// unput read into [ebp + 16], number of inputs held in eax

		;// validate input
		cmp		eax, 6
		jg		Error			;// retry if too many inputs entered

		mov		ecx, eax		;// moves number of entered values into ecx, counter
		mov		esi, edx		;// esi now points to the input buffer
		dec		eax
		add		esi, eax		;// point esi to end of the buffer
		mov		eax, 1			;// eax is the place counter
		mov		ebx, [ebp + 40]	;// ebx = OFFSET answer
		mov		edx, 0			;// set edx to 0

	ValidateLoop:
		mov		dl, BYTE PTR [esi]		;// edi contains current value
		sub		dl, 48d			;// subtract ascii value
		cmp		dl, 0
		jl		Error
		cmp		dl, 9
		jg		Error
		push	eax				;// save place counter
		mul		edx				;// eax * [esi]: eax contains the ten place to determine the integer value
		add		[ebx], eax		;// answer + eax
		pop		eax
		push	ebx				;// save ebx
		mov		ebx, 10
		mul		ebx				;// multiply eax by 10
		pop		ebx				;// restore ebx
		dec		esi				;// point esi to next value
		loop	ValidateLoop	;// loop back

		jmp		ExitgetData

	Error:
		;// print error
		mWriteString [ebp + 52]
		mov		eax, 0
		mov		[ebx], eax		;// reset answers
		jmp		tryInput

	ExitgetData:
		pop		ebp
		popad					;// restore all registers
		ret		16
getData ENDP



;// ********** Combination **********
;// Description: Calculates the combination of n choose r using calls to the recursive factorial procedure.
;// Recieves: values of n and r, and pointer to result.
;//			[ebp + 48] = n
;//			[ebp + 44] = r
;//			[ebp + 40] = OFFSET result
;//			[ebp - 4] = Nfact
;//			[ebp - 8] = Rfact
;//			[ebp - 12] = NRfact
;// Returns: none
;// Preconditions: none
;// Post Conditions: changes value of result
;// Registers Changed: none
Combination PROC
		pushad
		push	ebp
		mov		ebp, esp
		sub		esp, 12			;// make room for locals


		;// make calls to factorial
		mov		eax, [ebp + 48]
		mov		[ebp - 4], eax	;// n! = n
		lea		eax, [ebp - 4]	;// load address of Nfact into eax
		push	eax				;// push address of Nfact on stack
		push	[ebp + 48]		;// = n
		call	Factorial		;// returns eax = n!
	
		mov		eax, [ebp + 44]
		mov		[ebp - 8], eax	;// move r into Rfact
		lea		eax, [ebp - 8]	;// load address of Rfact in eax
		push	eax				;// push address of Rfact on stack
		push	[ebp + 44]		;// = r
		call	Factorial		;// returns eax = r!

		mov		eax, [ebp + 48]
		sub		eax, [ebp + 44]	
		mov		[ebp - 12], eax	;// = n-r
		lea		eax, [ebp - 12]	;// load address of NRfact into eax
		push	eax				;// push address of NRfact onto stack
		push	[eax]			;// push value of n-r on stack
		call	Factorial		;// eax = (n-r)!
		
		;// perform multiplication/division to get result
		mov		eax, [ebp - 12]
		mov		ebx, [ebp - 8]	;// ebx = r!
		mov		edx, 0			;// set edx for overflow of multiplication
		mul		ebx				;// eax * ebx = (n-r)! * r! = edx/eax

		mov		ebx, eax		;// ebx = r!(n-r)!
		mov		eax, [ebp - 4]	;// eax = n!
		div		ebx				;// eax = n!/(n!(n-r)!)

		;// set result
		mov		ebx, [ebp + 40]
		mov		[ebx], eax

		mov		esp, ebp
		pop		ebp
		popad
		ret		12
Combination ENDP



;// ********** Factorial **********
;// Description: Calculates the factorial of the integer in eax.
;// Recieves: value in eax and ebx
;//			[ebp + 24] = address of factorial local
;//			[ebp + 20] = ebx, next value
;// Returns: factorial in eax
;// Preconditions: none
;// Post Conditions: none
;// Registers Changed: none
Factorial PROC USES ebx eax edi
		push	ebp
		mov		ebp, esp
		
		mov		edi, [ebp + 24]	;// load address of factorial into edi
		mov		eax, [edi]		;// dereference factorial
		mov		ebx, [ebp + 20]	;// move next value into ebx
		;// handle 0!
		cmp		eax, 0
		je		zeroFact

		dec		ebx
		cmp		ebx, 0
		je		ExitFact		;// base case
		mul		ebx				;// eax * ebx = eax
		mov		[edi], eax		;// update factorial
		push	edi
		push	ebx
		call	Factorial		;// recursive case
		jmp		ExitFact

	zeroFact:
		mov		eax, 1
		mov		[edi], eax

	ExitFact:
		pop		ebp
		ret		8
Factorial ENDP



;// ********** showResults **********
;// Description: Shows the results of the program
;// Recieves: 
;//				[ebp + 44] OFFSET score
;//				[ebp + 40]	n
;//				[ebp + 36]	r
;//				[ebp + 32]	answer
;//				[ebp + 28]	result
;//				[ebp + 24]	OFFSET res_1
;//				[ebp + 20]	OFFSET res_2
;//				[ebp + 16]	OFFSET res_3
;//				[ebp + 12]	OFFSET res_win
;//				[ebp + 8]	OFFSET res_lose
;// Returns: factorial in eax
;// Preconditions: none
;// Post Conditions: none
;// Registers Changed: none
showResults PROC
		push	ebp
		mov		ebp, esp
		pushad

		;// write the answer
		mWriteString [ebp + 24]
		mov		eax, [ebp + 28]
		call	WriteDec
		mWriteString [ebp + 20]
		mov		eax, [ebp + 36]
		call	WriteDec
		mWriteString [ebp + 16]
		mov		eax, [ebp + 40]
		call	WriteDec
		call	crlf

		;// compare answer to result
		mov		eax, [ebp + 28]
		cmp		eax, [ebp + 32]
		je		Correct

	Incorrect:
		mWriteString [ebp + 8]		;// print losing prompt
		jmp		ExitResults

	Correct:	
		mWriteString [ebp + 12]		;// print winning prompt
		mov		eax, [ebp + 44]
		mov		ebx, [eax]			;// increment score
		inc		ebx
		mov		[eax], ebx

	ExitResults:
		
		call	crlf

		popad
		pop		ebp
		ret		36
showResults ENDP



;// ********** continePrompt **********
;// Description: Shows the results of the program
;// Recieves: 
;//				[ebp + 48]  OFFSET probNum
;//				[ebp + 44]  OFFSET cont_prmpt
;//				[ebp + 40]	OFFSET cont_flag
;// Returns: none
;// Preconditions: none
;// Post Conditions: changes value of cont_flag
;// Registers Changed: none
continuePrompt PROC
		pushad
		push	ebp
		mov		ebp, esp
		sub		esp, 4

	RePrompt:
		mWriteString [ebp + 44]		;// write the prompt
		lea		edx, [ebp - 4]		;// edx points to the buffer
		mov		ecx, 2				;// fill buffer with two bytes
		call	ReadString
		lea		edx, [ebp - 4]
		mov		al, BYTE PTR [edx]
		cmp		eax, 121			;// compare with 'y'
		je		KeepPlaying
		cmp		eax, 110			;// compare with 'n'
		je		QuitPlaying
		jmp		RePrompt

	KeepPlaying:
		;// set control flag to zero
		mov		eax, [ebp + 40]
		mov		ebx, [eax]
		mov		ebx, 0
		mov		[eax], ebx

		;// increment problem number
		mov		eax, [ebp + 48]
		mov		ebx, [eax]
		inc		ebx				;// increment problem number
		mov		[eax], ebx

		jmp		ExitContPrompt

	QuitPlaying:
		;// set control flag to 1
		mov		eax, [ebp + 40]
		mov		ebx, [eax]
		mov		ebx, 1
		mov		[eax], ebx
		
	ExitContPrompt:
		call	crlf
		mov		esp, ebp
		pop		ebp
		popad
		ret		8
continuePrompt ENDP



;// ********** DisplayResults **********
;// Description: Shows the results of the program
;// Recieves: 
;//				[ebp + 52]	OFFSET res_score1
;//				[ebp + 48]	OFFSET res_score2
;//				[ebp + 44]	probNum
;//				[ebp + 40]	score
;// Returns: none
;// Preconditions: none
;// Post Conditions: changes value of cont_flag
;// Registers Changed: none
DisplayResults PROC
		pushad
		push	ebp
		mov		ebp, esp

		mWriteString [ebp + 52]
		mov		eax, [ebp + 44]
		call	WriteDec
		call	crlf

		mWriteString [ebp + 48]
		mov		eax, [ebp + 40]
		call	WriteDec
		call	crlf

		pop		ebp
		popad
		ret		12
DisplayResults ENDP

END		main