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
	
	-- Hierarchy signals (Golden FRL)
    signal Frl_RdPhyAddr_gold	: 	std_logic_vector(5 downto 0);  
	signal Frl_Empty_gold      	:	std_logic;
	signal Frl_HeadPtr_gold    	: 	std_logic_vector(4 downto 0);

	-- Signals for the student's DUT (FRL)
	
	signal Resetb				:	std_logic;
	signal Cdb_Flush    		: 	std_logic;
	signal Rob_CommitPrePhyAddr :	std_logic_vector(5 downto 0);
	signal Rob_Commit	    	:	std_logic ;
	signal Rob_CommitRegWrite 	:	std_logic;
	signal Cfc_FrlHeadPtr		:	std_logic_vector(4 downto 0) ;
	signal Dis_FrlRead   	 	: 	std_logic ;
	signal Frl_RdPhyAddr		: 	std_logic_vector(5 downto 0);  
	signal Frl_Empty      		:	std_logic;
	signal Frl_HeadPtr  		: 	std_logic_vector(4 downto 0);

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
	
	component Frl is 
	generic (WIDE  : integer := 6;DEEP  : integer:=16;PTRWIDTH:integer:=5);
	port (
	--Inputs
	Clk            : in  std_logic;
	Resetb         : in  std_logic;
	Cdb_Flush      : in  std_logic ;
	--Interface with Rob
	Rob_CommitPrePhyAddr 	   : in  std_logic_vector(WIDE-1 downto 0) ;
	Rob_Commit    : in  std_logic ;
	Rob_CommitRegWrite : in std_logic;
	Cfc_FrlHeadPtr: in  std_logic_vector(PTRWIDTH-1 downto 0) ;
	--Intreface with Dis_FrlRead unit
	Frl_RdPhyAddr        : out  std_logic_vector(WIDE-1 downto 0) ;
	Dis_FrlRead    : in  std_logic ;
	Frl_Empty      : out  std_logic ;
	--Interface with Previous Head Pointer Stack
	Frl_HeadPtr    : out  std_logic_vector(PTRWIDTH-1 downto 0) 
	);
	end component Frl;
	------------------------------------------
 	for 	FRL_UUT: frl use entity work.frl(behav);
	------------------------------------------
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

	FRL_UUT:  frl
	port map (                
			Clk						=>	Clk,
			Resetb  				=>	Resetb,
			Cdb_Flush				=>	Cdb_Flush,
			Rob_CommitPrePhyAddr	=>	Rob_CommitPrePhyAddr,
			Rob_Commit  			=>	Rob_Commit,
			Rob_CommitRegWrite 		=>	Rob_CommitRegWrite,
			Cfc_FrlHeadPtr			=>	Cfc_FrlHeadPtr,
			Frl_RdPhyAddr			=>	Frl_RdPhyAddr,	
			Dis_FrlRead				=>	Dis_FrlRead,
			Frl_Empty				=>	Frl_Empty,	
			Frl_HeadPtr  			=>	Frl_HeadPtr
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
		  --check outputs of FRL only--
-------------------------------------------------
	compare_outputs_Clkd: process (Clk_Delayed10, Reset)
		file my_outfile: text open append_mode is "TomasuloCompareTestLog.log";
		variable my_inline, my_outline: line;

		begin
			if (Reset = '0' and (Clk_Delayed10'event and Clk_Delayed10 = '0')) then			--- 10%after the middle of the clock.
				if (Frl_RdPhyAddr_gold /= Frl_RdPhyAddr) then
					write (my_outline, string'("ERROR! Frl_RdPhyAddr of TEST does not match Frl_RdPhyAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Frl_Empty_gold /= Frl_Empty) then
					write (my_outline, string'("ERROR! Frl_Empty of TEST does not match Frl_Empty_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Frl_HeadPtr_gold /= Frl_HeadPtr) then
					write (my_outline, string'("ERROR! Frl_HeadPtr of TEST does not match Frl_HeadPtr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
			end if;
		end process compare_outputs_Clkd;

	spy_process: process
		begin
--inputs
			init_signal_spy("/UUT/Resetb","Resetb",1,1);
			enable_signal_spy("/UUT/Resetb","Resetb",0);

			init_signal_spy("/UUT/Cdb_Flush","Cdb_Flush",1,1);
			enable_signal_spy("/UUT/Cdb_Flush","Cdb_Flush",0);
			
			init_signal_spy("/UUT/Rob_CommitPrePhyAddr","Rob_CommitPrePhyAddr",1,1);
			enable_signal_spy("/UUT/Rob_CommitPrePhyAddr","Rob_CommitPrePhyAddr",0);
			
			init_signal_spy("/UUT/Rob_Commit","Rob_Commit",1,1);
			enable_signal_spy("/UUT/Rob_Commit","Rob_Commit",0);
			
			init_signal_spy("/UUT/Rob_CommitRegWrite","Rob_CommitRegWrite",1,1);
			enable_signal_spy("/UUT/Rob_CommitRegWrite","Rob_CommitRegWrite",0);
			
			init_signal_spy("/UUT/Cfc_FrlHeadPtr","Cfc_FrlHeadPtr",1,1);
			enable_signal_spy("/UUT/Cfc_FrlHeadPtr","Cfc_FrlHeadPtr",0);
			
			init_signal_spy("/UUT/Dis_FrlRead","Dis_FrlRead",1,1);
			enable_signal_spy("/UUT/Dis_FrlRead","Dis_FrlRead",0);
--outputs--
			init_signal_spy("/UUT/Frl_RdPhyAddr","Frl_RdPhyAddr_gold",1,1);
			enable_signal_spy("/UUT/Frl_RdPhyAddr","Frl_RdPhyAddr_gold",0);
			
			init_signal_spy("/UUT/Frl_Empty","Frl_Empty_gold",1,1);
			enable_signal_spy("/UUT/Frl_Empty","Frl_Empty_gold",0);
			
			init_signal_spy("/UUT/Frl_HeadPtr","Frl_HeadPtr_gold",1,1);
			enable_signal_spy("/UUT/Frl_HeadPtr","Frl_HeadPtr_gold",0);
			
		wait;
	end process spy_process;			

end architecture arch_top_tb_ROB;
