-------------------------------------------------------------------------------
-- Design   : Signal Spy testbench for Load/Store Address Buffer
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

architecture arch_top_tb_SAddrBuf of top_tb is

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
		
	
-- Hierarchy signals (Golden SAddrBuf)
    signal AddrBuffFull_gold          :	std_logic; 
    signal AddrMatch0_gold            :  std_logic;
    signal AddrMatch1_gold            :  std_logic;
    signal AddrMatch2_gold            :  std_logic;
    signal AddrMatch3_gold            :  std_logic;
	signal AddrMatch4_gold            :  std_logic;
    signal AddrMatch5_gold            :  std_logic;
    signal AddrMatch6_gold            :  std_logic;
    signal AddrMatch7_gold            :  std_logic;
    signal AddrMatch0Num_gold         :  std_logic_vector (2 downto 0);
    signal AddrMatch1Num_gold         :  std_logic_vector (2 downto 0);
    signal AddrMatch2Num_gold         :  std_logic_vector (2 downto 0);
    signal AddrMatch3Num_gold         :  std_logic_vector (2 downto 0);
    signal AddrMatch4Num_gold         :  std_logic_vector (2 downto 0);
	signal AddrMatch5Num_gold         :  std_logic_vector (2 downto 0);
    signal AddrMatch6Num_gold         :  std_logic_vector (2 downto 0);
    signal AddrMatch7Num_gold         :  std_logic_vector (2 downto 0);
    				     
 -- Signals for the student's DUT (ROB)
    signal Resetb  	         : std_logic; 
    signal AddrBuffFull          :	std_logic; 
    signal AddrMatch0            :  std_logic;
    signal AddrMatch1            :  std_logic;
    signal AddrMatch2            :  std_logic;
    signal AddrMatch3            :  std_logic;
	signal AddrMatch4            :  std_logic;
    signal AddrMatch5            :  std_logic;
    signal AddrMatch6            :  std_logic;
    signal AddrMatch7            :  std_logic;
    signal AddrMatch0Num         :  std_logic_vector (2 downto 0);
    signal AddrMatch1Num         :  std_logic_vector (2 downto 0);
    signal AddrMatch2Num         :  std_logic_vector (2 downto 0);
    signal AddrMatch3Num         :  std_logic_vector (2 downto 0);
    signal AddrMatch4Num         :  std_logic_vector (2 downto 0);
	signal AddrMatch5Num         :  std_logic_vector (2 downto 0);
    signal AddrMatch6Num         :  std_logic_vector (2 downto 0);
    signal AddrMatch7Num         :  std_logic_vector (2 downto 0);
    signal ScanAddr0             :  std_logic_vector (31 downto 0);
	signal ScanAddr1             :  std_logic_vector (31 downto 0);
    signal ScanAddr2             :  std_logic_vector (31 downto 0);
    signal ScanAddr3             :  std_logic_vector (31 downto 0);
	signal ScanAddr4             :  std_logic_vector (31 downto 0);
    signal ScanAddr5             :  std_logic_vector (31 downto 0);
    signal ScanAddr6             :  std_logic_vector (31 downto 0);
    signal ScanAddr7             :  std_logic_vector (31 downto 0);				   
    signal LsqSwAddr             :  std_logic_vector (36 downto 0);  
	signal Cdb_Flush              :  std_logic;
    signal Rob_TopPtr         :  std_logic_vector (4 downto 0);
    signal Cdb_RobDepth              :  std_logic_vector (4 downto 0);
    signal StrAddr               :  std_logic;
	signal SB_FlushSw               :  std_logic;
	signal SB_FlushSwTag            :  std_logic_vector (1 downto 0);
	signal SBTag_counter		    :  std_logic_vector (1 downto 0);
	signal Rob_CommitMemWrite      :  std_logic;
--	signal Rob_Commit              :  std_logic;	
 -- component declaration
	component tomasulo_top
	port (
		Reset     : in std_logic;
		Clk : in std_logic;
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
	
	component AddBuff
	port (     
			Clk                   : in  std_logic;
            Resetb                 : in  std_logic;
			AddrBuffFull          : out std_logic;
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
            ScanAddr0             : in std_logic_vector (31 downto 0);
            ScanAddr1             : in std_logic_vector (31 downto 0);
            ScanAddr2             : in std_logic_vector (31 downto 0);
            ScanAddr3             : in std_logic_vector (31 downto 0);
			ScanAddr4             : in std_logic_vector (31 downto 0); 
			ScanAddr5             : in std_logic_vector (31 downto 0);
            ScanAddr6             : in std_logic_vector (31 downto 0);
            ScanAddr7             : in std_logic_vector (31 downto 0);
			LsqSwAddr             : in std_logic_vector (36 downto 0); 
	 	    Cdb_Flush             : in std_logic;
            Rob_TopPtr        	  : in std_logic_vector (4 downto 0);
            Cdb_RobDepth          : in std_logic_vector (4 downto 0);
            StrAddr               : in std_logic;
			SB_FlushSw            : in std_logic;
			SB_FlushSwTag         : in std_logic_vector (1 downto 0);
			SBTag_counter		  : in std_logic_vector (1 downto 0);
			Rob_CommitMemWrite    : in std_logic	
		);
	end component AddBuff;
for 	AddBuff_TEST:  AddBuff use entity work.AddBuff(behave);

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

	AddBuff_TEST:  AddBuff
	port map (                
			Clk                   =>	Clk,
            Resetb                =>	Resetb,
			AddrBuffFull          =>	AddrBuffFull,
			
			AddrMatch0            =>	AddrMatch0,
			AddrMatch1            =>	AddrMatch1,
            AddrMatch2            =>	AddrMatch2,
            AddrMatch3            =>	AddrMatch3,
			AddrMatch4            =>	AddrMatch4,
			AddrMatch5            =>	AddrMatch5,
            AddrMatch6            =>	AddrMatch6,
            AddrMatch7            =>	AddrMatch7,
            AddrMatch0Num         =>	AddrMatch0Num,
			AddrMatch1Num         =>	AddrMatch1Num,
            AddrMatch2Num         =>	AddrMatch2Num,
            AddrMatch3Num         =>	AddrMatch3Num,
            AddrMatch4Num         =>	AddrMatch4Num,
			AddrMatch5Num         =>	AddrMatch5Num,
            AddrMatch6Num         =>	AddrMatch6Num,
            AddrMatch7Num         =>	AddrMatch7Num,
            ScanAddr0             =>	ScanAddr0,
            ScanAddr1             =>	ScanAddr1,
            ScanAddr2             =>	ScanAddr2,
            ScanAddr3             =>	ScanAddr3,
			ScanAddr4             => 	ScanAddr4,
			ScanAddr5             =>	ScanAddr5,
            ScanAddr6             =>	ScanAddr6,
            ScanAddr7             =>	ScanAddr7,
			LsqSwAddr             =>	LsqSwAddr, 
	 	    Cdb_Flush             =>	Cdb_Flush,
            Rob_TopPtr        	  =>	Rob_TopPtr,
            Cdb_RobDepth          =>	Cdb_RobDepth,
            StrAddr               =>	StrAddr,
			SB_FlushSw            => 	SB_FlushSw,
			SB_FlushSwTag         =>	SB_FlushSwTag,
			SBTag_counter         =>	SBTag_counter, 
			Rob_CommitMemWrite    =>	Rob_CommitMemWrite
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
		  --check outputs of Load/Store Address Buffer only--
-------------------------------------------------
	compare_outputs_Clkd: process (Clk_Delayed10, Reset)
		file my_outfile: text open append_mode is "TomasuloCompareTestLog.log";
		variable my_inline, my_outline: line;

		begin
			if (Reset = '0' and (Clk_Delayed10'event and Clk_Delayed10 = '0')) then			--- 10%after the middle of the clock.
				if (AddrBuffFull_gold /= AddrBuffFull) then
					write (my_outline, string'("ERROR! AddrBuffFull of TEST does not match AddrBuffFull_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (AddrMatch0_gold /= AddrMatch0) then
					write (my_outline, string'("ERROR! AddrMatch0 of TEST does not match AddrMatch0_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (AddrMatch1_gold /= AddrMatch1) then
					write (my_outline, string'("ERROR! AddrMatch1 of TEST does not match AddrMatch1_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (AddrMatch2_gold /= AddrMatch2) then
					write (my_outline, string'("ERROR! AddrMatch2 of TEST does not match AddrMatch2_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (AddrMatch3_gold /= AddrMatch3) then
					write (my_outline, string'("ERROR! AddrMatch3 of TEST does not match AddrMatch3_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (AddrMatch4_gold /= AddrMatch4) then
					write (my_outline, string'("ERROR! AddrMatch4 of TEST does not match AddrMatch4_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (AddrMatch5_gold /= AddrMatch5) then
					write (my_outline, string'("ERROR! AddrMatch5 of TEST does not match AddrMatch5_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (AddrMatch6_gold /= AddrMatch6) then
					write (my_outline, string'("ERROR! AddrMatch6 of TEST does not match AddrMatch6_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (AddrMatch7_gold /= AddrMatch7) then
					write (my_outline, string'("ERROR! AddrMatch7 of TEST does not match AddrMatch7_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (AddrMatch0Num_gold /= AddrMatch0Num) then
					write (my_outline, string'("ERROR! AddrMatch0Num of TEST does not match AddrMatch0Num_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (AddrMatch1Num_gold /= AddrMatch1Num) then
					write (my_outline, string'("ERROR! AddrMatch1Num of TEST does not match AddrMatch1Num_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (AddrMatch2Num_gold /= AddrMatch2Num) then
					write (my_outline, string'("ERROR! AddrMatch2Num of TEST does not match AddrMatch2Num_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (AddrMatch3Num_gold /= AddrMatch3Num) then
					write (my_outline, string'("ERROR! AddrMatch3Num of TEST does not match AddrMatch3Num_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (AddrMatch4Num_gold /= AddrMatch4Num) then
					write (my_outline, string'("ERROR! AddrMatch4Num of TEST does not match AddrMatch4Num_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (AddrMatch5Num_gold /= AddrMatch5Num) then
					write (my_outline, string'("ERROR! AddrMatch5Num of TEST does not match AddrMatch5Num_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (AddrMatch6Num_gold /= AddrMatch6Num) then
					write (my_outline, string'("ERROR! AddrMatch6Num of TEST does not match AddrMatch6Num_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (AddrMatch7Num_gold /= AddrMatch7Num) then
					write (my_outline, string'("ERROR! AddrMatch7Num of TEST does not match AddrMatch7Num_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
			end if;
		end process compare_outputs_Clkd;

	spy_process: process
		begin
--inputs
			init_signal_spy("/UUT/LoadStoreQue_inst/Resetb","Resetb",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/Resetb","Resetb",0);

			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/ScanAddr0","ScanAddr0",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/ScanAddr0","ScanAddr0",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/ScanAddr1","ScanAddr1",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/ScanAddr1","ScanAddr1",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/ScanAddr2","ScanAddr2",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/ScanAddr2","ScanAddr2",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/ScanAddr3","ScanAddr3",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/ScanAddr3","ScanAddr3",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/ScanAddr4","ScanAddr4",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/ScanAddr4","ScanAddr4",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/ScanAddr5","ScanAddr5",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/ScanAddr5","ScanAddr5",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/ScanAddr6","ScanAddr6",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/ScanAddr6","ScanAddr6",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/ScanAddr7","ScanAddr7",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/ScanAddr7","ScanAddr7",0);
						
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/LsqSwAddr","LsqSwAddr",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/LsqSwAddr","LsqSwAddr",0);

			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/Cdb_Flush","Cdb_Flush",1,1);			
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/Cdb_Flush","Cdb_Flush",0);
						
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/Rob_TopPtr","Rob_TopPtr",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/Rob_TopPtr","Rob_TopPtr",0);

			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/Cdb_RobDepth","Cdb_RobDepth",1,1);			
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/Cdb_RobDepth","Cdb_RobDepth",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/StrAddr","StrAddr",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/StrAddr","StrAddr",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/SB_FlushSw","SB_FlushSw",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/SB_FlushSw","SB_FlushSw",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/SB_FlushSwTag","SB_FlushSwTag",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/SB_FlushSwTag","SB_FlushSwTag",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/SBTag_counter","SBTag_counter",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/SBTag_counter","SBTag_counter",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/Rob_CommitMemWrite","Rob_CommitMemWrite",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/Rob_CommitMemWrite","Rob_CommitMemWrite",0);
			
			
--outputs--
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrBuffFull","AddrBuffFull_gold",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrBuffFull","AddrBuffFull_gold",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch0","AddrMatch0_gold",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch0","AddrMatch0_gold",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch1","AddrMatch1_gold",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch1","AddrMatch1_gold",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch2","AddrMatch2_gold",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch2","AddrMatch2_gold",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch3","AddrMatch3_gold",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch3","AddrMatch3_gold",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch4","AddrMatch4_gold",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch4","AddrMatch4_gold",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch5","AddrMatch5_gold",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch5","AddrMatch5_gold",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch6","AddrMatch6_gold",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch6","AddrMatch6_gold",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch7","AddrMatch7_gold",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch7","AddrMatch7_gold",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch0Num","AddrMatch0Num_gold",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch0Num","AddrMatch0Num_gold",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch1Num","AddrMatch1Num_gold",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch1Num","AddrMatch1Num_gold",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch2Num","AddrMatch2Num_gold",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch2Num","AddrMatch2Num_gold",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch3Num","AddrMatch3Num_gold",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch3Num","AddrMatch3Num_gold",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch4Num","AddrMatch4Num_gold",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch4Num","AddrMatch4Num_gold",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch5Num","AddrMatch5Num_gold",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch5Num","AddrMatch5Num_gold",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch6Num","AddrMatch6Num_gold",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch6Num","AddrMatch6Num_gold",0);
			
			init_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch7Num","AddrMatch7Num_gold",1,1);
			enable_signal_spy("/UUT/LoadStoreQue_inst/AddBudd/AddrMatch7Num","AddrMatch7Num_gold",0);
			
		wait;
	end process spy_process;			

end architecture arch_top_tb_SAddrBuf;
