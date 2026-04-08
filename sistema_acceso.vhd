library IEEE;
use IEEE.std_logic_1164.all;

-- ============================================================
-- sistema_acceso  (TOP LEVEL)
-- Integra comparadorfinal (compañero) + módulos propios:
--   - contador_intentos
--   - alarma
--   - control_puerta
--   - display_control
-- ============================================================
entity sistema_acceso is
    port (
        Clock         : in  std_logic;   -- 50 MHz (FPGA)
        reset_teclado : in  std_logic;   -- botón reset teclado
        reset_tiempo  : in  std_logic;   -- botón reset reloj
        reset_admin   : in  std_logic;   -- botón admin (desbloquea sistema)
        entrada       : in  std_logic_vector(3 downto 0);  -- teclado BCD
        save_dig      : in  std_logic;   -- guardar dígito
        comparar_dig  : in  std_logic;   -- comparar clave completa
        -- Salidas físicas
        cerradura     : out std_logic;   -- relay de la cerradura
        alarma_sonido : out std_logic;   -- buzzer
        alarma_visual : out std_logic;   -- LED alarma
        seg           : out std_logic_vector(6 downto 0);  -- display 7 seg
        an            : out std_logic_vector(3 downto 0)   -- ánodos display
    );
end entity;

architecture arch_sistema of sistema_acceso is

    -- ---- Componentes del compañero ------------------------
    component comparadorfinal
        port (
            entrada              : in  std_logic_vector(3 downto 0);
            Clock                : in  std_logic;
            reset_tiempo         : in  std_logic;
            reset_teclado        : in  std_logic;
            save_dig             : in  std_logic;
            comparar_dig         : in  std_logic;
            digito0, digito1     : buffer std_logic_vector(3 downto 0);
            digito2, digito3     : buffer std_logic_vector(3 downto 0);
            accs_permitido, accs_denegado : out std_logic
        );
    end component;

    -- ---- Componentes propios ------------------------------
    component contador_intentos
        port (
            Clock          : in  std_logic;
            reset          : in  std_logic;
            accs_denegado  : in  std_logic;
            accs_permitido : in  std_logic;
            bloqueo_activo : out std_logic;
            alarma_activa  : out std_logic;
            intentos       : out std_logic_vector(1 downto 0)
        );
    end component;

    component alarma
        port (
            Clock          : in  std_logic;
            reset          : in  std_logic;
            alarma_activa  : in  std_logic;
            alarma_sonido  : out std_logic;
            alarma_visual  : out std_logic;
            cuenta_reg_alr : out std_logic_vector(4 downto 0)
        );
    end component;

    component control_puerta
        port (
            Clock          : in  std_logic;
            reset          : in  std_logic;
            accs_permitido : in  std_logic;
            bloqueo_activo : in  std_logic;
            cerradura      : out std_logic;
            estado         : out std_logic_vector(1 downto 0);
            cuenta_reg     : out std_logic_vector(4 downto 0)
        );
    end component;

    component display_control
        port (
            Clock      : in  std_logic;
            reset      : in  std_logic;
            estado     : in  std_logic_vector(1 downto 0);
            cuenta_reg : in  std_logic_vector(4 downto 0);
            digito0    : in  std_logic_vector(3 downto 0);
            digito1    : in  std_logic_vector(3 downto 0);
            digito2    : in  std_logic_vector(3 downto 0);
            digito3    : in  std_logic_vector(3 downto 0);
            seg        : out std_logic_vector(6 downto 0);
            an         : out std_logic_vector(3 downto 0)
        );
    end component;

    -- ---- Señales internas ---------------------------------
    signal accs_perm   : std_logic;
    signal accs_den    : std_logic;
    signal bloqueo     : std_logic;
    signal alr_activa  : std_logic;
    signal dig0,dig1,dig2,dig3 : std_logic_vector(3 downto 0);
    signal estado_puerta       : std_logic_vector(1 downto 0);
    signal cuenta_puerta       : std_logic_vector(4 downto 0);
    signal cuenta_alr          : std_logic_vector(4 downto 0);
    -- El display usa cuenta_puerta en OPEN y cuenta_alr en ALR
    signal cuenta_display      : std_logic_vector(4 downto 0);

begin

    -- Selección de cuenta regresiva para display
    cuenta_display <= cuenta_alr when estado_puerta = "11" else cuenta_puerta;

    -- ---- Instancias ---------------------------------------
    U1: comparadorfinal port map (
        entrada       => entrada,
        Clock         => Clock,
        reset_tiempo  => reset_tiempo,
        reset_teclado => reset_teclado,
        save_dig      => save_dig,
        comparar_dig  => comparar_dig,
        digito0       => dig0,
        digito1       => dig1,
        digito2       => dig2,
        digito3       => dig3,
        accs_permitido => accs_perm,
        accs_denegado  => accs_den
    );

    U2: contador_intentos port map (
        Clock          => Clock,
        reset          => reset_admin,
        accs_denegado  => accs_den,
        accs_permitido => accs_perm,
        bloqueo_activo => bloqueo,
        alarma_activa  => alr_activa,
        intentos       => open
    );

    U3: alarma port map (
        Clock          => Clock,
        reset          => reset_admin,
        alarma_activa  => alr_activa,
        alarma_sonido  => alarma_sonido,
        alarma_visual  => alarma_visual,
        cuenta_reg_alr => cuenta_alr
    );

    U4: control_puerta port map (
        Clock          => Clock,
        reset          => reset_admin,
        accs_permitido => accs_perm,
        bloqueo_activo => bloqueo,
        cerradura      => cerradura,
        estado         => estado_puerta,
        cuenta_reg     => cuenta_puerta
    );

    U5: display_control port map (
        Clock      => Clock,
        reset      => reset_admin,
        estado     => estado_puerta,
        cuenta_reg => cuenta_display,
        digito0    => dig0,
        digito1    => dig1,
        digito2    => dig2,
        digito3    => dig3,
        seg        => seg,
        an         => an
    );

end architecture;
