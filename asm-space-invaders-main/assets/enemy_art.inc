; Compact ASCII redraws keep the faces, toppings, and food layers readable.
%macro padded_art_row 2
%%row_start:
    db %1
    times (%2 - ($ - %%row_start)) db ' '
%endmacro

; Enemy metadata: HP, width, height, score, artwork pointer, color.
type_table:
 dd 1,11,8,10,art_cupcake,0x0D
 dd 1,7,8,10,art_fries,0x0E
 dd 2,7,6,20,art_burger,0x0B
 dd 1,7,8,20,art_hotdog,0x0C
 dd 2,8,8,30,art_pizza,0x0A
 dd 20,8,8,500,art_rat,0x0F

art_cupcake:
    padded_art_row '   . . .   ',11
    padded_art_row '  (^^^^^)  ',11
    padded_art_row '|  @   @  |',11
    padded_art_row '|    o    |',11
    padded_art_row '|#########|',11
    padded_art_row '|P.C.G.P.C|',11
    padded_art_row '|C.G.P.C.G|',11
    padded_art_row '+---------+',11

art_fries:
    padded_art_row '|#|#|#|',7
    padded_art_row '|#|#|#|',7
    padded_art_row '|#|#|#|',7
    padded_art_row '|#|#|#|',7
    padded_art_row '+-----+',7
    padded_art_row '|@ @  |',7
    padded_art_row '|#####|',7
    padded_art_row '+-----+',7

art_burger:
    padded_art_row '.-----.',7
    padded_art_row '|@ @  |',7
    padded_art_row '|=====|',7
    padded_art_row '|-----|',7
    padded_art_row '|#####|',7
    padded_art_row '+-----+',7

art_hotdog:
    padded_art_row '.=====.',7
    padded_art_row '|=====|',7
    padded_art_row '|=====|',7
    padded_art_row '|@ @  |',7
    padded_art_row '|~===~|',7
    padded_art_row '|=====|',7
    padded_art_row '|=====|',7
    padded_art_row '+-----+',7

art_pizza:
    padded_art_row '   /#   ',8
    padded_art_row '  /#@#  ',8
    padded_art_row ' /##P## ',8
    padded_art_row '/#P#P##|',8
    padded_art_row '|P#P#P#|',8
    padded_art_row '|##P###|',8
    padded_art_row '|######|',8
    padded_art_row '+------+',8

art_rat:
    padded_art_row '##    ##',8
    padded_art_row '## @@ ##',8
    padded_art_row '########',8
    padded_art_row '|@ @@ @|',8
    padded_art_row '|  --  |',8
    padded_art_row '|######|',8
    padded_art_row '|##  ##|',8
    padded_art_row '+------+',8
