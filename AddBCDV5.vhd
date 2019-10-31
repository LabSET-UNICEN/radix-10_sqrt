-------------------------------------------------------------------------------
--
--  This file is part of Radix-10 restoring square root.
--
--  Description:  
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

-- Adder dependiendo en donde GyP dependen de suma inicial


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- use work.mipackage.all;

library UNISIM;
use UNISIM.VComponents.all;

entity AddBCD is
     generic (NDigit: integer:=16);
	  Port ( 
	        a, b : in  STD_LOGIC_VECTOR (NDigit*4-1 downto 0);
           cin : in  STD_LOGIC;
           cout : out  STD_LOGIC;
           s : out  STD_LOGIC_VECTOR (NDigit*4-1 downto 0));
end AddBCD;


architecture Behavioral of AddBCD is

component Add4V5 
		Port ( a : in  STD_LOGIC_VECTOR (3 downto 0);
           b : in  STD_LOGIC_VECTOR (3 downto 0);
           cin : in  STD_LOGIC;
           c : out  STD_LOGIC_VECTOR (3 downto 0);
           cout : out  STD_LOGIC);
end component;


	type partialAdds is array (NDigit-1 downto 0) of STD_LOGIC_VECTOR (4 downto 0);
	signal sum: partialAdds;


	signal cyin: std_logic_vector(NDigit downto 0);
	signal p, g: std_logic_vector(NDigit-1 downto 0);


begin

	cyin(0) <= cin; 	
	
	GenAdd: for i in 0 to NDigit-1 generate
		GAdd: Add4V5 Port map( a => a((i+1)*4-1 downto i*4),
										b => b((i+1)*4-1 downto i*4),
										cin => '0',
										c => sum(i)(3 downto 0),
										cout => sum(i)(4));
	end generate;	
	
		
	
	GenCch: for i in 0 to NDigit-1 generate
									
				GP1_LUT6 : LUT6_2
				generic map (
					INIT => X"00000200FFFFFC00") 
				port map (
					O6 => p(i),  
					O5 => g(i),  
					I0 => sum(i)(0),   
					I1 => sum(i)(1),   
					I2 => sum(i)(2),   
					I3 => sum(i)(3),   
					I4 => sum(i)(4),   
					I5 => '1'    
				);
			
				Mxcy_1: MUXCY port map (
							DI => g(i),
							CI => cyin(i),
							S => p(i),
							O => cyin(i+1));										
				
	end generate;
	
-- esto lo hace super óptimo, no hace propagación d eacarreo y de hecho usa varias LUT6:2
--	GenAddRes: for i in 0 to NDigit-1 generate
--      s((i+1)*4-1 downto i*4) <= sum(i)(3 downto 0) + (cyin(i+1) & cyin(i+1) & cyin(i));
--	end generate;
	
	
	
-- La LUTs correspondientes al peso 0 y peso uno se pueden implemetar en una LUT6:2	
-- se reduce el área
	GenAddRes: for i in 0 to NDigit-1 generate
      	
			
-- para la corrección del bit de peso 0 y 1				
       s01_LUT6 : LUT6_2
				generic map (
					INIT => X"0000936c00005a5a")  
				port map (
					O6 => s(4*i+1),  
					O5 => s(4*i),
					I0 => sum(i)(0),   
					I1 => sum(i)(1),   
					I2 => cyin(i),   
					I3 => cyin(i+1),   
					I4 => '0',   
					I5 => '1'); 	


-- para la corrección del bit de peso 2			
			LUT6_s2 : LUT6
			generic map (
				INIT => X"e001c003007800f0") 
-- desde más significativo a menos significativo
			port map (
				O => s(i*4+2),
				I4 => cyin(i),
				I5 => cyin(i+1),
				I0 => sum(i)(0),
				I1 => sum(i)(1),
				I2 => sum(i)(2),
				I3 => sum(i)(3));		


-- para la corrección del bit de peso 3			
			LUT6_s3 : LUT6
			generic map (
				INIT => X"0006000401800300") 
-- desde más significativo a menos significativo
			port map (
				O => s(i*4+3),
				I4 => cyin(i),
				I5 => cyin(i+1),
				I0 => sum(i)(0),
				I1 => sum(i)(1),
				I2 => sum(i)(2),
				I3 => sum(i)(3));		

	end generate;


	cout <= cyin(NDigit); 
	
end Behavioral;



