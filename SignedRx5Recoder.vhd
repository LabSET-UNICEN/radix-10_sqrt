-------------------------------------------------------------------------------
--
--  This file is part of Radix-10 restoring square root.
--
--  Description:  
--    BCD-8421 to radix-5 digit encoder
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



-- Recodifica, segun paper de Vazquez&Dinechin, un dígito BCD-8421 a digito radix 5 con signo de la forma (yu, yl)
-- Con yu en {1,2,0}, yl en {-2,-1, 0, 1, 2}
-- De este modo, d = 5*yu + yl

-- Para yu: 0 -> 00, 1 -> 01, 2 -> 10
-- Para yl: 0 -> 000, 1 -> 001, 2 -> 010, -1 -> 101, -2 -> 110

-- Para d = yu,yl
-- d	   yu		yl
-- 0000  00		000  
-- 0001  00		001  
-- 0010  00		010  
-- 0011  01		110  
-- 0100  01		101  
-- 0101  01		000  
-- 0110  01		001  
-- 0111  01		010  
-- 1000  10		110  
-- 1001  10		101  

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity SignedRx5Recoder is
    Port ( d : in  std_logic_vector (3 downto 0);
			  yu : out std_logic_vector (1 downto 0);
			  yl : out std_logic_vector (2 downto 0));
end SignedRx5Recoder;

architecture Behavioral of SignedRx5Recoder is

begin

  	 G_YU : LUT6_2
				generic map (
					INIT => X"0300000000f80000") 
				port map (
					O6 => yu(1),  
					O5 => yu(0),  
					I0 => d(0),   
					I1 => d(1),   
					I2 => d(2),   
					I3 => d(3),   
					I4 => '1',   
					I5 => '1'    
				);


  	 G_YL_21 : LUT6_2
				generic map (
					INIT => X"03180000018c0000") 
				port map (
					O6 => yl(2),  
					O5 => yl(1),  
					I0 => d(0),   
					I1 => d(1),   
					I2 => d(2),   
					I3 => d(3),   
					I4 => '1',   
					I5 => '1'    
				);


	G_YL_0 : LUT6
				generic map (
					INIT => X"0252000000000000") 
				port map (
					O => yl(0),  
					I0 => d(0),   
					I1 => d(1),   
					I2 => d(2),   
					I3 => d(3),   
					I4 => '1',   
					I5 => '1'    
				);



end Behavioral;

