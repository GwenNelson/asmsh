default rel
extern _printf
extern _exit
extern _readline
extern _free
extern _strncmp
extern _getcwd
extern _getlogin
extern _gethostname
extern _system
extern _fork
extern _execve
extern _chdir
extern _snprintf
extern _strtok
extern _memset
extern environ

section .data
	UNIX_PROMPT: db "%s@%s:%s$ ",0
	PROMPT_STR: times 4096 db 0
	INLINE_STR: dd 0
	HOSTNAME_STR: times 50 db 0
	EXEC_CMD: dd 0
	EXEC_ARGC: dd 0
	EXEC_ARGV: times 10 dd 0
	.len: equ $ - EXEC_ARGV
	
	STRTOK_SEP_STR: db " ",0
	
	QUIT_CMD_STR: db "quit",0
	EXIT_CMD_STR: db "exit",0
	CD_CMD_STR: db "cd ",0

section .text
	global _main

_main:

sh_loop:
	call unix_prompt
	
	push rbp
	mov rdi,PROMPT_STR
	call _readline
	pop rbp
	
	mov  r14,rax
	
	mov rdi,r14
	mov rsi,QUIT_CMD_STR
	mov rdx,4
	push rbp
	call _strncmp
	pop rbp
	
	mov r15,rax
	cmp r15,0
	je freecmdline
	
	mov rdi,r14
	mov rsi,EXIT_CMD_STR
	mov rdx,4
	push rbp
	call _strncmp
	pop rbp
		
	mov r15,rax
	cmp r15,0
	je freecmdline

	mov rdi,r14
	mov rsi,CD_CMD_STR
	mov rdx,3
	push rbp
	call _strncmp
	pop rbp
	
	mov r13,rax
	cmp r13,0
	je handle_cd
	
	mov rdi,r14
	call split_line
	
	push rbp
	mov rdi,[EXEC_CMD]
	call _system
	pop rbp

freecmdline:	
	push rbp
	mov rdi,r14
	call _free
	pop rbp

	cmp r15,0
	jne sh_loop
	je quit

quit:
	push rbp
	mov rdi,0
	mov rax,0
	call _exit
	pop rbp

handle_cd:
	mov r12,3
	add r12,r14
	mov rdi,r12
	mov rsi, STRTOK_SEP_STR
	push rbp
	call _strtok ; cheap way to right trim whitespace
	pop rbp
	push rbp
	call _chdir
	pop rbp
	jmp freecmdline

split_line:
	;rdi register set by caller
	mov rsi, STRTOK_SEP_STR
	call _strtok
	mov [EXEC_CMD], rax ; store the command
	mov r8, 0
	mov [EXEC_ARGC], r8 ; set argc to 0 so we can index the array

	; zero out the EXEC_ARGV array from last time
	mov rdi,EXEC_ARGV
	mov rsi,0
	mov rdx,EXEC_ARGV.len
	call _memset
	
	mov r15, EXEC_ARGV ; store pointer to argv[0]

	; set argv[0]
	mov rdi, EXEC_CMD
	mov [EXEC_ARGV], rdi
	jmp split_line_done

split_line_loop:
	mov rdi, 0                ; invoke strtok() again to get command params
	mov rsi, STRTOK_SEP_STR
	call _strtok
	mov r14, rax

	cmp rax, 0
	je split_line_done ; if strtok returns NULL, we're done

	mov r8, EXEC_ARGC
	inc r8
	mov [EXEC_ARGC],r8

	inc rbx
	mov rax,0
	add [EXEC_ARGV],rbp
	mov [EXEC_ARGV],r14
	inc rbp
	jmp split_line_loop

split_line_done:
	mov rax,0
	ret

unix_prompt:
	mov rdi,0
	call _getlogin
	mov r12, rax

	mov rdi, HOSTNAME_STR
	mov rsi, 49
	call _gethostname
	mov r13, HOSTNAME_STR

	mov rdi,0
	call _getcwd
	mov r14,rax
	
	mov rdi,PROMPT_STR
	mov rsi,4096
	mov rdx,UNIX_PROMPT
	mov rcx,r12
	mov r8,r13
	mov r9,r14
	call _snprintf
	mov rdi,r14
	call _free

	ret
