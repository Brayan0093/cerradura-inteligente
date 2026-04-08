library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity comparadortiempo is

port
(   comparar :in std_logic;
    hora ,horaincio,horafinal : in std_logic_vector(7 downto 0);
    igu : out std_logic
);

end comparadortiempo;

architecture arch_comparadortiempo of comparadortiempo is

begin

compara: process(comparar,hora)
begin

    
    
    igu <= '0';
	 if (comparar = '1') then 

    if ((hora>=horaincio)and (hora< horafinal)) then
        igu <= '1';

    
    else
        igu <= '0';

    end if;
	 end if ;

end process;

end arch_comparadortiempo;