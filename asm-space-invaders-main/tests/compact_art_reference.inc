; Independent expected forms for the compact ASCII designs used in gameplay.
%macro compact_test_row 2
%%row_start:
    db %1
    times (%2 - ($ - %%row_start)) db ' '
%endmacro

test_cupcake_art:
    compact_test_row '   . . .   ',11
    compact_test_row '  (^^^^^)  ',11
    compact_test_row '|  @   @  |',11
    compact_test_row '|    o    |',11
    compact_test_row '|#########|',11
    compact_test_row '|P.C.G.P.C|',11
    compact_test_row '|C.G.P.C.G|',11
    compact_test_row '+---------+',11

test_fries_art:
    compact_test_row '|#|#|#|',7
    compact_test_row '|#|#|#|',7
    compact_test_row '|#|#|#|',7
    compact_test_row '|#|#|#|',7
    compact_test_row '+-----+',7
    compact_test_row '|@ @  |',7
    compact_test_row '|#####|',7
    compact_test_row '+-----+',7

test_burger_art:
    compact_test_row '.-----.',7
    compact_test_row '|@ @  |',7
    compact_test_row '|=====|',7
    compact_test_row '|-----|',7
    compact_test_row '|#####|',7
    compact_test_row '+-----+',7

test_hotdog_art:
    compact_test_row '.=====.',7
    compact_test_row '|=====|',7
    compact_test_row '|=====|',7
    compact_test_row '|@ @  |',7
    compact_test_row '|~===~|',7
    compact_test_row '|=====|',7
    compact_test_row '|=====|',7
    compact_test_row '+-----+',7

test_pizza_art:
    compact_test_row '   /#   ',8
    compact_test_row '  /#@#  ',8
    compact_test_row ' /##P## ',8
    compact_test_row '/#P#P##|',8
    compact_test_row '|P#P#P#|',8
    compact_test_row '|##P###|',8
    compact_test_row '|######|',8
    compact_test_row '+------+',8

test_rat_art:
    compact_test_row '##    ##',8
    compact_test_row '## @@ ##',8
    compact_test_row '########',8
    compact_test_row '|@ @@ @|',8
    compact_test_row '|  --  |',8
    compact_test_row '|######|',8
    compact_test_row '|##  ##|',8
    compact_test_row '+------+',8

test_chef_art:
    compact_test_row ' .-.  ',6
    compact_test_row '|###| ',6
    compact_test_row '|@ @| ',6
    compact_test_row '|_=_| ',6
    compact_test_row '|[P]| ',6
    compact_test_row '|WWW| ',6
    compact_test_row '|KK | ',6
    compact_test_row '+----+',6

test_cleaver_art:
    compact_test_row '  ### ',6
    compact_test_row ' #####',6
    compact_test_row '######',6
    compact_test_row '######',6
    compact_test_row ' #####',6
    compact_test_row '  ##  ',6
    compact_test_row '  ##  ',6
    compact_test_row '  ##  ',6

test_rolling_pin_art:
    compact_test_row '#====#',6
    compact_test_row '######',6
    compact_test_row '######',6
    compact_test_row '######',6
    compact_test_row '######',6
    compact_test_row '######',6
    compact_test_row '######',6
    compact_test_row '#====#',6

test_fireball_art:
    compact_test_row '   ^   ',7
    compact_test_row '  ###  ',7
    compact_test_row ' ##### ',7
    compact_test_row '#######',7
    compact_test_row '|@#@F#|',7
    compact_test_row '#######',7
    compact_test_row ' ##### ',7
    compact_test_row '  ###  ',7
    compact_test_row '  # #  ',7
