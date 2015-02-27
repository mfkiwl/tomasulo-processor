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
-----------------------------------------------------------------------------

--added by Sabya to use compiled library
library ee560;
use ee560.all;
------------------------------------------------------------------------------

entity top_tb is
end entity top_tb;

architecture arch_top_tb_Issue_Unit of top_tb is

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
	
-- Hierarchy signals (Golden Issue_Unit)
    signal  Resetb_gold 		:std_logic;        
    signal  IssInt_Rdy_gold 	:std_logic;
    signal  IssMul_Rdy_gold   	:std_logic;
    signal  IssDiv_Rdy_gold    	:std_logic;
    signal  IssLsb_Rdy_gold    	:std_logic;                    
	signal  Div_ExeRdy_gold    	:std_logic;
    signal  Iss_Int_gold       	:std_logic;
    signal  Iss_Mult_gold      	:std_logic; 
    signal  Iss_Div_gold       	:std_logic;
    signal  Iss_Lsb_gold       	:std_logic;  
-- Signals for the student's DUT (Issue_Unit)
    signal  Resetb 		  :std_logic;        
    signal  IssInt_Rdy    :std_logic;
    signal  IssMul_Rdy    :std_logic;
    signal  IssDiv_Rdy    :std_logic;
    signal  IssLsb_Rdy    :std_logic;                    
	signal  Div_ExeRdy    :std_logic;
    signal  Iss_Int       :std_logic;
    signal  Iss_Mult      :std_logic; 
    signal  Iss_Div       :std_logic;
    signal  Iss_Lsb       :std_logic;                
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
	
	component issue_unit
	port ( 
	  Clk             :   in std_logic;
      Resetb          :   in std_logic;   
      IssInt_Rdy      :   in std_logic;
      IssMul_Rdy      :   in std_logic;
      IssDiv_Rdy      :   in std_logic;
      IssLsb_Rdy      :   in std_logic;                    
      Div_ExeRdy      :   in std_logic;      
	  Iss_Int         :   out std_logic;
      Iss_Mult        :   out std_logic; 
      Iss_Div         :   out std_logic;
      Iss_Lsb         :   out std_logic   
	);
	end component issue_unit;
for 	Issue_Unit_UUT:  issue_unit use entity work.issue_unit(behavioral);
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

	Issue_Unit_UUT:  issue_unit
	port map (                
	  Clk             =>Clk,   
	  Resetb          =>Resetb,   
      IssInt_Rdy      =>IssInt_Rdy,
      IssMul_Rdy      =>IssMul_Rdy,
      IssDiv_Rdy      =>IssDiv_Rdy,
      IssLsb_Rdy      =>IssLsb_Rdy,                    
      Div_ExeRdy      =>Div_ExeRdy,      
	  Iss_Int         =>Iss_Int,
      Iss_Mult        =>Iss_Mult, 
      Iss_Div         =>Iss_Div,
      Iss_Lsb         =>Iss_Lsb     
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
		  --check outputs of Issue_Unit only--
-------------------------------------------------
	compare_outputs_Clkd: process (Clk_Delayed10, Reset)
		file my_outfile: text open append_mode is "TomasuloCompareTestLog.log";
		variable my_inline, my_outline: line;

		begin
			if (Reset = '0' and (Clk_Delayed10'event and Clk_Delayed10 = '0')) then			--- 10%after the middle of the clock.
				if (Iss_Int_gold /=Iss_Int) then
					write (my_outline, string'("ERROR! Iss_Int of TEST does not match Iss_Int_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Iss_Mult_gold /= Iss_Mult) then
					write (my_outline, string'("ERROR! Iss_Mult of TEST does not match Iss_Mult_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Iss_Div_gold /= Iss_Div) then
					write (my_outline, string'("ERROR! Iss_Div of TEST does not match Iss_Div_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Iss_Lsb_gold /= Iss_Lsb ) then
					write (my_outline, string'("ERROR! Iss_Lsb of TEST does not match Iss_Lsb_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
			end if;
		end process compare_outputs_Clkd;

	spy_process: process
		begin
--inputs
			init_signal_spy("/UUT/Resetb","Resetb",1,1);
			enable_signal_spy("/UUT/Resetb","Resetb",0);

			init_signal_spy("/UUT/IssInt_Rdy","IssInt_Rdy",1,1);
			enable_signal_spy("/UUT/IssInt_Rdy","IssInt_Rdy",0);
			
			init_signal_spy("/UUT/IssMul_Rdy","IssMul_Rdy",1,1);
			enable_signal_spy("/UUT/IssMul_Rdy","IssMul_Rdy",0);
			
			init_signal_spy("/UUT/IssDiv_Rdy","IssDiv_Rdy",1,1);
			enable_signal_spy("/UUT/IssDiv_Rdy","IssDiv_Rdy",0);
			
			init_signal_spy("/UUT/IssLsb_Rdy","IssLsb_Rdy",1,1);
			enable_signal_spy("/UUT/IssLsb_Rdy","IssLsb_Rdy",0);
			
			init_signal_spy("/UUT/Div_ExeRdy","Div_ExeRdy",1,1);
			enable_signal_spy("/UUT/Div_ExeRdy","Div_ExeRdy",0);						
--outputs--
			init_signal_spy("/UUT/Iss_Int","Iss_Int_gold",1,1);
			enable_signal_spy("/UUT/Iss_Int","Iss_Int_gold",0);
			
			init_signal_spy("/UUT/Iss_Mult","Iss_Mult_gold",1,1);
			enable_signal_spy("/UUT/Iss_Mult","Iss_Mult_gold",0);
			
			init_signal_spy("/UUT/Iss_Div","Iss_Div_gold",1,1);
			enable_signal_spy("/UUT/Iss_Div","Iss_Div_gold",0);
			
			init_signal_spy("/UUT/Iss_Lsb","Iss_Lsb_gold",1,1);
			enable_signal_spy("/UUT/Iss_Lsb","Iss_Lsb_gold",0);
			
		wait;
	end process spy_process;			

end architecture arch_top_tb_Issue_Unit;
