TITLE BucketFiller     (abreu_assignment05.asm)
; Author: James Cameron Abreu
; Course: CS271-400
; Project ID: Assignment 05
; Date: 02/23/2017	
; Description: This program is an example of how to get user input, process arrays, 
;  generate seudo-random integers, and sort an array using a selection sort. It uses 
;  the popular Irvine32 library for displaying to the screen and generating 
;  seudo-random numbers.

; INCLUDE FILES -------------------------------------------------------------------------
INCLUDE Irvine32.inc


; LINE NUMBERS: (for cool folks that 'gg' to lines in vim)------|
;																|
;	constants.......................35							|
;	.data...........................65							|
;																|
;	PROCEDURES (tab implies nested usage):						|
;		MAIN........................125							|
;		Introduction................175							|
;		getData.....................220							|
;			validate................280							|
;		fillArray...................325							|
;		sortList....................365							|
;			getTrueIndex (unused)...560							|
;			exchangeElements........600							|
;		displayMedian...............645							|
;		displayList.................740							|
;			newLine.................785							|
;----------------------------------------------------------------


; CONSTANTS -----------------------------------------------------------------------------
; user request:
MIN = 10
MAX = 200

; random integer range:
LO = 100
HI = 999

; numbers per line:
NUM_PER_LINE = 10

; Program name:
PROGRAM_NAME EQU <"Bucket Filler, an array processing program by James Cameron Abreu", 0>

; Selection Sort local variables:
SORT_OUTER		EQU DWORD PTR [ebp - 4]
SORT_INNER		EQU DWORD PTR [ebp - 8]
SORT_MININDEX	EQU DWORD PTR [ebp - 12]
SORT_TRUEINDEX_INNER	EQU DWORD PTR [ebp - 16]
SORT_TRUEINDEX_MIN		EQU DWORD PTR [ebp - 20]
SORT_TRUEINDEX_OUTER	EQU DWORD PTR [ebp - 24]
; END CONSTANTS -------------------------------------------------------------------------






; DATA ----------------------------------------------------------------------------------
.data
; PROCEDURE ORGANIZED DATA:
; main
request				DWORD		?
array				DWORD		MAX		DUP(?)

; introduction
intro_title			BYTE		PROGRAM_NAME
intro_description	BYTE		"Description: Bucket Filler is an example program to process "
					BYTE		"array elements and generate random numbers. It also sorts " 
					BYTE		"those elements using a selection sort algorithm. ", 0
intro_between1		BYTE		"The random numbers are generated with a suedo-random number "
					BYTE		"generator between the integers ", 0
intro_between2		BYTE		" and ", 0
intro_between3		BYTE		". ", 0



; get data
getData_prompt1		BYTE		"Please provide the size of the array (positive integer between ", 0
getData_prompt2		BYTE		" and ", 0 ; between MIN and MAX
getData_prompt3		BYTE		"): ", 0

; validate
validate_invalid	BYTE		"The input you have provided is invalid. ", 0

; display median
main_median			BYTE		"Median of values in array: ", 0

; display list
message_unsorted	BYTE		"Array of seudo-randomly filled integers (unsorted): ", 0
message_sorted		BYTE		"Array values after sorting using a selection-sort algorithm:", 0

; The following procedures do not use any special data:
; fill array
; sort list
; exchange elements
; newLine


; DEBUG data!
DB_debug				BYTE		"DEBUG: ", 0
DB_space				BYTE		" ", 0
DB_comma				BYTE		",", 0
DB_commaSpace			BYTE		", ", 0
DB_testDWORD			DWORD		19	

DB_TAB					BYTE		9, 0
DB_OUTER				BYTE		"OUTER: ", 0
DB_INNER				BYTE		"INNER: ", 0
DB_VALMIN				BYTE		"array[min]: ", 0
DB_VALOUTER				BYTE		"array[outer]: ", 0
DB_UPDATEMIN			BYTE		"Min was updated.", 0





; CODE ----------------------------------------------------------------------------------
.code
main PROC

	; display program information
	call	introduction ; no need for stack pushes, just makes main cleaner

	; get user data and validate
	push	OFFSET request ; get array size from user (passed by reference)
	push	OFFSET getData_prompt1
	push	OFFSET getData_prompt2
	push	OFFSET getData_prompt3
	push	OFFSET validate_invalid
	call	getData

	; fill array
	push	OFFSET array ; array to store elements (pass by reference)
	push	request ; number of elements to fill (pass by value)
	call	fillArray ; pops 8 before return

	; display unsorted list:
	push	OFFSET array
	push	request
	push	OFFSET message_unsorted
	call	displayList

	; sort list
	PUSH	OFFSET array ; argument by reference
	PUSH	request ; argument by value
	call	sortList ; uses exchange elements proc, pops 8 before return

	; display median
	mov		edx, OFFSET main_median
	call	WriteString
	push	OFFSET array
	push	request
	call	displayMedian ; pops 8 before return
	call	CrLf
	call	CrLf

	; display updated sorted list:
	push	OFFSET array
	push	request
	push	OFFSET message_sorted
	call	displayList

	exit	; exit to operating system
main ENDP




; ------------------------------------------------------------------
introduction PROC
;
; Description: Displays the title, program description, and program 
;  limits using the Irvine32 library functions.
; Receives: 
; Returns: 
; Registers Modified:
; ------------------------------------------------------------------
	PUSHAD	

; Title
	MOV		EDX, OFFSET intro_title	
	CALL	writeString
	CALL	CrLf
	CALL	CrLf

; Program Description:
	MOV		EDX, OFFSET intro_description
	CALL	writeString

	MOV		EDX, OFFSET intro_between1
	CALL	writeString
	MOV		EAX, LO 
	CALL	writeDec
	MOV		EDX, OFFSET intro_between2
	CALL	writeString
	MOV		EAX, HI 
	CALL	writeDec
	MOV		EDX, OFFSET intro_between3
	CALL	writeString
	CALL	CrLf
	CALL	CrLf

	POPAD
	ret
introduction ENDP








; ------------------------------------------------------------------
getData PROC ; validation included
;
; Description: prompts the user to enter the amount of elements the 
;  array of random integers will hold. Input validation is performed 
;  in the form of boundary checking. 
; Parameters in order of push: arraySize (reference, DWORD, +52),
;  prompt1 (reference, DWORD, +48), prompt2 (reference DWORD, +44), 
;  prompt3 (reference, DWORD, +40), invalidMessage (reference, DWORD, +36)
; Receives: none. all on stack
; Returns: nothing. Stack pops all values.
; Registers Modified: none. pushad and popad used.
; ------------------------------------------------------------------
	pushad ; 32 bytes pushed onto stack

	mov		ebp, esp
	mov		ebx, [ebp + 52] ; POINTER to our arraySize in edx
							; (remember to dereference later)

	GET_INPUT:
								; instructions:
		mov		edx, [ebp + 48] ; between:
		call	writeString
		mov		eax, MIN		; min
		call	writeDec
		mov		edx, [ebp + 44] ; and
		call	writeString
		mov		eax, MAX		; max
		call	writeDec
		mov		edx, [ebp + 40]
		call	writeString
		
		; get input from user, store in our dereferenced pointer
		call	readInt
		mov		[ebx], eax ; store in DEREFERENCED pointer for array size

		; input validation on number:
		push	[ebx] ; array size (passed by value)
		push	[ebp + 36] ; invalid message
		call	validate ; validate returns eax as a bool: 0 for invalid, 1 for valid 

		; check return value:
		cmp		eax, 0
		je		GET_INPUT

	popad ; 32 bytes popped from stack
	ret	
getData ENDP 












; ------------------------------------------------------------------
validate PROC
;
; Description: validates the users input by performing bounds checking. 
; Parameters as pushed: userInput (passed by value, +12), 
;  invalid message (reference, DWORD, +8)
; Receives: 
; Returns: eax contains 0 if invalid, 1 if true
; Registers Modified: eax, edx, ecx
; ------------------------------------------------------------------
	push	ebp ; prevent nested calling from ruining our calling proc ebp
	mov		ebp, esp
	
	mov		eax, [ebp + 12]

	cmp		eax, MIN
	jb		INVALID
	
	cmp		eax, MAX
	ja		INVALID

	; bounds checking okay
	jmp		VALID

	INVALID:
	mov		edx, [ebp + 8]
	call	writeString
	call	CrLf
	mov		eax, 0
	jmp		RETURN_VALIDATION

	VALID:
	mov		eax, 1

	RETURN_VALIDATION:
		pop		ebp
		ret		8
validate ENDP







; ------------------------------------------------------------------
fillArray PROC
;
; Description: Fills an array with a random sequence of 32 bit 
;  unsigned integers between the global constants LO and HI. 
; Parameters in order of push: arraySize (value, DWORD, +36), 
;  array (reference, DWORD, +40)
; Receives: parameters on the stack
; Returns: parameters passed by reference are modified.No registers 
;  are returned. 
; Registers Modified: none (pushad used)
; ------------------------------------------------------------------
	pushad ; 32 bytes pushed onto stack

	mov		ebp, esp		; ebp already pushed, no need to push again
	mov		ecx, [ebp + 36] ; our arraySize in ecx
	mov		edi, [ebp + 40] ; starting address of our array

	call	randomize		; random seed

	; the following was written with the help of page 382 of our textbook:
	; Assembly Language for x86 Processors, seventh edition, Irvine
	mov		edx, HI
	sub		edx, LO			; EDX = absolute range (0...n)
	cld						; clear direction flag (used for stosd functionality)
	
	fillElement:
		mov		eax, edx	; get absolute range
		call	randomRange
		add		eax, LO		; bias the result
		stosd				; store eax into [edi], increment edi by 4 bytes
		loop	fillElement

	popad
	ret		8 ; two DWORD parameters = 4 + 4
fillArray ENDP






; ------------------------------------------------------------------
sortList PROC
;
; Description: uses exchangeElements procedure. This is my own take on 
;  writing a selection sort in assembly. 
; Parameters in order of push: array (reference, DWORD) 
;  arraySize (value, DWORD), 
; Receives: 
; Returns: 
; Registers Modified:
; ------------------------------------------------------------------
	pushad ; 32 bytes pushed onto stack
	mov		ebp, esp		; ebp already pushed, no need to push again
	sub		esp, 24			; 3 local DWORD variables (with symbolic constants):
							; SORT_OUTER = DWORD PTR [ebp - 4] is my inner for loop counter

							; SORT_INNER = DWORD PTR [ebp - 8] is my outter for loop counter
							; SORT_MININDEX	 = DWORD PTR [ebp - 12] is a min value variable

							; SORT_TRUEINDEX_INNER = DWORD PTR [ebp - 16] is the true amount of bytes 
							;  to add to edi in order to get the element we want: array[innerIndex]

							; SORT_TRUEINDEX_MIN = DWORD PTR [ebp - 20] is the true amount of bytes to 
							;  add to edi in order to get the element we want: array[minIndex]

							; SORT_TRUEINDEX_OUTER = DWORD PTR [ebp - 24] is the true amount of bytes
							;  to add to edi in order to get the element we want: array[outerIndex]

							; Parameter variables:
							; [ebp + 36] ; our arraySize 
	mov		edi, [ebp + 40] ; starting address of our array in edi

	; setup:
	mov	SORT_OUTER, 0


	SORT_OUTER_FORLOOP:
		; innerloop starts with outer loops value:
		mov		edx, SORT_OUTER
		mov		SORT_INNER, edx


		; DEBUG
		; COMMENT	! ;----------------------------------------------------------
		; Description: Display inner and outer loop vales at each outer pass	;
		; outer:																;
		;mov		edx, OFFSET DB_OUTER										;
		;call	writeString														;
		;mov		eax, SORT_OUTER												;
		;call	writeDec														;
		;mov		edx, OFFSET DB_TAB											;
		;call	writeString														;
		; inner:																;
		;mov		edx, OFFSET DB_INNER										;
		;call	writeString														;
		;mov		eax, SORT_INNER												;
		;call	writeDec														;
		;mov		edx, OFFSET													;
		; ! ;--------------------------------END DEBUG---------------------------



		; index for min is also set to outer loop:
		mov		edx, SORT_OUTER
		mov		SORT_MININDEX, edx

		SORT_INNER_FORLOOP:

			; get true index for minIndex
			mov		eax, SORT_MININDEX
			mov		ebx, 4 ; for DWORD
			mul		ebx
			mov		SORT_TRUEINDEX_MIN, eax ; minIndex VALUE stored in esi

			; get true index for innerLoop
			mov		eax, SORT_INNER
			mov		ebx, 4 ; for DWORD
			mul		ebx
			mov		SORT_TRUEINDEX_INNER, eax

			; if (array[indexMin) > array[y]
			mov		edx, SORT_TRUEINDEX_MIN
			mov		ebx, SORT_TRUEINDEX_INNER
			mov		eax, [edi + edx]
			cmp		eax, [edi + ebx]
			jbe		SORT_SKIPSETMIN

			; DEBUG
			; COMMENT	! ;----------------------------------------------------------
			; Description: Display inner and outer loop vales at each outer pass	;
			; inner:																;
			;call	CrLf															;
			;mov		edx, OFFSET DB_TAB											;
			;call	writeString														;
			;mov		edx, OFFSET DB_TAB											;
			;call	writeString														;
			;mov		edx, OFFSET DB_INNER										;
			;call	writeString														;
			;mov		eax, SORT_INNER												;
			;call	writeDec														;
			;mov		edx, OFFSET DB_TAB											;
			;call	writeString														;
			;mov		edx, OFFSET DB_UPDATEMIN									;
			;call	writeString														;
			;mov		edx, OFFSET													;
			; ! ;--------------------------------END DEBUG---------------------------

			; NEW MINIMUM index! 
			;indexOfMin = INNERLOOP	
			mov		eax, SORT_INNER
			mov		SORT_MININDEX, eax

			SORT_SKIPSETMIN:

				; inner++, if inner < size of array loop again
				inc		SORT_INNER
				mov		edx, SORT_INNER
				cmp		edx, [ebp + 36]
				jb		SORT_INNER_FORLOOP ; loop: inner

		; code BEFORE looping outer:

			; Swap the array[outer loop index] and array[index of min]:
			; PREPARATION--------------------------
			; get true index for minIndex (how many bytes from array start address?)
			mov		eax, SORT_MININDEX
			mov		ebx, 4 ; for DWORD
			mul		ebx
			mov		SORT_TRUEINDEX_MIN, eax

			; get true index for outer loop index (how many bytes from array start address?)
			mov		eax, SORT_OUTER
			mov		ebx, 4 ; for DWORD
			mul		ebx
			mov		SORT_TRUEINDEX_OUTER, eax


			; pass array[minIndex] onto stack by reference
			mov		eax, edi
			mov		edx, SORT_TRUEINDEX_MIN
			add		eax, edx
			push	eax ; passed by reference
			; DEBUG
			 ;COMMENT	! ; ---------------------------------------------------------
			; Description: real value of array[minIndex]							;
			;mov		edx, OFFSET DB_TAB											;
			;call	writeString														;
			;mov		edx, OFFSET DB_VALMIN										;
			;call	writeString														;
			;mov		eax, [eax]	;dereference									;	
			;call	writeDec														;
			 ;! ;--------------------------------END DEBUG---------------------------

			; pass array[outerIndex] onto stack by reference
			mov		eax, edi
			mov		edx, SORT_TRUEINDEX_OUTER
			add		eax, edx
			push	eax ; passed by reference
			; DEBUG
			 ;COMMENT	! ; ---------------------------------------------------------
			; Description: real value of array[outer];								;
			;mov		edx, OFFSET DB_TAB											;
			;call	writeString														;
			;mov		edx, OFFSET DB_VALOUTER										;
			;call	writeString														;
			;mov		eax, [eax]	; dereference									;
			;call	writeDec														;
			 ;! ;--------------------------------END DEBUG---------------------------

			; swap(array[minIndex], array[outerIndex])
			call	exchangeElements

		; DEBUG
		;COMMENT	! ; ---------------------------------------------------------
		;mov		edx, OFFSET DB_TAB											;
		;call	writeString														;
		;call	waitMSG															;
		;call	CrLf															;
		;call	CrLf															;
		; ! ;--------------------------------END DEBUG---------------------------

		; outer++, if outer < size of array loop again
		inc		SORT_OUTER
		mov		edx, SORT_OUTER
		cmp		edx, [ebp + 36]
		jb		SORT_OUTER_FORLOOP	; loop: outer

	SORT_CLEANUP:
	mov		esp, ebp		; remove locals from stack
	popad
	ret		8 ; (two DWORD parameters) = 4 + 4
sortList ENDP



; ------------------------------------------------------------------
getTrueIndex PROC
;
; Description: takes in an index and returns the amount of bytes to jump
; Parameters in order of push: index (DWORD, value, +44),
;  sizeOfData (DWORD, value, +40), trueIndex (DWORD, reference, +36)
; Receives: 
; Returns: amount of bytes to jump is left on the stack to be popped (DWORD)
; Registers Modified: none, pushad and popad used
; ------------------------------------------------------------------
	pushad
	mov		ebp, esp		; ebp already pushed, no need to push again

	; eax will be our returned accumulator (the actual bytes needed to jump):
	mov		eax, 0

	; ecx will contain our passed in index:
	mov		ecx, [ebp + 44]

	; ebx will contain the size of the data type
	mov		ebx, [ebp + 40]

	; tally our true size:
	TRUEINDEX_ADD:
		add		eax, ebx
		LOOP	TRUEINDEX_ADD

	; store accumulator:
	mov		edx, [ebp + 36]
	mov		[edx], eax		; store accumulator (the real amount of bytes to jump)
							;  into the dereferenced value of the parameter

	popad
	ret		 12; three DWORD parameters = 4 + 4 + 4
getTrueIndex ENDP





; ------------------------------------------------------------------
exchangeElements PROC
;
; Description:
; Parameters: array[i] (reference, DWORD), array[j] (reference, DWORD), where 
;  i and j are elements to be exchanged.
; Receives: 
; Returns: 
; Registers Modified:
; ------------------------------------------------------------------
	pushad
	mov		ebp, esp		; ebp already pushed, no need to push again
	sub		esp, 4			; 1 local variable DWORD
							;DWORD PTR [ebp - 4] is my temp variable

							; [ebp + 36] ; our value of array[minIndex]
							; [ebp + 40] is our value of array[outerIndex]

	; temp = array[outerIndex]
	mov		ebx, [ebp + 40]
	mov		eax, [ebx] ; dereference
	mov		[ebp - 4], eax

	; array[outer] = array[minIndex]
	mov		eax, [ebp + 40] ; outer pointer
	mov		ebx, [ebp + 36] ; min pointer
	mov		edx, [ebx] ; VALUE of min
	mov		[eax], edx ; VALUE of OUTER = value of min

	; array[minIndex] = temp
	mov		eax, [ebp - 4]
	mov		edx, [ebp + 36]
	mov		[edx], eax

	mov		esp, ebp		; remove locals from stack
	popad
	ret		8 ; two DWORD parameters = 4 + 4
exchangeElements ENDP






; ------------------------------------------------------------------
displayMedian PROC
;
; Description:
; Parameters in order of push:  array (reference, DWORD + 40), arraySize (value, DWORD, +36)
; Receives: 
; Returns: none, all parameters popped before return.
; Registers Modified:
; ------------------------------------------------------------------
	pushad
	mov		ebp, esp		; ebp already pushed, no need to push again
	sub		esp, 12			; 1 local variable DWORD
							; [ebp - 4] is used for ACTUAL BYTES to jump in array
							; [ebp - 8] is used for even cases: MIDDLE1
							; [ebp - 12] is used for even cases: MIDDLE2

	mov		esi, [ebp + 40]

	; divide number of elements by 2 to check parity
	mov		edx, 0
	mov		eax, [ebp + 36]
	mov		ebx, 2
	div		ebx
	; eax contains quotient, edx contains remainder

	; Check parity
	cmp		edx, 0
	je		MEDIAN_EVEN

	; CASE: ODD AMOUNT OF NUMBERS-----------------------
	; multiply to get actual bytes in array to access:
	; just use the quotient (eax is index)
	mov		ebx, 4 ; for DWORD
	mul		ebx

	; access the correct element:
	mov		ebx, eax
	mov		eax, esi ; starting address of array
	add		eax, ebx ; add true offset from index

	mov		ebx, [eax] ; dereferenced
	mov		[ebp - 4], ebx
	jmp	MEDIAN_DISPLAY

	; CASE: EVEN AMOUNT OF NUMNBER-----------------------
	MEDIAN_EVEN:
	
		; overall: add two middle numbers and divide by 2.
		; first number find address and store in [ebp - 8]
			; eax is previous quotient:
			dec		eax	; array elements start at index 0, not 1

			; multiply to get actual bytes in array to access:
			; just use the quotient (eax is index)
			mov		ebx, 4 ; for DWORD
			mul		ebx

			; access the correct element:
			mov		ebx, eax
			mov		eax, esi ; starting address of array
			add		eax, ebx ; add true offset from index

			mov		ebx, [eax] ; dereferenced
			mov		[ebp - 8], ebx
		; second number find address and store in [ebp - 12]

			; simply shift our address over by 4
			mov		ebx, [eax + 4]
			mov		[ebp - 12], ebx

		; add two numbers together
			mov		eax, [ebp - 8]
			add		eax, [ebp - 12]

		; divide by two
		mov		edx, 0
		mov		ebx, 2
		div		ebx

		; store quotient in [ebp - 4] to be displayed:
		mov		[ebp - 4], eax

	MEDIAN_DISPLAY:
	mov		eax, [ebp - 4]
	call	writeDec

	; cleanup
	mov		esp, ebp		; remove locals from stack
	popad
	ret		8 ; two DWORD parameters = 4 + 4
displayMedian ENDP




; ------------------------------------------------------------------
displayList PROC
;
; Description: Takes in a message to display (title), and then prints out
;  all of the elements of the array.
; Parameters in order: array (reference, DWORD), arraySize (value, DWORD), 
;	title (reference, BYTE)
; Receives: parameters on the stack.
; Returns: none, all parameters popped before return.
; Registers Modified:
; ------------------------------------------------------------------
	push	ebp
	mov		ebp, esp

	mov		EDX, [ebp + 8] ; OFFSET title
	call	writeString
	call	CrLf

	mov		EDX, [ebp + 16] ; store address of array into edx
	mov		EBX, 0 ; DISTANCE from base
	mov		ECX, [ebp + 12] ; arraySize

	DisplayElement:
		mov		EAX, [EDX + EBX]
		call	writeDec

		; tab:
		mov		AL, 9
		call	writeChar

		; call newLine proc here
		push	[ebp + 12] ; arraySize
		call	newLine

		add		EBX, 4 ; four bytes each index increment
		loop	DisplayElement

	; cleanup and return
	call	CrLf
	call	CrLf
	pop		ebp
	ret		12 ; three DWORD parameters = 4 + 4 + 4
displayList ENDP


; ------------------------------------------------------------------
newLine PROC
;
; Description: Takes in ECX and determines if a new line needs to be 
;  printed. If so, print it. 
; Parameters: the size of the array (DWORD passed by value)
; Receives: ECX contains the CURRENT counter
; Returns: nothing (popad)
; Registers Modified: none (popad)
; ------------------------------------------------------------------
	PUSHAD
	mov		ebp, esp

	; ecx contains how many LEFT but we want how many we've already printed:
	mov		eax, [ebp + 36] ; passed in by value (our original max counter)
	sub		eax, ecx ; previous 
	inc		eax ; now ecx contains how many we've done so far

	; divide
	mov		edx, 0
	mov		ebx, NUM_PER_LINE ; global constant
	div		ebx

	; compare remainder:
	cmp		edx, 0
	jne		NEWLINE_FINISH

	; print new line:
	call	CrLf

	NEWLINE_FINISH:
		POPAD
		ret		4 ; one parameter (DWORD)
newLine	ENDP

END main
