#=========================================================================
# Book Cipher Decryption
#=========================================================================
# Decrypts a given encrypted text with a given book.
# 
# Inf2C Computer Systems
# 
# Dmitrii Ustiugov
# 9 Oct 2020
# 
#
#=========================================================================
# DATA SEGMENT
#=========================================================================
.data
#-------------------------------------------------------------------------
# Constant strings
#-------------------------------------------------------------------------

input_text_file_name:         .asciiz  "input_book_cipher.txt"
book_file_name:               .asciiz  "book.txt"
newline:                      .asciiz  "\n"
check:			      .asciiz  "found first line after"
        
#-------------------------------------------------------------------------
# Global variables in memory
#-------------------------------------------------------------------------
# 
input_text:                   .space 10001       # Maximum size of input_text_file + NULL
.align 4                                         # The next field will be aligned
book:                         .space 10001       # Maximum size of book_file + NULL
.align 4                                         # The next field will be aligned
bookline:		      .byte
bookword:		      .byte
# You can add your data here!

#=========================================================================
# TEXT SEGMENT  
#=========================================================================
.text

#-------------------------------------------------------------------------
# MAIN code block
#-------------------------------------------------------------------------

.globl main                     # Declare main label to be globally visible.
                                # Needed for correct operation with MARS
main:
#-------------------------------------------------------------------------
# Reading file block. DO NOT MODIFY THIS BLOCK
#-------------------------------------------------------------------------

# opening file for reading (text)

        li   $v0, 13                    # system call for open file
        la   $a0, input_text_file_name  # input_text file name
        li   $a1, 0                     # flag for reading
        li   $a2, 0                     # mode is ignored
        syscall                         # open a file
        
        move $s0, $v0                   # save the file descriptor 

        # reading from file just opened

        move $t0, $0                    # idx = 0

READ_LOOP:                              # do {
        li   $v0, 14                    # system call for reading from file
        move $a0, $s0                   # file descriptor
                                        # input_text[idx] = c_input
        la   $a1, input_text($t0)             # address of buffer from which to read
        li   $a2,  1                    # read 1 char
        syscall                         # c_input = fgetc(input_text_file);
        blez $v0, END_LOOP              # if(feof(input_text_file)) { break }
        lb   $t1, input_text($t0)          
        beq  $t1, $0,  END_LOOP        # if(c_input == '\0')
        addi $t0, $t0, 1                # idx += 1
        j    READ_LOOP
END_LOOP:
        sb   $0,  input_text($t0)       # input_text[idx] = '\0'

        # Close the file 

        li   $v0, 16                    # system call for close file
        move $a0, $s0                   # file descriptor to close
        syscall                         # fclose(input_text_file)


# opening file for reading (book)

        li   $v0, 13                    # system call for open file
        la   $a0, book_file_name        # book file name
        li   $a1, 0                     # flag for reading
        li   $a2, 0                     # mode is ignored
        syscall                         # open a file
        
        move $s0, $v0                   # save the file descriptor 

        # reading from file just opened

        move $t0, $0                    # idx = 0

READ_LOOP1:                              # do {
        li   $v0, 14                    # system call for reading from file
        move $a0, $s0                   # file descriptor
                                        # book[idx] = c_input
        la   $a1, book($t0)              # address of buffer from which to read
        li   $a2,  1                    # read 1 char
        syscall                         # c_input = fgetc(book_file);
        blez $v0, END_LOOP1              # if(feof(book_file)) { break }
        lb   $t1, book($t0)          
        beq  $t1, $0,  END_LOOP1        # if(c_input == '\0')
        addi $t0, $t0, 1                # idx += 1
        j    READ_LOOP1
END_LOOP1:
        sb   $0,  book($t0)             # book[idx] = '\0'

        # Close the file 

        li   $v0, 16                    # system call for close file
        move $a0, $s0                   # file descriptor to close
        syscall                         # fclose(book_file)

#------------------------------------------------------------------
# End of reading file block.
#------------------------------------------------------------------	
la $t2, input_text 			#key
li $t0, 10
li $s0, 0
li $s1, 0
j bookoutLs

prebookL:
	li $s0, 0		#taken - v0, a0, a1, a2, s0, t1, t2, t3
bookoutL:         
  	lb $t1, ($t2)       #load byte from book into t1
  	addi $t2, $t2, 1     #increment $t2 address
  	beq $t1, $0, main_end     #EOF
	ble $t1, 32, prebookW
  	subi $t1, $t1, 48   #ascii value to dec value
  	mul $s0, $s0, $t0    #total * 10
  	add $s0, $s0, $t1    #total += $t1
  	j bookoutL                #jump to start of loop
  	
 prebookW:
 	li $s1, 0
 bookoutW:
  	lb $t1, ($t2)       #load byte from book into t1
  	addi $t2, $t2, 1     #increment $t2 address 
  	beq $t1, $0, main_end     #EOF
	beq $t1, 0x0a, pullline
	ble $t1, 47, bookoutW
  	subi $t1, $t1, 48   #ascii value to dec value
  	mul $s1, $s1, $t0
  	add $s1, $s1, $t1    #total += $t1
  	j bookoutW                #jump to start of loop		

######################################################################### special loop for characters after new line
prebookLs:
	li $s0, 0		#taken - v0, a0, a1, a2, s0, t1, t2, t3
bookoutLs:         
  	lb $t1, ($t2)       #load byte from book into t1
  	addi $t2, $t2, 1     #increment $t2 address
  	beq $t1, $0, main_end     #EOF
  	beq $t1, 0x20, prebookWs
  	subi $t1, $t1, 48   #ascii value to dec value
  	mul $s0, $s0, $t0    #total * 10
  	add $s0, $s0, $t1    #total += $t1
  	j bookoutLs                #jump to start of loop
  	
 prebookWs:
 	li $s1, 0
 bookoutWs:
  	lb $t1, ($t2)       #load byte from book into t1
  	addi $t2, $t2, 1     #increment $t2 address 
  	beq $t1, 0x0a, pulllineS
  	beq $t1, $0, main_end     #EOF
  	blt $t1, 47, bookoutWs
  	subi $t1, $t1, 48   #ascii value to dec value
  	mul $s1, $s1, $t0
  	add $s1, $s1, $t1    #total += $t1
  	j bookoutWs                #jump to start of loop
########################################################################
pulllineS:
	la $t5, book
	li $t8, 1 #word counter
	li $t7, 1 #line counter
	j pull_mainS
	
nwlineS:
	addi $t7, $t7, 1   # increment the line
	addi $t5, $t5, 1 # increment the byte counter
	
	
pull_mainS:	#main line loop
	lb $t6, 0($t5) # load next byte
	beq $t6, 0x00, prline # check for eof
	beq $t6, 0x0a, nwlineS #inc line
	beq $t7, $s0, word_mainS #if you reach target line, return and prepare to pull word
	addi $t5, $t5, 1 # increment the byte counter
	j pull_mainS
	
wordS:
	addi $t8, $t8, 1   # increment the word
		
word_mainS:	#main line loop
	lb $t6, 0($t5) # load next byte
	addi $t5, $t5, 1 # increment the byte counter
	beq $t6, 0x20, wordS
	beq $t6, $0, main_end
	beq $s1, $t8, printwordS #if you reach target word, print word
	bgt $t8, $s1, prebookL # see if word counter passes word address	
	j pull_mainS
	
printwordS:
	li $v0, 11           
	move $a0, $t6	# print_char in register $t6
	syscall
	
	j word_mainS
########################################################################

#taken - v0, a0, s0, t1, t2, t3, t5, t6, t7, t8

pullline:
	la $t5, book
	li $t8, 1 #word counter
	li $t7, 1 #line counter
	j pull_main


#########################################################################################	

nwline:
	addi $t7, $t7, 1   # increment the line
	addi $t5, $t5, 1 # increment the byte counter
	
pull_main:	#main line loop
	lb $t6, 0($t5) # load next byte
	beq $t6, 0x00, prline # check for eof
	beq $t6, 0x0a, nwline #inc line
	beq $t7, $s0, word_main #if you reach target line, return and prepare to pull word
	addi $t5, $t5, 1 # increment the byte counter
	j pull_main
	
prline: 
	li $v0, 11           
	li $a0, 0x0a	# print \n
	syscall
	j prebookLs
		
#########################################################################################	
s:
	blt $t8, $s1, prebookLs
	j prebookL
word:
	addi $t8, $t8, 1   # increment the word
	beq $s1, $t8, printword
		
word_main:	#main line loop
	lb $t6, 0($t5) # load next byte
	addi $t5, $t5, 1 # increment the byte counter
	beq $t6, 0x20, word #inc word
	beq $t6, 0x0a, s
	bgt $t8, $s1, prebookL
	beq $s1, $t8, printword #if you reach target word, print word
	j pull_main
	
printword:
	li $v0, 11           
	move $a0, $t6	# print_char in register $t6
	syscall
	j word_main

#------------------------------------------------------------------
# Exit, DO NOT MODIFY THIS BLOCK
#------------------------------------------------------------------
main_end:    
        li   $v0, 10          # exit()
        syscall

#----------------------------------------------------------------
# END OF CODE
#----------------------------------------------------------------
