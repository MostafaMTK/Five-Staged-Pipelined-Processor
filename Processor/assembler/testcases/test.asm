# all numbers in hex format
# we always start by reset signal
# this is a commented line
# you should ignore empty lines

.ORG 0  #this is the reset address
200

.ORG 1  #this is the address of the empty stack exception handler
400

.ORG 400
SUB R2, R2, R2
RTI

.ORG 200
IN  R1            #R1=30 # 200
IN  R2            #R2=50 # 201
IN  R6            #R6=2 # 202

ADD R3,R1,R2      #R3=80 # 203
AND R4,R3,R1      #R4=0 # 204
NOT R4            #R4=FFFFFFFF # 205

SWAP R2,R1        #R1=00000050, R2=00000030 # 206, 207, 208

SUB R5,R1,R2      #R5=20 # 207
INC R5            #R5=21 # 208

JZ  300           #Z=0 (not taken) # 209, 210

ADD R6,R6,R6      #R6=00000004 # 211 --> Hardware Interrupt
# Hardware interrupt
JZ 500 # 212

.ORG 300
ADD R7,R7,R7      #(not executed)

.ORG 500
OUT R1            #(not executed)