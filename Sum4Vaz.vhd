-------------------------------------------------------------------------------
--
--  This file is part of Radix-10 restoring square root.
--
--  Description:  
--    4-bit adder with precorrection
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



library UNISIM;
use UNISIM.vcomponents.all;

entity Sum4Vaz is
    Port ( a : in  STD_LOGIC_VECTOR (3 downto 0);
           b : in  STD_LOGIC_VECTOR (3 downto 0);
           cin : in  STD_LOGIC;
           s : out  STD_LOGIC_VECTOR (3 downto 0);
           cout : out  STD_LOGIC);
end Sum4Vaz;

architecture Behavioral of Sum4Vaz is

	signal p: std_logic_vector(3 downto 0);
	signal co: std_logic_vector(2 downto 0);
	signal ss: std_logic_vector(3 downto 1);

--signal ts: std_logic_vector(2 downto 1);

	signal g: std_logic;

begin


-- ============ Comienzo: Para el bit 0
	     LUT2_b0 : LUT2
		   generic map (  
		      INIT => "0110") -- a(1) xor b(1)
		   port map (
		      O => p(0),   
		      I0 => a(0), 
		      I1 => b(0)  
		   );

		  Mxcy_0: MUXCY port map (
		    	DI => a(0),
		    	CI => cin,
		    	S => p(0),
		    	O => co(0));

		  XORCY_0 : XORCY
			   port map (
			      O => s(0), 
			      CI => cin, 
			      LI => p(0) 
			   );				
-- ============ Fin: Para el bit 0				
	
-- ============ Comienzo: Para el bit 1
	   	LUT6_P1 : LUT6
			generic map (
				INIT => X"000000150b160d1a") 
				
-- desde más significativo a menos significativo, a3.a2.a1.b3.b2.b1 a a3'.a2'.a1'.b3'.b2'.b1'
			port map (
				O => p(1),
				I0 => b(1),
				I1 => b(2),
				I2 => b(3),
				I3 => a(1),
				I4 => a(2),
				I5 => a(3));

		  Mxcy_1: MUXCY port map (
		    	DI => '0',
		    	CI => co(0),
		    	S => p(1),
		    	O => co(1));

		  XORCY_1 : XORCY
			   port map (
			      O => ss(1),--s(1), 
			      CI => co(0), 
			      LI => p(1) 
			   );				
-- ============ Fin: Para el bit 1						


-- ============ Comienzo: Para el bit 2
	   	LUT6_P2 : LUT6
			generic map (
				INIT => X"0000001913070e1c") 
-- desde más significativo a menos significativo, a3.a2.a1.b3.b2.b1 a a3'.a2'.a1'.b3'.b2'.b1'
			port map (
				O => p(2),
				I0 => b(1),
				I1 => b(2),
				I2 => b(3),
				I3 => a(1),
				I4 => a(2),
				I5 => a(3));

		  Mxcy_2: MUXCY port map (
		    	DI => '0',
		    	CI => co(1),
		    	S => p(2),
		    	O => co(2));

		  XORCY_2 : XORCY
			   port map (
			      O => ss(2),--s(2), 
			      CI => co(1), 
			      LI => p(2) 
			   );				
-- ============ Fin: Para el bit 2				


-- ============ Comienzo: Para el bit 3

	   	LUT6_P3 : LUT6
			generic map (
				INIT => X"0000000102040810") 
-- desde más significativo a menos significativo, a3.a2.a1.b3.b2.b1 a a3'.a2'.a1'.b3'.b2'.b1'
			port map (
				O => p(3),
				I0 => b(1),
				I1 => b(2),
				I2 => b(3),
				I3 => a(1),
				I4 => a(2),
				I5 => a(3));


	   	LUT6_G : LUT6
			generic map (
				INIT => X"0000001e1c181000") 
-- desde más significativo a menos significativo, a3.a2.a1.b3.b2.b1 a a3'.a2'.a1'.b3'.b2'.b1'
			port map (
				O => g,
				I0 => b(1),
				I1 => b(2),
				I2 => b(3),
				I3 => a(1),
				I4 => a(2),
				I5 => a(3));

		  Mxcy_3: MUXCY port map (
		    	DI => g,
		    	CI => co(2),
		    	S => p(3),
		    	O => cout);

		  XORCY_3 : XORCY
			   port map (
			      O => ss(3),--s(3), 
			      CI => co(2), 
			      LI => p(3) 
			   );				

-- ============ Fin: Para el bit 3				


-- ========== Fase de eliminación de números redundantes
-- OJO NO USA LOS LATCH del slice
-- debería agregar lígica a la salida del latch para ver si utiliza otro latch
-- quzá deba hacer simplemente el not

	LDCE_inst1 : LDCE
		generic map (INIT => '0') -- Initial value of latch ('0' or '1')  
		port map (
			Q => s(1),      -- Data output
			CLR => ss(3),  -- Asynchronous clear/reset input
			D => ss(1),      -- Data input
			G => '1',      -- Gate input
			GE => '1'     -- Gate enable input
		);

	LDCE_inst2 : LDCE
		generic map (INIT => '0') -- Initial value of latch ('0' or '1')  
		port map (
			Q => s(2),      -- Data output
			CLR => ss(3),  -- Asynchronous clear/reset input
			D => ss(2),      -- Data input
			G => '1',      -- Gate input
			GE => '1'     -- Gate enable input
		);
	
	--s(2) <= ss(2) and (not ss(3));
	--s(1) <= ss(1) and (not ss(3));
	
	s(3) <= ss(3);

--s(2) <= ts(2) and ts(1);
--s(1) <= ts(1) or ts(2);

end Behavioral;

