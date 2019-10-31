-------------------------------------------------------------------------------
--
--  This file is part of Radix-10 restoring square root.
--
--  Description:  
--    Radix-10 square root computation based on digit recurrence
-- 			the imput number has a N-digit accuracy, and result P-digit accuracy
-- 			the input normalized in  0.1xxxx
-- 			the output  0.3xxx
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




-- este módulo posee como optimización la determinación del dígito
-- solo requiere explorar un número en el caso de restauración


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- P=7, K=3
-- P=16, K=4
-- P=34, K=6

--library UNISIM;
--use UNISIM.VComponents.all;

entity sq_root_r10_opt is
--	generic (N: integer:= 7; P:integer:=7; K: integer:= 3); -- Por ahora N=P, y K = parte superior[log2(p)]
--	generic (N: integer:= 8; P:integer:=8; K: integer:= 3); -- Por ahora N=P, y K = parte superior[log2(p)]
--	generic (N: integer:= 16; P:integer:=16; K: integer:= 4); -- Por ahora N=P, y K = parte superior[log2(p)]
--	generic (N: integer:= 32; P:integer:=32; K: integer:= 5); -- Por ahora N=P, y K = parte superior[log2(p)]
	generic (N: integer:= 34; P:integer:=34; K: integer:= 6); -- Por ahora N=P, y K = parte superior[log2(p)]

   port ( clk, rst : in std_logic;
           start: in std_logic;
			  v : in  std_logic_vector (4*N-1 downto 0);
			  sr : out  std_logic_vector (4*P-1 downto 0);
			  done: out std_logic);
end sq_root_r10_opt;

architecture Behavioral of sq_root_r10_opt is

	
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

	
	component UnitCtrl 
	generic (P:integer:=7; K:integer:=3);
    Port ( clk, rst, start : in  std_logic;
           step: out std_logic_vector(K-1 downto 0);
			  base_i: out std_logic_vector(P-1 downto 0);-- para generar B**-1, B**-2,,,B**-P
			  rst_r, ld_r, rst_y, ld_y, done: out  std_logic);
	end component;

	signal next_r, r: std_logic_vector(4*N+3 downto 0); -- modela el resto parcial, forma Q1.P
	signal next_y, y: std_logic_vector(4*P-1 downto 0);-- modela el resultado parcial, forma Q0.P

	signal rx10: std_logic_vector(4*N+7 downto 0);-- modela resto por 10,  forma Q2.N
	signal yx2: std_logic_vector(4*P+3 downto 0);-- modela y por dos, forma Q1.P
	
	-- señales de control
	signal step: std_logic_vector(K-1 downto 0);
	signal step_one:std_logic_vector(K-1 downto 0);
	
	signal rst_r, ld_r: std_logic;
	signal rst_y, ld_y: std_logic;
	
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

	signal ri, ri_1 : std_logic_vector(4*N+7 downto 0);
	-- modela (r.10 - 2.y(i-1)+yi.B^-i).yi e (r.10 - 2.y(i-1)+yi-1.B^-i).yi-1 
	-- forma Q2.P
	
	signal si : std_logic; -- los signos de la operación (r.10 - 2.y(i-1)+yi.B^-i).yi ...

	signal result_r: std_logic_vector(4*N+7 downto 0);
	-- el resto correcto para el próximo ciclo
	-- forma Q2.P

	signal result_y: std_logic_vector(3 downto 0); -- el valor seleccionado correcto

	signal base_i: std_logic_vector(P-1 downto 0);-- para generar B**-1, B**-2,,,B**-P
	
	signal yi_div: std_logic_vector(3 downto 0); -- yi producido por la división
	signal yi_root: std_logic_vector(3 downto 0); -- yi producido por la tabla de raíz de dos dígitos

begin

-- Unidad de Control del circuito
-- =====================
	ectrl: UnitCtrl generic map (P => P, K => K)
						Port map (clk => clk, rst => rst, start => start, 
									step => step, base_i => base_i, rst_r => rst_r, ld_r => ld_r, 
									rst_y => rst_y, ld_y => ld_y, done => done);
	

-- =====================


	emult2 : mult_bcd_x2 generic map (P => P)
							port map ( d => y, r => yx2);
							
	
	
	rx10 <= r&x"0";	

-- ======= Evaluación del caso especial - SC
	step_one <= (0 => '1', others => '0');
	special_cond <= '1' when ((step=step_one) and (r(4*N+3 downto 4*(N-2))=x"054") and 
	
										(
										(r(4*N-9 downto 4*(N-3))=x"0") or (r(4*N-9 downto 4*(N-3))=x"1") or (r(4*N-9 downto 4*(N-3))=x"2") or (r(4*N-9 downto 4*(N-3))=x"3") 
										)) else '0';
	
-- ===============

-- generación de yi
-- ======================
	ediv: div_custom port map (a => rx10(4*(N+2)-1 downto 4*(N-1)), b => yx2(4*P downto 4*(P-1)) , q => yi_div);

	esr2: square_root_2 port map (a  => r(4*N-1 downto 4*(N-2)),  sr => yi_root);
	
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

	eAdd_i0: adder_BCD_L6 generic map (TAdd => 2, NDigit => P+1)
						port map (a => yx2, b => yi_base_i, cin => '0', 
										cout => open, s => yi_add);

	eAdd_i1: adder_BCD_L6 generic map (TAdd => 2, NDigit => P+1)
						port map (a => yx2, b => yi_1_base_i, cin => '0', 
										cout => open, s => yi_1_add);

-- ============================


-- generación de (2.y(i-1)+yi.B^-i).yi, (2.y(i-1)+yi-1.B^-i).yi-1 y (2.y(i-1)+yi-2.B^-i).yi-2
-- ============================
	
	emult_i0: Mult_Nx1_vaz generic map (TAdd => 2, NDigit => P+1)
		 port map ( d => yi_add, y => yi,  p => yi_prod); 
	
	emult_i1: Mult_Nx1_vaz generic map (TAdd => 2, NDigit => P+1)
		 port map ( d => yi_1_add, y => yi_1,  p => yi_1_prod); 

-- ============================

-- generación (r.10 - 2.y(i-1)+yi.B^-i).yi, (r.10 - 2.y(i-1)+yi-1.B^-i).yi-1 y (r.10 - 2.y(i-1)+yi-2.B^-i).yi-2
-- ============================

	esub_i0: SubBCD generic map (N => N+2)
						port map (a => rx10, b => yi_prod, co => si, r => ri);

	esub_i1: SubBCD generic map (N => N+2)
						port map (a => rx10, b => yi_1_prod, co => open, r => ri_1);

-- ============================

	result_r <= ri when si='0' else
					ri_1; 
					
	result_y <= yi when si='0' else
					yi_1;				

-- ======================================
-- Correspondiente a los almacenamientos del circuito

--luego veo acá
	next_r <= (x"0"&v) when rst_r='1' else
				  result_r(4*N+3 downto 0) when ld_r = '1' else r;
				
	
	enex_y: for J in P downto 1 generate 
	
		next_y(4*J-1 downto 4*(J-1)) <= (others => '0') when rst_y='1' else 
											result_y when (ld_y = '1' and  base_i(J-1)='1')
											else y(4*J-1 downto 4*(J-1));
	
		
	end generate;
	

	Preg: process (clk, rst)
	begin
		if rst='1' then
			r <= (others => '0');
			y <= (others => '0');
		elsif rising_edge(clk) then 
			r <= next_r;
			y <= next_y;
		end if;
	end process;
-- ======================================

	sr <= y;




end Behavioral;

