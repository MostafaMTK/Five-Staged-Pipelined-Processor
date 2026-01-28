LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY memory IS
  PORT(
    clk  : IN  std_logic;
    we   : IN  std_logic;
    addr : IN  std_logic_vector(17 DOWNTO 0);
    datain  : IN  std_logic_vector(31 DOWNTO 0);
    dataout : OUT std_logic_vector(31 DOWNTO 0)
  );
END memory;

ARCHITECTURE mem_arch OF memory IS
  TYPE ram_type IS ARRAY (262143 DOWNTO 0) OF std_logic_vector(31 DOWNTO 0);
  SIGNAL ram : ram_type := (OTHERS => (OTHERS => '0'));
  SIGNAL dout : std_logic_vector(31 DOWNTO 0);
BEGIN

  PROCESS(clk)
    VARIABLE a : integer;
  BEGIN
    IF falling_edge(clk) THEN
        a := to_integer(unsigned(addr));
        IF we = '1' THEN
            ram(a) <= datain;
            dout <= datain;
        ELSE
            dout <= ram(a);
        END IF;
    END IF;
  END PROCESS;

  dataout <= dout;

END mem_arch;
