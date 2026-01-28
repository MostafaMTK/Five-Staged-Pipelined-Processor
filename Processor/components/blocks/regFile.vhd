LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY regfile IS
    PORT( 
        clk, rst, we: IN std_logic;
        r1_address, r2_address, w_address : IN std_logic_vector(2 DOWNTO 0);
        data_in   : IN std_logic_vector(31 DOWNTO 0);
        r1_data, r2_data : OUT std_logic_vector(31 DOWNTO 0)
    );
END ENTITY regfile;

ARCHITECTURE struct_regfile OF regfile IS
TYPE register_file_type IS ARRAY (0 to 7) OF std_logic_vector(31 DOWNTO 0);
SIGNAL register_file : register_file_type := (OTHERS => (OTHERS => '0'));
BEGIN
    
    PROCESS(clk)
        VARIABLE a : integer;
    BEGIN
        IF falling_edge(clk) THEN
            a := to_integer(unsigned(w_address));
            IF we = '1' THEN
                register_file(a) <= data_in;
            END IF;
        END IF;
    END PROCESS;

    WITH r1_address SELECT
        r1_data <= register_file(0) WHEN "000",
                   register_file(1) WHEN "001",
                   register_file(2) WHEN "010",
                   register_file(3) WHEN "011",
                   register_file(4) WHEN "100",
                   register_file(5) WHEN "101",
                   register_file(6) WHEN "110",
                   register_file(7) WHEN "111",
                   (OTHERS => '0') WHEN OTHERS;
    
    WITH r2_address SELECT
        r2_data <= register_file(0) WHEN "000",
                   register_file(1) WHEN "001",
                   register_file(2) WHEN "010",
                   register_file(3) WHEN "011",
                   register_file(4) WHEN "100",
                   register_file(5) WHEN "101",
                   register_file(6) WHEN "110",
                   register_file(7) WHEN "111",
                   (OTHERS => '0') WHEN OTHERS;

END struct_regfile;