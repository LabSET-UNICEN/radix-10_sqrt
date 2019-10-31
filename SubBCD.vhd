-------------------------------------------------------------------------------
--
--  This file is part of Radix-10 restoring square root.
--
--  Description:  
--   BCD subtractor
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



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity SubBCD is
	generic (N :integer:= 16);
    Port ( a : in  STD_LOGIC_VECTOR (4*N-1 downto 0);
           b : in  STD_LOGIC_VECTOR (4*N-1 downto 0);
           co: out  STD_LOGIC;
	       r : out  STD_LOGIC_VECTOR (4*N-1 downto 0));
end SubBCD;

architecture Behavioral of SubBCD is

signal p, ab: std_logic_vector(4*N-1 downto 0);
signal ci: std_logic_vector(4*N downto 0);

begin

	ci(0) <= '0';
	
	genSub: for I in 0 to N-1 generate
		
		ab(4*(I+1)-1 downto 4*I) <= not (a(4*(I+1)-1 downto 4*I)xor b(4*(I+1)-1 downto 4*I));
	
-- propaga petición si las dos entradas son iguales not (a xor b)
-- el el caso que a=0 y b=1, genera petición. Si a=1 y b=0 mata la petición
	  		
		Xor_1: XORCY port map (O => p(4*I), CI => ci(4*I), LI => ab(4*I));
		Mxcy_1: MUXCY port map (DI => b(4*i),CI => ci(4*i),S => ab(4*i),O => ci(4*i+1));	

		Xor_2: XORCY port map (O => p(4*I+1), CI => ci(4*I+1), LI => ab(4*I+1));
		Mxcy_2: MUXCY port map (DI => b(4*i+1),CI => ci(4*i+1),S => ab(4*i+1),O => ci(4*i+2));	
		
		Xor_3: XORCY port map (O => p(4*I+2), CI => ci(4*I+2), LI => ab(4*I+2));
		Mxcy_3: MUXCY port map (DI => b(4*i+2),CI => ci(4*i+2),S => ab(4*i+2),O => ci(4*i+3));	

		Xor_4: XORCY port map (O => p(4*I+3), CI => ci(4*I+3), LI => ab(4*I+3));
		Mxcy_4: MUXCY port map (DI => b(4*i+3),CI => ci(4*i+3),S => ab(4*i+3),O => ci(4*(i+1)));	

-- p = a-b complementado
-- en la operación pide al dígito anterior c(4*(I+1))='1', entonces debe corrgir el dígito restando 6, ya que pide 16 y debe pedir 10
-- si c(4*(I+1)) = '1', entoces el resultado (a corregir restando 6) correspondiente a ese dígito está en [7, F]

-- Para el caso que haya petición, como  el resultado <p>  se encuentra complementado a uno entonces el rango está en [0..8]. Para 7 es 8, para 9 es 6... para F es 0
-- Significa que cuando hay petición c(4*(I+1))='1', para resultado igual a 
-- 7, en realidad es 8, debe dar 1=7-6, o bien complemento a 9 de 8, c9(8)
-- 8, en realidad es 7, debe dar 2=8-6, o bien complemento a 9 de 7, c9(7)
-- 9, en realidad es 6, debe dar 3=9-6, o bien c9(6)
-- A, en realidad es 5, debe dar 4=10-6, o bien c9(5)
-- B, en realidad es 4, debe dar 5=11-6, o bien c9(4)
-- C, en realidad es 3, debe dar 6=12-6, o bien c9(3)
-- D, en realidad es 2, debe dar 7=13-6, o bien c9(2)
-- E, en realidad es 1, debe dar 8=14-6, o bien c9(1)
-- F, en realidad es 0, debe dar 9=15-6, o bien c9(0)
-- es decir c9(not p)

	--c_nueve(4*I) <=	not p(4*I); 
--	  c_nueve(4*I+1) <= p(4*I+1); 
--	  c_nueve(4*I+2) <=	p(4*I+2) xor p(4*I+1); 
--	  c_nueve(4*I+3) <=	not (p(4*I+3) or p(4*I+2) or p(4*I+1)); -- a'.b'.c' 
--	  r(4*(I+1)-1 downto 4*I) <= c_nueve(4*(I+1)-1 downto 4*I) when (ci(4*(I+1))='1') else (not p(4*(I+1)-1 downto 4*I));

-- r(4*I+v) es c_nueve(p(4*I+v)) sii ci(4*(I+1))==1, sino r(4*I+v) es not p(4*I+v)
-- con v en 0..3


--	  r(4*I) <=	not p(4*I); 
--	  r(4*I+1) <= not (p(4*I+1) xor ci(4*(I+1)));

     r01_LUT6 : LUT6_2
				generic map (
					INIT => X"000000c300000055") 
				port map (
					O6 => r(4*i+1),  
					O5 => r(4*i),  
					I0 => p(4*i),   
					I1 => p(4*i+1),   
					I2 => ci(4*(i+1)),   
					I3 => '0',   
					I4 => '0',   
					I5 => '1'    
				);
	  	    
--	  r(4*I+2) <=	(p(4*I+2) xor p(4*I+1)) when (ci(4*(I+1))='1') else (not p(4*I+2)); 
--	  r(4*I+3) <=	(not (p(4*I+3) or p(4*I+2) or p(4*I+1))) when (ci(4*(I+1))='1') else (not p(4*I+3));
--	  	  
	       r23_LUT6 : LUT6_2
				generic map (
					INIT => X"0000010800000630") 
				port map (
					O6 => r(4*i+3),  
					O5 => r(4*i+2),
					I0 => p(4*i+1),   
					I1 => p(4*i+2),   
					I2 => p(4*i+3),   
					I3 => ci(4*(i+1)),   
					I4 => '0',   
					I5 => '1');    
	  
	end generate;




	co <= ci(4*N);
	
end Behavioral;

