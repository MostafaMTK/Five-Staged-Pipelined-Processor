LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY forwardUnit IS
  PORT(
    EXMEM_Rd, MEMWB_Rd, IDEX_Rs1, IDEX_Rs2: IN std_logic_vector(2 DOWNTO 0);
    EXMEM_WB, MEMWB_WB, IDEX_SP: IN std_logic_vector(1 DOWNTO 0);  -- 2-bit WB signal
    IDEX_MemWrite: IN std_logic;
    ALU_Data1, ALU_Data2, StoreData: OUT std_logic_vector(1 DOWNTO 0)
  );
END forwardUnit;

ARCHITECTURE FU_arch OF forwardUnit IS
BEGIN

    -- Forward to ALU Data1 (Rs1)
    -- Priority: EX/MEM > MEM/WB > No forwarding
    -- Check RegWrite bit (WB(1)) and register match
    ALU_Data1 <= "10" WHEN (EXMEM_WB(1) = '1' AND EXMEM_Rd = IDEX_Rs1)
                 ELSE "01" WHEN (MEMWB_WB(1) = '1' AND MEMWB_Rd = IDEX_Rs1)
                 ELSE "00";

    -- Forward to ALU Data2 (Rs2)
    -- Priority: EX/MEM > MEM/WB > No forwarding
    ALU_Data2 <= "10" WHEN (EXMEM_WB(1) = '1' AND EXMEM_Rd = IDEX_Rs2)
                 ELSE "01" WHEN (MEMWB_WB(1) = '1' AND MEMWB_Rd = IDEX_Rs2)
                 ELSE "00";

    -- Forward for Store Data (STD/PUSH uses Rs1 as data source)
    -- Only forward when writing to memory
    StoreData <= "10" WHEN (EXMEM_WB(1) = '1' AND EXMEM_Rd = IDEX_Rs1 AND (IDEX_MemWrite = '1' or IDEX_SP(0) = '1'))
                 ELSE "01" WHEN (MEMWB_WB(1) = '1' AND MEMWB_Rd = IDEX_Rs1 AND (IDEX_MemWrite = '1' or IDEX_SP(0) = '1'))
                 ELSE "00";

END FU_arch;