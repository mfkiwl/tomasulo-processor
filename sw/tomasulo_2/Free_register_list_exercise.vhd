-- Modified by Da Cheng in Summer 2010
-------------------------------------------------------------------------------
-- Description: 
-- Free register list keeps track of physical register IDs, used to solve read/write dependency.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

--Entity declaration
entity Frl is 
generic (WIDE:integer:= 6 ; DEEP:integer:=16 ; PTRWIDTH:integer:=5);
port (
	--Inputs
	Clk          	  		: in  std_logic;
	Resetb       		  	: in  std_logic;
	Cdb_Flush    			: in  std_logic;
	--Interface with Rob
	Cfc_FrlHeadPtr			: in  std_logic_vector(PTRWIDTH-1 downto 0);
	Rob_CommitPrePhyAddr	: in  std_logic_vector(WIDE-1 downto 0);
	Rob_CommitRegWrite 		: in std_logic;
	Rob_Commit   			: in  std_logic;
	--Intreface with Dis_FrlRead unit
	Dis_FrlRead    			: in  std_logic;
	Frl_RdPhyAddr        	: out  std_logic_vector(WIDE-1 downto 0);
	Frl_Empty      			: out  std_logic;
	--Interface with Previous Head Pointer Stack
	Frl_HeadPtr    			: out  std_logic_vector(PTRWIDTH-1 downto 0) 
);
end Frl;

architecture behav of Frl is
subtype freeregid is std_logic_vector(WIDE-1 downto 0);
type freeregid1 is array(0 to DEEP-1) of freeregid;
signal freereglist:freeregid1;
signal Frl_HeadPtr_temp :  std_logic_vector(PTRWIDTH-1 downto 0) ;
signal Frl_TailPtr :  std_logic_vector(PTRWIDTH-1 downto 0) ;

begin
--	Task 1:	Fill in the process with how to update FRL

Process(Clk,Resetb)
--variable i:integer;
begin
	if (Resetb = '0') then
		-- Initialization of FRL contents: 		location 0	=physical register 32
		-- 										location15 	=physical register 47
		freereglist(15) <= "101111";
		freereglist(14) <= "101110";
		freereglist(13) <= "101101";
		freereglist(12) <= "101100";
		freereglist(11) <= "101011";
		freereglist(10) <= "101010";
		freereglist(9) <= "101001";
		freereglist(8) <= "101000";
		freereglist(7) <= "100111";
		freereglist(6) <= "100110";
		freereglist(5) <= "100101";
		freereglist(4) <= "100100";
		freereglist(3) <= "100011";
		freereglist(2) <= "100010";
		freereglist(1) <= "100001";
		freereglist(0) <= "100000";		
		Frl_HeadPtr_temp <= "00000";
		Frl_TailPtr <= "10000";
		
	elsif ( Clk'event and Clk = '1' ) then
		-- Update head pointer when dispatch and flush
		if (Cdb_Flush = '1') then	--Phase 2, checkpoints and walk forward/backward?
			Frl_HeadPtr_temp <= Cfc_FrlHeadPtr;
		elsif (Dis_FrlRead = '1') then
			Frl_HeadPtr_temp <= Frl_HeadPtr_temp + '1';
		end if;
		
		-- Update tail pointer when commit
		-- Free physical registers when commit
		if (Rob_Commit = '1' and Rob_CommitRegWrite = '1') then
			Frl_TailPtr <= Frl_TailPtr + '1';
			freereglist( conv_integer(unsigned(Frl_TailPtr(3 downto 0))) ) <= Rob_CommitPrePhyAddr;
		end if;
		
	end if;
	
end process;
--	Task 2:	generate the two signals: Frl_Empty and Frl_RdPhyAddr.
Frl_Empty		<= '1' when (Frl_HeadPtr_temp = Frl_TailPtr) else '0';
Frl_RdPhyAddr	<= freereglist( conv_integer(unsigned(Frl_HeadPtr_temp(3 downto 0))) );
Frl_HeadPtr		<= Frl_HeadPtr_temp;

end architecture behav;