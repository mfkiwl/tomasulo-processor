------------------------------------------------------------------------------------------------------------------------------------
--********************************************************************************************************************
-- Design   		: Return Address Stack
-- Project  		: EE560 Summer 2010
-- Entity   		: ras
-- Author   		: Varun Khadilkar
-- Company  		: University of Southern California 
-- Last Updated     : March 19, 2010
--********************************************************************************************************************
------------------------------------------------------------------------------------------------------------------------------------
--Comments: 
--Mar 23	:	Last location is never emptied. Added extra register to empty last locations.
--Mar 19	: 	TOSP, TOSP+1 changed from integer to counters. Removed ras_addr_valid. Now we give help from RAS all the time
--Mar 8		:	Can we help even if RAS is empty? Keep driving output with last value. Change the code.
--Mar 5		:	New code Complete.
--Mar 1		: 	Some singals needs to be continuously driven, e.g. Output ADDR by RAS. Change.
--Feb 25	:	RAS in Dispatch. Code changed. Now component of Dipatch stage. Checkpoints removed.
--Feb 21	:	RAS no longer in Fetch !! Change Design. 
--Feb 16	: 	RAS Design updated. RAS to be checkpointed. Detail Circuit Diagram designed.
--Feb 12	:	RAS Designed. 4 location. 32 wide. In Fetch. 
------------------------------------------------------------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_signed.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

------------------------------------------------------------------------------------------------------------------------------------
entity ras is

generic (size  : integer :=4);

port(
	--global signals
	Resetb 					: in std_logic;
	Clk						: in std_logic;
	 
	-- Interface with Dispatch
	--inputs
	Dis_PcPlusFour			: in std_logic_vector(31 downto 0); 	-- the PC+4 value carried forward for storing in RAS
	Dis_RasJalInst				: in std_logic;							-- set to 1 if instruction is JAL
	Dis_RasJr31Inst				: in std_logic;							-- set to 1 if instruction is JR
	--outputs
	Ras_Addr				: out std_logic_vector(31 downto 0) 	-- The address given by RAS for JR
	
	);
	
end ras;

-------------------------------------------------------------------------------------------------------------------------------------------

architecture ras_arch of ras is

	-- RAS counter
	-- Used to Keep track of how filled is Stack. "000" means Empty. "100" means Full. 
	-- Counter Saturates at "100". This means even if we push more data, we can have only latest 4 stored.
	
	signal RasCounter	: std_logic_vector (2 downto 0);	
	
	-- Top of the stack pointer
	-- Tosp in this design Points to the FILLED LOCATION. Thus we always push at TospPlusOne. But Pop from Tosp. 
	signal Tosp			: std_logic_vector (1 downto 0);
	signal TospPlusOne	: std_logic_vector (1 downto 0);
	
	--RAS data
	-- UseWhen Empty latches the last Poped address and drives output when RAS is empty.
	-- Thus for external World, RAS is never empty. It keeps giving data which is a prediction and may be wrong.
	signal UseWhenEmpty : std_logic_vector(31 downto 0);
	subtype RasData is std_logic_vector(31 downto 0);
	type RasDepth is array(0 to size-1) of RASData;
	signal Ras    : RasDepth;
	
-------------------------------------------------------------------------------------------------------------------------------------------	
	begin

	
		--Ras_Addr is continueously giving address stored at location pointed by TOSP
		--This way we can POP data stored in RAS without wasting a clock.

		Ras_Addr <= Ras(CONV_INTEGER (unsigned( Tosp))) when RasCounter /= "000" else UseWhenEmpty; 
	
		process (Clk, Resetb)
		begin
			
			-- in Resetb, we set ras counter to zero (ras is empty)
			-- tosp and tospplusone both point to zero. but its fine because as soon as we start filling ras, they are updated as desired.
			-- 
			if (Resetb = '0') then
			
				Rascounter <= "000";
				Tosp <= "11";
				TospPlusOne <= "00";
				UseWhenEmpty <= (others => '0');
				
				for i in (size-1) downto 0 loop
					
					Ras(i) <= (others => '0');
				
				end loop;
				
				
			
			
			elsif (Clk'event and Clk = '1') then
			
					
				if (Dis_RasJalInst = '1') then
					
					-- NOTE: we push on tospplusone and not tosp.
					-- This is because in our design, top of the stack pointer (TOSP) always points to a filled location.
					--Thus when we need to push data onto RAS, we have to do it at TOSP+1.
					Ras(CONV_INTEGER (unsigned( TospPlusOne)))  <= Dis_PcPlusFour;
					
					--if instruction is JAL, we advise to push PC+4 in RAS at the next clock edge, increment TOSP and RASCON						
					Tosp <= Tosp + 1;
					TospPlusOne <= TospPlusOne + 1;
					Rascounter <= Rascounter + 1;
					if (Rascounter = "100") then Rascounter <= "100"; end if;
				
				end if;
				
			--if instruction is JR, if RASCON is not zero, then we advise to decrement TOSP and RASCON on next clock edge.	
				if (Dis_RasJr31Inst = '1' ) then 
					
					if (Rascounter /= "000") then
						
						TospPlusOne <= TospPlusOne - 1;
						Tosp <= Tosp - 1;					
						Rascounter <= Rascounter - 1;
						UseWhenEmpty <= Ras(CONV_INTEGER (unsigned( Tosp)));
						
					end if;			
				end if;
					
				
					
			end if;

		end process;			
			
	end ras_arch;
-------------------------------------------------------------------------------------------------------------------------------------	
	