library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control is
  port (
    opcode   : in    std_logic_vector (4 downto 0);
    ALUSignal : out    std_logic_vector(2 downto 0);
    IMM_Flush, CALL ,RET ,HLT ,INT ,IMM ,setC: out    std_logic;
    IN_p ,SWAP ,INC_NOT ,Branch ,Buff ,OUT_p : out    std_logic;
    SP ,WB ,M ,JUMP_Type : out    std_logic_vector(1 downto 0);
    FlagE,FlagReset:out    std_logic_vector(2 downto 0)
  );
end entity control;

architecture controlUnit of control is
begin
  
  -- HLT (00001)
  with opcode select
    HLT <= '1' when "00001",
           '0' when others;

  -- IMM_Flush
  with opcode select
    IMM_Flush <= '1' when "00001" | "01101" | "10010" | "10011" | "10100" | 
                          "11000" | "11001" | "11010" | "11011" | "11100" | "11110",
                 '0' when others;

  -- CALL (11100, 11110)
  with opcode select
    CALL <= '1' when "11100" | "11110",
            '0' when others;

  -- RET (11101, 11111)
  with opcode select
    RET <= '1' when "11101" | "11111",
           '0' when others;

  -- INT (11110)
  with opcode select
    INT <= '1' when "11110",
           '0' when others;

  -- IMM (00100, 01101, 10010, 10011, 10100)
  with opcode select
    IMM <= '1' when "00100" | "01101" | "10010" | "10011" | "10100",
           '0' when others;

  -- setC (00010)
  with opcode select
    setC <= '1' when "00010",
            '0' when others;

  -- IN_p (00110)
  with opcode select
    IN_p <= '1' when "00110",
            '0' when others;

  -- OUT_p (00101)
  with opcode select
    OUT_p <= '1' when "00101",
             '0' when others;

  -- SWAP (01001)
  with opcode select
    SWAP <= '1' when "01001",
            '0' when others;

  -- INC_NOT (00011, 00100)
  with opcode select
    INC_NOT <= '1' when "00011" | "00100",
               '0' when others;

  -- Buff (00011, 00101, 00110, 01000, 10000, 10010)
  with opcode select
    Buff <= '1' when "00101" | "00110" | "01000" | "10000" | "10010",
            '0' when others;

  -- Branch (11000, 11001, 11010, 11011, 11100)
  with opcode select
    Branch <= '1' when "11000" | "11001" | "11010" | "11011" | "11100",
              '0' when others;


  -- SP[1:0]: "01"=push, "10"=pop, "00"=no change
  with opcode select
    SP <= "01" when "10000" | "11100" | "11110",  -- PUSH, CALL, INT
          "10" when "10001",                       -- POP
          "00" when others;

  -- WB[1:0]: "10"=RegWrite, "11"=RegWrite+MemToReg, "00"=none
  with opcode select
    WB <= "10" when "00011" | "00100" | "00110" | "01000" | "01001" | 
                    "01010" | "01011" | "01100" | "01101" | "10010",
          "11" when "10001" | "10011",             -- POP, LDD
          "00" when others;

  -- M[1:0]: "10"=MemRead, "01"=MemWrite, "00"=none
  with opcode select
    M <= "10" when "10011",                        -- LDD
         "01" when "10100",                        -- STD
         "00" when others;

  -- JUMP_Type[1:0]: "01"=JZ, "10"=JN, "11"=JC, "00"=others
  with opcode select
    JUMP_Type <= "01" when "11000",                -- JZ
            "10" when "11001",                     -- JN
            "11" when "11010",                     -- JC
            "00" when others;

  -- ALUSignal[2:0]: "000"=ADD, "001"=SUB, "010"=AND, "011"=NOT, "100"=XOR, "111"=NOP
  with opcode select
    ALUSignal <= "011" when "00011",               -- NOT
                 "000" when "00100" | "00101" | "00110" | "01000" | "01010" | 
                            "01101" | "10000" | "10010" | "10011" | "10100",
                 "001" when "01011",               -- SUB
                 "010" when "01100",               -- AND
                 "100" when "01001",               -- SWAP (XOR)
                 "111" when others;                -- NOP/default

  -- FlagE[2:0]: "001"=C only, "110"=N,Z, "111"=all, "000"=none
  with opcode select
    FlagE <= "001" when "00010",                   -- SETC
             "110" when "00011" | "01100",         -- NOT, AND
             "111" when "00100" | "01010" | "01011" | "01101" | "11111",  -- INC, ADD, SUB, IADD, RTI
             "000" when others;

  -- FlagReset[2:0]: "100"=reset N, "010"=reset Z, "001"=reset C, "000"=none
  with opcode select
    FlagReset <= "010" when "11000",               -- JZ
                 "100" when "11001",               -- JN
                 "001" when "11010",               -- JC
                 "000" when others;

end architecture controlUnit;