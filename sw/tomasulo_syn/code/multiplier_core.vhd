------------------------------------------------------------------------------
-- Create/rivision Date: on 07/21/09
-- Design Name:    multiplier_core for Tomasulo execution units
-- Module Name:    multiplier_core
-- Author:        Ketan Sharma, Ashutosh Moghe, Gandhi Puvvada
------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
-- use ieee.std_logic_unsigned.all;
------------------------------------------------------------------------------
-- This is a pipelined multiplier. It has 4 stages. 
-- The four parts of the combinational logic are separated by three (3, not 4) stage registers.
-- The end registers (one at entry and one at exit) are not coded here.
-- The entry register is the register in multiplier issue  queue.
-- The exit register is the CDB register.
--   Comb_logic_1  -> Stage_Reg1 -> Comb_logic_2  -> Stage_Reg2 -> Comb_logic_3  -> Stage_Reg3 ->  Comb_logic_4
--    _suffix_A			       _suffix_B                               _suffix_C				_suffix_D
--	The suffixes _A, _B, _C, _D are used with signals and variables.
------------------------------------------------------------------------------
-- This design is the "core" design. There is wrapper called "multiplier,
-- which instantiates this core. The wrapper design is responsible to carry 
-- the tags of 
------------------------------------------------------------------------------
entity multiplier_core is
    Port (  m: in std_logic_vector (15 downto 0 ); -- multiplicand (input 1)
            q: in std_logic_vector ( 15 downto 0); -- multiplier  (input 2)
            P: out std_logic_vector ( 31 downto 0); -- the output product
            clk: in std_logic 
          );
end multiplier_core;
------------------------------------------------------------------------------
architecture behv of multiplier_core is

-- Signals with suffixes  (signals with suffixes _B, _C, and _D are actually Pipeline registers
signal m_A, m_B, q_A, m_C, q_B, q_C: std_logic_vector (15 downto 0); -- Pipeline registers 
-- Note: The product bits are progressively generated and further carried through the pipe. Hence they were 6 bits to start 
-- with and eventually became 32 bits.
signal P_A_5_to_0, P_B_5_to_0: std_logic_vector (5 downto 0);
signal P_B_10_to_6 : std_logic_vector (10 downto 6);
-- P_B_5_to_0 are FFs in Stage_Reg1, where as P_B_10_to_6 are produced combinationally by CSAs
signal P_C_10_to_0: std_logic_vector (10 downto 0);
signal P_C_15_to_11: std_logic_vector (15 downto 11);
-- P_C_10_to_0 are FFs in Stage_Reg2, where as P_C_15_to_11 are produced combinationally by CSAs
signal P_D_15_to_0: std_logic_vector (15 downto 0);
signal P_D_31_to_16: std_logic_vector (31 downto 16); 
--  P_D_15_to_0 are FFs in Stage_Reg3, where as P_D_31_to_16 are produced combinationally by Comb_logic_4 (CPA/CLA)
signal s_A_out, c_A_out, s_B_in, c_B_in, s_B_out, c_B_out,s_C_in, c_C_in, s_C_out, c_C_out, s_D_in, c_D_in : std_logic_vector (15 downto 1); -- _B, _C, _D are Pipeline registers 

begin
  -----------------------------------------------------------
  
  m_A <= m; q_A <= q;
  
  mult_stage1_comb: process (m_A, q_A)
  variable s_v_A : std_logic_vector (15 downto 0); -- sum input. -- note s_v_A is 16 bits where as s_A signal is 15 bits
  variable pp_v_A : std_logic_vector (15 downto 1); -- partial product for stage 1.
  variable c_v_A : std_logic_vector (15 downto 1); -- carry input.
  begin
    
    c_v_A(15 downto 1) := "000000000000000"; -- carry input for stage 1 is 0.
    
    s_v_A(15 downto 0) := (m_A(15) and q_A(0)) & (m_A(14) and q_A(0)) & (m_A(13) and q_A(0)) & 
                        (m_A(12) and q_A(0)) & (m_A(11) and q_A(0)) & (m_A(10) and q_A(0)) & 
						(m_A(9) and q_A(0)) & (m_A(8) and q_A(0)) & (m_A(7) and q_A(0)) & 
						(m_A(6) and q_A(0)) & (m_A(5) and q_A(0)) & (m_A(4) and q_A(0)) &
						(m_A(3) and q_A(0)) & (m_A(2) and q_A(0)) & (m_A(1) and q_A(0)) & (m_A(0) and q_A(0)); -- sum input for stage 1 is partial product of stage 0.
    P_A_5_to_0(0) <= s_v_A(0); -- the lowest partial product retires as product outputs 0th bit.

    for i in 1 to 5 loop -- this loop instantiates 5 stages of the 15  CSA stages in a 16x16 multiplication. using linear cascading of CSAs (and not a Walace Tree)

	   for j in 1 to 15 loop -- one iteration of this loop makes one 15 bit CSA (one row of Full-Adder boxes)
		  pp_v_A(j) := q_A(i) and m_A(j-1);
		  s_v_A(j -1) := s_v_A(j) xor c_v_A(j) xor pp_v_A(j);
		  c_v_A(j) := (s_v_A(j) and c_v_A(j)) or (c_v_A(j) and pp_v_A(j)) or (s_v_A(j) and pp_v_A(j));
	   end loop;

	   P_A_5_to_0(i) <= s_v_A(0);
	   s_v_A(15) := m_A(15) and q_A(i);
    end loop;
	s_A_out <= s_v_A(15 downto 1); -- note s_v_A is 16 bits where as s_A signal is 15 bits
	c_A_out <= c_v_A;
   end process mult_stage1_comb;  
   
    mult_stage1_clocked: process (clk)
  
   begin
   
    if (clk'event and clk = '1') then
	  m_B <= m_A; q_B <= q_A; -- some bits of q are not needed bu they will be removed during oprimization by the syntehsis tool
      s_B_in <= s_A_out;
      c_B_in <= c_A_out;
	  P_B_5_to_0 <= P_A_5_to_0;
    end if;
    
  end process mult_stage1_clocked;  
  -----------------------------------------------------------
  
  mult_stage2_comb: process (m_B, q_B, S_B_in, c_B_in)
  variable s_v_B : std_logic_vector (15 downto 0); -- sum input. -- note s_v_B is 16 bits where as s_B signal is 15 bits
  variable pp_v_B : std_logic_vector (15 downto 1); -- partial product for stage 1.
  variable c_v_B : std_logic_vector (15 downto 1); -- carry input.
  begin
 
   s_v_B := S_B_in & '0';
   c_v_B := c_B_in;
  
    for i in 6 to 10 loop -- this loop instantiates 5 stages of the 15  CSA stages in a 16x16 multiplication. using linear cascading of CSAs (and not a Walace Tree)

	   for j in 1 to 15 loop -- one iteration of this loop makes one 15 bit CSA (one row of Full-Adder boxes)
		  pp_v_B(j) := q_B(i) and m_B(j-1);
		  s_v_B(j -1) := s_v_B(j) xor c_v_B(j) xor pp_v_B(j);
		  c_v_B(j) := (s_v_B(j) and c_v_B(j)) or (c_v_B(j) and pp_v_B(j)) or (s_v_B(j) and pp_v_B(j));
	   end loop;

	   P_B_10_to_6(i) <= s_v_B(0);
	   s_v_B(15) := m_B(15) and q_B(i);
    end loop;
	s_B_out <= s_v_B(15 downto 1); -- note s_v_B is 16 bits where as s_B signal is 15 bits
	c_B_out <= c_v_B;
   end process mult_stage2_comb;  
   
    mult_stage2_clocked: process (clk)
  
   begin
   
    if (clk'event and clk = '1') then
	  m_C <= m_B; q_C <= q_B; -- some bits of q are not needed bu they will be removed during oprimization by the syntehsis tool
      s_C_in <= s_B_out;
      c_C_in <= c_B_out;
	  P_C_10_to_0 <= P_B_10_to_6 & P_B_5_to_0;
    end if;
    
  end process mult_stage2_clocked;  
  -----------------------------------------------------------
  
  mult_stage3_comb: process (m_C, q_C, S_C_in, c_C_in)
  variable s_v_C : std_logic_vector (15 downto 0); -- sum input. -- note s_v_C is 16 bits where as s_C signal is 15 bits
  variable pp_v_C : std_logic_vector (15 downto 1); -- partial product for stage 1.
  variable c_v_C : std_logic_vector (15 downto 1); -- carry input.
  begin
 
   s_v_C := S_C_in & '0';
   c_v_C := c_C_in;
  
    for i in 11 to 15 loop -- this loop instantiates 5 stages of the 15  CSA stages in a 16x16 multiplication. using linear cascading of CSAs (and not a Walace Tree)

	   for j in 1 to 15 loop -- one iteration of this loop makes one 15 bit CSA (one row of Full-Adder boxes)
		  pp_v_C(j) := q_C(i) and m_C(j-1);
		  s_v_C(j -1) := s_v_C(j) xor c_v_C(j) xor pp_v_C(j);
		  c_v_C(j) := (s_v_C(j) and c_v_C(j)) or (c_v_C(j) and pp_v_C(j)) or (s_v_C(j) and pp_v_C(j));
	   end loop;

	   P_C_15_to_11(i) <= s_v_C(0);
	   s_v_C(15) := m_C(15) and q_C(i);
    end loop;
	s_C_out <= s_v_C(15 downto 1); -- note s_v_C is 16 bits where as s_C signal is 15 bits
	c_C_out <= c_v_C;
   end process mult_stage3_comb;  
   
    mult_stage3_clocked: process (clk)
  
   begin
   
    if (clk'event and clk = '1') then
	  -- m_D <= m_C; q_D <= q_C; -- the multiplicand and the multiplier are no more needed for the last stage.
      s_D_in <= s_C_out;
      c_D_in <= c_C_out;
	  P_D_15_to_0 <= P_C_15_to_11 & P_C_10_to_0;
    end if;
    
  end process mult_stage3_clocked;  
  -----------------------------------------------------------
    -- Comb_logic_4 (CPA/CLA)
    P_D_31_to_16 <= unsigned('0' & c_D_in) + unsigned('0' & s_D_in);
    
  -----------------------------------------------------------  
 
  P <= P_D_31_to_16  & P_D_15_to_0 ;
  
end behv;