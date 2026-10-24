; Food enemy type metadata and the complete ASCII designs from the team document.
; Each row is padded to the artwork's documented width for rectangle rendering.
%macro padded_art_row 2
%%row_start:
    db %1
    times (%2 - ($ - %%row_start)) db ' '
%endmacro

type_table:
 dd 1,11,8,10,0,art_cupcake,0x0D
 dd 1,7,8,10,0,art_fries,0x0E
 dd 2,7,6,20,0,art_burger,0x0B
 dd 1,7,8,20,1,art_hotdog,0x0C
 dd 2,7,8,30,1,art_pizza,0x0A
 dd 20,8,8,500,1,art_rat,0x0F

; Source dimensions are retained so the renderer can sample each sprite at half size.
enemy_source_widths db 22,14,14,14,14,15
enemy_source_heights db 16,16,11,16,16,16

art_cupcake:
    padded_art_row '       ####',22
    padded_art_row '      ######',22
    padded_art_row '     ########',22
    padded_art_row '   ############',22
    padded_art_row '   ############',22
    padded_art_row '   #### @@ ####',22
    padded_art_row '   #### .. ####',22
    padded_art_row '  ##############',22
    padded_art_row '  ##############',22
    padded_art_row '  ##PPPPPPPPPP##',22
    padded_art_row '  ##CCGGCCGGCC##',22
    padded_art_row '  ##GGCCGGCCGG##',22
    padded_art_row '  ##PPPPPPPPPP##',22
    padded_art_row '  ##CCCCCCCCCC##',22
    padded_art_row '  ##CCCCCCCCCC##',22
    padded_art_row '  ##############',22

art_fries:
    padded_art_row '  ##  ##  ##  ',14
    padded_art_row '  ##  ##  ##  ',14
    padded_art_row '  ##  ##  ##  ',14
    padded_art_row '  ##  ##  ##  ',14
    padded_art_row '##############',14
    padded_art_row '##############',14
    padded_art_row '##############',14
    padded_art_row '##############',14
    padded_art_row '##############',14
    padded_art_row '####   @@  @@ ',14
    padded_art_row '####          ',14
    padded_art_row '##############',14
    padded_art_row '##############',14
    padded_art_row '##############',14
    padded_art_row '##############',14
    padded_art_row '##############',14

art_burger:
    padded_art_row '############ ',14
    padded_art_row '##############',14
    padded_art_row '##############',14
    padded_art_row '##   @@  @@   ',14
    padded_art_row '## [WWW][WWW] ',14
    padded_art_row '##############',14
    padded_art_row '##~~~~~~~~~~~~',14
    padded_art_row '##############',14
    padded_art_row '##....------..',14
    padded_art_row '##############',14
    padded_art_row '  ############',14

art_hotdog:
    padded_art_row '  #########  ',14
    padded_art_row '  ############',14
    padded_art_row '####========##',14
    padded_art_row '####========##',14
    padded_art_row '####========##',14
    padded_art_row '####========##',14
    padded_art_row '####========##',14
    padded_art_row '## YY @@  @@ Y',14
    padded_art_row '## YY ========',14
    padded_art_row '####========##',14
    padded_art_row '####========##',14
    padded_art_row '####========##',14
    padded_art_row '####========##',14
    padded_art_row '  ############',14
    padded_art_row '    ########  ',14
    padded_art_row '     ###### ',14

art_pizza:
    padded_art_row '##############',14
    padded_art_row '##############',14
    padded_art_row '#### @@  @@ ##',14
    padded_art_row '####    @   ##',14
    padded_art_row '## .. PP .. PP',14
    padded_art_row '## PP .. PP ..',14
    padded_art_row '##############',14
    padded_art_row '##############',14
    padded_art_row '  ############',14
    padded_art_row '  ############',14
    padded_art_row '  ############',14
    padded_art_row '  ####    ####',14
    padded_art_row '  ####    ####',14
    padded_art_row '  ##        ##',14
    padded_art_row '  ##        ##',14
    padded_art_row '  ##        ##',14

art_rat:
    padded_art_row '##        ##  ',15
    padded_art_row '##        ##',15
    padded_art_row '  ############',15
    padded_art_row '############## ',15
    padded_art_row '##############',15
    padded_art_row '####  @@    @@',15
    padded_art_row '####    ----  ',15
    padded_art_row '##############',15
    padded_art_row '##############',15
    padded_art_row '##############',15
    padded_art_row '  ############',15
    padded_art_row '    ####    ##',15
    padded_art_row '    ####    ##',15
    padded_art_row '    ##      #  ',15
    padded_art_row '   ##      ##  ',15
    padded_art_row '   ##      ##',15
