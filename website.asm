format ELF64 executable

SYS_write = 1
SYS_exit = 60
SYS_socket = 41

AF_INET = 2
SOCK_STREAM = 1

macro write fd, buf, count
{
    mov rax, SYS_write
    mov rdi, fd
    mov rsi, buf
    mov rdx, count
    syscall
}

;; int socket(int domain, int type, int protocol);
macro socket domain, type, protocol
{
    mov rax, SYS_socket
    mov rdi, domain
    mov rsi, type
    mov rdx, protocol
    syscall
}

macro exit code
{
    mov rax, SYS_exit
    mov rdi, code
    syscall
}

segment readable executable
entry main
main:
    write 1, start, start_len
    socket AF_INET, SOCK_STREAM, 0
    exit 0
segment readable writable
start db "Starting Web Server", 10
start_len = $ - start