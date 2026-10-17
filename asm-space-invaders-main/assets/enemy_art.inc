; Food enemy type metadata and compact, colored ASCII sprites. No code.
type_table:
 dd 1,5,3,10,0,art_cupcake,0x0D
 dd 1,5,3,10,0,art_fries,0x0E
 dd 2,7,3,20,0,art_burger,0x06
 dd 1,5,3,20,1,art_hotdog,0x0C
 dd 2,7,3,30,1,art_pizza,0x0A
 dd 20,11,4,500,1,art_rat,0x0F
art_cupcake: db ' .^. ','(o.o)','[###]'
art_fries:   db '| | |','[o.o]','[###]'
art_burger:  db ' /===\ ','( o o )',' \===/ '
art_hotdog:  db '/===\','|o.o|','\===/'
art_pizza:   db ' /o.o\ ','/ * * \','-------'
art_rat:     db ' /\     /\ ','(  o   o  )',' \  ---  / ','  /|___|\  '
