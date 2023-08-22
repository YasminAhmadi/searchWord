%ifndef SYS_EQUAL
%define SYS_EQUAL
    sys_read     equ     0
    sys_write    equ     1
    sys_open     equ     2
    sys_close    equ     3
    sys_lseek    equ     8
    sys_create   equ     85
    sys_unlink   equ     87
    sys_getdents equ     217
    sys_mmap     equ     9
    sys_mumap    equ     11
    sys_brk      equ     12
    sys_exit     equ     60
    stdin        equ     0
    stdout       equ     1
    stderr       equ     3
    PROT_READ     equ   0x1
    PROT_WRITE    equ   0x2
    MAP_PRIVATE   equ   0x2
    MAP_ANONYMOUS equ   0x20
    O_RDONLY    equ     0q000000
    O_WRONLY    equ     0q000001
    O_RDWR      equ     0q000002
    O_CREAT     equ     0q000100
    O_APPEND    equ     0q002000
    sys_IRUSR     equ     0q400      ; user read permission
    sys_IWUSR     equ     0q200      ; user write permission
    NL            equ   0xA
    Space         equ   0x20
%endif
;----------------------------------------------------
newLine:
   push   rax
   mov    rax, NL
   call   putc
   pop    rax
   ret
;----------------------------------------------------
space:
   push   rax
   mov    rax, ' '
   call   putc
   pop    rax
   ret
;---------------------------------------------------------
putc:	

   push   rcx
   push   rdx
   push   rsi
   push   rdi 
   push   r11 

   push   ax
   mov    rsi, rsp    ; points to our char
   mov    rdx, 1      ; how many characters to print
   mov    rax, sys_write
   mov    rdi, stdout 
   syscall
   pop    ax

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx
   ret
;---------------------------------------------------------
writeNum:
;Go for rax
   push   rax
   push   rbx
   push   rcx
   push   rdx

   sub    rdx, rdx
   mov    rbx, 10 
   sub    rcx, rcx
   cmp    rax, 0
   jge    wAgain
   push   rax 
   mov    al, '-'
   call   putc
   pop    rax
   neg    rax  

wAgain:
   cmp    rax, 9	
   jle    cEnd
   div    rbx
   push   rdx
   inc    rcx
   sub    rdx, rdx
   jmp    wAgain

cEnd:
   add    al, 0x30
   call   putc
   dec    rcx
   jl     wEnd
   pop    rax
   jmp    cEnd
wEnd:
   pop    rdx
   pop    rcx
   pop    rbx
   pop    rax
   ret

;---------------------------------------------------------
num2str:
;Go for rax, string pointer in rdi
   push   rax
   push   rbx
   push   rcx
   push   rdx

   sub    rdx, rdx
   mov    rbx, 10 
   sub    rcx, rcx
   cmp    rax, 0
   jge    n2swAgain
   push   rax 
   mov    al, '-'
   mov    [rdi], al
   inc    rdi
   pop    rax
   neg    rax  

n2swAgain:
   cmp    rax, 9	
   jle    n2scEnd
   div    rbx
   push   rdx
   inc    rcx
   sub    rdx, rdx
   jmp    n2swAgain

n2scEnd:
   add    al, 0x30
   mov    [rdi], al
   inc    rdi
   dec    rcx
   jl     n2swEnd
   pop    rax
   jmp    n2scEnd
n2swEnd:
   pop    rdx
   pop    rcx
   pop    rbx
   pop    rax
   ret

;---------------------------------------------------------
getc:
   push   rcx
   push   rdx
   push   rsi
   push   rdi 
   push   r11 

 
   sub    rsp, 1
   mov    rsi, rsp
   mov    rdx, 1
   mov    rax, sys_read
   mov    rdi, stdin
   syscall
   mov    al, [rsi]
   add    rsp, 1

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx

   ret
;---------------------------------------------------------

readNum:
; Last result is in RAX
; Doesn't matter how many -
   push   rcx
   push   rbx
   push   rdx

   mov    bl,0
   mov    rdx, 0
rAgain:
   xor    rax, rax
   call   getc
   cmp    al, '-'
   jne    sAgain
   mov    bl,1  
   jmp    rAgain
sAgain:
   cmp    al, NL
   je     rEnd
   cmp    al, ' ' ;Space
   je     rEnd
   sub    rax, 0x30
   imul   rdx, 10
   add    rdx,  rax
   xor    rax, rax
   call   getc
   jmp    sAgain
rEnd:
   mov    rax, rdx 
   cmp    bl, 0
   je     sEnd
   neg    rax 
sEnd:  
   pop    rdx
   pop    rbx
   pop    rcx
   ret

;-------------------------------------------
printString:
; go rsi
    push    rax
    push    rcx
    push    rsi
    push    rdi

    mov     rdi, rsi
    call    GetStrlen
    mov     rax, sys_write  
    mov     rdi, stdout
    syscall 
    
    pop     rdi
    pop     rsi
    pop     rcx
    pop     rax
    ret
;-------------------------------------------
; rsi : zero terminated string start 
GetStr:
   call getc
   mov [rsi], al
   inc rsi
   cmp al, NL
   jne GetStr
   dec rsi
   mov byte[rsi], 0 
   ret
;-------------------------------------------
; rsi : zero terminated string start 
GetStrlen:
    push    rbx
    push    rcx
    push    rax  

    xor     rcx, rcx
    not     rcx
    xor     rax, rax
    cld
    repne   scasb
    not     rcx
    lea     rdx, [rcx -1]  ; length in rdx

    pop     rax
    pop     rcx
    pop     rbx
    ret
;-------------------------------------------
CreateFile:
   mov rax, sys_create
   mov rsi, sys_IRUSR | sys_IWUSR
   syscall
   cmp rax, 0
   jl CreateFileError
   ret
CreateFileError:
   ret
;-------------------------------------------
ReadFile:
   mov rax, sys_read
   syscall
   cmp rax, 0
   jl ReadFileError
   mov byte[rsi+rax], 0
   ret
ReadFileError:
   ret
;-------------------------------------------
WriteFile:
   mov rax, sys_write
   syscall
   cmp rax, 0
   jl WriteFileError
   ret
WriteFileError:
   ret
;-------------------------------------------
OpenF:
   mov rax, sys_open
   xor rdx, rdx
   syscall
   cmp rax, 0
   jl OpenFError
   ret
   OpenFError:
   ret
;-------------------------------------------
ReadFolder:
   mov rax, sys_getdents
   mov rsi, folder_files
   mov rdx, 4096
   syscall
   cmp rax, 0
   jl ReadFolderError
   ret
   ReadFolderError:
   ret  
;-------------------------------------------
CloseF:
   mov rax, sys_close
   syscall
   cmp rax, 0
   jl CloseFError
   ret
   CloseFError:
   ret
;-------------------------------------------
AppFile:
   mov rax, sys_open
   mov rsi, O_RDWR | O_APPEND
   syscall
   cmp rax, 0
   jl AppFileError
   ret
AppFileError:
   ret 
;-------------------------------------------

section .data
   result_txt        db "result.txt", 0
   space_asci             db " ", 0

section .bss
   folder_path   resb 100
   word_to_find      resb 100
   result_txt_desc   resq 0
   fol_desc         resq 1000
   s_part        resb 100
   folder_files  resb 4096
   f_part     resb 100
   count_str_format  resb 10
   len_read                 equ 1000
   file_content  resb 1000

section .text
   global _start

_start:
   ;get the folder path
   mov rsi, folder_path
   call GetStr
   mov byte[rsi], '/'
   ;get folder path lengh
   mov rdi, folder_path
   call GetStrlen
   add r10, rdx ;lenght of folder in r10
   ;get the word
   mov rsi, word_to_find
   call GetStr
   ;create the result folder
   mov rdi, result_txt
   call CreateFile
   ;open entry and get the content
   mov rdi, folder_path
   call OpenF
   mov [fol_desc], rax 
   mov rdi, [fol_desc] 
   call ReadFolder
   call CloseF
   ;move file name+paths to r8
   mov r8, folder_files


;get file names in folder
find_file_name:
   ;check for end condition
   cmp byte[r8], 0
   je exit
   ;go to the file name
   add r8, 19
   ;check for the currect file 
   mov rdi, r8
   call GetStrlen
   dec rdx
   cmp byte[r8+rdx], "t"
   je file_name_found
   ;throw away trash (0s)
   temp:
   inc r8
   mov al, [r8]
   cmp al, 0
   je temp
   jmp find_file_name


;process the file found in the folder
file_name_found: 
   ;file name in r8
   mov [f_part], r8

   ;attach folder name to file name
   mov r14, folder_path
   ;r10 : len of folder_path
   add r14, r10
   mov r15, r8
   loop1: 
      mov r13b, [r15]
      cmp r13b, 0
      je end_loop1
      mov [r14], r13b 
      inc r15
      inc r14
      jmp loop1
   end_loop1:
   mov byte [r14], 0


   ;open the file
   mov rdi, folder_path
   mov rsi, O_RDONLY
   call OpenF

   ;read the file
   mov rdi, rax ;file descriptor
   mov rsi, file_content 
   mov rdx, len_read
   call ReadFile
   mov rsi, file_content

   ;close the file
   mov rdi, rax
   call CloseF


   ;count the word in the file
   mov r14, file_content
   ;file content byte content
   xor r12, r12
   ;word byte content
   xor r13, r13
   xor r11, r11
   ;searching the word in file content
   loop2:   
         mov r15, word_to_find
         mov r12b, [r14]
         mov r13b, [r15]
         cmp r12b, 0
         je end_loop2
         cmp r12b, r13b
         je check_word
         inc r14
         jmp loop2
      check_word: 
         mov r12b, [r14]
         mov r13b, [r15]
         cmp r13b, 0
         je check_word_end
         cmp r12b, 0
         je end_loop2
         cmp r12b, r13b
         jne find_space
         inc r14
         inc r15
         jmp check_word
      check_word_end:
         mov r12b, [r14]
         cmp r12b, 0x41   ;check if this byte is not a letter (lower than A)
         jl sucess_word   ;jump to next character if less
         cmp r12b, 0x7A   ;compare al with "z" ==> if greater, not a letter
         jg sucess_word   ;jump to next character if greater
         jmp find_space
      sucess_word:
         ;r11 --> number of matches
         inc r11
         ;check if the file content is finished (also checked in the beginning of the loop)
         cmp r12b, 0
         je end_loop2
         jmp loop2
      find_space:
      ; moving to the next non letter (space)
         inc r14
         mov r12b, [r14]
         cmp r12b, 0
         je end_loop2
         cmp r12b, 0x41  ; This is your existing code again
         jl loop2               ; jump to next character if less
         cmp r12b, 0x7A               ; compare al with "z" (lower bounder)
         jg loop2               ; jump to next character if greater
         jmp find_space
   end_loop2:
   ;convet numbert to string --> count_str_format
   mov rax, r11
   mov rdi, count_str_format
   call num2str

   ;the second part (space/number/newline) of the result
   create_second:
      mov r15, s_part
      mov r14, count_str_format
      mov r13b, [space_asci]
      mov [r15], r13b
      inc r15
      loop3: ;move count_str_format to s_part (byte by byte until reach 0)
         mov r13b, [r14]
         cmp r13b, 0
         je end_loop3
         mov byte [r15], r13b
         inc r14
         jmp loop3
      end_loop3: ;move newline to s_part
      inc r15
      mov r13b, NL
      mov byte [r15], r13b
      inc r15
      mov byte [r15], 0
   end_create_second:

   ;open a file with the name result.txt and write to it
   mov rdi, result_txt
   call AppFile
   mov [result_txt_desc], rax

   ;write in the result file 
   mov rdi, [f_part]
   call GetStrlen 
   mov rsi, [f_part]
   mov rdi, [result_txt_desc]
   call WriteFile
   mov rdi, s_part
   call GetStrlen 
   mov rsi, s_part
   mov rdi, [result_txt_desc]
   call WriteFile

   ;close result file
   mov rdi, [result_txt_desc]
   call CloseF

   ;move to next char and get back to begginig
   mov rdi, r8
   call GetStrlen
   add r8, rdx

   ;throw away trash
   temp1:
   inc r8
   mov al, [r8]
   cmp al, 0
   je temp1


   jmp find_file_name


exit:
   mov eax, 1
   mov ebx, 0
   int 80h