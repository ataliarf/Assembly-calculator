%macro debugPrint 1
    pushad
    mov ebx,0
    mov bl, [debug_mode]
    cmp ebx,0
    jz %%dont_have_debug
    PrintForDebugMode stderr, format_string, %1
    %%dont_have_debug:
    popad
%endmacro

%macro PrintForDebugMode 3
    pushad
    pushfd
    mov esi, %1
    push dword %2            
    push dword %3            
    push dword [esi]
    call fprintf     
    add esp, 12
    popfd
    popad
%endmacro


%macro print 1
    pushad
    push %1
    call printf
    add esp, 4
    popad
%endmacro

%macro print 2
    pushad
    push %2
    push %1
    call printf
    add esp, 8
    popad
%endmacro

%macro stackSizeCheck 0
  pushad
  mov eax, [myStackESP]
  sub eax, [myStackEBP]
  shr eax, 2
  mov ebx, [stack_size]
  sub ebx, eax
  mov [emptySpaceInStack], ebx

  popad
%endmacro

%macro safeMalloc 0
    pushad
    push 1
    push 5
    call calloc
    add esp, 8
    mov dword [x], eax
    popad
    mov eax, dword [x]
%endmacro

%macro safeFree 1
    pushad
    push %1
    call free
    add esp, 4
    popad
%endmacro

section .bss
    myStackESP: resd 1
    myStackEBP: resd 1
    inputBuffer: resb 80
    x: resd 1
    emptySpaceInStack: resd 1
    firstList: resd 1
    secondList: resd 1
    firstData: resb 1
    secondData: resb 1
    carryFlag: resb 1
    sumLinks: resb 1
    prevLink: resd 1
    firstLink: resd 1

section .data
    format_decimal: db "%d", 10, 0
    format_octal: db "%o", 10, 0
    format_string: db "%s", 0	                                            
    format_octal1: db "%o", 0
    new_line: db 10, 0
    calc_msg: db "calc: ", 0
    sum_msg: db "The Sum Is: ", 0
    num_msg: db "The Number You Inserted Is: ", 0
    InsufficientNumberError: db "Error: Insufficient Number of Arguments on Stack",10,0     
    stackOverFlowError: db "Error: not enoght space in stack to fullfill your request",10,0 
    debug_mode: dd 0
    stack_size: dd 5
    error_mode: dd 0
    num_of_op: dd 0

section .text
  align 16
  global main
  extern printf
  extern fprintf 
  extern fflush
  extern malloc 
  extern calloc 
  extern free 
  extern getchar 
  extern fgets 
  extern stdout
  extern stdin
  extern stderr

main:
    push ebp
    mov ebp, esp

    mov ebx, dword [ebp+8]      ; ebx = argc
    mov ecx, dword [ebp+12]     ; ecx = argv
    mov edx, 1
    mov eax, 5

    loop_on_argv:
    cmp edx, ebx
    je loop_on_argv_end
    push eax
    mov eax, edx
    shl eax, 2
    add eax, ecx
    mov edi, dword [eax]        ; edi = argv[i]
    pop eax
    cmp byte [edi], '-'
    jne convert_str_to_number
    mov dword [debug_mode], 1
    jmp cont_loop_on_argv
    convert_str_to_number:
    movzx eax, byte [edi]
    sub eax, '0'
    cmp byte [edi+1], 0
    je cont_loop_on_argv
    sub byte [edi+1], '0'
    shl eax, 3
    or al, byte [edi+1]
    cont_loop_on_argv:
    inc edx
    jmp loop_on_argv

    loop_on_argv_end:
    mov dword [stack_size], eax
    shl eax, 2
    push eax
    call malloc
    add esp, 4
    mov dword [myStackEBP], eax
    mov dword [myStackESP], eax
    pushad
    call myCalc
    popad

main_return:
    mov esp, ebp
    pop ebp
    ret
;------------------Mycalc------------------
myCalc:
    push ebp
    mov ebp, esp

mainLoop:
    print calc_msg

    push dword [stdin]
    push 80
    push inputBuffer
    call fgets
    add esp, 12
    mov ecx, [num_of_op]
    inc ecx
    mov [num_of_op], ecx

    mov eax, inputBuffer
    cmp byte [eax], 112    
    je ifPopAndPrint

    cmp byte [eax], 100
    je ifDuplicate


    cmp byte [eax], 43            ;+
    je ifPlus


    cmp byte [eax], 38            ;&
    je ifUmpersent

    cmp byte [eax], 110            ;n
    je ifNumOfBytes



    cmp byte [eax], 113 
    je quitt
    

nummber:
    stackSizeCheck
    mov edi, [emptySpaceInStack]
    cmp edi,0
    je mainError
    popad



    return_num:
    pushad
    call buildLinkedList
    jmp mainLoop

quitt:
    pushad
    call ifQuit
    popad
    jmp myCalc_return

mainError:
    print stackOverFlowError
    jmp mainLoop


myCalc_return:
    mov esp, ebp
    pop ebp
    ret    
;----------------buildLinkedList-------------------
buildLinkedList:
    push ebp
    mov ebp, esp

    mov eax, inputBuffer

   

Yloop:
    cmp byte [eax], 10
    je .end_of_loop
    inc eax
    jmp Yloop

.end_of_loop:
    dec eax
    mov edi, 0              ; last link in linkedlist

.build_loop:
    cmp eax, inputBuffer
    jl buildLinkedList_return
    mov bl, byte [eax]
    sub bl, '0'
    pushad
    push 5
    call malloc
    add esp, 4
    mov dword [x], eax
    popad
    mov ecx, dword [x]
    mov byte [ecx], bl
    mov dword [ecx+1], 0
    cmp edi, 0
    jne .not_first_link

    mov ebx, dword [myStackESP]
    mov dword [ebx], ecx
    add dword [myStackESP], 4
    jmp .update_link

.not_first_link:
    mov dword [edi+1], ecx

.update_link:
    mov edi, ecx   
    dec eax
    jmp .build_loop

buildLinkedList_return:
    mov eax, dword [myStackESP]
    sub eax, 4
    mov eax, dword [eax]



.loop1:
    cmp eax, 0
    je .exit
    movzx ebx, byte [eax]

    mov eax, dword [eax+1]
    jmp .loop1

.exit:
    popad
    pop ebp
    jmp mainLoop


;---------------------Quit-----------------------
ifQuit:
    push ebp
    mov ebp, esp

    QuitLoop:
    stackSizeCheck
    mov ecx, [emptySpaceInStack]
    mov edx, [stack_size]

    cmp ecx,edx
    je  ifQuit_return

    pushad
    call myPop
    add esp, 4
    push eax
    add esp, 4
    popad
    pushad
    call deleteListOfNumbers
    popad
    jmp QuitLoop

   
    Nowfree_stack:
    pushad
    push dword [myStackEBP]
    call free
    add esp, 4
    popad



ifQuit_return:
    mov eax, [num_of_op]
    dec eax
    print format_octal, eax
    mov esp, ebp
    pop ebp
    ret
;---------------------PopAndPrint-----------------------
ifPopAndPrint:
    push ebp
    mov ebp, esp

    pushad
    stackSizeCheck
    mov ecx, [emptySpaceInStack]
    mov edx, [stack_size]
    cmp ecx,edx
    je .dontPop
    call myPop
    push eax
    call printListOfNumbers
    add esp, 4
    popad
    jmp ifPopAndPrint_return

.dontPop:
    print InsufficientNumberError

ifPopAndPrint_return:
    pop ebp
    jmp mainLoop

;-----------------------Duplicate----------------------
ifDuplicate:
    push ebp
    mov ebp, esp

    stackSizeCheck
    mov ecx, [emptySpaceInStack]
    mov edx, [stack_size]
    cmp ecx, edx
    je .dontPop


    pushad
    call myPop
    mov esi, eax    ;esi is the first
    push eax
    call copyLinkedList
    push eax               ;eax is the second
    call myPush
    
    stackSizeCheck
    mov ecx, [emptySpaceInStack]
    cmp ecx, 0
    je .dontPush
    
    push esi
    call myPush
    add esp, 12
    popad
    jmp .dontPushcheck

.dontPop:
    print InsufficientNumberError
    jmp ifDuplicate_return

.dontPushcheck:
    cmp [error_mode],dword 1
    je dontPush
    jmp ifDuplicate_return


.dontPush:
    print stackOverFlowError

ifDuplicate_return:
    mov [error_mode],dword 0
    pop ebp
    jmp mainLoop

;-----------------------ifPlus----------------------
ifPlus:
    push ebp
    mov ebp, esp

    stackSizeCheck
    mov ecx, [emptySpaceInStack]
    mov edx, [stack_size]
    sub edx, ecx 
    cmp edx, 2
    jb dontAddp
    
    
    call myPop
    mov edx, eax
    
    call myPop
    mov ecx, eax


    push edx
    push ecx
    call addTwoNumbers
    add esp, 8

    debugPrint sum_msg
    mov bl, [debug_mode]
    cmp bl, 0
    je pushsum
    pushad
    push eax
    call printListOfNumbers
    add esp, 4
    popad


pushsum:
    push eax
    call myPush
    add esp, 4
    

    jmp ifPlus_return

dontAddp:
    print InsufficientNumberError

ifPlus_return:
    pop ebp
    jmp mainLoop


;-------------------------MyPop---------------------
myPop:
    push ebp
    mov ebp, esp
    sub [myStackESP], dword 4
    mov ecx, [myStackESP]
    mov eax, [ecx]
    pop ebp
    ret

;--------------------MyPush----------------
myPush:
    push ebp
    mov ebp, esp
    stackSizeCheck
    mov edi,[emptySpaceInStack]
    cmp edi, 0
    jnz pushToStack

dontPush:
        print stackOverFlowError
        mov [error_mode], dword 1
        jmp myPush_return


pushToStack:
   

    mov ecx, [ebp+8]
    mov eax, dword [myStackESP]
    mov dword[eax], ecx
    add dword[myStackESP], 4

myPush_return:
    mov esp,ebp
    pop ebp
    ret

;-----------------CopyLinkedList--------------
copyLinkedList:
    push ebp
    mov ebp,esp
    sub esp, 8

    pushad
    push dword 5
    call malloc
    add esp,4
    mov [ebp-4],eax
    popad

    mov ebx, [ebp-4]                
    mov ecx, dword[ebp+8]               
    mov edi,0

contCopyLinkList:
        mov dl, byte[ecx]           
        mov [ebx],dl                
        mov edi, [ecx+1]
        
        cmp edi,0                  
        jz copyLinkedList_return           

        pushad
        push dword 5
        call malloc                
        mov [ebp-8],eax            
        add esp,4
        popad

        mov eax, [ebp-8]           
        mov [ebx+1], eax            
        mov eax, dword[ecx+1]      
        mov ecx,eax                
        mov ebx, [ebp-8]          
        jmp contCopyLinkList


copyLinkedList_return:
    mov eax, [ebp-4]
    mov esp,ebp
    pop ebp
    ret

;----------------lengthOfLinkedList---------------
 lengthOfLinkedList:
    push ebp
    mov ebp,esp
    mov esi, 1              ;length counter              
    mov ecx, dword[ebp+8]    ; linked list.curr
    mov edi,0               ;linked list.next

lengthLoop:
        mov edi, dword [ecx+1]
        cmp edi, 0                  
        je lengthLinkedList_return  
        inc esi
        mov ecx, edi
        jmp lengthLoop

lengthLinkedList_return:
    mov eax, esi
    mov esp,ebp
    pop ebp
    ret

;--------------addTwoNumbers----------
addTwoNumbers:
    push ebp
    mov ebp,esp

    mov edi, dword[ebp+8]  
    mov esi, dword[ebp+12]

    push edi
    push esi

    mov dword [firstList], edi
    mov dword [secondList], esi
    mov byte [carryFlag], 0
    mov dword [firstLink], 0
    mov dword [prevLink], 0

    addTwoNumbers_loop:
    mov byte [firstData], 0
    mov byte [secondData], 0

    cmp dword [firstList], 0
    jne firstList_ok
    cmp dword [secondList], 0
    jne secondList_ok?

    cmp byte [carryFlag], 1
    je add_one
    jmp addTwoNumbers_return

    firstList_ok:
    mov eax, dword [firstList]
    mov bl, byte [eax]
    mov byte [firstData], bl
    mov eax, dword [firstList]
    mov eax, dword [eax+1]
    mov edx, dword [firstList]
    mov dword [firstList], eax

    secondList_ok?:
    cmp dword [secondList], 0
    je addLinks
    mov eax, dword [secondList]
    mov bl, byte [eax]
    mov byte [secondData], bl
    mov eax, dword [eax+1]
    mov edx, dword [secondList]
    mov dword [secondList], eax

    addLinks:
    mov bl, byte [firstData]
    add bl, byte [secondData]
    add bl, byte [carryFlag]

    safeMalloc
    
    mov cl, bl
    and cl, 7
    mov byte [eax], cl

    shr bl, 3
    mov byte [carryFlag], bl

    cmp dword [firstLink], 0
    jne .not_first

    mov dword [firstLink], eax
    jmp .continue

    .not_first:
    mov ebx, dword [prevLink]
    mov dword [ebx+1], eax
    
    .continue:
    mov dword [prevLink], eax
    jmp addTwoNumbers_loop

    add_one:
    safeMalloc

    mov byte [eax], 1
    mov ebx, dword [prevLink]
    mov dword [ebx+1], eax

addTwoNumbers_return:
    call deleteListOfNumbers
    add esp, 8
    mov eax, dword [firstLink]
    mov esp,ebp
    pop ebp
    ret
;-----------------------------------------

printListOfNumbers:
    push ebp
    mov ebp,esp
    mov ebx, 0
    mov esi, dword[ebp+8]                       ; num list to print

    loopOfReverse:
        mov bl, byte[esi]
        push ebx
        mov edx, dword[esi+1]
        mov esi, edx
        cmp esi, 0
        jnz loopOfReverse
    

    printingList:                                 ; print each link, with leading 0
        pop ebx
        print format_octal1, ebx
        cmp esp, ebp
        jnz printingList

    print new_line

printListOfNumbers_return:
    mov esp,ebp
    pop ebp
    ret

;-----------------------------------------

deleteListOfNumbers:
    push ebp
    mov ebp,esp

    mov esi, dword[ebp+8]                       ; num list to print

    .loop:
    cmp esi, 0
    je deleteListOfNumbers_return
    mov edi, dword [esi+1]
    safeFree esi
    mov esi, edi
    jmp .loop

deleteListOfNumbers_return:
    mov esp,ebp
    pop ebp
    ret

    ;--------------UmpersentTwoNumbers----------
UmpersentTwoNumbers:
    push ebp
    mov ebp,esp

    mov edi, dword[ebp+8]  
    mov esi, dword[ebp+12]

    push edi
    push esi

    mov dword [firstList], edi
    mov dword [secondList], esi
    mov dword [firstLink], 0
    mov dword [prevLink], 0

    UmpersentTwoNumbers_loop:
    mov byte [firstData], 0
    mov byte [secondData], 0

    cmp dword [firstList], 0
    jne Umpersent_firstList_ok
    cmp dword [secondList], 0
    jne Umpersent_secondList_ok?

    jmp UmpersentTwoNumbers_return

    Umpersent_firstList_ok:
    mov eax, dword [firstList]
    mov bl, byte [eax]
    mov byte [firstData], bl
    mov eax, dword [firstList]
    mov eax, dword [eax+1]
    mov edx, dword [firstList]
    mov dword [firstList], eax

    Umpersent_secondList_ok?:
    cmp dword [secondList], 0
    je UmpersentLinks
    mov eax, dword [secondList]
    mov bl, byte [eax]
    mov byte [secondData], bl
    mov eax, dword [eax+1]
    mov edx, dword [secondList]
    mov dword [secondList], eax

    UmpersentLinks:
    mov bl, byte [firstData]
    and bl, byte [secondData]

    safeMalloc
    mov byte [eax], bl


    cmp dword [firstLink], 0
    jne Umpersent_not_first

    mov dword [firstLink], eax
    jmp  Umpersent_continue

    Umpersent_not_first:
    mov ebx, dword [prevLink]
    mov dword [ebx+1], eax
    
    Umpersent_continue:
    mov dword [prevLink], eax
    jmp UmpersentTwoNumbers_loop

UmpersentTwoNumbers_return:
    call deleteListOfNumbers
    add esp, 8
    mov eax, dword [firstLink]
    mov esp,ebp
    pop ebp
    ret

;---------------------ifNumOfBytes-----------------------
ifNumOfBytes:
    push ebp
    mov ebp, esp


    
    stackSizeCheck
    mov ecx, [emptySpaceInStack]
    mov edx, [stack_size]
    cmp ecx,edx
    je dontPopN
    call myPop
    push eax
    call lengthOfLinkedList
    add esp, 4
    mov ebx, eax


    
    mov eax, 3
    mul ebx
    shr eax, 2

    cmp eax, 0
    jne cont 
    
    swich:
    mov eax, 1
    jmp cont


    cont:
    mov edi, eax
    safeMalloc
    mov [eax], edi
   

    push eax
    call myPush
    add esp, 4
    jmp ifNumOfBytes_return


dontPopN:
    print InsufficientNumberError

ifNumOfBytes_return:
    pop ebp
    jmp mainLoop

;-----------------------ifUmpersent----------------------
ifUmpersent:
    push ebp
    mov ebp, esp

    stackSizeCheck
    mov ecx, [emptySpaceInStack]
    mov edx, [stack_size]
    sub edx, ecx 
    cmp edx, 2
    jb .dontAdd
    
    
    call myPop
    mov edx, eax
    
    call myPop
    mov ecx, eax


    push edx
    push ecx
    call UmpersentTwoNumbers
    add esp, 8

    push eax
    call myPush
    add esp, 4
    

    jmp ifUmpersent_return

.dontAdd:
    print InsufficientNumberError

ifUmpersent_return:
    pop ebp
    jmp mainLoop
