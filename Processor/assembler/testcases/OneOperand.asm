# all numbers in hex format
# we always start by reset signal
# this is a commented line
# you should ignore empty lines

.ORG 0  #this is the reset address
200

.ORG 200
NOT R1      #R1 = FFFF , 204
NOP         #No change , 205
INC R1      #R1 =00000 , 206
IN R1	    #R1= 000E, add E on the in port, 207
IN R2       #R2= 0010, add 10 on the in port, 208
NOT R2      #R2= FFEF, 209
INC R1      #R1= 000F, 210
LDM R3, 0005 #R3= 0005, 211
SUB R2, R2, R3    #R2= FFEA,  //R2 - R3, 213
OUT R1 # 214
OUT R2 # 215
