-------------------------------------------------------------------------------
--
--  This file is part of Radix-10 restoring square root.
--
--  Description:  
--   N-digit in BCD-8421 representations multiplier
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


-- Realiza el producto entre un operando multiplicando de N dígitos BCD-8421 (d) y
--  según paper de Vazquez&Dinexhin


 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity Mult_Nx1_vaz is
    Generic (TAdd: integer:= 2; NDigit :integer:=34);
    Port ( d: in  std_logic_vector (NDigit*4-1 downto 0);
	        y : in  std_logic_vector (3 downto 0);
			  p : out std_logic_vector((NDigit+1)*4-1 downto 0)); 
end Mult_Nx1_vaz;


architecture Behavioral of Mult_Nx1_vaz is

	component adder_BCD_L6 is
		generic (TAdd:integer:= 0; NDigit : integer:=4);
		port (  a, b : in  STD_LOGIC_VECTOR (NDigit*4-1 downto 0);
           cin : in  STD_LOGIC;
           cout : out  STD_LOGIC;
           s : out  STD_LOGIC_VECTOR (NDigit*4-1 downto 0));
	end component;
	
	component SignedRx5Recoder 
    Port ( d : in  std_logic_vector (3 downto 0);
			  yu : out std_logic_vector (1 downto 0);
			  yl : out std_logic_vector (2 downto 0));
	end component;
	
	component mult_bcd_x2 
	   generic (P:integer:=8);
	   port ( d : in  STD_LOGIC_VECTOR (4*P-1 downto 0);
           r : out  STD_LOGIC_VECTOR (4*P+3 downto 0));
	end component;
	
	signal yu :  std_logic_vector (1 downto 0); -- 00 es 0, 01 es 1 y 10 es 2
	signal yl :  std_logic_vector (2 downto 0); -- 000 es 0, 001 es 1, 010 es 2, 101 es -1, 100 es -2
	signal d2:  std_logic_vector ((NDigit+1)*4-1 downto 0);
	
	signal ru,rl:  std_logic_vector((NDigit+1)*4-1 downto 0); 

	-- corresponde a la parte alta y parte baja del producto parcial generado en BCD_8421
	signal gppu, gppl: std_logic_vector((NDigit+1)*4-1 downto 0);

	-- funciones de propagación de acarreo en los productos parciales
	signal pu, pl: std_logic_vector((NDigit+1)*4-1 downto 0);

	-- funciones de generación de acarreo en los productos parciales
	signal gu, gl: std_logic_vector((NDigit+1)*4-1 downto 0);

	-- funciones de acarreo en los productos parciales
	signal cu, cl: std_logic_vector((NDigit+1)*4 downto 0);

	-- señales auxiliares
	-- para manejo de desplazamientos en 5d y 10d
	signal dd: std_logic_vector((NDigit+1)*4 downto 0);
	-- para extensión en uso de d
	signal ed: std_logic_vector((NDigit+1)*4 downto 0);

begin


	ERec: SignedRx5Recoder port map ( d => y, yu => yu, yl => yl);
	
	
	Gen2x:  mult_bcd_x2 generic map (P => NDigit)
								port map ( d => d, r => d2); 
								

	GAdd: adder_BCD_L6 generic map (TAdd => TAdd, NDigit => NDigit+1)
						port map (  a => ru, b => rl, cin => yl(2), cout => open, s => p);
									  

	dd((NDigit+1)*4-1 downto 0) <= d&x"0"; -- usado para los desplazamientos 5d y 10d
   dd((NDigit+1)*4) <= '0';
	
 
-- ==================================	
-- ==================================
	-- Para cada digito genera 5d, 10d o 0d, parte alta del producto parcial
	Gen_u: for i in 0 to NDigit generate
	
		cu(4*i) <= '0';
	
	--intancia 0 de digito i
			G_PPU_0 : LUT6_2
				generic map (
					INIT => X"0000c00000aa3c00") 
				port map (
					O6 => gu(4*i),  
					O5 => pu(4*i),  
					I0 => dd(4*i),   
					I1 => dd(4*i+1),   
					I2 => dd(4*(i+1)),   
					I3 => yu(0),
					I4 => yu(1),   
					I5 => '1');
					
			Mxcy_pp_0: MUXCY port map (
							DI => gu(4*i),
							CI => cu(4*i),
							S => pu(4*i),
							O => cu(4*i+1));	

			XORCY_pp_0 : XORCY
			   port map (
			      O => ru(4*i), 
			      CI => cu(4*i), 
			      LI => pu(4*i));					

	 
	--intancia 1 de digito i
			-- gu(4*i+1) <= '0'
			G_PPU_1 : LUT6
				generic map (
					INIT => X"0000000000000ac0") 
				port map (
					O => pu(4*i+1),  
					I0 => dd(4*i+1),   
					I1 => dd(4*i+2),   
					I2 => yu(0),
					I3 => yu(1),   
					I4 => '0',   
					I5 => '0');
	
			Mxcy_pp_1: MUXCY port map (
							DI => '0',
							CI => cu(4*i+1),
							S => pu(4*i+1),
							O => cu(4*i+2));	

			XORCY_pp_1 : XORCY
			   port map (
			      O => ru(4*i+1), 
			      CI => cu(4*i+1), 
			      LI => pu(4*i+1));					

		
	--intancia 2 de digito i
			G_PPU_2 : LUT6_2
				generic map (
					INIT => X"0000c00000aa3c00") 
				port map (
					O6 => gu(4*i+2),  
					O5 => pu(4*i+2),  
					I0 => dd(4*i+2),   
					I1 => dd(4*i+3),   
					I2 => dd(4*(i+1)),   
					I3 => yu(0),
					I4 => yu(1),   
					I5 => '1');
	
			Mxcy_pp_2: MUXCY port map (
							DI => gu(4*i+2),
							CI => cu(4*i+2),
							S => pu(4*i+2),
							O => cu(4*i+3));	

			XORCY_pp_2 : XORCY
			   port map (
			      O => ru(4*i+2), 
			      CI => cu(4*i+2), 
			      LI => pu(4*i+2));					

	
	--intancia 3 de digito i
			-- gu(4*i+3) <= '0'
			G_PPU_3 : LUT6
				generic map (
					INIT => X"0000000000000020") 
				port map (
					O => pu(4*i+3),  
					I0 => dd(4*i+3),   
					I1 => yu(0),
					I2 => yu(1), 
					I3 => '0',   					
					I4 => '0',   
					I5 => '0');
	

			XORCY_pp_3 : XORCY
			   port map (
			      O => ru(4*i+3), 
			      CI => cu(4*i+3), 
			      LI => pu(4*i+3));					

	
	end generate;
-- ==================================
-- ==================================

	ed((NDigit+1)*4-1 downto 0) <= x"0"&d; -- extensión de d
	cl(0) <= '0';	 
	
-- ==================================
-- ==================================	 
	-- Para cada digito genera -2d, -d, 0, d, 2d, parte baja del producto parcial
	
	-- 000 es 0, 001 es 1, 010 es 2, 101 es -1, 100 es -2
   Gen_l: for i in 0 to NDigit generate
 
	 cl(4*i) <= '0';

	--intancia 0 de digito i
			G_PPL_0 : LUT6
				generic map (
					INIT => X"0000000003500ca0") 
				port map (
					O => pl(4*i),  
					I0 => ed(4*i),   
					I1 => d2(4*i),   
					I2 => yl(0),   
					I3 => yl(1),
					I4 => yl(2),   
					I5 => '0');

			Mxcy_ppl_0: MUXCY port map (
							DI => '0',
							CI => cl(4*i),
							S => pl(4*i),
							O => cl(4*i+1));	

			XORCY_ppl_0 : XORCY
			   port map (
			      O => rl(4*i), 
			      CI => cl(4*i), 
			      LI => pl(4*i));					

	--intancia 1 de digito i
			G_PPL_1 : LUT6_2
				generic map (
					INIT => X"035000000ca00ca0") 				
				
				port map (
					O6 => gl(4*i+1),  
					O5 => pl(4*i+1),  
					I0 => ed(4*i+1),   
					I1 => d2(4*i+1),   
					I2 => yl(0),
					I3 => yl(1),
					I4 => yl(2),   
					I5 => '1');
					
			Mxcy_ppl_1: MUXCY port map (
							DI => gl(4*i+1),
							CI => cl(4*i+1),
							S => pl(4*i+1),
							O => cl(4*i+2));	

			XORCY_ppl_1 : XORCY
			   port map (
			      O => rl(4*i+1), 
			      CI => cl(4*i+1), 
			      LI => pl(4*i+1));		

	--intancia 2 de digito i
			G_PPL_2 : LUT6
				generic map (
					INIT => X"0000000003500ca0") 
				port map (
					O => pl(4*i+2),  
					I0 => ed(4*i+2),   
					I1 => d2(4*i+2),   
					I2 => yl(0),   
					I3 => yl(1),
					I4 => yl(2),   
					I5 => '0');
					
					
			Mxcy_ppl_2: MUXCY port map (
							DI => '0',
							CI => cl(4*i+2),
							S => pl(4*i+2),
							O => cl(4*i+3));	

			XORCY_ppl_2 : XORCY
			   port map (
			      O => rl(4*i+2), 
			      CI => cl(4*i+2), 
			      LI => pl(4*i+2));					

	--intancia 3 de digito i	
				G_PPL_3 : LUT6_2
				generic map (
					INIT => X"035000000ca00ca0") 				
				port map (
					O6 => gl(4*i+3),  
					O5 => pl(4*i+3),  
					I0 => ed(4*i+3),   
					I1 => d2(4*i+3),   
					I2 => yl(0),
					I3 => yl(1),
					I4 => yl(2),   
					I5 => '1');
				
				
			XORCY_ppl_3 : XORCY
			   port map (
			      O => rl(4*i+3), 
			      CI => cl(4*i+3), 
			      LI => pl(4*i+3));	
	
	 end generate;
	 
	 
	 
	 
	 
	 
	 



end Behavioral;

