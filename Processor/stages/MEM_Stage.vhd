LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY MEM_Fetch_Stage IS
  PORT(
    clk, rst : IN std_logic;
    
    -- External signals
    external_INT : IN std_logic;
    
    -- From Hazard Detection Unit
    PC_Stall, IF_ID_Flush : IN std_logic;
    
    -- From Decode Stage (for jumps/branches)
    JUMP_taken : IN std_logic;
    INT : IN std_logic;
    CALL : IN std_logic; -- To Prev PC + 1
    HLT : IN std_logic;
    RET : IN std_logic;
    IMM_Flush : IN std_logic;
    
    -- From EX/MEM Pipeline Register
    EX_MEM_ALUData : IN std_logic_vector(31 downto 0);
    EX_MEM_WriteData : IN std_logic_vector(31 downto 0);
    EX_MEM_Rd : IN std_logic_vector(2 downto 0);
    EX_MEM_SP : IN std_logic_vector(1 downto 0);  -- "01"=push, "10"=pop
    EX_MEM_WB : IN std_logic_vector(1 downto 0);
    EX_MEM_Mem : IN std_logic_vector(1 downto 0); -- "10"=read, "01"=write
    EX_MEM_CALL : IN std_logic;
    EX_MEM_INT : IN std_logic;
    EX_MEM_OUT : IN std_logic;
    
    -- From ID/EX (for INT index and flags)
    ID_EX_Flags : IN std_logic_vector(2 downto 0);
    
    -- Outputs to IF/ID Pipeline Register
    IF_ID_Instruction : OUT std_logic_vector(31 downto 0);
    
    -- Outputs to MEM/WB Pipeline Register
    MEM_WB_ALUData : OUT std_logic_vector(31 downto 0);
    MEM_WB_MemData : OUT std_logic_vector(31 downto 0);
    MEM_WB_Rd : OUT std_logic_vector(2 downto 0);
    MEM_WB_WB : OUT std_logic_vector(1 downto 0);
    MEM_WB_OUT : OUT std_logic;
    
    -- Immediate Sign Extend (To IF/ID Pipeline Register & PC MUX)
    IMM : OUT std_logic_vector(31 downto 0);

    -- Stack Pointer output (for monitoring/debugging)
    SP_out : OUT std_logic_vector(17 downto 0);
    
    -- PC output (for monitoring/debugging)
    PC_out : OUT std_logic_vector(17 downto 0);
    
    -- Flags output (restored from memory for RET/RTI)
    Flags_restored : OUT std_logic_vector(2 downto 0)
  );
END ENTITY MEM_Fetch_Stage;

ARCHITECTURE arch_mem_fetch OF MEM_Fetch_Stage IS
  COMPONENT memory
    PORT(
      clk     : IN  std_logic;
      we      : IN  std_logic;
      addr    : IN  std_logic_vector(17 DOWNTO 0);
      datain  : IN  std_logic_vector(31 DOWNTO 0);
      dataout : OUT std_logic_vector(31 DOWNTO 0)
    );
  END COMPONENT;
  
  COMPONENT PC
    PORT(
      clk      : in std_logic;
      PC_in    : in std_logic_vector(17 downto 0);
      PC_out   : out std_logic_vector(17 downto 0);
      HLT      : in std_logic;
      PC_stall : in std_logic
    );
  END COMPONENT;
  
  COMPONENT SP
    PORT(
      clk    : in std_logic;
      rst    : in std_logic;
      SP_in  : in std_logic_vector(17 downto 0);
      SP_out : out std_logic_vector(17 downto 0)
    );
  END COMPONENT;
  
  COMPONENT prevPc_Flags
    PORT(
      clk      : in std_logic;
      INT      : in std_logic;
      CALL     : in std_logic;
      Flags_in : in std_logic_vector(2 downto 0);
      PC_in    : in std_logic_vector(17 downto 0);
      output   : out std_logic_vector(20 downto 0)
    );
  END COMPONENT;

  SIGNAL PC_current, PC_next, PC_plus_1 : std_logic_vector(17 downto 0);
  SIGNAL SP_current, SP_next, SP_plus_1, SP_minus_1 : std_logic_vector(17 downto 0);
  
  SIGNAL mem_addr : std_logic_vector(17 downto 0);
  SIGNAL mem_datain : std_logic_vector(31 downto 0);
  SIGNAL mem_dataout : std_logic_vector(31 downto 0);
  SIGNAL mem_we : std_logic;
  
  SIGNAL prevPc_Flags_output : std_logic_vector(20 downto 0);
  
  SIGNAL first_OR, second_OR : std_logic;
  SIGNAL addr_select : std_logic_vector(1 downto 0);
  
  SIGNAL vector_select : std_logic_vector(2 downto 0);
  SIGNAL vector_addr : std_logic_vector(17 downto 0);
  
  SIGNAL SP_or_SP_plus_1 : std_logic_vector(17 downto 0);

  SIGNAL IMM_S : std_logic_vector(31 downto 0);
  SIGNAL JUMP_target : std_logic_vector(17 downto 0);

  SIGNAL next_prev_PC : std_logic_vector(17 downto 0);

BEGIN

  -- ==================== port maps ====================
  
  next_prev_PC <= PC_plus_1 when external_INT = '0' else PC_current;

  memory_inst : memory
    PORT MAP(
      clk => clk,
      we => mem_we,
      addr => mem_addr,
      datain => mem_datain,
      dataout => mem_dataout
    );
    
  PC_inst : PC
    PORT MAP(
      clk => clk,
      PC_in => PC_next,
      PC_out => PC_current,
      HLT => HLT,
      PC_stall => PC_Stall
    );
    
  SP_inst : SP
    PORT MAP(
      clk => clk,
      rst => rst,
      SP_in => SP_next,
      SP_out => SP_current
    );
    
  prevPc_Flags_inst : prevPc_Flags
    PORT MAP(
      clk => clk,
      INT => INT,
      CALL => CALL,
      Flags_in => ID_EX_Flags,
      PC_in => next_prev_PC,
      output => prevPc_Flags_output
    );


  -- Immediate Sign Extend
  IMM_S <= (31 DOWNTO 16 => '0') & mem_dataout(15 DOWNTO 0);
  JUMP_target <= IMM_S(17 DOWNTO 0);
  
  -- PC Increment
  PC_plus_1 <= std_logic_vector(unsigned(PC_current) + 1);
  
  -- SP Increment/Decrement
  SP_plus_1 <= std_logic_vector(unsigned(SP_current) + 1);
  SP_minus_1 <= std_logic_vector(unsigned(SP_current) - 1);
  
  
  -- First OR: INT | reset | EX_MEM_Mem (any bit set)
  first_OR <= INT or rst or EX_MEM_Mem(1) or EX_MEM_Mem(0);
  
  -- Second OR: reset | INT | EX_MEM_SP (any bit) | RET
  second_OR <= rst or INT or EX_MEM_SP(1) or EX_MEM_SP(0) or RET;
  
  -- Address select based on OR outputs
  addr_select <= first_OR & second_OR;
  
  -- SP MUX: Select SP or SP+1 (for POP/RET/RTI)
  SP_or_SP_plus_1 <= SP_plus_1 when (EX_MEM_SP(1) = '1' or RET = '1') else
                     SP_current;
  
  -- Vector Address Selection
  -- Selectors: [reset, INT_instruction, external_INT]
  -- Reset has highest priority, then external INT, then INT instruction
  vector_select <= rst & IMM_S(0) & external_INT;
  
  with vector_select select
    vector_addr <= std_logic_vector(to_unsigned(0, 18)) when "100" | "110" | "101" | "111",  -- Reset: M[0]
                   std_logic_vector(to_unsigned(1, 18)) when "001" | "011",                  -- External INT: M[1]
                   std_logic_vector(to_unsigned(3, 18)) when "010",                          -- INT with index=1: M[3]
                   std_logic_vector(to_unsigned(2, 18)) when others;                         -- INT with index=0: M[2]
  
  -- Main Address MUX
  with addr_select select
    mem_addr <= PC_current when "00",                    -- Normal fetch
                EX_MEM_ALUData(17 downto 0) when "10",  -- LDD/STD address
                SP_or_SP_plus_1 when "01",              -- Stack operations
                vector_addr when others;                 -- "11": Reset/Interrupt vectors
  
  
  -- Write to memory when: STD, PUSH, CALL, INT, or external interrupt
  mem_we <= EX_MEM_Mem(0) or                              -- STD
            EX_MEM_SP(0);                                 -- PUSH (SP decrements)
  
  -- Priority:
  -- 1. INT instruction: Write [Flags(2:0), PC+1(17:0)] as 32-bit value
  -- 2. CALL: Write PC+1
  -- 3. External INT: Write current PC + Flags
  -- 4. PUSH: Write register data
  -- 5. STD: Write register data
  
  mem_datain <= (31 downto 21 => '0') & prevPc_Flags_output when (EX_MEM_INT = '1') else
                (31 downto 18 => '0') & prevPc_Flags_output(17 downto 0) when (EX_MEM_CALL = '1') else
                EX_MEM_WriteData;  -- PUSH or STD
  
  -- PC priority:
  -- 1. Reset: PC ← M[0]
  -- 2. External Interrupt: PC ← M[1]
  -- 3. RET/RTI: PC ← Memory data (from stack)
  -- 4. INT instruction: PC ← M[2] or M[3]
  -- 5. JUMP taken: PC ← JUMP target
  -- 6. Normal: PC ← PC + 1
  
  PC_next <= mem_dataout(17 downto 0) when (rst = '1' or external_INT = '1' or RET = '1' or INT = '1') else
             JUMP_target when (JUMP_taken = '1') else
             PC_plus_1;
  
  -- SP updates:
  -- - Decrement (SP-1): PUSH, CALL, INT, external interrupt
  -- - Increment (SP+1): POP, RET
  -- - No change: otherwise
  
  SP_next <= SP_minus_1 when (EX_MEM_SP(0) = '1') else
             SP_plus_1 when (EX_MEM_SP(1) = '1' or RET = '1') else
             SP_current;
  
  -- ==================== outputs to IF/ID ====================
  
  -- Instruction from memory (fetched at PC)
  IF_ID_Instruction <= mem_dataout when (addr_select = "00" and (IF_ID_Flush = '0' and RET = '0' and IMM_Flush = '0' and INT = '0' and rst = '0')) else
                      (others => '0');  -- NOP when flushed

  IMM <= IMM_S;
  
  -- ==================== outputs to MEM/WB ====================
  
  MEM_WB_ALUData <= EX_MEM_ALUData;
  MEM_WB_MemData <= mem_dataout;  -- Data read from memory (LDD, POP)
  MEM_WB_Rd <= EX_MEM_Rd;
  MEM_WB_WB <= EX_MEM_WB;
  MEM_WB_OUT <= EX_MEM_OUT;
  
  -- For RET/RTI: Extract flags from memory data
  -- Format in memory: [unused(31:21), Flags(20:18), PC(17:0)]
  Flags_restored <= mem_dataout(20 downto 18);
  
  -- ==================== outputs to monitor ====================
  
  SP_out <= SP_current;
  PC_out <= PC_current;

END ARCHITECTURE arch_mem_fetch;