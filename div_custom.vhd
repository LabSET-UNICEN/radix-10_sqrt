-------------------------------------------------------------------------------
--
--  This file is part of Radix-10 restoring square root.
--
--  Description:  
--    Divider
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


--
--  División entre dividendo con forma Q2.1 y divisor de forma Q1.1
--  otra caracteríastica es que el rango del divisor es [0.6-1.9]
-- y rango de dividendo es [0, 19.9]
-- el resultado que se requiere es de un dígito de precisión 


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


library UNISIM;
use UNISIM.VComponents.all;

entity div_custom is
	 	  Port (a : in  STD_LOGIC_VECTOR (11 downto 0);-- xxxx xxxx xxxx
             b : in  STD_LOGIC_VECTOR (4 downto 0);-- x xxxx
           q : out  STD_LOGIC_VECTOR (3 downto 0));
end div_custom;

architecture Behavioral of div_custom is

	component CmpBCD 
		generic (N :integer:= 7);
		 Port ( a : in  STD_LOGIC_VECTOR (4*N-1 downto 0);
				  b : in  STD_LOGIC_VECTOR (4*N-1 downto 0);
				 a_less_b: out std_logic);
	end component;

-- poseen los productos parciales si son de b.f, con f en [0,9]
	signal p1, p2, p3, p4, p5, p6, p7, p8, p9: std_logic_vector(11 downto 0);

-- posee los si a es menor a cada producto parcial
	signal s_ab: std_logic_vector(9 downto 1);

begin

	p1 <= "0000000"&b;

-- =================================
-- Correspondiente a 2x
-- =================================
	p2(11 downto 6) <= (others => '0');
	p2(5 downto 0) <= "010010" when b="00110" else -- 1.2 cuando es 0.6
							"010100" when b="00111" else -- 1.4 cuando es 0.7
							"010110" when b="01000" else -- 1.6 cuando es 0.8
							"011000" when b="01001" else -- 1.8 cuando es 0.9
							"100000" when b="10000" else -- 2.0 cuando es 1.0
							"100010" when b="10001" else -- 2.2 cuando es 1.1
							"100100" when b="10010" else -- 2.4 cuando es 1.2
							"100110" when b="10011" else -- 2.6 cuando es 1.3
							"101000" when b="10100" else -- 2.8 cuando es 1.4
							"110000" when b="10101" else -- 3.0 cuando es 1.5
							"110010" when b="10110" else -- 3.2 cuando es 1.6
							"110100" when b="10111" else -- 3.4 cuando es 1.7
							"110110" when b="11000" else -- 3.6 cuando es 1.8
							"111000" when b="11001" else -- 3.8 cuando es 1.9
							(others => '0');
-- =================================
	
	
-- =================================
-- Correspondiente a 3x
-- =================================
	p3(11 downto 7) <= (others => '0');
	p3(6 downto 0) <= "0011000" when b="00110" else -- 1.8 cuando es 0.6
							"0100001" when b="00111" else -- 2.1 cuando es 0.7
							"0100100" when b="01000" else -- 2.4 cuando es 0.8
							"0100111" when b="01001" else -- 2.7 cuando es 0.9
							"0110000" when b="10000" else -- 3.0 cuando es 1.0
							"0110011" when b="10001" else -- 3.3 cuando es 1.1
							"0110110" when b="10010" else -- 3.6 cuando es 1.2
							"0111001" when b="10011" else -- 3.9 cuando es 1.3
							"1000010" when b="10100" else -- 4.2 cuando es 1.4
							"1000101" when b="10101" else -- 4.5 cuando es 1.5
							"1001000" when b="10110" else -- 4.8 cuando es 1.6
							"1010001" when b="10111" else -- 5.1 cuando es 1.7
							"1010100" when b="11000" else -- 5.4 cuando es 1.8
							"1010111" when b="11001" else -- 5.7 cuando es 1.9
							(others => '0');
-- =================================
	
	
-- =================================
-- Correspondiente a 4x
-- =================================
	p4(11 downto 7) <= (others => '0');
	p4(6 downto 0) <= "0100100" when b="00110" else -- 2.4 cuando es 0.6
							"0101000" when b="00111" else -- 2.8 cuando es 0.7
							"0110010" when b="01000" else -- 3.2 cuando es 0.8
							"0110110" when b="01001" else -- 3.6 cuando es 0.9
							"1000000" when b="10000" else -- 4.0 cuando es 1.0
							"1000100" when b="10001" else -- 4.4 cuando es 1.1
							"1001000" when b="10010" else -- 4.8 cuando es 1.2
							"1010010" when b="10011" else -- 5.2 cuando es 1.3
							"1010110" when b="10100" else -- 5.6 cuando es 1.4
							"1100000" when b="10101" else -- 6.0 cuando es 1.5
							"1100100" when b="10110" else -- 6.4 cuando es 1.6
							"1101000" when b="10111" else -- 6.8 cuando es 1.7
							"1110010" when b="11000" else -- 7.2 cuando es 1.8
							"1110110" when b="11001" else -- 7.6 cuando es 1.9
							(others => '0');
-- =================================
	

-- =================================
-- Correspondiente a 5x
-- =================================
	p5(11 downto 8) <= (others => '0');	
	p5(7 downto 0) <= "00110000" when b="00110" else -- 3.0 cuando es 0.6
							"00110101" when b="00111" else -- 3.5 cuando es 0.7
							"01000000" when b="01000" else -- 4.0 cuando es 0.8
							"01001001" when b="01001" else -- 4.5 cuando es 0.9
							"01010000" when b="10000" else -- 5.0 cuando es 1.0
							"01010101" when b="10001" else -- 5.5 cuando es 1.1
							"01100000" when b="10010" else -- 6.0 cuando es 1.2
							"01100101" when b="10011" else -- 6.5 cuando es 1.3
							"01110000" when b="10100" else -- 7.0 cuando es 1.4
							"01110101" when b="10101" else -- 7.5 cuando es 1.5
							"10000000" when b="10110" else -- 8.0 cuando es 1.6
							"10000101" when b="10111" else -- 8.5 cuando es 1.7
							"10010000" when b="11000" else -- 9.0 cuando es 1.8
							"10010101" when b="11001" else -- 9.5 cuando es 1.9
							(others => '0');
-- =================================

-- =================================
-- Correspondiente a 6x
-- =================================
	p6(11 downto 9) <= (others => '0');	
	p6(8 downto 0) <= "000110110" when b="00110" else -- 3.6 cuando es 0.6
							"001000010" when b="00111" else -- 4.2 cuando es 0.7
							"001001000" when b="01000" else -- 4.8 cuando es 0.8
							"001010100" when b="01001" else -- 5.4 cuando es 0.9
							"001100000" when b="10000" else -- 6.0 cuando es 1.0
							"001100110" when b="10001" else -- 6.6 cuando es 1.1
							"001110010" when b="10010" else -- 7.2 cuando es 1.2
							"001111000" when b="10011" else -- 7.8 cuando es 1.3
							"010000100" when b="10100" else -- 8.4 cuando es 1.4
							"010010000" when b="10101" else -- 9.0 cuando es 1.5
							"010010110" when b="10110" else -- 9.6 cuando es 1.6
							"100000010" when b="10111" else -- 10.2 cuando es 1.7
							"100001000" when b="11000" else -- 10.8 cuando es 1.8
							"100010100" when b="11001" else -- 11.4 cuando es 1.9
							(others => '0');
-- =================================	

-- =================================
-- Correspondiente a 7x
-- =================================
	p7(11 downto 9) <= (others => '0');	
	p7(8 downto 0) <= "001000010" when b="00110" else -- 4.2 cuando es 0.6
							"001001001" when b="00111" else -- 4.9 cuando es 0.7
							"001010110" when b="01000" else -- 5.6 cuando es 0.8
							"001100011" when b="01001" else -- 6.3 cuando es 0.9
							"001110000" when b="10000" else -- 7.0 cuando es 1.0
							"001110111" when b="10001" else -- 7.7 cuando es 1.1
							"010000100" when b="10010" else -- 8.4 cuando es 1.2
							"010010001" when b="10011" else -- 9.1 cuando es 1.3
							"010011000" when b="10100" else -- 9.8 cuando es 1.4
							"100000101" when b="10101" else -- 10.5 cuando es 1.5
							"100010010" when b="10110" else -- 11.2 cuando es 1.6
							"100011001" when b="10111" else -- 11.9 cuando es 1.7
							"100100110" when b="11000" else -- 12.6 cuando es 1.8
							"100110011" when b="11001" else -- 13.3 cuando es 1.9
							(others => '0');
-- =================================	


-- =================================
-- Correspondiente a 8x
-- =================================
	p8(11 downto 9) <= (others => '0');		
	p8(8 downto 0) <= "001001000" when b="00110" else -- 4.8 cuando es 0.6
							"001010110" when b="00111" else -- 5.6 cuando es 0.7
							"001100100" when b="01000" else -- 6.4 cuando es 0.8
							"001110010" when b="01001" else -- 7.2 cuando es 0.9
							"010000000" when b="10000" else -- 8.0 cuando es 1.0
							"010001000" when b="10001" else -- 8.8 cuando es 1.1
							"010010110" when b="10010" else -- 9.6 cuando es 1.2
							"100000100" when b="10011" else -- 10.4 cuando es 1.3
							"100010010" when b="10100" else -- 11.2 cuando es 1.4
							"100100000" when b="10101" else -- 12.0 cuando es 1.5
							"100101000" when b="10110" else -- 12.8 cuando es 1.6
							"100110110" when b="10111" else -- 13.6 cuando es 1.7
							"101000100" when b="11000" else -- 14.4 cuando es 1.8
							"101010001" when b="11001" else -- 15.2 cuando es 1.9
							(others => '0');
-- =================================	

-- =================================
-- Correspondiente a 9x
-- =================================
	p9(11 downto 9) <= (others => '0');		
	p9(8 downto 0) <= "001010100" when b="00110" else -- 5.4 cuando es 0.6
							"001100011" when b="00111" else -- 6.3 cuando es 0.7
							"001110010" when b="01000" else -- 7.2 cuando es 0.8
							"010000001" when b="01001" else -- 8.1 cuando es 0.9
							"010010000" when b="10000" else -- 9.0 cuando es 1.0
							"010011001" when b="10001" else -- 9.9 cuando es 1.1
							"100001000" when b="10010" else -- 10.8 cuando es 1.2
							"100010111" when b="10011" else -- 11.7 cuando es 1.3
							"100100110" when b="10100" else -- 12.6 cuando es 1.4
							"100110101" when b="10101" else -- 13.5 cuando es 1.5
							"101000100" when b="10110" else -- 14.4 cuando es 1.6
							"101010011" when b="10111" else -- 15.3 cuando es 1.7
							"101100010" when b="11000" else -- 16.2 cuando es 1.8
							"101110001" when b="11001" else -- 17.1 cuando es 1.9
							(others => '0');
-- =================================	


	cmp1: CmpBCD generic map (N => 3) port map (a => a, b =>p1, a_less_b => s_ab(1));
	cmp2: CmpBCD generic map (N => 3) port map (a => a, b =>p2, a_less_b => s_ab(2));
	cmp3: CmpBCD generic map (N => 3) port map (a => a, b =>p3, a_less_b => s_ab(3));
	cmp4: CmpBCD generic map (N => 3) port map (a => a, b =>p4, a_less_b => s_ab(4));
	cmp5: CmpBCD generic map (N => 3) port map (a => a, b =>p5, a_less_b => s_ab(5));
	cmp6: CmpBCD generic map (N => 3) port map (a => a, b =>p6, a_less_b => s_ab(6));
	cmp7: CmpBCD generic map (N => 3) port map (a => a, b =>p7, a_less_b => s_ab(7));
	cmp8: CmpBCD generic map (N => 3) port map (a => a, b =>p8, a_less_b => s_ab(8));
	cmp9: CmpBCD generic map (N => 3) port map (a => a, b =>p9, a_less_b => s_ab(9));


	q <= x"0" when s_ab(1)='1' else
		  x"1" when s_ab(2)='1' else
   	  x"2" when s_ab(3)='1' else
			x"3" when s_ab(4)='1' else		  
			x"4" when s_ab(5)='1' else
			x"5" when s_ab(6)='1' else		  
			x"6" when s_ab(7)='1' else
			x"7" when s_ab(8)='1' else		  
			x"8" when s_ab(9)='1' else
			x"9";

	
end Behavioral;

