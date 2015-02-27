-------------------------------------------------------------------------------
-- Design   : Signal Spy testbench for Store Buffer
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

architecture arch_top_tb_Store_Buf of top_tb is

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
  
	
	signal	SB_Full_gold           		: std_logic;
	signal	SB_Stall_gold 		   		: std_logic;
	signal	SB_FlushSw_gold          	: std_logic;
	signal	SB_FlushSwTag_gold       	: std_logic_vector(1 downto 0);
	signal 	SBTag_counter_gold				: std_logic_vector(1 downto 0);	
	signal	SB_DataDmem_gold  			: std_logic_vector (31 downto 0);
	signal	SB_AddrDmem_gold  			: std_logic_vector (31 downto 0);
	signal	SB_DataValid_gold 			: std_logic;
	
		
-- Signals for the student's DUT (BPB)
	signal  Resetb          	: std_logic ;		
	signal	Rob_SwAddr	 	 	: std_logic_vector (31 downto 0);
	signal	PhyReg_StoreData  	: std_logic_vector (31 downto 0);
	signal	Rob_CommitMemWrite  : std_logic;
	signal	SB_Full           	: std_logic;
	signal	SB_Stall 		   	: std_logic;
	signal	Rob_TopPtr    		: std_logic_vector(4 downto 0);
	signal	SB_FlushSw          : std_logic;
	signal	SB_FlushSwTag       : std_logic_vector(1 downto 0);
	signal	SBTag_counter       : std_logic_vector(1 downto 0);
	signal	SB_DataDmem  		: std_logic_vector (31 downto 0);
	signal	SB_AddrDmem  		: std_logic_vector (31 downto 0);
	signal	SB_DataValid 		: std_logic;
	signal	DCE_WriteBusy       : std_logic;
	signal	DCE_WriteDone 		: std_logic;	
	
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
	
	component store_buffer
	port (                
		Clk    	        	: in  std_logic ;
        Resetb          	: in  std_logic ;		
		Rob_SwAddr	 	 	: in std_logic_vector (31 downto 0);
		PhyReg_StoreData  	: in std_logic_vector (31 downto 0);
		Rob_CommitMemWrite  : in std_logic;
		SB_Full           	: out std_logic;
		SB_Stall 		   	: out std_logic;
		Rob_TopPtr    		: in std_logic_vector(4 downto 0);
		SB_FlushSw          : out std_logic;
		SB_FlushSwTag       : out std_logic_vector(1 downto 0);
		SBTag_counter       : out std_logic_vector(1 downto 0);
		SB_DataDmem  		: out std_logic_vector (31 downto 0);
		SB_AddrDmem  		: out std_logic_vector (31 downto 0);
		SB_DataValid 		: out std_logic;
		DCE_WriteBusy       : in std_logic;
		DCE_WriteDone 		: in std_logic
		);
	end component store_buffer;
for Store_Buffer_UUT:  store_buffer use entity work.store_buffer(struct);
 	
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

	Store_Buffer_UUT:  store_buffer
	port map (                
		Clk    	        	=> Clk,
		Resetb          	=> Resetb ,		
		Rob_SwAddr	 	 	=> Rob_SwAddr,
		PhyReg_StoreData  	=> PhyReg_StoreData,
		Rob_CommitMemWrite  => Rob_CommitMemWrite,
		SB_Full           	=> SB_Full,
		SB_Stall 		   	=> SB_Stall,
		Rob_TopPtr    		=> Rob_TopPtr,
		SB_FlushSw          => SB_FlushSw,
		SB_FlushSwTag       => SB_FlushSwTag,
		SBTag_counter       => SBTag_counter,
		SB_DataDmem  		=> SB_DataDmem,
		SB_AddrDmem  		=> SB_AddrDmem,
		SB_DataValid 		=> SB_DataValid,
		DCE_WriteBusy       => DCE_WriteBusy,
		DCE_WriteDone 		=> DCE_WriteDone	
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
		  --check outputs of Store Buffer only--
-------------------------------------------------
	compare_outputs_Clkd: process (Clk_Delayed10, Reset)
		file my_outfile: text open append_mode is "TomasuloCompareTestLog.log";
		variable my_inline, my_outline: line;

		begin
			if (Reset = '0' and (Clk_Delayed10'event and Clk_Delayed10 = '0')) then			--- 10%after the middle of the clock.
				if (SB_Full_gold /= SB_Full) then
					write (my_outline, string'("ERROR! SB_Full of TEST does not match SB_Full_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (SB_Stall_gold /= SB_Stall) then
					write (my_outline, string'("ERROR! SB_Stall of TEST does not match SB_Stall_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (SB_FlushSw_gold /= SB_FlushSw) then
					write (my_outline, string'("ERROR! SB_FlushSw of TEST does not match SB_FlushSw_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (SB_FlushSwTag_gold /= SB_FlushSwTag) then
					write (my_outline, string'("ERROR! SB_FlushSwTag of TEST does not match SB_FlushSwTag_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (SBTag_counter_gold /= SBTag_counter) then
					write (my_outline, string'("ERROR! SBTag_counter of TEST does not match SBTag_counter_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (SB_DataDmem_gold /= SB_DataDmem) then
					write (my_outline, string'("ERROR! SB_DataDmem of TEST does not match SB_DataDmem_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (SB_AddrDmem_gold /= SB_AddrDmem) then
					write (my_outline, string'("ERROR! SB_AddrDmem of TEST does not match SB_AddrDmem_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (SB_DataValid_gold /=SB_DataValid) then
					write (my_outline, string'("ERROR! SB_DataValid of TEST does not match SB_DataValid_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				
			end if;
		end process compare_outputs_Clkd;

	spy_process: process
		begin
--inputs
			init_signal_spy("/UUT/Resetb","Resetb",1,1);
			enable_signal_spy("/UUT/Resetb","Resetb",0);

			init_signal_spy("/UUT/Rob_SwAddr","Rob_SwAddr",1,1);
			enable_signal_spy("/UUT/Rob_SwAddr","Rob_SwAddr",0);
			
			init_signal_spy("/UUT/PhyReg_StoreData","PhyReg_StoreData",1,1);
			enable_signal_spy("/UUT/PhyReg_StoreData","PhyReg_StoreData",0);
			
			init_signal_spy("/UUT/Rob_CommitMemWrite","Rob_CommitMemWrite",1,1);
			enable_signal_spy("/UUT/Rob_CommitMemWrite","Rob_CommitMemWrite",0);
			
			init_signal_spy("/UUT/Rob_TopPtr","Rob_TopPtr",1,1);
			enable_signal_spy("/UUT/Rob_TopPtr","Rob_TopPtr",0);
			
			init_signal_spy("/UUT/DCE_WriteBusy","DCE_WriteBusy",1,1);
			enable_signal_spy("/UUT/DCE_WriteBusy","DCE_WriteBusy",0);
			
			init_signal_spy("/UUT/DCE_WriteDone","DCE_WriteDone",1,1);
			enable_signal_spy("/UUT/DCE_WriteDone","DCE_WriteDone",0);
			
--outputs--
			init_signal_spy("/UUT/SB_Full","SB_Full_gold",1,1);
			enable_signal_spy("/UUT/SB_Full","SB_Full_gold",0);
			
			init_signal_spy("/UUT/SB_Stall","SB_Stall_gold",1,1);
			enable_signal_spy("/UUT/SB_Stall","SB_Stall_gold",0);
			
			init_signal_spy("/UUT/SB_FlushSw","SB_FlushSw_gold",1,1);
			enable_signal_spy("/UUT/SB_FlushSw","SB_FlushSw_gold",0);
			
			init_signal_spy("/UUT/SB_FlushSwTag","SB_FlushSwTag_gold",1,1);
			enable_signal_spy("/UUT/SB_FlushSwTag","SB_FlushSwTag_gold",0);
			
			init_signal_spy("/UUT/SBTag_counter","SBTag_counter_gold",1,1);
			enable_signal_spy("/UUT/SBTag_counter","SBTag_counter_gold",0);
			
			init_signal_spy("/UUT/SB_DataDmem","SB_DataDmem_gold",1,1);
			enable_signal_spy("/UUT/SB_DataDmem","SB_DataDmem_gold",0);
			
			init_signal_spy("/UUT/SB_AddrDmem","SB_AddrDmem_gold",1,1);
			enable_signal_spy("/UUT/SB_AddrDmem","SB_AddrDmem_gold",0);
			
			init_signal_spy("/UUT/SB_DataValid","SB_DataValid_gold",1,1);
			enable_signal_spy("/UUT/SB_DataValid","SB_DataValid_gold",0);
			
			wait;
	end process spy_process;			

end architecture arch_top_tb_Store_Buf;
