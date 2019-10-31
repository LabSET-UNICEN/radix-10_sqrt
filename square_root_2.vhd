-------------------------------------------------------------------------------
--
--  This file is part of Radix-10 restoring square root.
--
--  Description:  
--    Precalculed tables for 2-digit BCD square root 
--		the input number must be less or equal than 10 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity square_root_2 is
    Port ( a : in  STD_LOGIC_VECTOR (7 downto 0);
           sr : out  STD_LOGIC_VECTOR (3 downto 0));
end square_root_2;

architecture Behavioral of square_root_2 is

begin


	sr <= x"3" when a=x"10" else
			x"3" when a=x"11" else
			x"3" when a=x"12" else
			x"3" when a=x"13" else
			x"3" when a=x"14" else
			x"3" when a=x"15" else
			x"4" when a=x"16" else
			x"4" when a=x"17" else
			x"4" when a=x"18" else
			x"4" when a=x"19" else
			x"4" when a=x"20" else
			x"4" when a=x"21" else
			x"4" when a=x"22" else
			x"4" when a=x"23" else
			x"4" when a=x"24" else
			x"5" when a=x"25" else
			x"5" when a=x"26" else
			x"5" when a=x"27" else
			x"5" when a=x"28" else
			x"5" when a=x"29" else
			x"5" when a=x"30" else
			x"5" when a=x"31" else
			x"5" when a=x"32" else
			x"5" when a=x"33" else
			x"5" when a=x"34" else
			x"5" when a=x"35" else
			x"6" when a=x"36" else
			x"6" when a=x"37" else
			x"6" when a=x"38" else
			x"6" when a=x"39" else
			x"6" when a=x"40" else
			x"6" when a=x"41" else
			x"6" when a=x"42" else
			x"6" when a=x"43" else
			x"6" when a=x"44" else
			x"6" when a=x"45" else
			x"6" when a=x"46" else
			x"6" when a=x"47" else
			x"6" when a=x"48" else
			x"7" when a=x"49" else
			x"7" when a=x"50" else
			x"7" when a=x"51" else
			x"7" when a=x"52" else
			x"7" when a=x"53" else
			x"7" when a=x"54" else
			x"7" when a=x"55" else
			x"7" when a=x"56" else
			x"7" when a=x"57" else
			x"7" when a=x"58" else
			x"7" when a=x"59" else
			x"7" when a=x"60" else
			x"7" when a=x"61" else
			x"7" when a=x"62" else
			x"7" when a=x"63" else
			x"8" when a=x"64" else
			x"8" when a=x"65" else
			x"8" when a=x"66" else
			x"8" when a=x"67" else
			x"8" when a=x"68" else
			x"8" when a=x"69" else
			x"8" when a=x"70" else
			x"8" when a=x"71" else
			x"8" when a=x"72" else
			x"8" when a=x"73" else
			x"8" when a=x"74" else
			x"8" when a=x"75" else
			x"8" when a=x"76" else
			x"8" when a=x"77" else
			x"8" when a=x"78" else
			x"8" when a=x"79" else
			x"8" when a=x"80" else
			x"9" when a=x"81" else
			x"9" when a=x"82" else
			x"9" when a=x"83" else
			x"9" when a=x"84" else
			x"9" when a=x"85" else
			x"9" when a=x"86" else
			x"9" when a=x"87" else
			x"9" when a=x"88" else
			x"9" when a=x"89" else
			x"9" when a=x"90" else
			x"9" when a=x"91" else
			x"9" when a=x"92" else
			x"9" when a=x"93" else
			x"9" when a=x"94" else
			x"9" when a=x"95" else
			x"9" when a=x"96" else
			x"9" when a=x"97" else
			x"9" when a=x"98" else
			x"9" when a=x"99" else 
			(others => '0'); -- son 38 casos que nunca entra
			
		
end Behavioral;

