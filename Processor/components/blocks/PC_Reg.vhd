library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PC is
  port (
    clk      : in std_logic;
    PC_in    : in std_logic_vector(17 downto 0);
    PC_out   : out std_logic_vector(17 downto 0);
    HLT      : in std_logic;
    PC_stall : in std_logic
  );
end entity;
architecture rtl of PC is
  signal PC : std_logic_vector(17 downto 0) := (others => '0');
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if (HLT = '0' and PC_stall = '0') then
        PC <= PC_in;
      end if;
    end if;
  end process;
  PC_out <= PC;
end architecture rtl;