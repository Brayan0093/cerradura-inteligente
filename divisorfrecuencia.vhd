LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY divisorfrecuencia IS
    PORT (
        clk  : IN STD_LOGIC;
        out1, out2 : BUFFER STD_LOGIC
    );
END divisorfrecuencia;

ARCHITECTURE arch_divisorfrecuencia OF divisorfrecuencia IS
    SIGNAL count1 : INTEGER RANGE 0 TO 24999999;
BEGIN

    PROCESS (clk)
        VARIABLE count2 : INTEGER RANGE 0 TO 24999999;
    BEGIN
        IF (clk'EVENT AND clk = '1') THEN
            count1 <= count1 + 1;
            count2 := count2 + 1;

            IF (count1 =24999999 ) THEN
                out1 <= NOT out1;
                count1 <= 0;
            END IF;

            IF (count2 = 24999999) THEN
                out2 <= NOT out2;
                count2 := 0;
            END IF;

        END IF;
    END PROCESS;

END arch_divisorfrecuencia;