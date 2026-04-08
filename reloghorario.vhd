library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity reloghorario is
    port (
        Clock, Reset : in std_logic;
        CNT : out std_logic_vector(7 downto 0)  -- 8 bits para llegar a 179
    );
end entity;

architecture arch_contador of reloghorario is

    signal CNT_int : integer range 0 to 179;
    
    component divisorfrecuencia
        port (
            clk        : in  std_logic;
            out1, out2 : buffer std_logic
        );
    end component;
    
    signal tem : std_logic;

begin

    h: divisorfrecuencia port map (Clock, tem, open);

    COUNTER : process (Clock, Reset)
    begin
        if (Reset = '1') then
            CNT_int <= 0;
        elsif (tem'event and tem = '1') then
            if (CNT_int = 179) then
                CNT_int <= 0;
            else
                CNT_int <= CNT_int + 1;
            end if;
        end if;
    end process;

    CNT <= std_logic_vector(to_unsigned(CNT_int, 8));

end architecture;