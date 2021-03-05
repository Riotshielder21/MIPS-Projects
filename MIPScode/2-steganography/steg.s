#=========================================================================
# Steganography
#=========================================================================
# Retrive a secret message from a given text.
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

input_text_file_name:         .asciiz  "input_steg.txt"
newline:                      .asciiz  "\n"
        
#-------------------------------------------------------------------------
# Global variables in memory
#-------------------------------------------------------------------------
# 
input_text:                   .space 10001       # Maximum size of input_text_file + NULL
.align 4                                         # The next field will be aligned

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

# opening file for reading

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


#------------------------------------------------------------------
# End of reading file block.
#------------------------------------------------------------------


li $t2, 0x20	#li whitespace ascii
la $t5, input_text	#input text
la $s0, newline
li $s1, 0x0a
li $t4, 1		#word number
li $t7, 1		#line number
j specialmain

specialchar:
	beq $t6, $s1, nwline #inc line or print
	beq $t6, $t2, wcountspecial #inc word
	beq $t4, $t7, prchar #print char for word in line
	j specialmain

checkchar:
	
	beq $t6, $s1, nwline #inc line and print
	beq $t6, $t2, wcount #inc word
	beq $t4, $t7, prchar #print char for word in line
	j loopmain

specialmain:	#main loop

	lb $t6, 0($t5) # load next byte
	addi $t5, $t5, 1 # increment the byte counter
	beq $t6, 0x00, main_end # check for eof
	j specialchar #check chars

loopmain:	#main loop

	lb $t6, 0($t5) # load next byte
	addi $t5, $t5, 1 # increment the byte counter
	beq $t6, 0x00, main_end # check for eof
	j checkchar #check chars
nwline:
	
	blt $t4, $t7, prline # if less words than line number -> prline
	li $t4, 1	# word to 1
	addi $t7, $t7, 1   # increment the line
	j loopmain
	
wcountspecial:			
	addi $t4, $t4, 1	#add to wcounter
	j specialmain

wcount:
	addi $t4, $t4, 1	#add to wcounter
	beq $t4, $t7, eow #if whitspeace after word then print it			
	j loopmain

prline:
	li $v0, 4           
	move $a0, $s0	# print_char in register \n
	syscall
	addi $t7, $t7, 1   # increment the line
	li $t4, 1	# word to 1
	j specialmain
	
prchar:
	li $v0, 11           
	move $a0, $t6	# print_char in register $t6
	syscall
	
	j loopmain

eow:
	li $v0, 11           
	move $a0, $t6	# print_char in register $t6
	syscall
	j loopmain
	
#------------------------------------------------------------------
# Exit, DO NOT MODIFY THIS BLOCK
#------------------------------------------------------------------
main_end:
	li $v0, 11           
	li $a0, 0x0a	#print newline
	syscall      
        li   $v0, 10          # exit()
        syscall

#----------------------------------------------------------------
# END OF CODE
#----------------------------------------------------------------
