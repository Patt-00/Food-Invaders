; Food enemy type metadata and the complete ASCII designs from the team document.
; Each row is padded to the artwork's documented width for rectangle rendering.
%macro padded_art_row 2
%%row_start:
    db %1
    times (%2 - ($ - %%row_start)) db ' '
%endmacro

type_table:
 dd 1,22,16,10,art_cupcake,0x0D
 dd 1,14,16,10,art_fries,0x0E
 dd 2,14,11,20,art_burger,0x0B
 dd 1,14,16,20,art_hotdog,0x0C
 dd 2,14,16,30,art_pizza,0x0A
 dd 20,15,16,500,art_rat,0x0F

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
