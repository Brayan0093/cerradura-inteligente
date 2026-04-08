library IEEE;
use IEEE.std_logic_1164.all;

entity registro4dig is
    port (Clock, Reset : in  std_logic;
          Din          : in  std_logic_vector(3 downto 0);
          Dout0, Dout1 : out std_logic_vector(3 downto 0);
          Dout2, Dout3 : out std_logic_vector(3 downto 0));
end entity;

architecture arch_registro4dig of registro4dig is

    signal D0, D1, D2, D3 : std_logic_vector(3 downto 0);

begin

    SHIFT : process (Clock, Reset)
    begin
        if (Reset = '1') then
            D0 <= "0000"; D1 <= "0000"; D2 <= "0000"; D3 <= "0000";
        elsif (Clock'event and Clock = '1') then
            D0 <= Din; D1 <= D0; D2 <= D1; D3 <= D2;
        end if;
    end process;

    Dout3 <= D3; Dout2 <= D2; Dout1 <= D1; Dout0 <= D0;

end architecture;