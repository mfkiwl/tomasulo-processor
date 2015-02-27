-- CHECKED AND MODIFIED BY PRASANJEET
-------------------------------------------
--UPDATED ON: 7/9/09, 7/13/10


-- TASK     : Complete the four TODO sections

-------------------------------------------
-------------------------------------------------------------------------------
--
-- Design   : Load/Store Issue Cntrl
-- Project  : Tomasulo Processor 
-- Author   : Rohit Goel 
-- ComOppany  : University of Southern California 
--
-------------------------------------------------------------------------------
--
-- File         : Lsqcntrl.vhd
-- Version      : 1.0
--
-------------------------------------------------------------------------------
--
-- Description : The Issue control controls the Issuque 
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;

-- Entity declaration


entity Lsquectrl is 
port (
-- Global Clk and Resetb Signals
Clk                  : in  std_logic ;
Resetb                : in  std_logic ;

-- cdb interface
Cdb_RdPhyAddr         : in  std_logic_vector(5 downto 0) ;
Cdb_PhyRegWrite       : in  std_logic;
Cdb_Valid             : in  std_logic ;

-- lsq interface
Opcode                : in  std_logic_vector(7 downto 0); 
AddrReadyBit          : in  std_logic_vector(7 downto 0); 
AddrUpdate            : out std_logic_vector(7 downto 0); 
AddrUpdateSel         : out std_logic_vector(7 downto 0); 

-- ROB Interface
Cdb_Flush            : in std_logic ;
Rob_TopPtr           : in std_logic_vector (4 downto 0 ) ;
Cdb_RobDepth         : in std_logic_vector (4 downto 0 ) ;

-- Dispatch / issue unit interface
Dis_LdIssquenable            : in  std_logic ; 
Iss_LdStIssued                 : in  std_logic ;
DCE_ReadBusy                      : in std_logic;
Lsbuf_Done                 : in std_logic;
-- shift register inputs
InstructionValidBit   : in  std_logic_vector(7 downto 0); -- '1' indicates instruction is valid in the buffer
RsDataValidBit        : in  std_logic_vector(7 downto 0); -- '1' indicates rs data is valid in the buffer

Buffer0RsTag        : in  std_logic_vector(5 downto 0); 
Buffer1RsTag        : in  std_logic_vector(5 downto 0); 
Buffer2RsTag        : in  std_logic_vector(5 downto 0); 
Buffer3RsTag        : in  std_logic_vector(5 downto 0); 
Buffer4RsTag        : in  std_logic_vector(5 downto 0); 
Buffer5RsTag        : in  std_logic_vector(5 downto 0); 
Buffer6RsTag        : in  std_logic_vector(5 downto 0); 
Buffer7RsTag        : in  std_logic_vector(5 downto 0); 

Buffer0RdTag        : in  std_logic_vector(4 downto 0); 
Buffer1RdTag        : in  std_logic_vector(4 downto 0); 
Buffer2RdTag        : in  std_logic_vector(4 downto 0); 
Buffer3RdTag        : in  std_logic_vector(4 downto 0); 
Buffer4RdTag        : in  std_logic_vector(4 downto 0); 
Buffer5RdTag        : in  std_logic_vector(4 downto 0); 
Buffer6RdTag        : in  std_logic_vector(4 downto 0); 
Buffer7RdTag        : in  std_logic_vector(4 downto 0); 

IssuqueCounter0     : in std_logic_vector ( 2 downto 0 ) ;
IssuqueCounter1     : in std_logic_vector ( 2 downto 0 ) ;
IssuqueCounter2     : in std_logic_vector ( 2 downto 0 ) ;
IssuqueCounter3     : in std_logic_vector ( 2 downto 0 ) ;
IssuqueCounter4     : in std_logic_vector ( 2 downto 0 ) ;
IssuqueCounter5     : in std_logic_vector ( 2 downto 0 ) ;
IssuqueCounter6     : in std_logic_vector ( 2 downto 0 ) ;
IssuqueCounter7     : in std_logic_vector ( 2 downto 0 ) ;

-- output control signals - group 1
Sel0                  : out std_logic; -- '1' indicates update from dispatch 
Flush                 : out std_logic_vector(7 downto 0); -- '1' indicates invalidate instruction valid bit 
Sel1Rs                : out std_logic_vector(7 downto 0); -- '1' indicates update from cdb - highest priority
En                    : out std_logic_vector(7 downto 0); -- '1' indicates update / shift
OutSelect             : out std_logic_vector(2 downto 0);  
IncrementCounter      : out std_logic_vector(7 downto 0 ) ;
-- issue que unit control signals
Issque_LdStQueueFull         : out std_logic ;
IssuequefullTemp_Upper,IssuequefullTemp_Lower : out std_logic ;
Iss_LdStReady        : out std_logic ;

-- Address Buffer Signal 
 AddrBuffFull         : in std_logic;
 AddrMatch0           : in std_logic ;
 AddrMatch1           : in std_logic ;
 AddrMatch2           : in std_logic ;
 AddrMatch3           : in std_logic ;
 AddrMatch4           : in std_logic ;
 AddrMatch5           : in std_logic ;
 AddrMatch6           : in std_logic ;
 AddrMatch7           : in std_logic ;
 
 AddrMatch0Num        : in std_logic_vector ( 2 downto 0 )  ;
 AddrMatch1Num        : in std_logic_vector ( 2 downto 0 )  ;
 AddrMatch2Num        : in std_logic_vector ( 2 downto 0 )  ;
 AddrMatch3Num        : in std_logic_vector ( 2 downto 0 )  ;
 AddrMatch4Num        : in std_logic_vector ( 2 downto 0 )  ;
 AddrMatch5Num        : in std_logic_vector ( 2 downto 0 )  ;
 AddrMatch6Num        : in std_logic_vector ( 2 downto 0 )  ;
 AddrMatch7Num        : in std_logic_vector ( 2 downto 0 )  ;
 
 ScanAddr0            : in std_logic_vector ( 31 downto 0 ) ;
 ScanAddr1            : in std_logic_vector ( 31 downto 0 ) ;
 ScanAddr2            : in std_logic_vector ( 31 downto 0 ) ;
 ScanAddr3            : in std_logic_vector ( 31 downto 0 ) ;    
 ScanAddr4            : in std_logic_vector ( 31 downto 0 ) ;
 ScanAddr5            : in std_logic_vector ( 31 downto 0 ) ;
 ScanAddr6            : in std_logic_vector ( 31 downto 0 ) ;
 ScanAddr7            : in std_logic_vector ( 31 downto 0 )     
);
end Lsquectrl ;

architecture behavctrl of Lsquectrl is 
signal  OutTemp                                : std_logic_vector ( 2 downto 0 ) ;
signal  OutSelectTemp , Entemp                 : std_logic_vector ( 7 downto 0 ) ;  
signal  IssuequeReadyTemp , IssuequefullTemp,IssuequefullTemp_Upper_sig,IssuequefullTemp_Lower_sig   : std_logic   ;                                                      
signal  Buffer0Depth, Buffer1Depth ,Buffer2Depth ,Buffer3Depth, Buffer4Depth, 
        Buffer5Depth ,Buffer6Depth ,Buffer7Depth : std_logic_vector(4 downto 0) ;
signal OutSelectTemp2 : std_logic_vector( 7 downto 0 )  ;

 begin 

 
----------------------Generating Issuque ready -------------------------------------

 
Iss_LdStReady      <= IssuequeReadyTemp  and ( not AddrBuffFull);  --so you can't issue any lw/sw when address buffer is full!!  NOTE: qualify for "sw" only

---------- ----------Done Generating issuque Ready --------------------------------





-------------------- Generating Full Condition-------------------------------------
--###############################################################################################
-- TODO 1: Generate the Full control signal
--################################################################################################


   process (  InstructionValidBit ,Iss_LdStIssued )
       begin
        
    if ( Iss_LdStIssued = '1' ) then --when an instruction is issued issueque is not full
         IssuequefullTemp <= '0' ;
		 IssuequefullTemp_Upper_sig <= ----- ;  --Fill in the initial values of these two signals.	//almost same as Issueque full signal
		 IssuequefullTemp_Lower_sig <= ----- ;
    else
          IssuequefullTemp_Upper_sig <=InstructionValidBit(7) and  InstructionValidBit(6) and  
							   InstructionValidBit(5) and  InstructionValidBit(4);
              							   
	      IssuequefullTemp_Lower_sig <=InstructionValidBit(3) and  InstructionValidBit(2) and  
                               InstructionValidBit(1) and  InstructionValidBit(0) ;
    end if ;
   end process ;
	IssuequefullTemp_Upper<=IssuequefullTemp_Upper_sig;
	IssuequefullTemp_Lower<=IssuequefullTemp_Lower_sig;
	
   Issque_LdStQueueFull  <=  -- ------------------------------------------; --Complete the right hand side of the expression 
   
------------------ Done Generating Full Condition ------------------------------- 
--################################################################################################ 
 
------------------- Generating OutSelect----------------------------------------


--these are simple output select signals based on the instruction and corresponding necessary operands being ready

OutSelectTemp (0)<= AddrReadyBit(0) and InstructionValidBit(0);                                           
OutSelectTemp (1)<= AddrReadyBit(1) and InstructionValidBit(1) ;
OutSelectTemp (2)<= AddrReadyBit(2) and InstructionValidBit(2) ;
OutSelectTemp (3)<= AddrReadyBit(3) and InstructionValidBit(3) ;
OutSelectTemp (4)<= AddrReadyBit(4) and InstructionValidBit(4) ;                                               
OutSelectTemp (5)<= AddrReadyBit(5) and InstructionValidBit(5) ;
OutSelectTemp (6)<= AddrReadyBit(6) and InstructionValidBit(6) ;
OutSelectTemp (7)<= AddrReadyBit(7) and InstructionValidBit(7) ;          


--**********************************************************************************************************

--###############################################################################################
-- TODO 2: Complete the memory disambiguation
--################################################################################################
--*****************************************************************************************************************
--          Complete the processes to satisfy the memory disambiguation rules
--          do not issue a "lw" if number of address matches is greater than the number of "sw" skipping the "lw"
--          do not issue a "sw" if any lw with unkonwn address is lying ahead of it, you need the address of the lw to make an entry in the address buffer
--          as the sw is bypassing it.
--**************************************************************************************************************
-- These processes takes care of memory disambiguation
--=====================================================
-- 1. For an instruction being a valid "lw" it can only be issued when all the "sw"(with same address) in front of it had comitted
--    This case is substantiated by address match number being less than issuecounter signal which indicates that
--    all the "sw" that were issued earlier have comitted so one can issue the lw 

-- 2. For an instruction being a valid "sw" it can be issued only if all the "lw" in front of it have their address ready, this 
--    Precaution is needed because you need to store the address of any bypassing sw (for any lw) if the address matches
--**************************************************************************************************************

process ( AddrMatch0Num , AddrMatch0 , IssuqueCounter0 , Opcode ,InstructionValidBit,OutSelectTemp)
    begin
        OutSelectTemp2(0) <= OutSelectTemp(0) ; --initialize the signal OutSelectTemp2 = OutSelectTemp
        if ( opcode(0) = '1'  and InstructionValidBit(0) = '1' ) then  --valid "lw"
          if ( AddrMatch0 = '1' ) then
           if ( AddrMatch0Num > IssuqueCounter0 ) then  -- "lw" can not be issued only when no of matches is greater than no of "sw"s skipping "lw"
               OutSelectTemp2(0) <= '0' ;
           end if ;
       end if ;
   end if ;
   end process ;
   
process ( AddrMatch1Num , AddrMatch1 , IssuqueCounter1 , OutSelectTemp ,
             Opcode,  AddrReadyBit, InstructionValidBit, ScanAddr0 , ScanAddr1)
    begin
        OutSelectTemp2(1) <= OutSelectTemp(1) ;
        if ( InstructionValidBit(1) = '1' ) then
            if ( opcode(1) = '1'  ) then  --"lw""
                if ( AddrMatch1 = '1' ) then
                    if ( AddrMatch1Num > IssuqueCounter1 ) then
                        OutSelectTemp2(1) <= '0' ;
                    end if ;
                end if ;
						--**********************************************************************
						-- -- Mod by PRASANJEET: 7/25/09   
						--**********************************************************************
				if(InstructionValidBit(0)= '1' and (AddrReadyBit(0) = '0' or (AddrReadyBit(0) = '1' and  ( ScanAddr0 = ScanAddr1 )))and opcode(0) = '0')then -- not ready "sw" in front
				   OutSelectTemp2(1)<='0';
				end if;
						--***********************************************************************
			else  -- this clause states that you can issue a "sw" in the following two cases: 1. there is a sw in fornt of it 2. it has lw with known address in fornt of it.  NOTE: this portion of code emphasizes on the fact that a sw can't skip a lw with unknown address. (because you need to store the address of sw in the address buffer if it matches)
			--//write code for OutSelectTemp 2, 3, 4, 5, 6, 7
     --*****************************************************************************************
	 -- Mod by PRASANJEET: 7/26/09
	 --*****************************************************************************************
				if( InstructionValidBit(0) = '1' and (opcode(0) = '1' and AddrReadyBit(0) = '0' )) then -- Mod by PRASANJEET: 7/26/09
					OutSelectTemp2(1) <= '0';  
				end if;
	 --******************************************************************************************
            end if ;
        end if ;
    end process ;
	
	-- Going along the same lines complete the rest of the six processes
  
process ( AddrMatch2Num , AddrMatch2 , IssuqueCounter2 , Opcode  ,OutSelectTemp ,
            InstructionValidBit , AddrReadyBit, ScanAddr0 , ScanAddr1 , ScanAddr2)
	begin
		OutSelectTemp2(2) <= OutSelectTemp(2) ;
		--------------------------------------------
		--------------------------------------------
		--------------------------------------------
		--------------------------------------------
		--------------------------------------------
	end process ;  

process ( AddrMatch3Num, InstructionValidBit , AddrMatch3 , IssuqueCounter3 , Opcode  ,OutSelectTemp,
          AddrReadyBit, ScanAddr0 , ScanAddr1 , Scanaddr2, ScanAddr3 )
    begin
        OutSelectTemp2(3) <= OutSelectTemp(3) ;
        --------------------------------------------
		--------------------------------------------
		--------------------------------------------
		--------------------------------------------
		--------------------------------------------
    end process ;  
	
	process ( AddrMatch4Num, InstructionValidBit , AddrMatch4 , IssuqueCounter4 , Opcode  ,OutSelectTemp,
          AddrReadyBit, ScanAddr0 , ScanAddr1 , Scanaddr2, ScanAddr3, ScanAddr4 )
    begin
        OutSelectTemp2(4) <= OutSelectTemp(4) ;
       	--------------------------------------------
		--------------------------------------------
		--------------------------------------------
		--------------------------------------------
		--------------------------------------------
    end process ;
	
	process ( AddrMatch5Num, InstructionValidBit , AddrMatch5 , IssuqueCounter5 , Opcode  ,OutSelectTemp,
          AddrReadyBit, ScanAddr0 , ScanAddr1 , Scanaddr2, ScanAddr3, ScanAddr4, ScanAddr5 )
    begin
        OutSelectTemp2(5) <= OutSelectTemp(5) ;
        --------------------------------------------
		--------------------------------------------
		--------------------------------------------
		--------------------------------------------
		--------------------------------------------
    end process ;
	
	process ( AddrMatch6Num, InstructionValidBit , AddrMatch6 , IssuqueCounter6 , Opcode  ,OutSelectTemp,
          AddrReadyBit, ScanAddr0 , ScanAddr1 , Scanaddr2, ScanAddr3, ScanAddr4, ScanAddr5, ScanAddr6 )
    begin
        OutSelectTemp2(6) <= OutSelectTemp(6) ;
        --------------------------------------------
		--------------------------------------------
		--------------------------------------------
		--------------------------------------------
		--------------------------------------------
    end process ;
	
	process ( AddrMatch7Num, InstructionValidBit , AddrMatch7 , IssuqueCounter7 , Opcode  ,OutSelectTemp,
          AddrReadyBit, ScanAddr0 , ScanAddr1 , Scanaddr2, ScanAddr3, ScanAddr4, ScanAddr5, ScanAddr6, ScanAddr7 )
    begin
        OutSelectTemp2(7) <= OutSelectTemp(7) ;
        --------------------------------------------
		--------------------------------------------
		--------------------------------------------
		--------------------------------------------
		--------------------------------------------
    end process ;
	
	--##################################################################################################################
     
	 --***************************************************************************************
	 -- This process is used to assign priority so that only one instruction is issued even
	 -- when multiple instructions are ready to be issued
	 --***************************************************************************************
    process ( OutSelectTemp2) --to issue only one at a time, priority is given over here
        begin
            Outtemp <= "000" ;
            if ( OutSelectTemp2(0) = '1')  then
              Outtemp <= "000" ;
              IssuequeReadyTemp <= '1' ;
             else 
               if ( OutSelectTemp2(1) = '1' ) then
                  Outtemp <= "001" ;
                  IssuequeReadyTemp <= '1' ;            
               else
                    if ( OutSelectTemp2(2) = '1') then
                       Outtemp <= "010" ;
                       IssuequeReadyTemp <= '1' ;
                    else
                        if ( OutSelectTemp2(3) = '1')  then
                             Outtemp <= "011" ;
                             IssuequeReadyTemp <= '1' ;
                        else
							if ( OutSelectTemp2(4) = '1')  then
								Outtemp <= "100" ;
								IssuequeReadyTemp <= '1' ;
							else
								if ( OutSelectTemp2(5) = '1') then
									Outtemp <= "101" ;
									IssuequeReadyTemp <= '1' ;            
								else
									if ( OutSelectTemp2(6) = '1') then
										Outtemp <= "110" ;
										IssuequeReadyTemp <= '1' ;
									else
										if ( OutSelectTemp2(7) = '1')  then
											Outtemp <= "111" ;
											IssuequeReadyTemp <= '1' ;
										else                        
											IssuequeReadyTemp <= '0' ;
										end if ;
									end if; 
								end if;
							end if; 
						end if;
					end if;
				end if;
			end if;
		end process ;

OutSelect <= Outtemp ;


------------------------------------Done Generating OutSelect ------------------------------------------     
--********************************************************************************************************
-- These processes keep track of bypassing "sw" for every entry of "lw"
-- The increment counter signal is sort of count enable that increments the corresponding counter for a "lw"
-- If the bypassing "sw" has the same address
--***********************************************************************************************************
process ( Outtemp , opcode , ScanAddr0 , ScanAddr1 , ScanAddr2 , ScanAddr3, 
		  ScanAddr4 , ScanAddr5 , ScanAddr6 , ScanAddr7,Iss_LdStIssued  ) -- generating the done signal as well as incrementing the counter to make note of sw skipping lw
    begin  --gives the total no. of address matches
        IncrementCounter(0) <= '0' ;
    if ( opcode(0) = '1' and Iss_LdStIssued = '1'  ) then  -- an "lw/sw" instruction is about to be issued so make a note of it
     case Outtemp is
           when "000" =>  IncrementCounter(0) <= '0' ;
           when "001" =>  if ( ScanAddr0 = ScanAddr1 ) then  
							IncrementCounter(0) <= '1' ;  -- it is sort of counter enable
						  else
							IncrementCounter(0) <= '0' ; 
						  end if ;
           when "010" =>  if ( ScanAddr0 = ScanAddr2 ) then
							IncrementCounter(0) <= '1' ;
                          else
							IncrementCounter(0) <= '0' ; 
                          end if ;  		   
           when "011" =>  if ( ScanAddr0 = ScanAddr3 ) then  
							IncrementCounter(0) <= '1' ;  -- it is sort of counter enable
						  else
							IncrementCounter(0) <= '0' ; 
						  end if ;
           when "100" =>  if ( ScanAddr0 = ScanAddr4 ) then
							IncrementCounter(0) <= '1' ;
                          else
							IncrementCounter(0) <= '0' ; 
                          end if ;  
		   when "101" =>  if ( ScanAddr0 = ScanAddr5 ) then  
							IncrementCounter(0) <= '1' ;  -- it is sort of counter enable
						  else
							IncrementCounter(0) <= '0' ; 
						  end if ;
           when "110" =>  if ( ScanAddr0 = ScanAddr6 ) then
							IncrementCounter(0) <= '1' ;
                          else
							IncrementCounter(0) <= '0' ; 
                          end if ;
           when others => if ( ScanAddr0 = ScanAddr7 ) then
							IncrementCounter(0) <= '1' ;
                          else
                            IncrementCounter(0) <= '0' ; 
                          end if ;                       
  end case ;
  end if ;
  end process ;
  
  
  
process ( Outtemp , opcode ,Iss_LdStIssued,  ScanAddr1 , ScanAddr2 , ScanAddr3, ScanAddr4,
            ScanAddr5, ScanAddr6, ScanAddr7)
      begin
          IncrementCounter(1) <= '0' ;
      if ( opcode(1) = '1' and Iss_LdStIssued = '1'  ) then
       case Outtemp is
           when "000" =>  IncrementCounter(1) <= '0' ;
           when "001" =>  IncrementCounter(1) <= '0' ; 
                        
           when "010" =>  if ( ScanAddr1 = ScanAddr2) then
							IncrementCounter(1) <= '1' ;
                          else
							IncrementCounter(1) <= '0' ; 
						  end if ;
           when "011" =>  if ( ScanAddr1 = ScanAddr3 ) then  
							IncrementCounter(1) <= '1' ;  -- it is sort of counter enable
						  else
							IncrementCounter(1) <= '0' ; 
						  end if ;
           when "100" =>  if ( ScanAddr1 = ScanAddr4 ) then
							IncrementCounter(1) <= '1' ;
                          else
							IncrementCounter(1) <= '0' ; 
                          end if ;  
		   when "101" =>  if ( ScanAddr1 = ScanAddr5 ) then  
							IncrementCounter(1) <= '1' ;  -- it is sort of counter enable
						  else
							IncrementCounter(1) <= '0' ; 
						  end if ;
           when "110" =>  if ( ScanAddr1 = ScanAddr6 ) then
							IncrementCounter(1) <= '1' ;
                          else
							IncrementCounter(1) <= '0' ; 
                          end if ;
           
           when others => if ( ScanAddr1 = ScanAddr7 ) then
                            IncrementCounter(1) <= '1' ;
                          else
                            IncrementCounter(1) <= '0' ; 
                          end if ;
                         
    end case ;
end if ;
end process ;
    
    
process ( Outtemp, opcode, ScanAddr2, ScanAddr3, ScanAddr4, ScanAddr5, ScanAddr6, ScanAddr7, Iss_LdStIssued  )
    begin
        IncrementCounter(2) <= '0' ;
        if ( opcode(2) = '1' and Iss_LdStIssued = '1' ) then
         case Outtemp is
           when "000" =>  IncrementCounter(2) <= '0' ;
           when "001" =>  IncrementCounter(2) <= '0' ; 
           when "010" =>  IncrementCounter(2) <= '0' ; 
           when "011" =>  if ( ScanAddr2 = ScanAddr3 ) then  
							IncrementCounter(2) <= '1' ;  -- it is sort of counter enable
						  else
							IncrementCounter(2) <= '0' ; 
						  end if ;
           when "100" =>  if ( ScanAddr2 = ScanAddr4 ) then
							IncrementCounter(2) <= '1' ;
                          else
							IncrementCounter(2) <= '0' ; 
                          end if ;  
		   when "101" =>  if ( ScanAddr2 = ScanAddr5 ) then  
							IncrementCounter(2) <= '1' ;  -- it is sort of counter enable
						  else
							IncrementCounter(2) <= '0' ; 
						  end if ;
           when "110" =>  if ( ScanAddr2 = ScanAddr6 ) then
							IncrementCounter(2) <= '1' ;
                          else
							IncrementCounter(2) <= '0' ; 
                          end if ;            
           when others => if ( ScanAddr2 = ScanAddr7 ) then
                            IncrementCounter(2) <= '1' ;
                          else
                            IncrementCounter(2) <= '0' ; 
                          end if ;                          
      end case ;
  end if; 
end process ;

process ( Outtemp, opcode, ScanAddr3, ScanAddr4, ScanAddr5, ScanAddr6, ScanAddr7, Iss_LdStIssued  )
    begin
        IncrementCounter(3) <= '0' ;
        if ( opcode(3) = '1' and Iss_LdStIssued = '1' ) then
         case Outtemp is
           when "000" =>  IncrementCounter(3) <= '0' ;
           when "001" =>  IncrementCounter(3) <= '0' ; 
           when "010" =>  IncrementCounter(3) <= '0' ; 
           when "011" =>  IncrementCounter(3) <= '0' ;
           when "100" =>  if ( ScanAddr3 = ScanAddr4 ) then
							IncrementCounter(3) <= '1' ;
                          else
							IncrementCounter(3) <= '0' ; 
                          end if ;  
		   when "101" =>  if ( ScanAddr3 = ScanAddr5 ) then  
							IncrementCounter(3) <= '1' ;  -- it is sort of counter enable
						  else
							IncrementCounter(3) <= '0' ; 
						  end if ;
           when "110" =>  if ( ScanAddr3 = ScanAddr6 ) then
							IncrementCounter(3) <= '1' ;
                          else
							IncrementCounter(3) <= '0' ; 
                          end if ;            
           when others => if ( ScanAddr3 = ScanAddr7 ) then
                            IncrementCounter(3) <= '1' ;
                          else
                            IncrementCounter(3) <= '0' ; 
                          end if ;                          
      end case ;
  end if; 
end process ;

process ( Outtemp, opcode, ScanAddr4, ScanAddr5, ScanAddr6, ScanAddr7, Iss_LdStIssued  )
    begin
        IncrementCounter(4) <= '0' ;
        if ( opcode(4) = '1' and Iss_LdStIssued = '1' ) then
         case Outtemp is
           when "000" =>  IncrementCounter(4) <= '0' ;
           when "001" =>  IncrementCounter(4) <= '0' ; 
           when "010" =>  IncrementCounter(4) <= '0' ; 
           when "011" =>  IncrementCounter(4) <= '0' ;
           when "100" =>  IncrementCounter(4) <= '0' ; 
		   when "101" =>  if ( ScanAddr4 = ScanAddr5 ) then  
							IncrementCounter(4) <= '1' ;  -- it is sort of counter enable
						  else
							IncrementCounter(4) <= '0' ; 
						  end if ;
           when "110" =>  if ( ScanAddr4 = ScanAddr6 ) then
							IncrementCounter(4) <= '1' ;
                          else
							IncrementCounter(4) <= '0' ; 
                          end if ;            
           when others => if ( ScanAddr4 = ScanAddr7 ) then
                            IncrementCounter(4) <= '1' ;
                          else
                            IncrementCounter(4) <= '0' ; 
                          end if ;                          
      end case ;
  end if; 
end process ;

process ( Outtemp, opcode, ScanAddr5, ScanAddr6, ScanAddr7, Iss_LdStIssued  )
    begin
        IncrementCounter(5) <= '0' ;
        if ( opcode(5) = '1' and Iss_LdStIssued = '1' ) then
         case Outtemp is
           when "000" =>  IncrementCounter(5) <= '0' ;
           when "001" =>  IncrementCounter(5) <= '0' ; 
           when "010" =>  IncrementCounter(5) <= '0' ; 
           when "011" =>  IncrementCounter(5) <= '0' ;
           when "100" =>  IncrementCounter(5) <= '0' ; 
		   when "101" =>  IncrementCounter(5) <= '0' ;
           when "110" =>  if ( ScanAddr5 = ScanAddr6 ) then
							IncrementCounter(5) <= '1' ;
                          else
							IncrementCounter(5) <= '0' ; 
                          end if ;            
           when others => if ( ScanAddr5 = ScanAddr7 ) then
                            IncrementCounter(5) <= '1' ;
                          else
                            IncrementCounter(5) <= '0' ; 
                          end if ;                          
      end case ;
  end if; 
end process ;

process ( Outtemp, opcode, ScanAddr6, ScanAddr7, Iss_LdStIssued  )
    begin
        IncrementCounter(6) <= '0' ;
        if ( opcode(6) = '1' and Iss_LdStIssued = '1' ) then
         case Outtemp is
           when "000" =>  IncrementCounter(6) <= '0' ;
           when "001" =>  IncrementCounter(6) <= '0' ; 
           when "010" =>  IncrementCounter(6) <= '0' ; 
           when "011" =>  IncrementCounter(6) <= '0' ;
           when "100" =>  IncrementCounter(6) <= '0' ; 
		   when "101" =>  IncrementCounter(6) <= '0' ;
           when "110" =>  IncrementCounter(6) <= '0' ;          
           when others => if ( ScanAddr6 = ScanAddr7 ) then
                            IncrementCounter(6) <= '1' ;
                          else
                            IncrementCounter(6) <= '0' ; 
                          end if ;                          
      end case ;
  end if; 
end process ;       
        IncrementCounter(7) <= '0' ;  --since the last so will always be '0'

----------------------------------- Generating Address Update Condition--------------------

--********************************************************************************************************************************
-- This process takes care of address updating conditions, there are two control signals
-- 1. the addrupdate which tell i need to update the "rs" field data for address calculation on this entry
-- 2. The addrupdate sel which when "0" indicates that i have the valid rs field data with me so i update myself with my own data
--                             when "1" indicates that i will get the updated rs field data from the entry above me
--*********************************************************************************************************************************
process ( RsDataValidBit, Entemp, Outtemp, AddrReadyBit, Iss_LdStIssued, InstructionValidBit)
    begin
       AddrUpdate <= "00000000" ;  -- i want to update this address 
       AddrUpdateSel <= "00000000" ;  -- whether to update from the one above me (1)/or from me(0)
       if( Iss_LdStIssued = '1' ) then 
        case Outtemp is
                    when "000" =>  
						AddrUpdateSel (7 downto 0) <= '0' & RsDataValidBit (7 downto 1);
						for i in 0 to 6 loop						  
							if (RsDataValidBit (i+1) = '1') then
							  AddrUpdate (i) <= not AddrReadyBit(i+1);  -- if address is ready no need to update!!
							end if;
						end loop;
						AddrUpdate (7) <= '0';
						
					when "001" =>
						if( (RsDataValidBit(0) ='1') and (AddrReadyBit(0) = '0') ) then 
                                    AddrUpdate(0)     <= '1';
                                    AddrUpdateSel(0) <= '0' ;
						end if;
						
						AddrUpdateSel (7 downto 1) <= '0' & RsDataValidBit (7 downto 2);
						for i in 1 to 6 loop						 
						    if (RsDataValidBit (i+1) = '1') then
							  AddrUpdate (i) <= not AddrReadyBit (i+1);
							end if;
						end loop;
						AddrUpdate (7) <= '0';
						
					when "010" =>
						if(RsDataValidBit(0) = '1' and AddrReadyBit(0) = '0' ) then 
                            AddrUpdate(0)     <= '1';
                            AddrUpdateSel(0) <= '0' ;  
                        end if;                              
                              
                        if(RsDataValidBit(1) = '1' and AddrReadyBit(1) = '0'  ) then 
                            AddrUpdate(1)     <= '1';
                            AddrUpdateSel(1) <= '0' ;  
                        end if;     
						
						AddrUpdateSel (7 downto 2) <= '0' & RsDataValidBit (7 downto 3);
						for i in 2 to 6 loop						  
						    if (RsDataValidBit (i+1) = '1') then
							  AddrUpdate (i) <= not AddrReadyBit (i+1);
							end if;
						end loop;
						AddrUpdate (7) <= '0';
						
					when "011" =>
						if(RsDataValidBit(0) = '1' and AddrReadyBit(0) = '0' ) then 
                            AddrUpdate(0)     <= '1';
                            AddrUpdateSel(0) <= '0' ;  
                        end if;                              
                              
                        if(RsDataValidBit(1) = '1' and AddrReadyBit(1) = '0'  ) then 
                            AddrUpdate(1)     <= '1';
                            AddrUpdateSel(1) <= '0' ;  
                        end if;    

						if(RsDataValidBit(2) = '1' and AddrReadyBit(2) = '0'  ) then 
                            AddrUpdate(2)     <= '1';
                            AddrUpdateSel(2) <= '0' ;  
                        end if;    
						
						AddrUpdateSel (7 downto 3) <= '0' & RsDataValidBit (7 downto 4);
						for i in 3 to 6 loop						 
						    if (RsDataValidBit (i+1) = '1') then
							  AddrUpdate (i) <= not AddrReadyBit (i+1);
							end if;
						end loop;
						AddrUpdate (7) <= '0';
						
					when "100" =>
						if(RsDataValidBit(0) = '1' and AddrReadyBit(0) = '0' ) then 
                            AddrUpdate(0)     <= '1';
                            AddrUpdateSel(0) <= '0' ;  
                        end if;                              
                              
                        if(RsDataValidBit(1) = '1' and AddrReadyBit(1) = '0'  ) then 
                            AddrUpdate(1)     <= '1';
                            AddrUpdateSel(1) <= '0' ;  
                        end if;    

						if(RsDataValidBit(2) = '1' and AddrReadyBit(2) = '0'  ) then 
                            AddrUpdate(2)     <= '1';
                            AddrUpdateSel(2) <= '0' ;  
                        end if;    
						
						if(RsDataValidBit(3) = '1' and AddrReadyBit(3) = '0'  ) then 
                            AddrUpdate(3)     <= '1';
                            AddrUpdateSel(3) <= '0' ;  
                        end if;    
						
						AddrUpdateSel (7 downto 4) <= '0' & RsDataValidBit (7 downto 5);
						for i in 4 to 6 loop						 
						    if (RsDataValidBit (i+1) = '1') then
							  AddrUpdate (i) <= not AddrReadyBit (i+1);
							end if;
						end loop;
						AddrUpdate (7) <= '0';
						
					when "101" =>
						if(RsDataValidBit(0) = '1' and AddrReadyBit(0) = '0' ) then 
                            AddrUpdate(0)     <= '1';
                            AddrUpdateSel(0) <= '0' ;  
                        end if;                              
                              
                        if(RsDataValidBit(1) = '1' and AddrReadyBit(1) = '0'  ) then 
                            AddrUpdate(1)     <= '1';
                            AddrUpdateSel(1) <= '0' ;  
                        end if;    

						if(RsDataValidBit(2) = '1' and AddrReadyBit(2) = '0'  ) then 
                            AddrUpdate(2)     <= '1';
                            AddrUpdateSel(2) <= '0' ;  
                        end if;    
						
						if(RsDataValidBit(3) = '1' and AddrReadyBit(3) = '0'  ) then 
                            AddrUpdate(3)     <= '1';
                            AddrUpdateSel(3) <= '0' ;  
                        end if;   
						
						if(RsDataValidBit(4) = '1' and AddrReadyBit(4) = '0'  ) then 
                            AddrUpdate(4)     <= '1';
                            AddrUpdateSel(4) <= '0' ;  
                        end if;
						
						AddrUpdateSel (7 downto 5) <= '0' & RsDataValidBit (7 downto 6);
						for i in 5 to 6 loop						  
						    if (RsDataValidBit (i+1) = '1') then
							  AddrUpdate (i) <= not AddrReadyBit (i+1);
							end if;
						end loop;
						AddrUpdate (7) <= '0';
						
					when "110" =>
						if(RsDataValidBit(0) = '1' and AddrReadyBit(0) = '0' ) then 
                            AddrUpdate(0)     <= '1';
                            AddrUpdateSel(0) <= '0' ;  
                        end if;                              
                              
                        if(RsDataValidBit(1) = '1' and AddrReadyBit(1) = '0'  ) then 
                            AddrUpdate(1)     <= '1';
                            AddrUpdateSel(1) <= '0' ;  
                        end if;    

						if(RsDataValidBit(2) = '1' and AddrReadyBit(2) = '0'  ) then 
                            AddrUpdate(2)     <= '1';
                            AddrUpdateSel(2) <= '0' ;  
                        end if;    
						
						if(RsDataValidBit(3) = '1' and AddrReadyBit(3) = '0'  ) then 
                            AddrUpdate(3)     <= '1';
                            AddrUpdateSel(3) <= '0' ;  
                        end if;   
						
						if(RsDataValidBit(4) = '1' and AddrReadyBit(4) = '0'  ) then 
                            AddrUpdate(4)     <= '1';
                            AddrUpdateSel(4) <= '0' ;  
                        end if;
						
						if(RsDataValidBit(5) = '1' and AddrReadyBit(5) = '0'  ) then 
                            AddrUpdate(5)     <= '1';
                            AddrUpdateSel(5) <= '0' ;  
                        end if;
						
						AddrUpdateSel (7 downto 6) <= '0' & RsDataValidBit (7);
					    if (RsDataValidBit (7) = '1') then
							AddrUpdate (6) <= not AddrReadyBit (7);
					    end if;					
						AddrUpdate (7) <= '0'; 
                             
					when others =>           
						if(RsDataValidBit(0) = '1' and AddrReadyBit(0) = '0' ) then 
                            AddrUpdate(0)     <= '1';
                            AddrUpdateSel(0) <= '0' ;  
                        end if;                              
                              
                        if(RsDataValidBit(1) = '1' and AddrReadyBit(1) = '0'  ) then 
                            AddrUpdate(1)     <= '1';
                            AddrUpdateSel(1) <= '0' ;  
                        end if;    

						if(RsDataValidBit(2) = '1' and AddrReadyBit(2) = '0'  ) then 
                            AddrUpdate(2)     <= '1';
                            AddrUpdateSel(2) <= '0' ;  
                        end if;    
						
						if(RsDataValidBit(3) = '1' and AddrReadyBit(3) = '0'  ) then 
                            AddrUpdate(3)     <= '1';
                            AddrUpdateSel(3) <= '0' ;  
                        end if;   
						
						if(RsDataValidBit(4) = '1' and AddrReadyBit(4) = '0'  ) then 
                            AddrUpdate(4)     <= '1';
                            AddrUpdateSel(4) <= '0' ;  
                        end if;
						
						if(RsDataValidBit(5) = '1' and AddrReadyBit(5) = '0'  ) then 
                            AddrUpdate(5)     <= '1';
                            AddrUpdateSel(5) <= '0' ;  
                        end if;   

						if(RsDataValidBit(6) = '1' and AddrReadyBit(6) = '0'  ) then 
                            AddrUpdate(6)     <= '1';
                            AddrUpdateSel(6) <= '0' ;  
                        end if;  
						
                            AddrUpdate(7)     <= '0';
                            AddrUpdateSel(7) <= '0' ;
        end case ; 
        
	  else 
	  
                  if(RsDataValidBit(0) = '1' and AddrReadyBit(0) = '0'  ) then 
                        AddrUpdate(0)     <= '1';
                        AddrUpdateSel(0) <= '0' ;  
                  elsif(RsDataValidBit(1) = '1' and AddrReadyBit(1) = '0'   ) then 
                      if ( Entemp(0) = '0' ) then 
                        AddrUpdate(1)     <= '1'; --not moving so update myself
                        AddrUpdateSel(1)  <= '0' ;
                      else
                        AddrUpdate(0)     <= '1';  -- update as per the below one is moving
                        AddrUpdateSel(0)  <= '1' ; 
                      end if ;  
                  elsif(RsDataValidBit(2) = '1' and AddrReadyBit(2) = '0'  ) then
                      if ( Entemp(1) = '0' )  then 
                        AddrUpdate(2)     <= '1';
                        AddrUpdateSel(2) <= '0' ; 
                      else
                        AddrUpdate(1)     <= '1';
                        AddrUpdateSel(1)  <= '1' ; 
                      end if ;                        
				  elsif(RsDataValidBit(3) = '1' and AddrReadyBit(3) = '0'   ) then 
                      if ( Entemp(2) = '0' ) then 
                        AddrUpdate(3)     <= '1';
                        AddrUpdateSel(3) <= '0' ; 
                      else
                        AddrUpdate(2)     <= '1';
                        AddrUpdateSel(2)  <= '1' ; 
                      end if;
                  elsif(RsDataValidBit(4) = '1' and AddrReadyBit(4) = '0'   ) then 
                        if ( Entemp(3) = '0' ) then 
                          AddrUpdate(4)     <= '1'; --not moving so update myself
                          AddrUpdateSel(4)  <= '0' ;
                        else
                          AddrUpdate(3)     <= '1';  -- update as per the below one is moving
                          AddrUpdateSel(3)  <= '1' ; 
                      end if ;  
                  elsif(RsDataValidBit(5) = '1' and AddrReadyBit(5) = '0'  ) then
                      if ( Entemp(4) = '0' )  then 
                        AddrUpdate(5)     <= '1';
                        AddrUpdateSel(5) <= '0' ; 
                      else
                        AddrUpdate(4)     <= '1';
                        AddrUpdateSel(4)  <= '1' ; 
                      end if ;                        
				  elsif(RsDataValidBit(6) = '1' and AddrReadyBit(6) = '0'   ) then 
                      if ( Entemp(5) = '0' ) then 
                        AddrUpdate(6)     <= '1';
                        AddrUpdateSel(6) <= '0' ; 
                      else
                        AddrUpdate(5)     <= '1';
                        AddrUpdateSel(5)  <= '1' ; 
                      end if;
                  elsif(RsDataValidBit(7) = '1' and AddrReadyBit(7) = '0'   ) then 
                      if ( Entemp(6) = '0' ) then 
                        AddrUpdate(7)     <= '1';
                        AddrUpdateSel(7) <= '0' ; 
                      else
                        AddrUpdate(6)     <= '1';
                        AddrUpdateSel(6)  <= '1' ; 
                      end if;
				 else
				       AddrUpdate <= "00000000" ;  -- i want to update this address 
					   AddrUpdateSel <= "00000000" ;
                  end if;
      end if ;
end process;                    
                                                                               
-----------------------------------------------------------------------------------------------------------       
---------------------------------------------------------------------
-- hereonwards same as in issuequeues
----------------------------------------------------------------------
------------------------------- Generating Flush Condition for Queues -----------------
--###############################################################################################
-- TODO 3: Calculation of buffer depth to help in selective flushing
--         fill in the eight expressions
--################################################################################################
	
  -- you arrive at the younger instruction to branch by first calcualting its depth using the tag and top pointer of rob
  -- and comparing its depth with depth of branch instruction (known as Cdb_RobDepth)
Buffer0Depth <=  --------------------------; //unsigned subraction
Buffer1Depth <=  --------------------------; 
Buffer2Depth <=  --------------------------; 
Buffer3Depth <=  --------------------------; 
Buffer4Depth <=  --------------------------; 
Buffer5Depth <=  --------------------------; 
Buffer6Depth <=  --------------------------; 
Buffer7Depth <=  --------------------------;               
--################################################################################################ 
 
 --****************************************************************************************
-- This process takes care of selective flushing and also takes care of shift aspect while
-- doing the selective flushing, i.e if 1 get a shift update signal then instead of flushing
-- myself 1 will be 0 instead (as 1 gets shifted to the place of 0) but remember when flushing 
-- 1 you will be checking bufferdepth 1 and entemp(0) as entemp(0) means 1 is shifting to 0 place
--****************************************************************************************** 
--###############################################################################################
-- TODO 4: Complete the code on selective flusing
--         fill in the missing expressions
-- NOTE: Remember the queue is from 7 downto 0
--       buffer 7th is at top so dispatch writes to it
--       buffer 0 is at the bottom 
--################################################################################################
               process ( Cdb_Flush , Cdb_RobDepth , Buffer0Depth , Buffer1Depth ,
                         Buffer2Depth , Buffer3Depth, Buffer4Depth, Buffer5Depth,
						 Buffer7Depth, Buffer6Depth, Entemp, InstructionValidBit)
                   begin
                       Flush <= "00000000"; 
                       if ( Cdb_Flush = '1' ) then    
                                                    
                          if ( Buffer0Depth > Cdb_RobDepth  ) then  --note this depth is calculated with respect to branch instruction
                             if ( EnTemp(0)  = '0' ) then
                               Flush(0) <= InstructionValidBit(0) ;
                             end if ;
                          end if ;
         
                          if ( Buffer1Depth > Cdb_RobDepth ) then
                             if ( Entemp(0) = '1' ) then 
                               Flush(0) <= ---------------------------------------; Hint: Take into account the shift mechanism so is it i or i+1 or i - 1? -- flush only when instructionvalidbit is 1??? only flush the valid instructions //similar to integer_queue
                             else
                               Flush(1) <= InstructionValidBit(1) ;
                             end if ;
                          else
                               Flush(1) <= '0' ;
                          end if ;
                        
						  if ( Buffer2Depth > Cdb_RobDepth ) then
                             if ( Entemp(1) = '1' ) then 
                             Flush(1) <= ---------------------------------------;
                             else
                             Flush(2) <= InstructionValidBit(2) ;
                             end if ;                            
                          else
                             Flush(2) <= '0' ;
                          end if ;
                          
						  if ( Buffer3Depth > Cdb_RobDepth ) then
                             if ( Entemp(2) = '1' ) then 
                               Flush(2) <= ---------------------------------------;
                             else
                               Flush(3) <= InstructionValidBit(3) ;
                             end if ;
                          else
                             Flush(3) <= '0' ;
                          end if ;
						
						  if ( Buffer4Depth > Cdb_RobDepth ) then
                             if ( Entemp(3) = '1' ) then 
                               Flush(3) <= ---------------------------------------;
                             else
                               Flush(4) <= InstructionValidBit(4) ;
                             end if ;
                          else
                             Flush(4) <= '0' ;
                          end if ;
						  
						  if ( Buffer5Depth > Cdb_RobDepth ) then
                             if ( Entemp(4) = '1' ) then 
                               Flush(4) <= ---------------------------------------;
                             else
                               Flush(5) <= InstructionValidBit(5) ;
                             end if ;
                          else
                             Flush(5) <= '0' ;
                          end if ;
						  
						  if ( Buffer6Depth > Cdb_RobDepth ) then
                             if ( Entemp(5) = '1' ) then 
                               Flush(5) <= ---------------------------------------;
                             else
                               Flush(6) <= InstructionValidBit(6) ;
                             end if ;
                          else
                             Flush(6) <= '0' ;
                          end if ;
						  
						  if ( Buffer7Depth > Cdb_RobDepth ) then
                             if ( Entemp(6) = '1' ) then 
                               Flush(6) <= ---------------------------------------;
                             else
                               Flush(7) <= InstructionValidBit(7) ;
                             end if ;
                          else
                             Flush(7) <= '0' ;
                          end if ;
						  
                       end if ;
            end process ; 
               
               
-------------------- Done Generating Flush Condition ----------------------

--################################################################################################
 
 ---------------------- Generating Rs and Rt Select for Queues to Update from Dispatch -----        
               
               
               
Sel0 <= Dis_LdIssquenable ;

En <= Entemp ;

--***********************************************************************
-- this process deals with generation of enable temp signal 
--***********************************************************************

process ( OutTemp, Iss_LdStIssued, InstructionValidBit, Dis_LdIssquenable )

 
     begin
         if ( Iss_LdStIssued = '1' )  then
         Case (OutTemp) is
             when "000"    => Entemp <= "11111111" ;
             when "001"    => Entemp <= "11111110" ;
             when "010"    => Entemp <= "11111100" ; 
			 when "011"    => Entemp <= "11111000" ;
			 when "100"    => Entemp <= "11110000" ;
             when "101"    => Entemp <= "11100000" ;
             when "110"    => Entemp <= "11000000" ; 
             when others   => Entemp <= "10000000" ;
         end case ; 
         else
            Entemp(0) <=   not (InstructionValidBit(0)); 
            Entemp(1) <= ( not (InstructionValidBit(1)))  or ( not (InstructionValidBit(0) )) ;
            Entemp(2) <= (not (InstructionValidBit(2)))or  (not (InstructionValidBit(1) )) or ( not (InstructionValidBit(0) ));
            Entemp(3) <= (not (InstructionValidBit(3))) or (not (InstructionValidBit(2) ))or 
			( not (InstructionValidBit(1) )) or ( not (InstructionValidBit(0) ) ) ;
			Entemp(4) <= (not (InstructionValidBit(4))) or (not (InstructionValidBit(3))) or 
			(not (InstructionValidBit(2) ))or( not (InstructionValidBit(1) )) or ( not (InstructionValidBit(0) ) ) ; 
			Entemp(5) <= (not (InstructionValidBit(5))) or (not (InstructionValidBit(4))) or (not (InstructionValidBit(3))) or 
			(not (InstructionValidBit(2) ))or( not (InstructionValidBit(1) )) or ( not (InstructionValidBit(0) ) ) ;
			Entemp(6) <= (not (InstructionValidBit(6))) or (not (InstructionValidBit(5))) or 
			(not (InstructionValidBit(4))) or (not (InstructionValidBit(3))) or 
			(not (InstructionValidBit(2) ))or( not (InstructionValidBit(1) )) or ( not (InstructionValidBit(0) ) ) ;			
			Entemp(7) <= Dis_LdIssquenable or (not (InstructionValidBit(6))) or (not (InstructionValidBit(5))) or 
			(not (InstructionValidBit(4))) or (not (InstructionValidBit(3))) or(not (InstructionValidBit(2) )) or 
			( not (InstructionValidBit(1) )) or ( not (InstructionValidBit(0) ) ) ; 
     	
     end if ;
 end process ;  
 
  --*******************************************************************************************
 -- This process does updation of rs data as done in issuequecntrl
 --********************************************************************************************
 
process (  Buffer0RsTag ,Buffer1RsTag, Buffer2RsTag, Buffer3RsTag, InstructionValidBit,
           Buffer7RsTag, Buffer4RsTag, Buffer5RsTag, Buffer6RsTag, Cdb_RdPhyAddr, Cdb_Valid, Entemp, RsDataValidBit,Cdb_PhyRegWrite) 
         begin
              Sel1Rs <= "00000000" ;
             if ( Cdb_Valid = '1'  ) then --updation from CDB
                 if ( Buffer0RsTag = Cdb_RdPhyAddr and RsDataValidBit(0) ='0' and  InstructionValidBit(0) = '1' and  Cdb_PhyRegWrite ='1' ) then                     
                      Sel1Rs(0) <= '1' ;
                 end if ;
                 
                 if ( Buffer1RsTag = Cdb_RdPhyAddr and RsDataValidBit(1) ='0'and InstructionValidBit(1) = '1' and  Cdb_PhyRegWrite ='1' ) then
                    if ( Entemp (0) = '1' ) then
                       Sel1Rs(0) <= '1' ;
                    else
                       Sel1Rs(1)  <= '1' ;
                    end if ;
                 end if ;
				 
				 if ( Buffer2RsTag = Cdb_RdPhyAddr and RsDataValidBit(2) ='0'and InstructionValidBit(2) = '1' and  Cdb_PhyRegWrite ='1' ) then
                    if ( Entemp (1) = '1' ) then
                       Sel1Rs(1) <= '1' ;
                    else
                       Sel1Rs(2)  <= '1' ;
                    end if ;
                 end if ;
				 
				 if ( Buffer3RsTag = Cdb_RdPhyAddr and RsDataValidBit(3) ='0'and InstructionValidBit(3) = '1' and  Cdb_PhyRegWrite ='1' ) then
                    if ( Entemp (2) = '1' ) then
                       Sel1Rs(2) <= '1' ;
                    else
                       Sel1Rs(3)  <= '1' ;
                    end if ;
                 end if ;
				 
				 if ( Buffer4RsTag = Cdb_RdPhyAddr and RsDataValidBit(4) ='0'and InstructionValidBit(4) = '1' and  Cdb_PhyRegWrite ='1' ) then
                    if ( Entemp (3) = '1' ) then
                       Sel1Rs(3) <= '1' ;
                    else
                       Sel1Rs(4)  <= '1' ;
                    end if ;
                 end if ;
				 
				 if ( Buffer5RsTag = Cdb_RdPhyAddr and RsDataValidBit(5) ='0'and InstructionValidBit(5) = '1' and  Cdb_PhyRegWrite ='1' ) then
                    if ( Entemp (4) = '1' ) then
                       Sel1Rs(4) <= '1' ;
                    else
                       Sel1Rs(5)  <= '1' ;
                    end if ;
                 end if ;
				 
				 if ( Buffer6RsTag = Cdb_RdPhyAddr and RsDataValidBit(6) ='0'and InstructionValidBit(6) = '1' and  Cdb_PhyRegWrite ='1' ) then
                    if ( Entemp (5) = '1' ) then
                       Sel1Rs(5) <= '1' ;
                    else
                       Sel1Rs(6)  <= '1' ;
                    end if ;
                 end if ;
                   
                if ( Buffer7RsTag = Cdb_RdPhyAddr and RsDataValidBit(7) ='0' and InstructionValidBit(7) = '1'  and  Cdb_PhyRegWrite ='1' ) then
                    if ( Entemp (6) = '1' ) then
                      Sel1Rs(6) <= '1' ;
                    else
                      Sel1Rs(7) <= '1' ;
                    end if ;
                end if ;
                
			else
                Sel1Rs <= "00000000" ;
            end if ;  
end process ;          
          
end behavctrl ; 
  
----------------------------------------------------------------------------------------------------               