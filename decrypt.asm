decrypt: # undoes the encryption for the memory between the addresses stored in $a1 and $a2 using keys in $a3 and $a4
#@param $a1 the starting address in memory that we want to encrypt
#@param $a2 the ending address in memory that we want to encrypt
#@param $a3 the key dictating the addition/subtraction portion of the encrytion algorithm
#@param $a4 the key dictating the shifts/swaps portion of the encryption algorithm
#***Note that $a1 and $a2 must be the same starting and ending address as when encrypted otherwise the algorithm will NOT work 
#as intended. In fact, performing multiple encryption operations (encryption on already encrypted data) is a way to 
#strengthen the encryption.
