-------------------------------------------------------------------------------
--
--  This file is part of Radix-10 restoring square root.
--
--  Description:  
--    Radix-10 square root computation for floating point compliant with the IEEE758 standard
--
--  Author(s): 	Martín Vázquez, martin.o.vazquez@gmail.com
--	Date: 01/10/2019	
--	
--	  
--
-------------------------------------------------------------------------------
--
--  Copyright (c) 2019 LabSET
--
--  This source file may be used and distributed without restriction provided
--  that this copyright statement is not removed from the file and that any
--  derivative work contains the original copyright notice and the associated
--  disclaimer.
--
--  This source file is free software: you can redistribute it and/or modify it
--  under the terms of the GNU Lesser General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or (at your
--  option) any later version.
--
--  This source file is distributed in the hope that it will be useful, but
--  WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
--  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
--  for more details.
--
--  You should have received a copy of the GNU Lesser General Public License
--  along with the ImageZero Encoder.  If not, see http://www.gnu.org/licenses
--
------------------------------------------------------------------------------ 


-- Circuito que realiza la raíz cuadrada radix-10 punto flotanet decimal conforme al estándar
--  mediante digit recurrence.


-- Para decimal32, P=7 y Ne=8 y bias=101 
-- Para decimal64, P=16 y Ne=10 y bias=398 
-- Para decimal128, P=34 y Ne=14 y bias=6176 

-- K = parte superior[log2(p+1)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.my_package.all;

library UNISIM;
use UNISIM.VComponents.all;


entity sq_root_r10_float is

	generic (TAdd: integer:=2;P: integer:=7; Ne: integer :=8; K: integer:=3);
--	generic (TAdd: integer:= 2;P: integer:=16; Ne: integer :=10;K: integer:=4);
--	generic (TAdd: integer:= 2;P: integer:=34; Ne: integer :=14; K: integer:=6);


	port ( clk, rst : in std_logic;
           start: in std_logic;
			  
			  -- el signo del argumento es siempre positivo
			  v : in  std_logic_vector (4*P-1 downto 0);
			  q: in std_logic_vector(Ne-1 downto 0);
			  
			  -- el signo del resultado es siempre negativo
			  
			  y_o : out  std_logic_vector (4*P-1 downto 0);
			  exp_o: out std_logic_vector(Ne-1 downto 0);
			  
			  done: out std_logic);
			  
end sq_root_r10_float;

architecture Behavioral of sq_root_r10_float is

	
	component LeadingZeros 
		generic (P: integer:=16);
		Port ( a : in  STD_LOGIC_VECTOR (4*P-1 downto 0);
			 c : out  STD_LOGIC_VECTOR (log2sup(P+1)-1 downto 0));
	end component;
	
	component SubBCD 
		generic (N :integer:= 16);
		 Port ( a : in  STD_LOGIC_VECTOR (4*N-1 downto 0);
				  b : in  STD_LOGIC_VECTOR (4*N-1 downto 0);
				  co: out  STD_LOGIC;
				 r : out  STD_LOGIC_VECTOR (4*N-1 downto 0));
	end component;

	component Mult_Nx1_vaz
		 Generic (TAdd: integer:= 0; NDigit :integer:=7);
		 Port ( d: in  std_logic_vector (NDigit*4-1 downto 0);
				  y : in  std_logic_vector (3 downto 0);
				  p : out std_logic_vector((NDigit+1)*4-1 downto 0)); 
	end component;
	
	component mult_bcd_x2 
	 	 Generic (P:integer:=8);
	     Port ( d : in  STD_LOGIC_VECTOR (4*P-1 downto 0);
           r : out  STD_LOGIC_VECTOR (4*P+3 downto 0));
	end component;

	component adder_BCD_L6 is
		generic (TAdd:integer:= 0; NDigit : integer:=4);
		port (  a, b : in  STD_LOGIC_VECTOR (NDigit*4-1 downto 0);
           cin : in  STD_LOGIC;
           cout : out  STD_LOGIC;
           s : out  STD_LOGIC_VECTOR (NDigit*4-1 downto 0));
	end component;

	component div_custom 
			  Port (a : in  STD_LOGIC_VECTOR (11 downto 0);-- xxxx xxxx xxxx
					 b : in  STD_LOGIC_VECTOR (4 downto 0);-- x xxxx
				  q : out  STD_LOGIC_VECTOR (3 downto 0));
	end component;

	component square_root_2 
		 Port ( a : in  STD_LOGIC_VECTOR (7 downto 0);
				  sr : out  STD_LOGIC_VECTOR (3 downto 0));
	end component;

	
	component UnitCtrl_float 
	generic (P:integer:=7; K:integer:=3);
    Port ( clk, rst, start : in  std_logic;
           step: out std_logic_vector(K-1 downto 0);
			  base_i: out std_logic_vector(P-1 downto 0);-- para generar B**-1, B**-2,,,B**-P
			  ld_ini, ld_exp_cb, rst_acum, ld_acum, rst_w, ld_w, 
			  rst_y, ld_y, rst_out, ld_out, done: out  std_logic);
	end component;


-- =============== Contante que se debe multiplicar a la raíz punto fijo, al considerar el exponente impar del argumento  
-- ===================
	constant cte_prod:std_logic_vector (4*P-1 downto 0) := x"3162278"; -- para P=7; formato Q1.p
--	constant cte_prod:std_logic_vector (4*P-1 downto 0) := x"3162277660168379";-- para P=16; formato Q1.p
--	constant cte_prod:std_logic_vector (4*P-1 downto 0) := x"3162277660168379331998893544432767";-- para P=34; formato Q1.p. NOTA los últimos dos están inventados
-- ===================

	signal next_q, reg_q:  std_logic_vector(Ne-1 downto 0); -- modela exponente del argumento
	signal next_v, reg_v: std_logic_vector(4*P-1 downto 0); -- modela maantisa del argumento, forma Q0.P)
	signal next_w, reg_w: std_logic_vector(4*P+3 downto 0); -- modela el resto parcial, forma Q1.P
	signal next_y, reg_y: std_logic_vector(4*P-1 downto 0);-- modela el resultado parcial, forma Q0.P
	signal next_exp_cb, reg_exp_cb: std_logic_vector(Ne-1 downto 0); -- modela exponente real del argumento normalizado en CB
	
	signal cnt_zeros: std_logic_vector(log2sup(P+1)-1 downto 0); -- la cantidad de 0's iniciales que puede haber en v
	signal v_ld_zeros: std_logic_vector(4*P-1 downto 0); -- corresponde al valor de v sin los 0's iniciales
	signal sh_exp: std_logic_vector(Ne-1 downto 0); -- es el valor que debo sumarle al exponente por normalización	
	signal e_true_cd, e_true_cb, v_exp_sva: std_logic_vector(Ne-1 downto 0); -- para trataiento de exponente

	
	signal wx10: std_logic_vector(4*P+7 downto 0);-- modela resto por 10,  forma Q2.N
	signal yx2: std_logic_vector(4*P+3 downto 0);-- modela y por dos, forma Q1.P
	
	-- señales de control
	signal step: std_logic_vector(K-1 downto 0);
	signal step_one: std_logic_vector(K-1 downto 0);
	
	signal ld_ini: std_logic;
	signal ld_exp_cb: std_logic;
	signal rst_w, ld_w: std_logic;
	signal rst_y, ld_y: std_logic;
	signal rst_acum, ld_acum: std_logic;
	signal rst_out, ld_out: std_logic;
	
	signal y_ini: std_logic_vector(3 downto 0);
	signal special_cond: std_logic;
	
	signal yi, yi_1 : std_logic_vector(3 downto 0);-- correspondiente a yi e yi-1
	
	signal yi_base_i, yi_1_base_i: std_logic_vector(4*P+3 downto 0);-- corresponde a yi.B^-i e yi-1.B^-i 
	
	signal yi_add, yi_1_add: std_logic_vector(4*P+3 downto 0);
	-- corresponde a 2.y(i-1)+yi.B^-i y 2.y(i-1)+yi-1.B^-i 
	-- forma Q1.P
	
	signal yi_prod, yi_1_prod : std_logic_vector(4*P+7 downto 0);
	-- modela (2.y(i-1)+yi.B^-i).yi e (2.y(i-1)+yi-1.B^-i).yi-1 
	-- forma Q2.P

	signal wi, wi_1 : std_logic_vector(4*P+7 downto 0);
	-- modela (r.10 - 2.y(i-1)+yi.B^-i).yi e (r.10 - 2.y(i-1)+yi-1.B^-i).yi-1 
	-- forma Q2.P
	
	signal si : std_logic; -- los signos de la operación (r.10 - 2.y(i-1)+yi.B^-i).yi ...

	signal result_w: std_logic_vector(4*P+7 downto 0);
	-- el resto correcto para el próximo ciclo
	-- forma Q2.P

	signal result_y: std_logic_vector(3 downto 0); -- el valor seleccionado correcto

	signal base_i: std_logic_vector(P-1 downto 0);-- para generar B**-1, B**-2,,,B**-P
	
	signal yi_div: std_logic_vector(3 downto 0); -- yi producido por la división
	signal yi_root: std_logic_vector(3 downto 0); -- yi producido por la tabla de raíz de dos dígitos
	
	signal next_yi, reg_yi:std_logic_vector(3 downto 0); -- modela dígito que se est´a generando yi
	signal prod: std_logic_vector(4*(P+1)-1 downto 0); -- en formato Q2.p-1, es el resultado del producto de 0.yi * cte
	signal sh_prod: std_logic_vector (8*P-1 downto 0); --en formato Q1.2p-1, es el resutlado del producto cte * yi*10**-i
	signal p_acum, next_prod_acum, reg_prod_acum: std_logic_vector (8*P-1 downto 0); -- en formato Q1.2p-1, es el resutlado del producto cte * reg_y

	signal val_round: std_logic_vector(7 downto 0); -- corresponde al valor que se utiliza para realizar el redondeo,
	-- son tres digitos porque considera los dos casos en base a ceros iniciales
	
	signal s_prod_round: std_logic_vector(4*P+3 downto 0); -- son los p+2 dígitos más significativos de la mantisa con el producto de constantes y redondeo
	signal zeros_h: std_logic_vector(4*P-5 downto 0);
	signal oper_add_round: std_logic_vector(4*P+3 downto 0);
	
	signal next_yout, reg_yout: std_logic_vector(4*P-1 downto 0); -- corresponde al almacenamiento de la mantisa de salida
	signal exp_out, oper_exp, exp_div2_cb: std_logic_vector(Ne-1 downto 0);
	signal next_eout, reg_eout: std_logic_vector(Ne-1 downto 0); -- corresponde al almacenamiento del exponente de salida

begin

-- Unidad de Control del circuito
-- =====================
	ectrl: UnitCtrl_float generic map (P => P, K => K)
						Port map (clk => clk, rst => rst, start => start, 
									step => step, base_i => base_i, ld_ini => ld_ini, 
									ld_exp_cb => ld_exp_cb, rst_w => rst_w, ld_w => ld_w,
									rst_acum => rst_acum, ld_acum => ld_acum,
									rst_y => rst_y, ld_y => ld_y, 
									rst_out => rst_out, ld_out => ld_out, done => done);
	

-- =====================


-- =================
-- ===========================  Comienzo de paso inicial

	-- =========
	-- ==== Inicio de Normalización de operando de entrada

	eglz: LeadingZeros generic map (P => P)
			Port map ( a => reg_v, c => cnt_zeros);	
	
	-- Para P=7
	cg_ldzeros7_ini: if P=7 generate
						v_ld_zeros <= reg_v when (cnt_zeros="000") else 
										 (reg_v(4*P-5 downto 0)&x"0") when (cnt_zeros="001") else 
										 (reg_v(4*P-9 downto 0)&x"00") when (cnt_zeros="010") else 
										 (reg_v(4*P-13 downto 0)&x"000") when (cnt_zeros="011") else 
										 (reg_v(4*P-17 downto 0)&x"0000") when (cnt_zeros="100") else 
										 (reg_v(4*P-21 downto 0)&x"00000") when (cnt_zeros="101") else 
										 (reg_v(4*P-25 downto 0)&x"000000") when (cnt_zeros="110") else 
										 (others => '0'); -- nunca debería da 7, por restricción de argumento
										 
					   sh_exp <= "00000111" - ("00000"&cnt_zeros); -- P - #ceros_iniciales										 
	end generate;
	
-- Para P=16
	cg_ldzeros16_ini: if P=16 generate
						v_ld_zeros <= reg_v when (cnt_zeros=x"00000") else 
										 (reg_v(4*P-5 downto 0)&x"0") when (cnt_zeros="00001") else 
										 (reg_v(4*P-9 downto 0)&x"00") when (cnt_zeros="00010") else 
										 (reg_v(4*P-13 downto 0)&x"000") when (cnt_zeros="00011") else 
										 (reg_v(4*P-17 downto 0)&x"0000") when (cnt_zeros="00100") else 
										 (reg_v(4*P-21 downto 0)&x"00000") when (cnt_zeros="00101") else 
										 (reg_v(4*P-25 downto 0)&x"000000") when (cnt_zeros="00110") else 
										 (reg_v(4*P-29 downto 0)&x"0000000") when (cnt_zeros="00111") else 
										 (reg_v(4*P-33 downto 0)&x"00000000") when (cnt_zeros="01000") else 
										 (reg_v(4*P-37 downto 0)&x"000000000") when (cnt_zeros="01001") else 
										 (reg_v(4*P-41 downto 0)&x"0000000000") when (cnt_zeros="01010") else 
										 (reg_v(4*P-45 downto 0)&x"00000000000") when (cnt_zeros="01011") else 
										 (reg_v(4*P-49 downto 0)&x"000000000000") when (cnt_zeros="01100") else 
										 (reg_v(4*P-53 downto 0)&x"0000000000000") when (cnt_zeros="01101") else 
										 (reg_v(4*P-57 downto 0)&x"00000000000000") when (cnt_zeros="01110") else 
										 (reg_v(4*P-61 downto 0)&x"000000000000000") when (cnt_zeros="01111") else 					 
										 (others => '0'); -- nunca debería dar 16 por restricción en argumento
										 
						sh_exp <= "0000010000" - ("00000"&cnt_zeros); -- P - #ceros_iniciales										 										 
	end generate;
	
	-- Para P=34	
	cg_ldzeros34_ini: if P=34 generate
						v_ld_zeros <= reg_v when (cnt_zeros=x"000000") else 
										 (reg_v(4*P-5 downto 0)&x"0") when (cnt_zeros="000001") else 
										 (reg_v(4*P-9 downto 0)&x"00") when (cnt_zeros="000010") else 
										 (reg_v(4*P-13 downto 0)&x"000") when (cnt_zeros="000011") else 
										 (reg_v(4*P-17 downto 0)&x"0000") when (cnt_zeros="000100") else 
										 (reg_v(4*P-21 downto 0)&x"00000") when (cnt_zeros="000101") else 
										 (reg_v(4*P-25 downto 0)&x"000000") when (cnt_zeros="000110") else 
										 (reg_v(4*P-29 downto 0)&x"0000000") when (cnt_zeros="000111") else 
										 (reg_v(4*P-33 downto 0)&x"00000000") when (cnt_zeros="001000") else 
										 (reg_v(4*P-37 downto 0)&x"000000000") when (cnt_zeros="001001") else 
										 (reg_v(4*P-41 downto 0)&x"0000000000") when (cnt_zeros="001010") else 
										 (reg_v(4*P-45 downto 0)&x"00000000000") when (cnt_zeros="001011") else 
										 (reg_v(4*P-49 downto 0)&x"000000000000") when (cnt_zeros="001100") else 
										 (reg_v(4*P-53 downto 0)&x"0000000000000") when (cnt_zeros="001101") else 
										 (reg_v(4*P-57 downto 0)&x"00000000000000") when (cnt_zeros="001110") else 
										 (reg_v(4*P-61 downto 0)&x"000000000000000") when (cnt_zeros="001111") else 					 
										(reg_v(4*P-65 downto 0)&x"0000000000000000") when (cnt_zeros="010000") else 					 
										(reg_v(4*P-69 downto 0)&x"00000000000000000") when (cnt_zeros="010001") else 					 										 
										(reg_v(4*P-73 downto 0)&x"000000000000000000") when (cnt_zeros="010010") else 					 
										(reg_v(4*P-77 downto 0)&x"0000000000000000000") when (cnt_zeros="010011") else 					 										 
										(reg_v(4*P-81 downto 0)&x"00000000000000000000") when (cnt_zeros="010100") else 					 										 
										(reg_v(4*P-85 downto 0)&x"000000000000000000000") when (cnt_zeros="010101") else 					 										 
										(reg_v(4*P-89 downto 0)&x"0000000000000000000000") when (cnt_zeros="010110") else 					 										 
										(reg_v(4*P-93 downto 0)&x"00000000000000000000000") when (cnt_zeros="010111") else 					 										 
										(reg_v(4*P-97 downto 0)&x"000000000000000000000000") when (cnt_zeros="011000") else 					 										 
										(reg_v(4*P-101 downto 0)&x"0000000000000000000000000") when (cnt_zeros="011001") else 					 										 
										(reg_v(4*P-105 downto 0)&x"00000000000000000000000000") when (cnt_zeros="011010") else 					 										 
										(reg_v(4*P-109 downto 0)&x"000000000000000000000000000") when (cnt_zeros="011011") else 					 										 
										(reg_v(4*P-113 downto 0)&x"0000000000000000000000000000") when (cnt_zeros="011100") else 					 										 
										(reg_v(4*P-117 downto 0)&x"00000000000000000000000000000") when (cnt_zeros="011101") else 					 										 
										(reg_v(4*P-121 downto 0)&x"000000000000000000000000000000") when (cnt_zeros="011110") else 					 										 
										(reg_v(4*P-125 downto 0)&x"0000000000000000000000000000000") when (cnt_zeros="011111") else 					 										 
										(reg_v(4*P-129 downto 0)&x"00000000000000000000000000000000") when (cnt_zeros="100000") else 					 										 
										(reg_v(4*P-133 downto 0)&x"000000000000000000000000000000000") when (cnt_zeros="100001") else 					 										 
										 (others => '0'); -- nunca debería dar 34 por restricción en argumento 
							
							sh_exp <= "00000000100010" - ("00000000"&cnt_zeros); -- P - #ceros_iniciales										 										 
	end generate;
	-- ==== Fin normalización del operando de entrada
	-- ========

	-- =========
	-- ==== Inicio de Tratamiento de exponente
	
	cg_doexp_7: if P=7 generate -- puede ser Ne=8
		e_true_cd <= reg_q + sh_exp; -- exponmente de entrada mas ajuste por normalización, en cero desplazado
		e_true_cb <=e_true_cd + x"9b"; -- exponente + CB(bias), exponente + CB(101)
	end generate;
	

	cg_doexp_16: if P=16 generate -- puede ser Ne=10
		e_true_cd <= reg_q + sh_exp; -- exponmente de entrada mas ajuste por normalización, en cero desplazado
		e_true_cb <=e_true_cd + "1001110010";--x"272"; -- exponente + CB(bias), exponente + CB(398)
	end generate;

	cg_doexp_34: if P=34 generate -- puede ser Ne=14
		e_true_cd <= reg_q + sh_exp; -- exponmente de entrada mas ajuste por normalización, en cero desplazado
		e_true_cb <=e_true_cd + "10011111100000"; --x"27e0"; -- exponente + CB(bias), exponente + CB(398)
	end generate;
	-- ==== Fin de tratamiento de exponente
	-- ========
-- ================ Fin de paso inicial


-- ===================
-- =============================== Inicio de estapa correspondiente a cálculo de raiz cuadrada punto fijo 
-- desde ciclo 2 al ciclo P+1, (step desde 0 a P-1)
-- ===================


	emult2 : mult_bcd_x2 generic map (P => P)
							port map ( d => reg_y, r => yx2);
							
	
	
	wx10 <= reg_w&x"0";	

-- ======= Evaluación del caso especial - SC
	step_one <= (0 => '1', others => '0');
	special_cond <= '1' when ((step=step_one) and (reg_w(4*P+3 downto 4*(P-2))=x"054") and 
	
										(
										(reg_w(4*P-9 downto 4*(P-3))=x"0") or (reg_w(4*P-9 downto 4*(P-3))=x"1") or (reg_w(4*P-9 downto 4*(P-3))=x"2") or (reg_w(4*P-9 downto 4*(P-3))=x"3") 
										)) else '0';
	
-- ===============

-- generación de yi
-- ======================
	ediv: div_custom port map (a => wx10(4*(P+2)-1 downto 4*(P-1)), b => yx2(4*P downto 4*(P-1)) , q => yi_div);

	esr2: square_root_2 port map (a  => reg_w(4*P-1 downto 4*(P-2)),  sr => yi_root);
	
	y_ini <= yi_root when (step=0) else yi_div;
	yi <= x"7" when (special_cond='1') else y_ini;
-- ======================

-- generación de yi-1
-- ======================
	yi_1 <= "0001" when yi_div="0010" else
    		  "0010" when yi_div="0011" else
			  "0011" when yi_div="0100" else
			  "0100" when yi_div="0101" else
    		  "0101" when yi_div="0110" else
			  "0110" when yi_div="0111" else
    		  "0111" when yi_div="1000" else
			  "1000" when yi_div="1001" else
			  (others => '0');
	
-- ======================

-- generación de del cuadrado de yi.B^-i, yi-1.B^-i 
-- =========================
	yi_base_i(4*P+3 downto 4*P) <= (others => '0'); 
	yi_1_base_i(4*P+3 downto 4*P) <= (others => '0');


	gbase: for I in 0 to P-1 generate
	
	-- para yi
		yi_base_i(4*(P-I)-1) <= base_i(P-I-1) and yi(3); 
		yi_base_i(4*(P-I)-2) <= base_i(P-I-1) and yi(2);
		yi_base_i(4*(P-I)-3) <= base_i(P-I-1) and yi(1);
		yi_base_i(4*(P-I)-4) <= base_i(P-I-1) and yi(0);
	
	--para yi-1
		yi_1_base_i(4*(P-I)-1) <= base_i(P-I-1) and yi_1(3); 
		yi_1_base_i(4*(P-I)-2) <= base_i(P-I-1) and yi_1(2);
		yi_1_base_i(4*(P-I)-3) <= base_i(P-I-1) and yi_1(1);
		yi_1_base_i(4*(P-I)-4) <= base_i(P-I-1) and yi_1(0);
	

	end generate;
-- ============================

-- generación de 2.y(i-1) + yi.B^-i, 2.y(i-1) + yi-1.B^-i y 2.y(i-1) + yi-2.B^-i
-- ============================

	eAdd_i0: adder_BCD_L6 generic map (TAdd => TAdd, NDigit => P+1)
						port map (a => yx2, b => yi_base_i, cin => '0', 
										cout => open, s => yi_add);

	eAdd_i1: adder_BCD_L6 generic map (TAdd => TAdd, NDigit => P+1)
						port map (a => yx2, b => yi_1_base_i, cin => '0', 
										cout => open, s => yi_1_add);

-- ============================


-- generación de (2.y(i-1)+yi.B^-i).yi, (2.y(i-1)+yi-1.B^-i).yi-1 y (2.y(i-1)+yi-2.B^-i).yi-2
-- ============================
	
	emult_i0: Mult_Nx1_vaz generic map (TAdd => TAdd, NDigit => P+1)
		 port map ( d => yi_add, y => yi,  p => yi_prod); 
	
	emult_i1: Mult_Nx1_vaz generic map (TAdd => TAdd, NDigit => P+1)
		 port map ( d => yi_1_add, y => yi_1,  p => yi_1_prod); 

-- ============================

-- generación (r.10 - 2.y(i-1)+yi.B^-i).yi, (r.10 - 2.y(i-1)+yi-1.B^-i).yi-1 y (r.10 - 2.y(i-1)+yi-2.B^-i).yi-2
-- ============================

	esub_i0: SubBCD generic map (N => P+2)
						port map (a => wx10, b => yi_prod, co => si, r => wi);

	esub_i1: SubBCD generic map (N => P+2)
						port map (a => wx10, b => yi_1_prod, co => open, r => wi_1);

-- ============================

	result_w <= wi when si='0' else
					wi_1; 
					
	result_y <= yi when si='0' else
					yi_1;				

-- ===================
-- ====== Fin de estapa correspondiente a cálculo de raiz cuadrada punto fijo 
-- ===================

	

-- ===================
-- =============================== Inicio Etapa correspondiente al producto de la constante que considera el exponente del argumento
-- desde ciclo 3 al ciclo P+2, (step desde 1 a P)
-- en cada paso de esta etapa se procesa Cte * yi*10**-i = cte  
-- ===================

	-- multiplicación que realiza cte*yi. resultado en formato Q2.p-1
	emult_cte: Mult_Nx1_vaz generic map (TAdd => TAdd, NDigit => P)
		 port map ( y => reg_yi, d => cte_prod,  p => prod); 
	
	
	-- Para P=7
	
	shift_prod_7: if P=7 generate
						sh_prod <= 	 (prod&x"000000") when (step="001") else 
										 (x"0"&prod&x"00000") when (step="010") else 
										 (x"00"&prod&x"0000") when (step="011") else 
										 (x"000"&prod&x"000") when (step="100") else 
										 (x"0000"&prod&x"00") when (step="101") else 
										 (x"00000"&prod&x"0") when (step="110") else 
										 (x"000000"&prod) when (step="111") else 
										 (others => '0'); 

					
	end generate;
	
-- Para P=16
	shift_prod_16: if P=16 generate
						sh_prod <= 	 (prod&x"000000000000000") when (step="00001") else 
										 (x"0"&prod&x"00000000000000") when (step="00010") else 
										 (x"00"&prod&x"0000000000000") when (step="00011") else 
										 (x"000"&prod&x"000000000000") when (step="00100") else 
										 (x"0000"&prod&x"00000000000") when (step="00101") else 
										 (x"00000"&prod&x"0000000000") when (step="00110") else 
										 (x"000000"&prod&x"000000000") when (step="00111") else 
										 (x"0000000"&prod&x"00000000") when (step="01000") else 
										 (x"00000000"&prod&x"0000000") when (step="01001") else 
										 (x"000000000"&prod&x"000000") when (step="01010") else 
										 (x"0000000000"&prod&x"00000") when (step="01011") else 
										 (x"00000000000"&prod&x"0000") when (step="01100") else 
										 (x"000000000000"&prod&x"000") when (step="01101") else 
										 (x"0000000000000"&prod&x"00") when (step="01110") else 
										 (x"00000000000000"&prod&x"0") when (step="01111") else 
										 (x"000000000000000"&prod) when (step="10000") else 
										 (others => '0'); 
	end generate;
	
	-- Para P=34	
	shift_prod_34: if P=34 generate
						sh_prod <= 	 (prod&x"000000000000000000000000000000000") when (step="000001") else 
										 (x"0"&prod&x"00000000000000000000000000000000") when (step="000010") else 
										 (x"00"&prod&x"0000000000000000000000000000000") when (step="000011") else 
										 (x"000"&prod&x"000000000000000000000000000000") when (step="000100") else 
										 (x"0000"&prod&x"00000000000000000000000000000") when (step="000101") else 
										 (x"00000"&prod&x"0000000000000000000000000000") when (step="000110") else 
										 (x"000000"&prod&x"000000000000000000000000000") when (step="000111") else 
										 (x"0000000"&prod&x"00000000000000000000000000") when (step="001000") else 
										 (x"00000000"&prod&x"0000000000000000000000000") when (step="001001") else 
										 (x"000000000"&prod&x"000000000000000000000000") when (step="001010") else 
										 (x"0000000000"&prod&x"00000000000000000000000") when (step="001011") else 
										 (x"00000000000"&prod&x"0000000000000000000000") when (step="001100") else 
										 (x"000000000000"&prod&x"000000000000000000000") when (step="001101") else 
										 (x"0000000000000"&prod&x"00000000000000000000") when (step="001110") else 
										 (x"00000000000000"&prod&x"0000000000000000000") when (step="001111") else 
										 (x"000000000000000"&prod&x"000000000000000000") when (step="010000") else 
										 (x"0000000000000000"&prod&x"00000000000000000") when (step="010001") else 
										 (x"00000000000000000"&prod&x"0000000000000000") when (step="010010") else 
										 (x"000000000000000000"&prod&x"000000000000000") when (step="010011") else 
										 (x"0000000000000000000"&prod&x"00000000000000") when (step="010100") else 
										 (x"00000000000000000000"&prod&x"0000000000000") when (step="010101") else 
										 (x"000000000000000000000"&prod&x"000000000000") when (step="010110") else 
										 (x"0000000000000000000000"&prod&x"00000000000") when (step="010111") else 
										 (x"00000000000000000000000"&prod&x"0000000000") when (step="011000") else 
										 (x"000000000000000000000000"&prod&x"000000000") when (step="011001") else 
										 (x"0000000000000000000000000"&prod&x"00000000") when (step="011010") else 
										 (x"00000000000000000000000000"&prod&x"0000000") when (step="011011") else 
										 (x"000000000000000000000000000"&prod&x"000000") when (step="011100") else 
										 (x"0000000000000000000000000000"&prod&x"00000") when (step="011101") else 
										 (x"00000000000000000000000000000"&prod&x"0000") when (step="011110") else 
										 (x"000000000000000000000000000000"&prod&x"000") when (step="011111") else 
										 (x"0000000000000000000000000000000"&prod&x"00") when (step="010000") else 
										 (x"00000000000000000000000000000000"&prod&x"0") when (step="010001") else 
										 (x"000000000000000000000000000000000"&prod) when (step="010010") else 
										 (others => '0'); 				
	end generate;
	
	
	eAdd_acum: adder_BCD_L6 generic map (TAdd => TAdd, NDigit => 2*P)
						port map (a => reg_prod_acum, b => sh_prod, cin => '0', 
										cout => open, s => p_acum);
	

-- ===================
-- =============================== Fin Etapa correspondiente al producto de la constante que considera el exponente del argumento
-- ===================



-- ===================
-- =============================== Inicio Etapa correspondiente Procesamiento de resultado - redondeo
-- === corresponde al último ciclo -  P+3 
-- ===================



-- === se trabaja con los p+2 digitoa más significativos de <reg_prod_acum>
-- == puede tener forma x,xx..x, si <reg_prod_acum>!=0
-- == puede tener forma 0,x..x, si <reg_prod_acum>=0

	val_round(3 downto 0) <= x"1" when ( (reg_prod_acum(8*P-1 downto 8*P-4)=x"0") and (
						(reg_prod_acum(4*P-5 downto 4*P-8)=x"6") or (reg_prod_acum(4*P-5 downto 4*P-8)=x"7") or
						(reg_prod_acum(4*P-5 downto 4*P-8)=x"8") or (reg_prod_acum(4*P-5 downto 4*P-8)=x"9") or 
						  (
							(reg_prod_acum(4*P-5 downto 4*P-8)=x"5") and 
							 ( 
							   (reg_prod_acum(4*P-1 downto 4*P-4)=x"1") or (reg_prod_acum(4*P-1 downto 4*P-4)=x"3") or 
								(reg_prod_acum(4*P-1 downto 4*P-4)=x"5") or (reg_prod_acum(4*P-1 downto 4*P-4)=x"7") or
								(reg_prod_acum(4*P-1 downto 4*P-4)=x"9") 							
							 )
						  )
						)) else x"0";  
						
	
	val_round(7 downto 4) <= x"1" when ( (reg_prod_acum(8*P-1 downto 8*P-4)/=x"0") and (
						(reg_prod_acum(4*P-1 downto 4*P-4)=x"6") or (reg_prod_acum(4*P-1 downto 4*P-4)=x"7") or
						(reg_prod_acum(4*P-1 downto 4*P-4)=x"8") or (reg_prod_acum(4*P-1 downto 4*P-4)=x"9") or 
						  (
							(reg_prod_acum(4*P-1 downto 4*P-4)=x"5") and 
							 ( 
							   (reg_prod_acum(4*P+3 downto 4*P)=x"1") or (reg_prod_acum(4*P+3 downto 4*P)=x"3") or 
								(reg_prod_acum(4*P+3 downto 4*P)=x"5") or (reg_prod_acum(4*P+3 downto 4*P)=x"7") or
								(reg_prod_acum(4*P+3 downto 4*P)=x"9") 							
							 )
						  )
						)) else x"0";  
	
	zeros_h <= (others => '0');
	oper_add_round <= zeros_h&val_round;
 
	eAdd_round: adder_BCD_L6 generic map (TAdd => TAdd, NDigit => P+1)
						port map (a => reg_prod_acum(8*P-1 downto 4*P-4), b => oper_add_round,
									cin => '0', cout => open, s => s_prod_round);

-- <s_prod_round> puede tener un cero inicial	
-- formato 0.xx..xxx o bien x.xx..xx

	next_yout <= (others => '0') when rst_out='1' else
					reg_yout when ld_out='0' else
					reg_y when (reg_exp_cb(0)='0') else -- significa que el exponente es par, no requiere ajuste de constante
					s_prod_round(4*P+3  downto 4) when (s_prod_round(4*P+3 downto 4*P)/=x"0") else
					s_prod_round(4*P-1  downto 0);

-- Para el caso que <s_prod_round> no posea un cero inicial, se debe sumar uno al exponente para formato 0.x
-- Para el caso de exponente negativo, ya se considera el desplazamiento debido a -13/2=-7. lo considera el exponente 
-- 4 casos
-- 1. exponente es positivo y <s_prod_round> no posee cero inicial, SUMA uno al exponente
-- 2. exponente es positivo y <s_prod_round> posee cero inicial, NO suma/resta
-- 3. exponente es necgativo y <s_prod_round> no posee cero inicial, SUMA uno al exponente
-- 4. eponente negativo y <s_prod_round> posee cero inicial, No suma/resta

-- los casos considerando mantisa entero (resta de P al exponente), y además considerando el bias para que no quede en CB

	exp_div2_cb <= reg_exp_cb(Ne-1)&reg_exp_cb(Ne-1 downto 1); -- el exponente en cb dividido dos

-- -- suma bias, resta p, y +/- 1 (o nada) según el caso
	
	gen_operexp7: if P=7 generate   
		oper_exp <= x"5f" when ((reg_exp_cb(0)='1') and (s_prod_round(4*P+3 downto 4*P)/=x"0")) else  -- bias-p+1 = 95 
						x"5e"; -- bias-p = 94
	end generate;

	gen_operexp16: if P=16 generate   
		oper_exp <= "0101111111" when ((reg_exp_cb(0)='1') and (s_prod_round(4*P+3 downto 4*P)/=x"0")) else  -- bias-p+1 = 383 
						"0101111110"; -- bias-p = 382
	end generate;

	gen_operexp34: if P=34 generate   
		oper_exp <= "01011111111111" when ((reg_exp_cb(0)='1') and (s_prod_round(4*P+3 downto 4*P)/=x"0")) else  -- bias-p+1 = 6143 
						"01011111111110"; -- bias-p = 6142
	end generate;


	exp_out <= exp_div2_cb + oper_exp;
	
	


-- ===================
-- =============================== Fin Etapa correspondiente Procesamiento de resultado - redondeo
-- ===================
	

 -- ======================================
-- Correspondiente a los almacenamientos del circuito


	next_v <= v when ld_ini='1' else reg_v;
	next_q <= q when ld_ini='1' else reg_q;

	next_exp_cb <= e_true_cb when ld_exp_cb='1' else reg_exp_cb; 
	
	next_eout <= (others => '0') when rst_out='1' else
						exp_out when ld_out='1' else
						reg_eout;

	next_w <= (x"0"&v_ld_zeros) when rst_w='1' else
				  result_w(4*P+3 downto 0) when ld_w = '1' else reg_w;
				
	
	enex_y: for J in P downto 1 generate 
	
		next_y(4*J-1 downto 4*(J-1)) <= (others => '0') when rst_y='1' else 
											result_y when (ld_y = '1' and  base_i(J-1)='1')
											else reg_y(4*J-1 downto 4*(J-1));
	
		
	end generate;

	
	next_yi <= (others => '0') when rst_y='1' else
					result_y when ld_y='1' else reg_yi;
	
	
	next_prod_acum <= (others => '0') when rst_acum='1' else
							p_acum when ld_acum='1' else reg_prod_acum;
	
-- ================
-- ======== Almacenamientos del circuito
-- ================
	
	Preg: process (clk, rst)
	begin
		if rst='1' then
			
			reg_v <= (others => '0');
			reg_q <= (others => '0');
			reg_w <= (others => '0');
			reg_y <= (others => '0');
			reg_exp_cb <= (others => '0');
			
			reg_yi <= (others => '0');
			reg_prod_acum <= (others => '0'); 
			
			reg_yout <= (others => '0');
			reg_eout <= (others => '0');
			
		elsif rising_edge(clk) then 
			
			reg_v <= next_v;
			reg_q <= next_q;
			reg_w <= next_w;
			reg_y <= next_y;
			reg_exp_cb <= next_exp_cb;
			
			reg_yi <= next_yi;
			reg_prod_acum <= next_prod_acum;
			
			reg_yout <= next_yout;
			reg_eout <= next_eout;
		end if;
	end process;
-- ======================================



	y_o <= reg_yout;
	exp_o <= reg_eout;

end Behavioral;

