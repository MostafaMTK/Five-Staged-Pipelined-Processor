library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity processor is
  port (
    clk           : in  std_logic;
    rst           : in  std_logic;
    external_INT  : in  std_logic;
    input_port    : in  std_logic_vector(31 downto 0);
    output_port   : out std_logic_vector(31 downto 0);
    
    -- monitor outputs
    PC_out        : out std_logic_vector(17 downto 0);
    SP_out        : out std_logic_vector(17 downto 0);
    Flags_out     : out std_logic_vector(2 downto 0);
    FU_ALU_Data1 : out std_logic_vector(1 downto 0);
    FU_ALU_Data2 : out std_logic_vector(1 downto 0);
    FU_StoreData : out std_logic_vector(1 downto 0)
  );
end entity processor;

architecture rtl of processor is
  
  COMPONENT MEM_Fetch_Stage
    PORT(
      clk, rst : IN std_logic;
      external_INT : IN std_logic;
      PC_Stall, IF_ID_Flush : IN std_logic;
      JUMP_taken : IN std_logic;
      INT : IN std_logic;
      CALL : IN std_logic;
      HLT : IN std_logic;
      RET : IN std_logic;
      IMM_Flush : IN std_logic;
      EX_MEM_ALUData : IN std_logic_vector(31 downto 0);
      EX_MEM_WriteData : IN std_logic_vector(31 downto 0);
      EX_MEM_Rd : IN std_logic_vector(2 downto 0);
      EX_MEM_SP : IN std_logic_vector(1 downto 0);
      EX_MEM_WB : IN std_logic_vector(1 downto 0);
      EX_MEM_Mem : IN std_logic_vector(1 downto 0);
      EX_MEM_CALL : IN std_logic;
      EX_MEM_INT : IN std_logic;
      EX_MEM_OUT : IN std_logic;
      ID_EX_Flags : IN std_logic_vector(2 downto 0);
      IF_ID_Instruction : OUT std_logic_vector(31 downto 0);
      MEM_WB_ALUData : OUT std_logic_vector(31 downto 0);
      MEM_WB_MemData : OUT std_logic_vector(31 downto 0);
      MEM_WB_Rd : OUT std_logic_vector(2 downto 0);
      MEM_WB_WB : OUT std_logic_vector(1 downto 0);
      MEM_WB_OUT : OUT std_logic;
      IMM : OUT std_logic_vector(31 downto 0);
      SP_out : OUT std_logic_vector(17 downto 0);
      PC_out : OUT std_logic_vector(17 downto 0);
      Flags_restored : OUT std_logic_vector(2 downto 0)
    );
  END COMPONENT;
  
  COMPONENT IF_ID_Reg
    PORT(
      clk : in std_logic;
      Instr_in : in std_logic_vector(31 downto 0);
      Instr_out : out std_logic_vector(31 downto 0);
      IMM_in : in std_logic_vector(31 downto 0);
      IMM_out : out std_logic_vector(31 downto 0);
      IF_ID_stall : in std_logic;
      IF_ID_Flush : in std_logic;
      reset : in std_logic;
      HLT : in std_logic;
      EX_Mem_mem : in std_logic
    );
  END COMPONENT;
  
  COMPONENT DEC_Stage
    PORT(
      clk, rst: IN  std_logic;
      IF_ID_Instr, MEM_WB_ALUData, MEM_WB_MemData, Input : IN std_logic_vector(31 downto 0);
      MEM_WB_WB : IN  std_logic_vector(1 DOWNTO 0);
      MEM_WB_WriteAddress : IN  std_logic_vector(2 DOWNTO 0);
      ID_EX_Flush, ID_EX_Swap, EX_MEM_Swap: IN std_logic;
      FlagReg : IN std_logic_vector(2 downto 0);
      MEM_WB_Out : IN std_logic;
      ReadDataFlags : IN std_logic_vector(2 downto 0);
      External_INT : IN std_logic;
      Output : OUT std_logic_vector(31 downto 0);
      ID_EX_Flags : OUT std_logic_vector(2 downto 0);
      Rs1_Address, Rs2_Address, Rd_Address : OUT std_logic_vector(2 downto 0);
      ReadData1, ReadData2, MEM_WB_WriteData : OUT std_logic_vector(31 DOWNTO 0);
      JUMP : OUT std_logic;
      IMM_Flush, CALL, RET, HLT, INT, IMM, setC : OUT std_logic;
      SWAP, INC_NOT, Buff, OUT_p : OUT std_logic;
      SP, WB, MEM  : OUT std_logic_vector(1 downto 0);
      FlagReset, ALUSignal, FlagE : OUT std_logic_vector(2 downto 0)
    );
  END COMPONENT;
  
  COMPONENT ID_EX_Reg
    PORT(
      clk : in std_logic;
      swap_in : in std_logic;
      swap_out : out std_logic;
      out_in : in std_logic;
      out_out : out std_logic;
      call_in : in std_logic;
      call_out : out std_logic;
      imm_in : in std_logic;
      imm_out : out std_logic;
      buffer_in : in std_logic;
      buffer_out : out std_logic;
      flagEn_in : in std_logic_vector(2 downto 0);
      flagEn_out : out std_logic_vector(2 downto 0);
      flagReset_in : in std_logic_vector(2 downto 0);
      flagReset_out : out std_logic_vector(2 downto 0);
      setCarry_in : in std_logic;
      setCarry_out : out std_logic;
      inc_in : in std_logic;
      inc_out : out std_logic;
      SP_in : in std_logic_vector(1 downto 0);
      SP_out : out std_logic_vector(1 downto 0);
      WB_in : in std_logic_vector(1 downto 0);
      WB_out : out std_logic_vector(1 downto 0);
      Mem_in : in std_logic_vector (1 downto 0);
      Mem_out : out std_logic_vector (1 downto 0);
      EX_in : in std_logic_vector (2 downto 0);
      EX_out : out std_logic_vector (2 downto 0);
      Rd_in : in std_logic_vector(2 downto 0);
      Rd_out : out std_logic_vector(2 downto 0);
      readData1_in : in std_logic_vector(31 downto 0);
      readData1_out : out std_logic_vector(31 downto 0);
      readData2_in : in std_logic_vector(31 downto 0);
      readData2_out : out std_logic_vector(31 downto 0);
      Rs1_in : in std_logic_vector(2 downto 0);
      Rs1_out : out std_logic_vector(2 downto 0);
      Rs2_in : in std_logic_vector(2 downto 0);
      Rs2_out : out std_logic_vector(2 downto 0);
      flags_in : in std_logic_vector(2 downto 0);
      flags_out : out std_logic_vector(2 downto 0);
      INT_in : in std_logic;
      INT_out : out std_logic;
      ID_EX_Flush : in std_logic
    );
  END COMPONENT;
  
  COMPONENT EX_stage
    PORT(
      clk : in std_logic;
      swap_ID_EX : in std_logic;
      out_ID_EX : in std_logic;
      call_ID_EX : in std_logic;
      imm_in_ID_EX : in std_logic;
      buffer_in_ID_EX : in std_logic;
      flagEn_in_ID_EX : in std_logic_vector(2 downto 0);
      setCarry_in_ID_EX : in std_logic;
      flagReset_in_ID_EX : in std_logic_vector(2 downto 0);
      inc_not_in_ID_EX : in std_logic;
      INT_in_ID_EX : in std_logic;
      SP_in_ID_EX : in std_logic_vector(1 downto 0);
      WB_in_ID_EX : in std_logic_vector(1 downto 0);
      Mem_in_ID_EX : in std_logic_vector(1 downto 0);
      EX_in_ID_EX : in std_logic_vector(2 downto 0);
      Rd_in_ID_EX : in std_logic_vector(2 downto 0);
      readData1_in_ID_EX : in std_logic_vector(31 downto 0);
      readData2_in_ID_EX : in std_logic_vector(31 downto 0);
      Rs1_in_ID_EX : in std_logic_vector(2 downto 0);
      Rs2_in_ID_EX : in std_logic_vector(2 downto 0);
      flags_in_ID_EX : in std_logic_vector(2 downto 0);
      MEM_WB_in_Rd : in std_logic_vector(2 downto 0);
      MEM_WB_in_WB : in std_logic_vector(1 downto 0);
      MEM_WB_in_WriteData : in std_logic_vector(31 downto 0);
      EX_MEM_in_Rd : in std_logic_vector(2 downto 0);
      EX_MEM_in_WB : in std_logic_vector(1 downto 0);
      aluData_in_Ex_MEM : in std_logic_vector(31 downto 0);
      IMM_in : in std_logic_vector(31 downto 0);
      swap_out_Ex_MEM : out std_logic;
      out_out_Ex_MEM : out std_logic;
      call_out_Ex_MEM : out std_logic;
      INT_out_EX_MEM : out std_logic;
      SP_out_Ex_MEM : out std_logic_vector(1 downto 0);
      WB_out_Ex_MEM : out std_logic_vector(1 downto 0);
      Mem_out_Ex_MEM : out std_logic_vector(1 downto 0);
      Rd_out_Ex_MEM : out std_logic_vector(2 downto 0);
      aluData_out_Ex_MEM : out std_logic_vector(31 downto 0);
      writeData_out_Ex_MEM : out std_logic_vector(31 downto 0);
      Flags_out : out std_logic_vector(2 downto 0);
      ID_EX_Rd : out std_logic_vector(2 downto 0);
      -- monitor --
      FU_ALU_Data1 : out std_logic_vector(1 downto 0);
      FU_ALU_Data2 : out std_logic_vector(1 downto 0);
      FU_StoreData : out std_logic_vector(1 downto 0)
    );
  END COMPONENT;
  
  COMPONENT EX_MEM_Reg
    PORT(
      clk : in std_logic;
      swap_in : in std_logic;
      swap_out : out std_logic;
      out_in : in std_logic;
      out_out : out std_logic;
      call_in : in std_logic;
      call_out : out std_logic;
      SP_in : in std_logic_vector(1 downto 0);
      SP_out : out std_logic_vector(1 downto 0);
      WB_in : in std_logic_vector(1 downto 0);
      WB_out : out std_logic_vector(1 downto 0);
      Mem_in : in std_logic_vector (1 downto 0);
      Mem_out : out std_logic_vector (1 downto 0);
      Rd_in : in std_logic_vector(2 downto 0);
      Rd_out : out std_logic_vector(2 downto 0);
      aluData_in : in std_logic_vector(31 downto 0);
      aluData_out : out std_logic_vector(31 downto 0);
      writeData_in : in std_logic_vector(31 downto 0);
      writeData_out : out std_logic_vector(31 downto 0);
      INT_in : in std_logic;
      INT_out : out std_logic
    );
  END COMPONENT;
  
  COMPONENT MEM_WB_Reg
    PORT(
      clk : in std_logic;
      out_in : in std_logic;
      out_out : out std_logic;
      WB_in : in std_logic_vector(1 downto 0);
      WB_out : out std_logic_vector(1 downto 0);
      Rd_in : in std_logic_vector(2 downto 0);
      Rd_out : out std_logic_vector(2 downto 0);
      aluData_in : in std_logic_vector(31 downto 0);
      aluData_out : out std_logic_vector(31 downto 0);
      memData_in : in std_logic_vector(31 downto 0);
      memData_out : out std_logic_vector(31 downto 0)
    );
  END COMPONENT;
  
  COMPONENT Hazard
    PORT(
      EX_MEM_M, EX_MEM_SP, ID_EX_M, ID_EX_SP: in std_logic_vector(1 downto 0);
      EX_MEM_SWAP, SWAP, IMM_Flush: in std_logic;
      ID_EX_Rd, IF_ID_Rs1, IF_ID_Rs2: in std_logic_vector(2 downto 0);
      PC_Stall, IF_ID_Flush, IF_ID_Stall, ID_EX_Flush: out std_logic
    );
  END COMPONENT;
  
  -- MEM_Fetch to IF_ID
  SIGNAL mem_to_ifid_instruction : std_logic_vector(31 downto 0);
  SIGNAL mem_to_ifid_imm : std_logic_vector(31 downto 0);
  
  -- MEM_Fetch to MEM_WB_Reg
  SIGNAL mem_to_memwb_aludata : std_logic_vector(31 downto 0);
  SIGNAL mem_to_memwb_memdata : std_logic_vector(31 downto 0);
  SIGNAL mem_to_memwb_rd : std_logic_vector(2 downto 0);
  SIGNAL mem_to_memwb_wb : std_logic_vector(1 downto 0);
  SIGNAL mem_to_memwb_out : std_logic;
  
  -- IF_ID outputs
  SIGNAL ifid_instruction : std_logic_vector(31 downto 0);
  SIGNAL ifid_imm : std_logic_vector(31 downto 0);
  
  -- Decode outputs
  SIGNAL dec_rs1_addr, dec_rs2_addr, dec_rd_addr : std_logic_vector(2 downto 0);
  SIGNAL dec_readdata1, dec_readdata2, dec_memwb_writedata : std_logic_vector(31 downto 0);
  SIGNAL dec_jump : std_logic;
  SIGNAL dec_imm_flush, dec_call, dec_ret, dec_hlt, dec_int, dec_imm, dec_setc : std_logic;
  SIGNAL dec_swap, dec_inc_not, dec_buff, dec_out_p : std_logic;
  SIGNAL dec_sp, dec_wb, dec_mem : std_logic_vector(1 downto 0);
  SIGNAL dec_flagreset, dec_alusignal, dec_flage : std_logic_vector(2 downto 0);
  SIGNAL dec_id_ex_flags : std_logic_vector(2 downto 0);
  SIGNAL dec_output : std_logic_vector(31 downto 0);
  
  -- ID_EX outputs
  SIGNAL idex_swap, idex_out, idex_call, idex_imm, idex_buffer : std_logic;
  SIGNAL idex_setcarry, idex_inc, idex_int : std_logic;
  SIGNAL idex_flage, idex_flagreset, idex_ex : std_logic_vector(2 downto 0);
  SIGNAL idex_sp, idex_wb, idex_mem : std_logic_vector(1 downto 0);
  SIGNAL idex_rd, idex_rs1, idex_rs2 : std_logic_vector(2 downto 0);
  SIGNAL idex_readdata1, idex_readdata2 : std_logic_vector(31 downto 0);
  SIGNAL idex_flags : std_logic_vector(2 downto 0);
  
  -- Execute outputs
  SIGNAL ex_swap, ex_out, ex_call, ex_int : std_logic;
  SIGNAL ex_sp, ex_wb, ex_mem : std_logic_vector(1 downto 0);
  SIGNAL ex_rd : std_logic_vector(2 downto 0);
  SIGNAL ex_aludata, ex_writedata : std_logic_vector(31 downto 0);
  SIGNAL ex_idex_rd : std_logic_vector(2 downto 0);
  
  -- EX_MEM outputs
  SIGNAL exmem_swap, exmem_out, exmem_call, exmem_int : std_logic;
  SIGNAL exmem_sp, exmem_wb, exmem_mem : std_logic_vector(1 downto 0);
  SIGNAL exmem_rd : std_logic_vector(2 downto 0);
  SIGNAL exmem_aludata, exmem_writedata : std_logic_vector(31 downto 0);
  
  -- MEM_WB outputs
  SIGNAL memwb_out : std_logic;
  SIGNAL memwb_wb : std_logic_vector(1 downto 0);
  SIGNAL memwb_rd : std_logic_vector(2 downto 0);
  SIGNAL memwb_aludata, memwb_memdata : std_logic_vector(31 downto 0);
  
  -- Hazard signals
  SIGNAL haz_pc_stall, haz_ifid_flush, haz_ifid_stall, haz_idex_flush : std_logic;
  
  -- Other signals
  SIGNAL flags_current : std_logic_vector(2 downto 0);
  SIGNAL flags_restored : std_logic_vector(2 downto 0);
  SIGNAL pc_monitor : std_logic_vector(17 downto 0);
  SIGNAL sp_monitor : std_logic_vector(17 downto 0);
  SIGNAL mem_conflict_signal : std_logic;
  
BEGIN

  -- ==================== port maps ====================
  
  -- Memory/Fetch Stage
  MEM_Fetch_Stage_inst: MEM_Fetch_Stage
    PORT MAP(
      -- Input --
      clk => clk,
      rst => rst,
      external_INT => external_INT,
      PC_Stall => haz_pc_stall,
      IF_ID_Flush => haz_ifid_flush,
      JUMP_taken => dec_jump,
      INT => dec_int,
      CALL => dec_call,
      HLT => dec_hlt,
      RET => dec_ret,
      IMM_Flush => dec_imm_flush,
      EX_MEM_ALUData => exmem_aludata,
      EX_MEM_WriteData => exmem_writedata,
      EX_MEM_Rd => exmem_rd,
      EX_MEM_SP => exmem_sp,
      EX_MEM_WB => exmem_wb,
      EX_MEM_Mem => exmem_mem,
      EX_MEM_CALL => exmem_call,
      EX_MEM_INT => exmem_int,
      EX_MEM_OUT => exmem_out,
      ID_EX_Flags => dec_id_ex_flags,
      -- Output --
      IF_ID_Instruction => mem_to_ifid_instruction,
      MEM_WB_ALUData => mem_to_memwb_aludata,
      MEM_WB_MemData => mem_to_memwb_memdata,
      MEM_WB_Rd => mem_to_memwb_rd,
      MEM_WB_WB => mem_to_memwb_wb,
      MEM_WB_OUT => mem_to_memwb_out,
      IMM => mem_to_ifid_imm,
      SP_out => sp_monitor,
      PC_out => pc_monitor,
      Flags_restored => flags_restored
    );
  
  -- IF/ID Pipeline Register
  IF_ID_Reg_inst: IF_ID_Reg
    PORT MAP(
      clk => clk,
      Instr_in => mem_to_ifid_instruction,
      Instr_out => ifid_instruction,
      IMM_in => mem_to_ifid_imm,
      IMM_out => ifid_imm,
      IF_ID_stall => haz_ifid_stall,
      IF_ID_Flush => haz_ifid_flush,
      reset => rst,
      HLT => dec_hlt,
      EX_Mem_mem => mem_conflict_signal
    );
  
  -- Decode Stage
  DEC_Stage_inst: DEC_Stage
    PORT MAP(
      clk => clk,
      rst => rst,
      IF_ID_Instr => ifid_instruction,
      MEM_WB_ALUData => memwb_aludata,
      MEM_WB_MemData => memwb_memdata,
      Input => input_port,
      MEM_WB_WB => memwb_wb,
      MEM_WB_WriteAddress => memwb_rd,
      ID_EX_Flush => haz_idex_flush,
      ID_EX_Swap => idex_swap,
      EX_MEM_Swap => exmem_swap,
      FlagReg => flags_current,
      MEM_WB_Out => memwb_out,
      ReadDataFlags => flags_restored,
      External_INT => external_INT,
      -- Output --
      Output => dec_output,
      ID_EX_Flags => dec_id_ex_flags,
      Rs1_Address => dec_rs1_addr,
      Rs2_Address => dec_rs2_addr,
      Rd_Address => dec_rd_addr,
      ReadData1 => dec_readdata1,
      ReadData2 => dec_readdata2,
      MEM_WB_WriteData => dec_memwb_writedata,
      JUMP => dec_jump,
      IMM_Flush => dec_imm_flush,
      CALL => dec_call,
      RET => dec_ret,
      HLT => dec_hlt,
      INT => dec_int,
      IMM => dec_imm,
      setC => dec_setc,
      SWAP => dec_swap,
      INC_NOT => dec_inc_not,
      Buff => dec_buff,
      OUT_p => dec_out_p,
      SP => dec_sp,
      WB => dec_wb,
      MEM => dec_mem,
      FlagReset => dec_flagreset,
      ALUSignal => dec_alusignal,
      FlagE => dec_flage
    );
  
  -- ID/EX Pipeline Register
  ID_EX_Reg_inst: ID_EX_Reg
    PORT MAP(
      clk => clk,
      swap_in => dec_swap,
      swap_out => idex_swap,
      out_in => dec_out_p,
      out_out => idex_out,
      call_in => dec_call,
      call_out => idex_call,
      imm_in => dec_imm,
      imm_out => idex_imm,
      buffer_in => dec_buff,
      buffer_out => idex_buffer,
      flagEn_in => dec_flage,
      flagEn_out => idex_flage,
      flagReset_in => dec_flagreset,
      flagReset_out => idex_flagreset,
      setCarry_in => dec_setc,
      setCarry_out => idex_setcarry,
      inc_in => dec_inc_not,
      inc_out => idex_inc,
      SP_in => dec_sp,
      SP_out => idex_sp,
      WB_in => dec_wb,
      WB_out => idex_wb,
      Mem_in => dec_mem,
      Mem_out => idex_mem,
      EX_in => dec_alusignal,
      EX_out => idex_ex,
      Rd_in => dec_rd_addr,
      Rd_out => idex_rd,
      readData1_in => dec_readdata1,
      readData1_out => idex_readdata1,
      readData2_in => dec_readdata2,
      readData2_out => idex_readdata2,
      Rs1_in => dec_rs1_addr,
      Rs1_out => idex_rs1,
      Rs2_in => dec_rs2_addr,
      Rs2_out => idex_rs2,
      flags_in => dec_id_ex_flags,
      flags_out => idex_flags,
      INT_in => dec_int,
      INT_out => idex_int,
      ID_EX_Flush => haz_idex_flush
    );
  
  -- Execute Stage
  EX_stage_inst: EX_stage
    PORT MAP(
      clk => clk,
      swap_ID_EX => idex_swap,
      out_ID_EX => idex_out,
      call_ID_EX => idex_call,
      imm_in_ID_EX => idex_imm,
      buffer_in_ID_EX => idex_buffer,
      flagEn_in_ID_EX => idex_flage,
      setCarry_in_ID_EX => idex_setcarry,
      flagReset_in_ID_EX => idex_flagreset,
      inc_not_in_ID_EX => idex_inc,
      INT_in_ID_EX => idex_int,
      SP_in_ID_EX => idex_sp,
      WB_in_ID_EX => idex_wb,
      Mem_in_ID_EX => idex_mem,
      EX_in_ID_EX => idex_ex,
      Rd_in_ID_EX => idex_rd,
      readData1_in_ID_EX => idex_readdata1,
      readData2_in_ID_EX => idex_readdata2,
      Rs1_in_ID_EX => idex_rs1,
      Rs2_in_ID_EX => idex_rs2,
      flags_in_ID_EX => idex_flags,
      MEM_WB_in_Rd => memwb_rd,
      MEM_WB_in_WB => memwb_wb,
      MEM_WB_in_WriteData => dec_memwb_writedata,
      EX_MEM_in_Rd => exmem_rd,
      EX_MEM_in_WB => exmem_wb,
      aluData_in_Ex_MEM => exmem_aludata,
      IMM_in => ifid_imm,
      -- Output --
      swap_out_Ex_MEM => ex_swap,
      out_out_Ex_MEM => ex_out,
      call_out_Ex_MEM => ex_call,
      INT_out_EX_MEM => ex_int,
      SP_out_Ex_MEM => ex_sp,
      WB_out_Ex_MEM => ex_wb,
      Mem_out_Ex_MEM => ex_mem,
      Rd_out_Ex_MEM => ex_rd,
      aluData_out_Ex_MEM => ex_aludata,
      writeData_out_Ex_MEM => ex_writedata,
      Flags_out => flags_current,
      ID_EX_Rd => ex_idex_rd,
      -- monitor --
      FU_ALU_Data1 => FU_ALU_Data1,
      FU_ALU_Data2 => FU_ALU_Data2,
      FU_StoreData => FU_StoreData
    );
  
  -- EX/MEM Pipeline Register
  EX_MEM_Reg_inst: EX_MEM_Reg
    PORT MAP(
      clk => clk,
      swap_in => ex_swap,
      swap_out => exmem_swap,
      out_in => ex_out,
      out_out => exmem_out,
      call_in => ex_call,
      call_out => exmem_call,
      SP_in => ex_sp,
      SP_out => exmem_sp,
      WB_in => ex_wb,
      WB_out => exmem_wb,
      Mem_in => ex_mem,
      Mem_out => exmem_mem,
      Rd_in => ex_rd,
      Rd_out => exmem_rd,
      aluData_in => ex_aludata,
      aluData_out => exmem_aludata,
      writeData_in => ex_writedata,
      writeData_out => exmem_writedata,
      INT_in => ex_int,
      INT_out => exmem_int
    );
  
  -- MEM/WB Pipeline Register
  MEM_WB_Reg_inst: MEM_WB_Reg
    PORT MAP(
      clk => clk,
      out_in => mem_to_memwb_out,
      out_out => memwb_out,
      WB_in => mem_to_memwb_wb,
      WB_out => memwb_wb,
      Rd_in => mem_to_memwb_rd,
      Rd_out => memwb_rd,
      aluData_in => mem_to_memwb_aludata,
      aluData_out => memwb_aludata,
      memData_in => mem_to_memwb_memdata,
      memData_out => memwb_memdata
    );
  
  -- Hazard Detection Unit
  Hazard_inst: Hazard
    PORT MAP(
      EX_MEM_M => exmem_mem,
      EX_MEM_SP => exmem_sp,
      ID_EX_M => idex_mem,
      ID_EX_SP => idex_sp,
      EX_MEM_SWAP => exmem_swap,
      SWAP => dec_swap,
      IMM_Flush => dec_imm_flush,
      ID_EX_Rd => ex_idex_rd,
      IF_ID_Rs1 => dec_rs1_addr,
      IF_ID_Rs2 => dec_rs2_addr,
      -- Output --
      PC_Stall => haz_pc_stall,
      IF_ID_Flush => haz_ifid_flush,
      IF_ID_Stall => haz_ifid_stall,
      ID_EX_Flush => haz_idex_flush
    );
  
  
  -- Memory conflict signal for IF_ID register
  mem_conflict_signal <= exmem_mem(1) or exmem_mem(0) or exmem_sp(1) or exmem_sp(0);
  
  -- External outputs to monitor
  output_port <= dec_output;
  PC_out <= pc_monitor;
  SP_out <= sp_monitor;
  Flags_out <= flags_current;

END ARCHITECTURE rtl;