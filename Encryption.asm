
# the following few lines set up register and memory values for a demo
addi $a0, $zero, 0x10010000
addi $a1, $zero, 0x10010010
addi $a2, $zero, 0x0F31
addi $a3, $zero, 0xFE31
sw $a3, ($a1)
sw $a3, 4($a1)
sw $a2, 8($a1)

encrypt: #encrypts the memory between the addresses stored in $a1 and $a2
#@param $a0 the starting address in memory that we want to encrypt
#@param $a1 the ending address in memory that we want to encrypt, must be a multiple of 4 words from the start, will not check
# if it is not a multiple of 4 words then the algorithm will simply encrypt memory further to reach a multiple of 4.
#@param $a2 the key dictating the addition/subtraction portion of the encrytion algorithm
#@param $a3 the key dictating the shifts/swaps portion of the encryption algorithm and the #loops


#$t0 through $t3 are for processing the data
#$t4 for holding the next address to add
#$t5 for operations, inner loop shift counter
#$t6 for holding the loop counter
#$t7 for operations, holds the horizontal shift amount
#$t8 for operations
#$t9 for operations
addi $t4, $a0, 0 #copy starting address to t4

load: #load the next four words
lw $t0 0($t4) #load first word
lw $t1 4($t4)
lw $t2 8($t4)
lw $t3 12($t4)


#get first 25 bits of $a4, which is the loop length, into $t6
srl $t6, $a3, 7   # shift right logical by 7 bits to get the bits in place
andi $t6, $t6, 0x1FFFFFF   # AND with 0x1FFFFFF (hexadecimal value) to get the first 25 bits

addi $t6, $t6, 9 # set loop counter, should do at least a few encryption loops to encrypt just in case the loop number happens to be low
srl $t7, $a3, 2 #shift right by 2 to get horizontal shift bits in position
andi $t7, $t7, 0x1F # get the 5 bits for horizontal shift
encryptionloop: #performs the actual encryption of a block

addi $t6, $t6, -1 #decrement the loop counter

#perform the addition using the addition/subtraction key in $a3
add $t0, $t0, $a2
add $t1, $t1, $a2
add $t2, $t2, $a2
add $t3, $t3, $a2

#perform the horizontal shift
add $t5, $zero, $t7  # copy shift amount to $t5

horizontalshift_loop:
#do t0
andi $t9, $t0, 0x00000001 #save the value about to be shifted out
sll $t9, $t9, 31 #shift left by 31 to align the saved bit as the new most significant bit
srl $t8, $t0, 1    # shift right logical by 1 bit
or $t0, $t8, $t9   # bitwise OR of shifted values to add on the carryover from t9

#do t1
andi $t9, $t1, 0x00000001 #save the value about to be shifted out
sll $t9, $t9, 31 #shift left by 31 to align the saved bit as the new most significant bit
srl $t8, $t1, 1    # shift right logical by 1 bit
or $t1, $t8, $t9   # bitwise OR of shifted values to add on the carryover from t9

#do t2
andi $t9, $t2, 0x00000001 #save the value about to be shifted out
sll $t9, $t9, 31 #shift left by 31 to align the saved bit as the new most significant bit
srl $t8, $t2, 1    # shift right logical by 1 bit
or $t0, $t8, $t9   # bitwise OR of shifted values to add on the carryover from t9


#do t3
andi $t9, $t3, 0x0001 #save the value about to be shifted out
sll $t9, $t9, 31 #shift left by 31 to align the saved bit as the new most significant bit
srl $t8, $t3, 1    # shift right logical by 1 bit
or $t3, $t8, $t9   # bitwise OR of shifted values to add on the carryover from t9

addi $t5, $t5, -1   # decrement shift count
bnez $t5, horizontalshift_loop   # branch to shift_loop if $t5 (inner loop shift counter) is not zero


# Now that the horizontal shifting is complete for this iteration of the encryption loop,
#it is time to perform the vertical shifts for halfwords(t3 ->t2, t2->t1, ... t0->t3)
andi $t5, $a3, 0x0002 #get vertical shift amount and load into counter
verticalshift_loop: 

#t3->t2
andi $t9, $t3, 0xFFFF #save the right half of the word (16 bits)
andi $t8, $t2, 0xFFFF #save the right half of the word being replaced (16 bits)
andi $t2, $t2, 0xFFFF0000 #wipe the right half of the word being replaced
or $t2, $t2, $t9 #swap in the right 16 bits

#t2->t1
andi $t9, $t1, 0xFFFF #save the right half of the word being replaced (16 bits)
andi $t1, $t1, 0xFFFF0000 #wipe the right half of the word being replaced
or $t1, $t1, $t8 #swap in the right 16 bits $t8 has the stuff from t2

#t1->t0
andi $t8, $t0, 0xFFFF #save right half of t0 to t8
andi $t0, $t0, 0xFFFF0000
or $t0, $t0, $t9 #swap in the contents of t9 which is carrying the right half of $t1

#t0 -> t3
andi $t3, $t3, 0xFFFF0000 #wipe right half
or $t3, $t3, $t8 #swap in the contents of t8 which is carrying the right half of $t0

addi $t5, $t5, -1   # decrement shift count
bnez $t5, verticalshift_loop   # branch to shift_loop if $t5 (inner loop shift counter) is not zero

#branch back to encryption main loop
bnez $t6, encryptionloop		
			
#save encrypted registers, then start encryption on next block of 4 words
sw $t0, ($t4)
sw $t1, 4($t4)
sw $t2, 8($t4)
sw $t3, 12($t4)
addi $t4, $t4, 16 #get starting address for next block

slt $t8, $t4, $a2
bnez $t8, load # if next address to load is less than the ending address, go load and encrypt four more words.
jr $ra #return when thee specified memory has been encrypted

decrypt: # undoes the encryption for the memory between the addresses stored in $a1 and $a2 using keys in $a3 and $a4
#@param $a1 the starting address in memory that we want to encrypt
#@param $a2 the ending address in memory that we want to encrypt
#@param $a3 the key dictating the addition/subtraction portion of the encrytion algorithm
#@param $a4 the key dictating the shifts/swaps portion of the encryption algorithm
#***Note that $a1 and $a2 must be the same starting and ending address as when encrypted otherwise the algorithm will NOT work 
#as intended. In fact, performing multiple encryption operations (encryption on already encrypted data) is a way to 
#strengthen the encryption.


