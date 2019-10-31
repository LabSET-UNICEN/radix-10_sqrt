-------------------------------------------------------------------------------
--
--  This file is part of Radix-10 restoring square root.
--
--  Description:  
--    BCD comparator
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


-- Compara dos números BCD (a y b) y devuelve uno si a<b
-- basado en restador binario, usado para el restador BCD


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity CmpBCD is
	generic (N :integer:= 7);
    Port ( a : in  STD_LOGIC_VECTOR (4*N-1 downto 0);
           b : in  STD_LOGIC_VECTOR (4*N-1 downto 0);
          a_less_b: out std_logic);
end CmpBCD;

architecture Behavioral of CmpBCD is

signal p: std_logic_vector(4*N-1 downto 0);
signal ab, a1b, c_nueve: std_logic_vector(4*N-1 downto 0);
signal ci: std_logic_vector(4*N downto 0);

begin

	ci(0) <= '0'; 
	
	genSub: for I in 0 to N-1 generate
		
		ab(4*(I+1)-1 downto 4*I) <= not (a(4*(I+1)-1 downto 4*I)xor b(4*(I+1)-1 downto 4*I));
		a1b(4*(I+1)-1 downto 4*I) <= (not a(4*(I+1)-1 downto 4*I)) and b(4*(I+1)-1 downto 4*I);
		
-- propaga petición si las dos entradas son iguales not (a xor b)
-- el el caso que a=0 y b=1, genera petición. Si a=1 y b=0 mata la petición
	  		
		Xor_1: XORCY port map (O => p(4*I), CI => ci(4*I), LI => ab(4*I));
		Mxcy_1: MUXCY port map (DI => a1b(4*i),CI => ci(4*i),S => ab(4*i),O => ci(4*i+1));	

		Xor_2: XORCY port map (O => p(4*I+1), CI => ci(4*I+1), LI => ab(4*I+1));
		Mxcy_2: MUXCY port map (DI => a1b(4*i+1),CI => ci(4*i+1),S => ab(4*i+1),O => ci(4*i+2));	
		
		Xor_3: XORCY port map (O => p(4*I+2), CI => ci(4*I+2), LI => ab(4*I+2));
		Mxcy_3: MUXCY port map (DI => a1b(4*i+2),CI => ci(4*i+2),S => ab(4*i+2),O => ci(4*i+3));	

		Xor_4: XORCY port map (O => p(4*I+3), CI => ci(4*I+3), LI => ab(4*I+3));
		Mxcy_4: MUXCY port map (DI => a1b(4*i+3),CI => ci(4*i+3),S => ab(4*i+3),O => ci(4*(i+1)));	

-- p = a-b complementado
-- en la operación pide al dígito anterior c(4*(I+1))='1'

  
	end generate;

	a_less_B <= ci(4*N);

end Behavioral;

