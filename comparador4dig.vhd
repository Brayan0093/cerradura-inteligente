library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity comparador4dig is
port
(   
    comparar: in std_logic;
    dig0,dig1,dig2,dig3,clv0,clv1,clv2,clv3 : in std_logic_vector(3 downto 0);
    igual : out std_logic
);
end comparador4dig;

architecture arch_comparador4dig of comparador4dig is

    component comparador
        port (
		      comparar:in std_logic;
            a, b : in std_logic_vector(3 downto 0);
            igu  : out std_logic
        );
    end component;

    signal tem0, tem1, tem2, tem3 : std_logic;

begin

    H: comparador port map (comparar, dig0, clv0, tem0);
    S: comparador port map (comparar, dig1, clv1, tem1);
    F: comparador port map (comparar, dig2, clv2, tem2);
    G: comparador port map (comparar, dig3, clv3, tem3);

    igual <= tem0 and tem1 and tem2 and tem3;

end arch_comparador4dig;