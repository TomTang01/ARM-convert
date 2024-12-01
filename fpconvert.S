// === file header ===
	.arch armv6               // armv6 architecture
	.cpu cortex-a72           // our CPU model
	.arm                      // arm 32-bit IS
	.fpu vfp                  // floating point co-processor
	.syntax unified           // modern syntax
// === definitions applying to the entire source file ===
	// you could put the bit count of certain fields or masks here, for example
	.equ EXTRACT_S_MASK, 0x8000
	.equ EXTRACT_E_MASK, 0x7f00
	.equ EXTRACT_M_MASK, 0x00ff
	.equ RESULT_MASK, 0x00000000
	// .data                  // uncomment if you need the data segment
	.text                     // start of text segment

// === fpconvert ===
	.global fpconvert         // make fpconvert global so the linker knows about it
	.type fpconvert, %function // define fpconvert to be a function
	.equ FP_OFFSET, 32 	      // (# of saved regs - 1) * 4 rounded up to multiples of 8
fpconvert:
// function prologue (do not edit)
	push {r4-r10, fp, lr}     // save registers to stack
	add fp, sp, FP_OFFSET     // set frame pointer to frame base
// you can use any of r0-r10 inclusive
// r0 is the parameter to the function
// the value of r0 upon bx lr is the value returned from the function

// YOUR CODE BEGINS
// === fpconvert function body ===
	// TODO implement; here's one example for the recommended style:
	// instruction operands   // equivalent C code         ; human readable explanation
	ldr r1, =EXTRACT_S_MASK	  //			       ; r1 to be the extract mask for the sign bit
	ldr r2, =EXTRACT_E_MASK	  //			       ; r2 to be the extract mask for the exponent bits
	ldr r3, =EXTRACT_M_MASK	  //			       ; r3 to be the extract mask for the mantissa bits

							       // 1. Extract all 3 parts
	and r1, r0, r1		  // r1 = r0 and 0x8000	       ; extract the sign bit. Store it in r1
	lsr r1, r1, #15		  // r1 = r1 >> 15	       ; shift the sign bit to the right most end
	and r2, r0, r2		  // r2 = r0 and 0x7f00	       ; extract the exponent bits. Store it in r2
	lsr r2, r2, #8		  // r2 = r2 >> 8	       ; shift the exponent bits to the right end
	and r3, r0, r3		  // r3 = r0 and 0x00ff        ; extract the mantissa bits. Store it in r3	

							       // 2. Check exponent
	cmp r2, #0x7f		  // if(r2 == 0x7f)	       ; Case 1: exp is all 1s
	bne .Lntinf
	bl  convert_infinity  	  // convert_infinity(n)       ; call convert_infinity on n
	b   .Lisinf
.Lntinf:cmp r2, #0x0		  // else if(r2 == 0x0)        ; Case 2: exp is all 0s
	bne .Lendei
	mov r2, #0x41		  // r2 = 0x41	      	       ; exponent = 65
	mov r4, #0		  // for(int i=0;	       ; for loop
	cmp r4, #8		  // i<8;;)
	bge .Lendfr
.Lfor:	and r5, r3, #0x0080	  // r5 = r3 and 0x0080	       ; check the first digit of r3	
	cmp r5, #0x0000		  // if(r5 == 0x0)	       ; Case 2.1: the left most digit of mantissa is 0
	bne .Lone
	lsl r3, r3, #1		  // r3 = r3 << 1	       ; left shift mantissa 1 digit
	sub r2, r2, #0x0001	  // r2 --;		       ; exp--;
	add r4, r4, #1		  // r4 = r4 + 1	       ; i++;
	cmp r4, #8		  // if(i<8)		       ; check if condition
	blt .Lfor
	b   .Lendfr
.Lone:	lsl r3, r3, #1		  // r3 = r3 << 1	       ; Case 2.2: the left most digit of mantissa is 1. Left shift mantissa 1 digit
	and r3, r3, #0x00ff	  // r3 = r3 and 0x00ff	       ; erase the 1 at the 9th digit from right
	sub r2, r2, #0x0001	  // r2 --;		       ; exp--;
	b   .Lendif
.Lendfr:mov r2, #0x0000		  // r2 = 0x0000	       ; set exp to all 0s
	b   .Lendif
.Lendei:add r2, r2, #0x40	  // r2 = r2 + 0x40	       ; Case 3: else. exp += 64
.Lendif:
							       //3. Combine sign, exp, mantissa to r0
	ldr r0, =RESULT_MASK	  // r0 = 0x00000000	       ; sets r0 to be a 32-bit register
	add r0, r0, r1		  // r0 = r0 + r1	       ; add the sign bit to the right end of the register
	lsl r0, r0, #8		  // r0 = r0 << 8	       ; shift the sign bit left 8 digits to make room for exp
	add r0, r0, r2		  // r0 = r0 + r2	       ; add the exp to the right of the sign bit
	lsl r0, r0, #8		  // r0 = r0 << 8	       ; shift the bits 8 digits to the left to make room for the mantissa
	add r0, r0, r3		  // r0 = r0 + r3	       ; add the mantissa to the end
	lsl r0, r0, #15		  // r0 = r0 << 15	       ; shift everything 15 digits to the left.
.Lisinf:
// === end fpconvert function body ===
// YOUR CODE ENDS

// function epilogue - do not edit
	sub sp, fp, FP_OFFSET
	pop {r4-r10, fp, lr}      // must match list in prolog's push
	bx lr                     // return
// function footer
	.size fpconvert, (. - fpconvert) // set size for function

// === file footer ===
	.section .note.GNU-stack, "", %progbits // stack/data non-exec (linker)
	.end
