library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity EX_stage is
  port (
    clk         : in std_logic;

    --coming from ID/EX reg
    swap_ID_EX      : in std_logic;
    out_ID_EX       : in std_logic;
    call_ID_EX      : in std_logic;
    imm_in_ID_EX       : in std_logic;
    buffer_in_ID_EX    : in std_logic;
    flagEn_in_ID_EX    : in std_logic_vector(2 downto 0);
    setCarry_in_ID_EX  : in std_logic;
    flagReset_in_ID_EX : in std_logic_vector(2 downto 0);
    inc_not_in_ID_EX       : in std_logic;
    INT_in_ID_EX : in std_logic;
    SP_in_ID_EX        : in std_logic_vector(1 downto 0);
    WB_in_ID_EX        : in std_logic_vector(1 downto 0);
    Mem_in_ID_EX       : in std_logic_vector (1 downto 0);
    EX_in_ID_EX        : in std_logic_vector (2 downto 0);
    Rd_in_ID_EX        : in std_logic_vector(2 downto 0);
    readData1_in_ID_EX : in std_logic_vector(31 downto 0);
    readData2_in_ID_EX : in std_logic_vector(31 downto 0);
    Rs1_in_ID_EX       : in std_logic_vector(2 downto 0);
    Rs2_in_ID_EX       : in std_logic_vector(2 downto 0);
    flags_in_ID_EX     : in std_logic_vector(2 downto 0);

    --coming from MEM/WB reg
    MEM_WB_in_Rd     : in std_logic_vector(2 downto 0);
    MEM_WB_in_WB       : in std_logic_vector(1 downto 0);
    MEM_WB_in_WriteData    :in std_logic_vector(31 downto 0);
    

   -- writeData_in_Ex_MEM  :in std_logic_vector(31 downto 0);

    --coming from EX/MEM reg
    EX_MEM_in_Rd     : in std_logic_vector(2 downto 0);
    EX_MEM_in_WB     : in std_logic_vector(1 downto 0);
    aluData_in_Ex_MEM    :in std_logic_vector(31 downto 0);

    --coming from IF/ID reg
    IMM_in           : in std_logic_vector(31 downto 0);

    -------outputs-------------
    --outputs to EX/MEM reg
    swap_out_Ex_MEM       : out std_logic;
    out_out_Ex_MEM        : out std_logic;
    call_out_Ex_MEM       : out std_logic;
    INT_out_EX_MEM        : out std_logic;
    SP_out_Ex_MEM         : out std_logic_vector(1 downto 0);
    WB_out_Ex_MEM         : out std_logic_vector(1 downto 0);
    Mem_out_Ex_MEM        : out std_logic_vector(1 downto 0);
    Rd_out_Ex_MEM         : out std_logic_vector(2 downto 0);
    aluData_out_Ex_MEM    : out std_logic_vector(31 downto 0);
    writeData_out_Ex_MEM  : out std_logic_vector(31 downto 0);

    --output to decode stage
    Flags_out             : out std_logic_vector(2 downto 0);

    --output to hazard unit
    ID_EX_Rd              : out std_logic_vector(2 downto 0);

    -- monitor
    FU_ALU_Data1 : out std_logic_vector(1 downto 0);
    FU_ALU_Data2 : out std_logic_vector(1 downto 0);
    FU_StoreData : out std_logic_vector(1 downto 0)
  );
end entity EX_stage;

architecture rtl of EX_stage is
  component alu IS
    PORT ( 
        Data1, Data2: IN  std_logic_vector(31 DOWNTO 0);  
        ALUSignal : IN std_logic_vector(2 DOWNTO 0);
        ALUData: OUT  std_logic_vector(31 DOWNTO 0);
        CF, NF, ZF: OUT std_logic
    );
  END component ; 

  component Flags is
    port (
      clk         : in std_logic;
      FEnable     : in std_logic_vector(2 downto 0);--N,Z,C
      reset_flags : in std_logic_vector(2 downto 0);--N,Z,C
      alu_Flags   : in std_logic_vector(2 downto 0);--N,Z,C
      ID_EX_Flags : in std_logic_vector(2 downto 0);--N,Z,C
      set_carry   : in std_logic;
      Flags_out   : out std_logic_vector(2 downto 0)

    );
  end component;

  component forwardUnit IS
    PORT(
      EXMEM_Rd, MEMWB_Rd, IDEX_Rs1, IDEX_Rs2: IN std_logic_vector(2 DOWNTO 0);
      EXMEM_WB, MEMWB_WB, IDEX_SP: IN std_logic_vector(1 DOWNTO 0);  -- 2-bit WB signal
      IDEX_MemWrite: IN std_logic;
      ALU_Data1, ALU_Data2, StoreData: OUT std_logic_vector(1 DOWNTO 0)
    );
  END component;

signal IMM_mux     : std_logic_vector (31 downto 0);
signal DATA1,DATA2 : std_logic_vector (31 downto 0);
signal alu_flags   : std_logic_vector (2 downto 0);
signal ALU_Data1, ALU_Data2, StoreData : std_logic_vector (1 downto 0);
signal alu_signal1, alu_signal2: std_logic_vector (1 downto 0);

begin
    swap_out_Ex_MEM <=  swap_ID_EX;
    out_out_Ex_MEM  <=  out_ID_EX;
    call_out_Ex_MEM <=  call_ID_EX;
    SP_out_Ex_MEM   <=  SP_in_ID_EX;   
    WB_out_Ex_MEM   <=  WB_in_ID_EX;  
    Mem_out_Ex_MEM  <=  Mem_in_ID_EX; 
    Rd_out_Ex_MEM   <=  Rd_in_ID_EX;
    ID_EX_Rd        <=  Rd_in_ID_EX;
    INT_out_EX_MEM <= INT_in_ID_EX;

    IMM_mux <=  (0 => '1', Others => '0') WHEN inc_not_in_ID_EX ='1'
         ELSE IMM_in;
    
    FU: forwardUnit port map( 
      EXMEM_Rd      =>EX_MEM_in_Rd,
      MEMWB_Rd      =>MEM_WB_in_Rd,
      IDEX_Rs1      =>Rs1_in_ID_EX,
      IDEX_Rs2      =>Rs2_in_ID_EX,
      EXMEM_WB      =>EX_MEM_in_WB,
      MEMWB_WB      =>MEM_WB_in_WB,
      IDEX_MemWrite =>Mem_in_ID_EX(0),
      IDEX_SP => SP_in_ID_EX,
      ALU_Data1     =>ALU_Data1,
      ALU_Data2     =>ALU_Data2,
      StoreData     =>StoreData
    );

    FU_ALU_Data1 <= ALU_Data1;
    FU_ALU_Data2 <= ALU_Data2;
    FU_StoreData <= StoreData;

    writeData_out_Ex_MEM <= readData1_in_ID_EX WHEN StoreData = "00"
                          ELSE aluData_in_Ex_MEM WHEN StoreData = "10"
                          ELSE MEM_WB_in_WriteData WHEN StoreData = "01"
                          ELSE readData1_in_ID_EX;

    --------ALU-----------
    alu_signal1 <= "11" WHEN imm_in_ID_EX ='1'
         ELSE ALU_Data1;
          
    alu_signal2 <= "11" WHEN buffer_in_ID_EX ='1'
         ELSE ALU_Data2;

    with alu_signal1 select
      DATA1 <= readData1_in_ID_EX when "00",
              MEM_WB_in_WriteData when "01",
              aluData_in_Ex_MEM when "10",
              IMM_mux when "11",
              readData1_in_ID_EX when others;

    with alu_signal2 select
      DATA2 <=  readData2_in_ID_EX when "00",
              MEM_WB_in_WriteData when "01",
              aluData_in_Ex_MEM when "10",
              (others=>'0') when "11",
              readData2_in_ID_EX when others;
        
    alu_Port: alu port map(
        Data1     =>DATA1
      , Data2     =>DATA2
      , ALUSignal =>EX_in_ID_EX
      , ALUData   =>aluData_out_Ex_MEM
      , CF        =>alu_flags(0)
      , NF        =>alu_flags(2)
      , ZF        =>alu_flags(1)
    );

    NZC: Flags port map(
      clk         => clk,
      FEnable     =>flagEn_in_ID_EX,
      reset_flags =>flagReset_in_ID_EX,
      alu_Flags   =>alu_flags,
      ID_EX_Flags =>flags_in_ID_EX,
      set_carry   =>setCarry_in_ID_EX,
      Flags_out   =>Flags_out
    );

end architecture rtl;
