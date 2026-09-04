;
; print_uint - print the 32 bits in eax as an UNSIGNED decimal number.
;
; Carter's print_int reads the same bits as signed, so it shows -100 where
; this shows 4294967196. Block 3 needs both to make its point.
;
; Use it the way you use his routines. Put the value in eax and call:
;
;       mov     eax, [value]
;       call    print_uint
;
; Every register you own is the same afterwards, including eax.
;
; How it works is Block 5 material, so treat it as a box you were handed for
; now. The short version: dividing by ten leaves the last digit in edx as a
; remainder, so the routine peels digits off the bottom, stacks them up, and
; then pops them back in the order you read them. Come back and read it once
; you have written a loop yourself.
;
; "Writing assembly is hell." - Sir Ren

segment .text

print_uint:
        enter   0, 0
        pusha
        pushf

        mov     ebx, 10
        xor     ecx, ecx                ; how many digits we have stacked up

.split:
        xor     edx, edx                ; div reads edx:eax, so clear the top
        div     ebx                     ; eax = eax / 10, edx = eax % 10
        push    edx                     ; digits come off backwards
        inc     ecx
        test    eax, eax
        jnz     .split                  ; nothing left to divide? stop

.emit:
        pop     eax
        add     eax, '0'                ; the digit 7 is the character '7'
        call    print_char
        loop    .emit                   ; loop counts ecx down for us

        popf
        popa
        leave
        ret
