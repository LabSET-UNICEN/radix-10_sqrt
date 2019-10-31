-------------------------------------------------------------------------------
--
--  This file is part of Radix-10 restoring square root.
--
--  Description:  
--    Control unit for radix-10 square root compliant with IEEE 754-2008 standard
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

Library UNISIM;
use UNISIM.vcomponents.all;

entity UnitCtrl_float is
	generic (P:integer:=7; K:integer:=3); -- K = parte entera superior
   Port ( clk, rst, start : in  STD_LOGIC;
           step: out std_logic_vector(K-1 downto 0);
			  base_i: out std_logic_vector(P-1 downto 0);-- para generar B**-1, B**-2,,,B**-P
			  ld_ini, ld_exp_cb, rst_acum, ld_acum, rst_w, ld_w, 
			  rst_y, ld_y, rst_out, ld_out, done: out STD_LOGIC);
end UnitCtrl_float;



architecture Behavioral of UnitCtrl_float is


	signal next_cnt, reg_cnt: std_logic_vector(K-1 downto 0);
	signal inc_cnt, rs_cnt: std_logic;
	
	signal next_base_i, reg_base_i: std_logic_vector(P-1 downto 0);-- para generar B**-1, B**-2,,,B**-P
	signal sh_base_i, rs_base_i: std_logic;
	
	type states is (inactive, do_init, do_pri, do_it, do_last, do_end);
	signal next_state, state : states;		
	

begin

	next_cnt <= (others => '0') when rs_cnt='1' else
					reg_cnt+1 when inc_cnt='1'else
					reg_cnt;				

--((P-1) => '1',others => '0')
	
	next_base_i <= "1000000" when rs_base_i='1' else
--	next_base_i <= "1000000000000000" when rs_base_i='1' else
-- next_base_i <= "1000000000000000000000000000000000" when rs_base_i='1' else
	
--	next_base_i <= ((P-1) => '1',others => '0') when rs_base_i='1' else
						('0'&reg_base_i(P-1 downto 1)) when sh_base_i='1' else 
						(others => '0');
					
	
	PCnt: process (clk, rst)
	begin
		if rst = '1' then
			reg_base_i <= (others => '0');
			reg_cnt <= (others => '0');
			state <= inactive;
		elsif rising_edge(clk) then
			reg_base_i <= next_base_i;
			reg_cnt <= next_cnt;
			state <= next_state;
		end if;
	end process;


	state_mach: process(start, state, reg_cnt)
	begin
			
		rs_base_i <= '0';
		sh_base_i <= '0';
		rs_cnt <= '0';
		inc_cnt <= '0';
		next_state <= state;	
		
		rst_acum <= '0';
		ld_acum <= '0';	

		rst_out <= '0';
		ld_out <= '0';	


		rst_w <= '0';
		rst_y <= '0';
				
		ld_ini <= '0';
		ld_exp_cb <= '0';
		ld_w <= '0';
		ld_y <= '0';	
				
		case state is
			
			when inactive =>

				if start='1' then -- caga dato inicial 
					next_state <= do_init;
					ld_ini <= '1';
				end if;

			when do_init => -- primer ciclo en donde se procesa mantisa y exponente

				next_state <= do_pri; 
				rs_base_i <= '1';
				rs_cnt <= '1';
				ld_exp_cb <= '1';
				rst_w <= '1';
				rst_acum <= '1';
				rst_y <= '1';
				rst_out <= '1';
				
			when do_pri => -- Aca el contador vale 0

		   	ld_y <= '1';
   			ld_w <= '1';
				sh_base_i <= '1';	
				inc_cnt <= '1';
				next_state <= do_it;
			
			when do_it => -- Aca el contador va desde 1 a P-1

		   	ld_y <= '1';
   			ld_w <= '1';
				ld_acum <= '1';
				inc_cnt <= '1';
				
				
				if reg_cnt = P-1 then
					next_state <= do_last;
				else 
					sh_base_i <= '1';	
									
				end if;
			
			when do_last => -- Aca el contador es P, paa efectuar la última etapa de multiplicación de la constante

				ld_acum <= '1';
				next_state <= do_end;

			when do_end => -- Aca la última etapa en donde se procesa resultado: redondeo, exponente, mantisa 

				ld_out <= '1';
				next_state <= inactive;

			

			when others => --finish
		end case;
	end process;
 
	step <= reg_cnt;
	base_i <= reg_base_i;
	done <= '0' when state/=inactive else '1';


end Behavioral;

