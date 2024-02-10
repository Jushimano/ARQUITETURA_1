.section .rodata
promptSize:   .asciz "Enter the size for n: "
formatIn:     .asciz "%d"
promptM:      .asciz "Enter the value for m: "   # Novo prompt para m
print_format: .string "%f "                      # Formato de saída
print_nl:     .asciz "\n"                        # Nova linha para impressão

.section .bss
n_size:  .space 8          # Reserve space for the size of the vector
m_size:  .space 8          # Reserve space for the size of the vector
p:       .space 8          # Reserve space for the pointer to the vector
q:       .space 8          # Reserve space for the pointer to the vector
r:       .space 8          # Reserve space for the pointer to the vector
a:       .space 8          # Reserve space for the pointer to the matrix
s:       .space 8          # Reserve space for the pointer to the vector 

.section .text
.extern printf, scanf, malloc, fflush

.global alloc_vector
alloc_vector:
    # Allocate memory for the vector
    push %rsi                  # Save the pointer to the vector
    imul $8, %rdi, %rdi        # Calculate the size needed for the vector (n * size of int)
    call malloc
    pop %rsi                   # Restore the pointer to the vector
    mov %rax, (%rsi)           # Store the pointer to the allocated memory

    # Return to the caller
    ret 

.global init_vector
init_vector:
# Initialize the values of the vector
# x[i] = (i % n) / n
    mov $0, %rcx                # Initialize the counter
    mov %rsi, %r8               # Copy the size of the vector to R8
    jmp .L2                     # Jump to the loop condition
.L3:
    xor %rdx, %rdx              # Clear RDX
    mov %rcx, %rax              # i -> RAX
    div %r8                     # i / n (ou m)
    # Now RDX contains i % n (m)
    mov %rdx, %rax              # i % n(m) -> RAX
    cvtsi2sd %rax, %xmm0        # Move the value to the XMM0 register
    cvtsi2sd %r8, %xmm1         # Move the value of n(ou m) to the XMM1 register
    divsd %xmm1, %xmm0          # (i % n(m)) / n(m)
    lea (%rdi, %rcx, 8), %rdx   # Calculate the offset for the vector and store it in RSI
    movsd %xmm0, (%rdx)         # Store the value in the vector

    inc %rcx # Increment the counter
.L2:
    cmp %r8, %rcx               # Compare the counter with the size of the vector
    jl .L3                      # Jump to the loop if the counter is less than the size of the vector

    # Return to the caller
    ret

.global init_zero_vector
init_zero_vector:
    # Initialize the values of the vector to zero
    xorpd %xmm0, %xmm0          # Load zero into XMM0 register
    mov $0, %rcx                # Initialize the counter

.Loop:
    cmp %rcx, %rsi              # Compare the counter with the size of the vector
    jge .End                    # If counter >= size, exit loop

    lea (%rdi, %rcx, 8), %rdx   # Calculate the offset for the vector and store it in RDX
    movsd %xmm0, (%rdx)         # Store zero value in the vector

    inc %rcx                    # Increment the counter
    jmp .Loop                   # Jump back to the loop

.End:
    # Return to the caller
    ret


.global init_matrix
init_matrix:
    # Function prologue
    push %rbp
    mov %rsp, %rbp

    # Parameters:
    # %rdi: Pointer to the matrix
    # %rsi: Number of rows (n)
    # %rdx: Number of columns (m)

    mov %rdx, %r8               # Copy the number of columns(m) to R8

    mov $0, %rcx                # Initialize the counter for rows

.Lrow_loop:
    cmp %rcx, %rsi              # Compare current row with the number of rows (n)
    je .Lend                    # End if all rows processed

    mov $0, %r9                 # Initialize the counter for columns
    # i * m * 8
    imul $8, %r8, %r10         # Calculate the size needed for the row (n * size of double)
    imul %rcx, %r10            # Calculate the offset for the row 
    add %rdi, %r10             # Add the offset to the pointer to the matrix

.Lcol_loop:
    cmp %r9, %r8                # Compare current column with the number of columns (m)
    je .Lnext_row               # Proceed to next row if all columns processed

    mov %rcx, %rax              # i -> RAX
    mov %r9, %rbx               # j -> RBX
    inc %rbx                    # j + 1
    imul %rbx, %rax             # i * (j + 1) -> RAX
    xor %rdx, %rdx              # Clear RDX
    div %rsi                    # (i * (j + 1)) / n -> RAX (quotient), RDX (remainder)
    cvtsi2sd %rdx, %xmm0        # (i * (j + 1)) % n -> XMM0
    cvtsi2sd %rsi, %xmm1        # n -> XMM1
    divsd %xmm1, %xmm0          # ((i * (j + 1)) % n) / n

    lea (%r10, %r9, 8), %rdx    # Calculate the address of A[i][j] and store it in RDX
    movsd %xmm0, (%rdx)         # Store the value in A[i][j]

    inc %r9                     # Increment the column counter
    jmp .Lcol_loop              # Jump back to column loop

.Lnext_row:
    inc %rcx                    # Increment the row counter
    jmp .Lrow_loop              # Jump back to row loop

.Lend:
    # Function epilogue
    pop %rbp
    ret

.global main_computation_p1
main_computation_p1:
    # Function prologue
    push %rbp                    # Save the base pointer
    mov %rsp, %rbp               # Set the base pointer to the current stack pointer

    mov 16(%rbp), %r10           # Save Pointer to the matrix A in R10

    # Save the parameters
    mov %rdi, %r13         # Pointer to the vector p
    mov %rsi, %rsi         # Pointer to the vector q
    mov %rdx, %rdx         # Pointer to the vector r
    mov %rcx, %r11         # Pointer to the vector s
    mov %r8, %r8           # Number of rows (n)
    mov %r9, %r9           # Number of columns (m)

    # Initialize the row counter
    xor %rcx, %rcx         # Initialize the row counter (i)

.mainc_row_loop:
    cmp %r8, %rcx         # Compare the row counter with the number of rows
    je .mainc_end         # If all rows processed, exit loop

    # Initialize the column counter
    xor %r12, %r12        # Initialize the column counter (j)

.mainc_col_loop:
    cmp %r9, %r12          # Compare the column counter with the number of columns
    je .mainc_next_row     # If all columns processed, proceed to next row

.P1:
    # Load s[j] into xmm2
    lea (%r11, %r12, 8), %rdi  # Load the address of the vector s into %rdi
    movsd (%rdi), %xmm2       # Load the value of s[j] into %xmm2

    # Load r[i] into xmm1
    lea (%rdx, %rcx, 8), %rdi  # Load the address of the vector r into %rdi
    movsd (%rdi), %xmm1       # Load the value of r[i] into %xmm1

    # Load A[i][j] into xmm0
    imul $8, %r8, %rdi       # Calculate the size needed for the row (n * size of double)
    imul %rcx, %rdi           # Calculate the offset for the row
    add %r10, %rdi            # Add the offset to the pointer to the matrix
    lea (%rdi, %r12, 8), %rdi  # Load the address of the column into %rdi
    movsd (%rdi), %xmm0       # Load the value of A[i][j] into %xmm0

    # Multiply r[i] * A[i][j]
    mulsd %xmm1, %xmm0        # r[i] * A[i][j]

    # Add s[j] + r[i] * A[i][j]
    addsd %xmm0, %xmm2        # s[j] + r[i] * A[i][j]

    # Store the result in s[j]
    lea (%r11, %r12, 8), %rdi  # Load the address of the vector s into %rdi
    movsd %xmm2, (%rdi)       # Store the result in s[j]

.P2:
    # Load A[i][j] into xmm0
    imul $8, %r8, %rdi       # Calculate the size needed for the row (n * size of double)
    imul %rcx, %rdi           # Calculate the offset for the row
    add %r10, %rdi            # Add the offset to the pointer to the matrix
    lea (%rdi, %r12, 8), %rdi  # Load the address of the column into %rdi
    movsd (%rdi), %xmm0       # Load the value of A[i][j] into %xmm0

    # Load p[j] into xmm1
    lea (%r13, %r12, 8), %rdi  # Load the address of the vector p into %rdi
    movsd (%rdi), %xmm1       # Load the value of p[j] into %xmm1

    # Multiply A[i][j] * p[j]
    mulsd %xmm1, %xmm0        # A[i][j] * p[j]

    # Load q[i] into xmm2 
    lea (%rsi, %rcx, 8), %rdi  # Load the address of the vector q into %rdi
    movsd (%rdi), %xmm2       # Load the value of q[i] into %xmm2

    # Add q[i] + A[i][j] * p[j]
    addsd %xmm0, %xmm2        # q[i] + A[i][j] * p[j]

    # Store the result in q[i]
    lea (%rsi, %rcx, 8), %rdi  # Load the address of the vector q into %rdi
    movsd %xmm2, (%rdi)       # Store the result in q[i]

    # Increment the column counter
    inc %r12                  # Increment the column counter
    jmp .mainc_col_loop       # Jump back to the start of the column loop

.mainc_next_row:
    inc %rcx                  # Increment the row counter
    jmp .mainc_row_loop       # Jump back to the start of the row loop

.mainc_end:
    # Function epilogue
    pop %rbp
    ret

.global main_computation_p2
main_computation_p2:
    # Function prologue
    push %rbp
    mov %rsp, %rbp

    # Save the parameters
    mov %rdi, %r12         # Pointer to the matrix A
    mov %rsi, %r13         # Pointer to the vector p
    mov %rdx, %r14         # Pointer to the vector q
    mov %rcx, %r15         # Number of rows (n)
    mov %r8, %r10          # Number of columns (m)

    # Initialize the row counter
    xor %rcx, %rcx         # Initialize the row counter

.mainc2_row_loop:
    cmp %r15, %rcx         # Compare counter with number of rows
    je .mainc2_end         # If counter == number of rows, exit loop

    # Initialize the column counter
    xor %r9, %r9           # Initialize the column counter

.mainc2_col_loop:
    cmp %r10, %r9          # Compare counter with number of columns
    je .mainc2_next_row    # If counter == number of columns, exit loop

    # Load q[i] into xmm0
    lea (%r14, %rcx, 8), %rdi # Load the address of the vector q into %rdi
    movsd (%rdi), %xmm0       # Load the value of q[i] into %xmm0

    # Load A[i][j] into xmm1
    imul $8, %r10, %rdi       # Calculate the size needed for the row (m * size of double)
    imul %r9, %rdi            # Calculate the offset for the row
    add %r12, %rdi            # Add the offset to the pointer to the matrix
    lea (%rdi, %rcx, 8), %rdi # Load the address of the column into %rdi
    movsd (%rdi), %xmm1       # Load the value of A[i][j] into %xmm1

    # Load p[j] into xmm2
    lea (%r13, %r9, 8), %rdi  # Load the address of the vector p into %rdi
    movsd (%rdi), %xmm2       # Load the value of p[j] into %xmm2

    # Multiply A[i][j] * p[j]
    mulsd %xmm2, %xmm1        # A[i][j] * p[j]

    # Add q[i] + A[i][j] * p[j]
    addsd %xmm1, %xmm0        # q[i] + A[i][j] * p[j]

    # Store the result in q[i]
    lea (%r14, %rcx, 8), %rdi # Load the address of the vector q into %rdi
    movsd %xmm0, (%rdi)       # Store the result in q[i]

    # Increment the column counter
    inc %r9                   # Increment the column counter
    jmp .mainc2_col_loop     # Jump back to the start of the loop

.mainc2_next_row:
    inc %rcx                  # Increment the row counter
    jmp .mainc2_row_loop     # Jump back to the start of the loop

.mainc2_end:
    # Function epilogue
    pop %rbp
    ret

# print_vector function
# First parameter (%rdi): Pointer to the vector
# Second parameter (%rsi): Size of the vector
.global print_vector
print_vector:
    push %rbp                  # Save base pointer
    mov %rsp, %rbp             # Set stack base pointer

    push %r12                  # Save callee-saved register
    push %r13                  # Save callee-saved register
    mov %rdi, %r12             # Copy the pointer to the vector to R12
    mov %rsi, %r13             # Copy the size of the vector to R13

    xor %rcx, %rcx             # Counter for loop, start at 0

loop_start:
    cmp %r13, %rcx             # Compare counter with vector size
    je loop_end                # If counter == vector size, exit loop

    lea print_format(%rip), %rdi # Load the address of the format string into %rdi
    pxor %xmm0, %xmm0           # Zero out the upper bits of %xmm0
    movsd (%r12, %rcx, 8), %xmm0 # Load current double from the vector into %rax
    mov $1, %eax                # Set the number of floating point arguments to 1
    push %rcx                  # Save the counter
    call printf                # Call printf
    
    pop %rcx                   # Restore the counter
    inc %rcx                   # Increment the counter
    jmp loop_start             # Jump back to the start of the loop

loop_end:
    pop %r13                   # Restore callee-saved register
    pop %r12                   # Restore callee-saved register
    pop %rbp                   # Restore base pointer
    ret                        # Return from the function

# print_matrix function
# First parameter (%rdi): Pointer to the matrix
# Second parameter (%rsi): Number of rows (n)
# Third parameter (%rdx): Number of columns (m)
.global print_matrix
print_matrix:
    push %rbp
    mov %rsp, %rbp

    mov %rdi, %r12          # Pointer to the matrix
    mov %rsi, %r13          # Number of rows (n)
    mov %rdx, %r14          # Number of columns (m)

    xor %rcx, %rcx          # Row counter

.row_loop:
    cmp %rcx, %r13
    je .end_matrix

    # Set up for printing a row (as a vector)
    imul %r14, %rax         # Calculate the offset for the row
    mov %r14, %rsi          # Size of the row (number of columns)
    lea (%r12, %rax, 8), %rdi   # Calculate the address of the current row
    sub $8, %rsp            # Align stack to 16 bytes
    push %rcx               # Save the row counter
    call print_vector       # Print the row
    call print_newline      # Print a newline after the row
    pop %rcx                # Restore the row counter
    add $8, %rsp            # Restore original stack alignment

    inc %rcx                # Move to the next row
    jmp .row_loop

.end_matrix:
    pop %rbp
    ret

# Print new line
.global print_newline
print_newline:
    lea print_nl(%rip), %rdi   # Load the address of the newline string into %rdi
    xor %eax, %eax             # Zero out RAX
    call printf
    ret

.global main
main:
# Print the prompt for the size of the vector
    sub $8, %rsp               # Align stack to 16 bytes
    mov $promptSize, %rdi
    mov  $1, %rsi              # Writing to %rsi zero extends to RSI.
    xor %eax, %eax             # Zeroing EAX is efficient way to clear AL.
    call printf
    add $8, %rsp               # Restore original stack alignment

# Read the size 'n' into a register
    sub $8, %rsp               # Align stack to 16 bytes
    lea formatIn(%rip), %rdi   # Load format for scanf
    lea n_size(%rip), %rsi     # Pass address of the top of stack for input
    call scanf
    add $8, %rsp               # Restore original stack alignment

    # Print new line
    call print_newline

    # Print the prompt for the size of the vector
    sub $8, %rsp               # Align stack to 16 bytes
    mov $promptM, %rdi
    mov  $1, %rsi              # Writing to %rsi zero extends to RSI.
    xor %eax, %eax             # Zeroing EAX is efficient way to clear AL.
    call printf
    add $8, %rsp               # Restore original stack alignment

    # Para ler o valor de m
    sub $8, %rsp               # Align stack to 16 bytes
    lea formatIn(%rip), %rdi  # Load formatIn for scanf
    lea m_size(%rip), %rsi     # Pass address of the top of stack for input
    call scanf
    add $8, %rsp               # Restore original stack alignment

    # Print new line
    call print_newline


# Allocate memory for r
    mov n_size(%rip), %rdi     # Load the size of the vector
    lea r(%rip), %rsi         # Load the pointer to the vector
    call alloc_vector

# Allocate memory for q
    mov n_size(%rip), %rdi     # Load the size of the vector
    lea q(%rip), %rsi         # Load the pointer to the vector
    call alloc_vector

# Allocate memory for p
    mov m_size(%rip), %rdi     # Load the size of the vector
    lea p(%rip), %rsi         # Load the pointer to the vector
    call alloc_vector

# Allocate memory for s
    mov m_size(%rip), %rdi     # Load the size of the vector
    lea s(%rip), %rsi         # Load the pointer to the vector
    call alloc_vector

# Allocate memory for A
    mov n_size(%rip), %rdi        # Load the number of rows (n)
    imul m_size(%rip), %rdi       # Calculate the total number of elements in the matrix (n * m)
    lea a(%rip), %rsi             # Load the pointer to the vector
    call alloc_vector             # Call the alloc_vector function to allocate memory for A
    mov %rax, a(%rip)             # Store the pointer to the allocated memory in the variable a

# Initialize the values of p
    mov p(%rip), %rdi         # Load the pointer to the vector
    mov m_size(%rip), %rsi     # Load the size of the vector
    call init_vector

# Initialize the values of r
    mov r(%rip), %rdi         # Load the pointer to the vector
    mov n_size(%rip), %rsi     # Load the size of the vector
    call init_vector

# Initialize the values of s
    mov s(%rip), %rdi         # Load the pointer to the vector
    mov m_size(%rip), %rsi     # Load the size of the vector
    call init_zero_vector

# Initialize the values of q
    mov q(%rip), %rdi         # Load the pointer to the vector
    mov n_size(%rip), %rsi     # Load the size of the vector
    call init_zero_vector

# Initialize the values of a
    mov a(%rip), %rdi          # Load the pointer to the matrix
    mov n_size(%rip), %rsi     # Load the number of rows (n)
    mov m_size(%rip), %rdx     # Load the number of columns (m)
    call init_matrix           # Call init_matrix with n and m

# Print the values of p
    mov p(%rip), %rdi         # Load the pointer to the vector
    mov m_size(%rip), %rsi     # Load the size of the vector
    call print_vector

# Print new line
    call print_newline

# Print the values of r
    mov r(%rip), %rdi         # Load the pointer to the vector
    mov n_size(%rip), %rsi     # Load the size of the vector
    call print_vector

# Print new line
    call print_newline

# Print the values of s
    mov s(%rip), %rdi         # Load the pointer to the vector
    mov m_size(%rip), %rsi     # Load the size of the vector
    call print_vector

# Print new line
    call print_newline

# Print the values of q
    mov q(%rip), %rdi         # Load the pointer to the vector
    mov n_size(%rip), %rsi     # Load the size of the vector
    call print_vector

# Print two new lines
    call print_newline
    call print_newline

# Print the values of a
    mov a(%rip), %rdi          # Load the pointer to the matrix
    mov n_size(%rip), %rsi     # Load the number of rows (n)
    mov m_size(%rip), %rdx     # Load the number of columns (m)
    call print_matrix          # Call print_matrix with n and m

# Print new line
    call print_newline

# Perform the main computation
    mov p(%rip), %rdi          # Load the pointer to the vector p
    mov q(%rip), %rsi          # Load the pointer to the vector q
    mov r(%rip), %rdx          # Load the pointer to the vector r
    mov s(%rip), %rcx           # Load the pointer to the vector s
    mov n_size(%rip), %r8      # Load the number of rows (n)
    mov m_size(%rip), %r9     # Load the number of columns (m)
    mov a(%rip), %rax          # Load the pointer to the matrix A
    push %rax                  # Save the pointer to the matrix A
    call main_computation_p1   # Call the main computation function
    pop %rax                   # Restore the pointer to the matrix A

# Print the values of s
    mov s(%rip), %rdi         # Load the pointer to the vector
    mov m_size(%rip), %rsi     # Load the size of the vector
    call print_vector

# Print new line
    call print_newline

# Print the values of q
    mov q(%rip), %rdi         # Load the pointer to the vector
    mov n_size(%rip), %rsi     # Load the size of the vector
    call print_vector

# Print new line
    call print_newline

# Flush the output
xor %rdi, %rdi              # Passing NULL to fflush flushes all open output streams
call fflush


# Jump to the exit code
    jmp exit

exit:
    # Exit the program
    mov $60, %rax  # sys_exit syscall number
    xor %rdi, %rdi  # Exit status 0, indicating success. Use other values for errors.
    syscall         # Invoke the kernel
