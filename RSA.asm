TITLE RSA(RSA.asm)

COMMENT !
//	.386
//	.model flat, stdcall
//	.stack 4096
//	ExitProcess proto, dwExitCode:dword
!
INCLUDE Irvine32.inc

.DATA
	Pvalue DWORD 0
	Qvalue DWORD 0
	Mvalue DWORD 0	;// Modulus M = (P*Q)
	Tvalue DWORD 0	;// Totient ?(M) = (P-1)*(Q-1)
	ExitLoop BYTE 0
	CaseTable BYTE '1'	;// lookup value
		DWORD Input	;// address of procedure
	EntrySize = ($ - CaseTable)
		BYTE '2'
		DWORD PrintPQMT
		BYTE '3'
		DWORD CreatePrime
		BYTE '4'
		DWORD DispBigNum
		BYTE '5'
		DWORD Quit
	NumberOfEntries = ($ - CaseTable) / EntrySize
	mainmenu BYTE "   ----- Main Menu -----", 0dh, 0ah
		   BYTE "1. Enter the values of P & Q", 0dh, 0ah
		   BYTE "2. Print the values of P, Q, M & T", 0dh, 0ah
		   BYTE "3. Generate a random large Prime for P", 0dh, 0ah
		   BYTE "4. Display large number test", 0dh, 0ah
		   BYTE "5. Exit", 0dh, 0ah
		   BYTE "Enter your selection: ", 0
	bignum DWORD 4 DUP (0FFFFFFFFh)	;// 18,446,744,073,709,551,615
	bigsize = LENGTHOF bignum
	Parray DWORD 4 DUP (0)			;// 128 bits
	primesize = LENGTHOF Parray
	Qarray DWORD primesize DUP (0)
	Marray DWORD primesize*2 DUP (0)
	sz = TYPE Parray				;// Size of each array element
.CODE
main PROC
	call	Randomize
Start:
	mov	edx, OFFSET mainmenu	;// ask user for input
	call	WriteString
	call	ReadChar			;// read character into AL
	call	Crlf
	call	Crlf
	mov	ebx, OFFSET CaseTable	;// point EBX to the table
	mov	ecx, NumberOfEntries	;// loop counter
L1:
	cmp	al, [ebx]			;// match found ?
	jne	L2				;// no: continue
	call	NEAR PTR [ebx + 1]	;// yes: call the procedure
	cmp	ExitLoop, 0
	ja	L3				;// exit the search
	jmp	Start
L2:
	add	ebx, EntrySize		;// point to the next entry
	loop	L1				;// repeat until ECX = 0

COMMENT !
// Just an experiment
CallInput:
	call	Input
	jmp	Return
CallPrintPQMT:
	call	PrintPQMT
	jmp	Return
CallCreatePrime:
	call	CreatePrime
	jmp	Return
CallDispBigNum:
	call	DispBigNum
	jmp	Return
CallQuit:
	call	Quit
	jmp	Return
!

L3:
	exit
	;// invoke ExitProcess, 0
main ENDP

;//---------------------------------------------------------
CreatePrime PROC USES eax ecx esi edi
;// Generates a large & random prime number
;// Receives: Nothing
;// Returns: Nothing
;// --------------------------------------------------------
	call	Clrscr
	;// Generate a random number
	mov	ecx, primesize
RandomLoop:
	call	Random32
	cmp	ecx, primesize
	jne	NotFirst
	or	eax, 80000000h	;// Set the highest bit to ensure the number meets the required length
NotFirst:
	cmp	ecx, 1	;// Skip the even test if it's not the last element
	jne	NotLast
	or	eax, 1	;// Make sure the number is odd
NotLast:
	mov	Parray[ecx * sz - sz], eax
	loop	RandomLoop
		
	;// For now, copy Parray to bignum, just to display it.
	mov	ecx, SIZEOF Parray
	mov	esi, OFFSET Parray
	mov	edi, OFFSET bignum
	rep	movsb
	
	call	DispBigNum

	;push	DWORD PTR [bignum]	;// Passing a pointer to the large prime
	;call	PrimeTest
	;add	esp, 4	;// undoing the push

	ret
CreatePrime ENDP

;//---------------------------------------------------------
PrimeTest PROC
;// Checks the primality of a number
;// Receives: Nothing
;// Returns: Nothing
;// --------------------------------------------------------
	push	ebp		;//	|
	mov	ebp, esp	;//	Same as "enter 0, 0"
	mov	esi, [ebp + 4]	;// Pointer to the prime we're testing

	COMMENT !
	/*
	Here we will use the Rabin-Miller Primality test (40 iterations)
	Input: n > 2, an odd integer to be tested for primality;
		k, a parameter that determines the accuracy of the test
	Output: composite if n is composite, otherwise probably prime
		write n ? 1 as 2s�d with d odd by factoring powers of 2 from n ? 1
	LOOP: repeat k times:
		pick a randomly in the range [2, n ? 1]
		x ? ad mod n
		if x = 1 or x = n ? 1 then do next LOOP
		for r = 1 .. s ? 1
			x ? x2 mod n
			if x = 1 then return composite
			if x = n ? 1 then do next LOOP
		return composite
	return probably prime
	*/
	!

	mov	ecx, 40	;// Perform the test 40 times
RMtest:
	
	loop	RMtest
	
	mov	esp, ebp	;//	|
	pop	ebp		;//	Same as "leave"
	ret
PrimeTest ENDP

;//---------------------------------------------------------
DispBigNum PROC USES eax ebx ecx edx esi edi
;// Displays large decimal integers!
;// Receives: Nothing
;// Returns: Nothing
;// --------------------------------------------------------
.DATA
	temparr	DWORD bigsize DUP (0)		;// The working array
	divby		DWORD 10				;// The number we want to divide by
	decdigits = 39					;// There are 39 decimal digits in a 128 bit integer
	numdigits	DWORD decdigits
	digitarr	DWORD decdigits DUP (0)	
.CODE
	call	Clrscr
	xor	eax, eax
	xor	ecx, ecx
	xor	edx, edx
	;// Copy bignum to temparr
	mov	ecx, SIZEOF bignum
	mov	esi, OFFSET bignum
	mov	edi, OFFSET temparr
	rep	movsb

	mov	ecx, numdigits
DigitLoop:
	push	ecx

;//	Divide the big number by 10
	xor	eax, eax
	xor	edx, edx
	mov	ecx, LENGTHOF bignum
DivLoop:
	mov	eax, temparr[ecx * sz - sz]	;// TYPE temparr = 4
	div	divby
	mov	temparr[ecx * sz - sz], eax
	loop	DivLoop

	pop	ecx
	mov	digitarr[ecx * sz - sz], edx ;// Save the remainder to display later
	loop	DigitLoop

;//	Now lets display the large number in decimal
	xor	eax, eax
	xor	esi, esi
	mov	ecx, numdigits
DispLoop:
	mov	eax, digitarr[esi * sz]
	call	WriteDec
	inc	esi
	loop	DispLoop

	call Crlf
	ret
DispBigNum ENDP

;//---------------------------------------------------------
Input PROC USES eax edx
;// Gathers input for the values of P & Q
;// Receives: Nothing
;// Returns: Pvalue, Qvalue, Mvalue, Tvalue ?
;// --------------------------------------------------------
.DATA
AskForP BYTE "Enter P (random prime): ", 0
AskForQ BYTE "Enter Q (random prime): ", 0
.CODE
	push	ebp		;//	|
	mov	ebp, esp	;//	Same as "enter 0, 0"
	;//	Only needed if local variables are used
	
	mov	edx, OFFSET AskForP
	call	WriteString
	call	ReadDec
	mov	Pvalue, eax
	mov	edx, OFFSET AskForQ
	call	WriteString
	call	ReadDec
	mov	Qvalue, eax

	call	Calculations

	call	Clrscr

	mov	esp, ebp	;//	|
	pop	ebp		;//	Same as "leave"
	ret
Input ENDP

;//---------------------------------------------------------
Calculations PROC USES eax ebx
;// Calculates the values of P, Q, M, & T
;// Receives: EAX
;// Returns: Mvalue & Tvalue ?
;// --------------------------------------------------------
	mul	Pvalue
	mov	Mvalue, eax
	mov	eax, Pvalue
	dec	eax
	mov	ebx, Qvalue
	dec	ebx
	mul	ebx
	mov	Tvalue, eax
	ret
Calculations ENDP

;//---------------------------------------------------------
PrintPQMT PROC USES eax edx
;// Prints the values of P, Q, M & T
;// Receives: Nothing
;// Returns: Nothing
;// --------------------------------------------------------
.data
Pdisplay BYTE "The value of P is: ", 0
Qdisplay BYTE "The value of Q is: ", 0
Mdisplay BYTE "The value of M (P*Q) is: ", 0
Tdisplay BYTE "The value of T (P-1)*(Q-1) is: ", 0
.code
	call	Clrscr
	mov	edx, OFFSET Pdisplay
	mov	eax, Pvalue
	call	Display
	mov	edx, OFFSET Qdisplay
	mov	eax, Qvalue
	call	Display
	mov	edx, OFFSET Mdisplay
	mov	eax, Mvalue
	call	Display
	mov	edx, OFFSET Tdisplay
	mov	eax, Tvalue
	call	Display
	call	Crlf
	ret
PrintPQMT ENDP
Display PROC
	call	WriteString
	call	WriteDec
	call	Crlf
	ret
Display ENDP

;//---------------------------------------------------------
Quit PROC
;// Exits the program
;// Receives: Nothing
;// Returns: Nothing
;// --------------------------------------------------------
	inc	ExitLoop
	ret
Quit ENDP

END main
END main
