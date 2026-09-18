%include "asm_io.inc"

segment .data
c_prompt        db  "How many readings? ", 0
r_prompt        db  "Reading ", 0
si_prompt       db  " - sensor id: ", 0
v_prompt        db  " - value: ", 0

packed_prompt   db "Packed: ", 0
sum_prompt      db "Sum: ", 0
avg_prompt      db "Average: ", 0
largest_prompt  db "Largest from sensor: ", 0
above_prompt    db "Above average: ", 0
first_prompt    db "First reading unpacked: sensor ", 0
value_prompt    db ", value ", 0
space         db " ", 0

count           dd 0
sum             dd 0
avg             dd 0
largest_val      dd 0
largest_sen     dd 0
above_count     dd 0

segment .bss
readings    resd 20
packed      resd 1          ; one doubleword

segment .text
        global  _asm_main
_asm_main:
    enter   0,0               
    pusha

; TODO 1
read_count:
    mov     eax, c_prompt   
    call    print_string    
    call    read_int
    
    ; check if valid count input
    cmp     eax, 1
    jl      read_count

    cmp     eax, 20
    jg      read_count

    mov     esi, eax                ; esi <- stores total readings
    mov     dword [count], 0
    mov     dword [sum], 0
    mov     dword [largest_val], 0
    mov     dword [largest_sen], 0

; TODO 2
read_loop:
    cmp     [count], esi
    jge     read_fin

read_sensor:
    ; read sensor ID
    mov     eax, r_prompt
    call    print_string

    mov     eax, [count]
    inc     eax
    call    print_int

    mov     eax, si_prompt
    call    print_string
    call    read_int

validate_sensor:
    ; validate 0–15
    cmp     eax, 0
    jl      read_sensor

    cmp     eax, 15
    jg      read_sensor

    mov     edi, eax             ; edi <- stores sensor id

read_value:
    ; read value

    mov     eax, r_prompt
    call    print_string

    mov     eax, [count]
    inc     eax
    call    print_int

    mov     eax, v_prompt
    call    print_string
    call    read_int

validate_value:
    ; validate 0–4095
    cmp     eax, 0
    jl      read_value

    cmp     eax, 2095
    jg      read_value

    ; eax stores valid vanue rn
    ; add value to sum

    add     [sum], eax

    ; check if largest value

    cmp     eax, [largest_val]
    jle     not_largest

    mov     [largest_val], eax
    mov     [largest_sen], edi


; TODO 3
not_largest:
    ; save value temp
    mov     edx, eax

    ; sensor id
    mov     eax, edi
    and     eax, 0x0F
    shl     eax, 12             ; shifts to bits 12-15
    
    ; value
    and     edx, 0x0FFF

    ; combine
    or      eax, edx

    ; eax packed dword

    mov     edx, [count]
    mov     [readings + edx*4], eax

    inc     dword [count]
    jmp     read_loop
 
; TODO 4
read_fin:
    ; calc for avg
    mov     eax, [sum]
    mov     edx, 0
    div     esi 

    mov     [avg], eax

    ; print packed values
    call    print_nl

    mov     eax, packed_prompt
    call    print_string

    mov     dword[count], 0

print_packed:
    cmp     [count], esi
    jge     packed_done

    mov     edx, [count]
    mov     eax, [readings + edx*4]
    call    print_int

    inc     dword [count]

    cmp     [count], esi
    jge     packed_done

    mov     eax, space
    call    print_string

    jmp     print_packed

packed_done:
    call    print_nl
    ; print sum
    mov     eax, sum_prompt
    call    print_string

    mov     eax, [sum]
    call    print_int
    call    print_nl

    ;  print average
    mov     eax, avg_prompt
    call    print_string

    mov     eax, [avg]
    call    print_int
    call    print_nl

    ;  print largest sensor
    mov     eax, largest_prompt
    call    print_string

    mov     eax, [largest_sen]
    call    print_int
    call    print_nl


    ; count values 
    mov     dword [above_count], 0
    mov     dword [count], 0

above_loop:
    cmp     [count], esi
    jge     above_done

    mov     edx, [count]
    mov     eax, [readings + edx*4]

    ; extract value from bits 0–11
    and     eax, 0x0FFF

    ; strictly greater than average
    cmp     eax, [avg]
    jle     not_above

    inc     dword [above_count]

not_above:
    inc     dword [count]
    jmp     above_loop

above_done:
    ;  print above average
    mov     eax, above_prompt
    call    print_string

    mov     eax, [above_count]
    call    print_int
    call    print_nl

    ;  unpack first reading
    mov     eax, first_prompt
    call    print_string

    ; read first packed DWORD from memory
    mov     eax, [readings]

    ; save packed value
    mov     edx, eax

    ; extract sensor ID
    shr     eax, 12
    and     eax, 0x0F
    call    print_int

    mov     eax, value_prompt
    call    print_string

    ; extract value
    mov     eax, edx
    and     eax, 0x0FFF
    call    print_int

    call    print_nl

    popa
    mov     eax, 0            ; return back to C
    leave                     
    ret