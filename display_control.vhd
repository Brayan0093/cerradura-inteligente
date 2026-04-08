library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- ============================================================
-- display_control
-- Maneja 4 displays de 7 segmentos (cátodo común).
-- Multiplexación + decodificador BCD/ASCII incluidos.
--
-- Modos de display según estado:
--   "00" IDLE     -> muestra "IDLE"  (letras)
--   "01" ABIERTA  -> muestra "OPEn" + cuenta regresiva (segundos)
--   "10" CERRADA  -> muestra dígitos ingresados (enmascarados con "----")
--   "11" BLOQUEADA-> muestra "ALr " + cuenta regresiva alarma
--
-- Segmentos: a b c d e f g  (bit 6 downto 0)
--   display: seg(6)=a, seg(5)=b, ..., seg(0)=g
-- ============================================================
entity display_control is
    port (
        Clock          : in  std_logic;   -- 50 MHz
        reset          : in  std_logic;
        estado         : in  std_logic_vector(1 downto 0);  -- del control_puerta
        cuenta_reg     : in  std_logic_vector(4 downto 0);  -- segundos 0..30
        digito0        : in  std_logic_vector(3 downto 0);  -- del comparadorfinal
        digito1        : in  std_logic_vector(3 downto 0);
        digito2        : in  std_logic_vector(3 downto 0);
        digito3        : in  std_logic_vector(3 downto 0);
        -- Salidas multiplexadas
        seg            : out std_logic_vector(6 downto 0);  -- a..g
        an             : out std_logic_vector(3 downto 0)   -- anodos (activo bajo)
    );
end entity;

architecture arch_display of display_control is

    -- Divisor para refresco ~1 kHz (multiplexacion)
    signal div_mux  : integer range 0 to 24999 := 0;
    signal clk_mux  : std_logic := '0';
    signal dig_sel  : std_logic_vector(1 downto 0) := "00";

    signal dato     : std_logic_vector(3 downto 0);
    signal seg_out  : std_logic_vector(6 downto 0);

    -- Decodificador BCD a 7 segmentos (cátodo común, activo alto)
    --       a b c d e f g
    -- 0  -> 1111110
    -- 1  -> 0110000  etc.
    function bcd_to_seg(d : std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        case d is
            when "0000" => return "1111110"; -- 0
            when "0001" => return "0110000"; -- 1
            when "0010" => return "1101101"; -- 2
            when "0011" => return "1111001"; -- 3
            when "0100" => return "0110011"; -- 4
            when "0101" => return "1011011"; -- 5
            when "0110" => return "1011111"; -- 6
            when "0111" => return "1110000"; -- 7
            when "1000" => return "1111111"; -- 8
            when "1001" => return "1111011"; -- 9
            -- Letras para mensajes
            when "1010" => return "0001000"; -- guion "-"  (dígito enmascarado)
            when "1011" => return "0111101"; -- 'd'
            when "1100" => return "0001111"; -- 'I' -> solo segmentos centrales -> "i"
            when "1101" => return "0111000"; -- 'L'
            when "1110" => return "1001111"; -- 'E'
            when "1111" => return "0000000"; -- apagado
            when others => return "0000000";
        end case;
    end function;

    -- Letras codificadas como constantes para mensajes fijos
    --           a b c d e f g
    constant L_I  : std_logic_vector(6 downto 0) := "0110000"; -- 'I'
    constant L_D  : std_logic_vector(6 downto 0) := "1111101"; -- 'd'
    constant L_L  : std_logic_vector(6 downto 0) := "0001110"; -- 'L'
    constant L_E  : std_logic_vector(6 downto 0) := "1001110"; -- 'E'
    constant L_O  : std_logic_vector(6 downto 0) := "1111110"; -- 'O'
    constant L_P  : std_logic_vector(6 downto 0) := "1110011"; -- 'P'
    constant L_N  : std_logic_vector(6 downto 0) := "0010101"; -- 'n'
    constant L_A  : std_logic_vector(6 downto 0) := "1110111"; -- 'A'
    constant L_R  : std_logic_vector(6 downto 0) := "0000101"; -- 'r'
    constant L_GN : std_logic_vector(6 downto 0) := "0001000"; -- '-' (guion)
    constant L_OFF: std_logic_vector(6 downto 0) := "0000000"; -- apagado

    -- Cuenta regresiva convertida a decenas y unidades
    signal dec_cnt  : integer range 0 to 9 := 0;
    signal uni_cnt  : integer range 0 to 9 := 0;
    signal cnt_val  : integer range 0 to 30 := 0;

begin

    -- ---- Divisor para multiplexación ----------------------
    process (Clock, reset)
    begin
        if (reset = '1') then
            div_mux <= 0;
            clk_mux <= '0';
        elsif (Clock'event and Clock = '1') then
            if (div_mux = 24999) then
                div_mux <= 0;
                clk_mux <= not clk_mux;
            else
                div_mux <= div_mux + 1;
            end if;
        end if;
    end process;

    -- ---- Selector de dígito activo ------------------------
    process (clk_mux, reset)
    begin
        if (reset = '1') then
            dig_sel <= "00";
        elsif (clk_mux'event and clk_mux = '1') then
            dig_sel <= std_logic_vector(unsigned(dig_sel) + 1);
        end if;
    end process;

    -- ---- Conversión cuenta regresiva a dec/uni -----------
    cnt_val <= to_integer(unsigned(cuenta_reg));
    dec_cnt <= cnt_val / 10;
    uni_cnt <= cnt_val mod 10;

    -- ---- Lógica de salida del display ---------------------
    process (dig_sel, estado, digito0, digito1, digito2, digito3, dec_cnt, uni_cnt)
    begin
        -- Valor por defecto para an
        if    (dig_sel = "00") then an <= "1110";
        elsif (dig_sel = "01") then an <= "1101";
        elsif (dig_sel = "10") then an <= "1011";
        else                        an <= "0111";
        end if;

        case estado is

            -- IDLE: muestra "IdLE"
            when "00" =>
                if    (dig_sel = "00") then seg <= L_I;
                elsif (dig_sel = "01") then seg <= L_D;
                elsif (dig_sel = "10") then seg <= L_L;
                else                        seg <= L_E;
                end if;

            -- ABIERTA: muestra "OP" + cuenta regresiva en segundos
            when "01" =>
                if    (dig_sel = "00") then seg <= L_O;
                elsif (dig_sel = "01") then seg <= L_P;
                elsif (dig_sel = "10") then seg <= bcd_to_seg(std_logic_vector(to_unsigned(dec_cnt, 4)));
                else                        seg <= bcd_to_seg(std_logic_vector(to_unsigned(uni_cnt, 4)));
                end if;

            -- CERRADA: muestra dígitos enmascarados "----"
            when "10" =>
                seg <= L_GN;

            -- BLOQUEADA / ALARMA: muestra "Ar" + cuenta regresiva
            when others =>
                if    (dig_sel = "00") then seg <= L_A;
                elsif (dig_sel = "01") then seg <= L_R;
                elsif (dig_sel = "10") then seg <= bcd_to_seg(std_logic_vector(to_unsigned(dec_cnt, 4)));
                else                        seg <= bcd_to_seg(std_logic_vector(to_unsigned(uni_cnt, 4)));
                end if;

        end case;
    end process;

end architecture;
