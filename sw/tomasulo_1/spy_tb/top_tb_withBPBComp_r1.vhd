-------------------------------------------------------------------------------
-- Design   : Signal Spy testbench for Branch Prediction Buffer
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
--use reverseAssemblyFunctionPkg.all; --modified by sabya - not needed in top!
-- synopsys translate_on
-----------------------------------------------------------------------------

--added by Sabya to use compiled library
library ee560;
use ee560.all;
------------------------------------------------------------------------------

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
	
-- Hierarchy signals (Golden BPB)
	signal Bpb_BranchPrediction_gold :std_logic; 

	
-- Signals for the student's DUT (BPB)
    signal Resetb           	:std_logic; 
    signal Dis_CdbUpdBranch     :std_logic; 
    signal Dis_CdbUpdBranchAddr :std_logic_vector(2 downto 0);
    signal Dis_CdbBranchOutcome :std_logic; 
	signal Bpb_BranchPrediction :std_logic; 
	signal Dis_BpbBranchPCBits  :std_logic_vector(2 downto 0) ;
	signal Dis_BpbBranch        :std_logic; 

  	
	
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
	
	component bpb
	port (                
		Clk               		    : in std_logic;
        Resetb              		: in std_logic; 
        Dis_CdbUpdBranch            : in  std_logic;
		Dis_CdbUpdBranchAddr  		: in std_logic_vector(2 downto 0);
		Dis_CdbBranchOutcome   		: in std_logic;
		Bpb_BranchPrediction    	: out std_logic; 
		Dis_BpbBranchPCBits         : in std_logic_vector(2 downto 0) ;
		Dis_BpbBranch               : in std_logic 
		);
	end component bpb;
 
 for 	BPB_UUT: bpb use entity work.bpb(behv);
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

	BPB_UUT:  bpb
	port map (                
		Clk		=> Clk,
		Resetb	=> Resetb,
        Dis_CdbUpdBranch=>Dis_CdbUpdBranch,
		Dis_CdbUpdBranchAddr=>Dis_CdbUpdBranchAddr,
		Dis_CdbBranchOutcome=>Dis_CdbBranchOutcome,   
		Bpb_BranchPrediction=>Bpb_BranchPrediction,
		Dis_BpbBranchPCBits=>Dis_BpbBranchPCBits,
		Dis_BpbBranch=>Dis_BpbBranch 	
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
		  --check outputs of Branch Prediction Buffer only--
-------------------------------------------------
	compare_outputs_Clkd: process (Clk_Delayed10, Reset)
		file my_outfile: text open append_mode is "TomasuloCompareTestLog.log";
		variable my_inline, my_outline: line;

		begin
			if (Reset = '0' and (Clk_Delayed10'event and Clk_Delayed10 = '0')) then			--- 10%after the middle of the clock.
				if (Bpb_BranchPrediction_gold /= Bpb_BranchPrediction) then
					write (my_outline, string'("ERROR! Bpb_BranchPrediction of TEST does not match Bpb_BranchPrediction_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
			end if;
		end process compare_outputs_Clkd;

	spy_process: process
		begin
--inputs
			init_signal_spy("/UUT/Resetb","Resetb",1,1);
			enable_signal_spy("/UUT/Resetb","Resetb",0);

			init_signal_spy("/UUT/Dis_CdbUpdBranch","Dis_CdbUpdBranch",1,1);
			enable_signal_spy("/UUT/Dis_CdbUpdBranch","Dis_CdbUpdBranch",0);
			
			init_signal_spy("/UUT/Dis_CdbUpdBranchAddr","Dis_CdbUpdBranchAddr",1,1);
			enable_signal_spy("/UUT/Dis_CdbUpdBranchAddr","Dis_CdbUpdBranchAddr",0);
			
			init_signal_spy("/UUT/Dis_CdbBranchOutcome","Dis_CdbBranchOutcome",1,1);
			enable_signal_spy("/UUT/Dis_CdbBranchOutcome","Dis_CdbBranchOutcome",0);
			
			init_signal_spy("/UUT/Dis_BpbBranchPCBits","Dis_BpbBranchPCBits",1,1);
			enable_signal_spy("/UUT/Dis_BpbBranchPCBits","Dis_BpbBranchPCBits",0);
			
			init_signal_spy("/UUT/Dis_BpbBranch","Dis_BpbBranch",1,1);
			enable_signal_spy("/UUT/Dis_BpbBranch","Dis_BpbBranch",0);
			
--outputs--
			init_signal_spy("/UUT/Bpb_BranchPrediction","Bpb_BranchPrediction_gold",1,1);
			enable_signal_spy("/UUT/Bpb_BranchPrediction","Bpb_BranchPrediction_gold",0);
			
		wait;
	end process spy_process;			

end architecture arch_top_tb_ROB;
