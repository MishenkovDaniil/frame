.model tiny
.code
org 100h
locals @@

INCLUDE         ../macros/vidmem.asm
INCLUDE         ../macros/exit.asm

Start:          LoadVideoES
                call clean_screen
                xor bx, bx

                mov di, 81h
                call Frameprint
                Exit

INCLUDE         f_clean.asm
INCLUDE         f_frame.asm

end		Start