-- Modified by Da Cheng in Summer 2010
-------------------------------------------------------------------------------
-- Description: 
-- Reorder buffer is to make sure that the instructions commit in order. 
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rob is
		port( --inputs--
			  clk				   	:in std_logic;
			  Resetb			  	:in std_logic;			  
			  -- Interface with CDB
			  Cdb_Valid		   		: in std_logic;                         -- signal to tell that the values coming on CDB is valid                             
			  Cdb_RobTag	   		: in std_logic_vector(4 downto 0);      -- Tag of the instruction which the the CDB is broadcasting
			  Cdb_SwAddr       		: in std_logic_vector (31 downto 0);    -- to give the store wordaddr
			  --Interface with Dispatch unit	
			  Dis_InstSw            : in std_logic;                      	-- signal that tells that the signal being dispatched is a store word
			  Dis_RegWrite          : in std_logic;                     	-- signal telling that the instruction is register writing instruction
			  Dis_InstValid         : in std_logic;                      	-- Signal telling that Dispatch unit is giving valid information
			  Dis_RobRdAddr         : in std_logic_vector(4 downto 0);      -- Actual Desitnation register number of the instruction being dispatched
			  Dis_NewRdPhyAddr      : in std_logic_vector (5 downto 0);   	-- Current Physical Register number of dispatching instruction taken by the dispatch unit from the FRL
			  Dis_PrevPhyAddr       : in std_logic_vector (5 downto 0);   	-- Previous Physical Register number of dispatch unit taken from CFC
			  Dis_SwRtPhyAddr       : in std_logic_vector (5 downto 0); 	-- Physical Address number from where store word has to take the data
			  Rob_Full              : out std_logic;                        -- Whether the ROB is Full or not
			  Rob_TwoOrMoreVacant   : out std_logic;          	 			-- Whether there are two or more vacant spot in ROB. Useful because Dispatch is 2 stage and if there is 
																			-- only 1 vacant spot and second stage is dispatching the insturction first stage should not 
																			-- dispatch any new Instruction		  
			  --translate_off 
				Dis_instruction    	: in std_logic_vector(31 downto 0); 
                Rob_Instruction     : out std_logic_vector(31 downto 0);
	          --translate_on
						  
			  -- Interface with store buffer
			  SB_Full               : in std_logic;                     	-- Tells the ROB that the store buffer is full
			  Rob_SwAddr            : out std_logic_vector (31 downto 0); 	-- The address in case of sw instruction
			  Rob_CommitMemWrite    : out std_logic;                		-- Signal to enable the memory for writing purpose  

			  -- Interface with FRL and CFC			  
			  Rob_TopPtr            : out std_logic_vector (4 downto 0);  	-- Gives the value of TopPtr pointer of ROB
			  Rob_BottomPtr         : out std_logic_vector (4 downto 0);  	-- Gives the Bottom Pointer of ROB
		      Rob_Commit            : out std_logic;          				-- FRL needs it to to add pre phy to free list cfc needs it to remove the latest cheackpointed copy
		      Rob_CommitRdAddr      : out std_logic_vector(4 downto 0);  	-- Architectural register number of committing instruction
		      Rob_CommitRegWrite    : out std_logic;					    -- Indicates that the instruction that is being committed is a register wrtiting instruction
		      Rob_CommitPrePhyAddr  : out std_logic_vector(5 downto 0);		-- pre physical addr of committing inst to be added to FRL
		      Rob_CommitCurrPhyAddr : out std_logic_vector (5 downto 0);  	-- Current Register Address of committing instruction to update retirment rat			  
		      Cdb_Flush  		    : in std_logic;                        	-- Flag indicating that current instruction is mispredicted or not
		      Cfc_RobTag            : in std_logic_vector (4 downto 0)  	-- Tag of the instruction that has the checkpoint
			  );
end rob;

architecture rob_arch of rob is

subtype bit6 is std_logic_vector(5 downto 0);
type phy_reg is array(0 to 31) of bit6;
signal CurrPhyArray,PrePhyArray: phy_reg;

subtype bit5 is std_logic_vector(4 downto 0);
type rd_addr is array(0 to 31) of bit5;
signal RdAddrArray: rd_addr;

type bit1 is array (0 to 31) of std_logic;
signal RegWriteArray,CompleteArray,MemwriteArray: bit1;

type bit21 is array (0 to 31) of std_logic_vector (20 downto 0);
signal SwAddrArray: bit21;  -- Used to store additional bits of store word address

type bit32 is array (0 to 31) of std_logic_vector (31 downto 0);
-- translate_off
signal Rob_Inst  :bit32;
-- translate_on

signal Internal_Depth	   : std_logic_vector(4 downto 0);
signal TopPtr_temp, BottomPtr_temp : std_logic_vector(5 downto 0);
signal full,commit_s       : std_logic;

begin
	Rob_TopPtr <= TopPtr_temp(4 downto 0);
	Rob_BottomPtr<=BottomPtr_temp(4 downto 0);

	-- when an Instruction gets commited from the ROB all the Information related to thatInstrcution is Broadcasted to that it can be used by others
	Rob_CommitRdAddr <= RdAddrArray(conv_integer(TopPtr_temp(4 downto 0)));
	Rob_CommitRegWrite <= RegWriteArray(conv_integer(TopPtr_temp(4 downto 0)));
	Rob_CommitCurrPhyAddr <= CurrPhyArray (conv_integer(TopPtr_temp(4 downto 0)));
	Rob_CommitPrePhyAddr <= PrePhyArray (conv_integer(TopPtr_temp(4 downto 0)));
	Rob_CommitMemWrite <= MemwriteArray (conv_integer(TopPtr_temp(4 downto 0)));

	-- translate_off  
	Rob_Instruction<=Rob_Inst(conv_integer(TopPtr_temp(4 downto 0)));
	-- translate_on

	Rob_SwAddr(31 downto 27)<= RdAddrArray(CONV_INTEGER(UNSIGNED(TopPtr_temp(4 downto 0))));
	Rob_SwAddr (26 downto 21) <= PrePhyArray(CONV_INTEGER(UNSIGNED(TopPtr_temp(4 downto 0))));
	Rob_SwAddr (20 downto 0) <= SwAddrArray(CONV_INTEGER(UNSIGNED(TopPtr_temp(4 downto 0))));
			
	-- To determine whether the ROB is full or empty we use an additional bit.  ROB becomes full if the MSB of the TopPtr and BottomPtr pointer differ
	-- and all other bits are same 

	full 			<= '1' when ((TopPtr_temp xor BottomPtr_temp) = "100000") else
					'0';
	--Condition to Check whether there is more than 1 vacant spot in the ROB
	Rob_TwoOrMoreVacant     <= '0' when (BottomPtr_temp(4 downto 0)-TopPtr_temp(4 downto 0)>=30) else 
              '1';					
	Rob_Full <= full when commit_s = '0' else '0';

	-- Task 1: 	commit_s signal need to be generated here.
	-- Hint: 	think of all possibilities and conditions to commit one instruction.
	
	commit_s <= ---------------------------------------------------
				---------------------------------------------------
				---------------------------------------------------
				---------------------------------------------------
			
	Rob_Commit <= commit_s;
	-- Task 2.1: Internal_Depth signal need to be generated here.
	-- Hint: Internal_Depth is used to update the bottom pointer when flush (in Task 2.2).
	-- In phase 1, Cfc_RobTag is same as Cdb_RobTag. They differ in phase 2.
	-- Make sure you understand why you generate internal_depth here, that is why you need it in task 2.2
	
	Internal_Depth <= 	---------------------------------------------------
						---------------------------------------------------
						---------------------------------------------------
						
	-- Handling the entry and exit of each instruction, and update TopPtr_temp/BottomPtr_temp signals
	rob_entry_exit: process(clk,Resetb) 
	begin
		if(Resetb = '0') then
			BottomPtr_temp <= (others=>'0');
			TopPtr_temp <= (others=>'0');
			for I in 0 to 31 loop
				RegWriteArray(I) <= '0';
				CompleteArray(I) <= '0';
				MemwriteArray(I) <= '0';
				CurrPhyArray(I) <= (others => '-');
				PrePhyArray(I) <= (others => '-');
				RdAddrArray(I) <= (others => '-');
				SwAddrArray(I) <= (others => '-');
				-- translate_off
				Rob_Inst(I) <= (others=>'0');
				-- translate_on
			end loop;
		elsif(clk'event and clk = '1') then
		-- Once the instruction has been commited, the complete bit of that instruction is set to 0 and TopPtr pointer is incremented by 1
			if( commit_s = '1') then
				CompleteArray(conv_integer(TopPtr_temp(4 downto 0))) <= '0';
				TopPtr_temp <= TopPtr_temp + '1';
			end if;				
			-- Whenever the dispatch unit dispatches one instruction, we take all the information from the dispatch unit and store it at the location 
			-- pointed by our BottomPtr pointer. Then we increment the BottomPtr pointer by 1
			if(Dis_InstValid = '1' and (full='0' or (full = '1' and commit_s = '1'))) then
				RegWriteArray(CONV_INTEGER(UNSIGNED(BottomPtr_temp(4 downto 0)))) <= Dis_RegWrite;   -- make all TopPtr and BottomPtr 4 downto 0
				MemwriteArray(CONV_INTEGER(UNSIGNED(BottomPtr_temp(4 downto 0)))) <= Dis_InstSw;
				CompleteArray(CONV_INTEGER(UNSIGNED(BottomPtr_temp(4 downto 0)))) <= '0';
				BottomPtr_temp <= BottomPtr_temp+1;			
				-- translate_off
				Rob_Inst(CONV_INTEGER(UNSIGNED(BottomPtr_temp(4 downto 0)))) <= Dis_instruction ;
				-- translate_on		
				if (Dis_InstSw = '0') then
					CurrPhyArray(CONV_INTEGER(UNSIGNED(BottomPtr_temp(4 downto 0))))<= Dis_NewRdPhyAddr;
					PrePhyArray(CONV_INTEGER(UNSIGNED(BottomPtr_temp(4 downto 0))))<= Dis_PrevPhyAddr;
					RdAddrArray(CONV_INTEGER(UNSIGNED(BottomPtr_temp(4 downto 0)))) <= Dis_RobRdAddr;
				else	
					CurrPhyArray(CONV_INTEGER(UNSIGNED(BottomPtr_temp(4 downto 0))))<= Dis_SwRtPhyAddr;
				end if;		
			end if;		
			-- Whenever an insturction finishes execution it announced it on the CDB. We will go that that loction and mark it as complete. If it is a 
			-- store word instruction, we also need to store the store word address inside the ROB 
			if (Cdb_Valid = '1') then  -- there is no harm doing it even when cfc jump is true
				CompleteArray(CONV_INTEGER(UNSIGNED(Cdb_RobTag))) <= '1';
				if (MemwriteArray(CONV_INTEGER(UNSIGNED(Cdb_RobTag))) = '1') then
					RdAddrArray(CONV_INTEGER(UNSIGNED(Cdb_RobTag))) <= Cdb_SwAddr ( 31 downto 27);
					PrePhyArray(CONV_INTEGER(UNSIGNED(Cdb_RobTag))) <= Cdb_SwAddr (26 downto 21);
					SwAddrArray(CONV_INTEGER(UNSIGNED(Cdb_RobTag))) <= Cdb_SwAddr (20 downto 0);
				end if;
			end if;
			-- Task 2.2: update bottom pointer using Internal_Depth from Task 2.1.
			-- In case of CDB Flush, we move the bottom Pointer to the instruction that claims flush at CDB, by which we invalidate all the younger Instructions. Think about where you can find this instruction's tag in order to flush all its younger instructions.
			if (Cdb_Flush = '1') then  
			
				---------------------------------------------------
				---------------------------------------------------
				---------------------------------------------------
			
			end if;
		end if;
	end process;	
end rob_arch;
