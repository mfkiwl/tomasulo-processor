-------------------------------------------------------------------------------
-- Design   : Register array acting as data cache
-- Project  : Tomasulo Processor 
-- Author   : Rohit Goel 
-- Company  : University of Southern California 
-- Following is the VHDL code for a dual-port RAM with a write clock.
-- There is no read clock. The read port is not a clocked port.
-- This is actually a register array. with no input or output registers.
-- ===================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ls_buffer_ram_reg_array is

generic (ADDR_WIDTH: integer := 6; DATA_WIDTH: integer := 32);

port (
	clka      : in  std_logic;
	wea       : in  std_logic;
	addra     : in  std_logic_vector  (ADDR_WIDTH-1 downto 0);
	dia       : in  std_logic_vector  (DATA_WIDTH-1 downto 0);
	addrb     : in  std_logic_vector  (ADDR_WIDTH-1 downto 0);
	dob       : out std_logic_vector  (DATA_WIDTH-1 downto 0);
	rea       : in std_logic ;
	mem_wri   : out std_logic ;
	mem_exc   : out std_logic ;
	mem_read  : out std_logic 
	
	-- modified by kapil 
	
	--addrc : in std_logic_vector(ADDR_WIDTH-1 downto 0);
	--doc : out std_logic_vector(DATA_WIDTH-1 downto 0)
	-- end modified by kapil 
	
	
	);

end entity ls_buffer_ram_reg_array;

architecture syn of ls_buffer_ram_reg_array is

	type ram_type is array (0 to 2**ADDR_WIDTH-1) of std_logic_vector (DATA_WIDTH-1 downto 0);
	signal RAM : ram_type :=
	(	X"0000_FFFF", X"0000_0010", X"0000_0020", X"0000_0030",	-- 00 04 08 0c
		X"0000_0040", X"0000_0050", X"0000_0060", X"0000_0070",
		X"0000_0080", X"0000_0001", X"0000_0002", X"0000_00B0",
		X"0000_00C0", X"0000_00D0", X"0000_00E0", X"0000_00F0",
		
		X"0000_0100", X"0000_0110", X"0000_0120", X"0000_0130",
		X"0000_0140", X"0000_0150", X"0000_0160", X"0000_0170",
		X"0000_0180", X"0000_0190", X"0000_01A0", X"0000_01B0",
		X"0000_01C0", X"0000_01D0", X"0000_01E0", X"0000_01F0",
		
		X"0000_0200", X"0000_0210", X"0000_0220", X"0000_0230",
		X"0000_0240", X"0000_0250", X"0000_0260", X"0000_0270",
		X"0000_0280", X"0000_0290", X"0000_02A0", X"0000_02B0",
		X"0000_02C0", X"0000_02D0", X"0000_02E0", X"0000_02F0",
		
		X"0000_0300", X"0000_0310", X"0000_0320", X"0000_0330",
		X"0000_0340", X"0000_0350", X"0000_0360", X"0000_0370",
		X"0000_0380", X"0000_0390", X"0000_03A0", X"0000_03B0",
		X"0000_03C0", X"0000_03D0", X"0000_03E0", X"0000_03F0"
	);
	-- signal read_addrb : std_logic_vector(1 downto 0) := "00";
	
	--signal doc_async : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

	process (clka)
	
	begin

	    if (clka'event and clka = '1') then
	         mem_read     <= rea ;
	         dob          <= RAM(conv_integer(addrb)); 
	         mem_wri <= '0' ;
	         mem_exc <= '0';
	         
	         
	        
			if (wea = '1') then
				RAM(conv_integer(addra)) <= dia;
				mem_wri <= '1' ;
				mem_exc <= '0'; 
				else
				
			end if;
	    end if;
	    
	end process;
	
	--doc <= RAM(conv_integer(addrc)); -- not a clocked-port
	      	     
  	
 
end architecture syn; 

-----------------------------------------------------------------------------
