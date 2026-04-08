library IEEE;
use IEEE.std_logic_1164.all;

-- ============================================================
-- tb_sistema_acceso
-- Testbench para el sistema completo de control de acceso.
--
-- Pruebas incluidas:
--   TEST 1: Clave correcta (1111) → cerradura abre
--   TEST 2: Clave incorrecta #1   → accs_denegado, intento 1
--   TEST 3: Clave incorrecta #2   → accs_denegado, intento 2
--   TEST 4: Clave incorrecta #3   → bloqueo + alarma activa
--   TEST 5: Reset admin           → sistema vuelve a IDLE
-- ============================================================
entity tb_sistema_acceso is
end entity;

architecture arch_tb of tb_sistema_acceso is

    -- ---- Componente bajo prueba ---------------------------
    component sistema_acceso
        port (
            Clock         : in  std_logic;
            reset_teclado : in  std_logic;
            reset_tiempo  : in  std_logic;
            reset_admin   : in  std_logic;
            entrada       : in  std_logic_vector(3 downto 0);
            save_dig      : in  std_logic;
            comparar_dig  : in  std_logic;
            cerradura     : out std_logic;
            alarma_sonido : out std_logic;
            alarma_visual : out std_logic;
            seg           : out std_logic_vector(6 downto 0);
            an            : out std_logic_vector(3 downto 0)
        );
    end component;

    -- ---- Señales del testbench ----------------------------
    signal Clock         : std_logic := '0';
    signal reset_teclado : std_logic := '0';
    signal reset_tiempo  : std_logic := '0';
    signal reset_admin   : std_logic := '0';
    signal entrada       : std_logic_vector(3 downto 0) := "0000";
    signal save_dig      : std_logic := '0';
    signal comparar_dig  : std_logic := '0';

    signal cerradura     : std_logic;
    signal alarma_sonido : std_logic;
    signal alarma_visual : std_logic;
    signal seg           : std_logic_vector(6 downto 0);
    signal an            : std_logic_vector(3 downto 0);

    -- Clock 50 MHz → periodo = 20 ns
    constant T_CLK : time := 20 ns;

    -- ---- Procedimiento: ingresar un dígito ----------------
    -- Simula presionar un botón del teclado (save_dig)
    procedure ingresar_digito (
        signal entrada_s  : out std_logic_vector(3 downto 0);
        signal save_dig_s : out std_logic;
        constant digito   : in  std_logic_vector(3 downto 0)
    ) is
    begin
        entrada_s  <= digito;
        wait for 5 * T_CLK;
        save_dig_s <= '1';
        wait for 2 * T_CLK;
        save_dig_s <= '0';
        wait for 5 * T_CLK;
    end procedure;

    -- ---- Procedimiento: pulsar comparar -------------------
    procedure pulsar_comparar (
        signal comparar_dig_s : out std_logic
    ) is
    begin
        comparar_dig_s <= '1';
        wait for 4 * T_CLK;
        comparar_dig_s <= '0';
        wait for 10 * T_CLK;
    end procedure;

    -- ---- Procedimiento: ingresar clave completa -----------
    procedure ingresar_clave (
        signal entrada_s      : out std_logic_vector(3 downto 0);
        signal save_dig_s     : out std_logic;
        signal comparar_dig_s : out std_logic;
        constant d0,d1,d2,d3  : in  std_logic_vector(3 downto 0)
    ) is
    begin
        ingresar_digito(entrada_s, save_dig_s, d0);
        ingresar_digito(entrada_s, save_dig_s, d1);
        ingresar_digito(entrada_s, save_dig_s, d2);
        ingresar_digito(entrada_s, save_dig_s, d3);
        pulsar_comparar(comparar_dig_s);
    end procedure;

begin

    -- ---- Generador de clock -------------------------------
    Clock <= not Clock after T_CLK / 2;

    -- ---- Instancia del sistema ----------------------------
    UUT: sistema_acceso port map (
        Clock         => Clock,
        reset_teclado => reset_teclado,
        reset_tiempo  => reset_tiempo,
        reset_admin   => reset_admin,
        entrada       => entrada,
        save_dig      => save_dig,
        comparar_dig  => comparar_dig,
        cerradura     => cerradura,
        alarma_sonido => alarma_sonido,
        alarma_visual => alarma_visual,
        seg           => seg,
        an            => an
    );

    -- ---- Proceso de estímulos -----------------------------
    ESTIMULOS: process
    begin

        -- Reset inicial del sistema
        reset_admin   <= '1';
        reset_teclado <= '1';
        reset_tiempo  <= '1';
        wait for 10 * T_CLK;
        reset_admin   <= '0';
        reset_teclado <= '0';
        reset_tiempo  <= '0';
        wait for 20 * T_CLK;

        -- ================================================
        -- TEST 1: Clave CORRECTA → "1111" (clave(0) del comparadorfinal)
        -- Esperado: accs_permitido='1', cerradura='1'
        -- ================================================
        report "TEST 1: Ingresando clave correcta 1111...";
        ingresar_clave(entrada, save_dig, comparar_dig,
                       "0001","0001","0001","0001");
        wait for 50 * T_CLK;
        -- Verificar cerradura abierta
        assert cerradura = '1'
            report "ERROR TEST 1: cerradura deberia estar ABIERTA"
            severity error;
        report "TEST 1 OK: cerradura abierta correctamente";

        -- Esperar que cierre (10 segundos simulados = mucho tiempo real)
        -- Para simulación acortamos esperando el reset de teclado
        reset_teclado <= '1';
        wait for 5 * T_CLK;
        reset_teclado <= '0';
        wait for 20 * T_CLK;

        -- ================================================
        -- TEST 2: Clave INCORRECTA #1 → "0000"
        -- Esperado: accs_denegado='1', intento 1/3
        -- ================================================
        report "TEST 2: Ingresando clave incorrecta #1 (0000)...";
        ingresar_clave(entrada, save_dig, comparar_dig,
                       "0000","0000","0000","0000");
        wait for 50 * T_CLK;
        assert cerradura = '0'
            report "ERROR TEST 2: cerradura deberia estar CERRADA"
            severity error;
        report "TEST 2 OK: clave incorrecta rechazada (intento 1/3)";

        -- ================================================
        -- TEST 3: Clave INCORRECTA #2 → "1010"
        -- Esperado: accs_denegado='1', intento 2/3
        -- ================================================
        report "TEST 3: Ingresando clave incorrecta #2 (1010)...";
        ingresar_clave(entrada, save_dig, comparar_dig,
                       "1010","1010","1010","1010");
        wait for 50 * T_CLK;
        assert cerradura = '0'
            report "ERROR TEST 3: cerradura deberia estar CERRADA"
            severity error;
        report "TEST 3 OK: clave incorrecta rechazada (intento 2/3)";

        -- ================================================
        -- TEST 4: Clave INCORRECTA #3 → "1111" fuera de horario
        -- Esperado: bloqueo_activo='1', alarma_sonido='1'
        -- ================================================
        report "TEST 4: Ingresando clave incorrecta #3 → debe activar BLOQUEO y ALARMA...";
        ingresar_clave(entrada, save_dig, comparar_dig,
                       "0011","0011","0011","0011");
        wait for 100 * T_CLK;
        assert alarma_sonido = '1' or alarma_visual = '1'
            report "ERROR TEST 4: alarma deberia estar ACTIVA tras 3 intentos"
            severity error;
        assert cerradura = '0'
            report "ERROR TEST 4: cerradura debe estar BLOQUEADA"
            severity error;
        report "TEST 4 OK: sistema bloqueado y alarma activa";

        -- ================================================
        -- TEST 5: Reset ADMIN → sistema vuelve a IDLE
        -- Esperado: cerradura='0', alarma='0'
        -- ================================================
        report "TEST 5: Aplicando reset_admin para desbloquear sistema...";
        wait for 20 * T_CLK;
        reset_admin <= '1';
        wait for 10 * T_CLK;
        reset_admin <= '0';
        wait for 50 * T_CLK;
        assert cerradura = '0'
            report "ERROR TEST 5: cerradura deberia estar en reposo"
            severity error;
        report "TEST 5 OK: sistema reseteado correctamente";

        -- ================================================
        -- TEST 6: Clave correcta tras reset
        -- ================================================
        report "TEST 6: Clave correcta despues de reset...";
        ingresar_clave(entrada, save_dig, comparar_dig,
                       "0001","0001","0001","0001");
        wait for 50 * T_CLK;
        assert cerradura = '1'
            report "ERROR TEST 6: cerradura deberia abrirse tras reset"
            severity error;
        report "TEST 6 OK: sistema funciona correctamente tras reset";

        report "======= TODOS LOS TESTS COMPLETADOS =======";
        wait; -- fin de la simulación
    end process;

end architecture;
