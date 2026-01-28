library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SP is
  port (
    clk    : in std_logic;
    rst    : in std_logic;
    SP_in  : in std_logic_vector(17 downto 0);
    SP_out : out std_logic_vector(17 downto 0)
  );
end entity;

architecture rtl of SP is
  -- Initial SP = 2^18 - 1 = 262143 = 0x3FFFF
  signal SP_reg : std_logic_vector(17 downto 0) := (others => '1');
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        SP_reg <= (others => '1');  -- Reset to max value
      else
        SP_reg <= SP_in;
      end if;
    end if;
  end process;
  SP_out <= SP_reg;
end architecture rtl;