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


-- celda para realizar multiplicación de palablra BCD por 2
--proviene desde D:..\Doctorado\ProyMultNx1\codigos

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity cell_mult_x2 is
    Port ( d : in  STD_LOGIC_VECTOR (3 downto 0);
           s : out  STD_LOGIC_VECTOR (3 downto 0);
           cin : in  STD_LOGIC;
           co : out  STD_LOGIC);
end cell_mult_x2;

architecture Behavioral of cell_mult_x2 is

signal t: std_logic;
signal sx: std_logic_vector(3 downto 0);

begin

	-- evalua si es mayor igual a 5
	t <= d(3) or (d(2) and (d(1) or d(0)));

	
	sx <= d + "0011";
	
	co <= sx(3) when t='1' else '0';
	s(3 downto 1) <= sx(2 downto 0) when t='1' else d(2 downto 0);
	
	s(0) <= cin;
	
end Behavioral;

