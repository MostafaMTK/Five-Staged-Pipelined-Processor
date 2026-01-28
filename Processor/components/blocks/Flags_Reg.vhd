library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Flags is
  port (
    clk         : in std_logic;
    FEnable     : in std_logic_vector(2 downto 0);--N,Z,C
    reset_flags : in std_logic_vector(2 downto 0);--N,Z,C
    alu_Flags   : in std_logic_vector(2 downto 0);--N,Z,C
    ID_EX_Flags : in std_logic_vector(2 downto 0);--N,Z,C
    set_carry   : in std_logic;
    Flags_out   : out std_logic_vector(2 downto 0)

  );
end entity;

architecture rtl of Flags is
  signal Flags : std_logic_vector(2 downto 0) := (others => '0');
begin
  process (clk)
  begin
    if falling_edge(clk) then
      for i in 0 to 1 loop
        if reset_flags(i) = '1' then
          Flags(i) <= '0';
        elsif FEnable(i) = '1' then
          Flags(i) <= alu_Flags(i)or ID_EX_Flags(i);
        end if;
      end loop;

      if reset_flags(2) = '1' then
        Flags(2) <= '0';
      elsif FEnable(2) = '1' then
        Flags(2) <= alu_Flags(2) or ID_EX_Flags(2) or set_carry;
      end if;
    end if;
  end process;
  Flags_out <= Flags;
end architecture rtl;