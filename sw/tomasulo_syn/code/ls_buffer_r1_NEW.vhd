-- File: ls_buffer.vhd
--
-- Tomasulo 2009
-- load-store buffer (buffer after lsq before CDB/Issue Unit)
--UPDATED ON: 7/24/09
-- Rohit Goel ,  Gandhi Puvvada
-- University of Southern California 
------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
------------------------------------------------------------------------------
--  Originally we wanted to have a  few location FIFO for the ls buffer. 
-- As we ran out of time, we made a single location buffer but we retained 
-- handhsake control signals on both sides of the buffer (the LSQ side and the
-- issue unit side) so that we can easily replace this with a FIFO later.
-- The selective flusing makes it a queue like LSQ (and not a pure FIFO) -- Gandhi 
------------------------------------------------------------------------------

entity ls_buffer is
port (
	     Clk				    : in  std_logic;
	    Resetb			        : in  std_logic;
		
	    --  from ROB  -- for fulsing the instruction in this buffer if appropriate.
       Cdb_Flush            : in std_logic ;
       Rob_TopPtr       : in std_logic_vector (4 downto 0 ) ;
       Cdb_RobDepth            : in std_logic_vector (4 downto 0 ) ;
	   
	   -- interface with lsq
	    Iss_LdStReady        : in std_logic ;
      Iss_LdStOpcode       : in std_logic ;  -- 1 = lw , 0 = sw
      Iss_LdStRobTag        : in std_logic_vector(4 downto 0); 
      Iss_LdStAddr         : in std_logic_vector(31 downto 0); 
      Iss_LdStData         : in std_logic_vector(31 downto 0);-- data to be written to memory in the case of sw
	  Iss_LdStPhyAddr          :   in  std_logic_vector(5 downto 0);  
	   -- translate_off 
     DCE_instruction    : in std_logic_vector(31 downto 0);
	 -- translate_on
	 
	 -- translate_off 
     Iss_instructionLsq       : in std_logic_vector(31 downto 0);
	 -- translate_on
     ---- interface with data cache emulator ----------------
      DCE_PhyAddr          :   in  std_logic_vector(5 downto 0);  
	  DCE_Opcode          : in std_logic ;
      DCE_RobTag          : in std_logic_vector(4 downto 0);  
      DCE_Addr            : in std_logic_vector(31 downto 0);    
      DCE_MemData: in std_logic_vector (31 downto 0 ) ; --  data from data memory in the case of lw
      DCE_ReadDone           : in std_logic ; -- data memory (data cache) reporting that read finished  -- from  ls_buffer_ram_reg_array -- instance name DataMem
      Lsbuf_LsqTaken         : out  std_logic; -- handshake signal to ls_queue
      Lsbuf_DCETaken         : out  std_logic; -- handshake signal to ls_queue
	  Lsbuf_Full         : out  std_logic; -- handshake signal to ls_queue
		-- interface with issue unit
	   -- from load buffer and store word
	         
	 -- translate_off 
     Lsbuf_instruction       : out std_logic_vector(31 downto 0);
	 -- translate_on
         Lsbuf_Ready        : out std_logic ;    
------------- changed as per CDB -------------		 
		Lsbuf_Data             :   out  std_logic_vector(31 downto 0);   
         Lsbuf_PhyAddr          :   out  std_logic_vector(5 downto 0);   
          Lsbuf_RobTag       : out std_logic_vector(4 downto 0) ;            
        
			Lsbuf_SwAddr           :   out std_logic_vector(31 downto 0);
			Lsbuf_RdWrite           :   out  std_logic;
      ------------------------------------------------------------
     
     
      Iss_Lsb      : in  std_logic  -- return signal from the issue unit
		);
end ls_buffer;

architecture struct of ls_buffer is

type array_4_5 is array (0 to 3) of std_logic_vector(4 downto 0) ;   --TAG
type array_4_6 is array (0 to 3) of std_logic_vector(5 downto 0) ;
type array_4_32 is array (0 to 3) of std_logic_vector(31 downto 0) ;   --DATA

signal  LsBufInstValid , LsBufInstValidTemp : std_logic_vector (3 downto 0) ; -- one bit for each location
signal  LsBufOpcode   : std_logic_vector ( 3 downto 0) ;
signal  LsbufRobTag      : array_4_5 ;
signal LsBufPhyAddr : array_4_6;
signal  LsBufData , LsBufSwAddr :array_4_32;
 -- translate_off 
signal LsBufInstruction    : array_4_32 ; -- [63:32] =  address; [31:0] = data
 -- translate_on
signal  lsq_incoming_Depth  : std_logic_vector( 4 downto 0 ) ; -- depth of incoming instruction from lsque or data emulator
signal  dce_incoming_Depth  : std_logic_vector( 4 downto 0 ) ; -- depth of incoming instruction from lsque or data emulator
signal  lsq_flush , dce_flush : std_logic;
signal  BufDepth : array_4_5 ; -- depth of each location of FIFO
signal  wr_ptr , rd_ptr  , wr_ptr_temp , rd_ptr_temp: std_logic_vector (2 downto 0) ; -- 3 bit read and write pointers for 4 location FIFO
signal  full_temp  , shift_2 , shift_3: std_logic ;

begin
    
  lsq_incoming_Depth <=   unsigned(Iss_LdStRobTag) - unsigned(Rob_TopPtr) ; -- depth of the incoming instruction  (coming from lsq)
  dce_incoming_Depth <=   unsigned(DCE_RobTag) - unsigned(Rob_TopPtr); -- depth of the incoming instruction  (coming from lsq)
  BufDepth(0) <=  unsigned(LsbufRobTag(0)) - unsigned(Rob_TopPtr); -- depth of the currently residing instruction
  BufDepth(1) <=  unsigned(LsbufRobTag(1)) - unsigned(Rob_TopPtr);    
  BufDepth(2) <=  unsigned(LsbufRobTag(2)) - unsigned(Rob_TopPtr);
  BufDepth(3) <=  unsigned(LsbufRobTag(3)) - unsigned(Rob_TopPtr);
      
   -- out to issue unit
     Lsbuf_Ready        <=  LsBufInstValid(conv_integer(rd_ptr_temp(1 downto 0)));
     Lsbuf_RobTag       <= LsbufRobTag(conv_integer(rd_ptr_temp(1 downto 0))) ;
     Lsbuf_Data         <= LsBufData(conv_integer(rd_ptr_temp(1 downto 0)))  ;
	 Lsbuf_SwAddr         <= LsBufSwAddr(conv_integer(rd_ptr_temp(1 downto 0)))  ;
	 Lsbuf_RdWrite         <= LsBufOpcode(conv_integer(rd_ptr_temp(1 downto 0)))  ;
	 Lsbuf_PhyAddr        <= LsBufPhyAddr(conv_integer(rd_ptr_temp(1 downto 0)))  ;
	  -- translate_off 
	 Lsbuf_instruction        <= LsBufInstruction(conv_integer(rd_ptr_temp(1 downto 0)))  ;
	  -- translate_on
     
   process (Cdb_Flush , LsBufInstValid , BufDepth ,Cdb_RobDepth,lsq_incoming_depth,dce_incoming_depth)
	 begin
	   if (Cdb_Flush = '1') then
		   for I in 0 to 3 loop
         if (BufDepth(I) > Cdb_RobDepth) then
            LsBufInstValidTemp(I) <= '0' ;   --  flush the entry in fifo
			   else
            LsBufInstValidTemp(I) <= LsBufInstValid(I);			
         end if ;  
       end loop ;
		   
		   if (lsq_incoming_depth > Cdb_RobDepth) then
		     lsq_flush <= '1';
		   else
         lsq_flush <= '0';
       end if ;	
		   
       if (dce_incoming_depth > Cdb_RobDepth) then
		     dce_flush <= '1';
		   else
         dce_flush <= '0';
       end if ;			   
		  
		  else
		     lsq_flush <= '0';
			   dce_flush <= '0';
			   for I in 0 to 3 loop
            LsBufInstValidTemp(I) <= LsBufInstValid(I);			
         end loop ;
		  end if ; -- end of Cdb_Flush = 1	 
	 end process ;
	 
	 ----------------------------------------------------------
	 -- Process for calculating write and read pointer in case of flush
	 ------------------------------------------------------------------
	 process(Cdb_Flush , LsBufInstValidTemp, wr_ptr, rd_ptr)
	 begin
	   shift_2 <= '0';
	   shift_3 <= '0';
	   if (Cdb_Flush = '1') then
	     
	     case LsBufInstValidTemp(3 downto 0) is 
                 
                    
          when "0000" =>            
            wr_ptr_temp <= "000";
						rd_ptr_temp <= "000";
                    
					when "0001" =>           
            wr_ptr_temp <= "001";
						rd_ptr_temp <= "000";
						
				  when "0010" =>        
            wr_ptr_temp <= "010";
						rd_ptr_temp <= "001";
				
			    when "0011" =>            
            wr_ptr_temp <= "010";
						rd_ptr_temp <= "000";
				    
					when "0100" =>            
            wr_ptr_temp <= "011";
						rd_ptr_temp <= "010";
				    
					when "0101" =>           
            wr_ptr_temp <= "010";
						rd_ptr_temp <= "000";
						shift_2 <= '1';
						
					when "0110" =>            
            wr_ptr_temp <= "011";
						rd_ptr_temp <= "001";

          when "0111" =>           
            wr_ptr_temp <= "011";
						rd_ptr_temp <= "000";

          when "1000" =>            
            wr_ptr_temp <= "100";
						rd_ptr_temp <= "011";
          when "1001" =>           
            wr_ptr_temp <= "101";
						rd_ptr_temp <= "011";
					when "1010" =>           
            wr_ptr_temp <= "011";
						rd_ptr_temp <= "001";
						shift_3 <= '1';
          when "1011" =>            
            wr_ptr_temp <= "110";
						rd_ptr_temp <= "011";
          when "1100" =>           
            wr_ptr_temp <= "100";
						rd_ptr_temp <= "010";
          when "1101" =>            
            wr_ptr_temp <= "101";
						rd_ptr_temp <= "010";
          when "1110" =>            
            wr_ptr_temp <= "100";
						rd_ptr_temp <= "001";
          when "1111" =>           
            wr_ptr_temp <= "100";
						rd_ptr_temp <= "000";
          when others =>
              wr_ptr_temp <= wr_ptr;
		          rd_ptr_temp <= rd_ptr;       				
						
		  end case;
	   else
	     wr_ptr_temp <= wr_ptr;
		   rd_ptr_temp <= rd_ptr;
	   end if;
	 end process;
	 
	 -----------------------------------------------------------------
 -----------------------------------------------------------------------
--- process for generating full signal
------------------------------------------------------------------------
Lsbuf_Full <= full_temp;
process (wr_ptr_temp , rd_ptr_temp , Iss_Lsb )
begin
   full_temp <= '0';
   if ((wr_ptr_temp(1 downto 0) = rd_ptr_temp(1 downto 0)) and (wr_ptr_temp(2) /= rd_ptr_temp(2))) then
      full_temp <= '1' ;
   end if ;
    
   if (Iss_Lsb = '1') then
      full_temp <= '0' ;
   end if ;        
end process ; 
 
----------------------------------------------------------------------------------------------
--- Process generating signals for lsq and dce telling if the data on their outputs is taken or not
----------------------------------------------------------------------------------------------
process (full_temp , dce_flush , lsq_flush , DCE_ReadDone , Iss_LdStReady , Iss_LdStOpcode)
begin
  Lsbuf_DCETaken <= '0' ;
  Lsbuf_LsqTaken <= '0';
  if (full_temp = '0') then
    
	  if ( Iss_LdStReady = '1' and Iss_LdStOpcode = '0') then -- sw taken from lsq
	   Lsbuf_LsqTaken <= '1' ;
	  elsif (DCE_ReadDone = '1') then
	   Lsbuf_DCETaken <= '1' ;
	  else
	    Lsbuf_LsqTaken <= '0';
	    Lsbuf_DCETaken <= '0';
	  end if;
  end if ;
end process;
----------------------------------------------------------------------------------------------- 
process ( Clk , Resetb )
  variable wr_i : integer;
  variable rd_i : integer;
    begin
      if ( Resetb = '0' ) then 
	     wr_ptr         <= (others => '0') ;
	     rd_ptr         <= (others => '0') ;
	     LsBufInstValid <= "0000" ;
       LsBufOpcode    <= (others => '0') ;  -- 1 = lw,  0 = sw
	          
      elsif ( Clk'event and Clk = '1' ) then     
       wr_i := conv_integer(wr_ptr_temp(1 downto 0));
       rd_i := conv_integer(rd_ptr_temp(1 downto 0));
	   
	     wr_ptr <= wr_ptr_temp;
	     rd_ptr <= rd_ptr_temp;
	   
	     for I in 0 to 3 loop
	      LsBufInstValid(I) <= LsBufInstValidTemp(I);
	     end loop;
	   
	     if (shift_2  = '1') then
	       LsBufInstValid(1) <= LsBufInstValidTemp(2);
         LsBufInstValid(2) <= '0';
         LsBufOpcode(1) <= LsBufOpcode(2) ;
         LsbufRobTag(1) <= LsbufRobTag(2);
         LsBufData(1) <= LsBufData(2);
		 LsBufSwAddr(1) <= LsBufSwAddr(2);
		 LsBufPhyAddr(1) <= LsBufPhyAddr(2);
		  -- translate_off 
		 LsBufInstruction(1) <= LsBufInstruction(2);
		  -- translate_on
       end if ;		 
	   
	     if (shift_3  = '1') then
	       LsBufInstValid(2) <= LsBufInstValidTemp(3);
         LsBufInstValid(3) <= '0';
         LsBufOpcode(2) <= LsBufOpcode(3) ;
         LsbufRobTag(2) <= LsbufRobTag(3);
         LsBufData(2) <= LsBufData(3);
		 LsBufSwAddr(2) <= LsBufSwAddr(3);
		 LsBufPhyAddr(2) <= LsBufPhyAddr(3);
		  -- translate_off 
		 LsBufInstruction(2) <= LsBufInstruction(3);
		  -- translate_on
       end if ;		 
	   
       if (Iss_Lsb = '1') then
	       rd_ptr <= rd_ptr_temp + 1;
		     LsBufInstValid(rd_i) <= '0' ;
	     end if;
	   
	     if (full_temp = '0') then
	       
           		   
         if ( lsq_flush = '0' and Iss_LdStReady = '1' and Iss_LdStOpcode = '0') then
           LsBufInstValid(wr_i) <= '1' ;
           LsBufOpcode(wr_i) <= Iss_LdStOpcode;
           LsbufRobTag(wr_i) <= Iss_LdStRobTag;
           LsBufData(wr_i) <= Iss_LdStData;
		   LsBufSwAddr(wr_i) <= Iss_LdStAddr ;
		   LsBufPhyAddr(wr_i) <= Iss_LdStPhyAddr ;
		    -- translate_off 
		   LsBufInstruction(wr_i) <= Iss_instructionLsq ;
		    -- translate_on
           wr_ptr <= wr_ptr_temp + 1 ;
         --  Lsbuf_LsqTaken <= '1';	
         elsif (dce_flush = '0' and DCE_ReadDone = '1') then
		       LsBufInstValid(wr_i) <= '1' ;
           LsBufOpcode(wr_i) <= DCE_Opcode;
           LsbufRobTag(wr_i) <= DCE_RobTag;
           LsBufData(wr_i) <= DCE_MemData ;
		   LsBufSwAddr(wr_i) <= DCE_Addr ;
		   LsBufPhyAddr(wr_i) <= DCE_PhyAddr ;
		    -- translate_off 
		   LsBufInstruction(wr_i) <= DCE_instruction ;
		    -- translate_on
           wr_ptr <= wr_ptr_temp + 1 ;
        --   Lsbuf_DCETaken <= '1';
         end if ; 
	      end if ;  -- end of full_temp = '0'
	    
	         
    end if ; -- end of Clk'event    
       --------------------------------------------------------
 end process ;

	
end architecture struct;
