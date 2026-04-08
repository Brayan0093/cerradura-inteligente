library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity comparadorfinal is
    port (
        entrada              : in  std_logic_vector(3 downto 0);
        Clock                : in  std_logic;
        reset_tiempo         : in  std_logic;
        reset_teclado        : in  std_logic;
        save_dig             : in  std_logic;
        comparar_dig         : in  std_logic;
        digito0, digito1     : buffer std_logic_vector(3 downto 0);
        digito2, digito3     : buffer std_logic_vector(3 downto 0);
        accs_permitido,accs_denegado : out std_logic
    );
end comparadorfinal;

architecture arch_comparadorfinal of comparadorfinal is

    type claves_array is array (0 to 3) of std_logic_vector(15 downto 0);
    type horas_array  is array (0 to 3) of std_logic_vector(7 downto 0);

    constant claves : claves_array := (
        "0001000100010001",
        "1001100110011001",
        "0111011101110111",
        "0101010101010101"
    );
    constant hora_ini : horas_array := ("00000000","00111100","01111000","00000000");
    constant hora_fin : horas_array := ("00111100","01111000","10110100","10110100");

    component comparador4dig
        port (
            comparar             : in  std_logic;
            dig0,dig1,dig2,dig3  : in  std_logic_vector(3 downto 0);
            clv0,clv1,clv2,clv3  : in  std_logic_vector(3 downto 0);
            igual                : out std_logic
        );
    end component;

    component comparadortiempo
        port (
            comparar                 : in  std_logic;
            hora,horaincio,horafinal : in  std_logic_vector(7 downto 0);
            igu                      : out std_logic
        );
    end component;

    component divisorfrecuencia
        port (
            clk        : in     std_logic;
            out1, out2 : buffer std_logic
        );
    end component;

    component reloghorario
        port (
            Clock, Reset : in  std_logic;
            CNT          : out std_logic_vector(7 downto 0)
        );
    end component;

    component registro4dig
        port (
            Clock, Reset : in  std_logic;
            Din          : in  std_logic_vector(3 downto 0);
            Dout0, Dout1 : out std_logic_vector(3 downto 0);
            Dout2, Dout3 : out std_logic_vector(3 downto 0)
        );
    end component;

    signal relogdivido      : std_logic;
    signal contador_relog   : std_logic_vector(7 downto 0) := "00000000";
    signal igual_clave      : std_logic_vector(3 downto 0);
    signal igual_tiempo     : std_logic_vector(3 downto 0);
    signal resultado        : std_logic_vector(3 downto 0);
    signal reset_int        : std_logic;
	 signal reset_comp: std_logic:= '0' ;

begin

   
    reset_int <= reset_teclado or reset_comp;

    H: divisorfrecuencia port map (Clock, relogdivido, open);
    S: reloghorario      port map (relogdivido, reset_tiempo, contador_relog);
    L: registro4dig      port map (save_dig, reset_int, entrada,digito0, digito1, digito2, digito3);

    GEN: for i in 0 to 3 generate

        C: comparador4dig port map (
            comparar => comparar_dig,
            dig0     => digito0,
            dig1     => digito1,
            dig2     => digito2,
            dig3     => digito3,
            clv0     => claves(i)(15 downto 12),
            clv1     => claves(i)(11 downto 8),
            clv2     => claves(i)(7  downto 4),
            clv3     => claves(i)(3  downto 0),
            igual    => igual_clave(i)
        );

        T: comparadortiempo port map (
            comparar  => comparar_dig,
            hora      => contador_relog,
            horaincio => hora_ini(i),
            horafinal => hora_fin(i),
            igu       => igual_tiempo(i)
        );

        resultado(i) <= igual_clave(i) and igual_tiempo(i);

    end generate;

    
    process (Clock)
   begin
    if (Clock'event and Clock = '1') then
        accs_permitido <= '0';
        accs_denegado  <= '0';
        reset_comp     <= '0';

        if (comparar_dig = '1') then
            reset_comp <= '1';  
            if ((resultado(0) or resultado(1) or resultado(2) or resultado(3)) = '1') then
                accs_permitido <= '1';
            else
                accs_denegado  <= '1';
            end if;
        end if;
    end if;
end process;

end arch_comparadorfinal;
