-------------------------------------------------------------------------------
--
-- Design   : Issue Queue
-- Project  : Tomasulo Processor 
-- Author   : Vaibhav Dhotre,Prasanjeet Das
-- Company  : University of Southern California 
-- Updated  : 03/15/2010, 07/13/2010

-- TASK     : Complete the seven TODO sections
-------------------------------------------------------------------------------
--
-- File         : issueque.vhd
-- Version      : 1.0
--
-------------------------------------------------------------------------------
--
-- Description : The issue queue stores instructions and dispatches instructions
--               to the issue block as and when they are ready to be executed 
--               Higher priority is given to instructions which has been in the 
--               queue for the longest time
--               This is the code for the integer issue queue, the codes for 
--               Multiplier queue and divider queue are provided separately
-------------------------------------------------------------------------------

--library declaration
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;

-- Entity declaration
entity issueque is 
port (
      -- Global Clk and dispatch Signals
      Clk                 : in  std_logic ;
      Resetb              : in  std_logic ;

      -- Information to be captured from the Output of LsBuffer
      Lsbuf_PhyAddr       : in  std_logic_vector(5 downto 0) ;
	  Lsbuf_RdWrite       : in  std_logic;
	  Iss_Lsb             : in std_logic;
	  
	    -- Information to be captured from the Write port of Physical Register file
     Cdb_RdPhyAddr       : in  std_logic_vector(5 downto 0) ;
     Cdb_PhyRegWrite     : in  std_logic;


      -- Information from the Dispatch Unit 
     Dis_Issquenable      : in  std_logic ; 
     Dis_RsDataRdy        : in  std_logic ;
     Dis_RtDataRdy        : in  std_logic ;
	 Dis_RegWrite         : in  std_logic;
     Dis_RsPhyAddr        : in  std_logic_vector ( 5 downto 0 ) ;
     Dis_RtPhyAddr        : in  std_logic_vector ( 5 downto 0 ) ;
     Dis_NewRdPhyAddr     : in  std_logic_vector ( 5 downto 0 ) ;
	 Dis_RobTag           : in  std_logic_vector ( 4 downto 0 ) ;
     Dis_Opcode           : in  std_logic_vector ( 2 downto 0 ) ;
	 Dis_Immediate        : in std_logic_vector ( 15 downto 0 );
	 Dis_Branch           : in  std_logic;
	 Dis_BranchPredict    : in  std_logic;
	 Dis_BranchOtherAddr  : in  std_logic_vector ( 31 downto 0 );
	 Dis_BranchPCBits     : in  std_logic_vector ( 2 downto 0 ) ;
     Issque_IntQueueFull  : out std_logic ;
	 Issque_IntQueueTwoOrMoreVacant : out std_logic;
	 Dis_Jr31Inst           : in  std_logic;
	 Dis_JalInst          : in  std_logic;
	 Dis_JrRsInst         : in  std_logic;
	  
	 -- translate_off 
     Dis_instruction    : in std_logic_vector(31 downto 0);
	 -- translate_on
	 
     -- Interface with the Issue Unit
      IssInt_Rdy             : out std_logic ;
	  Iss_Int               : in  std_logic ;
		
	  -- Interface with the Multiply execution unit
	  Mul_RdPhyAddr         : in std_logic_vector(5 downto 0);
	  Mul_ExeRdy            : in std_logic;
	  Div_RdPhyAddr         : in std_logic_vector(5 downto 0);
	  Div_ExeRdy            : in std_logic;
	  
	  -- Interface with the Physical Register File
     Iss_RsPhyAddrAlu         : out std_logic_vector(5 downto 0) ; 
     Iss_RtPhyAddrAlu         : out std_logic_vector(5 downto 0) ; 
     
	  
	  -- Interface with the Execution unit (ALU)
	 Iss_RdPhyAddrAlu         : out std_logic_vector(5 downto 0) ;
	 Iss_RobTagAlu            : out std_logic_vector(4 downto 0);
	 Iss_OpcodeAlu            : out std_logic_vector(2 downto 0) ; --add branch information 
	 Iss_BranchAddrAlu        : out std_logic_vector(31 downto 0);		
     Iss_BranchAlu		      : out std_logic;
	 Iss_RegWriteAlu          : out std_logic;
	 Iss_BranchUptAddrAlu     : out std_logic_vector(2 downto 0);
	 Iss_BranchPredictAlu     : out std_logic;
	 Iss_JalInstAlu           : out std_logic;
	 Iss_JrInstAlu            : out std_logic;
     Iss_JrRsInstAlu          : out std_logic;  
	 Iss_ImmediateAlu         : out std_logic_vector(15 downto 0);
	
   	 -- translate_off 
     Iss_instructionAlu       : out std_logic_vector(31 downto 0);
	 -- translate_on
	 
      --  Interface with ROB 
      Cdb_Flush            : in std_logic;
      Rob_TopPtr           : in std_logic_vector ( 4 downto 0 ) ;
      Cdb_RobDepth         : in std_logic_vector ( 4 downto 0 ) 
     ) ;
end issueque;

-- Architecture 
architecture behav of issueque is
 -- Type declarations
 -- Declarations of Register Array for the Issue Queue and Issue Priority Register
 type array_8_5 is array (0 to 7) of std_logic_vector(4 downto 0) ;   --TAG
 type array_8_6 is array (0 to 7) of std_logic_vector(5 downto 0) ;   --REG
 type array_8_3 is array (0 to 7) of std_logic_vector(2 downto 0) ;  --OPCODE
 type array_8_32 is array(0 to 7) of std_logic_vector(31 downto 0) ;  --BRANCHADDR
 type array_8_16 is array(0 to 7) of std_logic_vector(15 downto 0) ;  --IMMEDIATEADDR
 type array_8_1 is array(0 to 7) of std_logic;  --BRANCHPredict
 
 -- Signals declarations.    
   signal Flush                  : std_logic_vector(7 downto 0); 
   signal En                     : std_logic_vector(7 downto 0); 
   signal OutSelect              : std_logic_vector(2 downto 0);  
   signal OutSelecttemp          : std_logic_vector(7 downto 0);
   signal OutSelectEmpty         : std_logic_vector(7 downto 0);
   signal OutSelectJRrstemp      : std_logic_vector(7 downto 0);
   signal OutSelectJRrs          : std_logic_vector(2 downto 0);
   signal OutSelect_result       : std_logic_vector(2 downto 0);
   signal RtReadyTemp            : std_logic_vector(7 downto 0);
   signal RsReadyTemp            : std_logic_vector(7 downto 0);
   signal IssuedRdPhyAddr        : std_logic_vector(5 downto 0);
	 
   SIGNAL IssuequeBranchPredict  : array_8_1;
   SIGNAL IssuequeJR             : array_8_1;
   SIGNAL IssuequeJRrs           : array_8_1;
   SIGNAL IssuequeJAL            : array_8_1;
   SIGNAL IssuequeBranch         : array_8_1;
   SIGNAL IssuequeRegWrite       : array_8_1;
   SIGNAL IssuequeBranchAddr     : array_8_32;
   -- translate_off
   SIGNAL Issuequeinstruction    : array_8_32;
   -- translate_on
   SIGNAL IssuequeBranchPCBits   : array_8_3;
   SIGNAL IssuequeRsPhyAddrReg   : array_8_6;
   SIGNAL IssuequeRtPhyAddrReg   : array_8_6;
   SIGNAL IssuequeRdPhyAddrReg   : array_8_6;
   SIGNAL IssuequeOpcodeReg      : array_8_3;
   SIGNAL IssuequeRobTag         : array_8_5;
   SIGNAL IssuequeImmediate      : array_8_16;
   
    SIGNAL IssuequeRtReadyReg    : std_logic_vector (7  DOWNTO 0);
    SIGNAL IssuequeRsReadyReg    : std_logic_vector (7  DOWNTO 0);
    SIGNAL IssuequeInstrValReg   : std_logic_vector (7  DOWNTO 0);
    SIGNAL Entemp                : std_logic_vector (7  DOWNTO 0); 
    SIGNAL EnJRrstemp            : std_logic_vector (7  DOWNTO 0);  	
    SIGNAL IssuequeReadyTemp , IssuequefullTemp_Upper, IssuequefullTemp_Lower, UpperHalf_Has_Two_or_More_vacant, LowerHalf_Has_Two_or_More_vacant  : std_logic   ;                                                      
    SIGNAL Buffer0Depth     , Buffer1Depth ,Buffer2Depth ,Buffer3Depth             : std_logic_vector( 4 downto 0 ) ;
    SIGNAL Buffer4Depth     , Buffer5Depth ,Buffer6Depth ,Buffer7Depth             : std_logic_vector( 4 downto 0 ) ;
    SIGNAL IssuedRegWrite        : std_logic;
  
  
 begin 

----------------------Generating Issuque ready -------------------------------------
---DisJAL only Instruction valid.
--###############################################################################################
-- TODO 1: Generate the IssuequeReadyTemp signal which is asserted when
--################################################################################################
--         For anyone of the 8 entries in the issue queue
--         NOTE: where [i] is from 0 to 7
--         The instruction [i] is valid  and 
--             instruction [i] is JAL or (JR with Rs register ready) or (JRrs with Rs register ready) or other int type instructions with both Rs register and Rt register ready                                             
 IssuequeReadyTemp <= --------------------------------------------------------------
 --//JAL on slide 8 of 14
 --//JR and RS ready
 --//RS and RT registers ready (for add, sub, etc instructions) and instruction valid ready
 
 IssInt_Rdy          <= IssuequeReadyTemp ;         
---------- ----------Done Generating issuque Ready --------------------------------
--##################################################################################################



--------------------- Generating Full Condition-------------------------------------
--**********************************************************************************
-- This process generates the issueque full signal :
-- If you are issuing an instruction then the issueque is not full otherwise
-- issueque is full if all the eight entries are valid
--*********************************************************************************** 
--###############################################################################################
-- TODO 2: Generate the Full control signal
--################################################################################################

 process ( IssuequeInstrValReg ,Iss_Int )   --ISSUEBLKDONE FROM ISSUE UNIT telling you that a instruction is issued
       begin
    if ( Iss_Int = '1' ) then 
	
         IssuequefullTemp_Upper <= ----- ;  --Fill in the initial values of these two signals.
         IssuequefullTemp_Lower <= ----- ;	//not(or(check valid bits))
    else
          IssuequefullTemp_Upper <=IssuequeInstrValReg(7) and  IssuequeInstrValReg(6) and  
							   IssuequeInstrValReg(5) and  IssuequeInstrValReg(4);
              							   
	      IssuequefullTemp_Lower <=IssuequeInstrValReg(3) and  IssuequeInstrValReg(2) and  
                               IssuequeInstrValReg(1) and  IssuequeInstrValReg(0) ;
    end if ;
   end process ;

   Issque_IntQueueFull  <=  -- ------------------------------------------; --Complete the right hand side of the expression //full when both upper and lower are full
   
   --##################################################################################################

--------------- Nearly Full Signal ------------------------------
--**********************************************************************************
-- This process generates the issueque Nearly full signal :
-- The nearly full signal is generated for the first stage of dispatch unit for the following case 
-- where both the stages have instructions to be issued in the same queue.
-- 1. Only one slot vacant in issueque: The instruction in first stage cannot be issued by dispatch.
-- 2. Two or more slots vacant in issueque: The instruction in first stage of dispatch finds a slot in issueque.
--***********************************************************************************

--###############################################################################################
-- TODO 3: Generate the Nearly Full control signal
--################################################################################################
   
   UpperHalf_Has_Two_or_More_vacant <=(not(IssuequeInstrValReg(7)) and not(IssuequeInstrValReg(6))) or
                                      (not(IssuequeInstrValReg(7)) and not(IssuequeInstrValReg(5))) or
                                      (not(IssuequeInstrValReg(7)) and not(IssuequeInstrValReg(4))) or
                                      (not(IssuequeInstrValReg(6)) and not(IssuequeInstrValReg(5))) or
                                      (not(IssuequeInstrValReg(6)) and not(IssuequeInstrValReg(4))) or
                                      (not(IssuequeInstrValReg(5)) and not(IssuequeInstrValReg(4))) ;
							   
   LowerHalf_Has_Two_or_More_vacant <= (not(IssuequeInstrValReg(3)) and not(IssuequeInstrValReg(2))) or
                                      (not(IssuequeInstrValReg(3)) and not(IssuequeInstrValReg(1))) or
                                      (not(IssuequeInstrValReg(3)) and not(IssuequeInstrValReg(0))) or
                                      (not(IssuequeInstrValReg(2)) and not(IssuequeInstrValReg(1))) or
                                      (not(IssuequeInstrValReg(2)) and not(IssuequeInstrValReg(0))) or
                                      (not(IssuequeInstrValReg(1)) and not(IssuequeInstrValReg(0))) ;
									  
   Issque_IntQueueTwoOrMoreVacant  <= ---------------------------------------------------------; --complete this statement //OR the upper and lower two vacant, OR one in upper and one in lower
   -- NOTE : Two or more vacant only if 
   --        (a) UpperHalf Has Two or More vacant
   --        (b) LowerHalf Has Two or More vacant
   --        (c) Identify the third case when you need to deal with both the halfs simultaneoulsy
   --            i.e) atleast one  slot vacant in lower half and atleast one slot vacant in upper half

   ------------------ Done Generating Full and Nearly Full Condition -------------------------------  
   --##################################################################################################

   ------------------- Generating OutSelect and En-----------------------------------------
 
 -- issue the instruction if instruction and data are valid
 OUT_SELECT:
 for I in 0 to 7 generate
 
 OutSelecttemp(I) <= (IssuequeInstrValReg(I) and (IssuequeJAL(I) or(IssuequeRsReadyReg(I) and (IssuequeRtReadyReg(I) or IssuequeJR(I) or IssuequeJRrs(I)))))  ; -- this has the priority in being issued
 OutSelectJRrstemp(I) <= (IssuequeInstrValReg(I) and IssuequeRsReadyReg(I) and IssuequeJRrs(I))  ;
 end generate OUT_SELECT;
 
 --***************************************************************************************
 -- This process generates the mux select signal to let the ready instruction to be issued
 -- the priority is given to "0"th entry 
 --****************************************************************************************
 
 process ( OutSelecttemp )   --TO SELECT AMONGST THE 8 ENTRIES
     begin
       if ( OutSelecttemp(0) = '1' ) then        
		   OutSelect <= "000";
       else
        if ( OutSelecttemp(1)  = '1' ) then 
			OutSelect <= "001";
        else
             if ( OutSelecttemp(2) = '1') then 
				 OutSelect <= "010";
             else
				   if ( OutSelecttemp(3) = '1') then 
					   OutSelect <= "011";
                   else
					    if ( OutSelecttemp(4) = '1') then 
							OutSelect <= "100";
                        else
						    if ( OutSelecttemp(5) = '1') then 
								OutSelect <= "101";
                            else
					    	    if ( OutSelecttemp(6) = '1') then 
								   OutSelect <= "110";
                                else
									  OutSelect <= "111";									  
                                end if ; 
                            end if ;  
                        end if;
                    end if ; 
                end if ;  		
             end if;
        end if ;    
         
         
     end process ;
	 
 --***************************************************************************************
 -- This process generates to give priority to JRrs instruction in the issue queue.
 -- the mux select signal to let the ready instruction to be issued
 -- the priority is given to "0"th entry 
 --****************************************************************************************
	 process ( OutSelectJRrstemp )   --TO SELECT AMONGST THE 8 ENTRIES
     begin
       if ( OutSelectJRrstemp(0) = '1' ) then        
		   OutSelectJRrs <= "000";
       else
        if ( OutSelectJRrstemp(1)  = '1' ) then 
			OutSelectJRrs <= "001";
        else
             if ( OutSelectJRrstemp(2) = '1') then 
				 OutSelectJRrs <= "010";
             else
				   if ( OutSelectJRrstemp(3) = '1') then 
					   OutSelectJRrs <= "011";
                   else
						      if ( OutSelectJRrstemp(4) = '1') then 
							OutSelectJRrs <= "100";
                        else
								    if ( OutSelectJRrstemp(5) = '1') then 
								OutSelectJRrs <= "101";
                            else
									   if ( OutSelectJRrstemp(6) = '1') then 
								   OutSelectJRrs <= "110";
                                else
									  OutSelectJRrs <= "111";									  
                                end if ; 
                            end if ;  
                        end if;
                    end if ; 
                end if ;  		
             end if;
        end if ;    
         
         
     end process ;
	 
	 
	process ( OutSelect , Iss_Int ,IssuequeInstrValReg   , Dis_Issquenable )
      begin
          if ( Iss_Int = '1' )  then
          Case ( OutSelect) is
              when "000"    => Entemp <= "11111111" ;  --UPDATE ALL 8 (BECAUSE THE BOTTOMMOST ONE IS GIVEN OUT)
              when "001"    => Entemp <= "11111110" ;  --UPDATE 7 (BECAUSE THE LAST BUT ONE IS GIVEN OUT)
              when "010"    => Entemp <= "11111100" ; 
              when "011"    => Entemp <= "11111000" ;
			  when "100"    => Entemp <= "11110000" ; 
              when "101"    => Entemp <= "11100000" ;  
              when "110"    => Entemp <= "11000000" ; 
              when others   => Entemp <= "10000000" ;
          end case ; 
          else    --WHY THIS CLAUSE   --update till you become valid (YOU ARE NOT ISSUED BUT YOU SHOULD BE UPDATED AS PER INSTRUCTION VALID BIT)
             Entemp(0) <= (not (IssuequeInstrValReg(0) )) ;  --check *===NOTE 1==*, also, remember that you will shift update as soon as an instruction gets ready.
             Entemp(1) <= (not (IssuequeInstrValReg(1) )) or (  not (IssuequeInstrValReg(0)) ) ;
             Entemp(2) <= (not (IssuequeInstrValReg(2) )) or ( not (IssuequeInstrValReg(1) )) or ( not (IssuequeInstrValReg(0) )) ;
             Entemp(3) <= (not (IssuequeInstrValReg(3) )) or (not (IssuequeInstrValReg(2) ) ) or ( not (IssuequeInstrValReg(1) ) ) or ( not (IssuequeInstrValReg(0) ) )  ; --this is where dispatch writes (DISPATCH WRITES TO THE "3rd" ENTRY)
			 Entemp(4) <= (not (IssuequeInstrValReg(4) )) or (not (IssuequeInstrValReg(3) ) ) or (not (IssuequeInstrValReg(2) ) ) or ( not (IssuequeInstrValReg(1) ) ) or ( not (IssuequeInstrValReg(0) ) )  ; 
			 Entemp(5) <= (not (IssuequeInstrValReg(5) )) or (not (IssuequeInstrValReg(4) ) ) or (not (IssuequeInstrValReg(3) ) ) or (not (IssuequeInstrValReg(2) ) ) or ( not (IssuequeInstrValReg(1) ) ) or ( not (IssuequeInstrValReg(0) ) )  ; 
			 Entemp(6) <= (not (IssuequeInstrValReg(6) )) or (not (IssuequeInstrValReg(5) ) )or (not (IssuequeInstrValReg(4) ) ) or (not (IssuequeInstrValReg(3) ) ) or (not (IssuequeInstrValReg(2) )) or ( not (IssuequeInstrValReg(1) ) ) or ( not (IssuequeInstrValReg(0) ) )  ; 
			 Entemp(7) <= Dis_Issquenable or (not (IssuequeInstrValReg(7) )) or (not (IssuequeInstrValReg(6) )) or (not (IssuequeInstrValReg(5) ) )or (not (IssuequeInstrValReg(4) ) ) or (not (IssuequeInstrValReg(3) ) ) or (not (IssuequeInstrValReg(2) )) or ( not (IssuequeInstrValReg(1) ) ) or ( not (IssuequeInstrValReg(0) ) )  ; 
      end if ;                                                                                            
  end process ;  
  
  process ( OutSelectJRrs , Iss_Int ,IssuequeInstrValReg   , Dis_Issquenable )
      begin
          if ( Iss_Int = '1' )  then
          Case ( OutSelectJRrs) is
              when "000"    => EnJRrstemp <= "11111111" ;  --UPDATE ALL 8 (BECAUSE THE BOTTOMMOST ONE IS GIVEN OUT)
              when "001"    => EnJRrstemp <= "11111110" ;  --UPDATE 7 (BECAUSE THE LAST BUT ONE IS GIVEN OUT)
              when "010"    => EnJRrstemp <= "11111100" ; 
              when "011"    => EnJRrstemp <= "11111000" ;
			  when "100"    => EnJRrstemp <= "11110000" ;  
              when "101"    => EnJRrstemp <= "11100000" ;  
              when "110"    => EnJRrstemp <= "11000000" ; 
              when others   => EnJRrstemp <= "10000000" ;
          end case ; 
          else    --WHY THIS CLAUSE   --update till you become valid (YOU ARE NOT ISSUED BUT YOU SHOULD BE UPDATED AS PER INSTRUCTION VALID BIT)
             EnJRrstemp(0) <= (not (IssuequeInstrValReg(0) )) ;  --check *===NOTE 1==*, also, remember that you will shift update as soon as an instruction gets ready.
             EnJRrstemp(1) <= (not (IssuequeInstrValReg(1) )) or (  not (IssuequeInstrValReg(0)) ) ;
             EnJRrstemp(2) <= (not (IssuequeInstrValReg(2) )) or ( not (IssuequeInstrValReg(1) )) or ( not (IssuequeInstrValReg(0) )) ;
             EnJRrstemp(3) <= (not (IssuequeInstrValReg(3) )) or (not (IssuequeInstrValReg(2) ) ) or ( not (IssuequeInstrValReg(1) ) ) or ( not (IssuequeInstrValReg(0) ) )  ; --this is where dispatch writes (DISPATCH WRITES TO THE "3rd" ENTRY)
			 EnJRrstemp(4) <= (not (IssuequeInstrValReg(4) )) or (not (IssuequeInstrValReg(3) ) ) or (not (IssuequeInstrValReg(2) ) ) or ( not (IssuequeInstrValReg(1) ) ) or ( not (IssuequeInstrValReg(0) ) )  ; 
			 EnJRrstemp(5) <= (not (IssuequeInstrValReg(5) )) or (not (IssuequeInstrValReg(4) ) ) or (not (IssuequeInstrValReg(3) ) ) or (not (IssuequeInstrValReg(2) ) ) or ( not (IssuequeInstrValReg(1) ) ) or ( not (IssuequeInstrValReg(0) ) )  ; 
			 EnJRrstemp(6) <= (not (IssuequeInstrValReg(6) )) or (not (IssuequeInstrValReg(5) ) )or (not (IssuequeInstrValReg(4) ) ) or (not (IssuequeInstrValReg(3) ) ) or (not (IssuequeInstrValReg(2) )) or ( not (IssuequeInstrValReg(1) ) ) or ( not (IssuequeInstrValReg(0) ) )  ; 
			 EnJRrstemp(7) <= Dis_Issquenable or (not (IssuequeInstrValReg(7) )) or (not (IssuequeInstrValReg(6) )) or (not (IssuequeInstrValReg(5) ) )or (not (IssuequeInstrValReg(4) ) ) or (not (IssuequeInstrValReg(3) ) ) or (not (IssuequeInstrValReg(2) )) or ( not (IssuequeInstrValReg(1) ) ) or ( not (IssuequeInstrValReg(0) ) )  ; 
      end if ;                                                                                            
  end process ;  
	 
  En <= EnJRrstemp when (OutSelectJRrstemp /= "00000000") else Entemp; -- To given JRrs priority 
  OutSelect_result <= OutSelectJRrs when (OutSelectJRrstemp /= "00000000") else OutSelect; -- To given JRrs priority
------------------------------------Done Generating Enable ------------------------------------------      
   
    ------------------------------- Generating Flush Condition for Queues -----------------
	
--###############################################################################################
-- TODO 4: Calculation of buffer depth to help in selective flushing
--         fill in the eight expressions
--################################################################################################
	
  -- you arrive at the younger instruction to branch by first calcualting its depth using the tag and top pointer of rob
  -- and comparing its depth with depth of branch instruction (known as Cdb_RobDepth)
    Buffer0Depth <=  -------------------------------;  //unsigned mod subtraction (TP - ROBtag?)
    Buffer1Depth <=  -------------------------------;
    Buffer2Depth <=  -------------------------------;
    Buffer3Depth <=  -------------------------------;
	Buffer4Depth <=  -------------------------------;
    Buffer5Depth <=  -------------------------------;
    Buffer6Depth <=  -------------------------------;
    Buffer7Depth <=  -------------------------------;
--################################################################################################	

    
 --***************************************************************************************************************
 -- This process does the selective flushing, if the instruction is younger to branch and there is an intent to flush
 --  Flush the instruction if it is a valid instruction, this is an additional qualification which is unnecessary
 --  We are just flushing the valid instructions and not caring about invalid instructions
--***************************************************************************************************************** 

--###############################################################################################
-- TODO 5: Complete the code on selective flusing
--         fill in the missing expressions
-- NOTE: Remember the queue is from 7 downto 0
--       buffer 7th is at top so dispatch writes to it
--       buffer 0 is at the bottom 
--################################################################################################

 process ( Cdb_Flush , Cdb_RobDepth , Buffer0Depth , Buffer1Depth ,
           Buffer2Depth , Buffer3Depth , Buffer4Depth , Buffer5Depth ,
           Buffer6Depth , Buffer7Depth , En ,IssuequeInstrValReg)
     begin
         Flush <= (others => '0') ;
         if ( Cdb_Flush = '1' ) then
          
              if ( Buffer0Depth > Cdb_RobDepth  ) then  -- WHY THIS CONDITION?? CHECK WETHER THE INSTRUCTION IS AFTER BRANCH OR NOT(i.e, instruction is younger to branch)
                   if ( En(0)  = '0' ) then   -- NOT UPDATING HENCE FLUSH IF INSTRUCTION IS VALID
                    Flush(0) <= IssuequeInstrValReg(0) ;  --just to make sure that flush only valid instruction
                end if ;
         end if ;
         
          if ( Buffer1Depth > Cdb_RobDepth ) then  -- check for younger instructions
             if ( En(0) = '1' ) then 
             Flush(0) <= ---------------------------------------; Hint: Take into account the shift mechanism so is it i or i+1 or i - 1? //if you're shifting, flush the instruction that is 1 ahead
             else
             Flush(1) <= IssuequeInstrValReg(1) ;-- NO UPDATION SO FLUSH(1) IS THE STATUS OF INSTRUCTION (1)
             end if ;
          else
               Flush(1) <= '0' ;
          end if ;
          if ( Buffer2Depth > Cdb_RobDepth  ) then
             if ( En(1) = '1' ) then 
             Flush(1) <= ---------------------------------------;
             else
             Flush(2) <= IssuequeInstrValReg(2) ;
             end if ;
          else
             Flush(2) <= '0' ;
          end if ;
         if ( Buffer3Depth > Cdb_RobDepth  ) then
             if ( En(2) = '1' ) then 
             Flush(2) <= ---------------------------------------;
             else
             Flush(3) <= IssuequeInstrValReg(3) ;
             end if ;
         else
             Flush(3) <= '0' ;
         end if ;
		  if ( Buffer4Depth > Cdb_RobDepth  ) then
             if ( En(3) = '1' ) then 
             Flush(3) <= ---------------------------------------;
             else
             Flush(4) <= IssuequeInstrValReg(4) ;
             end if ;
          else
             Flush(4) <= '0' ;
          end if ;
		  if ( Buffer5Depth > Cdb_RobDepth  ) then
             if ( En(4) = '1' ) then 
             Flush(4) <= ---------------------------------------;
             else
             Flush(5) <= IssuequeInstrValReg(5) ;
             end if ;
          else
             Flush(5) <= '0' ;
          end if ;
		  if ( Buffer6Depth > Cdb_RobDepth  ) then
             if ( En(5) = '1' ) then 
             Flush(5) <= ---------------------------------------;
             else
             Flush(6) <= IssuequeInstrValReg(6) ;
          end if ;
          else
             Flush(6) <= '0' ;
          end if ;
          if ( Buffer7Depth > Cdb_RobDepth  ) then
             if ( En(6) = '1' ) then 
             Flush(6) <= ---------------------------------------;
             else
             Flush(7) <= IssuequeInstrValReg(7) ;
             end if ;
          else
             Flush(7) <= '0' ;
          end if ;
 end if ;
 end process ; 
 
 -------------------- Done Generating Flush Condition ----------------------
 --###############################################################################################
-- TODO 6: fill in the missing values  of the signals  Cdb_PhyRegWrite and IssuedRegWrite the forwarding conditions
-- replace the "-*'" by '1' or '0'
--################################################################################################
  --*****************************************************************************************************************************
  -- This processes does the updation of the various RtReadyTemp entries in the issue queues
  -- If there is a valid instruction in the queue with stale ready signal and cdb_declares result then compare the tag and put into queue
  -- Also check the instruction being issued for ALU Queue, load - store queue, instruction in 3rd stage of Multiplier execution unit
  -- and output of divider execution unit and do the forwarding if necessary.
  -- If En signal indicates shift update then either do self update or shift update accordingly
  -- *****************************************************************************************************************************  
  
 process (  IssuequeRtPhyAddrReg, Cdb_RdPhyAddr, Cdb_PhyRegWrite, Lsbuf_PhyAddr, Lsbuf_RdWrite, Iss_Lsb, IssuequeRegWrite , IssuequeInstrValReg, IssuequeRtReadyReg, En, Mul_RdPhyAddr, Div_RdPhyAddr, IssuedRdPhyAddr, Mul_ExeRdy, Div_ExeRdy, Iss_Int ) 
          begin
               RtReadyTemp <= (others => '0') ;
                  if (( (IssuequeRtPhyAddrReg(0) = Cdb_RdPhyAddr and Cdb_PhyRegWrite =  "-*-") or (IssuequeRtPhyAddrReg(0) = Lsbuf_PhyAddr and Lsbuf_RdWrite = '1' and Iss_Lsb = '1') or (IssuequeRtPhyAddrReg(0) = Mul_RdPhyAddr and Mul_ExeRdy = '1') or (IssuequeRtPhyAddrReg(0) = Div_RdPhyAddr and Div_ExeRdy = '1') or (IssuequeRtPhyAddrReg(0) = IssuedRdPhyAddr and Iss_Int = '1'  and IssuedRegWrite = "-*-")) and IssuequeRtReadyReg(0) ='0' and IssuequeInstrValReg(0) = '1'  ) then 
                     RtReadyTemp(0) <= '1' ;  --UPDATE FROM CDB
				  else
				     RtReadyTemp(0) <=  IssuequeRtReadyReg(0);
                  end if ;
                  
                  if (( (IssuequeRtPhyAddrReg(1) = Cdb_RdPhyAddr and Cdb_PhyRegWrite = "-*-") or (IssuequeRtPhyAddrReg(1) = Lsbuf_PhyAddr and Lsbuf_RdWrite = '1' and Iss_Lsb = '1') or (IssuequeRtPhyAddrReg(1) = Mul_RdPhyAddr and Mul_ExeRdy = '1') or (IssuequeRtPhyAddrReg(1) = Div_RdPhyAddr and Div_ExeRdy = '1') or (IssuequeRtPhyAddrReg(1) = IssuedRdPhyAddr and Iss_Int = '1'  and IssuedRegWrite = "-*-")) and IssuequeRtReadyReg(1) ='0' and IssuequeInstrValReg(1) = '1'  ) then
   
					  if (  En(0) = '1'   ) then
                        RtReadyTemp(0) <= '1' ;  --SHIFT UPDATE
                      else
                        RtReadyTemp(1)  <= '1' ; --buffer1 UPDATES itself ??  *===NOTE 1==* -- enabling the self updation till the invalid instruction becomes valid
                      end if ;
				  else
					  if ( En(0) = '1') then
						 RtReadyTemp(0) <= IssuequeRtReadyReg(1);
					  else
					     RtReadyTemp(1) <= IssuequeRtReadyReg(1);
					  end if;
                  end if ;

                  if (( (IssuequeRtPhyAddrReg(2) = Cdb_RdPhyAddr and Cdb_PhyRegWrite =  "-*-") or (IssuequeRtPhyAddrReg(2) = Lsbuf_PhyAddr and Lsbuf_RdWrite = '1' and Iss_Lsb = '1') or (IssuequeRtPhyAddrReg(2) = Mul_RdPhyAddr and Mul_ExeRdy = '1') or (IssuequeRtPhyAddrReg(2) = Div_RdPhyAddr and Div_ExeRdy = '1') or (IssuequeRtPhyAddrReg(2) = IssuedRdPhyAddr and Iss_Int = '1'  and IssuedRegWrite = "-*-")) and IssuequeRtReadyReg(2) ='0' and IssuequeInstrValReg(2) = '1'  ) then
                       
					  if (  En(1) = '1'   ) then
                        RtReadyTemp(1) <= '1' ;  --SHIFT UPDATE
                      else
                        RtReadyTemp(2)  <= '1' ; --buffer1 UPDATES itself ??  *===NOTE 1==* -- enabling the self updation till the invalid instruction becomes valid
                      end if ;
				  else
				      if ( En(1) = '1') then
						 RtReadyTemp(1) <= IssuequeRtReadyReg(2);
					  else
						 RtReadyTemp(2) <= IssuequeRtReadyReg(2);
					  end if;
                  end if ;
						  
					if (( (IssuequeRtPhyAddrReg(3) = Cdb_RdPhyAddr and Cdb_PhyRegWrite =  "-*-") or (IssuequeRtPhyAddrReg(3) = Lsbuf_PhyAddr and Lsbuf_RdWrite = '1' and Iss_Lsb = '1') or (IssuequeRtPhyAddrReg(3) = Mul_RdPhyAddr and Mul_ExeRdy = '1') or (IssuequeRtPhyAddrReg(3) = Div_RdPhyAddr and Div_ExeRdy = '1') or (IssuequeRtPhyAddrReg(3) = IssuedRdPhyAddr and Iss_Int = '1'  and IssuedRegWrite = "-*-")) and IssuequeRtReadyReg(3) ='0' and IssuequeInstrValReg(3) = '1'  ) then
                       
			    	  if (  En(2) = '1'   ) then
                         RtReadyTemp(2) <= '1' ;  --SHIFT UPDATE
                      else
                         RtReadyTemp(3)  <= '1' ; --buffer1 UPDATES itself ??  *===NOTE 1==* -- enabling the self updation till the invalid instruction becomes valid
                      end if ;
					else
				      if ( En(2) = '1') then
					     RtReadyTemp(2) <= IssuequeRtReadyReg(3);
					  else
		     			 RtReadyTemp(3) <= IssuequeRtReadyReg(3);
					  end if;
                    end if ;
						 
                  if (( (IssuequeRtPhyAddrReg(4) = Cdb_RdPhyAddr and Cdb_PhyRegWrite =  "-*-") or (IssuequeRtPhyAddrReg(4) = Lsbuf_PhyAddr and Lsbuf_RdWrite = '1' and Iss_Lsb = '1') or (IssuequeRtPhyAddrReg(4) = Mul_RdPhyAddr and Mul_ExeRdy = '1') or (IssuequeRtPhyAddrReg(4) = Div_RdPhyAddr and Div_ExeRdy = '1') or (IssuequeRtPhyAddrReg(4) = IssuedRdPhyAddr and Iss_Int = '1'   and IssuedRegWrite = "-*-")) and IssuequeRtReadyReg(4) ='0' and IssuequeInstrValReg(4) = '1'  ) then
				  
					  if (  En(3) = '1'   ) then
                         RtReadyTemp(3) <= '1' ;  --SHIFT UPDATE
                      else
                         RtReadyTemp(4)  <= '1' ; --buffer1 UPDATES itself ??  *===NOTE 1==* -- enabling the self updation till the invalid instruction becomes valid
                      end if ;
				  else
				      if ( En(3) = '1') then
						  RtReadyTemp(3) <= IssuequeRtReadyReg(4);
					  else
						  RtReadyTemp(4) <= IssuequeRtReadyReg(4);
					  end if;
                  end if ;

                  if (( (IssuequeRtPhyAddrReg(5) = Cdb_RdPhyAddr and Cdb_PhyRegWrite =  "-*-") or (IssuequeRtPhyAddrReg(5) = Lsbuf_PhyAddr and Lsbuf_RdWrite = '1' and Iss_Lsb = '1') or (IssuequeRtPhyAddrReg(5) = Mul_RdPhyAddr and Mul_ExeRdy = '1') or (IssuequeRtPhyAddrReg(5) = Div_RdPhyAddr and Div_ExeRdy = '1') or (IssuequeRtPhyAddrReg(5) = IssuedRdPhyAddr and Iss_Int = '1'   and IssuedRegWrite = "-*-")) and IssuequeRtReadyReg(5) ='0' and IssuequeInstrValReg(5) = '1'  ) then
				  
				      if (  En(4) = '1'   ) then
                        RtReadyTemp(4) <= '1' ;  --SHIFT UPDATE
                      else
                       RtReadyTemp(5)  <= '1' ; --buffer1 UPDATES itself ??  *===NOTE 1==* -- enabling the self updation till the invalid instruction becomes valid
                      end if ;
				  else
					  if ( En(4) = '1') then
						 RtReadyTemp(4) <= IssuequeRtReadyReg(5);
					  else
				    	 RtReadyTemp(5) <= IssuequeRtReadyReg(5);
					  end if;
                  end if ;

                  if (( (IssuequeRtPhyAddrReg(6) = Cdb_RdPhyAddr and Cdb_PhyRegWrite =  "-*-") or (IssuequeRtPhyAddrReg(6) = Lsbuf_PhyAddr and Lsbuf_RdWrite = '1' and Iss_Lsb = '1') or (IssuequeRtPhyAddrReg(6) = Mul_RdPhyAddr and Mul_ExeRdy = '1') or (IssuequeRtPhyAddrReg(6) = Div_RdPhyAddr and Div_ExeRdy = '1') or (IssuequeRtPhyAddrReg(6) = IssuedRdPhyAddr and Iss_Int = '1'  and IssuedRegWrite = "-*-")) and IssuequeRtReadyReg(6) ='0' and IssuequeInstrValReg(6) = '1'  ) then
				  
				   if (  En(5) = '1'   ) then
                        RtReadyTemp(5) <= '1' ;  --SHIFT UPDATE
                   else
                        RtReadyTemp(6)  <= '1' ; --buffer1 UPDATES itself ??  *===NOTE 1==* -- enabling the self updation till the invalid instruction becomes valid
                   end if ;
				  else
				   if ( En(5) = '1') then
					  RtReadyTemp(5) <= IssuequeRtReadyReg(6);
				   else
					  RtReadyTemp(6) <= IssuequeRtReadyReg(6);
				   end if;
                 end if ;

                if (( (IssuequeRtPhyAddrReg(7) = Cdb_RdPhyAddr and Cdb_PhyRegWrite =  "-*-") or (IssuequeRtPhyAddrReg(7) = Lsbuf_PhyAddr and Lsbuf_RdWrite = '1' and Iss_Lsb = '1') or (IssuequeRtPhyAddrReg(7) = Mul_RdPhyAddr and Mul_ExeRdy = '1') or (IssuequeRtPhyAddrReg(7) = Div_RdPhyAddr and Div_ExeRdy = '1') or (IssuequeRtPhyAddrReg(7) = IssuedRdPhyAddr and Iss_Int = '1'  and IssuedRegWrite = "-*-")) and IssuequeRtReadyReg(7) ='0' and IssuequeInstrValReg(7) = '1'  ) then
				  
				  if (  En(6) = '1'   ) then
                        RtReadyTemp(6) <= '1' ;  --SHIFT UPDATE
                  else
                        RtReadyTemp(7)  <= '1' ; --buffer1 UPDATES itself ??  *===NOTE 1==* -- enabling the self updation till the invalid instruction becomes valid
                  end if ;
   			    else
				  if ( En(6) = '1') then
				        RtReadyTemp(6) <= IssuequeRtReadyReg(7);
				  else
					    RtReadyTemp(7) <= IssuequeRtReadyReg(7);
				  end if;
                end if ;
						  
          end process ;
		  
--###############################################################################################
           
  

--###############################################################################################
-- TODO 7: fill in the missing values  of the signals  Cdb_PhyRegWrite and IssuedRegWrite the forwarding conditions
-- replace the "-*'" by '1' or '0'
--################################################################################################
  
   
--*****************************************************************************************************************************
  -- This processes does the updation of the various RsReadyTemp entries in the issue queues
  -- If there is a valid instruction in the queue with stale ready signal and cdb_declares result then compare the tag and put into queue
  -- Also check the instruction begin issued for load - store queue, ALU queue, instruction in 3rd stage of Multiplier execution unit
  -- and output of divider execution unit.
  -- If En signal indicates shift update then either do self update or shift update accordingly
  -- *****************************************************************************************************************************  
   process (IssuequeRsPhyAddrReg,  Cdb_RdPhyAddr, Cdb_PhyRegWrite, Lsbuf_PhyAddr, Iss_Lsb, Lsbuf_RdWrite,IssuequeInstrValReg, IssuequeRsReadyReg, En, Mul_RdPhyAddr, Div_RdPhyAddr, IssuedRdPhyAddr, Mul_ExeRdy, Div_ExeRdy, Iss_Int ) 
          begin
               RsReadyTemp <= (others => '0');
                  if (( (IssuequeRsPhyAddrReg(0) = Cdb_RdPhyAddr and Cdb_PhyRegWrite =  "-*-") or (IssuequeRsPhyAddrReg(0) = Lsbuf_PhyAddr and Lsbuf_RdWrite = '1' and Iss_Lsb = '1') or (IssuequeRsPhyAddrReg(0) = Mul_RdPhyAddr and Mul_ExeRdy = '1') or (IssuequeRsPhyAddrReg(0) = Div_RdPhyAddr and Div_ExeRdy = '1') or (IssuequeRsPhyAddrReg(0) = IssuedRdPhyAddr and Iss_Int = '1'  and IssuedRegWrite = "-*-")) and IssuequeRsReadyReg(0) ='0'and IssuequeInstrValReg(0) = '1'  ) then
							 
                       RsReadyTemp(0) <= '1' ;  --UPDATE FROM CDB
						else
						     RsReadyTemp(0) <=  IssuequeRsReadyReg(0);
                  end if ;
                  
                   if (( (IssuequeRsPhyAddrReg(1) = Cdb_RdPhyAddr and Cdb_PhyRegWrite =  "-*-") or (IssuequeRsPhyAddrReg(1) = Lsbuf_PhyAddr and Lsbuf_RdWrite = '1' and Iss_Lsb = '1') or (IssuequeRsPhyAddrReg(1) = Mul_RdPhyAddr and Mul_ExeRdy = '1') or (IssuequeRsPhyAddrReg(1) = Div_RdPhyAddr and Div_ExeRdy = '1') or (IssuequeRsPhyAddrReg(1) = IssuedRdPhyAddr and Iss_Int = '1'  and IssuedRegWrite = "-*-")) and IssuequeRsReadyReg(1) ='0'and IssuequeInstrValReg(1) = '1'  ) then
							 
							  if (  En(0) = '1'   ) then
                        RsReadyTemp(0) <= '1' ;  --SHIFT UPDATE
                       else
                        RsReadyTemp(1)  <= '1' ; --buffer1 UPDATES itself ??  *===NOTE 1==* -- enabling the self updation till the invalid instruction becomes valid
                       end if ;
						 else
						     if ( En(0) = '1') then
							  RsReadyTemp(0) <= IssuequeRsReadyReg(1);
							  else
							  RsReadyTemp(1) <= IssuequeRsReadyReg(1);
							  end if;
                    end if ;

                  if (((IssuequeRsPhyAddrReg(2) = Cdb_RdPhyAddr and Cdb_PhyRegWrite =  "-*-") or  (IssuequeRsPhyAddrReg(2) = Lsbuf_PhyAddr and Lsbuf_RdWrite = '1' and Iss_Lsb = '1') or (IssuequeRsPhyAddrReg(2) = Mul_RdPhyAddr and Mul_ExeRdy = '1') or (IssuequeRsPhyAddrReg(2) = Div_RdPhyAddr and Div_ExeRdy = '1') or (IssuequeRsPhyAddrReg(2) = IssuedRdPhyAddr and Iss_Int = '1'  and IssuedRegWrite = "-*-")) and IssuequeRsReadyReg(2) ='0'and IssuequeInstrValReg(2) = '1'  ) then
							 
							  if (  En(1) = '1'   ) then
                        RsReadyTemp(1) <= '1' ;  --SHIFT UPDATE
                       else
                        RsReadyTemp(2)  <= '1' ; --buffer1 UPDATES itself ??  *===NOTE 1==* -- enabling the self updation till the invalid instruction becomes valid
                       end if ;
						else
						     if ( En(1) = '1') then
							  RsReadyTemp(1) <= IssuequeRsReadyReg(2);
							  else
							  RsReadyTemp(2) <= IssuequeRsReadyReg(2);
							  end if;
                    end if ;
						  
				  if (((IssuequeRsPhyAddrReg(3) = Cdb_RdPhyAddr and Cdb_PhyRegWrite =  "-*-") or  (IssuequeRsPhyAddrReg(3) = Lsbuf_PhyAddr and Lsbuf_RdWrite = '1' and Iss_Lsb = '1') or (IssuequeRsPhyAddrReg(3) = Mul_RdPhyAddr and Mul_ExeRdy = '1') or (IssuequeRsPhyAddrReg(3) = Div_RdPhyAddr and Div_ExeRdy = '1') or (IssuequeRsPhyAddrReg(3) = IssuedRdPhyAddr and Iss_Int = '1'  and IssuedRegWrite = "-*-")) and IssuequeRsReadyReg(3) ='0'and IssuequeInstrValReg(3) = '1'  ) then
							 
							  if (  En(2) = '1'   ) then
                        RsReadyTemp(2) <= '1' ;  --SHIFT UPDATE
                       else
                        RsReadyTemp(3)  <= '1' ; --buffer1 UPDATES itself ??  *===NOTE 1==* -- enabling the self updation till the invalid instruction becomes valid
                       end if ;
							  else
						     if ( En(2) = '1') then
							  RsReadyTemp(2) <= IssuequeRsReadyReg(3);
							  else
							  RsReadyTemp(3) <= IssuequeRsReadyReg(3);
							  end if;
                    end if ;
						 
                  if (( (IssuequeRsPhyAddrReg(4) = Cdb_RdPhyAddr and Cdb_PhyRegWrite =  "-*-") or(IssuequeRsPhyAddrReg(4) = Lsbuf_PhyAddr and Lsbuf_RdWrite = '1' and Iss_Lsb = '1') or (IssuequeRsPhyAddrReg(4) = Mul_RdPhyAddr and Mul_ExeRdy = '1') or (IssuequeRsPhyAddrReg(4) = Div_RdPhyAddr and Div_ExeRdy = '1') or (IssuequeRsPhyAddrReg(4) = IssuedRdPhyAddr and Iss_Int = '1'  and IssuedRegWrite = "-*-")) and IssuequeRsReadyReg(4) ='0'and IssuequeInstrValReg(4) = '1'  ) then
							 
							  if (  En(3) = '1'   ) then
                        RsReadyTemp(3) <= '1' ;  --SHIFT UPDATE
                       else
                        RsReadyTemp(4)  <= '1' ; --buffer1 UPDATES itself ??  *===NOTE 1==* -- enabling the self updation till the invalid instruction becomes valid
                       end if ;
							  else
						     if ( En(3) = '1') then
							  RsReadyTemp(3) <= IssuequeRsReadyReg(4);
							  else
							  RsReadyTemp(4) <= IssuequeRsReadyReg(4);
							  end if;
                    end if ;

                  if (( (IssuequeRsPhyAddrReg(5) = Cdb_RdPhyAddr and Cdb_PhyRegWrite =  "-*-") or (IssuequeRsPhyAddrReg(5) = Lsbuf_PhyAddr and Lsbuf_RdWrite = '1' and Iss_Lsb = '1') or (IssuequeRsPhyAddrReg(5) = Mul_RdPhyAddr and Mul_ExeRdy = '1') or (IssuequeRsPhyAddrReg(5) = Div_RdPhyAddr and Div_ExeRdy = '1') or (IssuequeRsPhyAddrReg(5) = IssuedRdPhyAddr and Iss_Int = '1'  and IssuedRegWrite = "-*-")) and IssuequeRsReadyReg(5) ='0'and IssuequeInstrValReg(5) = '1'  ) then
							 
							  if (  En(4) = '1'   ) then
                        RsReadyTemp(4) <= '1' ;  --SHIFT UPDATE
                       else
                        RsReadyTemp(5)  <= '1' ; --buffer1 UPDATES itself ??  *===NOTE 1==* -- enabling the self updation till the invalid instruction becomes valid
                       end if ;
							  else
						     if ( En(4) = '1') then
							  RsReadyTemp(4) <= IssuequeRsReadyReg(5);
							  else
							  RsReadyTemp(5) <= IssuequeRsReadyReg(5);
							  end if;
                    end if ;

                  if (( (IssuequeRsPhyAddrReg(6) = Cdb_RdPhyAddr and Cdb_PhyRegWrite =  "-*-") or (IssuequeRsPhyAddrReg(6) = Lsbuf_PhyAddr and Lsbuf_RdWrite = '1' and Iss_Lsb = '1') or (IssuequeRsPhyAddrReg(6) = Mul_RdPhyAddr and Mul_ExeRdy = '1') or (IssuequeRsPhyAddrReg(6) = Div_RdPhyAddr and Div_ExeRdy = '1') or (IssuequeRsPhyAddrReg(6) = IssuedRdPhyAddr and Iss_Int = '1'  and IssuedRegWrite = "-*-")) and IssuequeRsReadyReg(6) ='0'and IssuequeInstrValReg(6) = '1'  ) then
							 
							  if (  En(5) = '1'   ) then
                        RsReadyTemp(5) <= '1' ;  --SHIFT UPDATE
                       else
                        RsReadyTemp(6)  <= '1' ; --buffer1 UPDATES itself ??  *===NOTE 1==* -- enabling the self updation till the invalid instruction becomes valid
                       end if ;
							  else
						     if ( En(5) = '1') then
							  RsReadyTemp(5) <= IssuequeRsReadyReg(6);
							  else
							  RsReadyTemp(6) <= IssuequeRsReadyReg(6);
							  end if;
                    end if ;

                  if (( (IssuequeRsPhyAddrReg(7) = Cdb_RdPhyAddr and Cdb_PhyRegWrite =  "-*-") or (IssuequeRsPhyAddrReg(7) = Lsbuf_PhyAddr and Lsbuf_RdWrite = '1' and Iss_Lsb = '1') or (IssuequeRsPhyAddrReg(7) = Mul_RdPhyAddr and Mul_ExeRdy = '1') or (IssuequeRsPhyAddrReg(7) = Div_RdPhyAddr and Div_ExeRdy = '1') or (IssuequeRsPhyAddrReg(7) = IssuedRdPhyAddr and Iss_Int = '1' and IssuedRegWrite = "-*-")) and IssuequeRsReadyReg(7) ='0'and IssuequeInstrValReg(7) = '1'  ) then
							 
							  if (  En(6) = '1'   ) then
                        RsReadyTemp(6) <= '1' ;  --SHIFT UPDATE
                       else
                        RsReadyTemp(7)  <= '1' ; --buffer1 UPDATES itself ??  *===NOTE 1==* -- enabling the self updation till the invalid instruction becomes valid
                       end if ;
							  else
						     if ( En(6) = '1') then
							  RsReadyTemp(6) <= IssuequeRsReadyReg(7);
							  else
							  RsReadyTemp(7) <= IssuequeRsReadyReg(7);
							  end if;
                    end if ;
						  
          end process ;
           
  
--###############################################################################################         
   
 ----------------------------------------------------------------------------------------------------
 
 ---------------------------------                                     ------------------------------
               process ( clk , Resetb )
                   begin
                       if ( Resetb = '0' ) then
                        IssuequeInstrValReg <= (others => '0') ;		
                        IssuequeRsReadyReg <= (others => '0');
                        IssuequeRtReadyReg <= (others => '0');
                        IssuequeJR <= (others => '0');
                        IssuequeJRrs <= (others => '0');
                        IssuequeJAL <= (others => '0');
                       elsif ( Clk'event and Clk = '1' ) then
                        IssuequeRsReadyReg <= RsReadyTemp;		
                        IssuequeRtReadyReg <= RtReadyTemp;		
                      -- end if;					   
                        for I in 6 downto 0 loop
								if ( Flush(I) = '1' ) then    
                           IssuequeInstrValReg(I) <= '0' ;
						    -- translate_off 
						   Issuequeinstruction(I) <= (others => '0') ;
						    -- translate_on
                         else   
                         if ( En(I) = '1' ) then  --update
                        	   IssuequeInstrValReg(I)   <= IssuequeInstrValReg(I + 1) ; 
							   IssuequeRsPhyAddrReg(I)  <= IssuequeRsPhyAddrReg(I + 1);
							   IssuequeRdPhyAddrReg(I)  <= IssuequeRdPhyAddrReg(I + 1);
							   IssuequeRtPhyAddrReg(I)  <= IssuequeRtPhyAddrReg(I + 1);
							   IssuequeRobTag(I)        <= IssuequeRobTag(I + 1);
							   IssuequeRegWrite(I)      <= IssuequeRegWrite(I + 1);
							   IssuequeOpcodeReg(I)     <= IssuequeOpcodeReg(I + 1);   
							   IssuequeBranchPredict(I) <= IssuequeBranchPredict(I + 1);
							   IssuequeBranch(I)        <= IssuequeBranch(I + 1);
                               IssuequeBranchAddr(I)    <= IssuequeBranchAddr(I + 1);
	                           IssuequeBranchPCBits(I)  <= IssuequeBranchPCBits(I + 1);
							   IssuequeJR(I)            <= IssuequeJR(I + 1);
							   IssuequeJRrs(I)          <= IssuequeJRrs(I + 1);
							   IssuequeJAL(I)           <= IssuequeJAL(I + 1);		
							   IssuequeImmediate(I)     <= IssuequeImmediate(I + 1);		
							    -- translate_off 
                               Issuequeinstruction(I)   <= Issuequeinstruction(I + 1);							   
							    -- translate_on
                         else
						 ---If can be removed ---
							   IssuequeInstrValReg(I)   <= IssuequeInstrValReg(I) ; 
                         end if ;
                        end if ;
								end loop;
                        
                         if ( Flush(7) = '1' ) then
                            IssuequeInstrValReg(7) <= '0' ;
							 -- translate_off 
							Issuequeinstruction(7) <= (others => '0') ;
							 -- translate_on
                          else   
                          if ( En(7) = '1' ) then 
								   IssuequeInstrValReg(7)   <= Dis_Issquenable;
								   IssuequeRdPhyAddrReg(7)  <= Dis_NewRdPhyAddr ;
                                   IssuequeOpcodeReg(7)     <= Dis_Opcode ;
								   IssuequeRobTag(7)        <= Dis_RobTag;
								   IssuequeRegWrite(7)      <= Dis_RegWrite;
                                   IssuequeRtPhyAddrReg(7)  <= Dis_RtPhyAddr ;
                                   IssuequeRsPhyAddrReg(7)  <= Dis_RsPhyAddr ;
								   IssuequeBranchPredict(7) <= Dis_BranchPredict;
								   IssuequeBranch(7)        <= Dis_Branch;
                                   IssuequeBranchAddr(7)    <= Dis_BranchOtherAddr;
	                               IssuequeBranchPCBits(7)  <= Dis_BranchPCBits;
								   IssuequeRsReadyReg(7)    <= Dis_RsDataRdy;
                                   IssuequeRtReadyReg(7)    <= Dis_RtDataRdy;	
								   IssuequeJR(7)            <= Dis_Jr31Inst;
								   IssuequeJRrs(7)          <= Dis_JrRsInst;
								   IssuequeJAL(7)           <= Dis_JalInst;
								   IssuequeImmediate(7)     <= Dis_Immediate;
								    -- translate_off 
								   Issuequeinstruction(7)   <= Dis_instruction;
								    -- translate_on

                            else
                            IssuequeInstrValReg(7) <= IssuequeInstrValReg(7) ; 
                         end if ;
                         end if ;                 
                       end if ;                      
                       
                       
               end process ;    
               
  --- Selecting the Output to Go to Execution Unit, Physical Register Filed, Issue Unit          
   
             Iss_RsPhyAddrAlu     <=  IssuequeRsPhyAddrReg(CONV_INTEGER (unsigned( OutSelect_result))) ;
             Iss_RtPhyAddrAlu     <=  IssuequeRtPhyAddrReg (CONV_INTEGER(unsigned( OutSelect_result))) ;
             IssuedRdPhyAddr      <=  IssuequeRdPhyAddrReg(CONV_INTEGER(unsigned( OutSelect_result))) ; 
             IssuedRegWrite <= IssuequeRegWrite(CONV_INTEGER(unsigned( OutSelect_result)));
			 Iss_RdPhyAddrAlu     <=  IssuedRdPhyAddr;
             Iss_OpcodeAlu        <=  IssuequeOpcodeReg(CONV_INTEGER(unsigned( OutSelect_result))) ;
		     Iss_RobTagAlu        <=  IssuequeRobTag(CONV_INTEGER(unsigned( OutSelect_result)));
			 Iss_RegWriteAlu      <=  IssuequeRegWrite(CONV_INTEGER(unsigned( OutSelect_result)));
			 Iss_BranchPredictAlu <=  IssuequeBranchPredict(CONV_INTEGER(unsigned( OutSelect_result)));
	         Iss_BranchAlu        <=  IssuequeBranch(CONV_INTEGER(unsigned( OutSelect_result)));
             Iss_BranchAddrAlu    <=  IssuequeBranchAddr(CONV_INTEGER(unsigned( OutSelect_result)));
	         Iss_BranchUptAddrAlu <=  IssuequeBranchPCBits(CONV_INTEGER(unsigned( OutSelect_result)));
			 Iss_JrInstAlu        <=  IssuequeJR(CONV_INTEGER(unsigned( OutSelect_result)));
		     Iss_JalInstAlu       <=  IssuequeJAL(CONV_INTEGER(unsigned( OutSelect_result)));
			 Iss_JrRsInstAlu      <=  IssuequeJrRs(CONV_INTEGER(unsigned( OutSelect_result)));
			 Iss_ImmediateAlu     <=  IssuequeImmediate(CONV_INTEGER(unsigned( OutSelect_result)));
			  -- translate_off 
			 Iss_instructionAlu   <=  Issuequeinstruction(CONV_INTEGER(unsigned( OutSelect_result)));
			  -- translate_on
				 
                  
                            
 
   
 end behav ;
   
