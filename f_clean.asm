locals @@
.code

;-----------------------------------
;Cleans the screen (without last 3 strings (needed for command line))
;-----------------------------------
;Entry: ES = 0b800h (set on video memory start addr)
;Exit: None 
;Destroys: AX, BX CX
;-----------------------------------
clean_screen    proc
                xor bx, bx

                mov cx, 80d*22d 
@@next:         mov word ptr es:[bx], 0h 
                add bx, 2
                loop @@next

                ret 
                endp
;-----------------------------------