-------------------------------------------------------------------------------
--
-- Design   : Test Bench test_all_streams
-- Project  : Tomasulo Processor 
-- Company  : University of Southern California 
-- Module: mega_tb
-- File: mega_tb.vhd
-- Date: 7/26/08
-- BY: Prasanjeet Das
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- This testbench creates clk and Reset for the  the  Tomasulo top
--  
library std,ieee, modelsim_lib;
use ieee.std_logic_textio.all;
use ieee.std_logic_1164.all;
use modelsim_lib.util.all;

library ee560;
use ee560.all;
-----------------------------------------------------------------------------
entity mega_tb is
generic (ADDR_WIDTH: integer := 6; DATA_WIDTH: integer := 32);--added by Sabya: data cache width
end entity mega_tb;

--use work.instr_stream_pkg.all; -- added by Sabya: we have the mem signal here, which is the instruction memory. see if we can just use this signal or do we need to use signal spy?

architecture mega_tb_a of mega_tb is

-- local signals
			signal clk, Reset : std_logic;
-- clock period
    constant clk_period: time := 20 ns;
-- clock count signal to make it easy for debugging
    signal clk_count: integer range 0 to 9999;
-- a 10% delayed clock for clock counting
	signal clk_delayed10 : std_logic;
	signal walking_led : std_logic;
	signal fio_icache_addr_IM        : std_logic_vector(5 downto 0); --changed by PRASANJEET
  signal fio_icache_data_in_IM     : std_logic_vector(127 downto 0); --changed by PRASANJEET
  signal fio_icache_wea_IM         : std_logic; --changed by PRASANJEET 
  signal fio_icache_data_out_IM    : std_logic_vector(127 downto 0); --changed by PRASANJEET
	signal fio_icache_ena_IM		       : std_logic; -- changed by PRASANJEET
   
  signal fio_dmem_addr_DM          : std_logic_vector(5 downto 0); --changed by PRASANJEET
  signal fio_dmem_data_out_DM      : std_logic_vector(31 downto 0); --changed by PRASANJEET	
      
  signal fio_dmem_data_in_DM       : std_logic_vector(31 downto 0); --changed by PRASANJEET
  signal fio_dmem_wea_DM    		  : std_logic; --changed by PRASANJEET
		
--data types and signals for data and instruction memory

--	type ram_type is array (0 to 2**ADDR_WIDTH-1) of std_logic_vector (DATA_WIDTH-1 downto 0);
--	signal dram_array : ram_type;
	
	signal dram_array : std_logic_vector (DATA_WIDTH*(2**ADDR_WIDTH)-1 downto 0);
 -- component declarations


component tomasulo_top 
port (
      Reset                 : in std_logic;
      --digi_address          : in std_logic_vector(5 downto 0); -- input ID for the register we want to see
      --digi_data             : out std_logic_vector(31 downto 0); -- output data given by the register
      clk                   : in std_logic;
		--modified by Prasanjeet
		-- signals corresponding to Instruction memory
		  fio_icache_addr_IM        : in  std_logic_vector(5 downto 0); --changed by PRASANJEET
      fio_icache_data_in_IM     : in  std_logic_vector(127 downto 0); --changed by PRASANJEET
      fio_icache_wea_IM         : in  std_logic; --changed by PRASANJEET 
      fio_icache_data_out_IM    : out std_logic_vector(127 downto 0); --changed by PRASANJEET
	    fio_icache_ena_IM		     : in  std_logic; -- changed by PRASANJEET

      fio_dmem_addr_DM          : in std_logic_vector(5 downto 0); --changed by PRASANJEET
      fio_dmem_data_out_DM      : out std_logic_vector(31 downto 0); --changed by PRASANJEET	
      
      fio_dmem_data_in_DM       : in std_logic_vector(31 downto 0); --changed by PRASANJEET
      fio_dmem_wea_DM    		  : in std_logic; --changed by PRASANJEET
		
		  Test_mode                 : in std_logic; -- for using the test mode 
      
      walking_led_start         : out std_logic		
		-- end modified by Prasanjeet
     );

end  component ;
	

   
 	
   begin

   UUT: tomasulo_top port map (
      Reset  =>   Reset,      
      clk    =>   clk,
		  fio_icache_addr_IM     => fio_icache_addr_IM,
      fio_icache_data_in_IM  => fio_icache_data_in_IM, 
      fio_icache_wea_IM      => fio_icache_wea_IM , 
      fio_icache_data_out_IM => fio_icache_data_out_IM,
	    fio_icache_ena_IM		    => fio_icache_ena_IM,

      fio_dmem_addr_DM       => fio_dmem_addr_DM,
      fio_dmem_data_out_DM   => fio_dmem_data_out_DM,	
      
      fio_dmem_data_in_DM    => fio_dmem_data_in_DM,
      fio_dmem_wea_DM    		  => fio_dmem_wea_DM,
		
		  Test_mode              => '0',  
      
      walking_led_start      => walking_led	
		-- end modified by Prasanjeet
    );
   
	clock_generate: process
	begin
	  clk <= '0', '1' after (clk_period/2);
	  wait for clk_period;
	end process clock_generate;
	
	-- Reset activation and inactivation
	
	 reset_process : process
	 begin
  
	  Reset <= '1' ;
	  wait for 80.1 ns ;
	  Reset <= '0';
	  
	  wait;
	 end process; 

	  clk_delayed10 <= clk after (clk_period/10);

	-- clock count processes
	
	clk_count_process: process (clk_delayed10, Reset)
	      begin
			if Reset = '1' then
	      	  clk_count <= 0;
	      	elsif clk_delayed10'event and clk_delayed10 = '1' then
	      	  clk_count <= clk_count + 1;  
	      	end if;
	      end process clk_count_process;
	
	
end architecture mega_tb_a;
