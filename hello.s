    global _start

    section .data

hello_world: db "Hello, world!",10
question: db "What is your name? "
hello_user_prefix: db "Hello there, "
hello_user_suffix: db "!",10

    section .text

    ; rsi = pointer to message
    ; rdx = number of bytes of message
    ; Returns: rax = number of bytes written
write:
    mov rax, 1 ; write syscall
    mov rdi, 1 ; write to stdout
    syscall
    ret

    ; rsi = pointer to buf
    ; rdx = size of buf in bytes
    ; Returns: rax = number of bytes read
read:
    xor rax, rax ; read syscall
    xor rdi, rdi ; read stdin
    syscall
    ret

    ; Allocate 16 bytes memory from the operating system
    ; Returns: rax = memory address
allocate:
    mov rax, 9 ; mmap syscall
    xor rdi, rdi ; addr = 0, let OS decide return addr
    mov rsi, 16 ; allocate 16 bytes
    mov rdx, 3 ; prot = PROT_READ | PROT_WRITE
    mov r10, 0x22 ; flags = MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1 ; fd = -1
    xor r9, r9 ; off = 0
    syscall
    ret

    ; Deallocates a 16 byte chunk allocated by `allocate`
    ; Parameters: rdi = memory address to deallocate
deallocate:
    mov rax, 11
    mov rsi, 16
    syscall
    ret

    ; End the program successfully
exit:
    mov rax, 60 ; exit syscall
    xor rdi, rdi ; return code 0
    syscall
    ret

_start:
    ; alloc space on the stack for the user's name
    mov rsi, hello_world
    mov rdx, 14
    call write

    mov rsi, question
    mov rdx, 19
    call write

    mov rbp, rsp
read_name_loop:
    call allocate
    push rax

    mov rsi, [rsp]
    mov rdx, 16
    call read

    mov r12, rax ; r12 = number of bytes read

    ; is last character read newline?
    mov r13, [rsi + rax - 1]
    cmp r13, 10
    jne read_name_loop

    mov rsi, hello_user_prefix
    mov rdx, 13
    call write

    mov r13, 8 ; r13 = number of bytes into stack 
write_name_loop:
    ; rsi = the (stack) pointer to the pointer of the chunk we want to print
    mov rsi, rbp
    sub rsi, r13

    ; is this the last chunk?
    ; rdx = rsi == rsp ? r12 : 16
    cmp rsi, rsp
    je last_write

    mov rsi, [rsi] ; deref rsi to get the pointer to the chunk
    mov rdx, 16
    call write

    mov rdi, rsi
    call deallocate

    add r13, 8
    jmp write_name_loop

last_write:
    mov rsi, [rsi] ; deref rsi to get the pointer to the chunk
    lea rdx, [r12 - 1]
    call write

    mov rdi, rsi
    call deallocate

    mov rsi, hello_user_suffix
    mov rdx, 2
    call write

    call exit
