#=========================================================================
# XOR Cipher Encryption
#=========================================================================
# Encrypts a given text with a given key.
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

input_text_file_name:         .asciiz  "input_xor.txt"
key_file_name:                .asciiz  "key_xor.txt"
        
#-------------------------------------------------------------------------
# Global variables in memory
#-------------------------------------------------------------------------
# 
input_text:                   .space 10001       # Maximum size of input_text_file + NULL
.align 4                                         # The next field will be aligned
key:                          .space 33           # Maximum size of key_file + NULL
.align 4                                         # The next field will be aligned
keycode:		      .byte		 #store the byteshift ascii key code
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


# opening file for reading (key)

        li   $v0, 13                    # system call for open file
        la   $a0, key_file_name         # key file name
        li   $a1, 0                     # flag for reading
        li   $a2, 0                     # mode is ignored
        syscall                         # open a file
        
        move $s0, $v0                   # save the file descriptor 

        # reading from file just opened

        move $t0, $0                    # idx = 0

READ_LOOP1:                              # do {
        li   $v0, 14                    # system call for reading from file
        move $a0, $s0                   # file descriptor
                                        # key[idx] = c_input
        la   $a1, key($t0)              # address of buffer from which to read
        li   $a2,  1                    # read 1 char
        syscall                         # c_input = fgetc(key_file);
        blez $v0, END_LOOP1              # if(feof(key_file)) { break }
        lb   $t1, key($t0)          
        addi $v0, $0, 10                # newline \n
        beq  $t1, $v0, END_LOOP1         # if(c_input == '\n')
        addi $t0, $t0, 1                # idx += 1
        j    READ_LOOP1
END_LOOP1:
        sb   $0,  key($t0)             # key[idx] = '\0'

        # Close the file 

        li   $v0, 16                    # system call for close file
        move $a0, $s0                   # file descriptor to close
        syscall                         # fclose(key_file)

#------------------------------------------------------------------
# End of reading file block.
#------------------------------------------------------------------

la $t2, key 			# key
la $s1, keycode			#binary keycode
li $v1, 0			#tempvar for key
li $t3, 0			#keypos
li $s2, 0			#key length

				#taken - v0, v1, a0, t1, t2, t3, s1, s2 

keyout:				#sort key

	lb $t1, 0($t2)
	blt $t1, 48, msg	#filter that random formfeed and also capture eof
	bge $t1, 57, msg	#i mean, why would there be letters
	
	blt $t3, 8, sortkey 	#print char if not whitespace
	
sanitycheck:	
	li $t3, 0		#keypos = 0 
	srl $v1, $v1, 1		#undo extra append
	sb $v1, 0($s1)		#store key byte 1
	addi $s1, $s1, 1	#increase keycode address
	addi $s2, $s2, 1	#inc key len
				

	#li $v0, 11           
	#li $a0, 0x0a		# print \n
	#syscall
	#li $v0, 35           
	#move $a0, $v1		# print v1
	#syscall
	#li $v0, 11           
	#li $a0, 0x0a		# print \n
	#syscall
	#li $v0, 11           
	#li $a0, 0x0a		# print \n
	#syscall

	li $v1, 0		#reset v1
	j keyout

sortkey:
	addi $t3, $t3, 1	#keypos ++
	sub $t1,$t1, 48 	#ASCII to Binary
	add $v1, $v1, $t1	#append binary number 
	sll $v1, $v1, 1		#prepare next append
	#li   $v0, 35           	# print ascii char
	#move   $a0, $t1
	#syscall
	#li $v0, 11           
	#li $a0, 0x0a		# print \n
	#syscall
	addi $t2, $t2, 1 	# increment the byte counter
	beq $t3, 8, sanitycheck	#sanitycheck for the random "Form Feed" ASCII in the text doc
	j keyout
	
#############################################################
	
princhar:			#s2 is key length ------ s1 is byte formatted keycode
				#taken - v0, a0, t1, t2, t3, t4, s1, s2 
	lb $t3, 0($s1)		#load key

	xor $t1, $t1, $t3	#perform cipher
				#65
				#122
				#|~'{} 
	li   $v0, 11           	# print ascii char
	move   $a0, $t1
	syscall
	addi $s1, $s1, 1	#increase keycode byte
	addi $t2, $t2, 1 	#increment the byte counter
	addi $t4, $t4, 1	#increment the key pos
	j msgout
	
	
reserved:

	addi $s1, $s1, 1	#increase keycode byte
	li   $v0, 11           	#print ascii char
	move   $a0, $t1
	syscall
	addi $t2, $t2, 1 	#increment the byte counter
	addi $t4, $t4, 1	#increment the key pos
	j msgout
	
msg:
	
	li $t4, 0		#current key pos
	la $t2, input_text	#input text
	
resetkey:
	la $s1, keycode
	li $t4, 0	
	
msgout:				#main xor loop

	lb $t1, 0($t2)
	beq $t1, 0x00, main_end
	beq $s2, $t4 resetkey
	beq $t1, 0x0a, reserved #newline
	beq $t1, 0x20, reserved #whitespace
	ble $t1, 0x20, special #newline
	j princhar #print char
	
special:
	addi $t2, $t2, 1
	j msgout


#------------------------------------------------------------------
# Exit, DO NOT MODIFY THIS BLOCK
#------------------------------------------------------------------
main_end:      
        li   $v0, 10          # exit()
        syscall

#----------------------------------------------------------------
# END OF CODE
#----------------------------------------------------------------
