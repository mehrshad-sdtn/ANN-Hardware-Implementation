LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;
USE ieee.fixed_pkg.ALL;
USE ieee.float_pkg.ALL;

ENTITY nn IS
	PORT(
			clk  	: IN  std_logic;
			nrst  	: IN  std_logic;
            r_file  : IN  std_logic;
            ot      : OUT integer

            
			
	);
END nn;

ARCHITECTURE behavioral OF nn IS
 CONSTANT int  : INTEGER :=  2;
 CONSTANT frac : INTEGER := 14;
 CONSTANT int_r  : INTEGER :=  4;
 CONSTANT frac_r : INTEGER := 28;
 SUBTYPE sfixed_bus IS sfixed(int - 1 DOWNTO -frac);
 TYPE    sfixed_bus_arr IS ARRAY (INTEGER RANGE <>) OF sfixed_bus;

 SUBTYPE sfixed_bus_res IS sfixed(int_r - 1 DOWNTO -frac_r);
 TYPE    sfixed_bus_arr_res IS ARRAY (INTEGER RANGE <>) OF sfixed_bus_res;

 TYPE    matrix IS ARRAY (INTEGER RANGE <>, INTEGER RANGE <>) OF sfixed_bus;

 CONSTANT dim0 : INTEGER := 784;
 CONSTANT dim1 : INTEGER := 32;
 CONSTANT dim2 : INTEGER := 10;

 SIGNAL W0 : matrix (0 TO 31, 0 TO 784);
 SIGNAL W1 : matrix (0 TO 9, 0 TO 32);
 SIGNAL B0 : sfixed_bus_arr (0 TO 32);
 SIGNAL B1 : sfixed_bus_arr (0 TO 9);
 SIGNAL A0 : sfixed_bus_arr (0 TO 784);
 SIGNAL A1 : sfixed_bus_arr (0 TO 31);
 SIGNAL A2 : sfixed_bus_arr (0 TO 9);
 SIGNAL Y1 : sfixed_bus_arr (0 TO 31);
 SIGNAL Y2 : sfixed_bus_arr (0 TO 9);

 SIGNAL ready: std_logic;
 SIGNAL maxval :  INTEGER := 0;
 
 BEGIN

    rd: PROCESS (r_file)
        FILE w0_file: text;
        FILE w1_file: text;
        FILE b0_file: text;
        FILE b1_file: text;
        FILE x_file : text;
        VARIABLE cur_line, cur_line0, cur_line1, cur_line2, cur_line3 : line;
        VARIABLE var, var0, var1, var2, var3 : Real;--sfixed(int - 1 DOWNTO -frac); 

        
    BEGIN
        file_open(w0_file, "W0.txt", read_mode);
        file_open(w1_file, "W1.txt", read_mode);
        file_open(b0_file, "b0.txt", read_mode);
        file_open(b1_file, "b1.txt", read_mode);
        file_open(x_file ,  "x.txt", read_mode);

    ------------------- loading feature vector -------------------------------

        FOR i IN 0 TO 784 - 1 LOOP
            --IF NOT endfile(x_file) THEN
                readline(x_file, cur_line);
                read(cur_line, var);
                A0(i) <= to_sfixed((var), A0(i));
            --END IF;
        END LOOP;
    
    ---------------------------weights & biases-------------------------------
        FOR j0 IN 0 TO 32 - 1 LOOP
            FOR k0 IN 0 TO 784 - 1 LOOP
                IF NOT endfile(w0_file) THEN
                    readline(w0_file, cur_line0);
                    read(cur_line0, var0);
                    W0(j0,k0) <= to_sfixed((var0), W0(j0,k0));
                END IF;
            END LOOP;
        END LOOP;

        FOR j1 IN 0 TO 10 - 1 LOOP
            FOR k1 IN 0 TO 32 - 1 LOOP
                IF NOT endfile(w1_file) THEN
                    readline(w1_file, cur_line1);
                    read(cur_line1, var1);
                    W1(j1,k1) <= to_sfixed((var1), W1(j1,k1));
                END IF;
            END LOOP;
        END LOOP;

        FOR i0 IN 0 TO 32 - 1 LOOP
            IF NOT endfile(b0_file) THEN
                readline(b0_file, cur_line2);
                read(cur_line2, var2);
                B0(i0) <= to_sfixed((var2), B0(i0));
            END IF;
        END LOOP;

        FOR i1 IN 0 TO 10 - 1 LOOP
            IF NOT endfile(b1_file) THEN
                readline(b1_file, cur_line3);
                read(cur_line3, var3);
                B1(i1) <= to_sfixed((var3), B1(i1));
            END IF;
        END LOOP;

        file_close(w0_file);
        file_close(w1_file);
        file_close(b0_file);
        file_close(b1_file);
        file_close(x_file );
                
    END PROCESS rd;


    ff: PROCESS (clk, nrst) 
    BEGIN
        IF clk = '1' AND clk'event THEN
            IF nrst = '1' THEN
                -- layer 1
                -- W0 x A0 
                FOR i0 IN 0 TO dim1 - 1 LOOP
                    FOR j0 IN 0 TO dim0 - 1 LOOP 
                        Y1(i0) <= Y1(i0) + W0(i0,j0) * A0(j0);
                    END LOOP;
                END LOOP;
                --- W0A0 + b0
                FOR l0 IN 0 TO dim1 - 1 LOOP
                    Y1(l0) <= Y1(l0) + B0(l0);
                    A1(l0) <= 0.5 * ( Y1(l0)/(1 + ((Y1(l0)))) + 1); --sigmoid approx.
                    --A1(l0) <= Y1(l0);
                END LOOP;


                --- layer 2
                --- W1 X A1
                FOR i1 IN 0 TO dim2 - 1 LOOP
                    FOR j1 IN 0 TO dim1 - 1 LOOP 
                        Y2(i1) <= Y2(i1) + W1(i1,j1) * A1(j1);
                    END LOOP;
                END LOOP;
                --- W1A1 + b1
                FOR l1 IN 0 TO dim2 - 1 LOOP
                    Y2(l1) <= Y2(l1) + B1(l1);
                    A2(l1) <= 0.5 * ( Y2(l1)/(1 + ((Y2(l1)))) + 1); -- sigmoid approx
                    --A2(l1) <= Y2(l1);
                    IF l1 = dim2 - 1 THEN
                        ready <= '1';
                    END IF; 
                END LOOP;
            ELSE 
                W0 <= (OTHERS => (OTHERS => x"0000"));
                W1 <= (OTHERS => (OTHERS => x"0000"));
                B0 <= (OTHERS => x"0000");
                B1 <= (OTHERS => x"0000");
                A0 <= (OTHERS => x"0000");
                A1 <= (OTHERS => x"0000");
                A2 <= (OTHERS => x"0000");
                Y1 <= (OTHERS => x"0000");
                Y2 <= (OTHERS => x"0000");
                --maxval <= (OTHERS => 0);
           
            END IF;
        END IF;
    

    END PROCESS ff;



    pred: PROCESS (ready) 
    VARIABLE max :  sfixed(int - 1 DOWNTO -frac);
    --VARIABLE maxval :  INTEGER;
    BEGIN
        max := A2(0);
        FOR i IN 0 TO dim2-1 LOOP
            IF A2(i) > max THEN
                max := A2(i);
                maxval <= i;
            END IF;
        END LOOP;
    --ot := maxval;  
    END PROCESS pred;
    ot <= maxval;


    
    
 END behavioral;
	
	
