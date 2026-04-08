library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- ============================================================
-- alarma
-- Se activa cuando alarma_activa = 1.
-- Genera una salida sonora (tono cuadrado) y visual.
-- Cuenta regresiva de 30 segundos en alarma (para display).
-- Se desactiva solo con reset externo (administrador).
-- ============================================================
entity alarma is
    port (
        Clock          : in  std_logic;   -- 50 MHz
        reset          : in  std_logic;   -- reset externo (admin)
        alarma_activa  : in  std_logic;   -- viene de contador_intentos
        alarma_sonido  : out std_logic;   -- señal cuadrada para buzzer
        alarma_visual  : out std_logic;   -- LED o salida visual
        cuenta_reg_alr : out std_logic_vector(4 downto 0)  -- 0..30 para display
    );
end entity;

architecture arch_alarma of alarma is

    -- Divisor para 1 Hz desde 50 MHz
    signal div_cnt   : integer range 0 to 24999999 := 0;
    signal clk_1hz   : std_logic := '0';

    -- Divisor para tono ~1kHz (buzzer)
    signal tone_cnt  : integer range 0 to 24999 := 0;
    signal tono      : std_logic := '0';

    -- Contador regresivo alarma (30 segundos)
    signal seg_cnt   : integer range 0 to 30 := 30;

begin

    -- ---- Generador 1 Hz -----------------------------------
    process (Clock, reset)
    begin
        if (reset = '1') then
            div_cnt <= 0;
            clk_1hz <= '0';
        elsif (Clock'event and Clock = '1') then
            if (div_cnt = 24999999) then
                div_cnt <= 0;
                clk_1hz <= not clk_1hz;
            else
                div_cnt <= div_cnt + 1;
            end if;
        end if;
    end process;

    -- ---- Generador tono 1 kHz (buzzer) --------------------
    process (Clock, reset)
    begin
        if (reset = '1') then
            tone_cnt <= 0;
            tono     <= '0';
        elsif (Clock'event and Clock = '1') then
            if (tone_cnt = 24999) then
                tone_cnt <= 0;
                tono     <= not tono;
            else
                tone_cnt <= tone_cnt + 1;
            end if;
        end if;
    end process;

    -- ---- Cuenta regresiva 30 s en alarma ------------------
    process (clk_1hz, reset)
    begin
        if (reset = '1') then
            seg_cnt <= 30;
        elsif (clk_1hz'event and clk_1hz = '1') then
            if (alarma_activa = '1') then
                if (seg_cnt > 0) then
                    seg_cnt <= seg_cnt - 1;
                else
                    seg_cnt <= 30;   -- reinicia para seguir mostrando
                end if;
            else
                seg_cnt <= 30;       -- no en alarma: mantener en 30
            end if;
        end if;
    end process;

    -- ---- Salidas ------------------------------------------
    alarma_sonido  <= tono          when alarma_activa = '1' else '0';
    alarma_visual  <= clk_1hz       when alarma_activa = '1' else '0';  -- parpadeo 1 Hz
    cuenta_reg_alr <= std_logic_vector(to_unsigned(seg_cnt, 5));

end architecture;
