-------------------------------------------------------------------------------
-- Design   	: Instruction Fetch Queue i_fetch_q
-- Project 	: Tomasulo Processor 
-- Author 	: Gandhi Puvvada 
-- Company 	: University of Southern California 
-- Date   	: 07/25/2008  , 7/15/2009, 6/29/2010
-- This file is same as the file dated 4/27/2010 except for a few spelling errors!
-- File	: i_fetch_q_efficient_r2.vhd
-------------------------------------------------------------------------------
-- Description :  	This is the revised design where we eliminated all
--			barrel shifters. We read an entire cache line of 4 words
--			into the Instruction Fetch Queue.
-----------------------------------------------------------------------------
-- Solution version of the design:
-- ==============================
-- Here we fixed the following two inefficiencies and one restriction  
-- which existed in the exercise version of the  design (i.e. in  i_fetch_q_inefficient_r2.vhd).

-- Inefficiency #1: Delay in conveying branch/jump target address to cache
-- Inefficiency #2: Delay in conveying the target instruction to the dispatch unit:
-- Restriction #1: All branch and jump target addresses shall be aligned to 4-word boundary.

-- Along with removing the inefficiency #2, we will use our forwarding (FWFT)
-- circuitry to forward the first instruction after the IFQ runs dry (becomes empty). 
-- FWFT = First Word Fall Through
-----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
-- use ieee.std_logic_unsigned.all; -- use of this package is discouraged. So, without this, we need to write "unsigned(wp) - unsigned(rp)" inplace of simple "wp - rp".
-- use work.tmslopkg.all ;

entity i_fetch_q is  

port (
	Clk						: in  std_logic;
	Resetb					: in  std_logic;
	   
	     -- interface with the dispatch unit
	Ifetch_Instruction		: out std_logic_vector(31 downto 0);
	Ifetch_PcPlusFour		: out std_logic_vector(31 downto 0);
	Ifetch_EmptyFlag		: out std_logic;
	Dis_Ren					: in  std_logic; -- may be active even if ifq is empty. 
	Dis_JmpBrAddr			: in std_logic_vector(31 downto 0);
	Dis_JmpBr				: in  std_logic;
	Dis_JmpBrAddrValid		: in std_logic;

		-- interface with the cache unit
	Ifetch_WpPcIn			: out std_logic_vector(31 downto 0); 
	Ifetch_ReadCache		: out std_logic;
		-- synopsys translate_off
		wp_report, rp_report, depth_report : out std_logic_vector(4 downto 0);
		-- synopsys translate_on	
	Ifetch_AbortPrevRead	: out std_logic;
	Cache_Cd0             : in  std_logic_vector (31 downto 0);
	Cache_Cd1             : in  std_logic_vector (31 downto 0);
	Cache_Cd2             : in  std_logic_vector (31 downto 0);
	Cache_Cd3             : in  std_logic_vector (31 downto 0);
	Cache_ReadHit        : in  std_logic
     );
end entity i_fetch_q;

-----------------------------------------------------------------------------

architecture i_fetch_q_arc of i_fetch_q is

-- Component declaration

   component i_fetch_fifo_ram_reg_array

   generic (N: integer := 2; M: integer := 32);

   port (
	   Clka : in std_logic;
	   wea : in std_logic;
	   addra : in std_logic_vector(N-1 downto 0);
	   dia : in std_logic_vector(M-1 downto 0);
	   addrb : in std_logic_vector(N-1 downto 0);
	   dob : out std_logic_vector(M-1 downto 0)
	   );

   end component i_fetch_fifo_ram_reg_array; 

    
-- local signal declarations
	-- Note: The suffix  "_int" means an internal local signal. Most outputs 
	--	     may be first generated as an internal signals and then assigned to 
	--           their output ports.
	signal wp, rp   : std_logic_vector(4 downto 0); 
	-- Note: We are using 5-bit pointers for a 16-location fifo. It is not absolutely
	-- necessary to use 5-bit pointers as it is a single clock fifo.  It is possible to use 
	-- 4-bit pointer. However, it makes it easy to produce the full and empty flags.
	-- We actually use only upper 3-bits of the 5-bit wp and 5-bit rp to compute EMPTY and FULL.
	-- This solves a lot of problems we solved earlier using a 2-state state machine!
	
	signal wp_2bit, rp_2bit : std_logic_vector(1 downto 0);
	--    the 2-bit pointers (3 downto 2) that go to the four 4x32 register arrays
	signal full, nearly_full, empty_int : std_logic; -- internal full and empty flags
	signal wp_upper_equals_rp_upper  : std_logic; -- to derive empty flag
	signal wenq, renq : std_logic; -- write-eable and read-enable, q = qualified
	-- synopsys translate_off
	signal depth    : std_logic_vector(4 downto 0); -- ----------------------------???? Try to avaoid
	-- synopsys translate_on
	-- instructions read from the i_fetch_q
	signal instr0			: std_logic_vector(31 downto 0);
	signal instr1			: std_logic_vector(31 downto 0);
	signal instr2			: std_logic_vector(31 downto 0);
	signal instr3 			: std_logic_vector(31 downto 0);
		
	signal bypass_fifo : std_logic; -- forwarding logic signal

	signal wp_pc_int, wp_pc_int_next    	: std_logic_vector(31 downto 0); 
							-- pc associated with wp
	signal rp_pc_plus_four_int : std_logic_vector(31 downto 0); 
							-- pc associated with rp
	signal ValidJump : std_logic; -- Jump only when J, Jal or JR$31. Do not Jump when JR $RS. 						

begin

-- Component instantiations
   ram_dp0: i_fetch_fifo_ram_reg_array  
    generic map (N => 2, M => 32)
	port map(
	   Clka => Clk, wea => wenq, addra => wp_2bit, 
	   dia => Cache_Cd0, addrb => rp_2bit, dob => instr0);
	
   ram_dp1: i_fetch_fifo_ram_reg_array  
    generic map (N => 2, M => 32)
	port map(
	   Clka => Clk, wea => wenq, addra => wp_2bit, 
	   dia => Cache_Cd1, addrb => rp_2bit, dob => instr1);
	
   ram_dp2: i_fetch_fifo_ram_reg_array  
    generic map (N => 2, M => 32)
	port map(
	   Clka => Clk, wea => wenq, addra => wp_2bit, 
	   dia => Cache_Cd2, addrb => rp_2bit, dob => instr2);
	
   ram_dp3: i_fetch_fifo_ram_reg_array  
    generic map (N => 2, M => 32)
	port map(
	   Clka => Clk, wea => wenq, addra => wp_2bit, 
	   dia => Cache_Cd3, addrb => rp_2bit, dob => instr3);
		

	-- =========================
		-- synopsys translate_off
		wp_report <= wp;  rp_report <= rp; depth_report <= depth;
		-- synopsys translate_on		

	-- =========================
	-- Two bits (3 downto 2) of the 5-bit wp counter are sent to all the dual port RAMs.
	wp_2bit <= wp(3 downto 2);
	
    rp_2bit <= rp(3 downto 2); 
	-- The 4 RAMs (register arrays) are organized in a lower-order interleaved fashion. 
	-- The lower 2 bits of the rp are used to select one instruction from the 4 instructions
	-- coming out of the 4 RAMs or the four instructions given out by the instruction cache
	-- in the forwarding situation.
	-- =========================
	-- instruction forwarding
	-- =========================
	bypass_fifo <= wp_upper_equals_rp_upper AND Cache_ReadHit;-- if fifo was empty, let us forward
	
	Ifetch_Instruction_forwarding_process: process 
	(bypass_fifo, rp, instr0, instr1, instr2, instr3, Cache_Cd0, Cache_Cd1, Cache_Cd2, Cache_Cd3)
	begin
	  if bypass_fifo = '1' then -- forward the instruction from the cache
		case (rp(1 downto 0)) is
			when "00" =>
				Ifetch_Instruction <=	Cache_Cd0;
			when "01" =>
				Ifetch_Instruction <=	Cache_Cd1;
			when "10" =>
				Ifetch_Instruction <=	Cache_Cd2;
			when others =>
				Ifetch_Instruction <=	Cache_Cd3;
		end case;
	  else -- use the instruction previously deposited in the fifo
		case (rp(1 downto 0)) is
			when "00" =>
				Ifetch_Instruction <=	instr0;
			when "01" =>
				Ifetch_Instruction <=	instr1;
			when "10" =>
				Ifetch_Instruction <=	instr2;
			when others =>
				Ifetch_Instruction <=	instr3;
		end case;
	  end if;
	end process Ifetch_Instruction_forwarding_process;
  -- =========================	
   -- depth, empty, full, ...etc.
  -- =========================	
		-- synopsys translate_off
        -- depth calculation and flags generation
			depth <= unsigned(wp) - unsigned(rp);     ---- avoid producing depth for synthesis   ***********************
        -- synopsys translate_on
		
        wp_upper_equals_rp_upper <= 		(                         -- only upper three bits!
								( wp(4) XNOR rp(4) ) AND
								( wp(3) XNOR rp(3) ) AND
								( wp(2) XNOR rp(2) ) 
							);
		
		empty_int <= wp_upper_equals_rp_upper AND  (NOT(Cache_ReadHit)); 
		Ifetch_EmptyFlag   <=   empty_int;
 
		--  the dispatch unit shall not consume an instruction during the 
		--  clock when it asserts "ValidJump" due to a successful branch
		-- though the empty_flag will be inactive  in that clock.
		--  The empty_flag will be inactive in that clock so that the jump instruction
		-- is decoded and executed by the dispatch unit.
		
		-- Generating Signal for Valid Jump. When Instruction is Jump type and Jump Addr is valid, Jump.
		ValidJump <= Dis_JmpBr AND Dis_JmpBrAddrValid;
		---
        full <=     	( 
								( wp(4) XOR  rp(4) ) AND
								( wp(3) XNOR rp(3) ) AND
								( wp(2) XNOR rp(2) ) 
							);
		nearly_full <= '1' when (unsigned(wp(4 downto 2)) -  unsigned(rp(4 downto 2)) = unsigned'("011") ) else '0'; -- 3 of the four rows full
		Ifetch_ReadCache <= (NOT (full OR (nearly_full AND Cache_ReadHit))) OR (ValidJump);
  -- =========================			
  
-- concurrent statements to produce wenq and renq (q = qualified)
	wenq <= Cache_ReadHit AND (NOT(full));  
	-- In the above expression for wenq, "not(full)"  is  
	-- unnecessary as we will not activate read-cache unless we have 
	-- atleast a row of space_left 
	renq <= Dis_Ren AND (NOT(empty_int)); 
	-- =========================
	wp_pc_int_next_combinational_process: process 
	(wp_pc_int, wenq, ValidJump, Dis_JmpBrAddr)
		begin
			if ValidJump = '1' then
				wp_pc_int_next <= Dis_JmpBrAddr (31 downto 4) & "0000"; -- aligned address
			elsif wenq = '1' then
				wp_pc_int_next <= unsigned(wp_pc_int) + 16; -- increment by 16
			else
				wp_pc_int_next <= wp_pc_int; -- recirculate the current value
			end if;
		end process wp_pc_int_next_combinational_process;
	-- =========================
   Clk_registers : process (Clk, Resetb)
   
	begin
	
		if (Resetb = '0') then
	  
			wp <= "00000"; 
			rp <= "00000"; 			
			wp_pc_int 			<= X"0000_0000";
			rp_pc_plus_four_int <= X"0000_0004";
			
		elsif (Clk'event AND Clk = '1') then
		
			wp_pc_int <= wp_pc_int_next; -- wp_pc_int_next was combinationally derived separately
			
			if (ValidJump = '1') then -- flush the fifo
				wp <= "000" & Dis_JmpBrAddr (3 downto 2); rp <= "000" & Dis_JmpBrAddr (3 downto 2); 
				-- Dis_JmpBrAddr (3 downto 2) is 00 or 01 or 10 or 11 
				-- depending on the 4-word alignment of the Dis_JmpBrAddr 
				-- Note: we are not using wp (1 downto 0) anywhere except for producing depth information during simulation.
				-- So, wp (1 downto 0)  will not be implemented anyway and it does not matter if we initiate it to "00"
				-- or to Dis_JmpBrAddr (3 downto 2). 
				rp_pc_plus_four_int <= unsigned(Dis_JmpBrAddr) + 4;
			else
				if (wenq = '1') then 
					wp(4 downto 2)  <=  unsigned(wp(4 downto 2)) + 1; 
				end if;
				if renq = '1' then  
					rp <= unsigned(rp) + 1;    					
					rp_pc_plus_four_int <= unsigned(rp_pc_plus_four_int) + 4;
				end if;
			end if;
		end if;
 	  
	end process Clk_registers;
	
	Ifetch_WpPcIn <= wp_pc_int_next; 
	-- send it out to the instruction cache
	Ifetch_PcPlusFour <= rp_pc_plus_four_int; 
	-- send it out to the dispatch unit. 
	Ifetch_AbortPrevRead <= ValidJump;
	
end architecture i_fetch_q_arc;
-----------------------------------------------------------------------------
