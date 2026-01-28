# all numbers in hex format
# we always start by reset signal
# this is a commented line
# you should ignore empty lines

.ORG 0  #this is the reset address
200

.ORG 200
IN R1       #add 6 in R1 # 200 --> 204
IN R2       #add 20 in R2 # 201 --> 205
LDM R3, FFFC # 202 --> 206
LDM R4, F322 # 204 --> 208
IADD R5,R3,2  #R5 = FFFE # 206 --> 210
ADD  R4,R1,R4    #R4= F328 # 208 --> 212
SUB  R6,R5,R4    #R6= 0CD6 , // R6 = R5 - R4 # 209 --> 213
AND  R6,R7,R6    #R6= 00000000 # 210 --> 214
SWAP R6,R1    #R1=00000000, R6=6, # 211 --> 215
MOV  R1, R3    #R3=0000000 # 214 --> 218
ADD  R2,R5,R2    #R2= 0001001E # 215 --> 219
