;
; Block 7 solution: pack three fields into one doubleword, then take it apart.
;
; This file ships in the Block 8 archive. It is here so that a student who
; missed Block 7 can sit the exit check. The exit check asks for the same
; operation on an array.
;
; This file stays out of the Block 7 archive. The Block 7 exercise asks the
; student to write the bit work, so the Block 7 download must not carry it.
;
;       make PROG=b7_solution run
;

%include "asm_io.inc"

segment .data
v_prompt    db  "Version (0-15): ", 0
f_prompt    db  "Flag (0 or 1): ", 0
l_prompt    db  "Length (0-255): ", 0
packed_msg  db  "Packed: ", 0
uv_msg      db  "Unpacked version: ", 0
uf_msg      db  "Unpacked flag: ", 0
ul_msg      db  "Unpacked length: ", 0

segment .bss
packed      resd  1                     ; one doubleword, written before the read

segment .text
        global  _asm_main
_asm_main:
        enter   0,0
        pusha

        ;
        ; Read the three inputs. Mask each one to its field width before the
        ; pack step. The version keeps 4 bits, the flag keeps 1 bit, and the
        ; length keeps 8 bits.
        ;
        ; An unmasked value writes outside its own field. A length of 325 is
        ; 9 bits wide. Its top bit lands in bit 8, which is the flag. A
        ; version of 20 is 5 bits wide. Its top bit lands in bit 16, which
        ; this layout leaves unused.
        ;
        mov     eax, v_prompt
        call    print_string
        call    read_int
        and     eax, 0x0F               ; four bits wide, so keep four bits
        mov     esi, eax

        mov     eax, f_prompt
        call    print_string
        call    read_int
        and     eax, 0x01
        mov     edi, eax

        mov     eax, l_prompt
        call    print_string
        call    read_int
        and     eax, 0xFF
        mov     ecx, eax

        call    print_nl

        ;
        ; Pack. Shift each field up to its place. Merge the fields with or.
        ; The or sets bits and leaves the bits that are already set alone.
        ; The length needs no shift because bits 0 to 7 are its place.
        ;
        mov     eax, esi
        shl     eax, 12                 ; the version to bits 12-15
        mov     ebx, edi
        shl     ebx, 8                  ; the flag to bit 8
        or      eax, ebx
        or      eax, ecx                ; the length is already at bits 0-7
        mov     [packed], eax           ; brackets: store INTO the location

        mov     eax, packed_msg
        call    print_string
        mov     eax, [packed]
        call    print_int
        call    print_nl

        ;
        ; Unpack. Read the value back out of memory for each field. Do not
        ; reuse the register from the pack step. The round trip is the point
        ; of the exercise.
        ;
        ; Shift a field down to the bottom first. Then mask it to its width.
        ; Masking in place also works when the mask matches the field
        ; position. Masking with a low mask before the shift does not work,
        ; because that mask clears every bit above the field.
        ;
        mov     eax, uv_msg
        call    print_string
        mov     eax, [packed]
        shr     eax, 12
        and     eax, 0x0F
        call    print_int
        call    print_nl

        mov     eax, uf_msg
        call    print_string
        mov     eax, [packed]
        shr     eax, 8
        and     eax, 0x01
        call    print_int
        call    print_nl

        mov     eax, ul_msg
        call    print_string
        mov     eax, [packed]
        and     eax, 0xFF               ; no shift needed, it is already at the bottom
        call    print_int
        call    print_nl

        popa
        mov     eax, 0                  ; eax carries the value that main returns
        leave
        ret
