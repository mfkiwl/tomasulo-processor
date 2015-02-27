------------------------------------------------------------------------------
-- File name: ee560_debounce_DPB_SCEN_CCEN_MCEN.vhd 
-- Date: 6/10/2009 
-- (C) Copyright 2009 Gandhi Puvvada 

-- Description:
-- 	A vhdl design for debouncing a Push Button (PB) and produce the following: 
-- 		(1) a debounced pulse DPB (DPB = debounced PB)
--		(2) a single clock-enable pulse, SCEN, after 0.084 sec, for single-stepping user design using a push button,
--		(3) a contunuous clock-enable pulse, CCEN, after another 0.16 sec., for running at full-speed
--		(4) a sequence of (multiple of) clock-enable pulses, MCEN, after every 0.084 sec after the 0.16 sec, for multi-stepping
-- 
-- 	Once 'PB' is pressed,  after the initial bouncing finishes in the WQ  (wait quarter second (actaully 0.084 sec)) state,  the DPB is activated,
-- 	and all three  pulses (SCEN, CCEN, and MCEN) are produced just for *one clock* in SCEN_state. 
-- 	Then, after waiting another half second in the WH (wait half second) (actaully 0.168 sec)) state,  the MCEN goes active for 1 clock every 
--	quarter second  and the CCEN goes active continuously. in MCEN_state. Finally, if the PB is released, we wait in WFCR 
--	(Wait for a complete release) state for a quarter second and return to the INI state. Please see the state diagram or 
-- 	read the code to understand the exact behavior. 

-- 	The  additional half-second (actually 0.168 sec) waiting after producing the first single-clock wide pulse allows the user
-- 	to release the button in time to avoid multi-stepping or running at full-speed even if he/she has used   MCEN or CCEN 
-- 	in his/her design.

-- 	To achieve the above and generate the outputs without asny glitches (though this is not necessary), let us use output coding.
--        In output coding the state memory bits are thoughtfully chosen in order to form the needed outputs.
--	 In this case  DPB, SCEN, MCEN, and CCEN are thos outputs.  However, the output combinations may repeat in different states.
--	So we need here  two tie-breakers.

--	State     		State       DPB	    SCEN          MCEN         CCEN    Tie-Breaker1   Tie-Breaker0
--	initial      		  INI		0		0		0		0		0		0
--	wait quarter	   WQ	0		0		0		0		0		1
--	SCEN_state	SCEN_st	1		1		1		1		-		-
--	wait half		   WH	1		0		0		0		0		0
--	MCEN_state	MCEN_st	1		0		1		1		-		-
--	CCEN_state	CCEN_st	1		0		0		1		-		-
--	Counter Clear	CCR		1		0		0		0		0		1
--	WFCR_state	WFCR	1		0		0		0		1		-

--	Timers (Counters to keep time):  2**19 clocks of 20ns = 2**20 of 10ns = approximately 10  milliseconds = accurately 10.48576 ms
--	So, instead of quarter second, let us wait for 2**22 clocks ( 0.084 sec.) and instead of half second,
--	let us wait for 2**23 clocks (0.168 seconds).
--	If we use a 24-bit counter, count(23 downto 0), and start it with 0, then the first time, count(22) goes high,
--	we know that the lower 22 bits (21:0) have gone through their 2**22 combinations. So count(22) is used as 
-- 	the 0.084 sec timer and the count(23) is used as the 0.168 sec timer.

--	We will use a generic parameter called N_dc (dc for debounce count) in place of 23 (and N_dc-1 in place of 22), 
--	so that N_dc can be made 4 during behavioral simulation to test this debouncing module.

--	As the names say, the SCEN, MCEN, and the CCEN are clock enables and are not clocks by themselves. If you use 
--	SCEN  (or MCEN) as a "clock" by itself,  then you would be creating a lot of sckew as these outputs of the internal
--	state machine take ordinary routes and do not get to go on the special routes used for clock distribution.
-- 	However, when they are used as clock enables, the static timing analyzer checks timing of these signals with respect 
--	to the main clock signal (50 MHz clock) properly. This results in a good timing design.  Moreover, you can use different
--	clock enables in different parts of the control unit so that the system is single stepped in some critical areas and 
--	multi-stepped or made to run at full speed.  This will not be possible if you try to use both SCEN and MCEN as clocks  
-- 	as you should not be using multiple clocks in a supposedly single-clock system. 
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ee560_debounce is
generic  (N_dc: 		positive := 23);
port     (CLK, RESETB_DEBOUNCE	:in  std_logic; -- CLK = 50 MHz
		  PB		:in  std_logic; -- push button
	 	  DPB, SCEN, MCEN, CCEN	:out std_logic -- debounced PB, single_CEN, multi_CEN, continuous CEN 
		 );
end  ee560_debounce ;
-------------------------------------------------------------------------------
architecture debounce_RTL of ee560_debounce   is

--  Note:  The most common RTL coding in VHDL is to use symbolic names for states
--  and leave it to the synthesis tool to tie these symbolic names to encoded bit combinations.
--  Designers define a suitable enumerated state type as shown below. 
--     type debounce_state_type is (INI, WQ, SCEN_St, WH, MCEN_St, CCEN_St, CCR, WFCR);
--     signal debounce_state: 	debounce_state_type;
--  However, in this design, we would like to use output coding and we want enforce state assignments.
--  Hence, we define constants bearing the symbolic state names and initialize them to the bit 
--  combinations of our choice.

-- By default, the synthesis tool (with default XST option "auto" for FSM encoding) will extract the state machine and will perform
attribute fsm_encoding: string;  -- Refer to XST user guide -- FSM encoding

signal debounce_state: 	std_logic_vector(5 downto 0);  -- 6-bit combination
--                                                                                                                       DPB       SCEN       MCEN    CCEN   TieB1       TieB0
constant INI: 	     std_logic_vector(5 downto 0) := ('0' & '0' & '0' & '0' & '0' & '0'); 
constant WQ: 	     std_logic_vector(5 downto 0) := ('0' & '0' & '0' & '0' & '0' & '1'); 
constant SCEN_st:    std_logic_vector(5 downto 0) := ('1' & '1' & '1' & '1' & '0' & '0'); 
constant WH: 	     std_logic_vector(5 downto 0) := ('1' & '0' & '0' & '0' & '0' & '0'); 
constant MCEN_St: 	 std_logic_vector(5 downto 0) := ('1' & '0' & '1' & '1' & '0' & '0'); 
constant CCEN_St: 	 std_logic_vector(5 downto 0) := ('1' & '0' & '0' & '1' & '0' & '0'); 
constant CCR: 	     std_logic_vector(5 downto 0) := ('1' & '0' & '0' & '0' & '0' & '1'); 
constant WFCR: 	     std_logic_vector(5 downto 0) := ('1' & '0' & '0' & '0' & '1' & '0'); 

attribute fsm_encoding of debounce_state: signal is "user";


-- The enumerated state type allows the display of state name in  symbolic form (ASCII form) in the waveform which is easy to read.
-- So, to provide this convenience, let us define an enumerated state signal called d_state here, and later assign values to it.
type debounce_state_type is (INI_s, WQ_s, SCEN_St_s, WH_s, MCEN_St_s, CCEN_St_s, CCR_s, WFCR_s);
signal d_state: 	debounce_state_type;
 
signal debounce_count: 	std_logic_vector(N_dc downto 0);
-- signal DPB_int, SCEN_int, MCEN_int, CCEN_int: std_logic; -- internal signals
-- signal tie-breaker1, tie-breaker0: std_logic; -- internal signals

begin

-- concurrent signal assignment statements

(DPB, SCEN, MCEN, CCEN) <= debounce_state(5 downto 2); -- this is because of output coding

-- for the purpose of displaying in the waveform
d_state <= 	INI_s when (debounce_state = INI) else
			WQ_s when (debounce_state = WQ) else
			SCEN_St_s when (debounce_state = SCEN_St) else
			WH_s when (debounce_state = WH) else
			MCEN_St_s when (debounce_state = MCEN_St) else
			CCEN_St_s when (debounce_state = CCEN_St) else
			CCR_s when (debounce_state = CCR) else
			WFCR_s; --  when (debounce_state = WFCR);


debounce: process (CLK, RESETB_DEBOUNCE)

        begin

          if (RESETB_DEBOUNCE = '0') then

            debounce_count <= (others => 'X');
            debounce_state <= INI;

          elsif (CLK'event and CLK = '1') then

            case debounce_state is

              when INI =>
                debounce_count <= (others => '0');
                if (PB = '1') then
                  debounce_state <= WQ;
 		      end if;
	     
              when WQ =>
                debounce_count <= debounce_count + 1;
                if (PB = '0') then
                  debounce_state <= INI;
                elsif (debounce_count(N_dc-1) = '1') then 
                  debounce_state <= SCEN_St;
                end if;

              when SCEN_St =>
		      debounce_count <= (others => '0');
                debounce_state <= WH;

              when WH =>  
                debounce_count <= debounce_count + 1;
                if (PB = '0') then
                  debounce_state <= CCR;
                elsif (debounce_count(N_dc) = '1') then 
                  debounce_state <= MCEN_St;
                end if;

              when MCEN_St =>
		      debounce_count <= (others => '0');
                debounce_state <= CCEN_St;
				
              when CCEN_St =>  
                debounce_count <= debounce_count + 1;
                if (PB = '0') then
                  debounce_state <= CCR;
                elsif (debounce_count(N_dc-1) = '1') then 
                  debounce_state <= MCEN_St;
                end if;

              when CCR =>
		      debounce_count <= (others => '0');
                debounce_state <= WFCR;

              when others =>  -- when WFCR =>  
                debounce_count <= debounce_count + 1;
                if (PB = '1') then
                  debounce_state <= WH;
                elsif (debounce_count(N_dc-1) = '1') then 
                  debounce_state <= INI;
                end if;

              end case;

          end if;

        end process debounce;
        ----------------------------

end debounce_RTL ;
