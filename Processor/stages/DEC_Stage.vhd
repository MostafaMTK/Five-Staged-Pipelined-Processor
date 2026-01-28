LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY DEC_Stage IS
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
END ENTITY DEC_Stage;

ARCHITECTURE arch_dec_stage OF DEC_Stage IS
COMPONENT control
    PORT(
        opcode                                    : IN  std_logic_vector (4 downto 0);
        ALUSignal                                 : OUT std_logic_vector(2 downto 0);
        IMM_Flush, CALL, RET, HLT, INT, IMM, setC : OUT std_logic;
        IN_p, SWAP, INC_NOT, Branch, Buff, OUT_p  : OUT std_logic;
        SP, WB, M, JUMP_Type                      : OUT std_logic_vector(1 downto 0);
        FlagE, FlagReset                          : OUT std_logic_vector(2 downto 0)
    );
END COMPONENT control;

COMPONENT regfile
    PORT(
        clk, rst, we                      : IN  std_logic;
        r1_address, r2_address, w_address : IN  std_logic_vector(2 DOWNTO 0);
        data_in                           : IN  std_logic_vector(31 DOWNTO 0);
        r1_data, r2_data                  : OUT std_logic_vector(31 DOWNTO 0)
    );
END COMPONENT regfile;

-- Internal Signals from Control Unit
SIGNAL IMM_Flush_S, CALL_S, RET_S, HLT_S, INT_S, IMM_S, setC_S : std_logic;
SIGNAL IN_p_S, SWAP_S, INC_NOT_S, Branch_S, Buff_S, OUT_p_S : std_logic;
SIGNAL SP_S, WB_S, M_S, JUMP_Type_S : std_logic_vector(1 downto 0);
SIGNAL FlagE_S, FlagReset_S, ALUSignal_S : std_logic_vector(2 downto 0);

-- Register File Signals
SIGNAL r1_data_S, r2_data_S : std_logic_vector(31 DOWNTO 0);
SIGNAL r2_address_MUX : std_logic_vector(2 DOWNTO 0);
SIGNAL data_in_MUX : std_logic_vector(31 DOWNTO 0);

-- Flag Signals
SIGNAL Prev_Flags_MUX : std_logic_vector(2 downto 0);
SIGNAL Flags_MUX : std_logic;

-- Read Data Signals
SIGNAL ReadData1_MUX : std_logic_vector(31 DOWNTO 0);
SIGNAL Rd_MUX : std_logic_vector(2 downto 0);

BEGIN

    -- ==================== port maps ====================

    -- Control Unit
    control_inst : control
        PORT MAP(
            opcode    => IF_ID_Instr(31 DOWNTO 27),
            ALUSignal => ALUSignal_S,
            IMM_Flush => IMM_Flush_S,
            CALL      => CALL_S,
            RET       => RET_S,
            HLT       => HLT_S,
            INT       => INT_S,
            IMM       => IMM_S,
            setC      => setC_S,
            IN_p      => IN_p_S,
            SWAP      => SWAP_S,
            INC_NOT   => INC_NOT_S,
            Branch    => Branch_S,
            Buff      => Buff_S,
            OUT_p     => OUT_p_S,
            SP        => SP_S,
            WB        => WB_S,
            M         => M_S,
            JUMP_Type => JUMP_Type_S,
            FlagE     => FlagE_S,
            FlagReset => FlagReset_S
        );

    -- Register File
    regfile_inst: regfile
        PORT MAP(
            clk        => clk,
            rst        => rst,
            we         => MEM_WB_WB(1),  -- RegWrite signal
            r1_address => IF_ID_Instr(23 DOWNTO 21),  -- Rs1
            r2_address => r2_address_MUX,
            w_address  => MEM_WB_WriteAddress,
            data_in    => data_in_MUX,
            r1_data    => r1_data_S,
            r2_data    => r2_data_S
        );

    -- Rs2 Address MUX: Select between Rs2 and Rd for SWAP instruction
    -- During SWAP, we need to read Rd as the second operand
    r2_address_MUX <= IF_ID_Instr(26 DOWNTO 24) when (INC_NOT_S = '1' or SWAP_S = '1') else  -- Rd for SWAP
                      IF_ID_Instr(20 DOWNTO 18);                                   -- Rs2 normally

    -- Write Data MUX: Select data to write to register file
    -- Priority: IN_p > MemToReg > ALUData
    data_in_MUX <= MEM_WB_MemData when (MEM_WB_WB(0) = '1') else     -- MemToReg (LDD/POP)
                   MEM_WB_ALUData;                                   -- ALU result

    -- Output Port MUX: Select data for OUT instruction
    Output <= data_in_MUX when (MEM_WB_Out = '1') else (others => '0');

    -- Flags MUX: Select between current flags, restored flags (RET/RTI), or flags from memory (INT)
    -- JUMP_Type[1:0]: "10"=JN, "01"=JZ, "11"=JC, "00"=others
    with JUMP_Type_S select
        Flags_MUX <= FlagReg(2) when "10",
                    FlagReg(1) when "01",
                    FlagReg(0) when "11",
                    '1' when others;


    Prev_Flags_MUX <= ReadDataFlags when (RET_S = '1' and FlagE_S = "111") else (others => '0');

    ReadData1_MUX <= Input when IN_p_S = '1' else r1_data_S;

    Rd_MUX <= IF_ID_Instr(23 DOWNTO 21) when (SWAP_S = '1' and ID_EX_Swap = '1' and EX_MEM_Swap = '0')
              else IF_ID_Instr(26 DOWNTO 24);   -- Rd for SWAP
              

    -- ==================== output ====================
    
    JUMP <= Flags_MUX and Branch_S;

    -- Register Addresses
    Rs1_Address <= IF_ID_Instr(23 DOWNTO 21);
    Rs2_Address <= r2_address_MUX;
    Rd_Address <= Rd_MUX;

    -- Register Data
    ReadData1 <= ReadData1_MUX;
    ReadData2 <= r2_data_S;
    MEM_WB_WriteData <= data_in_MUX;

    -- Flags to next stage
    ID_EX_Flags <= Prev_Flags_MUX;

    -- Control Signals (with flush capability)
    -- When ID_EX_Flush is asserted, all control signals should be zeroed (NOP)
    IMM_Flush <= (IMM_Flush_S or External_INT);
    CALL      <= (CALL_S or External_INT);
    RET       <= RET_S;
    HLT       <= HLT_S;
    INT       <= (INT_S or External_INT);
    IMM       <= IMM_S;
    setC      <= setC_S;
    SWAP      <= SWAP_S;
    INC_NOT   <= INC_NOT_S;
    Buff      <= Buff_S;
    OUT_p     <= OUT_p_S;
    
    SP        <= (SP_S(1) & (SP_S(0) or External_INT));
    WB        <= WB_S;
    MEM       <= M_S;
    
    FlagReset <= FlagReset_S;
    ALUSignal <= ALUSignal_S;
    FlagE     <= FlagE_S;

END arch_dec_stage;