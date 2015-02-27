------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
-- use IEEE.STD_LOGIC_SIGNED.ALL;

------------------------------------------------------------------------------
entity divider is
generic  (   
         tag_width   				: integer := 6
         );

	port (
				clk					: IN std_logic;
				Resetb				: IN std_logic;
				PhyReg_DivRsData			: IN std_logic_VECTOR(31 downto 0); -- from divider issue queue unit
				PhyReg_DivRtData			: IN std_logic_VECTOR(31 downto 0); -- from divider issue queue unit    --
				Iss_RobTag		: IN std_logic_vector( 4 downto 0);  -- from divider issue queue unit
				Iss_Div				: IN std_logic;  -- from  issue unit
				
				-------------------------------- Logic for the pics ( added by Atif) --------------------------------	
     			Div_RdPhyAddr : out std_logic_vector(5 downto 0); -- output to CDB required
				Div_RdWrite : out std_logic;
				Iss_RdPhyAddr : in std_logic_vector(5 downto 0);  -- incoming form issue queue, need to be carried as Iss_RobTag
				Iss_RdWrite : in std_logic;
				----------------------------------------------------------------------
				 -- translate_off 
     Iss_instructionDiv     : in std_logic_vector(31 downto 0);
	 -- translate_on
	 -- translate_off 
         Div_instruction       : out std_logic_vector(31 downto 0);
	    -- translate_on
			Cdb_Flush         : in std_logic;
            Rob_TopPtr    : in std_logic_vector ( 4 downto 0 ) ;
            Cdb_RobDepth         : in std_logic_vector ( 4 downto 0 ) ;
				Div_Done         		  : out std_logic ;
				Div_RobTag				  : OUT std_logic_vector(4 downto 0);
				Div_Rddata					  : OUT std_logic_vector(31 downto 0);
				Div_ExeRdy					  : OUT std_logic  -- divider is read for division ==> drives "div_exec_ready" in the TOP
			);
end divider;

architecture behv of divider is

	component  divider_core is
    Port ( Dividend 	: in std_logic_vector (31 downto 0 );
           Divisor 		: in std_logic_vector ( 31 downto 0);
           Rem_n_Quo 	: out std_logic_vector ( 31 downto 0)
          );
	end component divider_core;
	
	-- component divider_core is
    -- port ( DATA_A  : in std_logic_vector  (31 downto 0 );
           -- DATA_B  : in std_logic_vector  (31 downto 0);
           -- DIV_OUT : out std_logic_vector ( 31 downto 0)
          -- );
			 
	-- end component divider_core;
	
	subtype tag_type is std_logic_vector(4 downto 0); 
	type tag is array (0 to 5) of tag_type; -- changed from (0 to 4)

		-- tag_valid: 0 through 5 for the 6 pipeline registers forming a 6-clock long combinational division 
		-- note: Since 1 clock is lost in holding the incoming operands in a register before starting the division
		-- 		we can only take 6 clocks (including a clock long combinational logic upstream of the CDB mux)
	signal tag_valid,rdwrite		: std_logic_vector(5 downto 0); -- changed from (4 downto 0)
	signal tag_div      	: tag;
	
	subtype PhyAddr_Type is std_logic_vector(5 downto 0); 
	type  PhyAddr is array (0 to 5) of PhyAddr_Type;
	signal RdPhyAddr  : PhyAddr; 

	-- signal div_rem_quo		: std_logic_vector(31 downto 0);
	-- signal result			: std_logic_vector(31 downto 0);
	signal divisor, dividend: std_logic_vector(31 downto 0);
	signal rfd				: std_logic;  -- rfd = ready for division

signal BufferDepth  :std_logic_vector ( 4 downto 0 ) ; -- for the instruction coming from the division issue queue
signal Buffer0Depth :std_logic_vector ( 4 downto 0 ) ;
signal Buffer1Depth :std_logic_vector ( 4 downto 0 ) ;
signal Buffer2Depth :std_logic_vector ( 4 downto 0 ) ;
signal Buffer3Depth :std_logic_vector ( 4 downto 0 ) ;
signal Buffer4Depth :std_logic_vector ( 4 downto 0 ) ;
signal Buffer5Depth :std_logic_vector ( 4 downto 0 ) ;

	
begin
	
	div : divider_core
		port map (  
					Dividend => dividend,
					Divisor => divisor,
					Rem_n_Quo => Div_Rddata
				  );
		-- port map (
					-- DATA_A 	=> divisor,
					-- DATA_B 	=> dividend,
					-- DIV_OUT 	=> result
					-- );

Div_ExeRdy <= rfd;
-- Div_Rddata <= div_rem_quo;
 -- translate_off 
Div_instruction <= Iss_instructionDiv ;
 -- translate_on

 
Div_Done <= tag_valid(5) ;  -- previously 3? -- are you doing only 0 to 3? -- let us do 0 to 5 as our diagrams show 0 to 5
Div_RobTag <= tag_div(5);
Div_RdPhyAddr <= RdPhyAddr(5);
Div_RdWrite   <= rdwrite(5);
	
BufferDepth  <=  unsigned(Iss_RobTag)  -  unsigned(Rob_TopPtr) 	;       
Buffer0Depth <=  unsigned(tag_div(0))  -  unsigned(Rob_TopPtr) ;
Buffer1Depth <=  unsigned(tag_div(1))  -  unsigned(Rob_TopPtr) ;
Buffer2Depth <=  unsigned(tag_div(2))  -  unsigned(Rob_TopPtr) ;
Buffer3Depth <=  unsigned(tag_div(3))  -  unsigned(Rob_TopPtr) ;
Buffer4Depth <=  unsigned(tag_div(4))  -  unsigned(Rob_TopPtr) ;
   -- Note: On the tick of the clock, the six pipeline registers (0 to 5) will move one step down.  
   -- The top-most register 0 will receive a tag from divider issue unit.
   -- When Cdb_Flush is activated, we are responsible to invalidate appropriate Flip-Flops
   -- by the end of the clock. So we take care of the six valid-bit FFs, tag_valid(0 to 5) by looking at the 5 depths. 
   -- The CDB shall take care of invalidiating the outgoing div instruction 
   -- (going out of multiplier and entering the CDB register). So CDB will worry about Buf5Depth!
   -- Hence the following line is not needed here
-- Buffer5Depth <=  unsigned(tag_div(5))  -  unsigned(Rob_TopPtr) ;
	
	tag_carry	: process (clk, Resetb)
	begin
		if (Resetb = '0') then
			for i in 0 to 5 loop --   0 to 5
				tag_div(i) <= (others => '0'); --  Though we could have these as don't cares (others => '-'), for the sake of easy debugging, let us make them zeros;
				RdPhyAddr(i) <= (others=>'0');
			end loop;
				tag_valid  <= (others => '0');
				rdwrite    <= (others => '0');
				rfd		     <= '1';	
				divisor 	<= (others => '-');
				dividend	<= (others => '-');
				
		elsif(clk'event and clk = '1') then
			-- if an instruction is coming in from divide issue queue
			if(Iss_Div = '1' and rfd = '1' and ( (Cdb_Flush = '0') or ( Cdb_Flush = '1' and BufferDepth < Cdb_RobDepth )  ) ) then
			-- (Iss_Div = '1' and rfd = '1' ) ? it is enough to say (Iss_Div = '1') as Iss_Div  can not be made '1' by the issue unit unless rfd was '1'
				divisor 		  <= PhyReg_DivRtData;
				dividend		  <= PhyReg_DivRsData;
				tag_div(0)  <= Iss_RobTag;
				RdPhyAddr(0)<= Iss_RdPhyAddr;
				rdwrite(0) <= Iss_RdWrite;
				tag_valid(0)<= '1';
				rfd			<= '0';
			else
				tag_div(0)  <= (others => '0'); -- though it is not necessary, we wish to clear to make debugging easy
				RdPhyAddr(0) <= (others => '0');
				tag_valid(0)<= '0';
				rdwrite(0)<='0';
			end if;
			if ( Cdb_Flush = '1' and  
			           (  -- if there is an ongoing div operation which does not leave the divisor by the end of the clock
						  ( Buffer0Depth > Cdb_RobDepth    and tag_valid(0) = '1' ) or  
			              ( Buffer1Depth > Cdb_RobDepth    and tag_valid(1) = '1' ) or
						  ( Buffer2Depth > Cdb_RobDepth    and tag_valid(2) = '1' ) or
			              ( Buffer3Depth > Cdb_RobDepth    and tag_valid(3) = '1' ) or
			              ( Buffer4Depth > Cdb_RobDepth    and tag_valid(4) = '1' )
			              -- ( Buffer5Depth > Cdb_RobDepth    and tag_valid(5) = '1' )  -- see the above note regarding Buffer5Depth
						  ) ) then
					rfd <= '1' ;
					for i  in 1 to 5 loop  -- note: it's 1 to 5, not 0  to 4 as these items are on move!
						tag_valid(i) <= '0' ;
						rdwrite(i)<='0';
						tag_div(i) 	 <= (others => '0'); --  Though we could have these tags as don't cares (others => '-'), for the sake of easy debugging, let us make them zeros;
						RdPhyAddr(i) <= (others => '0');
					end loop; 
			else           
					for i in 1 to 5 loop
						tag_valid(i) <=   tag_valid(i-1);  -- tag_valid(0) receives a 1 or 0 depending on whether a new div instruction is issued or not.
						tag_div(i) 	 <= 	tag_div(i-1);
						rdwrite(i) <= rdwrite(i-1);
						RdPhyAddr(i) <= RdPhyAddr(i-1) ;
					end loop;
					
					if   (rfd = '0' and 
							( (tag_valid(5) = '1') or  -- it is unnecessary to qaulify with (rfd = '0' ) as (tag_valid(5) = '1') is enough for this part of the clause
							  ( (tag_valid(0) = '0') and (tag_valid(1) = '0') and (tag_valid(2) = '0') and (tag_valid(3) = '0') and (tag_valid(4) = '0') ) ) )
							  -- if all the upper 5 tag valid bits (bits 0 to 4)  are zeros -- this is perhaps redundant
							  -- However, if you do keep this piece of the clause, you do need the(rfd = '0' )  as a qualifier.
							  -- This is not apparent at first sight. This is an artifact of HDL coding!
							  -- Notice that, if we are initiating a division, we are assigning a '0' to the rfd signal (with delta-T delay) on line 125 above.
								-- Then we come down here and override that assignment with '1' in line 162, resulting rfd continuing to be 1 for 1 extra clock.
								-- To avoid this problem, you need to have (rfd = '0' )  as a qualifier for this part of the clause.
								-- In fact, if the tag_valid[0:4] = 00000 and (rfd = '0' ) , then (tag_valid(5) = '1') is true and hence this clause is redundant as stated before.
						   
					then
						rfd 			<= '1';
					end if;
					-- if (rfd = '1')then
						-- div_rem_quo	<= result;  --  another clock? Result shall go directly to the CDB mux
					-- end if;
					
					-- Div_RobTag <= tag_div(4);
					
			end if;
		end if ;
		
	end process tag_carry;
	
end architecture behv;