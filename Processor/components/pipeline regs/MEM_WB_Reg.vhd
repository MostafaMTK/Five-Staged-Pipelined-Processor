library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MEM_WB_Reg is
  port (
    clk         : in std_logic;
    out_in      : in std_logic;
    out_out     : out std_logic;
    WB_in       : in std_logic_vector(1 downto 0);
    WB_out      : out std_logic_vector(1 downto 0);
    Rd_in       : in std_logic_vector(2 downto 0);
    Rd_out      : out std_logic_vector(2 downto 0);
    aluData_in  : in std_logic_vector(31 downto 0);
    aluData_out : out std_logic_vector(31 downto 0);
    memData_in  : in std_logic_vector(31 downto 0);
    memData_out : out std_logic_vector(31 downto 0));
end entity MEM_WB_Reg;

architecture rtl of MEM_WB_Reg is
  signal out_s   : std_logic                     := '0';
  signal Rd      : std_logic_vector(2 downto 0)  := (others => '0');
  signal WB      : std_logic_vector(1 downto 0)  := (others => '0');
  signal aluData : std_logic_vector(31 downto 0) := (others => '0');
  signal memData : std_logic_vector(31 downto 0) := (others => '0');

begin
  process (clk)
  begin
    if rising_edge(clk) then
      out_s   <= out_in;
      WB      <= WB_in;
      Rd      <= Rd_in;
      aluData <= aluData_in;
      memData <= memData_in;
    end if;
  end process;
  out_out     <= out_s;
  WB_out      <= WB;
  Rd_out      <= Rd;
  aluData_out <= aluData;
  memData_out <= memData;

end architecture rtl;