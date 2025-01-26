    global _start

    section .data

prompt: db "Guess a number between 1 and 100: "
invalid_msg: db "Input must be a number between 1 and 100!",10,10
low_msg: db "Too low!",10,10
high_msg: db "Too high!",10,10
win_msg: db "You win!",10
decode_lut: db 1,10,100

    section .bss

random_number: resb 1
input_buf: resb 16

    section .text

    ; Writes data to stdout
    ; 
    ; rsi = pointer to message
    ; rdx = number of bytes of message
    ; Returns: rax = number of bytes written
write:
    mov rax, 1 ; write syscall
    mov rdi, 1 ; write to stdout
    syscall
    ret

    ; Reads data from stdin
    ; 
    ; rsi = pointer to buf
    ; rdx = size of buf in bytes
    ; Returns: rax = number of bytes read
read:
    xor rax, rax ; read syscall
    xor rdi, rdi ; read stdin
    syscall
    ret

    ; Puts a random byte in `random_number` between 1 and 100
    ; by calling `getrandom` syscall
    ;
    ; Clobbers: rax, rdi, rsi, rdx, rcx, r11
randomize:
    mov rax, 318
    mov rdi, random_number
    mov rsi, 1
    xor rdx, rdx
    syscall

    ; *random_number = *random_number % 100
    mov rax, [random_number]
    mov rdi, 100
    div rdi
    mov [random_number], rdx

    ret

handle_invalid_input:
    mov rsi, invalid_msg
    mov rdx, 43
    call write
    jmp gameloop

_start:
    call randomize

gameloop:
    ; print prompt to screen
    mov rsi, prompt
    mov rdx, 34
    call write

    ; read user input
    mov rsi, input_buf
    mov rdx, 16
    call read

    ; r15 = bytes in input_buf (sans new line)
    lea r15, [rax - 1]

    ; validate user input
    ; 1. check input is
    cmp r15, 0
    je gameloop

    ; 2. check that the size makes sense
    cmp r15, 3
    jg handle_invalid_input

    ; 3. check for non-numeric characters
    ; numberic characters live between 48 and 57
validate_characters:
    xor r12, r12 ; r12 = index
validate_loop:
    cmp byte [input_buf + r12], 48
    jl handle_invalid_input
    cmp byte [input_buf + r12], 57
    jg handle_invalid_input
    inc r12
    cmp r12, r15
    jne validate_loop 

    ; interpret user input as number
interpret_user_input:
    xor r12, r12 ; r12 = index
    xor r14, r14 ; r14 = guess number
interpret_loop:
    ; r13 = offset into `input_buf`
    lea r13, [r15 - 1]
    sub r13, r12

    ; rbx = guess digit
    xor rbx, rbx
    mov bl, [input_buf + r13] 
    sub rbx, 48

    ; rax = guess digit * position power (digit * 10 ^ index)
    xor rax, rax
    mov al, [decode_lut + r12]
    mul rbx
    add r14, rax

    inc r12
    cmp r12, r15
    jne interpret_loop

    ; validate user number
validate_bounds:
    cmp r14, 1
    jl handle_invalid_input
    cmp r14, 100
    jg handle_invalid_input
    
    ; check
check_guess:
    cmp r14b, byte [random_number]
    je victory
    jl too_low
    ; jg too_high

too_high:
    mov rsi, high_msg 
    mov rdx, 11
    jmp fail_epilogue
too_low:
    mov rsi, low_msg 
    mov rdx, 10

    ; increment guess counter
fail_epilogue:
    call write
    jmp gameloop

    ; exit
victory:
    mov rsi, win_msg
    mov rdx, 9
    call write

    mov rax, 60
    xor rdi, rdi
    syscall
