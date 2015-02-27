------------------------------------------------------------------------------
-- File: multiplier_r1.vhd (earlier multiplier.vhd) was revised)
-- EE560 Tomasulo with ROB project
-- July 23, 2009
-- Rohit Goel , Gandhi Puvvada
------------------------------------------------------------------------------
-- This is a wrapper which instantiates the multiplier_core
-- It carries the tag and valid bit of the mult instruction trhough 3 stage registers.
-- It also supports selective flushing due to mispredicted branches (when Cdb_Flush is true).
------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

------------------------------------------------------------------------------
entity multiplier is
generic  (   
         tag_width   				: integer := 6
         );
    port ( 
				clk				   	: in std_logic;
				Resetb			  	: in std_logic;
				Iss_Mult      	: in std_logic ;  					-- from issue unit
				PhyReg_MultRsData		: in std_logic_VECTOR(31 downto 0); -- from issue queue mult
				PhyReg_MultRtData		: in std_logic_VECTOR(31 downto 0); -- from issue queue mult
				Iss_RobTag 	: in std_logic_vector(4 downto 0);  -- from issue queue mult
	
-------------------------------- Logic for the pins ( added by Atif) --------------------------------	
     			Mul_RdPhyAddr : out std_logic_vector(5 downto 0); -- output to CDB required
				Mul_RdWrite : out std_logic;
				Iss_RdPhyAddr : in std_logic_vector(5 downto 0);  -- incoming form issue queue, need to be carried as Iss_RobTag
				Iss_RdWrite : in std_logic;
				----------------------------------------------------------------------
				 -- translate_off 
     Iss_instructionMul     : in std_logic_vector(31 downto 0);
	 -- translate_on
	 -- translate_off 
         Mul_instruction       : out std_logic_vector(31 downto 0);
	    -- translate_on
				Mul_RdData			      : out std_logic_VECTOR(31 downto 0); -- output to CDB unit (to CDB Mux)
				Mul_RobTag		      : out std_logic_vector(4 downto 0);  -- output to CDB unit (to CDB Mux)
				Mul_Done             : out std_logic ;						-- output to CDB unit ( to control Mux selection)
			Cdb_Flush              : in std_logic;
            Rob_TopPtr         : in std_logic_vector ( 4 downto 0 ) ;
            Cdb_RobDepth              : in std_logic_vector ( 4 downto 0 )
			);
end multiplier;

architecture multiply of multiplier is

component multiplier_core is
    Port (  m: in std_logic_vector (15 downto 0 ); -- multiplicand (input 1)
            q: in std_logic_vector ( 15 downto 0); -- multiplier  (input 2)
            P: out std_logic_vector ( 31 downto 0); -- the output product
            clk: in std_logic 
          );
end component multiplier_core;

	-- component multiplier_core is
		 -- Port ( DATA_A : in std_logic_vector (31 downto 0 );
				  -- DATA_B : in std_logic_vector ( 31 downto 0);
				  -- MULT_OUT : out std_logic_vector ( 31 downto 0)
				 -- );
	-- end component multiplier_core;
	
	subtype tag_type is std_logic_vector(4 downto 0);
	type tag is array (0 to 2) of tag_type;

	signal tag_mul : tag;
	-- signal mul_res_reg, mul_res_out			: std_logic_vector(31 downto 0);
	-- signal mul_pipe_reg_a, mul_pipe_reg_b	: std_logic_vector(31 downto 0);
	
	subtype phy_addr is std_logic_vector(5 downto 0);
	type phyaddr is array (0 to 2) of phy_addr;
	signal RdPhyAddr : phyaddr;
	
	signal tag_valid,RdWrite : std_logic_vector ( 0 to 2 ) ;
	signal BufDepth , Buf0Depth : std_logic_vector ( 4 downto 0 );
	signal Buf1Depth , Buf2Depth : std_logic_vector ( 4 downto 0 ); -- Note: Buf2Depth is not needed here!
   
	
	begin
	
	BufDepth <=  unsigned(Iss_RobTag)  - unsigned(Rob_TopPtr) ; -- depth of incoming instruction	
	Buf0Depth  <= unsigned(tag_mul(0)) - unsigned(Rob_TopPtr) ;  -- depth of instruction 0 in pipe
	Buf1Depth  <= unsigned(tag_mul(1)) - unsigned(Rob_TopPtr) ;  -- depth of instruction 1 in pipe
   -- Note: On the tick of the clock, the incoming instruction, and the instructions 0 and 1 will take postion 
   -- in register 0, 1, and 2 respectively.  When Cdb_Flush is activated, we are responsible to invalidate appropriate Flip-Flops
   -- by the end of the clock. So we take care of the three valid-bit FFs, tag_valid(0 to 2). The CDB shall take care of invalidiating 
   -- the outgoing mult instruction (going out of multiplier and entering the CDB register). So CDB will worry about Buf3Depth!
   -- Hence the following line is not needed here
   -- Buf2Depth  <= unsigned(tag_mul(2)) - unsigned(Rob_TopPtr) ;  -- depth of instruction 2 in pipe
  
	-- mult : multiplier_core
		-- port map (
						-- DATA_A	=>	mul_pipe_reg_a,
						-- DATA_B	=> mul_pipe_reg_b,
						-- MULT_OUT	=> mul_res_out
					-- );

	mult : multiplier_core
		port map (
				m =>  PhyReg_MultRsData (15 downto 0),
				q =>  PhyReg_MultRtData (15 downto 0),
				p =>  Mul_RdData,
				clk =>  clk
					);
					
					
	Mul_RobTag <= tag_mul(2);
    Mul_Done   <= tag_valid(2) ;  -- needed for controlling the CDB mux
	Mul_RdPhyAddr <= RdPhyAddr(2);
	Mul_RdWrite <= RdWrite(2);
	 -- translate_off 
	Mul_instruction <= Iss_instructionMul ;        
	 -- translate_on
	        
	tag_carry : process (clk, Resetb)
	begin
		if(Resetb = '0') then
		
			for i in 0 to 2 loop
				tag_mul(i) <= (others => '-');
				RdPhyAddr(i) <= (others=>'-');
				tag_valid(i) <= '0' ;
				RdWrite(i) <= '0';
				RdPhyAddr(i) <= (others=>'-');
			end loop;

		elsif(clk'event and clk = '1') then	
	   
			tag_mul(0) <= Iss_RobTag; -- we do not have to inhibit tag from entering
			tag_mul(1) <= tag_mul(0);
			tag_mul(2) <= tag_mul(1);
			
			RdPhyAddr(0) <= Iss_RdPhyAddr;
			RdPhyAddr(1) <= RdPhyAddr(0);
			RdPhyAddr(2) <= RdPhyAddr(1);
			
			RdWrite(0) <= Iss_RdWrite;
			RdWrite(1) <= RdWrite(0); 
			RdWrite(2) <= RdWrite(1);

			if ( Cdb_Flush = '1' ) then 
		
				if ( BufDepth > Cdb_RobDepth   ) then -- Note: It is BufDepth of the incoming instruction and not Buf0Depth
					tag_valid(0) <= '0' ;
				else
					tag_valid(0) <= Iss_Mult ;
				end if ;
				   
				if ( Buf0Depth > Cdb_RobDepth  and tag_valid(0) = '1'  ) then 
					tag_valid(1) <= '0' ;
				else
					tag_valid(1) <= tag_valid(0) ;
				end if ;
				-- The above is same as 
				-- if ( Buf0Depth > Cdb_RobDepth ) then 
					-- tag_valid(1) <= '0' ;
				-- else
					-- tag_valid(1) <= tag_valid(0) ;
				-- end if ;
				
				if ( Buf1Depth > Cdb_RobDepth  and tag_valid(1) = '1' ) then 
					tag_valid(2) <= '0' ;
				else
					tag_valid(2) <= tag_valid(1) ;
				end if ;
			else
			   tag_valid(0) <= Iss_Mult ;
			   tag_valid(1) <= tag_valid(0) ;
			   tag_valid(2) <= tag_valid(1) ;
			   
			end if ;  
										 
		end if;
		
	end process tag_carry;
	
end architecture multiply;

