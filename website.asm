format ELF64 executable

SYS_write equ 1
SYS_close equ 3
SYS_socket equ 41
SYS_accept equ 43
SYS_bind equ 49
SYS_listen equ 50
SYS_exit equ 60

AF_INET equ 2
SOCK_STREAM equ 1
INADDR_ANY equ 0
PORT equ 14619

STDIN equ 0
STDOUT equ 1
STDERR equ 2

MAX_CONN equ 5

macro syscall1 number, a
{
    mov rax, number
    mov rdi, a
    syscall
}

macro syscall2 number, a, b
{
    mov rax, number
    mov rdi, a
    mov rsi, b
    syscall
}

macro syscall3 number, a, b, c
{
    mov rax, number
    mov rdi, a
    mov rsi, b
    mov rdx, c
    syscall
}

macro close fd
{
    syscall1 SYS_close, fd
}

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

macro bind sockfd, addr, addr_len
{
    syscall3 SYS_bind, sockfd, addr, addr_len
}

; int listen(int sockfd, int backlog);
macro listen sockfd, backlog
{
    syscall2 SYS_listen, sockfd, backlog
}

; int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
macro accept sockfd, addr, addr_len
{
    syscall3 SYS_accept, sockfd, addr, addr_len
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
    ;; entry point addr 0x4000b0
    write STDOUT, start, start_len

    write STDOUT, socket_trace_msg, socket_trace_msg_len
    socket AF_INET, SOCK_STREAM, 0
    cmp rax, 0
    jl error
    mov qword [sockfd], rax

    write STDOUT, bind_trace_msg, bind_trace_msg_len
    ; assign IP, PORT 
    mov word [servaddr.sin_family], AF_INET
    mov word [servaddr.sin_port], PORT
    mov dword [servaddr.sin_addr], INADDR_ANY 
    ; int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
    bind [sockfd], servaddr, sizeof_servaddr
    cmp rax, 0
    jl error

    write STDOUT, listen_trace_msg, listen_trace_msg_len
    ; int listen(int sockfd, int backlog);
    listen [sockfd], MAX_CONN
    cmp rax, 0
    jl error

next_request:    
    write STDOUT, accept_trace_msg, accept_trace_msg_len
    ; int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
    accept [sockfd], cliaddr, sizeof_cliaddr
    cmp rax, 0
    jl error
    mov [connfd], rax

    write [connfd], response, response_len

    jmp next_request
    
    write STDOUT, ok_msg, ok_msg_len
    close [sockfd]
    exit 0

error:
    write STDERR, error_msg, error_msg_len
    close [sockfd]
    exit 1

segment readable writable
struc sockaddr_in 
{
    .sin_family dw 0
    .sin_port dw 0
    .sin_addr dd 0
    .sin_zero dq 0
}
sockfd dq 0
connfd dq 0
servaddr sockaddr_in
sizeof_servaddr = $ - servaddr
cliaddr sockaddr_in
sizeof_cliaddr dq sizeof_servaddr

hello db "Hello from flat assembler!",10
hello_len = $ - hello

response db "HTTP/1.1 200 OK", 13, 10
         db "Content-Type: text/html; charset=utf-8", 13, 10
         db "Connection: close", 13, 10
         db 13, 10
         db "<h1>Hello from flat assembler!</h1>"
response_len = $ - response

start db "INFO: Starting Web Server!", 10
start_len = $ - start

ok_msg db "INFO: OK!", 10
ok_msg_len = $ - ok_msg

socket_trace_msg db "INFO: Creating a socket ...", 10
socket_trace_msg_len = $ - socket_trace_msg

bind_trace_msg db "INFO: Binding the socket ...", 10
bind_trace_msg_len = $ - bind_trace_msg

listen_trace_msg db "INFO: listening to the socket ...", 10
listen_trace_msg_len = $ - listen_trace_msg

accept_trace_msg db "INFO: Waiting for client connections ...", 10
accept_trace_msg_len = $ - accept_trace_msg

error_msg db "ERROR!", 10
error_msg_len = $ - error_msg

;; db - 1 byte
;; dw - 2 byte
;; dd - 4 byte
;; dq - 8 byte
