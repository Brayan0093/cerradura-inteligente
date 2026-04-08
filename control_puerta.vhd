library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- ============================================================
-- control_puerta
-- Maneja el estado de la cerradura y los temporizadores.
--
-- Estados:
--   IDLE    : esperando clave
--   ABIERTA : puerta habilitada (10 s), cuenta regresiva
--   CERRADA : puerta cerrada, esperando nueva clave
--   BLOQUEADA: bloqueo por 3 intentos fallidos (30 s)
--
-- Salidas:
--   cerradura   : 1 = puerta desbloqueada (abierta)
--   estado      : 2 bits para el display
--                 "00"=IDLE, "01"=ABIERTA, "10"=CERRADA, "11"=BLOQUEADA
--   cuenta_reg  : cuenta regresiva en segundos para el display
-- ============================================================
entity control_puerta is
    port (
        Clock          : in  std_logic;   -- 50 MHz
        reset          : in  std_logic;   -- reset externo
        accs_permitido : in  std_logic;   -- del comparadorfinal
        bloqueo_activo : in  std_logic;   -- del contador_intentos
        cerradura      : out std_logic;   -- 1 = desbloqueada
        estado         : out std_logic_vector(1 downto 0);
        cuenta_reg     : out std_logic_vector(4 downto 0)  -- 0..30
    );
end entity;

architecture arch_control_puerta of control_puerta is

    type estado_t is (IDLE, ABIERTA, CERRADA, BLOQUEADA);
    signal estado_act : estado_t := IDLE;

    -- Generador 1 Hz
    signal div_cnt  : integer range 0 to 24999999 := 0;
    signal clk_1hz  : std_logic := '0';

    -- Contador de segundos
    signal seg_cnt  : integer range 0 to 30 := 0;

    -- Tiempo puerta abierta: 10 s
    -- Tiempo bloqueo:        30 s
    constant T_ABIERTA  : integer := 10;
    constant T_BLOQUEADA: integer := 30;

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

    -- ---- Máquina de estados / temporizador ----------------
    process (clk_1hz, reset)
    begin
        if (reset = '1') then
            estado_act <= IDLE;
            seg_cnt    <= 0;
        elsif (clk_1hz'event and clk_1hz = '1') then
            case estado_act is

                when IDLE =>
                    seg_cnt <= 0;
                    if (bloqueo_activo = '1') then
                        estado_act <= BLOQUEADA;
                        seg_cnt    <= T_BLOQUEADA;
                    elsif (accs_permitido = '1') then
                        estado_act <= ABIERTA;
                        seg_cnt    <= T_ABIERTA;
                    end if;

                when ABIERTA =>
                    if (bloqueo_activo = '1') then
                        estado_act <= BLOQUEADA;
                        seg_cnt    <= T_BLOQUEADA;
                    elsif (seg_cnt > 0) then
                        seg_cnt <= seg_cnt - 1;
                    else
                        estado_act <= CERRADA;
                        seg_cnt    <= 0;
                    end if;

                when CERRADA =>
                    seg_cnt <= 0;
                    if (bloqueo_activo = '1') then
                        estado_act <= BLOQUEADA;
                        seg_cnt    <= T_BLOQUEADA;
                    elsif (accs_permitido = '1') then
                        estado_act <= ABIERTA;
                        seg_cnt    <= T_ABIERTA;
                    end if;

                when BLOQUEADA =>
                    if (reset = '1') then
                        estado_act <= IDLE;
                        seg_cnt    <= 0;
                    elsif (seg_cnt > 0) then
                        seg_cnt <= seg_cnt - 1;
                    else
                        -- bloqueo terminado, volver a IDLE
                        estado_act <= IDLE;
                        seg_cnt    <= 0;
                    end if;

            end case;
        end if;
    end process;

    -- ---- Salidas combinacionales --------------------------
    cerradura <= '1' when estado_act = ABIERTA   else '0';

    estado    <= "00" when estado_act = IDLE     else
                 "01" when estado_act = ABIERTA  else
                 "10" when estado_act = CERRADA  else
                 "11";   -- BLOQUEADA

    cuenta_reg <= std_logic_vector(to_unsigned(seg_cnt, 5));

end architecture;
