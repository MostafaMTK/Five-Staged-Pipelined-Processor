library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prevPc_Flags is
  port (
    clk      : in std_logic;
    INT      : in std_logic;
    CALL     : in std_logic;
    Flags_in : in std_logic_vector(2 downto 0);
    PC_in    : in std_logic_vector(17 downto 0);
    output   : out std_logic_vector(20 downto 0)
  );
end entity prevPc_Flags;

architecture rtl of prevPc_Flags is
  signal prev_PC : std_logic_vector(17 downto 0);
  signal flags   : std_logic_vector(2 downto 0);
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if (INT = '1' or CALL = '1') then
        prev_PC <= PC_in;
        flags   <= Flags_in;
      end if;
    end if;
  end process;
  output <= flags & prev_PC;

end architecture rtl;