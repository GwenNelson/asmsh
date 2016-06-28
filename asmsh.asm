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
extern _execvp
extern _chdir
extern _snprintf
extern _strtok
extern _memset
extern _waitpid
extern _perror
extern _using_history
extern _add_history

section .data
	UNIX_PROMPT: db "%s@%s:%s$ ",0
	ZERO_STR: db 10,0
	STRTOK_SEP_STR: db " ",0
	ERR_EXEC_STR: db "Error executing command",0
	
	QUIT_CMD_STR: db "quit",0
	EXIT_CMD_STR: db "exit",0
	CD_CMD_STR: db "cd ",0


	PROMPT_STR: times 4096 db 0
	HOSTNAME_STR: times 50 db 0
	EXEC_CMD: times 2 dd 0

	ARGS: times 64 dd 0

section .text
	global _main

_main:
	push rbp
	call _using_history
	pop rbp

sh_loop:
	call unix_prompt
	mov r14,1
	mov r15,1
	mov rax,1
	
	push rbp
	mov rdi,PROMPT_STR
	call _readline
	pop rbp
	
	mov  r14,rax

	mov rdi,r14
	push rbp
	call _add_history
	pop rbp

	mov rdi,r14
	mov rsi,ZERO_STR
	mov rdx,1
	push rbp
	call _strncmp
	pop rbp	
	cmp rax,0
	je sh_loop
	
	mov rdi,r14
	mov rsi,QUIT_CMD_STR
	mov rdx,4
	push rbp
	call _strncmp
	pop rbp
	
	mov r15,rax
	cmp r15,0
	je quit
	
	mov rdi,r14
	mov rsi,EXIT_CMD_STR
	mov rdx,4
	push rbp
	call _strncmp
	pop rbp
		
	mov r15,rax
	cmp r15,0
	je quit

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
aftersplit:	
	push rbp
	call _fork
	pop rbp
	cmp rax,0
	je spawn_cmd
	mov rdi,rax  ; we're the parent, setup waitpid
	mov rsi,0
	mov rdx,0
	push rbp
	call _waitpid
	pop rbp
	mov r15,1
	jmp freecmdline

spawn_cmd:
	push rbp
	mov rdi,[EXEC_CMD]
	mov rsi,ARGS
	mov rdx,0
	call _execvp
	; if we get to here, something went wrong with the _execvp call
	mov rdi,ERR_EXEC_STR
	call _perror
	jmp quit ; we are still in the fork() child, so die

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
	mov rdi, rax
	call _chdir
	pop rbp
	jmp freecmdline

split_line:
	;rdi register set by caller
	mov r13, rdi ; save rdi

	mov rdi,ARGS ; clear ARGS
	mov rsi,0
	mov rdx,128  ; 64 64-bit pointers comes to 128 bytes
	call _memset

	mov rdi, r13
	mov rsi, STRTOK_SEP_STR
	call _strtok
	mov [EXEC_CMD],rax

	; store argv[0]
	mov r13,ARGS
	add r13,0
	mov [r13], rax

split_line_loop:
	mov rdi, 0                ; invoke strtok() again to get command params
	mov rsi, STRTOK_SEP_STR
	call _strtok
	cmp rax, 0

	je split_line_done ; if strtok returns NULL, we're done

	mov r13,ARGS       ; increment the index into ARGS and store the param
	add r13,8
	mov [r13], rax

	jne split_line_loop

split_line_done:
	mov rax,0
totally:
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
