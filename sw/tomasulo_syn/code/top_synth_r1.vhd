 -------------------------------------------------------------------------------
--
-- Design   : Tomasulo Top
-- Project  : Tomasulo Processor 
-- Author   : Manpreet Billing
-- Company  : University of Southern California 

-------------------------------------------------------------------------------
--
-- File         : top.vhd
-- Version      : 1.1
--
-------------------------------------------------------------------------------
-- minor revision by Ammar Sheik and Gandhi Puvvada on 7/11/2011 and 7/15/2011
--  File name: top_synth_r1.vhd
-- 
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
-- synopsys translate_off
use work.reverseAssemblyFunctionPkg.all;
-- synopsys translate_on

entity tomasulo_top is 
port (
      -- Global Clk and Resetb Signals
      Clk                   : in  std_logic ;
      Reset                 : in  std_logic ;
		
		--modified by Prasanjeet
		-- signals corresponding to Instruction memory
		fio_icache_addr_IM        : in  std_logic_vector(5 downto 0);
      fio_icache_data_in_IM     : in  std_logic_vector(127 downto 0);
      fio_icache_wea_IM         : in  std_logic; 
      fio_icache_data_out_IM    : out std_logic_vector(127 downto 0);
	   fio_icache_ena_IM		     : in  std_logic;
      
		--signals corresponding to Data memory
      fio_dmem_addr_DM          : in std_logic_vector(5 downto 0);
      fio_dmem_data_out_DM      : out std_logic_vector(31 downto 0);
		fio_dmem_data_in_DM       : in std_logic_vector(31 downto 0); --changed by PRASANJEET
      fio_dmem_wea_DM    		  : in std_logic; --changed by PRASANJEET

      Test_mode                 : in std_logic;-- for using the test mode 		
		walking_led_start         : out std_logic -- ADDED BY PRASANEJEET to enable the walking led counter 
		
		-- end modified by Prasanjeet
      
		-- COMMENTED BY PRASANJEET	
      -- modified by kapil 
      --digi_address          : in  std_logic_vector(5 downto 0); -- data mem address
      --digi_data             : out std_logic_vector(31 downto 0) -- data mem data 
      -- end modified by kapil 
     ) ;
end tomasulo_top;

-- Architecture begins here
architecture behave of tomasulo_top is

-- Component declarations


component physicalregister_file is
    generic(   
              tag_width   : integer:= 6
            );
	
    port(
			Clk 					: in std_logic;
			Resetb 	     			: in std_logic;	
			---Interface with Integer Issue queue---
			Iss_RsPhyAddrAlu		: in std_logic_vector(5 downto 0);
			Iss_RtPhyAddrAlu	    : in std_logic_vector(5 downto 0);
			---Interface with Load Store Issue queue---
			Iss_RsPhyAddrLsq	    : in std_logic_vector(5 downto 0);
			---Interface with Multiply Issue queue---
			Iss_RsPhyAddrMul		: in std_logic_vector(5 downto 0);
			Iss_RtPhyAddrMul		: in std_logic_vector(5 downto 0);
			---Interface with Divide Issue queue---
			Iss_RsPhyAddrDiv		: in std_logic_vector(5 downto 0);
			Iss_RtPhyAddrDiv		: in std_logic_vector(5 downto 0);
			---Interface with Dispatch---
			Dis_RsAddr              : in std_logic_vector(5 downto 0);
			PhyReg_RsDataRdy        : out std_logic; -- for dispatch unit
			Dis_RtAddr              : in std_logic_vector(5 downto 0);
			PhyReg_RtDataRdy        : out std_logic; -- for dispatch unit
			Dis_NewRdPhyAddr        : in std_logic_vector(5 downto 0);
			Dis_RegWrite            : in std_logic;
			---Interface with Integer Execution Unit---
			PhyReg_AluRsData		: out std_logic_vector(31 downto 0);
			PhyReg_AluRtData		: out std_logic_vector(31 downto 0);
			---Interface with Load Store Execution Unit---
		   PhyReg_LsqRsData			: out std_logic_vector(31 downto 0);
			---Interface with Multiply Execution Unit---
		   PhyReg_MultRsData		: out std_logic_vector(31 downto 0);
		   PhyReg_MultRtData		: out std_logic_vector(31 downto 0);
			---Interface with Divide Execution Unit---
		   PhyReg_DivRsData			: out std_logic_vector(31 downto 0);
		   PhyReg_DivRtData	        : out std_logic_vector(31 downto 0);
			---Interface with CDB ---
			Cdb_RdData   		    : in std_logic_vector(31 downto 0);
			Cdb_RdPhyAddr 			: in std_logic_vector(5 downto 0);
			Cdb_Valid               : in std_logic;
			Cdb_PhyRegWrite         : in std_logic;
			---Interface with Store Buffer ---
			Rob_CommitCurrPhyAddr     : in std_logic_vector(5 downto 0);
			PhyReg_StoreData        : out std_logic_vector(31 downto 0)
		  );
end component ;

-------------------------
component issue_unit is
    generic(
      Resetb_ACTIVE_VALUE : std_logic := '0'  -- ACTIVE LOW Resetb
    );         
    port(
      Clk               :   in std_logic;
      Resetb             :   in std_logic;        

      -- ready signals from each of the queues 
      
      IssInt_Rdy      :   in std_logic;
      IssMul_Rdy      :   in std_logic;
      IssDiv_Rdy      :   in std_logic;
      IssLsb_Rdy      :   in std_logic;                    
	  
      -- signal from the division execution unit to indicate that it is currently available
      Div_ExeRdy    :   in std_logic;
      
      --issue signals as acknowledgement from issue unit to each of the queues
      Iss_Int         :   out std_logic;
      Iss_Mult        :   out std_logic; 
      Iss_Div         :   out std_logic;
      Iss_Lsb         :   out std_logic                               
    );       
end	component;
-----------------------------------------------------------------
component cdb is
    generic(
           Resetb_ACTIVE_VALUE : std_logic := '0'
            );      
        port(
         Clk     :   in  std_logic;
         Resetb   :   in  std_logic;     
         
         --  from ROB 
         
         Rob_TopPtr          : in    std_logic_vector (4 downto 0 ) ;
         
         -- from integer execution unit
         Alu_RdData          :   in  std_logic_vector(31 downto 0);   
         Alu_RdPhyAddr       :   in  std_logic_vector(5 downto 0);
         Alu_BranchAddr      :   in  std_logic_vector(31 downto 0);			
         Alu_Branch          :   in  std_logic;
		 Alu_BranchOutcome   :   in  std_logic;
		 Alu_BranchUptAddr   :   in  std_logic_vector( 2 downto 0 );
         Iss_Int             :   in  std_logic; 
         Alu_BranchPredict   :   in  std_logic;			
		 Alu_JrFlush         :   in  std_logic;
		 Alu_RobTag          :   in  std_logic_vector( 4 downto 0);
		 Alu_RdWrite         :   in  std_logic;
	    -- translate_off 
         Alu_instruction       : in std_logic_vector(31 downto 0);
	    -- translate_on
         
         -- from mult execution unit
         Mul_RdData          :   in  std_logic_vector(31 downto 0);   -- mult_data coming from the multiplier
         Mul_RdPhyAddr       :   in  std_logic_vector(5 downto 0);   -- mult_prfaddr coming from the multiplier
         Mul_Done            :   in  std_logic ;  -- this is the valid bit coming from the bottom most pipeline register in the multiplier wrapper
         Mul_RobTag          :   in  std_logic_vector( 4 downto 0);
		 Mul_RdWrite         :   in  std_logic;
	     -- translate_off 
         Mul_instruction       : in std_logic_vector(31 downto 0);
	    -- translate_on
			
	     -- from div execution unit
         Div_Rddata          :   in  std_logic_vector(31 downto 0);   -- div_data coming from the divider
         Div_RdPhyAddr       :   in  std_logic_vector(5 downto 0);   -- div_prfaddr coming from the divider
         Div_Done            :   in  std_logic ; -- this is the valid bit coming from the bottom most pipeline register in the multiplier wrapper
         Div_RobTag          :   in  std_logic_vector( 4 downto 0);
		 Div_RdWrite         :   in  std_logic;
	     -- translate_off 
         Div_instruction       : in std_logic_vector(31 downto 0);
	    -- translate_on
			
			
		 -- from load buffer and store word
         Lsbuf_Data             :   in  std_logic_vector(31 downto 0);   
         Lsbuf_PhyAddr          :   in  std_logic_vector(5 downto 0);   
         Iss_Lsb              :   in  std_logic;                    
         Lsbuf_RobTag           :   in  std_logic_vector( 4 downto 0);
		 Lsbuf_SwAddr           :   in  std_logic_vector(31 downto 0);
		 Lsbuf_RdWrite           :   in  std_logic;
		 -- translate_off 
         Lsbuf_instruction       : in std_logic_vector(31 downto 0);
	     -- translate_on

         --outputs of cdb 
		-- translate_off 
         Cdb_instruction     : out std_logic_vector(31 downto 0);
	    -- translate_on
         Cdb_Valid           :   out  std_logic;
		 Cdb_PhyRegWrite     :   out  std_logic;--Cdb_PhyRegWrite
         Cdb_Data            :   out  std_logic_vector(31 downto 0);
         Cdb_RobTag          :   out  std_logic_vector(4 downto 0);--Cdb_RobTag
		 Cdb_BranchAddr      :   out  std_logic_vector(31 downto 0);
         Cdb_BranchOutcome   :   out  std_logic;
		 Cdb_BranchUpdtAddr  :   out  std_logic_vector( 2 downto 0 );
         Cdb_Branch          :   out  std_logic;
         Cdb_Flush           :   out  std_logic;
		 Cdb_RobDepth        :   out  std_logic_vector (4 downto 0 );
		 Cdb_RdPhyAddr       :   out  std_logic_vector (5 downto 0 );
		 Cdb_SwAddr          :   out  std_logic_vector (31 downto 0)
			
        );
    end component;
-------------------------------------------------------------------


component issueque is 
port (
      -- Global Clk and dispat Signals
      Clk                 : in  std_logic ;
      Resetb               : in  std_logic ;

     -- Information to be captured from the Ls Buffer
      Lsbuf_PhyAddr       : in  std_logic_vector(5 downto 0) ;
	   Lsbuf_RdWrite     : in  std_logic;

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
	  Iss_Lsb               : in std_logic;
		
	  -- Interface with the Multiply execution unit
	  Mul_RdPhyAddr         : in std_logic_vector(5 downto 0);
	  Mul_ExeRdy            : in std_logic;
	  Div_RdPhyAddr         : in std_logic_vector(5 downto 0);
	  Div_ExeRdy            : in std_logic;
	  
	  -- Interface with the Physical Register File
     Iss_RsPhyAddrAlu         : out std_logic_vector(5 downto 0) ; 
     Iss_RtPhyAddrAlu         : out std_logic_vector(5 downto 0) ; 
     
	  
	  -- Interface with the Execution unit
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
end component ;
 ------------------------------------------------------------------
component issueque_div is 
port (
      -- Global Clk and Resetb Signals
      Clk                 : in  std_logic ;
      Resetb               : in  std_logic ;

      -- Information to be captured from the Ls Buffer
      Lsbuf_PhyAddr       : in  std_logic_vector(5 downto 0) ;
	  Lsbuf_RdWrite     : in  std_logic;
     
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
      Issque_DivQueueFull          : out std_logic ;
	  Issque_DivQueueTwoOrMoreVacant : out std_logic;
	  
	  
	  -- translate_off 
      Dis_instruction    : in std_logic_vector(31 downto 0);
	  -- translate_on
     
     -- Interface with the Issue Unit
      IssDiv_Rdy           : out std_logic ;
	  Iss_Div              : in  std_logic ;
	  Iss_Int              : in  std_logic;
	  Iss_Lsb              : in  std_logic;
		
	  -- Interface with the Multiply execution unit
	  Iss_RdPhyAddrAlu      : in std_logic_vector(5 downto 0);
	  Iss_PhyRegValidAlu    : in std_logic;
	  Mul_RdPhyAddr         : in std_logic_vector(5 downto 0);
	  Mul_ExeRdy            : in std_logic;
	  Div_RdPhyAddr         : in std_logic_vector(5 downto 0);
	  Div_ExeRdy            : in std_logic;
	  
	  -- Interface with the Physical Register File
     Iss_RsPhyAddrDiv       : out std_logic_vector(5 downto 0) ; 
     Iss_RtPhyAddrDiv       : out std_logic_vector(5 downto 0) ; 
     
	  
	  -- Interface with the Execution unit
	 Iss_RdPhyAddrDiv       : out std_logic_vector(5 downto 0) ;
	 Iss_RobTagDiv          : out std_logic_vector(4 downto 0);
	 Iss_OpcodeDiv          : out std_logic_vector(2 downto 0) ; --add branch information 
	 Iss_RegWriteDiv        : out std_logic;
	 
	 -- translate_off 
     Iss_instructionDiv     : out std_logic_vector(31 downto 0);
	 -- translate_on
	  
      --  Interface with ROB 
      Cdb_Flush             : in std_logic;
      Rob_TopPtr            : in std_logic_vector ( 4 downto 0 ) ;
      Cdb_RobDepth          : in std_logic_vector ( 4 downto 0 ) 
     ) ;
end component;

----------------------------------------------------------------------------------------------
component issueque_mult is 
port (
      -- Global Clk and Resetb Signals
      Clk                 : in  std_logic ;
      Resetb               : in  std_logic ;

      -- Information to be captured from the Ls Buffer
      Lsbuf_PhyAddr       : in  std_logic_vector(5 downto 0) ;
	  Lsbuf_RdWrite     : in  std_logic;

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
      Issque_MulQueueFull          : out std_logic ;
	  Issque_MulQueueTwoOrMoreVacant : out std_logic;
     
	  -- translate_off 
      Dis_instruction    : in std_logic_vector(31 downto 0);
	  -- translate_on
      
	  -- Interface with the Issue Unit
      IssMul_Rdy           : out std_logic ;
	  Iss_Mult             : in  std_logic ;
	  Iss_Int              : in  std_logic;
	  Iss_Lsb              : in  std_logic;
		
	  -- Interface with the Multiply execution unit
	  Iss_RdPhyAddrAlu      : in std_logic_vector(5 downto 0);
	  Iss_PhyRegValidAlu    : in std_logic;
	  Mul_RdPhyAddr         : in std_logic_vector(5 downto 0);
	  Mul_ExeRdy            : in std_logic;
	  Div_RdPhyAddr         : in std_logic_vector(5 downto 0);
	  Div_ExeRdy            : in std_logic;
	 
	 -- translate_off 
     Iss_instructionMul       : out std_logic_vector(31 downto 0);
	 -- translate_on
	  
	  -- Interface with the Physical Register File
     Iss_RsPhyAddrMul       : out std_logic_vector(5 downto 0) ; 
     Iss_RtPhyAddrMul       : out std_logic_vector(5 downto 0) ; 
     
	  
	  -- Interface with the Execution unit
	 Iss_RdPhyAddrMul       : out std_logic_vector(5 downto 0) ;
	 Iss_RobTagMul          : out std_logic_vector(4 downto 0);
	 Iss_OpcodeMul          : out std_logic_vector(2 downto 0) ; --add branch information 
	 Iss_RegWriteMul        : out std_logic;
	  
      --  Interface with ROB 
      Cdb_Flush             : in std_logic;
      Rob_TopPtr            : in std_logic_vector ( 4 downto 0 ) ;
      Cdb_RobDepth          : in std_logic_vector ( 4 downto 0 ) 
     ) ;-- Information to be captured from the Write port of Physical Register file
     
end component;

------------------------------------------------------------------------------------------------
component lsq is 
port (
      -- Global Clk and Resetb Signals
      Clk                  : in  std_logic;
      Resetb                : in  std_logic;

     -- Information to be captured from the CDB (Common Data Bus)
      Cdb_RdPhyAddr        : in  std_logic_vector(5 downto 0);
	  Cdb_PhyRegWrite      : in  std_logic;
      Cdb_Valid            : in  std_logic ;

      -- Information from the Dispatch Unit 
      Dis_Opcode           : in  std_logic; 
      Dis_Immediate          : in  std_logic_vector(15 downto 0 );
      Dis_RsDataRdy        : in  std_logic;
      Dis_RsPhyAddr        : in  std_logic_vector(5 downto 0 ); 
      Dis_RobTag     : in  std_logic_vector(4 downto 0);
	  Dis_NewRdPhyAddr     : in  std_logic_vector(5 downto 0);--Dis_NewPhyAddr previous signal changed
      Dis_LdIssquenable    : in  std_logic; 
      Issque_LdStQueueFull    : out std_logic;
	  Issque_LdStQueueTwoOrMoreVacant: out std_logic;
	  
	  -- translate_off 
     Dis_instruction    : in std_logic_vector(31 downto 0);
	 -- translate_on
	 
	 -- translate_off 
     Iss_instructionLsq       : out std_logic_vector(31 downto 0);
	 -- translate_on
      -- interface with PRF
	  Iss_RsPhyAddrLsq   : out std_logic_vector(5 downto 0);
	  PhyReg_LsqRsData		   : in std_logic_vector(31 downto 0);
	  -- Interface with the Issue Unit
      Iss_LdStReady        : out std_logic ;
      Iss_LdStOpcode       : out std_logic ;  
      Iss_LdStRobTag        : out std_logic_vector(4 downto 0); --Iss_LdStRobTag previous changed
      Iss_LdStAddr         : out std_logic_vector(31 downto 0); 
      Iss_LdStIssued         : in  std_logic;
	  
      ---------------------- add appropriate value to the pin.. needed at CDB ( added by manpreet)
	  Iss_LdStPhyAddr          :   out  std_logic_vector(5 downto 0);  -- Physical address at which data is to be written in case of lw  
	  -------------------------------------------------------------------
      DCE_ReadBusy              : in  std_logic;
      Lsbuf_Done                : in std_logic;
    --  Interface with ROB 
      Cdb_Flush             : in std_logic;
      Rob_TopPtr        : in std_logic_vector (4 downto 0);
      Cdb_RobDepth             : in std_logic_vector (4 downto 0);
      SB_FlushSw           : in std_logic; 
      --SB_FlushSwTag            : in std_logic_vector (4 downto 0)    --Modified by Waleed 06/04/10
	  SB_FlushSwTag        : in std_logic_vector (1 downto 0);
	  SBTag_counter		   : in std_logic_vector (1 downto 0);    --Added by Waleed 06/04/10
      --Interface with ROB , Added by Waleed 06/04/10
	  Rob_CommitMemWrite   : in std_logic    
     );
end component;

----------------------------------------------

component dispatch_unit is
port(
      Clk           : in std_logic ;
      Resetb         : in std_logic ;
     -- Interface with Intsruction Fetch Queue
      Ifetch_Instruction : in std_logic_vector(31 downto 0); -- instruction from IFQ
      Ifetch_PcPlusFour  : in std_logic_vector(31 downto 0); -- the IC+4 value carried forward for jumping and branching
      Ifetch_EmptyFlag   : in std_logic;	-- signal showing that the ifq is empty,hence stopping any decoding and dispatch of the current if_inst
      Dis_Ren            : out std_logic;  -- stalling caused due to issue queue being full
      Dis_JmpBrAddr      : out std_logic_vector(31 downto 0); -- the jump or branch address
      Dis_JmpBr          : out std_logic; -- validating that address to cause a jump or branch
      Dis_JmpBrAddrValid : out std_logic; -- to tell if the jump pr branch address is valid or not.. ll be invalid for "jr $rs" inst
    -------------------------------------------------------------------------
    -- Interface with branch prediction buffer
   
      Dis_CdbUpdBranch          : out std_logic; -- indicates that a branch is processed by the top of the rob and gives the pred(wen to bpb)
      Dis_CdbUpdBranchAddr      : out std_logic_vector(2 downto 0);-- indiactes the last 3 bit addr of the branch beign processed by top
      Dis_CdbBranchOutcome      : out std_logic; -- indiacates the outocome of the branch to the bpb  
    
      Bpb_BranchPrediction      : in std_logic;  --This bit tells the dispatch what the prediction actually based on bpb state-mc
 
      Dis_BpbBranchPCBits       : out std_logic_vector(2 downto 0);--indiaces the 3 least sig bits of the current instr being dis
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
   -- interface with checkpoint module
      Dis_CfcRsAddr       :  out std_logic_vector(4 downto 0);-- Indicates the Rs Address to be read from Reg file
      Dis_CfcRtAddr       :  out std_logic_vector(4 downto 0); -- Indicates the Rt Address to be read from Reg file
   	  Dis_CfcRdAddr       :  out std_logic_vector(4 downto 0); -- Indicates the Rd Address to be written by instruction
      -- goes to Dis_CfcRdAddr of ROB too
		
	    Cfc_RsPhyAddr       : in std_logic_vector(5 downto 0); -- Rs Physical register Tag corresponding to Rs Addr
      Cfc_RtPhyAddr       : in std_logic_vector(5 downto 0); -- Rt Physical register Tag corresponding to Rt Addr
	    Cfc_RdPhyAddr       : in std_logic_vector(5 downto 0); -- Rd Old Physical register Tag corresponding to Rd Addr
	    Cfc_Full            : in std_logic ;
         
	    Dis_CfcBranchTag       : out std_logic_vector(4 downto 0) ; -- Indicats the rob tag of the branch for which checkpoint is to be done
	    Dis_CfcRegWrite        : out std_logic; -- cfc and ROB
	    Dis_CfcNewRdPhyAddr    : out std_logic_vector(5 downto 0);
	    Dis_CfcBranch          : out std_logic;
		 Dis_CfcInstValid       : out std_logic;
	 
   --------------------------------------------------------------------------------
-- physical register interface
      PhyReg_RsDataRdy        : in std_logic ; -- Indicating if the value of Rs is ready at the physical tag location
      PhyReg_RtDataRdy        : in std_logic ; -- Indicating if the value of Rt is ready at the physical tag location	  

   -- interface with issue queues 
     -- translate_off 
      Dis_Instruction    : out std_logic_vector(31 downto 0);
     -- translate_on
      
      Dis_RegWrite        : out std_logic;      
	    Dis_RsDataRdy       : out std_logic;-- Tells the queues the validity of the data given by the dispatch itself
      Dis_RtDataRdy       : out std_logic;--Tells the queues the validity of the data given by the dispatch itself
      Dis_RsPhyAddr       : out std_logic_vector(5 downto 0);--This tells the tag of the operands if the data is not in the complete or commit phase
      Dis_RtPhyAddr       : out std_logic_vector(5 downto 0);--This tells the tag of the operands if the data is not in the complete or commit phase
    
      Dis_RobTag          : out std_logic_vector(4 downto 0);
	    Dis_Opcode          : out std_logic_vector(2 downto 0);--Gives the Opcode of the given instruction
      
	    Dis_IntIssquenable     : out std_logic;--Informs the respective issue queue that the dispatch is going to enter a new entry
      Dis_LdIssquenable      : out std_logic;--Informs the respective issue queue that the dispatch is going to enter a new entry
      Dis_DivIssquenable     : out std_logic;--Informs the respective issue queue that the dispatch is going to enter a new entry
      Dis_MulIssquenable     : out std_logic;--Informs the respective issue queue that the dispatch is going to enter a new entry
      Dis_Immediate          : out std_logic_vector(15 downto 0);
      Issque_IntQueueFull       : in std_logic;
      Issque_LdStQueueFull      : in std_logic;
      Issque_DivQueueFull       : in std_logic;
      Issque_MulQueueFull       : in std_logic;
      Issque_IntQueTwoOrMoreVacant       : in std_logic;
      Issque_LdStQueTwoOrMoreVacant      : in std_logic;
      Issque_DivQueTwoOrMoreVacant       : in std_logic;
      Issque_MulQueTwoOrMoreVacant       : in std_logic;
      	   
		  Dis_BranchOtherAddr : out std_logic_vector(31 downto 0);
      Dis_BranchPredict   : out std_logic;
      Dis_Branch          : out std_logic;
      Dis_BranchPCBits    : out std_logic_vector(2 downto 0);
      Dis_JrRsInst        : out std_logic;
      Dis_JalInst         : out std_logic ; -- Indicating whether there is a call instruction
	    Dis_Jr31Inst        : out std_logic;
	    
   ----------------------------------------------------------------------------------

   ---- interface with the FRL---- accessed in first sage only so dont need NaerlyEmpty signal from Frl
      Frl_RdPhyAddr       : in std_logic_vector(5 downto 0); -- Physical tag for the next available free register
      Dis_FrlRead         : out std_logic ; -- Indicating if free register given by FRL is used or not	  
	    Frl_Empty           : in std_logic;
	   
   ----------------------------------------------------------------------------------

   ---- interface with the RAS----
      Dis_RasJalInst      : out std_logic ; -- Indicating whether there is a call instruction
	    Dis_RasJr31Inst     : out std_logic;
	    Dis_PcPlusFour      : out std_logic_vector(31 downto 0);
	    Ras_Addr            : in std_logic_vector(31 downto 0);
	  
   ----------------------------------------------------------------------------------

   ---- interface with the rob----
      Dis_PrevPhyAddr   : out std_logic_vector(5 downto 0);
	    Dis_NewRdPhyAddr  : out std_logic_vector(5 downto 0);  -- send to integer queue , cfc and
	    Dis_RobRdAddr     :  out std_logic_vector(4 downto 0); -- Indicates the Rd Address to be written by instruction                                                      -- send to Physical register file too.. so that he can make data ready bit "0"
	    Dis_InstValid     : out std_logic ;
	    Dis_InstSw        : out std_logic ;
	    Dis_SwRtPhyAddr   : out std_logic_vector(5 downto 0);
      Rob_BottomPtr     : in std_logic_vector(4 downto 0);
      Rob_Full          : in std_logic;
      Rob_TwoOrMoreVacant          : in std_logic
   
      );
  end component;




------------------------------------------------------------------


component multiplier is
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
end component;
-----------------------------------------------------------------



component ALU is
generic  (   
         tag_width   				: integer := 6
         );
port (
		PhyReg_AluRsData	   : in  std_logic_vector(31 downto 0);
		PhyReg_AluRtData		: in  std_logic_vector(31 downto 0);
		Iss_OpcodeAlu		   : in  std_logic_vector(2 downto 0);
		Iss_RobTagAlu           : in  std_logic_vector(4 downto 0);
		Iss_RdPhyAddrAlu	      : in  std_logic_vector(5 downto 0);
		Iss_BranchAddrAlu       : in  std_logic_vector(31 downto 0);		
      Iss_BranchAlu		      : in  std_logic;
		Iss_RegWriteAlu         : in  std_logic;
		Iss_BranchUptAddrAlu    : in  std_logic_vector(2 downto 0);
		Iss_BranchPredictAlu    : in  std_logic;
		Iss_JalInstAlu          : in  std_logic;
		Iss_JrInstAlu           : in  std_logic;
		Iss_JrRsInstAlu         : in  std_logic;
		Iss_ImmediateAlu        : in std_logic_vector(15 downto 0);
        -- translate_off 
        Iss_instructionAlu       : in std_logic_vector(31 downto 0);
	    -- translate_on		
		Alu_RdData           : out  std_logic_vector(31 downto 0);   
      Alu_RdPhyAddr        : out  std_logic_vector(5 downto 0);
      Alu_BranchAddr       : out  std_logic_vector(31 downto 0);			
      Alu_Branch           : out  std_logic;
	   Alu_BranchOutcome    : out  std_logic;
	    -- translate_off 
        Alu_instruction       : out std_logic_vector(31 downto 0);
	    -- translate_on	
		Alu_RobTag           : out  std_logic_vector(4 downto 0);
	   Alu_BranchUptAddr    : out  std_logic_vector( 2 downto 0 ); 
      Alu_BranchPredict    : out  std_logic;	
		Alu_RdWrite      : out  std_logic;
		Alu_JrFlush          : out  std_logic
		);
		end component;
-------------------------------------------------------------------

component divider is
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
end component;
    
--------------------------------------------------------------------


component inst_cache
generic (
         DATA_WIDTH     : integer := 128; --DATA_WIDTH_CONSTANT; -- defined as 128 in the instr_stream_pkg; 
         ADDR_WIDTH     : integer := 6 --ADDR_WIDTH_CONSTANT  -- defined as 6 in the instr_stream_pkg; 
        );
port (
      Clk           : in std_logic; 
      Resetb       : in std_logic;
      read_cache    : in std_logic;
      abort_prev_read : in std_logic; -- will be used under jump or successful branch
      addr          : in std_logic_vector (31 downto 0);
      cd0           : out std_logic_vector (31 downto 0);
      cd1           : out std_logic_vector (31 downto 0);
      cd2           : out std_logic_vector (31 downto 0);
      cd3           : out std_logic_vector (31 downto 0);
		-- synopsys translate_off
		registered_addr : out std_logic_vector(31 downto 0);
		-- synopsys translate_on	
      read_hit      : out std_logic;
	  
      fio_icache_addr_a        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      fio_icache_data_in_a     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      fio_icache_wea           : in  std_logic; 
      fio_icache_data_out_a    : out std_logic_vector(DATA_WIDTH-1 downto 0);
	   fio_icache_ena		   : in  std_logic	  
     ); 
end component;
-----------------------------------------------------------------------
component i_fetch_q is  

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
end component ; 

---------------------------------------------------
component bpb is
   port (
         Clk                  : in std_logic;
         Resetb               : in std_logic; 
         ---- rob -------
            Dis_CdbUpdBranch            : in  std_logic; -- indicates that a branch is processed by the top of the rob and gives the pred(wen to bpb)
            Dis_CdbUpdBranchAddr     : in std_logic_vector(2 downto 0);-- indiactes the last 3 bit addr of the branch beign processed by top
            Dis_CdbBranchOutcome     : in std_logic; -- indiacates the outocome of the branch to the bpb 0 nottaken 1 taken 
         ------------------ 
         ---- dispatch --------------
            Bpb_BranchPrediction    : out std_logic;  --This bit tells the dispatch what the prediction actually based on bpb state-mc
            Dis_BpbBranchPCBits         : in std_logic_vector(2 downto 0) ;--indiaces the 3 least sig bits of the current instr being dis
            Dis_BpbBranch               : in std_logic -- indiactes a branch instr (ren to the bpb)
         ---------------------------
         );
end component;




-------------------
component ls_buffer is
port (
	     Clk				    : in  std_logic;
	    Resetb			        : in  std_logic;
		
	   --  from ROB  -- for fulsing the instruction in this buffer if appropriate.
       Cdb_Flush            : in std_logic ;
       Rob_TopPtr       : in std_logic_vector (4 downto 0 ) ;
       Cdb_RobDepth            : in std_logic_vector (4 downto 0 ) ;
	   
	   -- interface with lsq
	    Iss_LdStReady        : in std_logic ;
      Iss_LdStOpcode       : in std_logic ;  -- 1 = lw , 0 = sw
      Iss_LdStRobTag        : in std_logic_vector(4 downto 0); 
      Iss_LdStAddr         : in std_logic_vector(31 downto 0); 
      Iss_LdStData         : in std_logic_vector(31 downto 0);-- data to be written to memory in the case of sw
	  Iss_LdStPhyAddr          :   in  std_logic_vector(5 downto 0);  
	   -- translate_off 
     DCE_instruction    : in std_logic_vector(31 downto 0);
	 -- translate_on
	 
	 -- translate_off 
     Iss_instructionLsq       : in std_logic_vector(31 downto 0);
	 -- translate_on
     ---- interface with data cache emulator ----------------
      DCE_PhyAddr          :   in  std_logic_vector(5 downto 0);  
	  DCE_Opcode          : in std_logic ;
      DCE_RobTag          : in std_logic_vector(4 downto 0);  
      DCE_Addr            : in std_logic_vector(31 downto 0);    
      DCE_MemData: in std_logic_vector (31 downto 0 ) ; --  data from data memory in the case of lw
      DCE_ReadDone           : in std_logic ; -- data memory (data cache) reporting that read finished  -- from  ls_buffer_ram_reg_array -- instance name DataMem
      Lsbuf_LsqTaken         : out  std_logic; -- handshake signal to ls_queue
      Lsbuf_DCETaken         : out  std_logic; -- handshake signal to ls_queue
	  Lsbuf_Full         : out  std_logic; -- handshake signal to ls_queue
		-- interface with issue unit
	   -- from load buffer and store word
	         
	 -- translate_off 
     Lsbuf_instruction       : out std_logic_vector(31 downto 0);
	 -- translate_on
         Lsbuf_Ready        : out std_logic ;    
------------- changed as per CDB -------------		 
		Lsbuf_Data             :   out  std_logic_vector(31 downto 0);   
         Lsbuf_PhyAddr          :   out  std_logic_vector(5 downto 0);   
          Lsbuf_RobTag       : out std_logic_vector(4 downto 0) ;            
        
			Lsbuf_SwAddr           :   out std_logic_vector(31 downto 0);
			Lsbuf_RdWrite           :   out  std_logic;
      ------------------------------------------------------------
     
     
      Iss_Lsb      : in  std_logic  -- return signal from the issue unit
		);
end component ;
-------------------------------------------------------------

component  ls_buffer_ram_reg_array is

generic (ADDR_WIDTH: integer := 6; DATA_WIDTH: integer := 32);

port (
	Clka      : in  std_logic;
	wea       : in  std_logic;
	addra     : in  std_logic_vector  (ADDR_WIDTH-1 downto 0);
	dia       : in  std_logic_vector  (DATA_WIDTH-1 downto 0);
	addrb     : in  std_logic_vector  (ADDR_WIDTH-1 downto 0);
	dob       : out std_logic_vector  (DATA_WIDTH-1 downto 0);
	rea       : in std_logic ;
	mem_wri   : out std_logic ;
	mem_exc   : out std_logic ;
	mem_read  : out std_logic 
	
	-- modified by kapil 
	--addrc : in std_logic_vector(ADDR_WIDTH-1 downto 0);
	--doc : out std_logic_vector(DATA_WIDTH-1 downto 0)
	-- end modified by kapil 
	
	
	);

end component ;
----------------------------------------------------------------------------------------------------------------------------------
component rob is
		port(--inputs--
			  Clk				 :in std_logic;
			  Resetb			   :in std_logic;
			  
			  -- Interface with CDB
			  Cdb_Valid		   : in std_logic;                             -- signal to tell that the values coming on CDB is valid                             
			  Cdb_RobTag	   : in std_logic_vector(4 downto 0);          -- Tag of the instruction which the the CDB is broadcasting
			  Cdb_SwAddr      : in std_logic_vector (31 downto 0);      -- to give the store wordaddr
				  
			  -- Interface with Dispatch unit	
			  Dis_InstSw                 : in std_logic;                      --  signal that tells that the signal being dispatched is a store word
			  Dis_RegWrite                : in std_logic;                      --  signal telling that the instruction is register writing instruction
			  Dis_InstValid              : in std_logic;                      --  Signal telling that Dispatch unit is giving valid information
			  Dis_RobRdAddr                  : in std_logic_vector(4 downto 0);   --  Actual Desitnation register number of the instruction being dispatched
			  Dis_NewRdPhyAddr                 : in std_logic_vector (5 downto 0);   --  Current Physical Register number of dispatching instruction taken by the dispatch unit from the FRL
			  Dis_PrevPhyAddr                  : in std_logic_vector (5 downto 0);    --  Previous Physical Register number of dispatch unit taken from CFC
			  Dis_SwRtPhyAddr               : in std_logic_vector (5 downto 0); -- Physical Address number from where store word has to take the data
			  Rob_Full                    : out std_logic;
			  Rob_TwoOrMoreVacant                      : out std_logic;
			  
			  -- Interface with store buffer
			  SB_Full                     : in std_logic;                     -- Tells the ROB that the store buffer is full
			  Rob_SwAddr                  : out std_logic_vector (31 downto 0);   -- The address in case of sw instruction
			  Rob_CommitMemWrite                : out std_logic;                        -- Signal to enable the memory for writing purpose  
			 -- Rob_FlushSw                 : out std_logic;  -- for address buffer of lsq 
			 -- Rob_FlushSwTag              : out std_logic_vector (5 downto 0);
			  -- Takes care of flushing the address buffer
			  -- Interface with FRL and CFC
			  -- translate_off 
				Dis_instruction    : in std_logic_vector(31 downto 0); 
        Rob_Instruction     : out std_logic_vector(31 downto 0);
	      -- translate_on
	        
			  Rob_TopPtr                  : out std_logic_vector (4 downto 0);  -- Gives the value of TopPtr pointer of ROB
		      Rob_BottomPtr               : out std_logic_vector (4 downto 0);
			  Rob_Commit                  : out std_logic;          -- FRL needs it to to add pre phy to free list cfc needs it to remove the latest cheackpointed copy
		      Rob_CommitRdAddr                 : out std_logic_vector(4 downto 0);           -- Architectural register number of committing instruction
		      Rob_CommitRegWrite               : out std_logic;					          --Indicates that the instruction that is being committed is a register wrtiting instruction
		      Rob_CommitPrePhyAddr                 : out std_logic_vector(5 downto 0);			  --pre physical addr of committing inst to be added to FRL
		      Rob_CommitCurrPhyAddr                : out std_logic_vector (5 downto 0);   -- Current Register Address of committing instruction to update retirment rat			  
		      Cdb_Flush  		         :in std_logic;                              --Flag indicating that current instruction is mispredicted or not
		      Cfc_RobTag             : in std_logic_vector (4 downto 0)  -- Tag of the instruction that has the checkpoint
			  );
			  
end component;
----------------------------------------------------------------------------------------------------------------------------------
component cfc is
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
		Dis_Jr31Inst             :in std_logic;                              --Flag indicating if the current instruction is Jr 31 or not
		
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
end component;
---------------------------------------------------------------------------------
component Frl is 
generic (WIDE  : integer := 6;DEEP  : integer:=16;PTRWIDTH:integer:=5);
port (
--Inputs
Clk            : in  std_logic ;
Resetb          : in  std_logic ;
Cdb_Flush      : in  std_logic ;
--Interface with Rob
Rob_CommitPrePhyAddr 	   : in  std_logic_vector(WIDE-1 downto 0) ;
Rob_Commit    : in  std_logic ;
Rob_CommitRegWrite : in std_logic;
Cfc_FrlHeadPtr: in  std_logic_vector(PTRWIDTH-1 downto 0) ;
--Intreface with Dis_FrlRead unit
Frl_RdPhyAddr        : out  std_logic_vector(WIDE-1 downto 0) ;
Dis_FrlRead    : in  std_logic ;
Frl_Empty      : out  std_logic ;
--Frl_NearEmpty  : out  std_logic;
--Interface with Previous Head Pointer Stack
Frl_HeadPtr    : out  std_logic_vector(PTRWIDTH-1 downto 0) 
);
end component;
---------------------------------------------------------------------------------
component ras is

generic (size  : integer :=4);

port(
	--global signals
	Resetb 					: in std_logic;
	Clk						: in std_logic;
	 
	-- Interface with Dispatch
	--inputs
	Dis_PcPlusFour			: in std_logic_vector(31 downto 0); 	-- the PC+4 value carried forward for storing in RAS
	Dis_RasJalInst				: in std_logic;							-- set to 1 if instruction is JAL
	Dis_RasJr31Inst				: in std_logic;							-- set to 1 if instruction is JR
	--outputs
	Ras_Addr				: out std_logic_vector(31 downto 0) 	-- The address given by RAS for JR
	
	);
	
end component;
---------------------------------------------------------------------------------
component store_buffer is
port ( 
	  -- Global Signals
	    Clk            : in  std_logic ;
        Resetb          : in  std_logic ;
				
	  --interface with ROB
		Rob_SwAddr  : in std_logic_vector (31 downto 0);
		PhyReg_StoreData  : in std_logic_vector (31 downto 0);
		Rob_CommitMemWrite      : in std_logic;
		SB_Full           : out std_logic;
		SB_Stall 		   : out std_logic;
		Rob_TopPtr   :in std_logic_vector(4 downto 0);
			-- interface with lsq
		  SB_FlushSw            : out std_logic;
		  --SB_FlushSwTag        : out std_logic_vector(4 downto 0); Modified by Waleed 06/04/10
		  SB_FlushSwTag        : out std_logic_vector(1 downto 0);
		  SBTag_counter		   : out std_logic_vector (1 downto 0); --Added by Waleed 06/04/10
		
	   --interface with Data Cache Emulator
	    SB_DataDmem  : out std_logic_vector (31 downto 0);
		SB_AddrDmem  : out std_logic_vector (31 downto 0);
		SB_DataValid : out std_logic;
		DCE_WriteBusy           : in std_logic;
		DCE_WriteDone :in std_logic
	   --interface with Load Store Buffer ( no forwarding now)
	  --  lsq_addr_dmem  : in std_logic_vector (5 downto 0);
	--	Lsbuf_Data_dmem  : out std_logic_vector (31 downto 0);
	--	Lsbuf_Data_valid : out std_logic
	  );   
end component;
---------------------------------------------------------------------------------
component data_cache is 
generic (
         DATA_WIDTH     : integer := 32; --DATA_WIDTH_CONSTANT; -- defined as 128 in the instr_stream_pkg; 
         ADDR_WIDTH     : integer := 6 --ADDR_WIDTH_CONSTANT  -- defined as 6 in the instr_stream_pkg; 
        );
port (
      Clk           : in std_logic; 
      Resetb       : in std_logic;
DCE_ReadCache    : in std_logic;
      -- Abort_PrevRead : in std_logic; -- will be used under jump or successful branch -- commented out on July 15, 2011
      --addr          : in std_logic_vector (5 downto 0);
	  Iss_LdStOpcode       : in std_logic ;  
      Iss_LdStRobTag        : in std_logic_vector(4 downto 0); 
      Iss_LdStAddr         : in std_logic_vector(31 downto 0); 
	  --- added --------
	  Iss_LdStPhyAddr          :   in  std_logic_vector(5 downto 0);  
   
	  ------------------
      Lsbuf_DCETaken       : in std_logic;
	  
	  Cdb_Flush                : in std_logic ; -- Cdb_Flush signal
	  Rob_TopPtr              : in std_logic_vector(4 downto 0);
	  Cdb_RobDepth                : in std_logic_vector(4 downto 0);
	  
      SB_WriteCache   : in std_logic ;
      SB_AddrDmem       : in std_logic_vector (31 downto 0);
      SB_DataDmem       : in std_logic_vector (31 downto 0);
	   -- translate_off 
     DCE_instruction    : out std_logic_vector(31 downto 0);
	 -- translate_on
	 
	 -- translate_off 
     Iss_instructionLsq       : in std_logic_vector(31 downto 0);
	 -- translate_on
	  
       --data_out      : out std_logic_vector (31 downto 0);
	    DCE_Opcode          : out std_logic ;
      DCE_RobTag          : out std_logic_vector(4 downto 0);  
      DCE_Addr            : out std_logic_vector(31 downto 0);    
      DCE_MemData            : out std_logic_vector (31 downto 0 ) ; --  data from data memory in the case of lw
      ------------------new pin added for CDB-----------
	   
      DCE_PhyAddr          :   out std_logic_vector(5 downto 0);
------------------------------------------------------------	  
		-- synopsys translate_off
		registered_addr : out std_logic_vector(5 downto 0);
		registered_SB_AddrDmem : out std_logic_vector(5 downto 0);
		-- synopsys translate_on	
    DCE_ReadDone      : out std_logic;
	  DCE_WriteDone    : out std_logic;
	  DCE_ReadBusy     : out std_logic;
	  DCE_WriteBusy       : out std_logic
    --  fio_icache_addr_a        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    --  fio_icache_data_in_a     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    --  fio_icache_wea           : in  std_logic; 
    --  fio_icache_data_out_a    : out std_logic_vector(DATA_WIDTH-1 downto 0);
	--  fio_icache_ena		   : in  std_logic	  
     ); 
end component;
---------------------------------------------------------------------------------
-- change the lsbuf instance and DCE instance .. component declaration is fine
-----------------------------------------------------------------------
    signal  Alu_RdData,Alu_BranchAddr : std_logic_vector(31 downto 0);
	 signal  Alu_RdPhyAddr  : std_logic_vector(5 downto 0);
	 signal  Alu_Branch ,Alu_BranchOutcome,Alu_BranchPredict,Alu_RdWrite,Alu_JrFlush : std_logic;
    signal  Alu_RobTag :std_logic_vector(4 downto 0);
	 signal	Alu_BranchUptAddr :std_logic_vector(2 downto 0);
				
	 signal	Bpb_BranchPrediction :std_logic;
				
	 signal	Cdb_Valid,Cdb_PhyRegWrite,Cdb_BranchOutcome,Cdb_Branch,Cdb_Flush :std_logic;
	 signal	Cdb_Data,Cdb_BranchAddr,Cdb_SwAddr :std_logic_vector(31 downto 0);
	 signal	Cdb_RobTag,Cdb_RobDepth :std_logic_vector(4 downto 0); 
	 signal	Cdb_RdPhyAddr : std_logic_vector(5 downto 0);
	 signal	Cdb_BranchUpdtAddr :std_logic_vector(2 downto 0);
				
	 signal	Cfc_RdPhyAddr,Cfc_RsPhyAddr,Cfc_RtPhyAddr : std_logic_vector(5 downto 0);
	 signal	Cfc_WalkBkwd,Cfc_WalkFwd,Cfc_Checkpoint,Cfc_Commit :std_logic;
	 signal	Cfc_RobTag,Cfc_BranchTag : std_logic_vector(4 downto 0);
				
	 signal	DCE_Opcode,DCE_ReadDone,DCE_WriteDone,DCE_ReadBusy,DCE_WriteBusy :std_logic;
	 signal	DCE_RobTag :std_logic_vector(4 downto 0);
	 signal	DCE_Addr,DCE_MemData :std_logic_vector(31 downto 0);
	 signal	DCE_PhyAddr : std_logic_vector(5 downto 0);
				
    signal	Dis_Ren,Dis_JmpBr,Dis_JmpBrAddrValid,Dis_CdbUpdBranch,Dis_CdbBranchOutcome :std_logic;
	 signal	Dis_JmpBrAddr,Dis_BranchOtherAddr,Dis_PcPlusFour :std_logic_vector(31 downto 0);
	 signal	Dis_CdbUpdBranchAddr,Dis_BranchPCBits,Dis_BpbBranchPCBits,Dis_Opcode :std_logic_vector(2 downto 0);
	 signal	Dis_CfcBranch,Dis_CfcRegWrite,Dis_Branch,Dis_BpbBranch,Dis_RegWrite,Dis_RsDataRdy,Dis_RtDataRdy,Dis_BranchPredict,Dis_JrRsInst :std_logic;
	 signal	Dis_CfcRsAddr,Dis_CfcRtAddr,Dis_CfcRdAddr,Dis_RobRdAddr,Dis_CfcBranchTag ,Dis_RobTag:std_logic_vector(4 downto 0);
	 signal	Dis_RsPhyAddr,Dis_RtPhyAddr,Dis_PrevPhyAddr,Dis_CfcNewRdPhyAddr, Dis_NewRdPhyAddr,Dis_SwRtPhyAddr:std_logic_vector(5 downto 0);
	 signal	Dis_IntIssquenable,Dis_LdIssquenable,Dis_DivIssquenable,Dis_MulIssquenable ,Dis_FrlRead:std_logic;
	 signal	Dis_Immediate :std_logic_vector(15 downto 0);
	 signal	Dis_JalInst,Dis_RasJalInst,Dis_RasJr31Inst,Dis_Jr31Inst,Dis_CfcInstValid,Dis_InstValid,Dis_InstSw:std_logic;
		
	 signal Dis_instruction,Alu_instruction,Mul_instruction ,Div_instruction,Lsbuf_instruction, Cdb_instruction			:std_logic_vector(31 downto 0);
	 signal Iss_instructionAlu,Iss_instructionMul,Iss_instructionDiv,Iss_instructionLsq,DCE_instruction : std_logic_vector(31 downto 0);
	 
    signal  Div_RdPhyAddr :std_logic_vector(5 downto 0);
    signal  Div_RdWrite,Div_Done,Div_ExeRdy :std_logic;
	 signal	Div_RobTag :std_logic_vector(4 downto 0);
	 signal	Div_Rddata :std_logic_vector(31 downto 0);
				
	 signal	Frl_RdPhyAddr:std_logic_vector(5 downto 0);
	 signal Frl_HeadPtr :std_logic_vector(4 downto 0);
	 signal	Frl_Empty :std_logic;
				
	 signal	Ifetch_Instruction,Ifetch_PcPlusFour,Ifetch_WpPcIn:std_logic_vector(31 downto 0);
	 signal	Ifetch_EmptyFlag,Ifetch_ReadCache,Ifetch_AbortPrevRead :std_logic;
	 signal	wp_report,rp_report,depth_report :std_logic_vector(4 downto 0);
				
	 signal	Cache_Cd0,Cache_Cd1,Cache_Cd2,Cache_Cd3 :std_logic_vector(31 downto 0);
	 signal	Cache_ReadHit :std_logic;
	-- signal	fio_icache_data_out_IM :std_logic_vector(127 downto 0);
				
	 signal	Iss_Int,Iss_Mult,Iss_Div,Iss_Lsb :std_logic;
				
	 signal	Issque_IntQueueFull,IssInt_Rdy,Iss_BranchAlu, Iss_RegWriteAlu:std_logic;
	 signal	Iss_RsPhyAddrAlu,Iss_RtPhyAddrAlu,Iss_RdPhyAddrAlu :std_logic_vector(5 downto 0);
	 signal	Iss_RobTagAlu :std_logic_vector(4 downto 0);
	 signal	Iss_OpcodeAlu ,Iss_BranchUptAddrAlu:std_logic_vector(2 downto 0);
	 signal	Iss_BranchAddrAlu :std_logic_vector(31 downto 0);
	 signal	Iss_BranchPredictAlu,Iss_JalInstAlu,Iss_JrInstAlu,Iss_JrRsInstAlu:std_logic;
	 signal Iss_ImmediateAlu : std_logic_vector(15 downto 0);
	 			
	 signal	Issque_DivQueueFull,IssDiv_Rdy,Iss_RegWriteDiv :std_logic;
	 signal	Iss_RsPhyAddrDiv,Iss_RtPhyAddrDiv,Iss_RdPhyAddrDiv :std_logic_vector(5 downto 0);
	 signal	Iss_RobTagDiv ,Iss_RobTagMul:std_logic_vector(4 downto 0);
	 signal	Iss_OpcodeDiv,Iss_OpcodeMul :std_logic_vector(2 downto 0);
	 
	 signal Issque_IntQueueTwoOrMoreVacant,Issque_MulQueueTwoOrMoreVacant,Issque_DivQueueTwoOrMoreVacant,Issque_LdStQueueTwoOrMoreVacant :std_logic;			
	 signal	Issque_MulQueueFull,IssMul_Rdy,Iss_RegWriteMul:std_logic;
	 signal	Iss_RsPhyAddrMul,Iss_RtPhyAddrMul,Iss_RdPhyAddrMul :std_logic_vector(5 downto 0);
	 
	 signal	Lsbuf_LsqTaken,Lsbuf_DCETaken,Lsbuf_Full,IssLsb_Rdy,Lsbuf_RdWrite:std_logic;
	 signal	Lsbuf_Data,Lsbuf_SwAddr,Iss_LdStAddr,Iss_LdStData:std_logic_vector(31 downto 0);
	 signal	Lsbuf_PhyAddr :std_logic_vector(5 downto 0);
	 signal	Lsbuf_RobTag:std_logic_vector(4 downto 0);
				
	 signal	Iss_LdStQueueFull,Iss_LdStReady,Iss_LdStOpcode :std_logic;
	 signal	Iss_RsPhyAddrLsq,Iss_RtPhyAddrLsq,Iss_LdStPhyAddr :std_logic_vector(5 downto 0);
	 signal	Iss_LdStRobTag ,Mul_RobTag:std_logic_vector(4 downto 0);
				
	 signal	Mul_RdPhyAddr ,Phs_PrevHeadPtr:std_logic_vector(5 downto 0);
	 signal	Mul_RdWrite,Mul_Done :std_logic ;
	 signal	Mul_RdData : std_logic_vector(31 downto 0);
				
	 signal	PhyReg_RsDataRdy,PhyReg_RtDataRdy :std_logic ;
	 signal	PhyReg_AluRsData,PhyReg_AluRtData,PhyReg_LsqRsData,PhyReg_LsqRtData:std_logic_vector(31 downto 0);
	 signal	PhyReg_MultRsData,PhyReg_MultRtData,PhyReg_DivRsData,PhyReg_DivRtData,PhyReg_StoreData,Ras_Addr:std_logic_vector(31 downto 0);
				
	 signal	Rob_Full,Rob_CommitMemWrite ,Rob_Commit,Rob_CommitRegWrite,Rob_WalkingRegWrite:std_logic;
	 signal	Rob_SwAddr, Rob_Instruction :std_logic_vector(31 downto 0);
	 signal	Rob_TopPtr,Rob_BottomPtr ,Rob_CommitRdAddr,Rob_WalkingRdAddr:std_logic_vector(4 downto 0);
	 signal	Rob_CommitPrePhyAddr,Rob_CommitCurrPhyAddr,Rob_WalkingPrePhyAddr,Rob_WalkingCurrPhyAddr:std_logic_vector(5 downto 0);
	 signal	Rob_Walking,Rob_WalkBkd,Rob_WalkFwd,Rob_TwoOrMoreVacant :std_logic;
				
	 signal	SB_Full,SB_Stall,SB_FlushSw,SB_DataValid :std_logic ;
	 --signal	SB_FlushSwTag :std_logic_vector(4 downto 0); Modified by Waleed 06/04/10
	 signal SB_FlushSwTag :std_logic_vector(1 downto 0);
	 signal SBTag_counter :std_logic_vector(1 downto 0); --Added by Waleed 06/04/10
	 
	 signal	SB_DataDmem,SB_AddrDmem :std_logic_vector(31 downto 0);
	
     signal Iss_LdStIssued,Lsbuf_Done,DCE_ReadCache,SB_InputValid,Cfc_Full:std_logic;	-- July 15, 2011 Gandhi: Removed Abort_PrevRead		
	 -- signal Iss_LdStIssued,Lsbuf_Done,DCE_ReadCache,Abort_PrevRead ,SB_InputValid,Cfc_Full:std_logic;		
	 signal Cfc_FrlHeadPtr : std_logic_vector(4 downto 0);
	-- signal ifetch_instruction_sig : std_logic_vector(31 downto 0);
	-- signal ifetch_instruction_string_sig : string(1 to 24) := "Empty_Empty_Empty_Empty"; 	
	-- translate_off
	signal IfetchInst_string : string(1 to 24) := (others => ' ');
	signal DisInst_string : string(1 to 24) := (others => ' ');
	signal IntQueueInst_string : string(1 to 24) := (others => ' ');
	signal MulQueueInst_string : string(1 to 24) := (others => ' ');
	signal DivQueueInst_string : string(1 to 24) := (others => ' ');
	signal LdStQueueInst_string : string(1 to 24) := (others => ' ');
	signal CdbInst_string : string(1 to 24) := (others => ' ');
	signal RobInst_string : string(1 to 24) := (others => ' ');
	-- translate_on
	 signal Resetb : std_logic ;
	 signal Dmem_ReadAddr : std_logic_vector(31 downto 0);
	 signal Dmem_WriteAddr : std_logic_vector(31 downto 0);
	 signal SB_WriteCache: std_logic;
	 signal Dmem_WriteData : std_logic_vector(31 downto 0);
	 signal walking_led_counter : std_logic_vector(24 downto 0);
        
	  begin           
-----------------------------------------------------------------------------------------------
-----  Components Interface  -------------------
-----------------------------------------------------------------------------------------------
-- synopsys translate_off
--ifetch_instruction_string_sig <= reverse_Assembly(ifetch_instruction_sig);
-- synopsys translate_on

Resetb <= not(reset) ;
	    Dmem_ReadAddr(31 downto 8) <= (others => '0');
		 Dmem_ReadAddr(1 downto 0) <= (others => '0');
	    Dmem_ReadAddr ( 7 downto 2 ) <= fio_dmem_addr_DM when Test_mode = '1' else
						Iss_LdStAddr ( 7 downto 2 );				
		fio_dmem_data_out_DM <= DCE_MemData;
		Dmem_WriteAddr(7 downto 2 ) <= fio_dmem_addr_DM when Test_mode = '1' else
		              SB_AddrDmem(7 downto 2);
		Dmem_WriteData <=  fio_dmem_data_in_DM  when Test_mode = '1' else
		              SB_DataDmem;
		
		--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		-- to support memory mapped I/O from location 64 onwards
	   --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		SB_WriteCache <= fio_dmem_wea_DM when Test_mode = '1' else 
		                --'0' when mem_addr(8)='1' else 
							  SB_DataValid; --don't write to the memory if it is memory mapped i/o
		walking_led_start <= '0' when (walking_led_counter = "0000000000000000000000000") else '1'; -- enable the walking LED based on counter
		--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

 process(Resetb, Clk )
     begin
     if(Resetb = '0') then
        walking_led_counter <= "0000000000000000000000000";
     elsif( Clk'event and Clk = '1' ) then
		-- if (SB_DataValid = '1' and SB_AddrDmem(7 downto 2) = "111111") then
		if (Dis_JmpBr = '1') then -- July 15, 2011 Instead of store word, we are using JUMP as trigger to walking LED
			walking_led_counter <= "1011111010111100001000000";  -- This value is chosen so that downcount to zero takes 10 seconds for 25 MHz Clock.
		--	walking_led_counter <= "1111111010111100001000000";  -- This value is chosen so that downcount to zero takes 10 seconds for 25 MHz Clock.
		elsif (walking_led_counter /= "0000000000000000000000000") then
			walking_led_counter <= walking_led_counter - 1;
		end if;
	end if;
 end process;
 
---- USING REVERSE ASSEMBLY FUNCTION FOR AIDING DEBUGGING
   -- translate_off      
  IfetchInst_string <= reverse_Assembly(Ifetch_Instruction);
  DisInst_String <= reverse_Assembly(Dis_Instruction);
  IntQueueInst_String <= reverse_Assembly(Iss_instructionAlu); -- output of Int queue.. Instruciton which is ready in integer queue to be sent to ALu
  MulQueueInst_String <= reverse_Assembly(Iss_instructionMul); -- output of Mul queue.. Instruciton which is ready in integer queue to be sent to Mul
  DivQueueInst_String <= reverse_Assembly(Iss_instructionDiv); -- output of Div queue.. Instruciton which is ready in integer queue to be sent to Div
  LdStQueueInst_String <= reverse_Assembly(Iss_instructionLsq); -- output of LdSt queue.. Instruciton which is ready in integer queue to be sent to LsBuf/DCE
  CdbInst_String <= reverse_Assembly(Cdb_Instruction); -- instruction on Cdb
  RobInst_String <= reverse_Assembly(Rob_Instruction); -- instruction at Rob Top
  -- translate_on  
		             

PhyRegFile : PhysicalRegister_File
generic map(   
              tag_width   => 6
            )
	
    port map(
			Clk 					=> Clk ,
			Resetb 	     			=> Resetb ,
			---Interface with Integer Issue queue---
			Iss_RsPhyAddrAlu		=> Iss_RsPhyAddrAlu, 
			Iss_RtPhyAddrAlu	    => Iss_RtPhyAddrAlu, 
			---Interface with Load Store Issue queue---
			Iss_RsPhyAddrLsq	    => Iss_RsPhyAddrLsq,
			
			---Interface with Multiply Issue queue---
			Iss_RsPhyAddrMul		=> Iss_RsPhyAddrMul,
			Iss_RtPhyAddrMul		=> Iss_RtPhyAddrMul,
			---Interface with Divide Issue queue---
			Iss_RsPhyAddrDiv		=> Iss_RsPhyAddrDiv,
			Iss_RtPhyAddrDiv		=> Iss_RtPhyAddrDiv,
			---Interface with Dispatch---
			Dis_RsAddr           => Cfc_RsPhyAddr,
			PhyReg_RsDataRdy        => PhyReg_RsDataRdy,
			Dis_RtAddr           => Cfc_RtPhyAddr,
			PhyReg_RtDataRdy        => PhyReg_RtDataRdy,
			Dis_NewRdPhyAddr        => Dis_NewRdPhyAddr,
			Dis_RegWrite            => Dis_RegWrite,
			---Interface with Integer Execution Unit---
			PhyReg_AluRsData		=> PhyReg_AluRsData,
			PhyReg_AluRtData		=> PhyReg_AluRtData,
			---Interface with Load Store Execution Unit---
		   PhyReg_LsqRsData			=> PhyReg_LsqRsData,
		   
			---Interface with Multiply Execution Unit---
		   PhyReg_MultRsData		=> PhyReg_MultRsData,
		   PhyReg_MultRtData		=> PhyReg_MultRtData,
			---Interface with Divide Execution Unit---
		   PhyReg_DivRsData			=> PhyReg_DivRsData,
		   PhyReg_DivRtData	        => PhyReg_DivRtData,
			---Interface with CDB ---
			Cdb_RdData   		    => Cdb_Data,
			Cdb_RdPhyAddr 			=> Cdb_RdPhyAddr,
			Cdb_Valid               => Cdb_Valid,
			Cdb_PhyRegWrite         => Cdb_PhyRegWrite,
			---Interface with Store Buffer ---
			Rob_CommitCurrPhyAddr     => Rob_CommitCurrPhyAddr,
			PhyReg_StoreData        => PhyReg_StoreData
		  );
-----------------------------------------------------------------------------------------------
inst_cache_inst: inst_cache
generic map (    DATA_WIDTH => 128, 
                 ADDR_WIDTH => 6   )
port map (
      Clk         => Clk, 
      Resetb     => Resetb,
		read_cache  => Ifetch_ReadCache,
      abort_prev_read => Ifetch_AbortPrevRead,
      addr          => Ifetch_WpPcIn,
      cd0           => Cache_Cd0 ,
      cd1           => Cache_Cd1 ,
      cd2           => Cache_Cd2,
      cd3           => Cache_Cd3 ,
		-- synopsys translate_off
		registered_addr => open,
		-- synopsys translate_on	
      read_hit      => Cache_ReadHit,
	  
      fio_icache_addr_a     =>    fio_icache_addr_IM, 
      fio_icache_data_in_a  =>  fio_icache_data_in_IM,
      fio_icache_wea        =>  fio_icache_wea_IM, 
      fio_icache_data_out_a =>  fio_icache_data_out_IM,
	   fio_icache_ena		    =>  fio_icache_ena_IM	  
     ); 
----------------------------------------------------------------------------------------------
ifetch_queue : i_fetch_q
port map(
	Clk						=> Clk,
	Resetb					=> Resetb,
	   
	     -- interface with the dispatch unit
	Ifetch_Instruction		=> Ifetch_Instruction,
	Ifetch_PcPlusFour		=> Ifetch_PcPlusFour ,
	Ifetch_EmptyFlag		=> Ifetch_EmptyFlag,
	Dis_Ren					=> Dis_Ren,
	Dis_JmpBrAddr			=> Dis_JmpBrAddr,
	Dis_JmpBr				=> Dis_JmpBr,
	Dis_JmpBrAddrValid		=> Dis_JmpBrAddrValid,

		-- interface with the cache unit
	Ifetch_WpPcIn			=>Ifetch_WpPcIn,
	Ifetch_ReadCache		=> Ifetch_ReadCache,
		-- synopsys translate_off
		wp_report          => wp_report,
		rp_report          => rp_report,
		depth_report       => depth_report,
		-- synopsys translate_on	
	Ifetch_AbortPrevRead   => Ifetch_AbortPrevRead,
	Cache_Cd0             => Cache_Cd0,
	Cache_Cd1             => Cache_Cd1,
	Cache_Cd2             => Cache_Cd2,
	Cache_Cd3             => Cache_Cd3,
	Cache_ReadHit        => Cache_ReadHit
     );
-----------------------------------------------------------------------------------------------
branch_predictor : bpb
 port map(
         Clk                  => Clk,
         Resetb                => Resetb,
         ---- rob -------
            Dis_CdbUpdBranch         => Dis_CdbUpdBranch,
            Dis_CdbUpdBranchAddr     =>Dis_CdbUpdBranchAddr,
            Dis_CdbBranchOutcome     =>Dis_CdbBranchOutcome,
         ------------------ 
         ---- dispatch --------------
            Bpb_BranchPrediction    =>Bpb_BranchPrediction,
            Dis_BpbBranchPCBits         =>Dis_BpbBranchPCBits,
            Dis_BpbBranch               =>Dis_BpbBranch
         ---------------------------
         );
-----------------------------------------------------------------------------------------------
ras_unit : ras
port map(
	--global signals
	Resetb 					=> Resetb,
	Clk						=> Clk,
	 
	-- Interface with Dispatch
	--inputs
	Dis_PcPlusFour			=>Dis_PcPlusFour,
	Dis_RasJalInst				=>Dis_RasJalInst,
	Dis_RasJr31Inst				=>Dis_RasJr31Inst,
	--outputs
	Ras_Addr				=>Ras_Addr
	
	);
	
-----------------------------------------------------------------------------------------------
dispatch_inst : dispatch_unit
port map(
      Clk           =>Clk,
      Resetb         =>Resetb,
     -- Interface with Intsruction Fetch Queue
      Ifetch_Instruction  =>Ifetch_Instruction,
      Ifetch_PcPlusFour   =>Ifetch_PcPlusFour,
      Ifetch_EmptyFlag    =>Ifetch_EmptyFlag,
      Dis_Ren             =>Dis_Ren,
      Dis_JmpBrAddr       =>Dis_JmpBrAddr,
      Dis_JmpBr        =>Dis_JmpBr,
      Dis_JmpBrAddrValid =>Dis_JmpBrAddrValid,
    
    -- Interface with branch prediction buffer
   
      Dis_CdbUpdBranch       =>Dis_CdbUpdBranch,
      Dis_CdbUpdBranchAddr   =>Dis_CdbUpdBranchAddr,
      Dis_CdbBranchOutcome   => Dis_CdbBranchOutcome,
      Bpb_BranchPrediction   =>Bpb_BranchPrediction,
      Dis_BpbBranchPCBits       =>Dis_BpbBranchPCBits,
      Dis_BpbBranch             =>Dis_BpbBranch,
      
	 -- interface with the cdb  
	    Cdb_Branch           =>Cdb_Branch,
      Cdb_BranchOutcome      =>Cdb_BranchOutcome,
      Cdb_BranchAddr         =>Cdb_BranchAddr,
      Cdb_BrUpdtAddr         =>Cdb_BranchUpdtAddr,
      Cdb_Flush              =>Cdb_Flush,
      Cdb_RobTag             =>Cdb_RobTag,
    ------------------------------------------------------------------------------
   -- interface with checkpoint module
      Dis_CfcRsAddr       =>Dis_CfcRsAddr,
      Dis_CfcRtAddr       =>Dis_CfcRtAddr,
   	  Dis_CfcRdAddr       =>Dis_CfcRdAddr,
      -- goes to Dis_RobRdAddr of ROB too
		
	    Cfc_RsPhyAddr    =>Cfc_RsPhyAddr,
      Cfc_RtPhyAddr      =>Cfc_RtPhyAddr,
	    Cfc_RdPhyAddr    =>Cfc_RdPhyAddr,
		Cfc_Full         =>Cfc_Full,
         
	    Dis_CfcBranchTag      =>Dis_CfcBranchTag,
	    Dis_CfcRegWrite       =>Dis_CfcRegWrite,
	    Dis_CfcNewRdPhyAddr   =>Dis_CfcNewRdPhyAddr,
	    Dis_CfcBranch         =>Dis_CfcBranch,
		Dis_CfcInstValid      =>Dis_CfcInstValid,
   --------------------------------------------------------------------------------
-- physical register interface
      PhyReg_RsDataRdy       =>PhyReg_RsDataRdy,
      PhyReg_RtDataRdy       =>PhyReg_RtDataRdy,

   -- interface with issue queues 
       -- translate_off 
      Dis_Instruction    =>Dis_instruction,
     -- translate_on      
      Dis_RegWrite    =>Dis_RegWrite,
	    Dis_RsDataRdy    =>Dis_RsDataRdy,
      Dis_RtDataRdy      => Dis_RtDataRdy,
      Dis_RsPhyAddr      =>Dis_RsPhyAddr,
      Dis_RtPhyAddr      => Dis_RtPhyAddr,
    
      Dis_RobTag         =>Dis_RobTag,
	    Dis_Opcode       =>Dis_Opcode,
      
	    Dis_IntIssquenable   =>Dis_IntIssquenable,
      Dis_LdIssquenable      =>Dis_LdIssquenable,
      Dis_DivIssquenable     =>Dis_DivIssquenable,
      Dis_MulIssquenable     =>Dis_MulIssquenable,
      Dis_Immediate         =>Dis_Immediate,
      Issque_IntQueueFull     =>Issque_IntQueueFull,
      Issque_LdStQueueFull    =>Iss_LdStQueueFull,
      Issque_DivQueueFull     =>Issque_DivQueueFull,
      Issque_MulQueueFull     =>Issque_MulQueueFull,
	    Issque_IntQueTwoOrMoreVacant =>Issque_IntQueueTwoOrMoreVacant,
	    Issque_LdStQueTwoOrMoreVacant =>Issque_LdStQueueTwoOrMoreVacant,
	    Issque_DivQueTwoOrMoreVacant =>Issque_DivQueueTwoOrMoreVacant,
	    Issque_MulQueTwoOrMoreVacant =>Issque_MulQueueTwoOrMoreVacant,
		  Dis_BranchOtherAddr =>Dis_BranchOtherAddr,
      Dis_BranchPredict   =>Dis_BranchPredict,
      Dis_BranchPCBits       =>Dis_BranchPCBits,
      Dis_Branch             =>Dis_Branch,
      
      Dis_JrRsInst        =>Dis_JrRsInst,
      Dis_JalInst        =>Dis_JalInst,
      Dis_Jr31Inst        =>Dis_Jr31Inst,
   ----------------------------------------------------------------------------------

   ---- interface with the FRL----
      Frl_RdPhyAddr      =>Frl_RdPhyAddr,
      Dis_FrlRead        =>Dis_FrlRead,
	    Frl_Empty        =>Frl_Empty,
   ----------------------------------------------------------------------------------

   ---- interface with the RAS----
      Dis_RasJalInst      =>Dis_RasJalInst,
	    Dis_RasJr31Inst       =>Dis_RasJr31Inst,
	    Dis_PcPlusFour     =>Dis_PcPlusFour,
	  
	    Ras_Addr         =>Ras_Addr,
	  Dis_PrevPhyAddr   =>Dis_PrevPhyAddr,
	    Dis_NewRdPhyAddr  =>Dis_NewRdPhyAddr,
	    Dis_RobRdAddr    =>Dis_RobRdAddr,                                                      -- send to Physical register file too.. so that he can make data ready bit "0"
	    Dis_InstValid    =>Dis_InstValid,
	    Dis_InstSw       => Dis_InstSw,
	    Dis_SwRtPhyAddr  =>Dis_SwRtPhyAddr,
      Rob_BottomPtr    =>Rob_BottomPtr,
      Rob_Full         =>Rob_Full,
	    Rob_TwoOrMoreVacant      =>Rob_TwoOrMoreVacant
   
      );
 
-----------------------------------------------------------------------------------------------
cfc_inst : cfc
port map(  --global signals
		Clk	 			         =>Clk,
		Resetb			         =>Resetb,
		--interface with dispatch unit
		Dis_CfcBranchTag            =>Dis_CfcBranchTag,
		Dis_CfcRdAddr               =>Dis_CfcRdAddr,
		Dis_CfcRsAddr               =>Dis_CfcRsAddr,
		Dis_CfcRtAddr               =>Dis_CfcRtAddr,
		Dis_CfcNewRdPhyAddr         =>Dis_CfcNewRdPhyAddr,
		Dis_CfcRegWrite             =>Dis_CfcRegWrite,
		Dis_CfcBranch               =>Dis_CfcBranch,
		Dis_InstValid            =>Dis_CfcInstValid,
		Dis_Jr31Inst             =>Dis_RasJr31Inst,
		Cfc_RdPhyAddr            =>Cfc_RdPhyAddr,
		Cfc_RsPhyAddr	         =>Cfc_RsPhyAddr,
		Cfc_RtPhyAddr	         =>Cfc_RtPhyAddr,
		Cfc_Full                 =>Cfc_Full,				
		--interface with ROB
		
		Rob_TopPtr		         =>Rob_TopPtr,
		Rob_Commit               =>Rob_Commit,
		Rob_CommitRdAddr         =>Rob_CommitRdAddr,
		Rob_CommitRegWrite       =>Rob_CommitRegWrite,
		Rob_CommitCurrPhyAddr    =>Rob_CommitCurrPhyAddr,
		
		--signals from cfc to ROB in case of CDB flush
		Cfc_RobTag               =>Cfc_RobTag,
	
	
		--interface with PHP
		Frl_HeadPtr              =>Frl_HeadPtr,
		Cfc_FrlHeadPtr           =>Cfc_FrlHeadPtr,
		--interface with CDB
		Cdb_Flush  		         =>Cdb_Flush,
		Cdb_RobTag               =>Cdb_RobTag,
		Cdb_RobDepth		     =>Cdb_RobDepth
	  );
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
frl_inst : Frl
generic map(WIDE  => 6 ,
         DEEP  => 16,
		 PTRWIDTH => 5)
port map(
--Inputs
Clk           =>Clk,
Resetb         =>Resetb,
Cdb_Flush     =>Cdb_Flush,
--Interface with Rob
Rob_CommitPrePhyAddr 	 =>Rob_CommitPrePhyAddr,
Rob_Commit    =>Rob_Commit,
Rob_CommitRegWrite =>Rob_CommitRegWrite,
Cfc_FrlHeadPtr =>Cfc_FrlHeadPtr,
--Intreface with Dis_FrlRead unit
Frl_RdPhyAddr        =>Frl_RdPhyAddr,
Dis_FrlRead    =>Dis_FrlRead,
Frl_Empty      =>Frl_Empty,
--Interface with Previous Head Pointer Stack

Frl_HeadPtr    =>Frl_HeadPtr
);
-----------------------------------------------------------------------------------------------
alu_inst : ALU
generic map(   
         tag_width   =>6
         )
port map(
		PhyReg_AluRsData	   =>PhyReg_AluRsData,
		PhyReg_AluRtData	   =>PhyReg_AluRtData,
		Iss_OpcodeAlu		   =>Iss_OpcodeAlu,
		Iss_RobTagAlu           =>Iss_RobTagAlu,
		Iss_RdPhyAddrAlu	     =>Iss_RdPhyAddrAlu,
		Iss_BranchAddrAlu       =>Iss_BranchAddrAlu,
      Iss_BranchAlu		     =>Iss_BranchAlu,
		Iss_RegWriteAlu         =>Iss_RegWriteAlu,
		Iss_BranchUptAddrAlu    =>Iss_BranchUptAddrAlu,
		Iss_BranchPredictAlu    =>Iss_BranchPredictAlu,
		Iss_JalInstAlu          =>Iss_JalInstAlu,
		Iss_JrInstAlu           =>Iss_JrInstAlu,
		Iss_JrRsInstAlu         =>Iss_JrRsInstAlu,
		Iss_ImmediateAlu     =>Iss_ImmediateAlu,
		-- translate_off 
        Iss_instructionAlu      =>Iss_instructionAlu ,
	    -- translate_on	
		Alu_RdData           =>Alu_RdData,
      Alu_RdPhyAddr        =>Alu_RdPhyAddr,
      Alu_BranchAddr       =>Alu_BranchAddr,
      Alu_Branch           =>Alu_Branch,
	   Alu_BranchOutcome    =>Alu_BranchOutcome,
	   -- translate_off 
        Alu_instruction      =>Alu_instruction,
	    -- translate_on	
		
		Alu_RobTag          =>Alu_RobTag,
	   Alu_BranchUptAddr    =>Alu_BranchUptAddr,
      Alu_BranchPredict    =>Alu_BranchPredict,
		Alu_RdWrite      =>Alu_RdWrite,
		Alu_JrFlush          =>Alu_JrFlush
		);
-----------------------------------------------------------------------------------------------
integer_queue_inst : issueque

port map(
      -- Global Clk and Resetb Signals
      Clk                 =>Clk,
      Resetb               =>Resetb,

      -- Information to be captured from the Lsb Buffer
      Lsbuf_PhyAddr       =>Lsbuf_PhyAddr,
	   Lsbuf_RdWrite    =>Lsbuf_RdWrite,
	   
	         -- Information to be captured from the Write port of Physical Register file
      Cdb_RdPhyAddr       =>Cdb_RdPhyAddr,
	   Cdb_PhyRegWrite    =>Cdb_PhyRegWrite,


      -- Information from the Dispatch Unit 
     Dis_Issquenable      =>Dis_IntIssquenable,
     Dis_RsDataRdy        =>Dis_RsDataRdy,
     Dis_RtDataRdy        =>Dis_RtDataRdy,
	  Dis_RegWrite        =>Dis_RegWrite,
     Dis_RsPhyAddr        =>Dis_RsPhyAddr,
     Dis_RtPhyAddr        =>Dis_RtPhyAddr,
     Dis_NewRdPhyAddr     =>Dis_NewRdPhyAddr,
	  Dis_RobTag          =>Dis_RobTag,
     Dis_Opcode           =>Dis_Opcode,
     Dis_Immediate      =>Dis_Immediate,
	  Dis_Branch          =>Dis_Branch,
	  Dis_BranchPredict   =>Dis_BranchPredict,
	  Dis_BranchOtherAddr  =>Dis_BranchOtherAddr,
	  Dis_BranchPCBits     =>Dis_BranchPCBits,
     Issque_IntQueueFull          =>Issque_IntQueueFull,
     Issque_IntQueueTwoOrMoreVacant =>Issque_IntQueueTwoOrMoreVacant,
	  Dis_Jr31Inst          =>Dis_Jr31Inst,
	  Dis_JalInst         =>Dis_JalInst,
	  Dis_JrRsInst        =>Dis_JrRsInst,
	  -- translate_off 
    Dis_instruction     => Dis_instruction,
    -- translate_on
     -- Interface with the Issue Unit
     IssInt_Rdy             =>IssInt_Rdy,
	  Iss_Int           =>Iss_Int ,
	  Iss_Lsb           => Iss_Lsb,
		
	  -- Interface with the Multiply execution unit
	  Mul_RdPhyAddr        => Mul_RdPhyAddr,
	  Mul_ExeRdy           => Mul_Done,
	  Div_RdPhyAddr        => Div_RdPhyAddr,
	  Div_ExeRdy           => Div_ExeRdy,
	  
	  -- Interface with the Physical Register File
     Iss_RsPhyAddrAlu         =>Iss_RsPhyAddrAlu,
     Iss_RtPhyAddrAlu         =>Iss_RtPhyAddrAlu,
     
	  
	  -- Interface with the Execution unit
	 Iss_RdPhyAddrAlu         =>Iss_RdPhyAddrAlu,
	 Iss_RobTagAlu            =>Iss_RobTagAlu,
	 Iss_OpcodeAlu            =>Iss_OpcodeAlu,
	 Iss_BranchAddrAlu        =>Iss_BranchAddrAlu,
    Iss_BranchAlu		       =>Iss_BranchAlu,
	 Iss_RegWriteAlu          =>Iss_RegWriteAlu,
	 Iss_BranchUptAddrAlu     =>Iss_BranchUptAddrAlu,
	 Iss_BranchPredictAlu     =>Iss_BranchPredictAlu,
	 Iss_JalInstAlu           =>Iss_JalInstAlu,
	 Iss_JrInstAlu            =>Iss_JrInstAlu,
    Iss_JrRsInstAlu          =>Iss_JrRsInstAlu,
	  Iss_ImmediateAlu         =>Iss_ImmediateAlu,
	  -- translate_off 
     Iss_instructionAlu     =>Iss_instructionAlu,
	 -- translate_on
      --  Interface with ROB 
      Cdb_Flush            =>Cdb_Flush,
      Rob_TopPtr           =>Rob_TopPtr,
      Cdb_RobDepth         =>Cdb_RobDepth
     ) ;
-----------------------------------------------------------------------------------------------
mult_inst : multiplier
generic map(   
         tag_width   		=> 6
         )
    port map( 
				Clk				  =>Clk,
				Resetb			  =>Resetb,
				Iss_Mult      	=>Iss_Mult,
				PhyReg_MultRsData	=>PhyReg_MultRsData,
				PhyReg_MultRtData	=>PhyReg_MultRtData,
				Iss_RobTag 	=>Iss_RobTagMul,
				--
				Mul_RdPhyAddr =>Mul_RdPhyAddr,
				Mul_RdWrite =>Mul_RdWrite,
				Iss_RdPhyAddr =>Iss_RdPhyAddrMul,
				Iss_RdWrite => Iss_RegWriteMul,
				--
				-- translate_off 
     Iss_instructionMul    =>Iss_instructionMul,
	 -- translate_on
	 -- translate_off 
         Mul_instruction       =>Mul_instruction,
	    -- translate_on
				Mul_RdData		=>Mul_RdData,
				Mul_RobTag		=>Mul_RobTag,
				Mul_Done        =>Mul_Done,
			Cdb_Flush           =>Cdb_Flush,
            Rob_TopPtr         =>Rob_TopPtr,
            Cdb_RobDepth      =>Cdb_RobDepth
			);
-----------------------------------------------------------------------------------------------
MultIssueQue_inst : issueque_mult

port map(
      -- Global Clk and Resetb Signals
      Clk                 =>Clk,
      Resetb               =>Resetb,

      -- Information to be captured from the Lsb Buffer
      Lsbuf_PhyAddr       =>Lsbuf_PhyAddr,
	   Lsbuf_RdWrite    =>Lsbuf_RdWrite,

      -- Information to be captured from the Write port of Physical Register file
      Cdb_RdPhyAddr       =>Cdb_RdPhyAddr,
	   Cdb_PhyRegWrite    =>Cdb_PhyRegWrite,
	   
      -- Information from the Dispatch Unit 
     Dis_Issquenable      =>Dis_MulIssquenable,
     Dis_RsDataRdy        =>Dis_RsDataRdy,
     Dis_RtDataRdy        =>Dis_RtDataRdy,
	  Dis_RegWrite        =>Dis_RegWrite,
     Dis_RsPhyAddr        =>Dis_RsPhyAddr,
     Dis_RtPhyAddr        =>Dis_RtPhyAddr,
     Dis_NewRdPhyAddr     =>Dis_NewRdPhyAddr,
	  Dis_RobTag          =>Dis_RobTag,
     Dis_Opcode           =>Dis_Opcode,
	  Issque_MulQueueFull          =>Issque_MulQueueFull,
	  Issque_MulQueueTwoOrMoreVacant =>Issque_MulQueueTwoOrMoreVacant,
	  -- translate_off 
      Dis_instruction    =>Dis_instruction,
	  -- translate_on
      
     -- Interface with the Issue Unit
     IssMul_Rdy             =>IssMul_Rdy,
	  Iss_Mult           =>Iss_Mult,
	  Iss_Int           => Iss_Int,
	  Iss_Lsb           => Iss_Lsb,
		
	  -- Interface with the Multiply execution unit
	  Iss_RdPhyAddrAlu      =>Iss_RdPhyAddrAlu,
	  Iss_PhyRegValidAlu    =>Iss_RegWriteAlu,
	  Mul_RdPhyAddr         =>Mul_RdPhyAddr,
	  Mul_ExeRdy            =>Mul_Done,
	  Div_RdPhyAddr         =>Div_RdPhyAddr,
	  Div_ExeRdy            =>Div_ExeRdy,
	  -- translate_off 
     Iss_instructionMul     =>Iss_instructionMul,
	 -- translate_on
	  -- Interface with the Physical Register File
     Iss_RsPhyAddrMul        =>Iss_RsPhyAddrMul,
     Iss_RtPhyAddrMul         =>Iss_RtPhyAddrMul,
     
	  
	  -- Interface with the Execution unit
	 Iss_RdPhyAddrMul         =>Iss_RdPhyAddrMul,
	 Iss_RobTagMul            =>Iss_RobTagMul,
	 Iss_OpcodeMul            =>Iss_OpcodeMul,
	 Iss_RegWriteMul          =>Iss_RegWriteMul,
	  
      --  Interface with ROB 
      Cdb_Flush            =>Cdb_Flush,
      Rob_TopPtr           =>Rob_TopPtr,
      Cdb_RobDepth         =>Cdb_RobDepth
     ) ;
-----------------------------------------------------------------------------------------------
divider_inst : divider
generic map(   
         tag_width   			=> 6
         )

	port map(
				Clk					=>Clk,
				Resetb				=>Resetb,
				PhyReg_DivRsData    =>PhyReg_DivRsData,
				PhyReg_DivRtData	=>PhyReg_DivRtData,
				Iss_RobTag		=>Iss_RobTagDiv,
				Iss_Div				=>Iss_Div,
				--
					Div_RdPhyAddr =>Div_RdPhyAddr,
				Div_RdWrite =>Div_RdWrite,
				Iss_RdPhyAddr =>Iss_RdPhyAddrDiv,
				Iss_RdWrite => Iss_RegWriteDiv,
				--
				 -- translate_off 
     Iss_instructionDiv     =>Iss_instructionDiv,
	 -- translate_on
	 -- translate_off 
         Div_instruction      =>Div_instruction,
	    -- translate_on
			Cdb_Flush         =>Cdb_Flush,
            Rob_TopPtr    =>Rob_TopPtr,
            Cdb_RobDepth     =>Cdb_RobDepth,
				Div_Done       =>Div_Done,
				Div_RobTag		=>Div_RobTag,
				Div_Rddata			=>Div_Rddata,
				Div_ExeRdy			=>Div_ExeRdy
			);
-----------------------------------------------------------------------------------------------
DivIssQue_inst : issueque_div

port map(
      -- Global Clk and Resetb Signals
      Clk                 =>Clk,
      Resetb               =>Resetb,

      -- Information to be captured from the Lsb Buffer
      Lsbuf_PhyAddr       =>Lsbuf_PhyAddr,
	   Lsbuf_RdWrite    =>Lsbuf_RdWrite,

      -- Information to be captured from the Write port of Physical Register file
      Cdb_RdPhyAddr       =>Cdb_RdPhyAddr,
	   Cdb_PhyRegWrite    =>Cdb_PhyRegWrite,
	   
      -- Information from the Dispatch Unit 
     Dis_Issquenable      =>Dis_DivIssquenable,
     Dis_RsDataRdy        =>Dis_RsDataRdy,
     Dis_RtDataRdy        =>Dis_RtDataRdy,
	  Dis_RegWrite        =>Dis_RegWrite,
     Dis_RsPhyAddr        =>Dis_RsPhyAddr,
     Dis_RtPhyAddr        =>Dis_RtPhyAddr,
     Dis_NewRdPhyAddr     =>Dis_NewRdPhyAddr,
	  Dis_RobTag          =>Dis_RobTag,
     Dis_Opcode           =>Dis_Opcode,
	  Issque_DivQueueFull          =>Issque_DivQueueFull,
	  Issque_DivQueueTwoOrMoreVacant =>Issque_DivQueueTwoOrMoreVacant,
     -- translate_off 
      Dis_instruction    =>Dis_instruction,
	  -- translate_on
     
     -- Interface with the Issue Unit
     IssDiv_Rdy             =>IssDiv_Rdy,
	  Iss_Div           =>Iss_Div,
	  Iss_Int           => Iss_Int,
	  Iss_Lsb           => Iss_Lsb,
		
	  -- Interface with the Multiply execution unit
	 Iss_RdPhyAddrAlu      =>Iss_RdPhyAddrAlu,
	  Iss_PhyRegValidAlu    =>Iss_RegWriteAlu,
	  Mul_RdPhyAddr         =>Mul_RdPhyAddr,
	  Mul_ExeRdy            =>Mul_Done,
	  Div_RdPhyAddr         =>Div_RdPhyAddr,
	  Div_ExeRdy            =>Div_ExeRdy,
	  -- Interface with the Physical Register File
     Iss_RsPhyAddrDiv         =>Iss_RsPhyAddrDiv,
     Iss_RtPhyAddrDiv         =>Iss_RtPhyAddrDiv,
     
	  
	  -- Interface with the Execution unit
	 Iss_RdPhyAddrDiv         =>Iss_RdPhyAddrDiv,
	 Iss_RobTagDiv            =>Iss_RobTagDiv,
	 Iss_OpcodeDiv            =>Iss_OpcodeDiv,
	 Iss_RegWriteDiv          =>Iss_RegWriteDiv,
	  -- translate_off 
     Iss_instructionDiv   =>Iss_instructionDiv,
	 -- translate_on
	  
      --  Interface with ROB 
      Cdb_Flush            =>Cdb_Flush,
      Rob_TopPtr           =>Rob_TopPtr,
      Cdb_RobDepth         =>Cdb_RobDepth
     ) ;
-----------------------------------------------------------------------------------------------
LoadStoreQue_inst : lsq
port map(
      -- Global Clk and Resetb Signals
      Clk                  =>Clk,
      Resetb                =>Resetb,

      -- Information to be captured from the CDB (Common Data Bus)
      Cdb_RdPhyAddr           =>Cdb_RdPhyAddr,
		Cdb_PhyRegWrite      => Cdb_PhyRegWrite,
      
      Cdb_Valid            =>Cdb_Valid,

      -- Information from the Dispatch Unit 
      Dis_Opcode           =>Dis_Opcode(0),
      Dis_Immediate          =>Dis_Immediate,
      Dis_RsDataRdy        =>Dis_RsDataRdy,
      
      Dis_RsPhyAddr        =>Dis_RsPhyAddr,
      
	  Dis_RobTag           =>Dis_RobTag,
      Dis_NewRdPhyAddr     =>Dis_NewRdPhyAddr,
      Dis_LdIssquenable    =>Dis_LdIssquenable,
      Issque_LdStQueueFull    =>Iss_LdStQueueFull,
      Issque_LdStQueueTwoOrMoreVacant =>Issque_LdStQueueTwoOrMoreVacant,
      -- translate_off 
     Dis_instruction    =>Dis_instruction,
	 -- translate_on
	 
	 -- translate_off 
     Iss_instructionLsq      =>Iss_instructionLsq,
	 -- translate_on
      -- interface with PRF
	  Iss_RsPhyAddrLsq   =>Iss_RsPhyAddrLsq,
	  
	  PhyReg_LsqRsData		   =>PhyReg_LsqRsData,
	  
      -- Interface with the Issue Unit
      Iss_LdStReady        =>Iss_LdStReady,
      Iss_LdStOpcode       =>Iss_LdStOpcode,
      Iss_LdStRobTag        =>Iss_LdStRobTag,
      Iss_LdStAddr         =>Iss_LdStAddr,
      
      Iss_LdStIssued         =>Iss_LdStIssued,
      Iss_LdStPhyAddr        => Iss_LdStPhyAddr,
      DCE_ReadBusy           =>DCE_ReadBusy,
      Lsbuf_Done         =>Lsbuf_Done,
    --  Interface with ROB 
      Cdb_Flush            =>Cdb_Flush,
      Rob_TopPtr        =>Rob_TopPtr,
      Cdb_RobDepth        =>Cdb_RobDepth,
      SB_FlushSw          =>SB_FlushSw,
      SB_FlushSwTag        =>SB_FlushSwTag,
	  SBTag_counter	   => SBTag_counter, --Added by Waleed 06/04/10
	  Rob_CommitMemWrite  => Rob_CommitMemWrite--Added by Waleed 06/04/10
     );

	 Iss_LdStIssued <= (((not(Lsbuf_Full) and not(Iss_LdStOpcode)) or (Iss_LdStOpcode and (not DCE_ReadBusy))) and Iss_LdStReady); -- lw /sw is ready to leave LSQ
     Lsbuf_Done <= (not Lsbuf_Full);
     DCE_ReadCache <= '1' when Test_mode = '1' else Iss_LdStReady and Iss_LdStOpcode and (not DCE_ReadBusy); -- changed by vaibhav
-----------------------------------------------------------------------------------------------
datacache_inst : data_cache
generic map(
         DATA_WIDTH     => 32 ,
         ADDR_WIDTH    =>6
        )
port map(
      Clk           => Clk,
      Resetb       => Resetb,
      DCE_ReadCache    => DCE_ReadCache,
      -- Abort_PrevRead => Abort_PrevRead,  -- July 15, 2011 Gandhi: Commented out this line
      --addr          : in std_logic_vector (5 downto 0);
	  Iss_LdStOpcode    => Iss_LdStOpcode,
      Iss_LdStRobTag      =>Iss_LdStRobTag,
      Iss_LdStAddr       =>Dmem_ReadAddr,
		Iss_LdStPhyAddr   =>Iss_LdStPhyAddr,
      Lsbuf_DCETaken         =>Lsbuf_DCETaken,
	  
	  Cdb_Flush         =>Cdb_Flush,
	  Rob_TopPtr         =>Rob_TopPtr,
	  Cdb_RobDepth           =>Cdb_RobDepth,
	  
      SB_WriteCache   =>SB_WriteCache,
      SB_AddrDmem     =>Dmem_WriteAddr,
      SB_DataDmem       =>Dmem_WriteData,
	  -- translate_off 
     DCE_instruction    =>DCE_instruction,
	
     Iss_instructionLsq     =>Iss_instructionLsq,
	 -- translate_on
       --data_out      : out std_logic_vector (31 downto 0);
	    DCE_Opcode        =>DCE_Opcode,
      DCE_RobTag          =>DCE_RobTag,
      DCE_Addr           =>DCE_Addr,
      DCE_MemData          =>DCE_MemData,
      DCE_PhyAddr    => DCE_PhyAddr,
		-- synopsys translate_off
		registered_addr  =>open ,
		registered_SB_AddrDmem => open,
		-- synopsys translate_on	
    DCE_ReadDone     =>DCE_ReadDone,
	  DCE_WriteDone    =>DCE_WriteDone,
	  DCE_ReadBusy     =>DCE_ReadBusy,
	  DCE_WriteBusy      =>DCE_WriteBusy
    --  fio_icache_addr_a        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    --  fio_icache_data_in_a     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    --  fio_icache_wea           : in  std_logic; 
    --  fio_icache_data_out_a    : out std_logic_vector(DATA_WIDTH-1 downto 0);
	--  fio_icache_ena		   : in  std_logic	  
     ); 
-----------------------------------------------------------------------------------------------
lsBuf_inst : ls_buffer
port map(
	     Clk				  =>Clk,
	    Resetb			      =>Resetb,
		
	    --  from ROB  -- for fulsing the instruction in this buffer if appropriate.
       Cdb_Flush            =>Cdb_Flush,
       Rob_TopPtr       =>Rob_TopPtr,
       Cdb_RobDepth          =>Cdb_RobDepth,
	   
	   -- interface with lsq
	    Iss_LdStReady       =>Iss_LdStReady,
      Iss_LdStOpcode       =>Iss_LdStOpcode,
      Iss_LdStRobTag        =>Iss_LdStRobTag,
      Iss_LdStAddr         =>Iss_LdStAddr,
      Iss_LdStData         =>Iss_LdStData,
		Iss_LdStPhyAddr      =>Iss_LdStPhyAddr,
     -- translate_off 
     DCE_instruction    =>DCE_instruction,
	 Iss_instructionLsq   =>Iss_instructionLsq,
	 -- translate_on
     ---- interface with data cache emulator ----------------
	   DCE_PhyAddr        =>DCE_PhyAddr,
      DCE_Opcode          =>DCE_Opcode,
      DCE_RobTag          =>DCE_RobTag,
      DCE_Addr            =>DCE_Addr,
      DCE_MemData         =>DCE_MemData,
      DCE_ReadDone        =>DCE_ReadDone,
       Lsbuf_LsqTaken     =>Lsbuf_LsqTaken,
      Lsbuf_DCETaken      =>Lsbuf_DCETaken,
	  Lsbuf_Full         =>Lsbuf_Full,

		-- interface with issue unit
		-- translate_off 
     Lsbuf_instruction       =>Lsbuf_instruction,
	 -- translate_on
      Lsbuf_Ready       => IssLsb_Rdy,
		Lsbuf_Data        =>Lsbuf_Data,
		Lsbuf_PhyAddr     =>Lsbuf_PhyAddr,
		Lsbuf_RobTag      =>Lsbuf_RobTag,
		Lsbuf_SwAddr      =>Lsbuf_SwAddr,
		Lsbuf_RdWrite     =>Lsbuf_RdWrite,
		
      Iss_Lsb     =>Iss_Lsb
		);

-----------------------------------------------------------------------------------------------
issueUnit_inst : issue_unit
  generic map(
      Resetb_ACTIVE_VALUE => '0' 
    )
    port map(
      Clk            =>Clk,
      Resetb          =>Resetb,

      -- ready signals from each of the queues 
      
      IssInt_Rdy     =>IssInt_Rdy,
      IssMul_Rdy     =>IssMul_Rdy,
      IssDiv_Rdy     =>IssDiv_Rdy,
      IssLsb_Rdy     =>IssLsb_Rdy,
	  
      -- signal from the division execution unit to indicate that it is currently available
      Div_ExeRdy    =>Div_ExeRdy,
      
      --issue signals as acknowledgement from issue unit to each of the queues
      Iss_Int         =>Iss_Int,
      Iss_Mult        =>Iss_Mult,
      Iss_Div         =>Iss_Div,
      Iss_Lsb         =>Iss_Lsb
    );       
  
-----------------------------------------------------------------------------------------------
cdb_inst : cdb
 generic map(
           Resetb_ACTIVE_VALUE => '0'
            )
    port map(
         Clk     =>Clk,
         Resetb   =>Resetb,
         
         --  from ROB 
         
         Rob_TopPtr         =>Rob_TopPtr,
         
         -- from integer execution unit
         Alu_RdData         =>Alu_RdData,
         Alu_RdPhyAddr      =>Alu_RdPhyAddr,
         Alu_BranchAddr     =>Alu_BranchAddr,
         Alu_Branch         =>Alu_Branch,
		   Alu_BranchOutcome  =>Alu_BranchOutcome,
		   Alu_BranchUptAddr  =>Alu_BranchUptAddr,
         Iss_Int             =>Iss_Int,
         Alu_BranchPredict   =>Alu_BranchPredict,
		   Alu_JrFlush         =>Alu_JrFlush,
		   Alu_RobTag          =>Alu_RobTag,
			Alu_RdWrite         =>Alu_RdWrite,
      -- translate_off 
         Alu_instruction   =>Alu_instruction,
	    -- translate_on   
         -- from mult execution unit
         Mul_RdData          =>Mul_RdData,
         Mul_RdPhyAddr       =>Mul_RdPhyAddr,
         Mul_Done            =>Mul_Done,
         Mul_RobTag          =>Mul_RobTag,
			Mul_RdWrite        =>Mul_RdWrite,
			-- translate_off 
         Mul_instruction    =>Mul_instruction,
	    -- translate_on
	     -- from div execution unit
         Div_Rddata          =>Div_Rddata,
         Div_RdPhyAddr       =>Div_RdPhyAddr,
         Div_Done            =>Div_Done,
         Div_RobTag          =>Div_RobTag,
			Div_RdWrite         =>Div_RdWrite,
			-- translate_off 
         Div_instruction      =>Div_instruction,
	    -- translate_on
			
		 -- from load buffer and store word
         Lsbuf_Data             =>Lsbuf_Data,
         Lsbuf_PhyAddr          =>Lsbuf_PhyAddr,
         Iss_Lsb              =>Iss_Lsb,
         Lsbuf_RobTag           =>Lsbuf_RobTag,
			Lsbuf_SwAddr         =>Lsbuf_SwAddr,
			Lsbuf_RdWrite         =>Lsbuf_RdWrite,
-- translate_off 
         Lsbuf_instruction      =>Lsbuf_instruction,
         Cdb_instruction       =>Cdb_instruction,
	    -- translate_on
         --outputs of cdb 
         Cdb_Valid           =>Cdb_Valid,
		 Cdb_PhyRegWrite     =>Cdb_PhyRegWrite,
         Cdb_Data            =>Cdb_Data,
         Cdb_RobTag          =>Cdb_RobTag,
		 Cdb_BranchAddr      =>Cdb_BranchAddr,
         Cdb_BranchOutcome   =>Cdb_BranchOutcome,
		 Cdb_BranchUpdtAddr  =>Cdb_BranchUpdtAddr,
         Cdb_Branch          =>Cdb_Branch,
         Cdb_Flush           =>Cdb_Flush,
		 Cdb_RobDepth        =>Cdb_RobDepth,
		 Cdb_RdPhyAddr       =>Cdb_RdPhyAddr,
		 Cdb_SwAddr          =>Cdb_SwAddr
			
        );
-----------------------------------------------------------------------------------------------
rob_inst : rob
port map(--inputs--
			  Clk				=>Clk,
			  Resetb			    =>Resetb,
			  
			  -- Interface with CDB
			  Cdb_Valid		   =>Cdb_Valid,
			  Cdb_RobTag	   =>Cdb_RobTag,
			  Cdb_SwAddr       =>Cdb_SwAddr,
				  
			  -- Interface with Dispatch unit	
			  Dis_InstSw             =>Dis_InstSw,
			  Dis_RegWrite           =>Dis_RegWrite,
			  Dis_InstValid          =>Dis_InstValid,
			  Dis_RobRdAddr             =>Dis_RobRdAddr,
			  Dis_NewRdPhyAddr       =>Dis_NewRdPhyAddr,
			  Dis_PrevPhyAddr        =>Dis_PrevPhyAddr,
			  Dis_SwRtPhyAddr        =>Dis_SwRtPhyAddr,
			  Rob_Full               =>Rob_Full,
			  Rob_TwoOrMoreVacant    =>Rob_TwoOrMoreVacant,
			  --translate_off
			  Dis_instruction        =>Dis_instruction,
			  --translate_on
			  -- Interface with store buffer
			  SB_Full                =>SB_Full,
			  Rob_SwAddr             =>Rob_SwAddr,
			  Rob_CommitMemWrite     =>Rob_CommitMemWrite,
			  -- Takes care of flushing the address buffer
			  -- Interface with FRL and CFC
			  --translate_off
			  Rob_Instruction        =>Rob_Instruction,
			  --translate_on
			  Rob_TopPtr                 =>Rob_TopPtr,  
              Rob_BottomPtr	             => Rob_BottomPtr,			  
		    
			  Rob_Commit                 =>Rob_Commit,
		      Rob_CommitRdAddr           =>Rob_CommitRdAddr,
		      Rob_CommitRegWrite         =>Rob_CommitRegWrite,
		      Rob_CommitPrePhyAddr       =>Rob_CommitPrePhyAddr,
		      Rob_CommitCurrPhyAddr      =>Rob_CommitCurrPhyAddr,
			     Cfc_RobTag             =>Cfc_RobTag,
			     Cdb_Flush              =>Cdb_Flush
	   
			  
			  );

-----------------------------------------------------------------------------------------------
storeBuffer_inst : store_buffer
port map( 
	  -- Global Signals
	    Clk            => Clk,
        Resetb          => Resetb ,
				
	  --interface with ROB
		Rob_SwAddr  => Rob_SwAddr,
		PhyReg_StoreData  => PhyReg_StoreData,
		Rob_CommitMemWrite      => Rob_CommitMemWrite,
		SB_Full           => SB_Full,
		SB_Stall 		  => SB_Stall,
		Rob_TopPtr   => Rob_TopPtr,
		-- interface with lsq
		  SB_FlushSw            =>SB_FlushSw,
		  SB_FlushSwTag         =>SB_FlushSwTag,
		  SBTag_counter			=>SBTag_counter, --Added by Waleed 06/04/10
			
	   --interface with Data Cache Emulator
	    SB_DataDmem  => SB_DataDmem,
		SB_AddrDmem  => SB_AddrDmem,
		SB_DataValid => SB_DataValid,
		DCE_WriteBusy     => DCE_WriteBusy,
		DCE_WriteDone => DCE_WriteDone
	
	  );   
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
      
 
           

 
			                        
end behave   ;    