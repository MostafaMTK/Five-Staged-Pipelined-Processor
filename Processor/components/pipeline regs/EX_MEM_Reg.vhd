
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EX_MEM_Reg is
  port (
    clk           : in std_logic;
    swap_in       : in std_logic;
    swap_out      : out std_logic;
    out_in        : in std_logic;
    out_out       : out std_logic;
    call_in       : in std_logic;
    call_out      : out std_logic;
    SP_in         : in std_logic_vector(1 downto 0);
    SP_out        : out std_logic_vector(1 downto 0);
    WB_in         : in std_logic_vector(1 downto 0);
    WB_out        : out std_logic_vector(1 downto 0);
    Mem_in        : in std_logic_vector (1 downto 0);
    Mem_out       : out std_logic_vector (1 downto 0);
    Rd_in         : in std_logic_vector(2 downto 0);
    Rd_out        : out std_logic_vector(2 downto 0);
    aluData_in    : in std_logic_vector(31 downto 0);
    aluData_out   : out std_logic_vector(31 downto 0);
    writeData_in  : in std_logic_vector(31 downto 0);
    writeData_out : out std_logic_vector(31 downto 0);
    INT_in        : in std_logic;
    INT_out       : out std_logic
    );
end entity EX_MEM_Reg;

architecture rtl of EX_MEM_Reg is
  signal swap      : std_logic                     := '0';
  signal out_s     : std_logic                     := '0';
  signal call      : std_logic                     := '0';
  signal SP        : std_logic_vector(1 downto 0)  := (others => '0');
  signal WB        : std_logic_vector(1 downto 0)  := (others => '0');
  signal Mem       : std_logic_vector (1 downto 0) := (others => '0');
  signal Rd        : std_logic_vector(2 downto 0)  := (others => '0');
  signal aluData   : std_logic_vector(31 downto 0) := (others => '0');
  signal writeData : std_logic_vector(31 downto 0) := (others => '0');
  signal INT       : std_logic := '0';

begin
  process (clk)
  begin
    if rising_edge(clk) then
      swap      <= swap_in;
      out_s     <= out_in;
      call      <= call_in;
      SP        <= SP_in;
      WB        <= WB_in;
      Mem       <= Mem_in;
      Rd        <= Rd_in;
      aluData   <= aluData_in;
      writeData <= writeData_in;
      INT       <= INT_in;
    end if;
  end process;
  swap_out      <= swap;
  out_out       <= out_s;
  call_out      <= call;
  SP_out        <= SP;
  WB_out        <= WB;
  Mem_out       <= Mem;
  Rd_out        <= Rd;
  aluData_out   <= aluData;
  writeData_out <= writeData;
  INT_out       <= INT;
end architecture rtl;