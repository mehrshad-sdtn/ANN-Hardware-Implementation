LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;
LIBRARY ieee;
USE ieee.fixed_pkg.ALL;

ENTITY nn_tb IS
END nn_tb;
ARCHITECTURE behavioral OF nn_tb IS
	COMPONENT nn is
		PORT(
			clk  	: IN  std_logic;
			nrst  	: IN  std_logic;
            r_file  : IN  std_logic;
            ot      : OUT integer
			
		);
	END COMPONENT;
	
	SIGNAL t_clk      : std_logic := '0';
	SIGNAL t_nrst     : std_logic;
	SIGNAL t_r_file   : std_logic;
    SIGNAL t_ot       : integer;	

BEGIN
	cut : nn PORT MAP (t_clk, t_nrst, t_r_file, t_ot);
	
	t_clk <= NOT t_clk AFTER 5 ns;
	t_nrst <= '0', '1' AFTER 33 ns;
	t_r_file <= '0', '1' AFTER 43 ns;
END behavioral;
	
	
