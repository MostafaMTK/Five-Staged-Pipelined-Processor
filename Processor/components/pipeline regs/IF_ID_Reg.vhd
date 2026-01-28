library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IF_ID_Reg is
  port (
    clk         : in std_logic;
    Instr_in    : in std_logic_vector(31 downto 0);
    Instr_out   : out std_logic_vector(31 downto 0);
    IMM_in      : in std_logic_vector(31 downto 0);
    IMM_out     : out std_logic_vector(31 downto 0);
    IF_ID_stall : in std_logic;
    IF_ID_Flush : in std_logic;
    reset       : in std_logic;
    HLT         : in std_logic;
    EX_Mem_mem  : in std_logic
  );
end entity IF_ID_Reg;

architecture rtl of IF_ID_Reg is
  signal Instr : std_logic_vector(31 downto 0) := (others => '0');
  signal IMM   : std_logic_vector(31 downto 0)  := (others => '0');
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if (not(reset = '0' and(IF_ID_stall = '1' or HLT = '1' or (EX_Mem_mem = '1' and IF_ID_Flush = '0')))) then
        Instr <= Instr_in;
      end if;
      IMM <= IMM_in;
    end if;
  end process;
  Instr_out <= Instr;
  IMM_out   <= IMM;
end architecture rtl;