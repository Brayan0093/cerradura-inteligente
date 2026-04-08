library IEEE;
use IEEE.std_logic_1164.all;

-- ============================================================
-- contador_intentos
-- Cuenta intentos fallidos (accs_denegado).
-- Al llegar a 3: activa bloqueo_activo y alarma_activa.
-- Se resetea con accs_permitido o reset externo.
-- ============================================================
entity contador_intentos is
    port (
        Clock          : in  std_logic;
        reset          : in  std_logic;   -- reset externo (admin)
        accs_denegado  : in  std_logic;   -- pulso del comparadorfinal
        accs_permitido : in  std_logic;   -- pulso del comparadorfinal
        bloqueo_activo : out std_logic;   -- 1 = sistema bloqueado
        alarma_activa  : out std_logic;   -- 1 = alarma sonando
        intentos       : out std_logic_vector(1 downto 0) -- 0..3
    );
end entity;

architecture arch_contador_intentos of contador_intentos is

    signal cnt : integer range 0 to 3 := 0;

begin

    process (Clock, reset)
    begin
        if (reset = '1') then
            cnt <= 0;
        elsif (Clock'event and Clock = '1') then
            if (accs_permitido = '1') then
                cnt <= 0;                        -- acceso OK: limpiar contador
            elsif (accs_denegado = '1') then
                if (cnt < 3) then
                    cnt <= cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -- Salidas combinacionales
    bloqueo_activo <= '1' when cnt >= 3 else '0';
    alarma_activa  <= '1' when cnt >= 3 else '0';

    intentos <= "00" when cnt = 0 else
                "01" when cnt = 1 else
                "10" when cnt = 2 else
                "11";

end architecture;
