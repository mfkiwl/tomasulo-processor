------------------------------------------------------------------------------
-- Create/rivision Date:    03/25/10, 
-- Minor revision: rev 4 on 7/14/2011 by Gandhi Puvvada
-- Design Name:    DATA Cache Emulator Unit
-- Module Name:    data_cache
-- Authors:         Manpreet Billing , Mohan SK
-- File : data_cache_r4.vhd
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
-- use ieee.std_logic_unsigned.all;
--synopsys translate_off
use work.instr_stream_pkg.all; -- instruction stream defining package
--synopsys translate_on
------------------------------------------------------------------------------
entity data_cache is 
generic (
         DATA_WIDTH     : integer := 32; --DATA_WIDTH_CONSTANT; -- defined as 128 in the instr_stream_pkg; 
         ADDR_WIDTH     : integer := 6 --ADDR_WIDTH_CONSTANT  -- defined as 6 in the instr_stream_pkg; 
        );
port (
      Clk           : in std_logic; 
      Resetb       : in std_logic;
      DCE_ReadCache    : in std_logic;
	  -- July 14, 2011 -- I have comment it out the following line as it is left unconnected in the top_synth.vhd -- Gandhi Puvvada
      -- Abort_PrevRead : in std_logic; -- will be used under jump or successful branch -- 
	  -- June 27, 2010 The above pin is not properly connected in the top. So I am ignoring the pin and producing it here as Abort_PrevRead_int
	  -- Moreover, it does not make sense for other top modules to remember what data item the data cache emulator is reading, 
	  -- and figuring out and telling this module to abort. 
	  --addr          : in std_logic_vector (5 downto 0);
	  Iss_LdStOpcode       : in std_logic ;  
      Iss_LdStRobTag        : in std_logic_vector(4 downto 0); 
      Iss_LdStAddr         : in std_logic_vector(31 downto 0); 
	  --- added --------
	  Iss_LdStPhyAddr          :   in  std_logic_vector(5 downto 0);  
   
	  ------------------
      Lsbuf_DCETaken       : in std_logic;
	  
	  Cdb_Flush                : in std_logic ; -- Cdb_Flush signal
	  Rob_TopPtr              : in std_logic_vector(4 downto 0);
	  Cdb_RobDepth                : in std_logic_vector(4 downto 0);
	  
      SB_WriteCache   : in std_logic ;
      SB_AddrDmem       : in std_logic_vector (31 downto 0);
      SB_DataDmem       : in std_logic_vector (31 downto 0);
	   -- translate_off 
     DCE_instruction    : out std_logic_vector(31 downto 0);
	 -- translate_on
	 
	 -- translate_off 
     Iss_instructionLsq       : in std_logic_vector(31 downto 0);
	 -- translate_on
	  
       --data_out      : out std_logic_vector (31 downto 0);
	  DCE_Opcode          : out std_logic ;
      DCE_RobTag          : out std_logic_vector(4 downto 0);  
      DCE_Addr            : out std_logic_vector(31 downto 0);    
      DCE_MemData            : out std_logic_vector (31 downto 0 ) ; --  data from data memory in the case of lw
      ------------------new pin added for CDB-----------
	   
      DCE_PhyAddr          :   out std_logic_vector(5 downto 0);
------------------------------------------------------------	  
		-- synopsys translate_off
		registered_addr : out std_logic_vector(5 downto 0);
		registered_SB_AddrDmem : out std_logic_vector(5 downto 0);
		-- synopsys translate_on	
    DCE_ReadDone      : out std_logic;
	  DCE_WriteDone    : out std_logic;
	  DCE_ReadBusy     : out std_logic;
	  DCE_WriteBusy       : out std_logic
    --  fio_icache_addr_a        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    --  fio_icache_data_in_a     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    --  fio_icache_wea           : in  std_logic; 
    --  fio_icache_data_out_a    : out std_logic_vector(DATA_WIDTH-1 downto 0);
	--  fio_icache_ena		   : in  std_logic	  
     ); 
end data_cache;
------------------------------------------------------------------------------
architecture behv of data_cache is

--constant DATA_WIDTH : integer := 32;
--constant ADDR_WIDTH : integer := 6;
signal count_rd : std_logic_vector( 3 downto 0);               -- count for latency
-- signal indx_rd : std_logic_vector ( 3 downto 0);               -- index to the register array contaning latencies
signal latency_rd : std_logic_vector ( 3 downto 0);            -- latency read from the latency register array
signal data_out_mem , reg_instruction: std_logic_vector(31 downto 0);
signal count_wr : std_logic_vector( 3 downto 0);               -- count for latency
-- signal indx_wr : std_logic_vector ( 3 downto 0);               -- index to the register array contaning latencies
signal latency_wr : std_logic_vector ( 3 downto 0);            -- latency read from the latency register array
signal pending_rd_req : std_logic; -- basically a new DCE_ReadCache request is recorded as a pending request
signal DCE_ReadDone_int : std_logic; -- internal signal for the output port DCE_ReadDone
signal pending_wr_req : std_logic; -- basically a new DCE_ReadCache request is recorded as a pending request
signal DCE_WriteDone_int : std_logic; -- internal signal for the output port DCE_WriteDone
signal WriteDone , ReadDone , mem_exc : std_logic ;

signal read_addr , reg_addr : std_logic_vector(31 downto 0);
signal reg_opcode , Abort_PrevRead_int, Abort_incoming_RD_int , read_hit_flag , DCE_ReadBusy_int: std_logic;
-- The line below is commented out as the signal "abort-all is causing combinational feedback 
-- signal reg_opcode , abort_all , read_hit_flag , DCE_ReadBusy_int: std_logic;
signal reg_RdTag , lw_Cdb_RobDepth ,incoming_lw_depth:std_logic_vector(4 downto 0);
signal reg_PhyAddr : std_logic_vector(5 downto 0);

signal WriteEnable , DCE_WriteBusy_int : std_logic;
signal SBreg_addr , SBreg_data , DataDmem: std_logic_vector(31 downto 0);
signal AddrDmem : std_logic_vector(5 downto 0);
-- Type definition for latencies
-- Type definition for a 4-bit individual register for the register array.
subtype reg is std_logic_vector (3 downto 0);
-- Type definition of 16-latencies register array
type reg_array is array (0 to 15) of reg;
--type test is array (0 to 31) of reg_array ;
constant latency_array_rd : reg_array :=  -- minimum latency = 0 after registering the request
              ( X"6",     --0                             -- which guarantees the 1 clock delay due to BRAM
                X"1",     --1   
                X"2",     --2
                X"7",     --3      -- however, the BRAM works like a pipeline
                X"4",     --4      -- if the latency is continuously 0 and if 
                X"6",     --5      -- DCE_ReadCache request is true continuously. 
                X"4",     --6
                X"4",     --7
                X"7",     --8
                x"6",     --9
                x"5",     --10
                X"4",     --11
                X"3",     --12
                X"3",     --13
                X"6",     --14
                X"2"      --15
              );

constant latency_array_wr : reg_array :=  -- minimum latency = 0 after registering the request
              ( X"7",     --0                             -- which guarantees the 1 clock delay due to BRAM
                X"6",     --1   
                X"5",     --2
                X"3",     --3      -- however, the BRAM works like a pipeline
                X"3",     --4      -- if the latency is continuously 0 and if 
                X"2",     --5      -- DCE_WriteCache request is true continuously. 
                X"1",     --6
                X"0",     --7
                X"0",     --8
                x"1",     --9
                x"2",     --10
                X"3",     --11
                X"4",     --12
                X"5",     --13
                X"6",     --14
                X"7"      --15
              );

------

-- component declarations [ data memory]
component ls_buffer_ram_reg_array is

generic (ADDR_WIDTH: integer := 6; DATA_WIDTH: integer := 32);

port (
	Clka      : in  std_logic;
	wea       : in  std_logic;
	addra     : in  std_logic_vector  (ADDR_WIDTH-1 downto 0);
	dia       : in  std_logic_vector  (DATA_WIDTH-1 downto 0);
	addrb     : in  std_logic_vector  (ADDR_WIDTH-1 downto 0);
	dob       : out std_logic_vector  (DATA_WIDTH-1 downto 0);
	rea       : in std_logic ;
	mem_wri   : out std_logic ;
	mem_exc   : out std_logic ;
	mem_read  : out std_logic 
	
	);

end component ls_buffer_ram_reg_array;


begin  -- begin of architecture 
    
-- component port map
memory:  ls_buffer_ram_reg_array 
         generic map (ADDR_WIDTH => ADDR_WIDTH, DATA_WIDTH => DATA_WIDTH)
         port map (
	       Clka     =>  Clk       ,
	       wea      =>  WriteEnable, --changed by PRASANJEET to support memory mapped I/O
	       addra    =>  AddrDmem, --mem_addr( 7 downto 2 ) changed by PRASANJEET	 ,
	       dia      =>  DataDmem		, --changed by PRASANJEET
	       addrb    =>  read_addr(7 downto 2), --ReadAddr ( 7 downto 2 ) , --changed by PRASANJEET
	       dob      =>  data_out_mem,
	       rea      =>  DCE_ReadCache,
	       mem_wri  =>  WriteDone  ,
	       mem_exc  =>  mem_exc  ,
	       mem_read =>  ReadDone 
     	);

   
lw_Cdb_RobDepth <= unsigned(reg_RdTag) - unsigned(Rob_TopPtr);
incoming_lw_depth <= unsigned(Iss_LdStRobTag) - unsigned(Rob_TopPtr);

DCE_Opcode <= reg_opcode ;
DCE_RobTag <= reg_RdTag ;
DCE_Addr   <= reg_addr ;
DCE_PhyAddr <= reg_PhyAddr;
 -- translate_off 
DCE_instruction <= reg_instruction ;
 -- translate_on
read_addr <= Iss_LdStAddr when DCE_ReadCache = '1' else reg_addr ;

DCE_ReadDone <= DCE_ReadDone_int ; -- DCE_ReadDone port is assigned with internal DCE_ReadDone_int

-- Fix 6/27/2010 -- abort_all <= '1' when ((Cdb_Flush = '1' and lw_Cdb_RobDepth > Cdb_RobDepth and DCE_ReadBusy_int = '1') or
-- Fix 6/27/2010 --                       (Cdb_Flush = '1' and incoming_lw_depth > Cdb_RobDepth and DCE_ReadBusy_int = '0'))
-- Fix 6/27/2010 --                 else '0' ;
Abort_PrevRead_int <= '1' when (Cdb_Flush = '1' and lw_Cdb_RobDepth > Cdb_RobDepth) else '0';
Abort_incoming_RD_int <= '1' when (Cdb_Flush = '1' and incoming_lw_depth > Cdb_RobDepth and DCE_ReadBusy_int = '0') else '0'; 
-------------------------------------------------------
lw_info_tranfer: process ( Clk, Resetb )

begin
    
    if (Resetb = '0') then

      reg_opcode <= '0';
      
      --reg_addr <= X"0";
    elsif Clk'event and Clk = '1' then

       if (DCE_ReadCache = '1') then
          reg_opcode <= Iss_LdStOpcode ;
          reg_RdTag <= Iss_LdStRobTag ;
          reg_addr  <= Iss_LdStAddr ;
		  reg_PhyAddr <= Iss_LdStPhyAddr;
		   -- translate_off 
		  reg_instruction <= Iss_instructionLsq;
		  
		   -- translate_on
		end if ;
  end if;
end process lw_info_tranfer;

-------------------------------------------------------------------------------
pending_rd_req_two_state_state_machine: process ( Clk, Resetb )

begin
    
    if (Resetb = '0') then

      pending_rd_req <= '0';
  
    elsif Clk'event and Clk = '1' then

      case pending_rd_req is
  
        when '0' =>   --- busy signal from data emulator
          if ((DCE_ReadCache = '1') and (Abort_incoming_RD_int = '0')) then -- and (abort_all = '0')) then
              pending_rd_req <= '1';
          end if;
          
        when others =>  -- i.e. when  '1' =>
          if ( ((DCE_ReadDone_int = '1') and (DCE_ReadCache = '0')) or (Abort_incoming_RD_int = '1') or (Abort_PrevRead_int = '1')) then -- (abort_all = '1') ) then		
		-- July 14, 2011 Gandhi: I commented out the following line and replaced it with the above line as now we do not have Abort_PrevRead  input any more.
		  --  if ( (((DCE_ReadDone_int = '1') or  (Abort_PrevRead = '1')) and (DCE_ReadCache = '0')) or (Abort_incoming_RD_int = '1') or (Abort_PrevRead_int = '1')) then -- (abort_all = '1') ) then
  -- July 27, 2010 fix   --  if ( ( ((DCE_ReadDone_int = '1') or  (Abort_PrevRead = '1')) and (DCE_ReadCache = '0')) or (abort_all = '1') ) then
		  --if (DCE_ReadCache = '0' )  then
             pending_rd_req <= '0';
          end if;
      
       end case;
   
    end if;
end process pending_rd_req_two_state_state_machine;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
register_addr_and_latecy: process ( Clk, Resetb )
variable indx_rd : std_logic_vector ( 3 downto 0); 
begin
    if (Resetb = '0') then
	-- synopsys translate_off
     -- registered_addr <= x"08080808"; -- actually does not need any initialization
	-- synopsys translate_on
      latency_rd <= X"0"; -- actually does not need any initialization
      count_rd <= X"0";
      indx_rd := X"0"; -- actually does not need any initialization
      
    elsif ( Clk'event and Clk='1') then     
		if ( ((DCE_ReadCache = '1') and (Abort_incoming_RD_int = '0')) and -- valid incoming read request
             ( (pending_rd_req = '0') or (DCE_ReadDone_int = '1') )  -- or (abort_all = '1') )  -- and no pending (= on going) request
			 -- July 14, 2011 Gandhi: commented out the bottom line and added the line above
             --( (pending_rd_req = '0') or (DCE_ReadDone_int = '1') or (Abort_PrevRead = '1'))  -- or (abort_all = '1') )  -- and no pending (= on going) request
           ) then -- i.e. a new request has been initiated; 
                -- we need to record the address of memory location to be read,
                --                   the latency pointed to by the index,
                --                   initiate count to zero, and
                --                   increment the index
          -- synopsys translate_off
            registered_addr <= read_addr(5 downto 0);   -- need to change according to the width
          -- synopsys translate_on
		    indx_rd := read_addr(5 downto 2); -- mod 16 of read addr
     			latency_rd <= latency_array_rd (CONV_INTEGER(unsigned(indx_rd)));
        count_rd <= X"0";
            
        elsif (pending_rd_req = '1') then
            count_rd <= unsigned(count_rd) + 1;
		else
			count_rd <= X"0";
        end if;                             
    end if;                                 
  
end process register_addr_and_latecy;
-------------------------------------------------------------------------------
DCE_ReadFlag_process :
   process(Clk,Resetb)
   begin
     if (Resetb = '0') then

      read_hit_flag <= '0';
  
    elsif Clk'event and Clk = '1' then
      if (DCE_ReadDone_int = '1' and Lsbuf_DCETaken = '0') then
        read_hit_flag <= '1' ;
      end if ;
      
      if ((read_hit_flag = '1') and (Lsbuf_DCETaken = '1'))then
        read_hit_flag <= '0';
      end if;
   end if ; -- end of clock if 
   end process;  
-------------------------------------------------------------------------------
DCE_MemData <= data_out_mem;
DCE_ReadDone_comb_process:
   process (pending_rd_req, latency_rd, count_rd, data_out_mem , read_hit_flag)
   begin
      if (((pending_rd_req = '1') and (latency_rd = count_rd)) or (read_hit_flag = '1')) then
          DCE_ReadDone_int <= '1';      
                
      else 
          DCE_ReadDone_int <= '0';
        
      end if;
end process DCE_ReadDone_comb_process;
-------------------------------------------------------------------------------
DCE_ReadBusy <= DCE_ReadBusy_int ;
DCE_ReadBusy_comb_process:
   process (pending_rd_req, latency_rd, count_rd, 
			-- abort_all,  
			Abort_PrevRead_int , read_hit_flag , Lsbuf_DCETaken) -- July 14, 2011 Gandhi: changed Abort_PrevRead to Abort_PrevRead_int
   begin
      -- if ((abort_all = '1') or (Abort_PrevRead = '1')) then
	  -- if (Abort_PrevRead = '1') or (Abort_PrevRead_int = '1') then -- removed (Abort_PrevRead = '1')
	  if (Abort_PrevRead_int = '1') then 
        DCE_ReadBusy_int <= '0' ;
      elsif ((pending_rd_req = '1') and (latency_rd /= count_rd)) then
         DCE_ReadBusy_int <= '1'; 
      elsif ((pending_rd_req = '1') and (latency_rd = count_rd) and (Lsbuf_DCETaken = '0')) then
         DCE_ReadBusy_int <= '1';
      elsif ((read_hit_flag = '1') and (Lsbuf_DCETaken = '0')) then
         DCE_ReadBusy_int <= '1' ;
      else
         DCE_ReadBusy_int <= '0' ;    	  
      end if;
end process DCE_ReadBusy_comb_process;
-------------------------------------------------------------------------------
-------------------------------------------------------
SB_info_tranfer: process ( Clk, Resetb )

begin
    
    if (Resetb = '0') then

     -- Cache_Write <= '0';
 
      SBreg_data <= (others => '0');
       SBreg_addr <= (others => '0');    
    elsif Clk'event and Clk = '1' then

       if (SB_WriteCache = '1' and DCE_WriteBusy_int = '0') then
        
          SBreg_data <= SB_DataDmem ;
          SBreg_addr  <= SB_AddrDmem ;
		
     end if ;
  end if;
end process SB_info_tranfer;

WriteEnable <= SB_WriteCache when (DCE_WriteBusy_int = '0') else '1' ;
AddrDmem  <= SB_AddrDmem(7 downto 2) when (DCE_WriteBusy_int = '0') else SBreg_addr(7 downto 2) ;
DataDmem  <= SB_DataDmem when (DCE_WriteBusy_int = '0') else SBreg_data;
-------------------------------------------------------------------------------

DCE_WriteDone <= DCE_WriteDone_int ; -- DCE_WriteDone port is assigned with internal DCE_WriteDone_int
DCE_WriteBusy <= DCE_WriteBusy_int ;

-------------------------------------------------------------------------------
pending_wr_req_two_state_state_machine: process ( Clk, Resetb )

begin
    
    if (Resetb = '0') then

      pending_wr_req <= '0';
  
    elsif Clk'event and Clk = '1' then

      case pending_wr_req is
  
        when '0' =>
          if SB_WriteCache = '1' then
              pending_wr_req <= '1';
          end if;
          
        when others =>  -- i.e. when  '1' =>
          if ( ( (DCE_WriteDone_int = '1')) and (SB_WriteCache = '0') ) then
		  --if (DCE_ReadCache = '0' )  then
             pending_wr_req <= '0';
          end if;
      
       end case;
   
    end if;
end process pending_wr_req_two_state_state_machine;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
register_addr_and_wr_latecy: process ( Clk, Resetb )
variable indx_wr : std_logic_vector ( 3 downto 0);
begin
    if (Resetb = '0') then
	-- synopsys translate_off
    --  registered_SB_AddrDmem <= b"001000"; -- actually does not need any initalization
	-- synopsys translate_on
      latency_wr <= X"0"; -- actually does not need any initialization
      count_wr <= X"0";
      indx_wr := X"0"; -- actually does not need any initialization
      
    elsif ( Clk'event and Clk='1') then     
		if ( ( SB_WriteCache = '1') and 
             ( (pending_wr_req = '0') or (DCE_WriteDone_int = '1')) 
           ) then -- i.e. a new request has been initiated; 
                -- we need to record the address of memory location to be read,
                --                   the latency pointed to by the index,
                --                   initiate count to zero, and
                --                   increment the index
          -- synopsys translate_off
            registered_SB_AddrDmem <= SB_AddrDmem(5 downto 0);   -- need to change according to the width
          -- synopsys translate_on
		    indx_wr := SB_AddrDmem(5 downto 2);  -- mod 16 of SB_AddrDmem
			latency_wr <= latency_array_wr (CONV_INTEGER(unsigned(indx_wr)));
            count_wr <= X"0";
            
			
        elsif (pending_wr_req = '1') then
            count_wr <= unsigned(count_wr) + 1;
		else
			count_wr <= X"0";
        end if;                             
    end if;                                 
  
end process register_addr_and_wr_latecy;
-------------------------------------------------------------------------------
DCE_WriteDone_comb_process:
   process (pending_wr_req, latency_wr, count_wr, SB_DataDmem)
   begin
      if ((pending_wr_req = '1') and (latency_wr = count_wr)) then
          DCE_WriteDone_int <= '1';      
         -- data_out <= data_out_mem;  
      else 
          DCE_WriteDone_int <= '0';
         -- data_out <= (others => 'X'); --  don't care
      end if;
end process DCE_WriteDone_comb_process;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
write_busy_comb_process:
   process (pending_wr_req, latency_wr, count_wr)
   begin
      if ((pending_wr_req = '1') and (latency_wr /= count_wr)) then
         DCE_WriteBusy_int <= '1'; 
      else
         DCE_WriteBusy_int <= '0';	  
      end if;
end process write_busy_comb_process;
-------------------------------------------------------------------------------


end behv;
