-------------------------------------------------------------------------------
--
--  This file is part of Radix-10 restoring square root.
--
--  Description:  
--    returns the number of leading zeros
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



-- Devuelve la cantidad de 0`s consecutivos que se encuentran al inicio de la secuencia

-- En el caso de ln versión V de ln (ln_Sh_V), se usa ara la eliminación de 0's iniciales del resultado calculado,
-- P puede ser 8,17,35 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.my_package.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity LeadingZeros is
	generic (P: integer:=16);
    Port ( a : in  STD_LOGIC_VECTOR (4*P-1 downto 0);
			 c : out  STD_LOGIC_VECTOR (log2sup(P+1)-1 downto 0));
end LeadingZeros;

architecture Behavioral of LeadingZeros is

	signal cg: std_logic_vector(P downto 0);
	signal g: std_logic_vector(P-1 downto 0);

begin

	cg(0) <= '1';
	
	genones: for I in P-1 downto 0 generate
	
		LUT6_g : LUT6
			generic map (
				INIT => X"0000000000000001") -- para detectar 0's
-- desde más significativo a menos significativo
			port map (
				O => g(P-1-i),
				I0 => a(4*i),
				I1 => a(4*i+1),
				I2 => a(4*i+2),
				I3 => a(4*i+3),
				I4 => '0',
				I5 => '0');	

		Mxcy: MUXCY port map (
		    	DI => '0',
		    	CI => cg(P-1-i),
		    	S => g(P-1-i),
		    	O => cg(P-i));
	end generate;


-- ==================
-- para leading 0's de la entrada
   gP7: if P=7 generate
		c(2) <= cg(4);
		c(1) <= (cg(2) and (not cg(4))) or cg(6);
		c(0) <= (cg(1) and (not cg(2))) or (cg(3) and (not cg(4))) or (cg(5) and (not cg(6))) or cg(7); 
	end generate;
	

   gP16: if P=16 generate
		c(4) <= cg(16);
		c(3) <= cg(8) and (not cg(16));
		c(2) <= (cg(4) and (not cg(8))) or (cg(12) and (not cg(16)));
		c(1) <= (cg(2) and (not cg(4))) or (cg(6) and (not cg(8))) or (cg(10) and (not cg(12))) or (cg(14) and (not cg(16))); 
		c(0) <= (cg(1) and (not cg(2))) or (cg(3) and (not cg(4))) or (cg(5) and (not cg(6))) or (cg(7) and (not cg(8))) or (cg(9) and (not cg(10))) or 
				(cg(11) and (not cg(12))) or (cg(13) and (not cg(14))) or (cg(15) and (not cg(16))); 
	end generate;
	
	   
	gP34: if P=34 generate
		c(5) <= cg(32);
		c(4) <= cg(16) and (not cg(32));
		c(3) <= (cg(8) and (not cg(16))) or (cg(24) and (not cg(32)));
		c(2) <= (cg(4) and (not cg(8))) or (cg(12) and (not cg(16))) or (cg(20) and (not cg(24))) or (cg(28) and (not cg(32)));
		
		c(1) <= (cg(2) and (not cg(4))) or (cg(6) and (not cg(8))) or (cg(10) and (not cg(12))) or (cg(14) and (not cg(16))) or 
		       (cg(18) and (not cg(20))) or (cg(22) and (not cg(24))) or (cg(26) and (not cg(28))) or (cg(30) and (not cg(32))) or cg(34);
	
		c(0) <= (cg(1) and (not cg(2))) or (cg(3) and (not cg(4))) or (cg(5) and (not cg(6))) or (cg(7) and (not cg(8))) or (cg(9) and (not cg(10))) or 
				(cg(11) and (not cg(12))) or (cg(13) and (not cg(14))) or (cg(15) and (not cg(16))) or (cg(17) and (not cg(18))) or (cg(19) and (not cg(20))) or
			(cg(21) and (not cg(22))) or (cg(23) and (not cg(24))) or (cg(25) and (not cg(26))) or (cg(27) and (not cg(28))) or (cg(29) and (not cg(30))) or
			(cg(31) and (not cg(32))) or (cg(33) and (not cg(34)));
				
	end generate;
-- ==================


-- ==================
-- para leading 0's del resultado parcial
   gP8: if P=8 generate
		c(3) <= cg(8);
		c(2) <= cg(4) and (not cg(8));
		c(1) <= (cg(2) and (not cg(4))) or (cg(6) and (not cg(8)));
		c(0) <= (cg(1) and (not cg(2))) or (cg(3) and (not cg(4))) or (cg(5) and (not cg(6))) or (cg(7) and (not cg(8))); 
	end generate;

   gP17: if P=17 generate
		c(4) <= cg(16);
		c(3) <= cg(8) and (not cg(16));
		c(2) <= (cg(4) and (not cg(8))) or (cg(12) and (not cg(16)));
	  	c(1) <= (cg(2) and (not cg(4))) or (cg(6) and (not cg(8))) or (cg(10) and (not cg(12))) or (cg(14) and (not cg(16))); 
	
   	c(0) <= (cg(1) and (not cg(2))) or (cg(3) and (not cg(4))) or (cg(5) and (not cg(6))) or (cg(7) and (not cg(8))) or (cg(9) and (not cg(10))) or 
				(cg(11) and (not cg(12))) or (cg(13) and (not cg(14))) or (cg(15) and (not cg(16))) or cg(17); 
	end generate;
	
	
	gP35: if P=35 generate
		c(5) <= cg(32);
		c(4) <= cg(16) and (not cg(32));
		c(3) <= (cg(8) and (not cg(16))) or (cg(24) and (not cg(32)));
		c(2) <= (cg(4) and (not cg(8))) or (cg(12) and (not cg(16))) or (cg(20) and (not cg(24))) or (cg(28) and (not cg(32)));
		
		c(1) <= (cg(2) and (not cg(4))) or (cg(6) and (not cg(8))) or (cg(10) and (not cg(12))) or (cg(14) and (not cg(16))) or 
		       (cg(18) and (not cg(20))) or (cg(22) and (not cg(24))) or (cg(26) and (not cg(28))) or (cg(30) and (not cg(32))) or cg(34);
	
		c(0) <= (cg(1) and (not cg(2))) or (cg(3) and (not cg(4))) or (cg(5) and (not cg(6))) or (cg(7) and (not cg(8))) or (cg(9) and (not cg(10))) or 
				(cg(11) and (not cg(12))) or (cg(13) and (not cg(14))) or (cg(15) and (not cg(16))) or (cg(17) and (not cg(18))) or (cg(19) and (not cg(20))) or
			(cg(21) and (not cg(22))) or (cg(23) and (not cg(24))) or (cg(25) and (not cg(26))) or (cg(27) and (not cg(28))) or (cg(29) and (not cg(30))) or
			(cg(31) and (not cg(32))) or (cg(33) and (not cg(34))) or cg(35);
	end generate;
-- =================



	
end Behavioral;

