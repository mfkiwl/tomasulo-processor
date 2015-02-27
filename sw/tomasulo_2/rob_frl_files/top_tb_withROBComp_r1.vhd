-------------------------------------------------------------------------------
-- Design   : Signal Spy testbench for Reorder Buffer
-- Project  : Tomasulo Processor 
-- Author   : Da Cheng
-- Data		: June,2010
-- Company  : University of Southern California 
-------------------------------------------------------------------------------
library std,ieee;
library modelsim_lib;
use ieee.std_logic_1164.all;
use modelsim_lib.util.all;
use std.textio.all;
use ieee.std_logic_textio.all;
library ee560; 
use ee560.all;

-----------------------------------------------------------------------------
entity top_tb is
end entity top_tb;

architecture arch_top_tb_ROB of top_tb is

-- local signals
	signal Clk, Reset: std_logic;

-- clock period
	constant Clk_Period: time:= 20 ns;
-- clock count signal to make it easy for debugging
	signal Clk_Count: integer range 0 to 999;
-- a 10% delayed clock for clock counting
	signal Clk_Delayed10: std_logic;
	signal Walking_Led: std_logic;
	signal Fio_Icache_Addr_IM: std_logic_vector(5 downto 0);
	signal Fio_Icache_Data_In_IM: std_logic_vector(127 downto 0);
	signal Fio_Icache_Wea_IM: std_logic; 
	signal Fio_Icache_Data_Out_IM: std_logic_vector(127 downto 0);
	signal Fio_Icache_Ena_IM		: std_logic;

	signal Fio_Dmem_Addr_DM: std_logic_vector(5 downto 0);
	signal Fio_Dmem_Data_Out_DM: std_logic_vector(31 downto 0);	

	signal Fio_Dmem_Data_In_DM: std_logic_vector(31 downto 0);
	signal Fio_Dmem_Wea_DM    		: std_logic;
	
-- Hierarchy signals (Golden ROB)
    signal  Rob_Full_gold,Rob_TwoOrMoreVacant_gold,Rob_CommitMemWrite_gold,Rob_Commit_gold,Rob_CommitRegWrite_gold: std_logic  ;
    signal  Rob_CommitPrePhyAddr_gold,Rob_CommitCurrPhyAddr_gold: std_logic_vector(5 downto 0);
    signal  Rob_SwAddr_gold: std_logic_vector(31 downto 0);
	signal  Rob_TopPtr_gold,Rob_BottomPtr_gold,Rob_CommitRdAddr_gold: std_logic_vector(4 downto 0);
	signal  Rob_Instruction_gold:std_logic_vector(31 downto 0);

-- Signals for the student's DUT (ROB)
    signal	Resetb: std_logic;
    signal  Cdb_Valid,Dis_InstSw,Dis_RegWrite,Dis_InstValid,Rob_Full,Rob_TwoOrMoreVacant,SB_Full,Rob_CommitMemWrite,Rob_Commit,Rob_CommitRegWrite,Cdb_Flush: std_logic  ;
    signal  Dis_NewRdPhyAddr,Dis_PrevPhyAddr,Dis_SwRtPhyAddr,Rob_CommitPrePhyAddr,Rob_CommitCurrPhyAddr: std_logic_vector(5 downto 0);
    signal  Cdb_SwAddr,Rob_SwAddr: std_logic_vector(31 downto 0);
	signal  Dis_RobRdAddr,Cdb_RobTag,Rob_TopPtr,Rob_BottomPtr,Cfc_RobTag,Rob_CommitRdAddr: std_logic_vector(4 downto 0);
	signal Rob_Instruction,Dis_instruction:std_logic_vector(31 downto 0);
 -- component declaration
	component tomasulo_top
	port (
		Reset     : in std_logic;
		--digi_address    : in std_logic_vector(5 downto 0); -- input ID for the register we want to see
		--digi_data : out std_logic_vector(31 downto 0); -- output data given by the register
		Clk : in std_logic;
		-- signals corresponding to Instruction memory
		Fio_Icache_Addr_IM  : in  std_logic_vector(5 downto 0);
		Fio_Icache_Data_In_IM     : in  std_logic_vector(127 downto 0);
		Fio_Icache_Wea_IM   : in  std_logic; 
		Fio_Icache_Data_Out_IM    : out std_logic_vector(127 downto 0);
		Fio_Icache_Ena_IM		     : in  std_logic;

		Fio_Dmem_Addr_DM    : in std_logic_vector(5 downto 0);
		Fio_Dmem_Data_Out_DM: out std_logic_vector(31 downto 0);	

		Fio_Dmem_Data_In_DM : in std_logic_vector(31 downto 0);
		Fio_Dmem_Wea_DM    		  : in std_logic;

		Test_mode     : in std_logic; -- for using the test mode 

		Walking_Led_start   : out std_logic
	);
	end component tomasulo_top;
	
	component rob
	port (                
			  Clk				 :in std_logic;
			  Resetb			   :in std_logic;
			  Cdb_Valid		   : in std_logic;                             -- signal to tell that the values coming on CDB is valid                             
			  Cdb_RobTag	   : in std_logic_vector(4 downto 0);          -- Tag of the instruction which the the CDB is broadcasting
			  Cdb_SwAddr      : in std_logic_vector (31 downto 0);      -- to give the store wordaddr
			  -- Interface with Dispatch unit	
			  Dis_InstSw                 : in std_logic;                      --  signal that tells that the signal being dispatched is a store word
			  Dis_RegWrite                : in std_logic;                      --  signal telling that the instruction is register writing instruction
			  Dis_InstValid              : in std_logic;                      --  Signal telling that Dispatch unit is giving valid information
			  Dis_RobRdAddr                  : in std_logic_vector(4 downto 0);   --  Actual Desitnation register number of the instruction being dispatched
			  Dis_NewRdPhyAddr                 : in std_logic_vector (5 downto 0);   --  Current Physical Register number of dispatching instruction taken by the dispatch unit from the FRL
			  Dis_PrevPhyAddr                  : in std_logic_vector (5 downto 0);    --  Previous Physical Register number of dispatch unit taken from CFC
			  Dis_SwRtPhyAddr               : in std_logic_vector (5 downto 0); -- Physical Address number from where store word has to take the data
			  Rob_Full                    : out std_logic;                        -- Whether the ROB is Full or not
			  Rob_TwoOrMoreVacant                      : out std_logic;          -- Whether there are two or more vacant spot in ROB. Useful because Dispatch is 2 stage and if there is 
			                                                                     --only 1 vacant spot and second stage is dispatching the insturction first stage should not 
																				 -- dispatch any new Instruction		  
			-- translate_off 
				Dis_instruction    : in std_logic_vector(31 downto 0); 
                Rob_Instruction     : out std_logic_vector(31 downto 0);
	        -- translate_on
						  
			  -- Interface with store buffer
			  SB_Full                     : in std_logic;                     -- Tells the ROB that the store buffer is full
			  Rob_SwAddr                  : out std_logic_vector (31 downto 0);   -- The address in case of sw instruction
			  Rob_CommitMemWrite                : out std_logic;                        -- Signal to enable the memory for writing purpose  
			 -- Rob_FlushSw                 : out std_logic;  -- for address buffer of lsq 
			 -- Rob_FlushSwTag              : out std_logic_vector (5 downto 0);
			  -- Takes care of flushing the address buffer
			  -- Interface with FRL and CFC
			  
			  Rob_TopPtr                  : out std_logic_vector (4 downto 0);  -- Gives the value of TopPtr pointer of ROB
			  Rob_BottomPtr               : out std_logic_vector (4 downto 0);  -- Gives the Bottom Pointer of ROB
		      Rob_Commit                  : out std_logic;          -- FRL needs it to to add pre phy to free list cfc needs it to remove the latest cheackpointed copy
		      Rob_CommitRdAddr                 : out std_logic_vector(4 downto 0);           -- Architectural register number of committing instruction
		      Rob_CommitRegWrite               : out std_logic;					          --Indicates that the instruction that is being committed is a register wrtiting instruction
		      Rob_CommitPrePhyAddr                 : out std_logic_vector(5 downto 0);			  --pre physical addr of committing inst to be added to FRL
		      Rob_CommitCurrPhyAddr                : out std_logic_vector (5 downto 0);   -- Current Register Address of committing instruction to update retirment rat			  
		      Cdb_Flush  		         :in std_logic;                              --Flag indicating that current instruction is mispredicted or not
		      Cfc_RobTag             : in std_logic_vector (4 downto 0)  -- Tag of the instruction that has the checkpoint		
	);
	end component rob;
	-----------------------------
 	for 	ROB_UUT: rob use entity work.rob(rob_arch);
	-----------------------------
	begin
	
	UUT: tomasulo_top
	port map (
		Reset  =>   Reset,
		Clk    =>   Clk,
		Fio_Icache_Addr_IM     => Fio_Icache_Addr_IM,
		Fio_Icache_Data_In_IM  => Fio_Icache_Data_In_IM, 
		Fio_Icache_Wea_IM=> Fio_Icache_Wea_IM , 
		Fio_Icache_Data_Out_IM => Fio_Icache_Data_Out_IM,
		Fio_Icache_Ena_IM		    => Fio_Icache_Ena_IM,
		Fio_Dmem_Addr_DM => Fio_Dmem_Addr_DM,
		Fio_Dmem_Data_Out_DM   => Fio_Dmem_Data_Out_DM,	
		Fio_Dmem_Data_In_DM    => Fio_Dmem_Data_In_DM,
		Fio_Dmem_Wea_DM    		  => Fio_Dmem_Wea_DM,
		Test_mode  => '0',  
		Walking_Led_start=> Walking_Led
    );

	ROB_UUT:  rob
	port map (                
			  Clk					=> Clk,
			  Resetb	   	 		=> Resetb,
			  Cdb_Valid	    		=> Cdb_Valid,                           
			  Cdb_RobTag			=> Cdb_RobTag,
			  Cdb_SwAddr    		=> Cdb_SwAddr,
			  Dis_InstSw    		=> Dis_InstSw,
			  Dis_RegWrite  		=> Dis_RegWrite,
			  Dis_InstValid 		=> Dis_InstValid,
			  Dis_RobRdAddr 		=> Dis_RobRdAddr,     
			  Dis_NewRdPhyAddr 		=> Dis_NewRdPhyAddr,
			  Dis_PrevPhyAddr 		=> Dis_PrevPhyAddr,
			  Dis_SwRtPhyAddr 		=> Dis_SwRtPhyAddr,
			  Rob_Full 				=> Rob_Full,
			  Rob_TwoOrMoreVacant	=> Rob_TwoOrMoreVacant,
			  Dis_instruction		=> Dis_instruction,
			  Rob_Instruction		=> Rob_Instruction,
			  SB_Full 				=> SB_Full,
			  Rob_SwAddr			=> Rob_SwAddr,
			  Rob_CommitMemWrite	=> Rob_CommitMemWrite,
			  Rob_TopPtr			=> Rob_TopPtr,
			  Rob_BottomPtr			=> Rob_BottomPtr,
			  Rob_Commit			=> Rob_Commit,
			  Rob_CommitRdAddr      => Rob_CommitRdAddr,        
			  Rob_CommitRegWrite    => Rob_CommitRegWrite,              
			  Rob_CommitPrePhyAddr  => Rob_CommitPrePhyAddr,                
			  Rob_CommitCurrPhyAddr => Rob_CommitCurrPhyAddr,
			  Cdb_Flush				=> Cdb_Flush,
			  Cfc_RobTag			=> Cfc_RobTag
			  ); 

	clock_generate: process
	begin
	  Clk <= '0', '1' after (Clk_Period/2);
	  wait for Clk_Period;
	end process clock_generate;
	
	-- Reset activation and inactivation
	  Reset <= '1', '0' after (Clk_Period * 4.1 );
	  Clk_Delayed10 <= Clk after (Clk_Period/10);
	-- clock count processes
	Clk_Count_process: process (Clk_Delayed10, Reset)
	      begin
			if Reset = '1' then
	      	  Clk_Count <= 0;
	      	elsif Clk_Delayed10'event and Clk_Delayed10 = '1' then
	      	  Clk_Count <= Clk_Count + 1;  
	      	end if;
	      end process Clk_Count_process;
-------------------------------------------------
		  --check outputs of ROB only--
-------------------------------------------------
	compare_outputs_Clkd: process (Clk_Delayed10, Reset)
		file my_outfile: text open append_mode is "TomasuloCompareTestLog.log";
		variable my_inline, my_outline: line;

		begin
			if (Reset = '0' and (Clk_Delayed10'event and Clk_Delayed10 = '0')) then			--- 10%after the middle of the clock.
				if (Rob_Full_gold /= Rob_Full) then
					write (my_outline, string'("ERROR! Rob_Full of TEST does not match Rob_Full_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Rob_TwoOrMoreVacant_gold /= Rob_TwoOrMoreVacant) then
					write (my_outline, string'("ERROR! Rob_TwoOrMoreVacant of TEST does not match Rob_TwoOrMoreVacant_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Rob_Instruction_gold /= Rob_Instruction) then
					write (my_outline, string'("ERROR! Rob_Instruction of TEST does not match Rob_Instruction_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Rob_SwAddr_gold /= Rob_SwAddr) then
					write (my_outline, string'("ERROR! Rob_SwAddr of TEST does not match Rob_SwAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Rob_CommitMemWrite_gold /= Rob_CommitMemWrite) then
					write (my_outline, string'("ERROR! Rob_CommitMemWrite of TEST does not match Rob_CommitMemWrite_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Rob_TopPtr_gold /= Rob_TopPtr) then
					write (my_outline, string'("ERROR! Rob_TopPtr of TEST does not match Rob_TopPtr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Rob_BottomPtr_gold /= Rob_BottomPtr) then
					write (my_outline, string'("ERROR! Rob_BottomPtr of TEST does not match Rob_BottomPtr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Rob_Commit_gold /= Rob_Commit) then
					write (my_outline, string'("ERROR! Rob_Commit of TEST does not match Rob_Commit_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Rob_CommitRdAddr_gold /= Rob_CommitRdAddr) then
					write (my_outline, string'("ERROR! Rob_CommitRdAddr of TEST does not match Rob_CommitRdAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Rob_CommitRegWrite_gold /= Rob_CommitRegWrite) then
					write (my_outline, string'("ERROR! Rob_CommitRegWrite of TEST does not match Rob_CommitRegWrite_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Rob_CommitPrePhyAddr_gold /= Rob_CommitPrePhyAddr) then
					write (my_outline, string'("ERROR! Rob_CommitPrePhyAddr of TEST does not match Rob_CommitPrePhyAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Rob_CommitCurrPhyAddr_gold /= Rob_CommitCurrPhyAddr) then
					write (my_outline, string'("ERROR! Rob_CommitCurrPhyAddr of TEST does not match Rob_CommitCurrPhyAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
			end if;
		end process compare_outputs_Clkd;
		
	spy_process: process
		begin
--inputs
			init_signal_spy("/UUT/Resetb","Resetb",1,1);
			enable_signal_spy("/UUT/Resetb","Resetb",0);

			init_signal_spy("/UUT/Cdb_Valid","Cdb_Valid",1,1);
			enable_signal_spy("/UUT/Cdb_Valid","Cdb_Valid",0);
			
			init_signal_spy("/UUT/Cdb_RobTag","Cdb_RobTag",1,1);
			enable_signal_spy("/UUT/Cdb_RobTag","Cdb_RobTag",0);
			
			init_signal_spy("/UUT/Cdb_SwAddr","Cdb_SwAddr",1,1);
			enable_signal_spy("/UUT/Cdb_SwAddr","Cdb_SwAddr",0);
			
			init_signal_spy("/UUT/Dis_InstSw","Dis_InstSw",1,1);
			enable_signal_spy("/UUT/Dis_InstSw","Dis_InstSw",0);
			
			init_signal_spy("/UUT/Dis_RegWrite","Dis_RegWrite",1,1);
			enable_signal_spy("/UUT/Dis_RegWrite","Dis_RegWrite",0);
			
			init_signal_spy("/UUT/Dis_InstValid","Dis_InstValid",1,1);
			enable_signal_spy("/UUT/Dis_InstValid","Dis_InstValid",0);
			
			init_signal_spy("/UUT/Dis_RobRdAddr","Dis_RobRdAddr",1,1);
			enable_signal_spy("/UUT/Dis_RobRdAddr","Dis_RobRdAddr",0);

			init_signal_spy("/UUT/Dis_NewRdPhyAddr","Dis_NewRdPhyAddr",1,1);
			enable_signal_spy("/UUT/Dis_NewRdPhyAddr","Dis_NewRdPhyAddr",0);
			
			init_signal_spy("/UUT/Dis_PrevPhyAddr","Dis_PrevPhyAddr",1,1);
			enable_signal_spy("/UUT/Dis_PrevPhyAddr","Dis_PrevPhyAddr",0);
			
			init_signal_spy("/UUT/Dis_SwRtPhyAddr","Dis_SwRtPhyAddr",1,1);
			enable_signal_spy("/UUT/Dis_SwRtPhyAddr","Dis_SwRtPhyAddr",0);
			
			init_signal_spy("/UUT/Dis_instruction","Dis_instruction",1,1);
			enable_signal_spy("/UUT/Dis_instruction","Dis_instruction",0);
						
			
	   
			init_signal_spy("/UUT/SB_Full","SB_Full",1,1);
			enable_signal_spy("/UUT/SB_Full","SB_Full",0);
			
			init_signal_spy("/UUT/Cdb_Flush","Cdb_Flush",1,1);
			enable_signal_spy("/UUT/Cdb_Flush","Cdb_Flush",0);
			
			init_signal_spy("/UUT/Cfc_RobTag","Cfc_RobTag",1,1);
			enable_signal_spy("/UUT/Cfc_RobTag","Cfc_RobTag",0);
			
--outputs--
			init_signal_spy("/UUT/Rob_Full","Rob_Full_gold",1,1);
			enable_signal_spy("/UUT/Rob_Full","Rob_Full_gold",0);
			
			init_signal_spy("/UUT/Rob_TwoOrMoreVacant","Rob_TwoOrMoreVacant_gold",1,1);
			enable_signal_spy("/UUT/Rob_TwoOrMoreVacant","Rob_TwoOrMoreVacant_gold",0);
			
			init_signal_spy("/UUT/Rob_Instruction","Rob_Instruction_gold",1,1);
			enable_signal_spy("/UUT/Rob_Instruction","Rob_Instruction_gold",0);
			
			init_signal_spy("/UUT/Rob_SwAddr","Rob_SwAddr_gold",1,1);
			enable_signal_spy("/UUT/Rob_SwAddr","Rob_SwAddr_gold",0);
			
			init_signal_spy("/UUT/Rob_CommitMemWrite","Rob_CommitMemWrite_gold",1,1);
			enable_signal_spy("/UUT/Rob_CommitMemWrite","Rob_CommitMemWrite_gold",0);
			
			init_signal_spy("/UUT/Rob_TopPtr","Rob_TopPtr_gold",1,1);
			enable_signal_spy("/UUT/Rob_TopPtr","Rob_TopPtr_gold",0);
			
			init_signal_spy("/UUT/Rob_BottomPtr","Rob_BottomPtr_gold",1,1);
			enable_signal_spy("/UUT/Rob_BottomPtr","Rob_BottomPtr_gold",0);
			
			init_signal_spy("/UUT/Rob_Commit","Rob_Commit_gold",1,1);
			enable_signal_spy("/UUT/Rob_Commit","Rob_Commit_gold",0);
			
			
			init_signal_spy("/UUT/Rob_CommitRdAddr","Rob_CommitRdAddr_gold",1,1);
			enable_signal_spy("/UUT/Rob_CommitRdAddr","Rob_CommitRdAddr_gold",0);
			
				
			init_signal_spy("/UUT/Rob_CommitRegWrite","Rob_CommitRegWrite_gold",1,1);
			enable_signal_spy("/UUT/Rob_CommitRegWrite","Rob_CommitRegWrite_gold",0);
			
				
			init_signal_spy("/UUT/Rob_CommitPrePhyAddr","Rob_CommitPrePhyAddr_gold",1,1);
			enable_signal_spy("/UUT/Rob_CommitPrePhyAddr","Rob_CommitPrePhyAddr_gold",0);
			
			init_signal_spy("/UUT/Rob_CommitCurrPhyAddr","Rob_CommitCurrPhyAddr_gold",1,1);
			enable_signal_spy("/UUT/Rob_CommitCurrPhyAddr","Rob_CommitCurrPhyAddr_gold",0);
			
		wait;
	end process spy_process;			

end architecture arch_top_tb_ROB;
