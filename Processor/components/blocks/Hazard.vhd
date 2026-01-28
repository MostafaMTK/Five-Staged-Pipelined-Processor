library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Hazard is
  port (
    EX_MEM_M ,EX_MEM_SP ,ID_EX_M ,ID_EX_SP: in    std_logic_vector (1 downto 0);
    EX_MEM_SWAP ,SWAP,IMM_Flush: in    std_logic;
    ID_EX_Rd,IF_ID_Rs1,IF_ID_Rs2: in    std_logic_vector(2 downto 0);
    PC_Stall,IF_ID_Flush,IF_ID_Stall,ID_EX_Flush: out    std_logic
  );
end entity Hazard;

architecture HazardUnit of Hazard is
  -- Internal condition signals
  signal load_use_hazard : std_logic;
  signal swap_hazard : std_logic;
  signal mem_conflict : std_logic;
begin

  -- Load-use hazard detection
  -- Detects when instruction in ID/EX will write to a register (via load or POP)
  -- and the instruction being decoded needs that register
  -- ID_EX_M(1)='1' means MemRead (LDD instruction)
  -- ID_EX_SP(1)='1' means SP+ve (POP instruction)
  load_use_hazard <= '1' when (((ID_EX_Rd=IF_ID_Rs1) or (ID_EX_Rd=IF_ID_Rs2)) and
                               (ID_EX_M(1)='1' or ID_EX_SP(1)='1')) else '0';

  -- SWAP hazard detection
  -- SWAP takes 3 cycles, so we need to stall when SWAP starts
  -- Check: previous instruction (in EX/MEM) was not SWAP, and current decoded instruction is SWAP
  swap_hazard <= '1' when (EX_MEM_SWAP='0' and SWAP='1') else '0';

  -- Memory conflict detection
  -- Detects when instruction in MEM stage is using memory (read or write)
  -- EX_MEM_M(1)='1' means MemRead (LDD), EX_MEM_M(0)='1' means MemWrite (STD)
  -- EX_MEM_SP(1)='1' means POP (reads stack), EX_MEM_SP(0)='1' means PUSH/CALL/INT (writes stack)
  mem_conflict <= '1' when (EX_MEM_M(1)='1' or EX_MEM_M(0)='1' or 
                            EX_MEM_SP(1)='1' or EX_MEM_SP(0)='1') else '0';

  -- PC_Stall: asserted for load-use, swap, or memory conflict
  -- Prevents new instruction from being fetched
  PC_Stall <= '1' when (load_use_hazard='1' or 
                        swap_hazard='1' or 
                        mem_conflict='1') else '0';

  -- IF_ID_Flush: asserted only when memory conflict occurs and NOT fetching immediate
  -- This flushes the normal instruction fetch and inserts a NOP
  IF_ID_Flush <= '1' when (mem_conflict='1' and IMM_Flush='0') else '0';

  -- IF_ID_Stall: asserted for load-use, swap, or (memory conflict with immediate fetch)
  -- Prevents IF/ID pipeline register from updating
  IF_ID_Stall <= '1' when (load_use_hazard='1' or 
                           swap_hazard='1' or 
                           (mem_conflict='1' and IMM_Flush='1')) else '0';

  -- ID_EX_Flush: asserted for load-use or (memory conflict with immediate fetch)
  -- Inserts a NOP bubble in the execute stage
  ID_EX_Flush <= '1' when (load_use_hazard='1' or 
                           (mem_conflict='1' and IMM_Flush='1')) else '0';

end architecture HazardUnit;