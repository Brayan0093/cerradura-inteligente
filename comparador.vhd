library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity comparador is

port
(   comparar: in std_logic;
    a , b : in std_logic_vector(3 downto 0);
    igu : out std_logic
);

end comparador;

architecture arch_comparador of comparador is

begin

compara: process(comparar,a,b)
begin

    if (comparar = '1')then 
    
    igu <= '0';

    if (a = b) then
        igu <= '1';

    
    else
        igu <= '0';

    end if;
	 end if;

end process;

end arch_comparador;