------------------------------------------------------------------------------
-- Create/rivision Date: 07/19/09 
-- Design Name:    Tomasulo Execution Units
-- Module Name:    DIVIDER_CORE
-- Author:         Rahul Tekawade, Ketan Sharma, Gandhi Puvvada
------------------------------------------------------------------------------
-- This is a combinational divider, which is given multiple clocks to finish its operation.
-- Multiple Clock Cycle constraint is placed in the .ucf file for paths passing through it.
-- This divider_core is instanted by a divider wrapper.
-- The wrapper carries ROB Tag, etc and it takes care of selective flushing the on-going division if needed.
-- This is actually a 16-bit unsigned division. However, the inputs, Dividend and Divisor, are both 32 bits each.
-- The assumption is that the upper 16 bits of these 32 bit operands are always zeros..
-- The 16-bit remainder and the 16 bit quotient are concatenated into one 32-bit word (called Rem_n_Quo) and returned as output.
------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
-- use IEEE.STD_LOGIC_UNSIGNED.ALL;
------------------------------------------------------------------------------
entity divider_core is
    Port ( Dividend : in std_logic_vector (31 downto 0 );
           Divisor : in std_logic_vector ( 31 downto 0);
           Rem_n_Quo : out std_logic_vector ( 31 downto 0)
          );
end divider_core;
------------------------------------------------------------------------------
architecture behv of divider_core is
   --signal div_rem_n_quo : std_logic_vector(31 downto 0); --Mod by PRASANJEET 7/25/09  
	begin 
	
	division_combi: process ( Dividend, Divisor)
	
	variable Dvd : std_logic_vector ( 31 downto 0);           -- dividend
	variable Dvr : std_logic_vector ( 31 downto 0);           -- divisor
	variable Quo : std_logic_vector ( 15 downto 0);           -- quotient
	variable Remain : std_logic_vector ( 15 downto 0);           -- remainder
	
	begin  
	Remain := (others => '0');
	
	Dvd := Dividend ;
	Dvr := Divisor ;
	
	IF ( Dvr = X"00000000") THEN         -- DIVIDE BY ZERO
		 Remain := X"FFFF";
		 Quo := X"FFFF";
	ELSE            
	  
	  for i in 0 to 15 loop

		  Remain := Remain(14 downto 0) & Dvd(15 - i);
		  IF ( unsigned(Remain) >= unsigned(Dvr) ) THEN 
				Remain := unsigned(Remain) - unsigned(Dvr(15 downto 0));
				Quo(15 - i) := '1';
		  ELSE
				Quo(15 - i) := '0';      
		  END IF;
	  
	  end loop;

	END IF;
	
   --div_rem_n_quo <=  --Mod by PRASANJEET 7/25/09 
	Rem_n_Quo <= Remain & Quo; 
	
	end process division_combi;
end behv;

