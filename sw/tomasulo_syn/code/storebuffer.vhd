-------------------------------------------
-- CHECKED AND MODIFIED BY WALEED
-------------------------------------------
--UPDATED ON: 6/4/10

-------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity store_buffer is
port ( 
	  -- Global Signals
	    Clk            	: in  std_logic ;
        Resetb          : in  std_logic ;

	  --interface with ROB
		Rob_SwAddr  		: in std_logic_vector (31 downto 0);
		PhyReg_StoreData  	: in std_logic_vector (31 downto 0);
		Rob_CommitMemWrite  : in std_logic;
		SB_Full           	: out std_logic;
		SB_Stall 		   	: out std_logic;
		Rob_TopPtr    		: in std_logic_vector(4 downto 0);
		
	  -- interface with lsq //addr buffer
		SB_FlushSw           : out std_logic;
		SB_FlushSwTag        : out std_logic_vector(1 downto 0);
		SBTag_counter		   : out std_logic_vector (1 downto 0);
		
	   --interface with Data Cache Emulator
	    SB_DataDmem  	: out std_logic_vector (31 downto 0);
		SB_AddrDmem  	: out std_logic_vector (31 downto 0);
		SB_DataValid 	: out std_logic;
		DCE_WriteBusy 	: in std_logic;
		DCE_WriteDone 	: in std_logic
	  );   
end store_buffer;

architecture struct of store_buffer is

    type array_4_32 is array (0 to 3) of std_logic_vector(31 downto 0);
	type array_4_2 is array (0 to 3) of std_logic_vector(1 downto 0);
    type array_4_1 is array (0 to 3) of std_logic;
	signal counter : std_logic_vector (1 downto 0);
	signal addr, data : array_4_32;
	signal valid : array_4_1;
	signal SBTag : array_4_2;
	signal SBTag_temp: std_logic_vector (1 downto 0); -- The internal signal for SBTag_counter
	signal SB_Full_temp, send_data : std_logic;
	signal DCETag : std_logic_vector(1 downto 0);         
    begin
-- **************************************************************************************************	
-- Store buffer (SB) has 4 entries: 0,1,2,3. Entry 3 holds the oldest store instruction that will write to cache next.
-- This is why at Reset, the counter signal is initialized to 3 so that we first fill entry 3.
-- Each SB entry in the store buffer has the following fields:
		-- 1) 32 bit data field which holds the value of register $rt of store instructions.
		-- 2) 32 bit address field to access data cache.
		-- 3) valid bit: If valid bit is 0 then entry is free and can be used otherwise the entry is busy.
		-- 4) 2 bit Tag field: The Tag field is used to flush the corresponding entry in the address buffer when the store instruction leaves the store buffer.
-- **************************************************************************************************		
	    SB_Full_temp <= '1' when (counter = "00" and valid(0) = '1') else '0';	
		SB_Stall <= '1' when (DCE_WriteBusy = '1' and SB_Full_temp = '1') else '0';
		SB_Full <= SB_Full_temp;

		SB_DataDmem <= data(3);
		SB_AddrDmem <= addr(3);
		SB_DataValid <= valid(3);
		SB_FlushSwTag <= DCEtag;
		SB_FlushSw <= DCE_WriteDone;
		send_data <= (not (DCE_WriteBusy) and valid(3)) ;
		SBTag_counter <= SBTag_temp;

store_buffer_update: process (Clk, Resetb)	
	begin
		if(Resetb = '0') then
			counter <= "11";
			SBTag_temp <= "00";		
			for I in 0 to 3 loop
				valid(I) <= '0';
			end loop;
		elsif(clk'event and clk = '1') then
			if (send_data = '1') then
				for I in 3 downto 1 loop
					valid(I) <= valid(I - 1);
					addr(I) <= addr(I - 1);
					data(I) <= data(I - 1);
					SBTag(I) <= SBTag(I - 1);
					DCETag <= SBTag(3);
				end loop;
			end if;
			
	-- **************************************************************************************************
	-- Task1: You have to complete the else condition below. This if statement is resposible for adding a new 
	--        store instruction to the store buffer. Notice that we first check if the instruction at the top 
	--        the ROB is a "SW" instruction and that the store buffer is not full.
	-- Hint: send_data signal is used to indicate if the cache is busy writing the value of store in entry(3) to 
	--	     the cache. You need to understand how the counter value is updated before you fill the else part.
    --       Please read carefully the counter part at the end of the file.	
	-- **************************************************************************************************			
			
			if 	(Rob_CommitMemWrite = '1' and SB_Full_temp = '0') then
				if(send_data = '0') then
					valid(conv_integer(unsigned(counter))) <= '1';
					addr(conv_integer(unsigned(counter))) <= Rob_SwAddr;
					data(conv_integer(unsigned(counter))) <= PhyReg_StoreData;
					SBTag(conv_integer(unsigned(counter))) <= SBTag_temp;
					SBTag_temp <= SBTag_temp + 1;
				else 
					-- Add your code for Task1 here
					--if (send_data = '1') then --above for loop will shift SB entries up
					--update new SB entry
					--counter stays the same
					valid(conv_integer(unsigned(counter + '1'))) <= '1';
					addr(conv_integer(unsigned(counter + '1'))) <= Rob_SwAddr;
					data(conv_integer(unsigned(counter + '1'))) <= PhyReg_StoreData;
					SBTag(conv_integer(unsigned(counter + '1'))) <= SBTag_temp;
					SBTag_temp <= SBTag_temp + 1;
                    ---------------------------------
				end if;
			
			elsif (Rob_CommitMemWrite = '0') then
				if(send_data = '1') then
					valid(0) <= '0';
				end if; 

			end if;	
			
	-- **************************************************************************************************
	-- We use a 2-bit up/down saturating counter to point to the next free entry in the store buffer. As we mentioned
	-- the counter is initialized to "11". Whenever we add a new instruction to the store buffer, we decrement the counter
    -- by 1 provided the counter value is greater than "00". On the other hand, when a store finish writing to the cache then
    -- we are going to shift all store buffer entry in the up direction and hence we need to increment our counter provided that 
    -- that the counter is not equal to 3.	
	-- **************************************************************************************************				
		
			if (send_data = '1' and Rob_CommitMemWrite = '0' and not(counter="11") and not(SB_Full_temp = '1')) then
				counter <= counter + 1;
			elsif (send_data = '0' and Rob_CommitMemWrite = '1' and not(counter="00")) then
				counter <= counter - '1' ;
			end if;
		 
		end if;
	end process;
end struct;

		
		