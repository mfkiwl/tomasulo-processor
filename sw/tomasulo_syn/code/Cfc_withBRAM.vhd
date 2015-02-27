-------------------------------------------------------------------------------
--
-- Design   : CFC Unit
-- Project  : Tomasulo Processor 
-- Entity   : CFC 
-- Author   : Rajat Shah
-- Company  : University of Southern California 
-- Last Updated     : April 15th, 2010
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
entity cfc is
port (  --global signals
		Clk	 			         :in std_logic;                              --Global Clock Signal
		Resetb			         :in std_logic;                              --Global Reset Signal
		--interface with dispatch unit
		Dis_InstValid            :in std_logic;                              --Flag indicating if the instruction dispatched is valid or not
		Dis_CfcBranchTag         :in std_logic_vector(4 downto 0);           --ROB Tag of the branch instruction 
		Dis_CfcRdAddr            :in std_logic_vector(4 downto 0);           --Rd Logical Address
		Dis_CfcRsAddr            :in std_logic_vector(4 downto 0);			 --Rs Logical Address
		Dis_CfcRtAddr            :in std_logic_vector(4 downto 0);			 --Rt Logical Address
		Dis_CfcNewRdPhyAddr      :in std_logic_vector(5 downto 0);           --New Physical Register Address assigned to Rd by Dispatch
		Dis_CfcRegWrite          :in std_logic;                              --Flag indicating whether current instruction being dispatched is register writing or not
		Dis_CfcBranch            :in std_logic;                              --Flag indicating whether current instruction being dispatched is branch or not
		Dis_Jr31Inst          :in std_logic;                              --Flag indicating if the current instruction is Jr 31 or not
		
		Cfc_RdPhyAddr            :out std_logic_vector(5 downto 0); 	     --Previous Physical Register Address of Rd
		Cfc_RsPhyAddr	         :out std_logic_vector(5 downto 0);          --Latest Physical Register Address of Rs
		Cfc_RtPhyAddr	         :out std_logic_vector(5 downto 0);          --Latest Physical Register Address of Rt
		Cfc_Full                 :out std_logic;							 --Flag indicating whether checkpoint table is full or not
						
		--interface with ROB
		Rob_TopPtr		         :in std_logic_vector(4 downto 0);		     --ROB tag of the intruction at the Top
		Rob_Commit               :in std_logic;                              --Flag indicating whether instruction is committing in this cycle or not
		Rob_CommitRdAddr         :in std_logic_vector(4 downto 0);           --Rd Logical Address of committing instruction
		Rob_CommitRegWrite       :in std_logic;					             --Indicates if instruction is writing to register or not
		Rob_CommitCurrPhyAddr    :in std_logic_vector(5 downto 0);			 --Physical Register Address of Rd of committing instruction			
		
		--signals from cfc to ROB in case of CDB flush
		Cfc_RobTag               :out std_logic_vector(4 downto 0);          --Rob Tag of the instruction to which rob_bottom is moved after branch misprediction (also to php)
	
		--interface with FRL
		Frl_HeadPtr              :in std_logic_vector(4 downto 0);           --Head Pointer of the FRL when a branch is dispatched
		Cfc_FrlHeadPtr           :out std_logic_vector(4 downto 0);          --Value to which FRL has to jump on CDB Flush
 		
		--interface with CDB
		Cdb_Flush  		         :in std_logic;                              --Flag indicating that current instruction is mispredicted or not
		Cdb_RobTag               :in std_logic_vector(4 downto 0);		     --ROB Tag of the mispredicted branch
		Cdb_RobDepth		     :in std_logic_vector(4 downto 0)			 --Depth of mispredicted branch from ROB Top
	  );
end cfc;

architecture cfc_arch of cfc is

--Signal declaration for 8 copies of checkpoints - Each 32 deep and 6 bit wide
type cfc_checkpoint_type is array(0 to 255) of std_logic_vector(5 downto 0);
signal Cfc_RsList, Cfc_RtList, Cfc_RdList : cfc_checkpoint_type; --3 BRAM, each containing flattened 8 tables

--Signal declaration for committed checkpoint (Retirement RAT) - 32 deep and 6 bit wide
type committed_type is array(0 to 31) of std_logic_vector(5 downto 0);
signal Committed_RsList, Committed_RtList, Committed_RdList : committed_type :=(
	  "000000", "000001", "000010", "000011", "000100", "000101", "000110", "000111",
      "001000", "001001", "001010", "001011", "001100", "001101", "001110", "001111", 
      "010000", "010001", "010010", "010011", "010100", "010101", "010110", "010111",
      "011000", "011001", "011010", "011011", "011100", "011101", "011110", "011111"); -- 3 copies of committed list initialize to 0 to 31

--Signal declaration for 8 copies of Dirty Flag Array(DFA) validating each checkpoints - Each 32 deep and 1 bit wide
type dfa_checkpoint_type is array(0 to 31) of std_logic;
type dfa_array_type is array (0 to 7) of dfa_checkpoint_type;
signal Dfa_List : dfa_array_type;

type checkpoint_tag_type is array (0 to 7) of std_logic_vector(4 downto 0);
signal Checkpoint_TagArray: checkpoint_tag_type; --8 deep and 5 bit wide array for storing ROB tag of checkpointed branch instructions

type Frl_HeadPtrArray_type is array (0 to 7) of std_logic_vector (4 downto 0);
signal Frl_HeadPtrArray: Frl_HeadPtrArray_type;

type depth_tag_type is array (0 to 7) of std_logic_vector(4 downto 0);
signal Depth_Array: depth_tag_type; 

type Cfc_Valid_Array_type is array (0 to 7) of std_logic;
signal Cfc_ValidArray: Cfc_Valid_Array_type;

signal Full, Empty : std_logic; --flag indicating if all 8 checkpoints are used or empty
signal Head_Pointer, Tail_Pointer: std_logic_vector(2 downto 0); --Head Pointer indicates active checkpoint while tail pointer indicates oldest uncommitted branch
signal Checkpoint_MatchArray: std_logic_vector (7 downto 0); --Array indicating if the instruction on CDB matches any checkpointed branch
signal DFA_RsValid, DFA_RtValid, DFA_RdValid: std_logic; 
signal Cfc_RsList_temp, Cfc_RtList_temp, Cfc_RdList_temp: std_logic_vector (5 downto 0);
signal Committed_RsList_temp, Committed_RtList_temp, Committed_RdList_temp: std_logic_vector (5 downto 0);
signal Next_Head_Pointer: std_logic_vector (2 downto 0); --Temporary Head_pointer generated during CDB Flush

begin
				  
Depth_Array(0) <= Checkpoint_TagArray(0) - Rob_TopPtr; -- std_logic_vector is treated as unsigned because of library declaration IEEE_STD_LOGIC_UNSIGNED 
Depth_Array(1) <= Checkpoint_TagArray(1) - Rob_TopPtr;
Depth_Array(2) <= Checkpoint_TagArray(2) - Rob_TopPtr;
Depth_Array(3) <= Checkpoint_TagArray(3) - Rob_TopPtr;
Depth_Array(4) <= Checkpoint_TagArray(4) - Rob_TopPtr;
Depth_Array(5) <= Checkpoint_TagArray(5) - Rob_TopPtr;
Depth_Array(6) <= Checkpoint_TagArray(6) - Rob_TopPtr;
Depth_Array(7) <= Checkpoint_TagArray(7) - Rob_TopPtr;

--Combinational assignment determining if the instruction on CDB is a frozen branch or not
Checkpoint_MatchArray(0) <= '1' when ((Checkpoint_TagArray(0) = Cdb_RobTag) and (Cfc_ValidArray(0) = '1')) else
						    '0';
Checkpoint_MatchArray(1) <= '1' when ((Checkpoint_TagArray(1) = Cdb_RobTag) and (Cfc_ValidArray(1) = '1')) else
						    '0';
Checkpoint_MatchArray(2) <= '1' when ((Checkpoint_TagArray(2) = Cdb_RobTag) and (Cfc_ValidArray(2) = '1')) else
						    '0';
Checkpoint_MatchArray(3) <= '1' when ((Checkpoint_TagArray(3) = Cdb_RobTag) and (Cfc_ValidArray(3) = '1')) else
						    '0';
Checkpoint_MatchArray(4) <= '1' when ((Checkpoint_TagArray(4) = Cdb_RobTag) and (Cfc_ValidArray(4) = '1')) else
						    '0';
Checkpoint_MatchArray(5) <= '1' when ((Checkpoint_TagArray(5) = Cdb_RobTag) and (Cfc_ValidArray(5) = '1')) else
						    '0';
Checkpoint_MatchArray(6) <= '1' when ((Checkpoint_TagArray(6) = Cdb_RobTag) and (Cfc_ValidArray(6) = '1')) else
						    '0';
Checkpoint_MatchArray(7) <= '1' when ((Checkpoint_TagArray(7) = Cdb_RobTag) and (Cfc_ValidArray(7) = '1')) else
						    '0';								


Cfc_Full <= Full;

--Task 0: Complete the Full and empty conditions depending on the Head_Pointer and Tail_pointer values				  
Full <=  '1' when (unsigned(Tail_Pointer-Head_Pointer)=1) else '0';
		
Empty <= '1' when (Head_Pointer = Tail_Pointer) else '0';  --Flag indicating that there is no frozen checkpoint
	
		 
Cfc_FrlHeadPtr <= Frl_HeadPtrArray(conv_integer(Next_Head_Pointer));
Cfc_RobTag <= Checkpoint_Tagarray(conv_integer(Next_Head_Pointer));

CfcUpdate: process (Clk, Resetb)
begin
  if(Resetb = '0') then
	Head_Pointer <= "000"; --Here the Head_Pointer points to the active checkpoint and not to the empty location
    Tail_Pointer <= "000";
	for I in 0 to 7 loop
	  for J in 0 to 31 loop
	   Dfa_List(I)(J) <= '0';
	  end loop;
	  Cfc_ValidArray(I) <= '0';
	end loop;
	
  elsif (Clk'event and Clk = '1') then
	--Releasing the oldest checkpoint if the branch reaches top of ROB
	if ((Rob_Commit = '1') and (Rob_TopPtr = Checkpoint_TagArray(conv_integer(Tail_Pointer))) and ((Tail_Pointer - Next_Head_Pointer) /= "00")) then 
		Tail_Pointer <= Tail_Pointer + '1';
		Cfc_ValidArray(conv_integer(Tail_Pointer)) <= '0';
		for I in 0 to 31 loop
			Dfa_List(conv_integer(Tail_Pointer))(I) <= '0';
		end loop;
	end if;
	
	if (Cdb_Flush = '1') then
	  
	  ---- ADDED BY MANPREET--- need to invalidate the active rat dfa bits
	  for J in 0 to 31 loop
					Dfa_List(conv_integer(Head_Pointer))(J) <= '0';
		end loop;
			
	  -----------------------------			
		for I in 0 to 7 loop
		  -- changed by Manpreet.. shouldnt invalidate the rat corresponding to branch_tag = cdb_robtag as
		  -- it contains instructions before the flushed branch and will become the active rat
			if (Cdb_RobDepth < Depth_Array(I)) then     --Invalidating all the younger checkpoints and clearing the Dfa_List
				Cfc_ValidArray(I)<='0';
				for J in 0 to 31 loop
					Dfa_List(I)(J) <= '0';
				end loop;
			end if;	
			if (Cdb_RobDepth = Depth_Array(I)) then
				Cfc_ValidArray(I)<='0';	
			end if ;	
		end loop;			
		Head_Pointer <= Next_Head_Pointer;

	else	
		-- Task 1: Update the DFA bit of the Active Checkpoint on dispatch of Register Writing Instruction
			if (Dis_InstValid='1' and Dis_CfcRegWrite='1') then
					Dfa_List(conv_integer(Head_Pointer)) (conv_integer(Dis_CfcRdAddr)) <= '1';
			end if;
		
		-- Task 2: Create a new checkpoint for dispatched branch (i.e. freeze the active checkpoint)
		
		if ((Dis_CfcBranch = '1' or Dis_Jr31Inst = '1')and Dis_InstValid = '1' and ((Full /= '1') or ((Rob_Commit = '1') and (Full = '1') ))) then	  -- Task 2.1 - some conditions missing - think structural hazard - can't dispatch branch if all checkpoints are in use. But what if a branch is committing as well?
			Checkpoint_TagArray (conv_integer(Head_Pointer)) <= Dis_CfcBranchTag;
			Cfc_ValidArray (conv_integer(Head_Pointer)) <= '1';
			Frl_HeadPtrArray(conv_integer(Head_Pointer)) <= Frl_HeadPtr;
			Head_Pointer <= Head_Pointer + 1;
			-- Task 2.2 - what things need to be done for a new checkpoint? Tagarray, validarray, FRL headpointer and the headpointer  should be updated. 
		end if;
    
  end if;		
  end if;
end process;

--Combinational Process to determine new head pointer during branch misprediction
CDB_Flush_Process: process (Cdb_Flush, Checkpoint_MatchArray, Frl_HeadPtrArray, Checkpoint_TagArray, Head_Pointer)
begin  
  Next_Head_Pointer <= Head_Pointer;
  if (Cdb_Flush = '1') then
	Case Checkpoint_MatchArray is  --Case statement to move the head pointer on branch misprediction to corresponding frozen checkpoint
		when "00000001" =>
			Next_Head_Pointer <= "000";
		when "00000010" =>
			Next_Head_Pointer <= "001";
		when "00000100" =>
			Next_Head_Pointer <= "010";
		when "00001000" =>
			Next_Head_Pointer <= "011";
		when "00010000" =>
			Next_Head_Pointer <= "100";
		when "00100000" =>
			Next_Head_Pointer <= "101";
		when "01000000" =>
			Next_Head_Pointer <= "110";
		when "10000000" =>
			Next_Head_Pointer <= "111";
		when others =>
			Next_Head_Pointer <= "XXX";
	end case;	
  end if;  
end process;

--Process to find the latest value of Rs to be given to Dispatch
Dispatch_RsRead_Process: process (Clk,Resetb)
variable found_Rs1, found_Rs2: std_logic;
variable BRAM_pointer1, BRAM_pointer2: integer;
variable BRAM_RsPointer: std_logic_vector(2 downto 0);
begin
  if (Resetb = '0') then
    Committed_RsList <= ("000000", "000001", "000010", "000011", "000100", "000101", "000110", "000111",
      "001000", "001001", "001010", "001011", "001100", "001101", "001110", "001111", 
      "010000", "010001", "010010", "010011", "010100", "010101", "010110", "010111",
      "011000", "011001", "011010", "011011", "011100", "011101", "011110", "011111");
    
  elsif (Clk'event and Clk = '1') then
   
	for I in 7 downto 0 loop
	 --This condition in the loop checks the 8 DFA table from Head_Pointer to Physical Bottom area to see which DFA bit is set first
	  if (I <= Head_Pointer) then  
	    if (Dfa_List(I)(conv_integer(Dis_CfcRsAddr)) = '1') then
			BRAM_pointer1 := I;  --storing the pointer to corresponding DFA
			found_Rs1 := '1';
		    exit;
		else
			found_Rs1 := '0';
		end if;
	  end if;
	  end loop ;
	 -- This condition n the loop scan the 8 DFA table from Physical Top to Tail_Pointer area to see which DFA bit is set first 
	 for I in 7 downto 0 loop
	  if (I >= Tail_Pointer) then
	    if (Dfa_List(I)(conv_integer(Dis_CfcRsAddr)) = '1') then
			BRAM_pointer2 := I;  --storing the pointer to corresponding DFA
			found_Rs2 := '1';
			exit;
		else
			found_Rs2 := '0';
		end if;
	  end if;
	end loop;
	
	-- Task 3: Use found_Rs1, found_Rs2, BRAM_pointer1 and BRAM_pointer2 to set BRAM_Rspointer and Dfa_RsValid
	-- Dfa_RsValid tells if the Rs register is present in any of the 8 checkpoints or not
	-- BRAM_Rspointer gives which checkpoint it is present in. Set it to  "000" by default.
		Dfa_RsValid <= found_Rs1 or found_Rs2;
		
		if (found_Rs1 = '1') then
			BRAM_Rspointer := conv_std_logic_vector(BRAM_pointer1, 3);
		elsif (found_Rs2 = '1') then
			BRAM_Rspointer := conv_std_logic_vector(BRAM_pointer2, 3);
		else
			BRAM_Rspointer := (others => '0');
		end if;
	-- Task 4: Update Committed_Rslist when a register-writing instruction is committed
	 if (Rob_Commit = '1' and Rob_CommitRegWrite = '1') then
		 Committed_Rslist(conv_integer(Rob_CommitRdAddr)) <= Rob_CommitCurrPhyAddr;
	 end if;
	
	
	if (Dis_InstValid = '1') then
	  if (Dis_CfcRegWrite = '1') then --setting the DFA bit in the active checkpoint corresponding to Rd Addr location
	    Cfc_RsList(conv_integer(Head_Pointer & Dis_CfcRdAddr)) <= Dis_CfcNewRdPhyAddr;
	  end if; 
	    
	  Cfc_RsList_temp <= Cfc_RsList(conv_integer(BRAM_RsPointer & Dis_CfcRsAddr)); --concatenating the pointer & logical Rs address value to read BRAM
	  Committed_RsList_temp <= Committed_RsList(conv_integer(Dis_CfcRsAddr));	  
	end if;
  end if;
end process;

process (Dfa_RsValid, Cfc_RsList_temp, Committed_RsList_temp)--mux to select between the checkpoint value or committed value
begin
  if (Dfa_RsValid = '1') then
	Cfc_RsPhyAddr <= Cfc_RsList_temp;
  else
	Cfc_RsPhyAddr <= Committed_RsList_temp;
  end if;
end process;

-- Task 5: same process as above for finding the latest value of Rt
Dispatch_RtRead_Process: process(Clk,Resetb)
variable found_Rt1, found_Rt2: std_logic;
variable BRAM_pointer1, BRAM_pointer2: integer;
variable BRAM_RtPointer: std_logic_vector (2 downto 0);
begin
  if (Resetb = '0') then
    Committed_RtList <= ("000000", "000001", "000010", "000011", "000100", "000101", "000110", "000111",
      "001000", "001001", "001010", "001011", "001100", "001101", "001110", "001111", 
      "010000", "010001", "010010", "010011", "010100", "010101", "010110", "010111",
      "011000", "011001", "011010", "011011", "011100", "011101", "011110", "011111");
    
  elsif (Clk'event and Clk = '1') then
    
	for I in 7 downto 0 loop
	 --This condition in the loop checks the 8 DFA table from Head_Pointer to Physical Bottom area to see which DFA bit is set first
	  if (I <= Head_Pointer) then  
	    if (Dfa_List(I)(conv_integer(Dis_CfcRtAddr)) = '1') then
			BRAM_pointer1 := I;  --storing the pointer to corresponding DFA
			found_Rt1 := '1';
		    exit;
		else
			found_Rt1 := '0';
		end if;
	  end if;
	  end loop ;
	 -- This condition n the loop scan the 8 DFA table from Physical Top to Tail_Pointer area to see which DFA bit is set first 
	 for I in 7 downto 0 loop
	  if (I >= Tail_Pointer) then
	    if (Dfa_List(I)(conv_integer(Dis_CfcRtAddr)) = '1') then
			BRAM_pointer2 := I;  --storing the pointer to corresponding DFA
			found_Rt2 := '1';
			exit;
		else
			found_Rt2 := '0';
		end if;
	  end if;
	end loop;
	
	-- Use found_Rt1, found_Rt2, BRAM_pointer1 and BRAM_pointer2 to set BRAM_Rtpointer and Dfa_RtValid
	-- Dfa_RtValid tells if the Rt register is present in any of the 8 checkpoints or not
	-- BRAM_Rtpointer gives which checkpoint it is present in. Set it to  "000" by default.
		Dfa_RtValid <= found_Rt1 or found_Rt2;
		
		if (found_Rt1 = '1') then
			BRAM_Rtpointer := conv_std_logic_vector(BRAM_pointer1, 3);
		elsif (found_Rt2 = '1') then
			BRAM_Rtpointer := conv_std_logic_vector(BRAM_pointer2, 3);
		else
			BRAM_Rtpointer := (others => '0');
		end if;
	-- Task 4: Update Committed_Rtlist when a register-writing instruction is committed
	 if (Rob_Commit = '1' and Rob_CommitRegWrite = '1') then
		 Committed_Rtlist(conv_integer(Rob_CommitRdAddr)) <= Rob_CommitCurrPhyAddr;
	 end if;
	
	
	if (Dis_InstValid = '1') then
	  if (Dis_CfcRegWrite = '1') then --setting the DFA bit in the active checkpoint corresponding to Rd Addr location
	    Cfc_RtList(conv_integer(Head_Pointer & Dis_CfcRdAddr)) <= Dis_CfcNewRdPhyAddr;
	  end if; 
	    
	  Cfc_RtList_temp <= Cfc_RtList(conv_integer(BRAM_RtPointer & Dis_CfcRtAddr)); --concatenating the pointer & logical Rt address value to read BRAM
	  Committed_RtList_temp <= Committed_RtList(conv_integer(Dis_CfcRtAddr));	  
	end if;
  end if;
end process;

process (Dfa_RtValid, Cfc_RtList_temp, Committed_RtList_temp)
begin
  if (Dfa_RtValid = '1') then
	Cfc_RtPhyAddr <= Cfc_RtList_temp;
  else
	Cfc_RtPhyAddr <= Committed_RtList_temp;
  end if;
end process;

-- Task 6: same process as above for finding the latest value of Rd
Dispatch_RdRead_Process: process(Clk,Resetb)
variable found_Rd1, found_Rd2: std_logic;
variable BRAM_pointer1, BRAM_pointer2: integer;
variable BRAM_RdPointer: std_logic_vector (2 downto 0);
begin
  if (Resetb = '0') then
    Committed_RdList <= ("000000", "000001", "000010", "000011", "000100", "000101", "000110", "000111",
      "001000", "001001", "001010", "001011", "001100", "001101", "001110", "001111", 
      "010000", "010001", "010010", "010011", "010100", "010101", "010110", "010111",
      "011000", "011001", "011010", "011011", "011100", "011101", "011110", "011111");
    
  elsif (Clk'event and Clk = '1') then

	for I in 7 downto 0 loop
	 --This condition in the loop checks the 8 DFA table from Head_Pointer to Physical Bottom area to see which DFA bit is set first
	  if (I <= Head_Pointer) then  
	    if (Dfa_List(I)(conv_integer(Dis_CfcRdAddr)) = '1') then
			BRAM_pointer1 := I;  --storing the pointer to corresponding DFA
			found_Rd1 := '1';
		    exit;
		else
			found_Rd1 := '0';
		end if;
	  end if;
	  end loop ;
	 -- This condition n the loop scan the 8 DFA table from Physical Top to Tail_Pointer area to see which DFA bit is set first 
	 for I in 7 downto 0 loop
	  if (I >= Tail_Pointer) then
	    if (Dfa_List(I)(conv_integer(Dis_CfcRdAddr)) = '1') then
			BRAM_pointer2 := I;  --storing the pointer to corresponding DFA
			found_Rd2 := '1';
			exit;
		else
			found_Rd2 := '0';
		end if;
	  end if;
	end loop;
	
	-- Use found_Rd1, found_Rd2, BRAM_pointer1 and BRAM_pointer2 to set BRAM_Rdpointer and Dfa_RdValid
	-- Dfa_RdValid tells if the Rd register is present in any of the 8 checkpoints or not
	-- BRAM_Rdpointer gives which checkpoint it is present in. Set it to  "000" by default.
		Dfa_RdValid <= found_Rd1 or found_Rd2;
		
		if (found_Rd1 = '1') then
			BRAM_Rdpointer := conv_std_logic_vector(BRAM_pointer1, 3);
		elsif (found_Rd2 = '1') then
			BRAM_Rdpointer := conv_std_logic_vector(BRAM_pointer2, 3);
		else
			BRAM_Rdpointer := (others => '0');
		end if;
	-- Task 4: Update Committed_Rdlist when a register-writing instruction is committed
	 if (Rob_Commit = '1' and Rob_CommitRegWrite = '1') then
		 Committed_Rdlist(conv_integer(Rob_CommitRdAddr)) <= Rob_CommitCurrPhyAddr;
	 end if;
	
	
	if (Dis_InstValid = '1') then
	  if (Dis_CfcRegWrite = '1') then --setting the DFA bit in the active checkpoint corresponding to Rd Addr location
	    Cfc_RdList(conv_integer(Head_Pointer & Dis_CfcRdAddr)) <= Dis_CfcNewRdPhyAddr;
	  end if; 
	    
	  Cfc_RdList_temp <= Cfc_RdList(conv_integer(BRAM_RdPointer & Dis_CfcRdAddr)); --concatenating the pointer & logical Rd address value to read BRAM
	  Committed_RdList_temp <= Committed_RdList(conv_integer(Dis_CfcRdAddr));	  
	end if;
  end if;


end process;

process (Dfa_RdValid, Cfc_RdList_temp, Committed_RdList_temp)
begin
  if (Dfa_RdValid = '1') then
	Cfc_RdPhyAddr <= Cfc_RdList_temp;
  else
	Cfc_RdPhyAddr <= Committed_RdList_temp;
  end if;
end process;

end cfc_arch;	      
