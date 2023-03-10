;-----------------------------------
;Print frame on user screen
;-----------------------------------
;Entry: ES = 0b800h (set on video memory start addr)
;       BX = attr: start of array of printing chrs
;               1, 2 values -  left corner shift 
;               3           -  len
;               4           -  height
;               5           -  colour
;               6, 7, 8     -  symbols in high str
;               9, 10, 11   -  symbols in mid str
;               12, 13, 14  -  symbols in low str
;Exit: None 
;Destroys: AX, BX = end of msg, CX, DX, SI, DI, BP
;-----------------------------------
Frameprint      proc
 
                xor  dh, dh              ;-|
                xor  ah, ah              ; |
                                         ; |
                call Skipspaces          ; |
                call Read_d_num          ; |
                mov  al, 2d              ; |
                mul  dl                  ; | set di
                                         ; |
                mov  di, ax              ; |
                                         ; |
                call Skipspaces          ; |
                call Read_d_num          ; |
                mov  al, 160d            ; |
                mul  dl                  ; |
                add  di, ax              ;-|

                call Skipspaces          ;-|
                call Read_d_num          ; | set len
                mov  si, dx              ;-| 


                call Skipspaces          ;-|
                call Read_d_num          ; |set height
                mov  bp, dx              ;-|
                

                call Skipspaces          ;-|
                call Read_h_num          ;-|set colour

                push bp                  ;-|
                mov  ax, di              ; |
                shr  bp, 1               ; |
                shl  bp, 5               ; |
                add  ax, bp              ; |
                shl  bp, 2               ; |shift for text in ax
                add  ax, bp              ; |
                pop  bp                  ; |
                                         ; |
                push si                  ; | 
                shr  si, 1               ; | 
                shl  si, 1               ; |
                add  ax, si              ; |
                pop  si                  ;-|

                push ax                  ;-|push shift for text
                mov ah, dl               ;mov colour
                
                call Skipspaces          ;-|
                call Read_d_num          ; |
                cmp  dl, 0               ; |
                je   @@scanuser          ; |
                cmp  dl, 1               ; |
                je   @@theme1            ; |
                cmp  dl, 2               ; |
                je   @@theme2            ; |
                cmp  dl, 3               ; | 
                je   @@theme3            ; |
                jmp  @@error             ; |
@@theme1:       
                push bx                  ; | set theme
                mov  bx, offset theme_1  ; |
                jmp  @@scanchr           ; |
@@theme2:
                push bx                  ; |
                mov  bx, offset theme_2  ; |
                jmp  @@scanchr           ; |
@@theme3:
                push bx                  ; |
                mov  bx, offset theme_3  ; |
                jmp  @@scanchr           ;-|

@@scanuser: 
                call Skipspaces 
                add  bx, 18d
                push bx
                sub  bx, 18d

@@scanchr:      
                call Skipspaces         ;-|
                call Read_h_num         ; |set left high symb
                mov al, dl 
                call Read_h_num         ;-|
                mov dh, dl 
                call Read_h_num         ;-|

                mov  cx, si             ;len in cx
                call Framestring

                add  di, 160d           ;-|
                sub  di, si             ; |next str
                sub  di, si             ;-|

                call Read_h_num         ;-|
                mov al, dl 
                call Read_h_num         ;-|
                mov dh, dl 
                call Read_h_num        

                dec  bp 
                
@@mid:                
                mov  cx, si             ;len in cx
                call Framestring
                
                add  di, 160d           ;-|
                sub  di, si             ; |next str
                sub  di, si             ;-|
                
                dec  bp
             
                cmp  bp, 1
                jne  @@mid


                call Read_h_num         ;-|
                mov al, dl 
                call Read_h_num         ;-|
                mov dh, dl 
                call Read_h_num    

                mov  cx, si             ; len in cx
                call Framestring


                pop  bx 
                pop  si                 ;pop shift for text
                call Skipspaces
                inc  bx 
                push ax 
                call strlen_to_quote 
                shr  ax, 1
                shl  ax, 1
                mov  cx, ax 
                mov  ax, si 
                sub  ax, cx
                mov di, ax
                dec bx
                pop ax
                call Skipspaces
                call Print_text                
                
                ret

@@error:        pop  dx
                pop  dx
                mov  ah, 09h
                mov  dx, offset error
                int  21h

                ret
                endp
;-----------------------------------

;-----------------------------------
;Find len of string up to quote 
;-----------------------------------
;Entry: BX = attr: start of str
;Exit:  AX := len of str
;Destroys:
;-----------------------------------
strlen_to_quote proc


                cld
                
                push bx 
                
                mov  al, "'"
                dec  bx 

@@next:         inc  bx 
                ;mov  cx, 100h
                cmp  byte ptr[bx], al 
                jne  @@next
        
                mov ax, bx 
                pop  bx 
                sub  ax, bx


                ret 
                endp 
;-----------------------------------
;-----------------------------------
;print text of frame 
;-----------------------------------
;Entry: ES = 0b800h (set on video memory start addr)
;       BX attr: start of text (MUST START AND END WITH ' symbol)
;       DI = attr: start addr of printing
;       AH = attr: colour
;Exit:  None 
;Destroys: AL, DI += 2*(len_of_str + 2), BX = end of msg (symbol '), (DX and AH if error)
;-----------------------------------
Print_text      proc

                cmp  byte ptr [bx], "'"
                jne  @@error
                inc  bx

@@next_symb:    mov  al, [bx]
                mov  word ptr es:[di], ax  
                add  di, 2  

                inc  bx 
                cmp  byte ptr [bx], "'"
                jne  @@next_symb
                ret 
        
@@error:        mov  ah, 09h
                mov  dx, offset print_text_err
                int  21h

                ret
                endp 
;-----------------------------------
;-----------------------------------
;print string of frame 
;-----------------------------------
;Entry: ES = 0b800h (set on video memory start addr)
;       DI = attr: start addr of printing
;       CX = attr: len of str
;       AH = attr: colour
;       AL = attr: left symbol
;       DH = attr: mid symbol
;       DL = attr: right symbol
;Exit:  None 
;Destroys: CX = 0, DI += 2 * CX_start_value 
;-----------------------------------
Framestring     proc


                stosw                                           ;-| write in mem left symbol
                mov al, dh                                      ;-| mov in ax mid symbol
                sub cx, 2                                       ;-| cx = num of mid symbols to write
                rep stosw                                       ;-| writing mid symbols
                mov al, dl                                      ;-| mov right symbol
                stosw                                           ;-| write right smbl


                ret
                endp 
;-----------------------------------
;-----------------------------------
;Read num up to 255d from string
;!!!after num must be a space symbol ' '!!!
;-----------------------------------
;Entry; BX = attr: start of string with number
;Exit:  DL = num
;       BX = addr of next symbol after num 
;Destroys: AL, CX
;-----------------------------------
Read_d_num      proc  

                xor dl, dl    
                mov cx, 3
                jmp @@start

@@r_next:       mov al, dl
                shl al, 3                                      ;-|
                shl dl, 1                                      ; | dl *= 10
                add dl, al                                     ;-|

@@start:        add dl, [bx]                                    ;-|
                sub dl, '0'                                     ; | dl += (int)[di++]
                inc bx                                          ;-|

                cmp byte ptr [bx], ' '                          ;-|ret if end of num
                je @@end 
                loop @@r_next 


@@end:          ret
                endp  
;-----------------------------------
;-----------------------------------
;Read hex num up to 255d from string
;-----------------------------------
;Entry; BX = attr: start of string with number
;Exit:  DL = num
;       BX = addr of next symbol after num 
;Destroys: CX
;-----------------------------------
Read_h_num      proc  


                xor dl, dl
                mov cx, 2
                jmp @@start

@@r_next:       shl dl, 4

@@start:        add dl, byte ptr [bx]
                cmp byte ptr [bx], '9'
                jna @@digit

                sub dl, 'A'
                add dl, 0Ah  
                jmp @@is_end
                
@@digit:        sub dl, '0'

@@is_end:       inc bx
                cmp byte ptr [bx], ' '
                je @@end
                loop @@r_next


@@end:          ret
                endp  
;-----------------------------------
;-----------------------------------
;skip space symbols in str
;-----------------------------------
;Entry; BX = attr: addr of string
;Exit:  BX = first not space symbol
;Destroys: None
;-----------------------------------
Skipspaces      proc  


                dec bx

@@next:         inc bx
                cmp byte ptr [bx], ' '
                je @@next


                ret
                endp  
;-----------------------------------

theme_1           db 'DAC4BFB320B3C0C4D9', "'enter your text'"
theme_2           db '060306032003060306', "'enter your text'"
theme_3           db 'C9CDBBBA20BAC8CDBC', "'enter your text'"
error             db 'error$'            
print_text_err    db "error: msg must start with '$"     