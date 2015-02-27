-------------------------------------------------------------------------------
--
-- Design   : Dispatch Unit
-- Project  : Tomasulo Processor 
-- Entity   : dispatch_unit
-- Author   : Manpreet Billing
-- Company  : University of Southern California 
-- Last Updated     : March 2, 2010
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity dispatch_unit is
port(
      Clk                : in std_logic ;
      Resetb             : in std_logic ;
     -- Interface with Intsruction Fetch Queue
      Ifetch_Instruction : in std_logic_vector(31 downto 0); -- instruction from IFQ
      Ifetch_PcPlusFour  : in std_logic_vector(31 downto 0); -- the PC+4 value carried forward for jumping and branching
      Ifetch_EmptyFlag   : in std_logic;	-- signal showing that the ifq is empty,hence stopping any decoding and dispatch of the current if_inst
      Dis_Ren            : out std_logic;   -- stalling caused due to issue queue being full
      Dis_JmpBrAddr      : out std_logic_vector(31 downto 0); -- the jump or branch address
      Dis_JmpBr          : out std_logic;   -- validating that address to cause a jump or branch
      Dis_JmpBrAddrValid : out std_logic;   -- to tell if the jump or branch address is valid or not.. will be invalid for "jr $rs" inst
    -------------------------------------------------------------------------
    -- Interface with branch prediction buffer
   
      Dis_CdbUpdBranch          : out std_logic; -- indicates that a branch is processed by the cdb and gives the pred(wen to bpb)
      Dis_CdbUpdBranchAddr      : out std_logic_vector(2 downto 0);-- indiactes the least significant 3 bit PC[4:2] of the branch beign processed by cdb
      Dis_CdbBranchOutcome      : out std_logic; -- indiacates the outocome of the branch to the bpb  
    
      Bpb_BranchPrediction      : in std_logic;  -- this bit tells the dispatch what is the prediction based on bpb state-mc
 
      Dis_BpbBranchPCBits       : out std_logic_vector(2 downto 0);-- indiaces the 3 least sig bits of the PC value of the current instr being dis (PC[4:2])
      Dis_BpbBranch             : out std_logic; -- indiactes a branch instr (ren to the bpb)
	
	--------------------------------------------------------------------------------
    -- interface with the cdb  
	  Cdb_Branch              : in std_logic;
      Cdb_BranchOutcome       : in std_logic;
      Cdb_BranchAddr          : in std_logic_vector(31 downto 0);
      Cdb_BrUpdtAddr          : in std_logic_vector(2 downto 0);  
      Cdb_Flush               : in std_logic;
      Cdb_RobTag              : in std_logic_vector(4 downto 0);
    ------------------------------------------------------------------------------
    -- interface with checkpoint module (CFC)
      Dis_CfcRsAddr       :  out std_logic_vector(4 downto 0); -- indicates the Rs Address to be read from Reg file
      Dis_CfcRtAddr       :  out std_logic_vector(4 downto 0); -- indicates the Rt Address to be read from Reg file
   	  Dis_CfcRdAddr       :  out std_logic_vector(4 downto 0); -- indicates the Rd Address to be written by instruction
      -- goes to Dis_CfcRdAddr of ROB too
	  Cfc_RsPhyAddr       : in std_logic_vector(5 downto 0); -- Rs Physical register Tag corresponding to Rs Addr
      Cfc_RtPhyAddr       : in std_logic_vector(5 downto 0); -- Rt Physical register Tag corresponding to Rt Addr
	  Cfc_RdPhyAddr       : in std_logic_vector(5 downto 0); -- Rd Old Physical register Tag corresponding to Rd Addr
	  Cfc_Full            : in std_logic ; -- indicates that all RATs are used and hence we stall in case of branch or Jr $31
      Dis_CfcBranchTag       : out std_logic_vector(4 downto 0) ; -- indicats the rob tag of the branch for which checkpoint is to be done
	  Dis_CfcRegWrite        : out std_logic; -- indicates that the instruction in the dispatch is a register writing instruction and hence should update the active RAT with destination register tag.
	  Dis_CfcNewRdPhyAddr    : out std_logic_vector(5 downto 0);  -- indicates the new physical register to be assigned to Rd for the instruciton in first stage
	  Dis_CfcBranch          : out std_logic;  -- indicates if branch is there in first stage of dispatch... tells cfc to checkpoint 
	  Dis_CfcInstValid       : out std_logic;
    --------------------------------------------------------------------------------
    -- physical register interface
      PhyReg_RsDataRdy        : in std_logic ; -- indicating if the value of Rs is ready at the physical tag location
      PhyReg_RtDataRdy        : in std_logic ; -- indicating if the value of Rt is ready at the physical tag location	  

    
    -- translate_off 
	  Dis_Instruction    : out std_logic_vector(31 downto 0);
    -- translate_on
	
    --------------------------------------------------------------------------------
	-- interface with issue queues 
	  Dis_RegWrite        : out std_logic;      
	  Dis_RsDataRdy       : out std_logic; -- tells the queues that Rs value is ready in PRF and no need to snoop on CDB for that.
      Dis_RtDataRdy       : out std_logic; -- tells the queues that Rt value is ready in PRF and no need to snoop on CDB for that.
      Dis_RsPhyAddr       : out std_logic_vector(5 downto 0); -- tells the physical register mapped to Rs (as given by Cfc)
      Dis_RtPhyAddr       : out std_logic_vector(5 downto 0); -- tells the physical register mapped to Rt (as given by Cfc)
      Dis_RobTag          : out std_logic_vector(4 downto 0);
	  Dis_Opcode          : out std_logic_vector(2 downto 0); -- gives the Opcode of the given instruction for ALU operation
       
	  Dis_IntIssquenable     : out std_logic; -- informs the respective issue queue that the dispatch is going to enter a new entry
      Dis_LdIssquenable      : out std_logic; -- informs the respective issue queue that the dispatch is going to enter a new entry
      Dis_DivIssquenable     : out std_logic; -- informs the respective issue queue that the dispatch is going to enter a new entry
      Dis_MulIssquenable     : out std_logic; -- informs the respective issue queue that the dispatch is going to enter a new entry
      Dis_Immediate          : out std_logic_vector(15 downto 0); -- 15 bit immediate value for lw/sw address calculation and addi instruction
      Issque_IntQueueFull       : in std_logic;
      Issque_LdStQueueFull      : in std_logic;
      Issque_DivQueueFull       : in std_logic;
      Issque_MulQueueFull       : in std_logic;
      Issque_IntQueTwoOrMoreVacant       : in std_logic;  -- indicates that 2 or more slots are available in integer queue
      Issque_LdStQueTwoOrMoreVacant      : in std_logic;
      Issque_DivQueTwoOrMoreVacant       : in std_logic;
      Issque_MulQueTwoOrMoreVacant       : in std_logic;
      	   
	  Dis_BranchOtherAddr : out std_logic_vector(31 downto 0); -- indicates 32 pins for carrying branch other address to be used incase of misprediction.
      Dis_BranchPredict   : out std_logic; -- indicates the prediction given by BPB for branch instruction
      Dis_Branch          : out std_logic;
      Dis_BranchPCBits    : out std_logic_vector(2 downto 0);
      Dis_JrRsInst        : out std_logic;
      Dis_JalInst         : out std_logic ; -- Indicating whether there is a call instruction
	  Dis_Jr31Inst        : out std_logic;
	    
    ----------------------------------------------------------------------------------
    ---- interface with the FRL---- accessed in first sage only so dont need NaerlyEmpty signal from Frl
      Frl_RdPhyAddr       : in std_logic_vector(5 downto 0); -- Physical tag for the next available free register
      Dis_FrlRead         : out std_logic ; -- indicating if free register given by FRL is used or not	  
	  Frl_Empty           : in std_logic; -- indicates that there are no more free physical registers
	   
    ----------------------------------------------------------------------------------
    ---- interface with the RAS
      Dis_RasJalInst      : out std_logic ; -- indicating whether there is a call instruction
	  Dis_RasJr31Inst     : out std_logic;
	  Dis_PcPlusFour      : out std_logic_vector(31 downto 0); -- represents the return address of Jal call instruction
	  Ras_Addr            : in std_logic_vector(31 downto 0);  -- popped RAS address from RAS
	  
    ----------------------------------------------------------------------------------
    ---- interface with the rob
      Dis_PrevPhyAddr   : out std_logic_vector(5 downto 0);  -- indicates old physical register mapped to Rd of the instruction
	  Dis_NewRdPhyAddr  : out std_logic_vector(5 downto 0);  -- indicates new physical register to be assigned to Rd (given by FRL)
	  Dis_RobRdAddr     : out std_logic_vector(4 downto 0);  -- indicates the Rd Address to be written by instruction                                                      -- send to Physical register file too.. so that he can make data ready bit "0"
	  Dis_InstValid     : out std_logic ;
	  Dis_InstSw        : out std_logic ;
	  Dis_SwRtPhyAddr   : out std_logic_vector(5 downto 0);  -- indicates physical register mapped to Rt of the Sw instruction
      Rob_BottomPtr     : in std_logic_vector(4 downto 0);
      Rob_Full          : in std_logic;
      Rob_TwoOrMoreVacant          : in std_logic
      );
  end dispatch_unit;
  
      
architecture behv of dispatch_unit is
    signal Ifetch_Instruction_small :std_logic_vector(5 downto 0);
    signal dispatch_rsaddr,dispatch_rtaddr,dispatch_rdaddr:std_logic_vector(4 downto 0);
    signal sel_que_full ,sel_que_nearly_full: std_logic;
    signal DisJal ,DisJr31 ,DisJrRs,RegWrite , jr_stall :std_logic ;
    signal jr_rob_tag : std_logic_vector(4 downto 0);
    signal StageReg_RdAddr ,Dis_CfcRdAddrTemp : std_logic_vector(4 downto 0);
	signal IntIssquenable ,DivIssquenable,LdIssquenable,MulIssquenable , ren_var : std_logic ;
	signal InstValid , InstSw ,Branch ,BranchPredict: std_logic ;
	signal Opcode , BranchPCBits : std_logic_vector (2 downto 0);
	signal ImmLdSt : std_logic_vector(15 downto 0);
	
	signal StageReg_IntIssquenable ,StageReg_DivIssquenable,StageReg_LdIssquenable,StageReg_MulIssquenable : std_logic ;
	signal StageReg_InstValid, StageReg_InstSw ,StageReg_Branch ,StageReg_RegWrite ,StageReg_BranchPredict: std_logic ;
	signal StageReg_Opcode , StageReg_BranchPCBits : std_logic_vector (2 downto 0);
	signal StageReg_ImmLdSt : std_logic_vector(15 downto 0);
	signal StageReg_BranchOtherAddr , BranchOtherAddr: std_logic_vector(31 downto 0);
	signal StageReg_JrRsInst ,StageReg_Jr31Inst,StageReg_JalInst : std_logic ;
	signal StageReg_NewRdPhyAddr : std_logic_vector(5 downto 0);
    signal StageReg_Instruction  : std_logic_vector(31 downto 0);
    
begin

  ----------------------------------------------------------
  --variable assignments---------------   
         
    Ifetch_Instruction_small <= Ifetch_Instruction(31 downto 26);
    dispatch_rsaddr <=Ifetch_Instruction(25 downto 21);
    dispatch_rtaddr <=Ifetch_Instruction(20 downto 16);
    dispatch_rdaddr <=Ifetch_Instruction(15 downto 11);
         
  ---- process for interactions with IFETCH        
  ifetch_comm : process(Ifetch_Instruction,sel_que_full,Rob_Full,Ifetch_Instruction_small,
                        Cdb_Flush,Ifetch_PcPlusFour,Ifetch_EmptyFlag,Bpb_BranchPrediction,
                        Cdb_BranchAddr,DisJal,DisJr31,DisJrRs,RegWrite, sel_que_nearly_full,Rob_TwoOrMoreVacant,
                        StageReg_InstValid,StageReg_RegWrite, Cfc_Full , Branch,InstValid,
						jr_stall, Frl_Empty, Cdb_RobTag, jr_rob_tag, Ras_Addr
                        )
  variable branch_addr_sign_extended_var ,branch_target_addr:std_logic_vector(31 downto 0);
  variable branch_addr_sign_extended_shifted_var :std_logic_vector(31 downto 0);
  
  begin
  
  ----------------------------------------------------------
  -- Task1: 
  -- 1. Correct the sign-extension operation implemented in the if statement below
  
       if (Ifetch_Instruction(15) = '1') then
             branch_addr_sign_extended_var := X"0000" & Ifetch_Instruction(15 downto 0) ; -- This line is incorrect and you need to modify it
       else
             branch_addr_sign_extended_var := X"FFFF" & Ifetch_Instruction(15 downto 0) ; -- This line is incorrect and you need to modify it 
       end if ;
  
  -- 2. Complete the branch target address calculation  
       branch_addr_sign_extended_shifted_var :=  branch_addr_sign_extended_var(29 downto 0)& "00";
       branch_target_addr := ; -- Complete this statement
	   
  -- End of Task1 
  ----------------------------------------------------------	   
  
  ----------------------------------------------------------
  -- Dis_Ren: In this process we generate the read enable signal of IFQ. When the 1st stage dispatch is stalled for one reason
  -- or IFQ is empty then read enable should be 0 otherwise it going to be 1.
  
  -- Dis_JmpBr: At the same time we generate the Dis_JmpBr signal. This signal is used to flush the IFQ and start fetching instruction 
  -- from other direction in any of the following cases: branch instr in dispatch predicted taken, jump instruction in dispatch,
  -- Flush signal active due to misprediction, or Jr $rs instruction coming out of stall.  
      
  -- Dis_JmpBr has higher priority over Dis_Ren  
      
      -- NOTE : The two or more vacant slot condition of rob is checked with StageReg_InstValid to make sure that instruction in 2nd stage dispatch is a valid instruction 
	  -- The same apply for Frl_empty which is checked with RegWrite signal to make sure that instruction in 1st stage dispatch is a register writing instruction
       if ((sel_que_full= '1')or (sel_que_nearly_full = '1') or (Rob_Full= '1') or
           (Rob_TwoOrMoreVacant = '0' and StageReg_InstValid = '1')or (Ifetch_EmptyFlag = '1') or 
           (jr_stall = '1') or (Frl_Empty = '1' and RegWrite = '1') or (Cfc_Full = '1' and (Branch = '1' or DisJr31 = '1'))) then 
           ren_var <= '0' ;
           Dis_Ren<= '0';
       else
           ren_var <= '1' ;
           Dis_Ren<= '1';
      end if ;
      
      -- Note : Bpb_BranchPrediction is "0" by default . It is "1" only if there is a branch instruction and the prediction is true in the prediction bit table
      -- CONDITIONAL INSTRUCTIONS AND CDBFLUSH IS CHECKED HERE... 
      if ( (((Ifetch_Instruction_small= "000010") or (((DisJal = '1') or (DisJr31 = '1' or DisJrRs = '1')) and InstValid = '1')
         or  (Bpb_BranchPrediction = '1') )and Ifetch_EmptyFlag = '0') or (Cdb_Flush='1') or (jr_stall = '1' and Cdb_RobTag = jr_rob_tag))then -- confirm
         Dis_JmpBr<= '1';
      else
         Dis_JmpBr<= '0';
      end if ;
	  	  
     -- Dis_JmpBrAddrValid: Pin from dispatch to IFetch telling if JR addr is valid...  
     Dis_JmpBrAddrValid <= not (DisJrRs and InstValid) ;  -- in ifetch this pin is checked along with disaptch_jm_br pin..
                                                          -- Thus keeping it "1" as default is harmless..But it should be "0" for "jr $rs" inst
														  
  ----------------------------------------------------------
  -- Task2: Complete the following piece of code to generate the next address from which you need to start fetching
  -- incase Dis_JmpBr is set to 1.
  
  -- Dis_JmpBrAddrValid  
  -- Note : Cdb has the responsibility of generating Cdb_Flush at mispredicted branches and mispredicted "jr $31" instructions
  -- Have to jump when dispatch is waiting for jr $RS once it comes on Cdb
     if (Cdb_Flush= '1' or (jr_stall = '1' and Cdb_RobTag = jr_rob_tag))then -- Cdb_Flush  -- can't avoid as have to give priority to CDB flush over any conditional instruction in dispatch
        Dis_JmpBrAddr<=Cdb_BranchAddr ; 
     else
    -- have to give the default value to avoid latch
        Dis_JmpBrAddr<=Cdb_BranchAddr ; 
		if ((Ifetch_Instruction_small = "000010") or (DisJal = '1')) then -- jump
			Dis_JmpBrAddr <= ; -- Complete this line
        elsif (DisJr31 = '1') then  -- JR $31 .. use address popped from RAS
			Dis_JmpBrAddr <= ; -- Complete this line 
		elsif (Bpb_BranchPrediction = '1' ) then  -- Branch predicted taken
			Dis_JmpBrAddr <= ; -- Complete this line 
		end if ;
	 end if ;
	 
  -- End of Task2
  ----------------------------------------------------------	
end process;

  ----------------------------------------------------------
  -- selective_que_full Process:
  
  -- This process is used to generate the sel_que_full signal which indicates if the desired instruction 
  -- issue queue is full or not. Basically, what we need to do is to investigate the opcode of the instruction
  -- in the dispatch stage and then we check the full bit of the corresponding instr issue queue. If the 
  -- corresponding issue queue is full then we set the sel_que_full bit to '1' otherwise it is set to '0'.  
          
    selective_que_full:process(Ifetch_Instruction_small,Ifetch_Instruction,Issque_IntQueueFull,
                               Issque_DivQueueFull,Issque_MulQueueFull,Issque_LdStQueueFull )
      begin
          if ((( (Ifetch_Instruction_small="000000") and((Ifetch_Instruction(5 downto 0) = "100000") -- add
                                                      or (Ifetch_Instruction(5 downto 0) = "100010") or  -- sub
                                                         (Ifetch_Instruction(5 downto 0) = "100100") or -- and
                                                         (Ifetch_Instruction(5 downto 0) = "100101") or  --or
                                                         (Ifetch_Instruction(5 downto 0) = "101010"))) -- slt
               or ( Ifetch_Instruction_small="001000" ) -- addi
               or ( Ifetch_Instruction_small="000101" ) -- bne
               or ( Ifetch_Instruction_small="000100" ) -- beq 
					     or ( Ifetch_Instruction_small="000011" )  -- jal 
					     or ( Ifetch_Instruction_small="000000" and (Ifetch_Instruction(5 downto 0) = "001000"))) -- jr
					     and Issque_IntQueueFull='1'  -- jr
              ) then
              
              sel_que_full<='1';
          elsif ((Ifetch_Instruction_small="000000") and (Ifetch_Instruction(5 downto 0) = "011011")  -- div
                 and (Issque_DivQueueFull='1')) then
                 
              sel_que_full<='1';
          elsif ((Ifetch_Instruction_small="000000") and (Ifetch_Instruction(5 downto 0) = "011001")  -- mul
                 and (Issque_MulQueueFull = '1' )) then
                 
              sel_que_full<='1';
          elsif (((Ifetch_Instruction_small="100011") or (Ifetch_Instruction_small="101011")) -- load / store
                 and (Issque_LdStQueueFull = '1')) then
                 
               sel_que_full<='1';
          else
          
             sel_que_full<='0';
         end if ;
    end process;

  ----------------------------------------------------------
  -- Task3: Complete the selective_que_nearly_full Process 
  
  -- This process is used to generate the sel_que_nearly_full signal which indicates if the desired instruction 
  -- issue queue has less than 2 vacancies ( 1 or 0) and the instruction in the 2nd dispatch stage is of the same 
  -- type.
  
  -- Hint: This process is very similar to the selective_que_full process.
         
     selective_que_nearly_full:process(Ifetch_Instruction_small,Ifetch_Instruction,Issque_IntQueTwoOrMoreVacant,
                          Issque_DivQueTwoOrMoreVacant,Issque_MulQueTwoOrMoreVacant,Issque_LdStQueTwoOrMoreVacant,
                          StageReg_IntIssquenable, StageReg_DivIssquenable, StageReg_MulIssquenable, StageReg_LdIssquenable -- Added by Vaibhav
								  )
      begin
		-- Add your Code of Task3 here.
        -------------------------------
		-------------------------------
		-------------------------------
      end process;

  -- End of Task3
  ----------------------------------------------------------	 
      
  ----------------------------------------------------------
  -- make_rob_entry Process:
  
  -- The name of the process may cause some confusion. In this process we generate 3 signals:
  -- 1. InstValid signal: This signal indicates if the instruction in the 1st stage dispatch is valid or not. Invalid instructions
  -- include the following:
					-- if the flush signal is active then the instruction in dispatch is flushed
					-- if the instruction is a jump instruction which executes in dispatch and then vanishes.
					-- JR $rs: This is a special case, since we stall the pipeline until JR $rs completes and it appears on Cdb. In 
                    --         we need an RobTag to identify when the instruction comes on Cdb but no Rob entry is needed as the instr
                    --         vanishes after the Cdb and does not enter ROB.					
  -- For Invalid instructions we don't need to assign an ROB entry for that instruction.
  
     make_rob_entry: process(Cdb_Flush, ren_var,dispatch_rsaddr, dispatch_rtaddr , dispatch_rdaddr , Ifetch_Instruction_Small,Ifetch_Instruction)
                         
       begin
          if ( (ren_var = '0') or (Cdb_Flush ='1') or (Ifetch_Instruction_small="000010")or
		  ((Ifetch_Instruction_small="000000") and (Ifetch_Instruction(5 downto 0) = "001000") and (dispatch_rsaddr /= "11111")) )then  
                InstValid<='0';
          else
                InstValid<='1';
          end if; 
		  
  -- 2. InstSw signal: This signal indicates if the instruction in the 1st stage dispatch is a SW instruction.		  
          
          if (Ifetch_Instruction_small="101011") then -- store word
              InstSw <='1';
          else
              InstSw <='0'; 
          end if ;
 
  -- 3. Dis_CfcRdAddrTemp: This signal holds the Rd address of the instruction in dispatch
  ----------------------------------------------------------
  -- Task4: Write an if-statement to generate Dis_CfcRdAddrTemp
  -- Hint: R-type instructions use $rd field, lw and addi use $rt as destination, jal uses $31 as destination.
  
         -- Add your Code of Task4 here.
         -------------------------------
		 -------------------------------
		 ------------------------------- 

  -- End of Task4
  ----------------------------------------------------------			  
		  
	end process ;    
	  
 ----------- Interface with issue queue-------------
 -- This process is used to generate the enable signal for the desired issue queue. This signal acts
 -- as a wen signal to update the desired issue queue. In addition, we generate the 3-bit ALUOpcode used
 -- with r-type, addi, branch and ld/sw instructions.
 
 process (Ifetch_Instruction_small,Ifetch_Instruction , ren_var,Cdb_Flush)
   begin
        DivIssquenable <= '0';
        MulIssquenable <= '0';
        IntIssquenable <= '0';
        LdIssquenable  <= '0' ;
        Opcode  <= "000";                             
     
        if ((ren_var = '0') or (Cdb_Flush ='1') or (Ifetch_Instruction_small="000010")) then -- "000010" jump instruction
			ImmLdSt <= Ifetch_Instruction(15 downto 0);
			-- No entry in any queue is to be made. Queue enables has default value of "0"
          
		else 
			ImmLdSt <= Ifetch_Instruction(15 downto 0);
			case Ifetch_Instruction_small is 
				when "000000" => 
					case Ifetch_Instruction(5 downto 0 ) is 
						when "011011" =>            ----div
							DivIssquenable <= '1';
                                       
						when "011001" =>               ---mul
							MulIssquenable <= '1';
                        
						when "100000" =>            ---- add
							IntIssquenable <= '1';
           
						when "100010" =>            ---sub
							IntIssquenable <= '1';
							Opcode <= "001";
                        
						when "100100" =>            ---and 
							IntIssquenable <= '1';
							Opcode <= "010";
                        
						when "100101" =>               ---or
							IntIssquenable <= '1';
							Opcode <= "011";      
                        
						when "101010" =>               ---slt
							IntIssquenable <= '1';
							Opcode <= "101";
                        
             		    when "001000" =>               ---jr
							IntIssquenable <= '1';
                                    
						when others =>
							Opcode <= "000"; 
							
					end case;
          
				when "001000" =>                       -- addi
					IntIssquenable <= '1';
                    Opcode <= "100";
                        
				when "000011" =>                        -----jal
					IntIssquenable <= '1';
                        			
				when "000100" =>                        -----beq
                    IntIssquenable <= '1';
                    Opcode <= "110";
								
				when "000101" =>                        -- bne
                    IntIssquenable <= '1';
                    Opcode <= "111";
                        
				when "100011" =>                         -- Load
                    LdIssquenable <= '1';
                    Opcode(0)<= '1'; 
                    Opcode(2 downto 1)<= "00"; 
                          
				when "101011" =>                         -- store
                    LdIssquenable <= '1'; 
                    Opcode(0)<= '0'; 
                    Opcode(2 downto 1)<= "00";
								                    
				when others   => 
                    Opcode <= "000";
									  
			end case ;      
		end if;
	end process;  

  --- GENERATING RegWrite signal ------------------------------
  -- Task5: Your task is to generate the RegWrite signal.
  -- Hint1: Why do we need to include the Dis_CfcRdAddrTemp in the sensitivity list !!!
  -- Hint2: For R-type instructions you need to check both opcode and the function field. Jr $rs and 
  -- Jr $31 have the same opcode as R-Type but are not register writing instruction. 
  process (Ifetch_Instruction_small, Ifetch_Instruction , Dis_CfcRdAddrTemp)                                                   
	begin
		-- Add your Code of Task5 here.
        -------------------------------
		-------------------------------
		-------------------------------
  -- End of Task5
  ----------------------------------------------------------	
    end process ;

-- Generating Jal , JrRs and Jr31 signals 
process (Ifetch_Instruction_small, Ifetch_Instruction , dispatch_rsaddr)                                                   
	begin
  
		DisJr31 <= '0';
		DisJrRs <= '0';
		DisJal<= '0';
		if ((Ifetch_Instruction_small = "000000") and (Ifetch_Instruction(5 downto 0 ) = "001000")) then-- jr 
			if (dispatch_rsaddr = "11111") then
				DisJr31 <= '1';
			else
				DisJrRs <= '1';
			end if; 
		elsif ( Ifetch_Instruction_small = "000011") then     
			DisJal<= '1';
		end if;
	end process ;

-- Generating Branch PC bits and Branch signal
bpb_comm_read:process(Ifetch_PcPlusFour,Ifetch_Instruction_small)
	begin
		BranchPCBits <=  (Ifetch_PcPlusFour(4 downto 2) - 1); -- to get PC for instruction
		
		if ((Ifetch_Instruction_small="000100") OR (Ifetch_Instruction_small="000101" )) then -- beq or bne
			Branch <= '1';  -- queues and bpb
		else
			Branch <= '0';
		end if ;
	end process;
   
-- CLOCK PROCESS FOR GENERATING STALL SIGNAL ON JR $RS INSTRUCTION 
-- This is a very important process which takes care of generating the stall signal required in case of Jr $rs
-- instruction. When there is a JR $rs instruction in dispatch, first we set the jr_stall flag which is used to stall 
-- the dispatch stage. At the same time we record the Rob Tag mapped to the JR $rs instruction in a special register.
-- We snoop on the Cdb waiting for that Rob Tag in order to get the value of $rs which represents the jump address. At
-- that moment we can come out from the stall.

-- Note that the Jr $rs disappears after coming out on the Cdb and does not enter the ROB and hence no ROB entry is needed.
-- However, we still need to assign an Rob Tag for the Jr $rs instruction in order to use it for snooping on the Cdb.

-- Task6: The process is almost complete you just need to update the condition of two if statements   
jr_process: process(Clk,Resetb)
	begin
		if (Resetb = '0') then 
			jr_stall <= '0';
			jr_rob_tag <= "00000"; -- can be don't care also
		elsif (Clk'event and Clk = '1') then
			if (Cdb_Flush = '1') then
				jr_stall <= '0' ;
			else
				if (Ifetch_Instruction(5 downto 0 )="001000" and Ifetch_Instruction_small = "000000")then -- if jr
					-- Add the condition for the following if statement.
					-- Hint: Single Condition
					if () then 
						jr_stall <= '1' ;
						if (StageReg_InstValid = '0') then
							jr_rob_tag <= Rob_BottomPtr ;
						else
							jr_rob_tag <= Rob_BottomPtr + 1 ;
						end if;
					end if ;
				end if ; -- end of if jr
				
				-- Complete the condition for the following if statement.
				-- Hint: How do you know when to come out of the JR $rs stall!!	
				if (jr_stall = '1' and ()) then
					jr_stall <= '0';
				end if ;
				        
			end if ;-- if Cdb_Flush
		end if ; -- if Resetb
		
-- End of Task6
----------------------------------------------------------		
		    
	end process ;
		   

       	  
  ----------------------------------------------------------
  -- issue_queue_entry Process:
  
  -- In this process we generate the BranchOtherAddr signal which is used in case of misprediction of branch instruction.  
  issue_queue_entry :process(Ifetch_Instruction,Ifetch_PcPlusFour,Bpb_BranchPrediction,DisJal, DisJr31,Ras_Addr)
  variable branch_addr_sign_extended_var ,branch_target_addr:std_logic_vector(31 downto 0);
  variable branch_addr_sign_extended_shifted_var :std_logic_vector(31 downto 0);
	begin
      
		if (Ifetch_Instruction(15) = '1') then
			branch_addr_sign_extended_var := X"FFFF" & Ifetch_Instruction(15 downto 0) ;
		else
            branch_addr_sign_extended_var := X"0000" & Ifetch_Instruction(15 downto 0) ; 
		end if ;
       
		branch_addr_sign_extended_shifted_var :=  branch_addr_sign_extended_var(29 downto 0)& "00";
		branch_target_addr := branch_addr_sign_extended_shifted_var + Ifetch_PcPlusFour;
     
     --------------------------- NOTE--------------------------------------------------  
       -- Dis_BranchOtherAddr pins carry the following :
       -- a) In case of a branch , we sent the "other address" with branch. By "other address " we mean , the address to be taken in case the branch is mis-predicted
       --    If the branch was predicted to be "not taken" , then we keep on executing the instructions from PC + 4 location only. In case of mis-prediction,
       --    we need to jump to target address calculated , thus we send branch_target_Addr on these pins
       --    If the branch was predicted to be "taken" , then we started executing instructions from "target address". In case of mis-prediction,
       --    we actually need to execute instructions from PC+4 , thus we send PC+4 on the pins
       
       -- b) In case of jr , the pins carry the address given by RAS (valid or invalid). Sending the invlaid address will be harmless. That address is compared with
	   --    the correct address from software stack and a flush signal is initiated in case of mis-match.
	   
	   -- c) In case of jal, the pins carry PC+4 which is stored in register $31.
       -----------------------------------------------------------------------------------------
       
       
        if(Bpb_BranchPrediction = '1' or DisJal = '1') then 
			BranchOtherAddr <= Ifetch_PcPlusFour;
		elsif (DisJr31 = '1') then
		    BranchOtherAddr <= Ras_Addr;
		else
			BranchOtherAddr <= branch_target_addr; -- put jr addr from RAS in case of jr
        end if ;			
      
    end process;
    
    -- PHYSICAL FILE SIGNALS  (From second stage)
		Dis_RsPhyAddr <= Cfc_RsPhyAddr;
		Dis_RtPhyAddr <= Cfc_RtPhyAddr;
	 
	-- BPB SIGNALS... INTERFACE WITH BPB IS FROM FIRST STAGE
		Dis_CdbUpdBranch <= Cdb_Branch;
        Dis_CdbUpdBranchAddr<=Cdb_BrUpdtAddr;
        Dis_CdbBranchOutcome<=Cdb_BranchOutcome; ---outcome bit from rob;
        Dis_BpbBranchPCBits <= BranchPCBits ;
        Dis_BpbBranch <= Branch ;
   
	 
	-- CFC SIGNALS.. INTERFACE WITH CFC IS FROM FIRST STAGE
	  
		Dis_CfcBranchTag <= Rob_BottomPtr when (StageReg_InstValid = '0') else Rob_BottomPtr + 1;
		Dis_CfcRegWrite <= RegWrite and InstValid ;
		Dis_CfcRsAddr <= dispatch_rsaddr ;
		Dis_CfcRtAddr <= dispatch_rtaddr ;
		Dis_CfcRdAddr <= Dis_CfcRdAddrTemp ;
		Dis_CfcBranch <= Branch ;
		Dis_CfcNewRdPhyAddr <= Frl_RdPhyAddr ;
		Dis_CfcInstValid <= InstValid;
    
    -- FRL SIGNALS.. INTERFACE WITH FRL IS FROM FIRST STAGE 
		Dis_FrlRead   <= RegWrite and InstValid;
    
    -- RAS SIGNALS.. INTERFACE WITH RAS IS FROM FIRST STAGE 
		Dis_PcPlusFour <= Ifetch_PcPlusFour ;
		Dis_RasJalInst <= DisJal and InstValid;
		Dis_RasJr31Inst  <= DisJr31 and InstValid;

	-- ISSUEQUE SIGNALS.. INTERFACE WITH ISSUEQUE IS FROM SECOND STAGE 
		-- translate_off 
		Dis_Instruction <= StageReg_Instruction ;
		-- translate_on
		Dis_RsDataRdy <= PhyReg_RsDataRdy ;
		Dis_RtDataRdy <= PhyReg_RtDataRdy ;
		Dis_RobTag  <= Rob_BottomPtr ;
		Dis_Opcode <= StageReg_Opcode;
		Dis_IntIssquenable <= StageReg_IntIssquenable when (Cdb_Flush = '0') else '0';
		Dis_LdIssquenable <= StageReg_LdIssquenable when (Cdb_Flush = '0') else '0';
		Dis_DivIssquenable <= StageReg_DivIssquenable when (Cdb_Flush = '0') else '0';
		Dis_MulIssquenable <= StageReg_MulIssquenable when (Cdb_Flush = '0') else '0';
		Dis_Immediate <= StageReg_ImmLdSt ;
		Dis_BranchOtherAddr <= StageReg_BranchOtherAddr ;
		Dis_BranchPredict <= StageReg_BranchPredict;
		Dis_Branch <= StageReg_Branch ;
		Dis_BranchPCBits <= StageReg_BranchPCBits ;
		Dis_JrRsInst <= StageReg_JrRsInst ;
		Dis_Jr31Inst <= StageReg_Jr31Inst ;
		Dis_JalInst <= StageReg_JalInst ;
	
	  
	-- ROB SIGNALS.. INTERFACE WITH ROB IS FROM SECOND STAGE  
		Dis_PrevPhyAddr <= Cfc_RdPhyAddr ;
		Dis_NewRdPhyAddr <= StageReg_NewRdPhyAddr ;
		Dis_RobRdAddr <= StageReg_RdAddr ;
		Dis_InstValid <= StageReg_InstValid when (Cdb_Flush = '0') else '0';
		Dis_InstSw  <= StageReg_InstSw when (Cdb_Flush = '0') else '0';
		Dis_RegWrite <= StageReg_RegWrite when (Cdb_Flush = '0') else '0';  -- signal for Queues too
		Dis_SwRtPhyAddr <= Cfc_RtPhyAddr;
	  
	 
	-- PROCESS FOR STAGE REGISTER of dispatch
	  process(Clk, Resetb)
	    begin
	      if (Resetb = '0') then
	        StageReg_InstValid <= '0';
	        StageReg_InstSw <= '0';
	        StageReg_RegWrite <= '0';
	        StageReg_IntIssquenable <= '0';
	        StageReg_LdIssquenable <= '0';
	        StageReg_DivIssquenable <= '0';
	        StageReg_MulIssquenable <= '0';
	        StageReg_Branch <= '0';
	        StageReg_JrRsInst <= '0';
	        StageReg_Jr31Inst <= '0';
	        StageReg_JalInst <= '0';
	        
	        
	      elsif (Clk'event and Clk = '1' ) then
	        StageReg_RdAddr <= Dis_CfcRdAddrTemp ;
	        StageReg_InstValid <= InstValid ;
	        StageReg_InstSw <= InstSw ;
	        StageReg_RegWrite <= RegWrite and InstValid;  -- RegWrite , DisJrRs, DisJal and DisJr31 are generated in the process without checking the validity of instruciton . Thus needs to be validated with InstValid signal
	        StageReg_Instruction  <= Ifetch_Instruction ;
	        StageReg_NewRdPhyAddr <= Frl_RdPhyAddr;
	        StageReg_Opcode <= Opcode;
	        StageReg_IntIssquenable <= IntIssquenable ;
	        StageReg_LdIssquenable <= LdIssquenable;
	        StageReg_DivIssquenable <= DivIssquenable;
	        StageReg_MulIssquenable <= MulIssquenable;
	        StageReg_ImmLdSt <= ImmLdSt ;
	        StageReg_BranchOtherAddr <= BranchOtherAddr ;
	        StageReg_BranchPredict <= Bpb_BranchPrediction ;
	        StageReg_Branch <= Branch ;
	        StageReg_BranchPCBits <= BranchPCBits ;
	        StageReg_JrRsInst <= DisJrRs and InstValid;
	        StageReg_Jr31Inst <= DisJr31 and InstValid;
	        StageReg_JalInst <= DisJal and InstValid;
	        
	      end if ;
	    end process; 


end behv ;
