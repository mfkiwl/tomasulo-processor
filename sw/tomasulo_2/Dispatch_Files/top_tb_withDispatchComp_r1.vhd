-------------------------------------------------------------------------------
-- Design   : Signal Spy testbench for Load/Store Address Buffer
-- Project  : Tomasulo Processor 
-- Author   : Waleed Dweik
-- Data		: 07/12/2010
-- Company  : University of Southern California 
-------------------------------------------------------------------------------
library std,ieee;
library modelsim_lib;
use ieee.std_logic_1164.all;
use modelsim_lib.util.all;
use std.textio.all;
use ieee.std_logic_textio.all;

-- synopsys translate_off
--use work.reverseAssemblyFunctionPkg.all;
-- synopsys translate_on
-----------------------------------------------------------------------------

--added by Sabya to use compiled library
library ee560;
use ee560.all;
------------------------------------------------------------------------------

entity top_tb is
end entity top_tb;

architecture arch_top_tb_Dispatch of top_tb is

-- local signals
	signal Clk, Reset: std_logic;

-- clock period
	constant Clk_Period: time:= 20 ns;
-- clock count signal to make it easy for debugging
	signal Clk_Count: integer range 0 to 999;
-- a 10% delayed clock for clock counting
	signal Clk_Delayed10: std_logic;
	signal Walking_Led: std_logic;
	signal Fio_Icache_Addr_IM: std_logic_vector(5 downto 0);
	signal Fio_Icache_Data_In_IM: std_logic_vector(127 downto 0);
	signal Fio_Icache_Wea_IM: std_logic; 
	signal Fio_Icache_Data_Out_IM: std_logic_vector(127 downto 0);
	signal Fio_Icache_Ena_IM		: std_logic;
	signal Fio_Dmem_Addr_DM: std_logic_vector(5 downto 0);
	signal Fio_Dmem_Data_Out_DM: std_logic_vector(31 downto 0);	
	signal Fio_Dmem_Data_In_DM: std_logic_vector(31 downto 0);
	signal Fio_Dmem_Wea_DM    		: std_logic;
		
	
-- Hierarchy signals (Golden Dispatch)
      signal Dis_Ren_gold         	   			: std_logic;   
      signal Dis_JmpBrAddr_gold       			: std_logic_vector(31 downto 0); 
      signal Dis_JmpBr_gold           			: std_logic;   
      signal Dis_JmpBrAddrValid_gold  			: std_logic;   
	  signal Dis_CdbUpdBranch_gold          	: std_logic;
      signal Dis_CdbUpdBranchAddr_gold      	: std_logic_vector(2 downto 0);
      signal Dis_CdbBranchOutcome_gold      	: std_logic;
	  signal Dis_BpbBranchPCBits_gold       	: std_logic_vector(2 downto 0);
      signal Dis_BpbBranch_gold     	        : std_logic; 
	  signal Dis_CfcRsAddr_gold       			: std_logic_vector(4 downto 0); 
      signal Dis_CfcRtAddr_gold       			: std_logic_vector(4 downto 0);
   	  signal Dis_CfcRdAddr_gold       			: std_logic_vector(4 downto 0); 
	  signal Dis_CfcBranchTag_gold       		: std_logic_vector(4 downto 0) ; 
	  signal Dis_CfcRegWrite_gold        		: std_logic; 
	  signal Dis_CfcNewRdPhyAddr_gold    		: std_logic_vector(5 downto 0);  
	  signal Dis_CfcBranch_gold          		: std_logic;  
	  signal Dis_CfcInstValid_gold       		: std_logic;
	  signal Dis_RegWrite_gold        			: std_logic;      
	  signal Dis_RsDataRdy_gold       			: std_logic;
      signal Dis_RtDataRdy_gold       			: std_logic; 
      signal Dis_RsPhyAddr_gold       			: std_logic_vector(5 downto 0); 
      signal Dis_RtPhyAddr_gold       			: std_logic_vector(5 downto 0); 
      signal Dis_RobTag_gold          			: std_logic_vector(4 downto 0);
	  signal Dis_Opcode_gold          			: std_logic_vector(2 downto 0);
	  signal Dis_IntIssquenable_gold     		: std_logic; 
      signal Dis_LdIssquenable_gold      		: std_logic; 
      signal Dis_DivIssquenable_gold     		: std_logic; 
      signal Dis_MulIssquenable_gold     		: std_logic; 
      signal Dis_Immediate_gold          		: std_logic_vector(15 downto 0);
	  signal Dis_BranchOtherAddr_gold 			: std_logic_vector(31 downto 0); 
      signal Dis_BranchPredict_gold   			: std_logic; 
      signal Dis_Branch_gold          			: std_logic;
      signal Dis_BranchPCBits_gold    			: std_logic_vector(2 downto 0);
      signal Dis_JrRsInst_gold        			: std_logic;
      signal Dis_JalInst_gold         			: std_logic ; 
	  signal Dis_Jr31Inst_gold        			: std_logic;
	  signal Dis_FrlRead_gold         		    : std_logic ;
      signal Dis_RasJalInst_gold      			: std_logic ; 
	  signal Dis_RasJr31Inst_gold     			: std_logic;
	  signal Dis_PcPlusFour_gold      			: std_logic_vector(31 downto 0);
      signal Dis_PrevPhyAddr_gold   			: std_logic_vector(5 downto 0); 
	  signal Dis_NewRdPhyAddr_gold  			: std_logic_vector(5 downto 0);  
	  signal Dis_RobRdAddr_gold     			: std_logic_vector(4 downto 0);                                                    
	  signal Dis_InstValid_gold     			: std_logic ;
	  signal Dis_InstSw_gold        			: std_logic ;
	  signal Dis_SwRtPhyAddr_gold   			: std_logic_vector(5 downto 0);
      -- translate_off 
      signal Dis_Instruction_gold    			: std_logic_vector(31 downto 0);
      -- translate_on  	  
    				     
 -- Signals for the student's DUT (Dispatch)
     signal Resetb             					: std_logic ;
     signal Ifetch_Instruction 					: std_logic_vector(31 downto 0); 
     signal Ifetch_PcPlusFour  					: std_logic_vector(31 downto 0); 
     signal Ifetch_EmptyFlag   					: std_logic;	
     signal Dis_Ren            					: std_logic;   
     signal Dis_JmpBrAddr      					: std_logic_vector(31 downto 0); 
     signal Dis_JmpBr          					: std_logic; 
     signal Dis_JmpBrAddrValid 					: std_logic;  
     signal Dis_CdbUpdBranch          			: std_logic; 
     signal Dis_CdbUpdBranchAddr      			: std_logic_vector(2 downto 0);
     signal Dis_CdbBranchOutcome      			: std_logic; 
     signal Bpb_BranchPrediction      			: std_logic; 
	 signal Dis_BpbBranchPCBits       			: std_logic_vector(2 downto 0);
     signal Dis_BpbBranch             			: std_logic; 
	 signal Cdb_Branch              			: std_logic;
     signal Cdb_BranchOutcome       			: std_logic;
     signal Cdb_BranchAddr          			: std_logic_vector(31 downto 0);
     signal Cdb_BranchUpdtAddr          		: std_logic_vector(2 downto 0);  
     signal Cdb_Flush               		    : std_logic;
     signal Cdb_RobTag              			: std_logic_vector(4 downto 0);
	 signal Dis_CfcRsAddr       				: std_logic_vector(4 downto 0); 
     signal Dis_CfcRtAddr       				: std_logic_vector(4 downto 0); 
   	 signal Dis_CfcRdAddr       				: std_logic_vector(4 downto 0); 
	 signal Cfc_RsPhyAddr       				: std_logic_vector(5 downto 0); 
     signal Cfc_RtPhyAddr       				: std_logic_vector(5 downto 0); 
	 signal Cfc_RdPhyAddr       				: std_logic_vector(5 downto 0);
	 signal Cfc_Full          					: std_logic ;
     signal Dis_CfcBranchTag       				: std_logic_vector(4 downto 0) ; 
	 signal Dis_CfcRegWrite        				: std_logic; 
	 signal Dis_CfcNewRdPhyAddr    				: std_logic_vector(5 downto 0);  
	 signal Dis_CfcBranch          				: std_logic;  
	 signal Dis_CfcInstValid       				: std_logic;
	 signal PhyReg_RsDataRdy        			: std_logic ; 
     signal PhyReg_RtDataRdy       				: std_logic ;  
	 signal Dis_RegWrite        				: std_logic;      
	 signal Dis_RsDataRdy       				: std_logic; 
     signal Dis_RtDataRdy       				: std_logic; 
     signal Dis_RsPhyAddr       				: std_logic_vector(5 downto 0); 
     signal Dis_RtPhyAddr       				: std_logic_vector(5 downto 0); 
     signal Dis_RobTag         					: std_logic_vector(4 downto 0);
	 signal Dis_Opcode     						: std_logic_vector(2 downto 0); 
	 signal Dis_IntIssquenable     				: std_logic;
     signal Dis_LdIssquenable      				: std_logic;
     signal Dis_DivIssquenable     				: std_logic;
     signal Dis_MulIssquenable     				: std_logic;
     signal Dis_Immediate          				: std_logic_vector(15 downto 0); 
     signal Issque_IntQueueFull       			: std_logic;
     signal Issque_LdStQueueFull      			: std_logic;
     signal Issque_DivQueueFull       			: std_logic;
     signal Issque_MulQueueFull      			: std_logic;
     signal Issque_IntQueueTwoOrMoreVacant      	: std_logic; 
     signal Issque_LdStQueueTwoOrMoreVacant      	: std_logic;
     signal Issque_DivQueueTwoOrMoreVacant       	: std_logic;
     signal Issque_MulQueueTwoOrMoreVacant       	: std_logic;
     signal Dis_BranchOtherAddr 				: std_logic_vector(31 downto 0); 
     signal Dis_BranchPredict   				: std_logic; 
     signal Dis_Branch          				: std_logic;
     signal Dis_BranchPCBits    				: std_logic_vector(2 downto 0);
     signal Dis_JrRsInst       					: std_logic;
     signal Dis_JalInst     					: std_logic ; 
	 signal Dis_Jr31Inst       					: std_logic;
     signal Frl_RdPhyAddr   					: std_logic_vector(5 downto 0); 
     signal Dis_FrlRead        					: std_logic ;   
	 signal Frl_Empty        					: std_logic; 
	 signal Dis_RasJalInst      				: std_logic ; 
	 signal Dis_RasJr31Inst     				: std_logic;
	 signal Dis_PcPlusFour      				: std_logic_vector(31 downto 0); 
	 signal Ras_Addr            				: std_logic_vector(31 downto 0); 
	 signal Dis_PrevPhyAddr   					: std_logic_vector(5 downto 0); 
	 signal Dis_NewRdPhyAddr  					: std_logic_vector(5 downto 0);  
	 signal Dis_RobRdAddr     					: std_logic_vector(4 downto 0);                                                       
	 signal Dis_InstValid     					: std_logic ;
	 signal Dis_InstSw        					: std_logic ;
	 signal Dis_SwRtPhyAddr  					: std_logic_vector(5 downto 0);  
     signal Rob_BottomPtr    					: std_logic_vector(4 downto 0);
     signal Rob_Full        					: std_logic;
     signal Rob_TwoOrMoreVacant      			: std_logic;
	 signal Dis_Instruction						: std_logic_vector(31 downto 0);
	  
	  
	component tomasulo_top
	port (
		Reset     					: in std_logic;
		Clk 						: in std_logic;
		Fio_Icache_Addr_IM  		: in  std_logic_vector(5 downto 0);
		Fio_Icache_Data_In_IM     	: in  std_logic_vector(127 downto 0);
		Fio_Icache_Wea_IM   		: in  std_logic; 
		Fio_Icache_Data_Out_IM    	: out std_logic_vector(127 downto 0);
		Fio_Icache_Ena_IM		    : in  std_logic;
		Fio_Dmem_Addr_DM    		: in std_logic_vector(5 downto 0);
		Fio_Dmem_Data_Out_DM		: out std_logic_vector(31 downto 0);	
		Fio_Dmem_Data_In_DM 		: in std_logic_vector(31 downto 0);
		Fio_Dmem_Wea_DM    		  	: in std_logic;
		Test_mode     				: in std_logic;  
		Walking_Led_start   		: out std_logic
	);
	end component tomasulo_top;
	
	component dispatch_unit is
	port(
      Clk           				: in std_logic ;
      Resetb         				: in std_logic ;
      Ifetch_Instruction 			: in std_logic_vector(31 downto 0); 
      Ifetch_PcPlusFour  			: in std_logic_vector(31 downto 0);
      Ifetch_EmptyFlag   			: in std_logic;	
      Dis_Ren            			: out std_logic; 
      Dis_JmpBrAddr      			: out std_logic_vector(31 downto 0);
      Dis_JmpBr          			: out std_logic; 
      Dis_JmpBrAddrValid 			: out std_logic; 
      Dis_CdbUpdBranch          	: out std_logic; 
      Dis_CdbUpdBranchAddr      	: out std_logic_vector(2 downto 0);
	  Dis_CdbBranchOutcome      	: out std_logic;
      Bpb_BranchPrediction      	: in std_logic;  
      Dis_BpbBranchPCBits       	: out std_logic_vector(2 downto 0);
      Dis_BpbBranch             	: out std_logic; 
	  Cdb_Branch              		: in std_logic;
      Cdb_BranchOutcome       		: in std_logic;
      Cdb_BranchAddr          		: in std_logic_vector(31 downto 0);
      Cdb_BrUpdtAddr          		: in std_logic_vector(2 downto 0);  
      Cdb_Flush               		: in std_logic;
      Cdb_RobTag              		: in std_logic_vector(4 downto 0);
      Dis_CfcRsAddr       			: out std_logic_vector(4 downto 0);
      Dis_CfcRtAddr       			: out std_logic_vector(4 downto 0); 
   	  Dis_CfcRdAddr       			: out std_logic_vector(4 downto 0); 
	  Cfc_RsPhyAddr       			: in std_logic_vector(5 downto 0); 
      Cfc_RtPhyAddr       			: in std_logic_vector(5 downto 0); 
	  Cfc_RdPhyAddr       			: in std_logic_vector(5 downto 0); 
	  Cfc_Full            			: in std_logic ;   
	  Dis_CfcBranchTag       		: out std_logic_vector(4 downto 0) ; 
	  Dis_CfcRegWrite        		: out std_logic; 
	  Dis_CfcNewRdPhyAddr    		: out std_logic_vector(5 downto 0);
	  Dis_CfcBranch          		: out std_logic;
	  Dis_CfcInstValid       		: out std_logic;
      PhyReg_RsDataRdy        		: in std_logic ; 
      PhyReg_RtDataRdy        		: in std_logic ;
	  -- translate_off 
      Dis_Instruction    			: out std_logic_vector(31 downto 0);
      -- translate_on
      Dis_RegWrite        			: out std_logic;      
	  Dis_RsDataRdy       			: out std_logic;
      Dis_RtDataRdy       			: out std_logic;
      Dis_RsPhyAddr       			: out std_logic_vector(5 downto 0);
      Dis_RtPhyAddr       			: out std_logic_vector(5 downto 0);
      Dis_RobTag          			: out std_logic_vector(4 downto 0);
	  Dis_Opcode          			: out std_logic_vector(2 downto 0);
	  Dis_IntIssquenable     		: out std_logic;
      Dis_LdIssquenable      		: out std_logic;
      Dis_DivIssquenable     		: out std_logic;
      Dis_MulIssquenable     		: out std_logic;
      Dis_Immediate          		: out std_logic_vector(15 downto 0);
      Issque_IntQueueFull       	: in std_logic;
      Issque_LdStQueueFull      	: in std_logic;
      Issque_DivQueueFull       	: in std_logic;
      Issque_MulQueueFull       	: in std_logic;
      Issque_IntQueTwoOrMoreVacant  : in std_logic;
      Issque_LdStQueTwoOrMoreVacant : in std_logic;
      Issque_DivQueTwoOrMoreVacant  : in std_logic;
      Issque_MulQueTwoOrMoreVacant  : in std_logic;
      Dis_BranchOtherAddr 			: out std_logic_vector(31 downto 0);
      Dis_BranchPredict   			: out std_logic;
      Dis_Branch          			: out std_logic;
      Dis_BranchPCBits    			: out std_logic_vector(2 downto 0);
      Dis_JrRsInst        			: out std_logic;
      Dis_JalInst         			: out std_logic ;
	  Dis_Jr31Inst        			: out std_logic;
      Frl_RdPhyAddr       			: in std_logic_vector(5 downto 0);
      Dis_FrlRead         			: out std_logic ; 	  
	  Frl_Empty           			: in std_logic;
      Dis_RasJalInst      			: out std_logic ; 
	  Dis_RasJr31Inst     			: out std_logic;
	  Dis_PcPlusFour      			: out std_logic_vector(31 downto 0);
	  Ras_Addr            			: in std_logic_vector(31 downto 0);
      Dis_PrevPhyAddr   			: out std_logic_vector(5 downto 0);
	  Dis_NewRdPhyAddr  			: out std_logic_vector(5 downto 0);  
	  Dis_RobRdAddr     			: out std_logic_vector(4 downto 0); 
	  Dis_InstValid     			: out std_logic ;
	  Dis_InstSw        			: out std_logic ;
	  Dis_SwRtPhyAddr   			: out std_logic_vector(5 downto 0);
      Rob_BottomPtr     			: in std_logic_vector(4 downto 0);
      Rob_Full          			: in std_logic;
      Rob_TwoOrMoreVacant          	: in std_logic
   
      );
  end component;
for 	dispatch_unit_TEST:  dispatch_unit use entity work.dispatch_unit(behv);

	begin

	UUT: tomasulo_top
	port map (
		Reset  						=>   	Reset,
		Clk    						=>   	Clk,
		Fio_Icache_Addr_IM     		=>   	Fio_Icache_Addr_IM,
		Fio_Icache_Data_In_IM  		=> 		Fio_Icache_Data_In_IM, 
		Fio_Icache_Wea_IM			=> 		Fio_Icache_Wea_IM , 
		Fio_Icache_Data_Out_IM 		=> 		Fio_Icache_Data_Out_IM,
		Fio_Icache_Ena_IM		    => 		Fio_Icache_Ena_IM,
		Fio_Dmem_Addr_DM 			=> 		Fio_Dmem_Addr_DM,
		Fio_Dmem_Data_Out_DM   		=> 		Fio_Dmem_Data_Out_DM,	
		Fio_Dmem_Data_In_DM    		=> 		Fio_Dmem_Data_In_DM,
		Fio_Dmem_Wea_DM    		  	=> 		Fio_Dmem_Wea_DM,
		Test_mode  					=> 		'0',  
		Walking_Led_start			=> 		Walking_Led
    );

	dispatch_unit_TEST : dispatch_unit
port map(
      Clk 							=>		Clk,
      Resetb         				=>		Resetb,
      Ifetch_Instruction  			=>		Ifetch_Instruction,
      Ifetch_PcPlusFour   			=>		Ifetch_PcPlusFour,
      Ifetch_EmptyFlag    			=>		Ifetch_EmptyFlag,
      Dis_Ren             			=>		Dis_Ren,
      Dis_JmpBrAddr       			=>		Dis_JmpBrAddr,
      Dis_JmpBr        				=>		Dis_JmpBr,
      Dis_JmpBrAddrValid 			=>		Dis_JmpBrAddrValid,
      Dis_CdbUpdBranch       		=>		Dis_CdbUpdBranch,
      Dis_CdbUpdBranchAddr   		=>		Dis_CdbUpdBranchAddr,
      Dis_CdbBranchOutcome   		=> 		Dis_CdbBranchOutcome,
      Bpb_BranchPrediction   		=>		Bpb_BranchPrediction,
      Dis_BpbBranchPCBits       	=>		Dis_BpbBranchPCBits,
      Dis_BpbBranch             	=>		Dis_BpbBranch,  
	  Cdb_Branch           			=>		Cdb_Branch,
      Cdb_BranchOutcome      		=>		Cdb_BranchOutcome,
      Cdb_BranchAddr         		=>		Cdb_BranchAddr,
      Cdb_BrUpdtAddr         		=>		Cdb_BranchUpdtAddr,
      Cdb_Flush              		=>		Cdb_Flush,
      Cdb_RobTag             		=>		Cdb_RobTag,
      Dis_CfcRsAddr       			=>		Dis_CfcRsAddr,
      Dis_CfcRtAddr      	 		=>		Dis_CfcRtAddr,
   	  Dis_CfcRdAddr       			=>		Dis_CfcRdAddr,
	  Cfc_RsPhyAddr    				=>		Cfc_RsPhyAddr,
      Cfc_RtPhyAddr      			=>		Cfc_RtPhyAddr,
	  Cfc_RdPhyAddr    				=>		Cfc_RdPhyAddr,
	  Cfc_Full         				=>		Cfc_Full,   
	  Dis_CfcBranchTag      		=>		Dis_CfcBranchTag,
	  Dis_CfcRegWrite       		=>		Dis_CfcRegWrite,
	  Dis_CfcNewRdPhyAddr   		=>		Dis_CfcNewRdPhyAddr,
	  Dis_CfcBranch         		=>		Dis_CfcBranch,
	  Dis_CfcInstValid      		=>		Dis_CfcInstValid,
      PhyReg_RsDataRdy       		=>		PhyReg_RsDataRdy,
      PhyReg_RtDataRdy       		=>		PhyReg_RtDataRdy,
      -- translate_off 
      Dis_Instruction    			=>		Dis_instruction,
      -- translate_on      
      Dis_RegWrite    				=>		Dis_RegWrite,
	  Dis_RsDataRdy    				=>		Dis_RsDataRdy,
      Dis_RtDataRdy      			=> 		Dis_RtDataRdy,
      Dis_RsPhyAddr      			=>		Dis_RsPhyAddr,
      Dis_RtPhyAddr      			=> 		Dis_RtPhyAddr,
      Dis_RobTag         			=>		Dis_RobTag,
	  Dis_Opcode       				=>		Dis_Opcode,
      Dis_IntIssquenable   			=>		Dis_IntIssquenable,
      Dis_LdIssquenable      		=>		Dis_LdIssquenable,
      Dis_DivIssquenable     		=>		Dis_DivIssquenable,
      Dis_MulIssquenable     		=>		Dis_MulIssquenable,
      Dis_Immediate         		=>		Dis_Immediate,
      Issque_IntQueueFull     		=>		Issque_IntQueueFull,
      Issque_LdStQueueFull    		=>		Issque_LdStQueueFull,
      Issque_DivQueueFull     		=>		Issque_DivQueueFull,
      Issque_MulQueueFull     		=>		Issque_MulQueueFull,
	  Issque_IntQueTwoOrMoreVacant	=>		Issque_IntQueueTwoOrMoreVacant,
	  Issque_LdStQueTwoOrMoreVacant =>		Issque_LdStQueueTwoOrMoreVacant,
	  Issque_DivQueTwoOrMoreVacant 	=>		Issque_DivQueueTwoOrMoreVacant,
	  Issque_MulQueTwoOrMoreVacant 	=>		Issque_MulQueueTwoOrMoreVacant,
	  Dis_BranchOtherAddr 			=>		Dis_BranchOtherAddr,
      Dis_BranchPredict   			=>		Dis_BranchPredict,
      Dis_BranchPCBits       		=>		Dis_BranchPCBits,
      Dis_Branch             		=>		Dis_Branch,
      Dis_JrRsInst        			=>		Dis_JrRsInst,
      Dis_JalInst        			=>		Dis_JalInst,
      Dis_Jr31Inst        			=>		Dis_Jr31Inst,
      Frl_RdPhyAddr      			=>		Frl_RdPhyAddr,
      Dis_FrlRead        			=>		Dis_FrlRead,
	  Frl_Empty        				=>		Frl_Empty,
      Dis_RasJalInst      			=>		Dis_RasJalInst,
	  Dis_RasJr31Inst       		=>		Dis_RasJr31Inst,
	  Dis_PcPlusFour     			=>		Dis_PcPlusFour, 
	  Ras_Addr         				=>		Ras_Addr,
	  Dis_PrevPhyAddr   			=>		Dis_PrevPhyAddr,
	  Dis_NewRdPhyAddr  			=>		Dis_NewRdPhyAddr,
	  Dis_RobRdAddr    				=>		Dis_RobRdAddr,                       
	  Dis_InstValid    				=>		Dis_InstValid,
	  Dis_InstSw       				=> 		Dis_InstSw,
	  Dis_SwRtPhyAddr  				=>		Dis_SwRtPhyAddr,
      Rob_BottomPtr    				=>		Rob_BottomPtr,
      Rob_Full         				=>		Rob_Full,
	  Rob_TwoOrMoreVacant      		=>		Rob_TwoOrMoreVacant
      ); 

	clock_generate: process
	begin
	  Clk <= '0', '1' after (Clk_Period/2);
	  wait for Clk_Period;
	end process clock_generate;
	
	-- Reset activation and inactivation
	  Reset <= '1', '0' after (Clk_Period * 4.1 );
	  Clk_Delayed10 <= Clk after (Clk_Period/10);
	-- clock count processes
	Clk_Count_process: process (Clk_Delayed10, Reset)
	      begin
			if Reset = '1' then
	      	  Clk_Count <= 0;
	      	elsif Clk_Delayed10'event and Clk_Delayed10 = '1' then
	      	  Clk_Count <= Clk_Count + 1;  
	      	end if;
	      end process Clk_Count_process;
-------------------------------------------------
		  --check outputs of Load/Store Address Buffer only--
-------------------------------------------------
	compare_outputs_Clkd: process (Clk_Delayed10, Reset)
		file my_outfile: text open append_mode is "TomasuloCompareTestLog.log";
		variable my_inline, my_outline: line;

		begin
			if (Reset = '0' and (Clk_Delayed10'event and Clk_Delayed10 = '0')) then			--- 10%after the middle of the clock.
				if (Dis_Ren_gold /= Dis_Ren) then
					write (my_outline, string'("ERROR! Dis_Ren of TEST does not match Dis_Ren_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_JmpBrAddr_gold /= Dis_JmpBrAddr) then
					write (my_outline, string'("ERROR! Dis_JmpBrAddr of TEST does not match Dis_JmpBrAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_JmpBr_gold /= Dis_JmpBr) then
					write (my_outline, string'("ERROR! Dis_JmpBr of TEST does not match Dis_JmpBr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_JmpBrAddrValid_gold /= Dis_JmpBrAddrValid) then
					write (my_outline, string'("ERROR! Dis_JmpBrAddrValid of TEST does not match Dis_JmpBrAddrValid_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_CdbUpdBranch_gold /= Dis_CdbUpdBranch) then
					write (my_outline, string'("ERROR! Dis_CdbUpdBranch of TEST does not match Dis_CdbUpdBranch_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_CdbUpdBranchAddr_gold /= Dis_CdbUpdBranchAddr) then
					write (my_outline, string'("ERROR! Dis_CdbUpdBranchAddr of TEST does not match Dis_CdbUpdBranchAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_CdbBranchOutcome_gold /= Dis_CdbBranchOutcome) then
					write (my_outline, string'("ERROR! Dis_CdbBranchOutcome of TEST does not match Dis_CdbBranchOutcome_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_BpbBranchPCBits_gold /= Dis_BpbBranchPCBits) then
					write (my_outline, string'("ERROR! Dis_BpbBranchPCBits of TEST does not match Dis_BpbBranchPCBits_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_BpbBranch_gold /= Dis_BpbBranch) then
					write (my_outline, string'("ERROR! Dis_BpbBranch of TEST does not match Dis_BpbBranch_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_CfcRsAddr_gold /= Dis_CfcRsAddr) then
					write (my_outline, string'("ERROR! Dis_CfcRsAddr of TEST does not match Dis_CfcRsAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_CfcRtAddr_gold /= Dis_CfcRtAddr) then
					write (my_outline, string'("ERROR! Dis_CfcRtAddr of TEST does not match Dis_CfcRtAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_CfcRdAddr_gold /= Dis_CfcRdAddr) then
					write (my_outline, string'("ERROR! Dis_CfcRdAddr of TEST does not match Dis_CfcRdAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_CfcBranchTag_gold /= Dis_CfcBranchTag) then
					write (my_outline, string'("ERROR! Dis_CfcBranchTag of TEST does not match Dis_CfcBranchTag_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_CfcRegWrite_gold /= Dis_CfcRegWrite) then
					write (my_outline, string'("ERROR! Dis_CfcRegWrite of TEST does not match Dis_CfcRegWrite_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_CfcNewRdPhyAddr_gold /= Dis_CfcNewRdPhyAddr) then
					write (my_outline, string'("ERROR! Dis_CfcNewRdPhyAddr of TEST does not match Dis_CfcNewRdPhyAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_CfcBranch_gold /= Dis_CfcBranch) then
					write (my_outline, string'("ERROR! Dis_CfcBranch of TEST does not match Dis_CfcBranch_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_CfcInstValid_gold /= Dis_CfcInstValid) then
					write (my_outline, string'("ERROR! Dis_CfcInstValid of TEST does not match Dis_CfcInstValid_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_RegWrite_gold /= Dis_RegWrite) then
					write (my_outline, string'("ERROR! Dis_RegWrite of TEST does not match Dis_RegWrite_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_RsDataRdy_gold /= Dis_RsDataRdy) then
					write (my_outline, string'("ERROR! Dis_RsDataRdy of TEST does not match Dis_RsDataRdy_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_RtDataRdy_gold /= Dis_RtDataRdy) then
					write (my_outline, string'("ERROR! Dis_RtDataRdy of TEST does not match Dis_RtDataRdy_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_RsPhyAddr_gold /= Dis_RsPhyAddr) then
					write (my_outline, string'("ERROR! Dis_RsPhyAddr of TEST does not match Dis_RsPhyAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_RtPhyAddr_gold /= Dis_RtPhyAddr) then
					write (my_outline, string'("ERROR! Dis_RtPhyAddr of TEST does not match Dis_RtPhyAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_RobTag_gold /= Dis_RobTag) then
					write (my_outline, string'("ERROR! Dis_RobTag of TEST does not match Dis_RobTag_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_Opcode_gold /= Dis_Opcode) then
					write (my_outline, string'("ERROR! Dis_Opcode of TEST does not match Dis_Opcode_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_IntIssquenable_gold /= Dis_IntIssquenable) then
					write (my_outline, string'("ERROR! Dis_IntIssquenable of TEST does not match Dis_IntIssquenable_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_LdIssquenable_gold /= Dis_LdIssquenable) then
					write (my_outline, string'("ERROR! Dis_LdIssquenable of TEST does not match Dis_LdIssquenable_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_DivIssquenable_gold /= Dis_DivIssquenable) then
					write (my_outline, string'("ERROR! Dis_DivIssquenable of TEST does not match Dis_DivIssquenable_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_MulIssquenable_gold /= Dis_MulIssquenable) then
					write (my_outline, string'("ERROR! Dis_MulIssquenable of TEST does not match Dis_MulIssquenable_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_Immediate_gold /= Dis_Immediate) then
					write (my_outline, string'("ERROR! Dis_Immediate of TEST does not match Dis_Immediate_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_BranchOtherAddr_gold /= Dis_BranchOtherAddr) then
					write (my_outline, string'("ERROR! Dis_BranchOtherAddr of TEST does not match Dis_BranchOtherAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_BranchPredict_gold /= Dis_BranchPredict) then
					write (my_outline, string'("ERROR! Dis_BranchPredict of TEST does not match Dis_BranchPredict_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_Branch_gold /= Dis_Branch) then
					write (my_outline, string'("ERROR! Dis_Branch of TEST does not match Dis_Branch_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_BranchPCBits_gold /= Dis_BranchPCBits) then
					write (my_outline, string'("ERROR! Dis_BranchPCBits of TEST does not match Dis_BranchPCBits_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_JrRsInst_gold /= Dis_JrRsInst) then
					write (my_outline, string'("ERROR! Dis_JrRsInst of TEST does not match Dis_JrRsInst_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_JalInst_gold /= Dis_JalInst) then
					write (my_outline, string'("ERROR! Dis_JalInst of TEST does not match Dis_JalInst_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_Jr31Inst_gold /= Dis_Jr31Inst) then
					write (my_outline, string'("ERROR! Dis_Jr31Inst of TEST does not match Dis_Jr31Inst_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_FrlRead_gold /= Dis_FrlRead) then
					write (my_outline, string'("ERROR! Dis_FrlRead of TEST does not match Dis_FrlRead_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_RasJalInst_gold /= Dis_RasJalInst) then
					write (my_outline, string'("ERROR! Dis_RasJalInst of TEST does not match Dis_RasJalInst_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_RasJr31Inst_gold /= Dis_RasJr31Inst) then
					write (my_outline, string'("ERROR! Dis_RasJr31Inst of TEST does not match Dis_RasJr31Inst_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_PcPlusFour_gold /= Dis_PcPlusFour) then
					write (my_outline, string'("ERROR! Dis_PcPlusFour of TEST does not match Dis_PcPlusFour_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_PrevPhyAddr_gold /= Dis_PrevPhyAddr) then
					write (my_outline, string'("ERROR! Dis_PrevPhyAddr of TEST does not match Dis_PrevPhyAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_NewRdPhyAddr_gold /= Dis_NewRdPhyAddr) then
					write (my_outline, string'("ERROR! Dis_NewRdPhyAddr of TEST does not match Dis_NewRdPhyAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_RobRdAddr_gold /= Dis_RobRdAddr) then
					write (my_outline, string'("ERROR! Dis_RobRdAddr of TEST does not match Dis_RobRdAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_InstValid_gold /= Dis_InstValid) then
					write (my_outline, string'("ERROR! Dis_InstValid of TEST does not match Dis_InstValid_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_InstSw_gold /= Dis_InstSw) then
					write (my_outline, string'("ERROR! Dis_InstSw of TEST does not match Dis_InstSw_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_SwRtPhyAddr_gold /= Dis_SwRtPhyAddr) then
					write (my_outline, string'("ERROR! Dis_SwRtPhyAddr of TEST does not match Dis_SwRtPhyAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Dis_Instruction_gold /= Dis_Instruction) then
					write (my_outline, string'("ERROR! Dis_Instruction of TEST does not match Dis_Instruction_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
			end if;
		end process compare_outputs_Clkd;

	spy_process: process
		begin
--inputs
			init_signal_spy("/UUT/dispatch_inst/Resetb","Resetb",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Resetb","Resetb",0);

			init_signal_spy("/UUT/dispatch_inst/Ifetch_Instruction","Ifetch_Instruction",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Ifetch_Instruction","Ifetch_Instruction",0);
			
			init_signal_spy("/UUT/dispatch_inst/Ifetch_PcPlusFour","Ifetch_PcPlusFour",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Ifetch_PcPlusFour","Ifetch_PcPlusFour",0);
			
			init_signal_spy("/UUT/dispatch_inst/Ifetch_EmptyFlag","Ifetch_EmptyFlag",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Ifetch_EmptyFlag","Ifetch_EmptyFlag",0);
			
			init_signal_spy("/UUT/dispatch_inst/Bpb_BranchPrediction","Bpb_BranchPrediction",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Bpb_BranchPrediction","Bpb_BranchPrediction",0);
			
			init_signal_spy("/UUT/dispatch_inst/Cdb_Branch","Cdb_Branch",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Cdb_Branch","Cdb_Branch",0);
			
			init_signal_spy("/UUT/dispatch_inst/Cdb_BranchOutcome","Cdb_BranchOutcome",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Cdb_BranchOutcome","Cdb_BranchOutcome",0);
			
			init_signal_spy("/UUT/dispatch_inst/Cdb_BranchAddr","Cdb_BranchAddr",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Cdb_BranchAddr","Cdb_BranchAddr",0);
			
			init_signal_spy("/UUT/dispatch_inst/Cdb_BrUpdtAddr","Cdb_BranchUpdtAddr",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Cdb_BrUpdtAddr","Cdb_BranchUpdtAddr",0);
						
			init_signal_spy("/UUT/dispatch_inst/Cdb_Flush","Cdb_Flush",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Cdb_Flush","Cdb_Flush",0);

			init_signal_spy("/UUT/dispatch_inst/Cdb_RobTag","Cdb_RobTag",1,1);			
			enable_signal_spy("/UUT/dispatch_inst/Cdb_RobTag","Cdb_RobTag",0);
						
			init_signal_spy("/UUT/dispatch_inst/Cfc_RsPhyAddr","Cfc_RsPhyAddr",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Cfc_RsPhyAddr","Cfc_RsPhyAddr",0);

			init_signal_spy("/UUT/dispatch_inst/Cfc_RtPhyAddr","Cfc_RtPhyAddr",1,1);			
			enable_signal_spy("/UUT/dispatch_inst/Cfc_RtPhyAddr","Cfc_RtPhyAddr",0);
			
			init_signal_spy("/UUT/dispatch_inst/Cfc_RdPhyAddr","Cfc_RdPhyAddr",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Cfc_RdPhyAddr","Cfc_RdPhyAddr",0);
			
			init_signal_spy("/UUT/dispatch_inst/Cfc_Full","Cfc_Full",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Cfc_Full","Cfc_Full",0);
			
			init_signal_spy("/UUT/dispatch_inst/PhyReg_RsDataRdy","PhyReg_RsDataRdy",1,1);
			enable_signal_spy("/UUT/dispatch_inst/PhyReg_RsDataRdy","PhyReg_RsDataRdy",0);
			
			init_signal_spy("/UUT/dispatch_inst/PhyReg_RtDataRdy","PhyReg_RtDataRdy",1,1);
			enable_signal_spy("/UUT/dispatch_inst/PhyReg_RtDataRdy","PhyReg_RtDataRdy",0);
			
			init_signal_spy("/UUT/dispatch_inst/Issque_IntQueueFull","Issque_IntQueueFull",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Issque_IntQueueFull","Issque_IntQueueFull",0);
			
			init_signal_spy("/UUT/dispatch_inst/Issque_LdStQueueFull","Issque_LdStQueueFull",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Issque_LdStQueueFull","Issque_LdStQueueFull",0);

			init_signal_spy("/UUT/dispatch_inst/Issque_DivQueueFull","Issque_DivQueueFull",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Issque_DivQueueFull","Issque_DivQueueFull",0);
			
			init_signal_spy("/UUT/dispatch_inst/Issque_MulQueueFull","Issque_MulQueueFull",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Issque_MulQueueFull","Issque_MulQueueFull",0);
			
			init_signal_spy("/UUT/dispatch_inst/Issque_IntQueTwoOrMoreVacant","Issque_IntQueueTwoOrMoreVacant",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Issque_IntQueTwoOrMoreVacant","Issque_IntQueueTwoOrMoreVacant",0);
			
			init_signal_spy("/UUT/dispatch_inst/Issque_LdStQueTwoOrMoreVacant","Issque_LdStQueueTwoOrMoreVacant",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Issque_LdStQueTwoOrMoreVacant","Issque_LdStQueueTwoOrMoreVacant",0);	

			init_signal_spy("/UUT/dispatch_inst/Issque_DivQueTwoOrMoreVacant","Issque_DivQueueTwoOrMoreVacant",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Issque_DivQueTwoOrMoreVacant","Issque_DivQueueTwoOrMoreVacant",0);
			
			init_signal_spy("/UUT/dispatch_inst/Issque_MulQueTwoOrMoreVacant","Issque_MulQueueTwoOrMoreVacant",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Issque_MulQueTwoOrMoreVacant","Issque_MulQueueTwoOrMoreVacant",0);

			init_signal_spy("/UUT/dispatch_inst/Frl_RdPhyAddr","Frl_RdPhyAddr",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Frl_RdPhyAddr","Frl_RdPhyAddr",0);
			
			init_signal_spy("/UUT/dispatch_inst/Frl_Empty","Frl_Empty",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Frl_Empty","Frl_Empty",0);
			
			init_signal_spy("/UUT/dispatch_inst/Ras_Addr","Ras_Addr",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Ras_Addr","Ras_Addr",0);
			
			init_signal_spy("/UUT/dispatch_inst/Rob_BottomPtr","Rob_BottomPtr",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Rob_BottomPtr","Rob_BottomPtr",0);				

			init_signal_spy("/UUT/dispatch_inst/Rob_Full","Rob_Full",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Rob_Full","Rob_Full",0);
			
			init_signal_spy("/UUT/dispatch_inst/Rob_TwoOrMoreVacant","Rob_TwoOrMoreVacant",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Rob_TwoOrMoreVacant","Rob_TwoOrMoreVacant",0);				
--outputs--
			init_signal_spy("/UUT/dispatch_inst/Dis_Ren","Dis_Ren_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_Ren","Dis_Ren_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_JmpBrAddr","Dis_JmpBrAddr_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_JmpBrAddr","Dis_JmpBrAddr_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_JmpBr","Dis_JmpBr_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_JmpBr","Dis_JmpBr_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_JmpBrAddrValid","Dis_JmpBrAddrValid_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_JmpBrAddrValid","Dis_JmpBrAddrValid_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_CdbUpdBranch","Dis_CdbUpdBranch_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_CdbUpdBranch","Dis_CdbUpdBranch_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_CdbUpdBranchAddr","Dis_CdbUpdBranchAddr_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_CdbUpdBranchAddr","Dis_CdbUpdBranchAddr_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_CdbBranchOutcome","Dis_CdbBranchOutcome_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_CdbBranchOutcome","Dis_CdbBranchOutcome_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_BpbBranchPCBits","Dis_BpbBranchPCBits_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_BpbBranchPCBits","Dis_BpbBranchPCBits_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_BpbBranch","Dis_BpbBranch_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_BpbBranch","Dis_BpbBranch_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_CfcRsAddr","Dis_CfcRsAddr_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_CfcRsAddr","Dis_CfcRsAddr_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_CfcRtAddr","Dis_CfcRtAddr_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_CfcRtAddr","Dis_CfcRtAddr_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_CfcRdAddr","Dis_CfcRdAddr_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_CfcRdAddr","Dis_CfcRdAddr_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_CfcBranchTag","Dis_CfcBranchTag_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_CfcBranchTag","Dis_CfcBranchTag_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_CfcRegWrite","Dis_CfcRegWrite_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_CfcRegWrite","Dis_CfcRegWrite_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_CfcNewRdPhyAddr","Dis_CfcNewRdPhyAddr_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_CfcNewRdPhyAddr","Dis_CfcNewRdPhyAddr_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_CfcBranch","Dis_CfcBranch_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_CfcBranch","Dis_CfcBranch_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_CfcInstValid","Dis_CfcInstValid_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_CfcInstValid","Dis_CfcInstValid_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_RegWrite","Dis_RegWrite_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_RegWrite","Dis_RegWrite_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_RsDataRdy","Dis_RsDataRdy_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_RsDataRdy","Dis_RsDataRdy_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_RtDataRdy","Dis_RtDataRdy_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_RtDataRdy","Dis_RtDataRdy_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_RsPhyAddr","Dis_RsPhyAddr_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_RsPhyAddr","Dis_RsPhyAddr_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_RtPhyAddr","Dis_RtPhyAddr_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_RtPhyAddr","Dis_RtPhyAddr_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_RobTag","Dis_RobTag_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_RobTag","Dis_RobTag_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_Opcode","Dis_Opcode_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_Opcode","Dis_Opcode_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_IntIssquenable","Dis_IntIssquenable_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_IntIssquenable","Dis_IntIssquenable_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_LdIssquenable","Dis_LdIssquenable_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_LdIssquenable","Dis_LdIssquenable_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_DivIssquenable","Dis_DivIssquenable_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_DivIssquenable","Dis_DivIssquenable_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_MulIssquenable","Dis_MulIssquenable_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_MulIssquenable","Dis_MulIssquenable_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_Immediate","Dis_Immediate_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_Immediate","Dis_Immediate_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_BranchOtherAddr","Dis_BranchOtherAddr_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_BranchOtherAddr","Dis_BranchOtherAddr_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_BranchPredict","Dis_BranchPredict_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_BranchPredict","Dis_BranchPredict_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_Branch","Dis_Branch_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_Branch","Dis_Branch_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_BranchPCBits","Dis_BranchPCBits_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_BranchPCBits","Dis_BranchPCBits_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_JrRsInst","Dis_JrRsInst_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_JrRsInst","Dis_JrRsInst_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_JalInst","Dis_JalInst_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_JalInst","Dis_JalInst_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_Jr31Inst","Dis_Jr31Inst_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_Jr31Inst","Dis_Jr31Inst_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_FrlRead","Dis_FrlRead_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_FrlRead","Dis_FrlRead_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_RasJalInst","Dis_RasJalInst_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_RasJalInst","Dis_RasJalInst_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_RasJr31Inst","Dis_RasJr31Inst_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_RasJr31Inst","Dis_RasJr31Inst_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_PcPlusFour","Dis_PcPlusFour_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_PcPlusFour","Dis_PcPlusFour_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_PrevPhyAddr","Dis_PrevPhyAddr_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_PrevPhyAddr","Dis_PrevPhyAddr_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_NewRdPhyAddr","Dis_NewRdPhyAddr_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_NewRdPhyAddr","Dis_NewRdPhyAddr_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_RobRdAddr","Dis_RobRdAddr_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_RobRdAddr","Dis_RobRdAddr_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_InstValid","Dis_InstValid_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_InstValid","Dis_InstValid_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_InstSw","Dis_InstSw_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_InstSw","Dis_InstSw_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_SwRtPhyAddr","Dis_SwRtPhyAddr_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_SwRtPhyAddr","Dis_SwRtPhyAddr_gold",0);
			
			init_signal_spy("/UUT/dispatch_inst/Dis_Instruction","Dis_Instruction_gold",1,1);
			enable_signal_spy("/UUT/dispatch_inst/Dis_Instruction","Dis_Instruction_gold",0);
			
		wait;
	end process spy_process;			

end architecture arch_top_tb_Dispatch;
