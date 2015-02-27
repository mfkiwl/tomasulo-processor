-------------------------------------------------------------------------------
-- Design   : Signal Spy testbench for load store queue
-- Project  : Tomasulo Processor 
-- Author   : Prasanjeet Das
-- Data		: July 15,2010
-- Company  : University of Southern California 
-------------------------------------------------------------------------------

library std,ieee;
library modelsim_lib;
use ieee.std_logic_1164.all;
use modelsim_lib.util.all;
use std.textio.all;
use ieee.std_logic_textio.all;

-- synopsys translate_off
--use work.reverseAssemblyFunctionPkg.all;
-- synopsys translate_on
-----------------------------------------------------------------------------

--added by Sabya to use compiled library
library ee560;
use ee560.all;
------------------------------------------------------------------------------

entity top_tb is
end entity top_tb;

architecture arch_top_tb_lsq of top_tb is

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
	
-- Hierarchy signals (Golden lsq)
    -- Global Clk and Resetb Signals
      signal Resetb        : std_logic;

      -- Information to be captured from the CDB (Common Data Bus)
      signal Cdb_RdPhyAddr_gold     : std_logic_vector(5 downto 0);
	  signal Cdb_PhyRegWrite_gold   : std_logic;
      signal Cdb_Valid_gold         : std_logic;

      -- Information from the Dispatch Unit 
      signal Dis_Opcode_gold                     : std_logic; 
      signal Dis_Immediate_gold                  : std_logic_vector(15 downto 0 );
      signal Dis_RsDataRdy_gold                  : std_logic;
      signal Dis_RsPhyAddr_gold                  : std_logic_vector(5 downto 0 ); 
      signal Dis_RobTag_gold                     : std_logic_vector(4 downto 0);
	  signal Dis_NewRdPhyAddr_gold               : std_logic_vector(5 downto 0);
      signal Dis_LdIssquenable_gold              : std_logic; 
      signal Issque_LdStQueueFull_gold           : std_logic;
	  signal Issque_LdStQueueTwoOrMoreVacant_gold: std_logic;
	  signal Dis_instruction_gold                : std_logic_vector(31 downto 0);
	  signal Iss_instructionLsq_gold             : std_logic_vector(31 downto 0);
	  signal Iss_RsPhyAddrLsq_gold               : std_logic_vector(5 downto 0);
	  signal PhyReg_LsqRsData_gold          	 : std_logic_vector(31 downto 0);
	  signal Iss_LdStReady_gold                  : std_logic ;
      signal Iss_LdStOpcode_gold                 : std_logic ;  
      signal Iss_LdStRobTag_gold                 : std_logic_vector(4 downto 0);
      signal Iss_LdStAddr_gold                   : std_logic_vector(31 downto 0); 
      signal Iss_LdStIssued_gold                 : std_logic;
	  signal Iss_LdStPhyAddr_gold                : std_logic_vector(5 downto 0);
      signal DCE_ReadBusy_gold                   : std_logic;
      signal Lsbuf_Done_gold                     : std_logic;
      signal Cdb_Flush_gold                      : std_logic;
      signal Rob_TopPtr_gold                     : std_logic_vector (4 downto 0);
      signal Cdb_RobDepth_gold                   : std_logic_vector (4 downto 0);
      signal SB_FlushSw_gold                     : std_logic; 
      signal SB_FlushSwTag_gold                  : std_logic_vector (1 downto 0);
	  signal SBTag_counter_gold       		     : std_logic_vector (1 downto 0);         --Added by Waleed 06/04/10
      signal Rob_CommitMemWrite_gold             : std_logic;	

      
      
-- Signals for the student's DUT (Issue_Queue)
         -- Information to be captured from the CDB (Common Data Bus)
      signal Cdb_RdPhyAddr     : std_logic_vector(5 downto 0);
	  signal Cdb_PhyRegWrite   : std_logic;
      signal Cdb_Valid         : std_logic;

      -- Information from the Dispatch Unit 
      signal Dis_Opcode                     : std_logic; 
      signal Dis_Immediate                  : std_logic_vector(15 downto 0 );
      signal Dis_RsDataRdy                  : std_logic;
      signal Dis_RsPhyAddr                  : std_logic_vector(5 downto 0 ); 
      signal Dis_RobTag                     : std_logic_vector(4 downto 0);
	  signal Dis_NewRdPhyAddr               : std_logic_vector(5 downto 0);
      signal Dis_LdIssquenable              : std_logic; 
      signal Issque_LdStQueueFull           : std_logic;
	  signal Issque_LdStQueueTwoOrMoreVacant: std_logic;
	  signal Dis_instruction                : std_logic_vector(31 downto 0);
	  signal Iss_instructionLsq             : std_logic_vector(31 downto 0);
	  signal Iss_RsPhyAddrLsq               : std_logic_vector(5 downto 0);
	  signal PhyReg_LsqRsData          	 : std_logic_vector(31 downto 0);
	  signal Iss_LdStReady                  : std_logic ;
      signal Iss_LdStOpcode                 : std_logic ;  
      signal Iss_LdStRobTag                 : std_logic_vector(4 downto 0);
      signal Iss_LdStAddr                   : std_logic_vector(31 downto 0); 
      signal Iss_LdStIssued                 : std_logic;
	  signal Iss_LdStPhyAddr                : std_logic_vector(5 downto 0);
      signal DCE_ReadBusy                   : std_logic;
      signal Lsbuf_Done                     : std_logic;
      signal Cdb_Flush                      : std_logic;
      signal Rob_TopPtr                     : std_logic_vector (4 downto 0);
      signal Cdb_RobDepth                   : std_logic_vector (4 downto 0);
      signal SB_FlushSw                     : std_logic; 
      signal SB_FlushSwTag                  : std_logic_vector (1 downto 0);
	  signal SBTag_counter       		    : std_logic_vector (1 downto 0);         --Added by Waleed 06/04/10
      signal Rob_CommitMemWrite             : std_logic;	
   
 -- component declaration
	component tomasulo_top
	port (
		Reset     : in std_logic;
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
	
component lsq 
port (
      -- Global Clk and Resetb Signals
      Clk                  : in  std_logic;
      Resetb               : in  std_logic;

      -- Information to be captured from the CDB (Common Data Bus)
      Cdb_RdPhyAddr        : in  std_logic_vector(5 downto 0);
	  Cdb_PhyRegWrite      : in  std_logic;
      Cdb_Valid            : in  std_logic ;

      -- Information from the Dispatch Unit 
	  
      Dis_Opcode           : in  std_logic; 
      Dis_Immediate        : in  std_logic_vector(15 downto 0 );
      Dis_RsDataRdy        : in  std_logic;
      Dis_RsPhyAddr        : in  std_logic_vector(5 downto 0 ); 
      Dis_RobTag           : in  std_logic_vector(4 downto 0);
	  Dis_NewRdPhyAddr     : in  std_logic_vector(5 downto 0);
      Dis_LdIssquenable    : in  std_logic; 
      Issque_LdStQueueFull : out std_logic;
	  Issque_LdStQueueTwoOrMoreVacant: out std_logic;
	  
	  -- translate_off 
     Dis_instruction       : in std_logic_vector(31 downto 0);
	 -- translate_on
	 
	 -- translate_off 
     Iss_instructionLsq    : out std_logic_vector(31 downto 0);
	 -- translate_on
	 
      -- interface with PRF
	  Iss_RsPhyAddrLsq     : out std_logic_vector(5 downto 0);
	  PhyReg_LsqRsData	   : in std_logic_vector(31 downto 0);
	  -- Interface with the Issue Unit
      Iss_LdStReady        : out std_logic ;
      Iss_LdStOpcode       : out std_logic ;  
      Iss_LdStRobTag       : out std_logic_vector(4 downto 0);
      Iss_LdStAddr         : out std_logic_vector(31 downto 0); 
      Iss_LdStIssued       : in  std_logic;
	  Iss_LdStPhyAddr      : out  std_logic_vector(5 downto 0);
      DCE_ReadBusy         : in  std_logic;
      Lsbuf_Done           : in std_logic;
    --  Interface with ROB 
      Cdb_Flush            : in std_logic;
      Rob_TopPtr           : in std_logic_vector (4 downto 0);
      Cdb_RobDepth         : in std_logic_vector (4 downto 0);
      SB_FlushSw           : in std_logic; 
      --SB_FlushSwTag            : in std_logic_vector (4 downto 0)    --Modified by Waleed 06/04/10
	  SB_FlushSwTag        : in std_logic_vector (1 downto 0);
	  SBTag_counter		   : in std_logic_vector (1 downto 0);         --Added by Waleed 06/04/10
      --Interface with ROB , Added by Waleed 06/04/10
	  Rob_CommitMemWrite   : in std_logic	  
     );
end component lsq;

 	
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

	lsq_UUT:  lsq
    port map (
               Clk                                 => Clk,       
               Resetb                              => Resetb,
               Cdb_RdPhyAddr                       => Cdb_RdPhyAddr,       
	           Cdb_PhyRegWrite                     => Cdb_PhyRegWrite,      
               Cdb_Valid                           => Cdb_Valid,           
               Dis_Opcode                          => Dis_Opcode,        
               Dis_Immediate                       => Dis_Immediate,     
               Dis_RsDataRdy                       => Dis_RsDataRdy,      
               Dis_RsPhyAddr                       => Dis_RsPhyAddr,       
               Dis_RobTag                          => Dis_RobTag,         
	           Dis_NewRdPhyAddr                    => Dis_NewRdPhyAddr,    
               Dis_LdIssquenable                   => Dis_LdIssquenable,   
               Issque_LdStQueueFull                => Issque_LdStQueueFull,
	           Issque_LdStQueueTwoOrMoreVacant     => Issque_LdStQueueTwoOrMoreVacant,
	           Dis_instruction                     => Dis_instruction,      
	           Iss_instructionLsq                  => Iss_instructionLsq,   
	       	   Iss_RsPhyAddrLsq                    => Iss_RsPhyAddrLsq,    
	           PhyReg_LsqRsData                    => PhyReg_LsqRsData,   
	           Iss_LdStReady                       =>  Iss_LdStReady,      
               Iss_LdStOpcode                      => Iss_LdStOpcode,       
               Iss_LdStRobTag                      => Iss_LdStRobTag,      
               Iss_LdStAddr                        => Iss_LdStAddr,        
               Iss_LdStIssued                      => Iss_LdStIssued,      
	           Iss_LdStPhyAddr                     => Iss_LdStPhyAddr,     
               DCE_ReadBusy                        => DCE_ReadBusy,         
               Lsbuf_Done                          => Lsbuf_Done,        
               Cdb_Flush                           => Cdb_Flush,            
               Rob_TopPtr                          => Rob_TopPtr,         
               Cdb_RobDepth                        => Cdb_RobDepth,       
               SB_FlushSw                          => SB_FlushSw,         
               SB_FlushSwTag                       => SB_FlushSwTag,       
	           SBTag_counter	                   => SBTag_counter,	   
               Rob_CommitMemWrite                  => Rob_CommitMemWrite 	  
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
		  --check outputs of lsq only--
-------------------------------------------------
	compare_outputs_Clkd: process (Clk_Delayed10, Reset)
		file my_outfile: text open append_mode is "TomasuloCompareTestLog.log";
		variable my_inline, my_outline: line;
		begin
			if (Reset = '0' and (Clk_Delayed10'event and Clk_Delayed10 = '0')) then			--- 10%after the middle of the clock.
				if (Issque_LdStQueueFull_gold /=Issque_LdStQueueFull) then
					write (my_outline, string'("ERROR! Issque_LdStQueueFull of TEST does not match Issque_LdStQueueFull_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if ( Issque_LdStQueueTwoOrMoreVacant_gold /=  Issque_LdStQueueTwoOrMoreVacant) then
					write (my_outline, string'("ERROR!  Issque_LdStQueueTwoOrMoreVacant of TEST does not match  Issque_LdStQueueTwoOrMoreVacant_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Iss_instructionLsq_gold /= Iss_instructionLsq) then
					write (my_outline, string'("ERROR! Iss_instructionLsq  of TEST does not match Iss_instructionLsq_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Iss_RsPhyAddrLsq_gold /= Iss_RsPhyAddrLsq ) then
					write (my_outline, string'("ERROR! Iss_RsPhyAddrLsq of TEST does not match Iss_RsPhyAddrLsq_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Iss_LdStReady_gold /=Iss_LdStReady) then
					write (my_outline, string'("ERROR! Iss_LdStReady  of TEST does not match Iss_LdStReady_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if ( Iss_LdStOpcode_gold /=  Iss_LdStOpcode) then
					write (my_outline, string'("ERROR!  Iss_LdStOpcode of TEST does not match  Iss_LdStOpcode_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Iss_LdStRobTag_gold /= Iss_LdStRobTag) then
					write (my_outline, string'("ERROR! Iss_LdStRobTag of TEST does not match Iss_LdStRobTag_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Iss_LdStAddr_gold /= Iss_LdStAddr ) then
					write (my_outline, string'("ERROR! Iss_LdStAddr of TEST does not match Iss_LdStAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;				
				if (Iss_LdStPhyAddr_gold /= Iss_LdStPhyAddr) then
					write (my_outline, string'("ERROR! Iss_LdStPhyAddr of TEST does not match Iss_LdStPhyAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
			end if;
		end process compare_outputs_Clkd;

	spy_process: process
		begin
--inputs
			init_signal_spy("/UUT/integer_queue_inst/Resetb","Resetb",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Resetb","Resetb",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Cdb_RdPhyAddr","Cdb_RdPhyAddr",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Cdb_RdPhyAddr","Cdb_RdPhyAddr",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Cdb_PhyRegWrite","Cdb_PhyRegWrite",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Cdb_PhyRegWrite","Cdb_PhyRegWrite",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Cdb_Valid","Cdb_Valid",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Cdb_Valid","Cdb_Valid",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Dis_Opcode","Dis_Opcode",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Dis_Opcode","Dis_Opcode",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Dis_Immediate","Dis_Immediate",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Dis_Immediate","Dis_Immediate",0);
						
			init_signal_spy("/UUT/loadstoreque_inst/Dis_RsDataRdy","Dis_RsDataRdy",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Dis_RsDataRdy","Dis_RsDataRdy",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Dis_RsPhyAddr","Dis_RsPhyAddr",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Dis_RsPhyAddr","Dis_RsPhyAddr",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Dis_NewRdPhyAddr","Dis_NewRdPhyAddr",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Dis_NewRdPhyAddr","Dis_NewRdPhyAddr",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Dis_RobTag","Dis_RobTag",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Dis_RobTag","Dis_RobTag",0);
	        
			init_signal_spy("/UUT/loadstoreque_inst/Dis_LdIssquenable","Dis_LdIssquenable",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Dis_LdIssquenable","Dis_LdIssquenable",0);
   
            init_signal_spy("/UUT/loadstoreque_inst/Dis_instruction","Dis_instruction",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Dis_instruction","Dis_instruction",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Cdb_Flush","Cdb_Flush",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Cdb_Flush","Cdb_Flush",0);
	    
		    init_signal_spy("/UUT/loadstoreque_inst/Rob_TopPtr","Rob_TopPtr",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Rob_TopPtr","Rob_TopPtr",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Cdb_RobDepth","Cdb_RobDepth",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Cdb_RobDepth","Cdb_RobDepth",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/PhyReg_LsqRsData","PhyReg_LsqRsData",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/PhyReg_LsqRsData","PhyReg_LsqRsData",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Iss_LdStIssued","Iss_LdStIssued",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Iss_LdStIssued","Iss_LdStIssued",0);
	            
			init_signal_spy("/UUT/loadstoreque_inst/DCE_ReadBusy","DCE_ReadBusy",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/DCE_ReadBusy","DCE_ReadBusy",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Lsbuf_Done","Lsbuf_Done",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Lsbuf_Done","Lsbuf_Done",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/SB_FlushSw","SB_FlushSw",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/SB_FlushSw","SB_FlushSw",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/SB_FlushSwTag","SB_FlushSwTag",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/SB_FlushSwTag","SB_FlushSwTag",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/SBTag_counter","SBTag_counter",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/SBTag_counter","SBTag_counter",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Rob_CommitMemWrite","Rob_CommitMemWrite",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Rob_CommitMemWrite","Rob_CommitMemWrite",0);
   
--outputs--
            init_signal_spy("/UUT/loadstoreque_inst/Issque_LdStQueueFull","Issque_LdStQueueFull_gold",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Issque_LdStQueueFull","Issque_LdStQueueFull_gold",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Iss_instructionLsq","Iss_instructionLsq_gold",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Iss_instructionLsq","Iss_instructionLsq_gold",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Iss_RsPhyAddrLsq","Iss_RsPhyAddrLsq_gold",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Iss_RsPhyAddrLsq","Iss_RsPhyAddrLsq_gold",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Issque_LdStQueueTwoOrMoreVacant","Issque_LdStQueueTwoOrMoreVacant_gold",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Issque_LdStQueueTwoOrMoreVacant","Issque_LdStQueueTwoOrMoreVacant_gold",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Iss_LdStReady ","Iss_LdStReady_gold",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Iss_LdStReady "," Iss_LdStReady_gold",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Iss_LdStOpcode","Iss_LdStOpcode_gold",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Iss_LdStOpcode","Iss_LdStOpcode_gold",0);
	
            -------
			init_signal_spy("/UUT/loadstoreque_inst/Iss_LdStRobTag","Iss_LdStRobTag_gold",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Iss_LdStRobTag","Iss_LdStRobTag_gold",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Iss_LdStAddr","Iss_LdStAddr_gold",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Iss_LdStAddr","Iss_LdStAddr_gold",0);
			
			init_signal_spy("/UUT/loadstoreque_inst/Iss_LdStPhyAddr","Iss_LdStPhyAddr_gold",1,1);
			enable_signal_spy("/UUT/loadstoreque_inst/Iss_LdStPhyAddr","Iss_LdStPhyAddr_gold",0);
			
		wait;
	end process spy_process;			

end architecture arch_top_tb_lsq;
