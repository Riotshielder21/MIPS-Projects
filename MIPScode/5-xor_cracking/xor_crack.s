#=========================================================================
# XOR Cipher Cracking
#=========================================================================
# Finds the secret key for a given encrypted text with a given hint.
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

input_text_file_name:         .asciiz  "input_xor_crack.txt"
hint_file_name:               .asciiz  "hint.txt"
newline:                      .asciiz  "\n"
        
#-------------------------------------------------------------------------
# Global variables in memory
#-------------------------------------------------------------------------
# 
input_text:                   .space 10001       # Maximum size of input_text_file + NULL
.align 4                                         # The next field will be aligned
hint:                         .space 101         # Maximum size of key_file + NULL
.align 4                                         # The next field will be aligned
decrypted:		      .asciiz
key:			      .byte
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


# opening file for reading (hint)

        li   $v0, 13                    # system call for open file
        la   $a0, hint_file_name        # hint file name
        li   $a1, 0                     # flag for reading
        li   $a2, 0                     # mode is ignored
        syscall                         # open a file
        
        move $s0, $v0                   # save the file descriptor 

        # reading from file just opened

        move $t0, $0                    # idx = 0

READ_LOOP1:                              # do {
        li   $v0, 14                    # system call for reading from file
        move $a0, $s0                   # file descriptor
                                        # hint[idx] = c_input
        la   $a1, hint($t0)             # address of buffer from which to read
        li   $a2,  1                    # read 1 char
        syscall                         # c_input = fgetc(key_file);
        blez $v0, END_LOOP1              # if(feof(key_file)) { break }
        lb   $t1, hint($t0)          
        addi $v0, $0, 10                # newline \n
        beq  $t1, $v0, END_LOOP1         # if(c_input == '\n')
        addi $t0, $t0, 1                # idx += 1
        j    READ_LOOP1
END_LOOP1:
        sb   $0,  hint($t0)             # hint[idx] = '\0'

        # Close the file 

        li   $v0, 16                    # system call for close file
        move $a0, $s0                   # file descriptor to close
        syscall                         # fclose(key_file)

#------------------------------------------------------------------
# End of reading file block.
#------------------------------------------------------------------

li $s2, -1
li $t1, 0

#taken - v0, a0, t1, t2, s0, s1, s2, s3 				

keyinc:	
	bge $s2, 255, main_end_false	# check if there is no more chipher keys
	addi $s2, $s2, 1	#add one to cipher key
	la $s1, input_text	# load input text into registers
	la $s3, decrypted	# load decrypted into registers
	
xor_text:
	lb $t1, 0($s1) 		#load first input text into code
	beq $t1, $0, presearch
	xor $t2, $t1, $s2
	sb $t2, 0($s3)
	addi $s1, $s1, 1
	addi $s3, $s3, 1
	j xor_text
	
#############################################################

chkchar:
	addi $s0, $s0, 1		#inc hint address
	lb $t2, 0($s0)			#hint char
	lb $t1, 0($s3)			#decrypt char			
	ble $t1, 13, char
	beq $t2, $0, main_end
	bne $t1, $t2, resethint
	addi $s3, $s3, 1
	j chkchar
	
char:	
	addi $s3, $s3, 1
	j chkchar
	
resethint:
	la $s0, hint	
	j hintsearch		
presearch:
	la $s3, decrypted	#address of decrypted text
	la $s0, hint 		#address of hint
	lb $t2, 0($s0)		#load hint
	
hintsearch:				#main search loop
	
	lb $t1, 0($s3)		#load next decrypt char
	addi $s3, $s3, 1	#inc address
	beq $t1, $t2, chkchar	#check char if equal
	beq $t1, $0, keyinc	#if end of decryption text, inc key
	j hintsearch #print char
	


#------------------------------------------------------------------
# Exit, DO NOT MODIFY THIS BLOCK
#------------------------------------------------------------------
main_end:
	li $t2, 0
end:        	
	beq $t2, 8, final
	addi $t2, $t2, 1
        subi $t1, $s2, 128
        sll $s2, $s2, 1
 	bge $t1, 0, print1
 	blt $t1, 0, print0
        
final:                      
        li  $v0, 11          
	li $a0, 0x0a
        syscall
        li   $v0, 10          # exit()
        syscall
        
        
print0:
	li  $v0, 1         
	li $a0, 0
        syscall
        j end
print1:
	li  $v0, 1         
	li $a0, 1
        syscall
        subi $s2, $s2, 256
        j end
        
main_end_false:      
	li  $v0, 1          
	li $a0, -1
        syscall
        li   $v0, 10          # exit()
        syscall

#----------------------------------------------------------------
# END OF CODE
#----------------------------------------------------------------
