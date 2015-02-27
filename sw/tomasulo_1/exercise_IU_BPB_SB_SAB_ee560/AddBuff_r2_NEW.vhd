-- CHECKED AND MODIFIED BY PRASANJEET
-------------------------------------------
--UPDATED ON: 7/9/09

-------------------------------------------
-- CHECKED AND MODIFIED BY WALEED
-------------------------------------------
--UPDATED ON: 6/4/10

-------------------------------------------

-------------------------------------------------------------------------------
--
-- Design   : Load/Store Address Buff 
-- Project  : Tomasulo Processor 
-- Author   : Rohit Goel 
-- Company  : University of Southern California 
--
-------------------------------------------------------------------------------
--
-- File         : AddBuff.vhd
-- Version      : 1.0
--
-------------------------------------------------------------------------------
--
-- Description : The Issue control controls the Issuque 
-------------------------------------------------------------------------------
--library declaration
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;

-- Entity declaration
entity AddBuff is 

port (
                    -- Global Clk and Resetb Signals
                   Clk                   : in  std_logic;
                   Resetb                 : in  std_logic;
                   

                   AddrBuffFull          : out std_logic; --buffer full
                   AddrMatch0            : out std_logic;
                   AddrMatch1            : out std_logic;
                   AddrMatch2            : out std_logic;
                   AddrMatch3            : out std_logic;
				   AddrMatch4            : out std_logic;
                   AddrMatch5            : out std_logic;
                   AddrMatch6            : out std_logic;
                   AddrMatch7            : out std_logic;
                   
                   AddrMatch0Num         : out std_logic_vector (2 downto 0); 
                   AddrMatch1Num         : out std_logic_vector (2 downto 0);
                   AddrMatch2Num         : out std_logic_vector (2 downto 0);
                   AddrMatch3Num         : out std_logic_vector (2 downto 0);
                   AddrMatch4Num         : out std_logic_vector (2 downto 0); 
                   AddrMatch5Num         : out std_logic_vector (2 downto 0);
                   AddrMatch6Num         : out std_logic_vector (2 downto 0);
                   AddrMatch7Num         : out std_logic_vector (2 downto 0);
                                      
                   ScanAddr0             : in std_logic_vector (31 downto 0); --scan address (address of entries in lsq)
                   ScanAddr1             : in std_logic_vector (31 downto 0);
                   ScanAddr2             : in std_logic_vector (31 downto 0);
                   ScanAddr3             : in std_logic_vector (31 downto 0);
				   ScanAddr4             : in std_logic_vector (31 downto 0); --scan address (address of entries in lsq)
                   ScanAddr5             : in std_logic_vector (31 downto 0);
                   ScanAddr6             : in std_logic_vector (31 downto 0);
                   ScanAddr7             : in std_logic_vector (31 downto 0);
				   
                   LsqSwAddr             : in std_logic_vector (36 downto 0);  --ld/sw address
                   Cdb_Flush             : in std_logic;
                   Rob_TopPtr         	 : in std_logic_vector (4 downto 0);
                   Cdb_RobDepth          : in std_logic_vector (4 downto 0);
                   StrAddr               : in std_logic;  -- control signal indicating to store address 
                   SB_FlushSw            : in std_logic;  --flush store
				   SB_FlushSwTag         : in std_logic_vector (1 downto 0);    --flush store tag
				   SBTag_counter		 : in std_logic_vector (1 downto 0);	
				   
				   --Interface with ROB
				   Rob_CommitMemWrite    : in std_logic
                  );
end AddBuff;

architecture behave of AddBuff is
    type array_8_32 is array (0 to 7) of std_logic_vector(31 downto 0);  --data
    type array_8_6 is array (0 to 7)   of std_logic_vector(4 downto 0);  --ROBtag
	type array_8_2 is array (0 to 7)   of std_logic_vector(1 downto 0);  --SBtag
	type array_8_1 is array (0 to 7)   of std_logic;  --tagSelect
    
    signal BuffAdd              : array_8_32;
	signal BuffRobTag			: array_8_6;
    signal BufValid             : std_logic_vector (7 downto 0); --buffer valid
    signal BufferDepth          : array_8_6;
    signal BuffSBTag			: array_8_2; 
	signal BuffTagSel			: array_8_1; 
	---Mod OAR: 24 Jul 09: Added one Flush
    signal Flush                : std_logic_vector ( 8 downto 0);
	signal En                   : std_logic_vector ( 6 downto 0); 
    
    signal  AddrMatch0NumTemp   : std_logic_vector(2 downto 0);
    signal  AddrMatch1NumTemp   : std_logic_vector(2 downto 0);
    signal  AddrMatch2NumTemp   : std_logic_vector(2 downto 0);
    signal  AddrMatch3NumTemp   : std_logic_vector(2 downto 0);
    signal  AddrMatch4NumTemp   : std_logic_vector(2 downto 0);
    signal  AddrMatch5NumTemp   : std_logic_vector(2 downto 0);
    signal  AddrMatch6NumTemp   : std_logic_vector(2 downto 0);
    signal  AddrMatch7NumTemp   : std_logic_vector(2 downto 0);
    
    begin 
     --***********************************************************************************************
     -- The following 7 processes are used to perform associative search required for Memory Disambiguation.
	 -- Since we have 8 entries in the load/store issue queue (LSQ) then we need 8 processes one for each memory 
	 -- address (ScanAddr). The associative search is combinational and is implemented for every memory address
     -- in LSQ regardless whether the instruction in LSQ is Load or Store. However, we just need the results of the
     -- associative search for Load instructions.

	 -- Task1: You are given the code completed for generating the number of matches for the first 7 addresses in 
	 -- LSQ (ScanAddr0 to ScanAddr6). You are required to Add the code for the associative search of matches to
	 -- "ScanAddr7".
     --***********************************************************************************************	 
    process (ScanAddr0 ,BuffAdd ,BufValid) 
        variable Add0MatchTemp : std_logic_vector (2 downto 0);
			
        begin
            Add0MatchTemp := "000";
            for  i in 0 to 7 loop
              if (BuffAdd(i) = ScanAddr0  and  BufValid(i) = '1') then --valid and address matched 
                Add0MatchTemp := unsigned(Add0MatchTemp) + 1;   -- increment address match index
			  else
                Add0MatchTemp := Add0MatchTemp;
              end if;
            end loop;  
            AddrMatch0NumTemp <= Add0MatchTemp;
        end process;  
   
    process (ScanAddr1 ,BuffAdd,BufValid ) 
        variable Add1MatchTemp : std_logic_vector (2 downto 0);
      
	    begin
            Add1MatchTemp := "000";
            for  i in 0 to 7 loop
              if (BuffAdd(i) = ScanAddr1  and  BufValid(i) = '1') then 
                Add1MatchTemp := unsigned(Add1MatchTemp) + 1; 
              else
                Add1MatchTemp := Add1MatchTemp;
              end if;
            end loop;
            AddrMatch1NumTemp <= Add1MatchTemp;
    end process;

    process (ScanAddr2 ,BuffAdd ,BufValid) 
        variable Add2MatchTemp : std_logic_vector (2 downto 0);
        
		begin
            Add2MatchTemp := "000";
            for i in 0 to 7 loop
              if (BuffAdd(i) = ScanAddr2  and  BufValid(i) = '1') then 
                Add2MatchTemp := unsigned(Add2MatchTemp) + 1; 
              else
                Add2MatchTemp := Add2MatchTemp;
              end if;
            end loop; 
            AddrMatch2NumTemp <=Add2MatchTemp;
    end process ;

    process (ScanAddr3 ,BuffAdd ,BufValid) 
        variable Add3MatchTemp : std_logic_vector (2 downto 0);
 
        begin      
            Add3MatchTemp := "000";
            for  i in 0 to 7 loop
              if (BuffAdd(i) = ScanAddr3  and  BufValid(i) = '1') then 
                Add3MatchTemp := unsigned(Add3MatchTemp) + 1; 
              else
                Add3MatchTemp := Add3MatchTemp;
              end if;
            end loop; 
            AddrMatch3NumTemp <= Add3MatchTemp;
    end process ;
	
	process (ScanAddr4 ,BuffAdd ,BufValid) 
        variable Add4MatchTemp : std_logic_vector (2 downto 0);
 
        begin      
            Add4MatchTemp := "000";
            for  i in 0 to 7 loop
              if (BuffAdd(i) = ScanAddr4  and  BufValid(i) = '1') then 
                Add4MatchTemp := unsigned(Add4MatchTemp) + 1; 
              else
                Add4MatchTemp := Add4MatchTemp;
              end if;
            end loop; 
            AddrMatch4NumTemp <= Add4MatchTemp;
    end process ;
	
	process (ScanAddr5 ,BuffAdd ,BufValid) 
        variable Add5MatchTemp : std_logic_vector (2 downto 0);
 
        begin      
            Add5MatchTemp := "000";
            for  i in 0 to 7 loop
              if ( BuffAdd(i) = ScanAddr5  and  BufValid(i) = '1' ) then 
                Add5MatchTemp := unsigned(Add5MatchTemp) + 1; 
              else
                Add5MatchTemp := Add5MatchTemp;
              end if;
            end loop; 
            AddrMatch5NumTemp <= Add5MatchTemp;
    end process;
	
	process (ScanAddr6 ,BuffAdd ,BufValid) 
        variable Add6MatchTemp : std_logic_vector (2 downto 0);
 
        begin      
            Add6MatchTemp := "000";
            for  i in 0 to 7 loop
              if (BuffAdd(i) = ScanAddr6  and  BufValid(i) = '1') then 
                Add6MatchTemp := unsigned(Add6MatchTemp) + 1; 
              else
                Add6MatchTemp := Add6MatchTemp;
              end if;
            end loop; 
            AddrMatch6NumTemp <= Add6MatchTemp;
    end process;
	
	process (ScanAddr7 ,BuffAdd ,BufValid) 
        -- Add your Task1 Code here
		----------------------------------------------------------------------
		----------------------------------------------------------------------
		----------------------------------------------------------------------
		----------------------------------------------------------------------
    end process;


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- After we generate the internal Signals for the number of matches for each of the memory addresses
-- in LSQ (ScanAddr0 to ScanAddr7). We need to map the internal signals to the corresponding output ports
-- (AddrMatch0Num to AddrMatch7Match). At the same time we set the bit that indicates that there was at 
-- least one match for each of the input addresses.

-- Task2: Add you code to map the matching results of ScanAddr7 to their respective output ports.
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	process (AddrMatch0NumTemp)  --depending upon address match index
		begin
			AddrMatch0  <= '0';
			AddrMatch0Num <= "000";
			if (AddrMatch0NumTemp > "000") then         
				AddrMatch0  <= '1';   --just make a note that address is matched        
				AddrMatch0Num <= AddrMatch0NumTemp;
			end if;        
	end process ; 

	process (AddrMatch1NumTemp)
		begin
			AddrMatch1  <= '0';
			AddrMatch1Num <= "000";
			if (AddrMatch1NumTemp > "000") then         
				AddrMatch1  <= '1';
				AddrMatch1Num <= AddrMatch1NumTemp;
			end if;
	end process;    
 
	process (AddrMatch2NumTemp)
		begin
			AddrMatch2  <= '0';
			AddrMatch2Num <= "000";
			if ( AddrMatch2NumTemp > "000") then         
				AddrMatch2  <= '1';
				AddrMatch2Num <= AddrMatch2NumTemp;        
		end if;
	end process;  
 
	process (AddrMatch3NumTemp)
		begin
			AddrMatch3  <= '0';
			AddrMatch3Num <= "000";
			if (AddrMatch3NumTemp > "000") then         
				AddrMatch3  <= '1';
				AddrMatch3Num <= AddrMatch3NumTemp; 
			end if;
	end process;

	process (AddrMatch4NumTemp)
		begin
			AddrMatch4  <= '0';
			AddrMatch4Num <= "000";
			if (AddrMatch4NumTemp > "000") then         
				AddrMatch4  <= '1';
				AddrMatch4Num <= AddrMatch4NumTemp; 
			end if;
	end process; 
	
	process (AddrMatch5NumTemp)
		begin
			AddrMatch5  <= '0';
			AddrMatch5Num <= "000";
			if (AddrMatch5NumTemp > "000") then         
				AddrMatch5  <= '1';
				AddrMatch5Num <= AddrMatch5NumTemp; 
			end if;
	end process; 
	
	process (AddrMatch6NumTemp)
		begin
			AddrMatch6  <= '0';
			AddrMatch6Num <= "000";
			if (AddrMatch6NumTemp > "000") then         
				AddrMatch6  <= '1';
				AddrMatch6Num <= AddrMatch6NumTemp; 
			end if;
	end process; 
	
	process (AddrMatch7NumTemp)
		begin
		-- Add you Task2 code here
		----------------------------------------------------------------------
		----------------------------------------------------------------------
		----------------------------------------------------------------------
		----------------------------------------------------------------------
	end process; 
 
   --*************************************************************************************************************
   -- This process is used to calculate Rob depth of all entries in address buffer to perform selective flushing in case of
   -- branch misprediction. The Rob depth is the distance between the Rob entry of the instruction in the address buffer 
   -- and the Rob top pointer taking into consideration the fact that ROB is implemented as a circular buffer.

   -- Task3: In this task we want to use the RobTag field of each address buffer entry (BuffRobTag array) to calculate
   -- the Rob depth field of each entry (BufferDepth array). 
   --*************************************************************************************************************
    
    process (BuffRobTag,Rob_TopPtr)  --using buffer tag and rob pointer
       -- Add your code for Task3 here
	   ----------------------------------------------------------------------
	   ----------------------------------------------------------------------
	   ----------------------------------------------------------------------
	   ----------------------------------------------------------------------
	end process;
		
   --********************************************************************************************************************
   -- The value of the Depth you calculated in the previous process is used to decide whether the address buffer entry 
   -- must be flushed in case of branch misprediction or not. This of course depends on the Rob Depth of the mispredicted 
   -- branch and Rob Depth of the store instruction in the address buffer. When the branch Rob depth is smaller than the
   -- Rob depth of address buffer entry then that entry is younger than the branch and hence must be flushed. This is known as
   -- selective Flushing and is done once the branch instruction appears on Cdb and is mispredicted.
   
   -- The following process is a very important process which takes care of generating the Flush signal of every 
   -- entry in the address buffer. There are two reasons for flushing address buffer entries:
   -- 1) Selective flushing due to branch misprediction provided that the entry Rob depth is larger than that of the 
   --    mispredicted branch.
   -- 2) When a store instruction writes to the cache and leaves the store buffer, we need to flush the corresponding
   --    entry of that store in the address buffer. In this case need to use the SBTag to identify the address buffer
   --    entry that must be flushed becasue the RobTag is released when the store instruction leaves the top of the
   --    and enters the store buffer.
    
   -- Task4: Write the code of the flushing process:
   -- Hints: 1. Cdb_RobDepth in the sensitivity list is the Rob depth of the instruction that is currently on Cdb, so before decide
   --           if you need to flush or not, you have to check Cdb_Flush input signal that indicates that the instruction on Cdb is
   --  			a mispredicted branch.
   --		 2. You need to check the TagSel when you flush. if you are doing selective flushing and TagSel of one entry is set to 1
   --			then there is no need to flush that entry because it belongs to a store instruction that has already left ROB and is
   --           waiting in the store buffer to write to the cache. The same thing happen when you are flushing the entry of the store
   --			which just finished writing to the cache, you need to check the TagSel, if it set to 0 then that entry belongs to a store
   --           instruction which still in the ROB and hence it can NOT be the desired entry.
   --		 3. There is only a single Flush bit per address buffer entry. This is enough because once a store instruction leaves ROB it 
   --			should never be flushed due to mis-prediction buffer but it needs to be flushed when the store leaves store buffer. This means
   --			you can check both flush conditions mentioned above concurrently for each address buffer entry but at most one of the conditions
   --			will set the Flush bit of that entry.			
    
   -- Flush(8) Special Case: Although we have 8 entries in address buffer and hence we just need 8-bit Flush signal (Flush[7:0]), we
   -- one more additional bit namely (Flush[8]) to count for the case when a new store instruction is writing its address to the address 
   -- buffer at the same time when the Cdb_Flush signal becomes active. This case is already completed for you. 
   --********************************************************************************************************************
   
	Flush(8) <= '1' when ((StrAddr = '1') AND (((unsigned(LsqSwAddr(36 downto 32))-unsigned(Rob_TopPtr))>Cdb_RobDepth)and Cdb_Flush = '1')) 
				 else '0';
   
    process (Cdb_Flush,Cdb_RobDepth,SB_FlushSw,SB_FlushSwTag,BufferDepth,BuffSBTag,BuffTagSel)	
		-- Add you code for Task4 here
        ----------------------------------------------------------------------
		----------------------------------------------------------------------
		----------------------------------------------------------------------
		----------------------------------------------------------------------		
    end process;


    -- **************************************************************************************************
	-- This process generates the shift enable signal that shifts all the entries in the address buffer.
	-- As soon as you get a hole (empty entry) you shift all the upper entries down to fill it so that
	-- A new entry is always written to the topmost location
	-- **************************************************************************************************
    process ( BufValid ) 
        begin              
            if (BufValid(0) = '0') then 
                En(6 downto 0) <= "1111111"; --bottom is invalid(issued) so update all
            elsif(BufValid(1) = '0') then
                En(6 downto 0) <= "1111110";
            elsif (BufValid(2) = '0' ) then
                En(6 downto 0) <= "1111100";
			elsif(BufValid(3) = '0') then
                En(6 downto 0) <= "1111000";
            elsif (BufValid(4) = '0' ) then
                En(6 downto 0) <= "1110000";
			elsif(BufValid(5) = '0') then
                En(6 downto 0) <= "1100000";
            elsif (BufValid(6) = '0' ) then
                En(6 downto 0) <= "1000000";	
            else
                En(6 downto 0) <= "0000000";  -- since except the top most others contain valid instruction so can't update, actually this allows the valid instruction to shift down 
            end if;            
    end process;
    
    --if all entries are valid then address buffer full
    AddrBuffFull <= Bufvalid(7) and BufValid(6) and Bufvalid(5) and Bufvalid(4) and BufValid(3) 
					and BufValid(2) and BufValid(1) and BufValid(0); 
                       
    
	-- **************************************************************************************************
	-- This is core clocked process used to update the address buffer entries. At Reset we set the Valid and the TagSel bits to '0'.
	-- Since new store instructions write to the top most entry (entry(7)), we have a separate if statement for entry 7. For all other 
	-- entries (entry(6) to entry(0) we use a for loop.
	
	-- Task5 is divided into two parts:
	-- 1) You need to complete the last elsif condition for address buffer entry(7). This condition handles the communication 
    --	  with the ROB. Basically you need to decide how should you update the different fields of address buffer entry(7) especially
	--	  SBTag field and TagSel field.
	-- 2) You need to complete the else codition in for loop below. This else condition handle the case when no shift is required. How
	--    would you update the different fields of the address buffer entries(6 to 0).
    -- Hint: In Both parts give careful thinking on what you are going to write in SBTag and TagSel fields. You may need to include a nested
    --       if statement.	
	-- **************************************************************************************************
	
	process (Clk,Resetb) 
        begin
            if (Resetb  = '0') then 
                BufValid <= "00000000";
				BuffTagSel <= "00000000"; 
            elsif (Clk'event and Clk = '1') then
				-- store the "sw" information always at the top 
				if (Flush(8) = '1') then		---if it's to be flushed don't update
					BuffAdd(7)  <= (others => '0');
					BuffRobTag(7)  <= (others => '0');
					BufValid(7) <= '0';
					BuffSBTag(7) <= (others => '0'); 
					BuffTagSel(7) <= '0';			 
				elsif (straddr = '1') then			---else put the incoming value on the top location.
					BuffAdd(7)  <= LsqSwAddr( 31 downto 0 );
					BuffRobTag(7)  <= LsqSwAddr( 36 downto 32 );
					BufValid(7) <= '1';
					BuffSBTag(7) <= (others => '0'); 
					BuffTagSel(7) <= '0';			 
				elsif (En(6) = '1') then			---else the next person is getting my values so I must go empty.
					BuffAdd(7)  <= (others => '0');
					BuffRobTag(7)  <= (others => '0');
					BufValid(7) <= '0';
					BuffSBTag(7) <= (others => '0'); 
					BuffTagSel(7) <= '0';			 
				elsif (Flush(7) = '1') then		---there is an instruction at the 15th location that is decided to be flushed. Mod25Jul09.
                    BuffAdd(7)  <= (others => '0');
                    BuffRobTag(7)  <= (others => '0');
                    BufValid(7) <= '0';
					BuffSBTag(7) <= (others => '0'); 
					BuffTagSel(7) <= '0';			
				elsif Rob_CommitMemWrite = '1' then
					-- Add your code for Task5 part1 here
					----------------------------------------------------------------------
					----------------------------------------------------------------------
					----------------------------------------------------------------------
					----------------------------------------------------------------------
					end if;	
				end if;
				

                for i in 0 to 6 loop   --shift the others accordingly
                  if (Flush(i) = '1' and En(i) = '0') then 
                    BuffAdd(i)  <= (others => '0');
                    BuffRobTag(i)  <= (others => '0');
                    BufValid(i) <= '0';
					BuffSBTag(i) <= (others => '0'); 
					BuffTagSel(i) <= '0';			 				
                  else
                    if (En(i) = '1') then   --shift update
						BuffAdd(i)  <= BuffAdd(i+1);
                        BuffRobTag(i)  <=  BuffRobTag(i+1);
                        BufValid(i) <=  BufValid(i+1) and (not Flush(i+1)); --update , note the use of flush signal while updation
						if ((Rob_CommitMemWrite = '1') and (BuffRobTag(i+1) = Rob_TopPtr) and (BuffTagSel(i+1) = '0'))then
							BuffSBTag(i) <= SBTag_counter;
							BuffTagSel(i) <= '1';
						else
							BuffSBTag(i) <= BuffSBTag(i+1);
							BuffTagSel(i) <= BuffTagSel(i+1);
						end if;
                    else
                        -- Add your code for Task5 part2 here
						---------------------------------------------------------------------- when we are not shiftingo
						----------------------------------------------------------------------
						----------------------------------------------------------------------
						----------------------------------------------------------------------		
                    end if;
                  end if;
                end loop;
            end if;
    end process;   
end behave; 