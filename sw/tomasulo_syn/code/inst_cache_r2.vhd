------------------------------------------------------------------------------
-- Create/rivision Date:    7/13/2008, 7/15/2009, 6/28/2010
-- Design Name:    Instruction Cache Emulator Unit
-- Module Name:    inst_cache
-- Authors:         Rahul P. Tekawade, Gandhi Puvvada
-- File: inst_cache_r2.vhd
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
-- use ieee.std_logic_unsigned.all;
--synopsys translate_off
use work.instr_stream_pkg.all; -- instruction stream defining package
--synopsys translate_on
------------------------------------------------------------------------------
entity inst_cache is 
generic (
         DATA_WIDTH     : integer := 128; --DATA_WIDTH_CONSTANT; -- defined as 128 in the instr_stream_pkg; 
         ADDR_WIDTH     : integer := 6 --ADDR_WIDTH_CONSTANT  -- defined as 6 in the instr_stream_pkg; 
        );
port (
      Clk           : in std_logic; 
      Resetb       : in std_logic;
      read_cache    : in std_logic;
      abort_prev_read : in std_logic; -- will be used under jump or successful branch
      addr          : in std_logic_vector (31 downto 0);
      cd0           : out std_logic_vector (31 downto 0);
      cd1           : out std_logic_vector (31 downto 0);
      cd2           : out std_logic_vector (31 downto 0);
      cd3           : out std_logic_vector (31 downto 0);
		-- synopsys translate_off
		registered_addr : out std_logic_vector(31 downto 0);
		-- synopsys translate_on	
      read_hit      : out std_logic;
	  
      fio_icache_addr_a        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      fio_icache_data_in_a     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      fio_icache_wea           : in  std_logic; 
      fio_icache_data_out_a    : out std_logic_vector(DATA_WIDTH-1 downto 0);
	  fio_icache_ena		   : in  std_logic	  
     ); 
end inst_cache;
------------------------------------------------------------------------------
architecture behv of inst_cache is

--constant DATA_WIDTH : integer := 128;
--constant ADDR_WIDTH : integer := 6;
signal count : std_logic_vector( 3 downto 0);               -- count for latency
-- signal indx : std_logic_vector ( 3 downto 0);               -- index to the register array contaning latencies
signal latency : std_logic_vector ( 3 downto 0);            -- latency read from the latency register array
signal data_out : std_logic_vector(127 downto 0);
signal pending_req : std_logic; -- basically a new read_cache request is recorded as a pending request
signal read_hit_int : std_logic; -- internal signal for the output port read_hit

-- Type definition for latencies
-- Type definition for a 4-bit individual register for the register array.
subtype reg is std_logic_vector (3 downto 0);
-- Type definition of 16-latencies register array
type reg_array is array (0 to 15) of reg;
constant latency_array : reg_array :=  -- minimum latency = 0 after registering the request
              -- ( X"7",     --0                             -- which guarantees the 1 clock delay due to BRAM
                -- X"1",     --1   
                -- X"2",     --2
                -- X"3",     --3      -- however, the BRAM works like a pipeline
                -- X"6",     --4      -- if the latency is continuously 0 and if 
                -- X"6",     --5      -- read_cache request is true continuously. 
                -- X"6",     --6
                -- X"7",     --7
                -- X"3",     --8
                -- x"1",     --9
                -- x"2",     --10
                -- X"6",     --11
                -- X"4",     --12
                -- X"5",     --13
                -- X"8",     --14
                -- X"7"      --15
              -- );
              ( X"3",     --0                             -- which guarantees the 1 clock delay due to BRAM
                X"5",     --1   
                X"0",     --2
                X"0",     --3      -- however, the BRAM works like a pipeline
                X"0",     --4      -- if the latency is continuously 0 and if 
                X"0",     --5      -- read_cache request is true continuously. 
                X"0",     --6
                X"5",     --7
                X"4",     --8
                x"9",     --9
                x"2",     --10
                X"7",     --11
                X"0",     --12
                X"0",     --13
                X"A",     --14
                X"7"      --15
              );

------

-- component declarations [ instruction memory]
component inst_cache_dpram is
generic (
         DATA_WIDTH     : integer := 128; -- defined as 128 in the instr_stream_pkg; 
         ADDR_WIDTH     : integer := 6  -- defined as 6 in the instr_stream_pkg; 
        );
port (
      Clka          : in std_logic;
      addr_a        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      data_in_a     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      wea           : in  std_logic; 
      data_out_a    : out std_logic_vector(DATA_WIDTH-1 downto 0);
		ena			  : in  std_logic;	

      Clkb          : in  std_logic; 
      addr_b        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      -- data_in_b     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      -- web           : in  std_logic; 
      data_out_b    : out std_logic_vector(DATA_WIDTH-1 downto 0)
     ); 
 end component inst_cache_dpram;  

begin  -- begin of architecture 
    
-- component port map
memory: inst_cache_dpram
       generic map(DATA_WIDTH => DATA_WIDTH, ADDR_WIDTH => ADDR_WIDTH)
       port map(Clka => Clk, addr_a => fio_icache_addr_a, data_in_a => fio_icache_data_in_a, 
	   wea => fio_icache_wea, data_out_a => fio_icache_data_out_a, ena => fio_icache_ena,   
	   Clkb=>Clk, addr_b=>addr(9 downto 4), data_out_b=>data_out); 
   -- note that we shall not be sending the registered address as we
   -- do not want to create an additional pipeline stage!


read_hit <= read_hit_int ; -- read_hit port is assigned with internal read_hit_int
-------------------------------------------------------------------------------
pending_req_two_state_state_machine: process ( Clk, Resetb )

begin
    
    if (Resetb = '0') then

      pending_req <= '0';
  
    elsif Clk'event and Clk = '1' then

      case pending_req is
  
        when '0' =>
          if read_cache = '1' then
              pending_req <= '1';
          end if;
          
        when others =>  -- i.e. when  '1' =>
          -- if ( ( (read_hit_int = '1') or  (abort_prev_read = '1') ) and (read_cache = '0') ) then
		  if (read_cache = '0' )  then
             pending_req <= '0';
          end if;
      
       end case;
   
    end if;
end process pending_req_two_state_state_machine;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
register_addr_and_latecy: process ( Clk, Resetb )

begin
    if (Resetb = '0') then
	-- synopsys translate_off
      registered_addr <= x"08080808"; -- actually does not need any initalization
	-- synopsys translate_on
      latency <= X"0"; -- actually does not need any initalization
      count <= X"0";
  --    indx <= X"0"; -- 
      
    elsif ( Clk'event and Clk='1') then     
		if ( ( read_cache = '1') and 
             ( (pending_req = '0') or (read_hit_int = '1') or (abort_prev_read = '1') ) 
           ) then -- i.e. a new request has been initiated; 
                -- we need to record the address of memory location to be read,
                --                   the latency pointed to by the index,
                --                   initiate count to zero, and
                --                   increment the index
          -- synopsys translate_off
            registered_addr <= addr(31 downto 0);   -- need to change according to the width
          -- synopsys translate_on
          
			latency <= latency_array (CONV_INTEGER(unsigned(addr(9 downto 6))));
            count <= X"0";
         --   indx <= unsigned(indx) + 1; -- index will naturally roll over
        elsif (pending_req = '1') then
            count <= unsigned(count) + 1;
		else
			count <= X"0";
        end if;                             
    end if;                                 
  
end process register_addr_and_latecy;
-------------------------------------------------------------------------------
read_hit_comb_process:
   process (pending_req, latency, count, data_out)
   begin
      if ((pending_req = '1') and (latency = count)) then
          read_hit_int <= '1';      
          cd0 <= data_out( 31 downto 0);  
          cd1 <= data_out( 63 downto 32);  
          cd2 <= data_out( 95 downto 64);
          cd3 <= data_out( 127 downto 96);
      else 
          read_hit_int <= '0';
          cd0 <= (others => 'X'); --  don't care
          cd1 <= (others => 'X'); --  don't care
          cd2 <= (others => 'X'); --  don't care
          cd3 <= (others => 'X'); --  don't care
     end if;
end process read_hit_comb_process;
-------------------------------------------------------------------------------
end behv;
