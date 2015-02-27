-------------------------------------------------------------------------------
-- Design   : Register array for Instruction Fetch Queue  i_fetch_q
-- Project  : Tomasulo Processor 
-- Author   : Gandhi Puvvada 
-- Company  : University of Southern California 
-- File: i_fetch_fifo_ram_reg_array.vhd (original file name: ram_n_addr_m_data_dp_clk.vhd)
-- Date: 6/27/2004, 4/13/2008, 7/22/2008
   
 -- Following is the VHDL code for a dual-port RAM with a write clock.
 -- There is no read clock. The read port is not a clocked port.
 -- This is actually a register array. with no input or output registers.
  -- ===================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity i_fetch_fifo_ram_reg_array is

generic (N: integer := 2; M: integer := 32);

port (
	clka : in std_logic;
	wea : in std_logic;
	addra : in std_logic_vector(N-1 downto 0);
	dia : in std_logic_vector(M-1 downto 0);
	addrb : in std_logic_vector(N-1 downto 0);
	dob : out std_logic_vector(M-1 downto 0)
	);

end entity i_fetch_fifo_ram_reg_array;

architecture syn of i_fetch_fifo_ram_reg_array is

	type ram_type is array (2**N-1 downto 0) of std_logic_vector (M-1 downto 0);
	signal RAM : ram_type;
	-- signal read_addrb : std_logic_vector(1 downto 0) := "00";

begin

	process (clka)
	
	begin

	    if (clka'event and clka = '1') then
		if (wea = '1') then
			RAM(conv_integer(addra)) <= dia;
		end if;
	    end if;
	    
	end process;
	      	     
  	dob <= RAM(conv_integer(addrb)); -- not a clocked-port
   
end architecture syn; 

-----------------------------------------------------------------------------
