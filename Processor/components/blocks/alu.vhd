library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY alu IS
    PORT ( 
        Data1, Data2: IN  std_logic_vector(31 DOWNTO 0);  
        ALUSignal : IN std_logic_vector(2 DOWNTO 0);
        ALUData: OUT  std_logic_vector(31 DOWNTO 0);
        CF, NF, ZF: OUT std_logic
    );
END alu ;
ARCHITECTURE alu_arch OF alu IS
SIGNAL addR, subR: std_logic_vector(32 DOWNTO 0);
SIGNAL notR, xorR, andR: std_logic_vector(31 DOWNTO 0);
SIGNAL result: std_logic_vector(31 DOWNTO 0);
BEGIN
    addR <= std_logic_vector(unsigned('0' & Data1) + unsigned('0' & Data2));
    subR <= std_logic_vector(unsigned('0' & Data1) - unsigned('0' & Data2));
    notR <= NOT Data2;
    xorR <= Data1 XOR Data2;
    andR <= Data1 AND Data2;

    WITH ALUSignal SELECT
        result <= addR(31 DOWNTO 0) WHEN "000",
                   subR(31 DOWNTO 0) WHEN "001",
                   notR WHEN "011",
                   xorR WHEN "100",
                   andR WHEN "010",
                   (OTHERS => '0') WHEN OTHERS;

    WITH ALUSignal SELECT
        CF <= addR(32) WHEN "000",
              subR(32) WHEN "001",
              '0' WHEN OTHERS;
    
    NF <= '1' WHEN to_integer(signed(result)) < 0
          ELSE '0';
    
    ZF <= '1' WHEN to_integer(signed(result)) = 0
          ELSE '0';

    ALUData <= result;

END alu_arch;