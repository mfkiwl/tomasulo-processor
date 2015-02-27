-------------------------------------------------------------------------------
-- Design   : Signal Spy testbench for IssueQue
-- Project  : Tomasulo Processor 
-- Author   : Prasanjeet Das
-- Data		: July 15,2010
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

architecture arch_top_tb_Issue_Queue of top_tb is

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
	
-- Hierarchy signals (Golden Issue_Queue)
      signal resetb : std_logic;
      -- Information to be captured from the Output of LsBuffer
      signal Lsbuf_PhyAddr_gold     :  std_logic_vector(5 downto 0) ;
	  signal Lsbuf_RdWrite_gold     :  std_logic;
	  signal Iss_Lsb_gold           :  std_logic;
	  
	    -- Information to be captured from the Write port of Physical Register file
      signal Cdb_RdPhyAddr_gold     :  std_logic_vector(5 downto 0) ;
      signal Cdb_PhyRegWrite_gold   :  std_logic;

      -- Information from the Dispatch Unit 
      signal Dis_Issquenable_gold                : std_logic ; 
      signal Dis_RsDataRdy_gold                  : std_logic ;
      signal Dis_RtDataRdy_gold                  : std_logic ;
	  signal Dis_RegWrite_gold                   : std_logic;
      signal Dis_RsPhyAddr_gold                  : std_logic_vector ( 5 downto 0 ) ;
      signal Dis_RtPhyAddr_gold                  : std_logic_vector ( 5 downto 0 ) ;
      signal Dis_NewRdPhyAddr_gold               : std_logic_vector ( 5 downto 0 ) ;
	  signal Dis_RobTag_gold                     : std_logic_vector ( 4 downto 0 ) ;
      signal Dis_Opcode_gold                     : std_logic_vector ( 2 downto 0 ) ;
	  signal Dis_Immediate_gold                  : std_logic_vector ( 15 downto 0 );
	  signal Dis_Branch_gold                     : std_logic;
	  signal Dis_BranchPredict_gold              : std_logic;
	  signal Dis_BranchOtherAddr_gold            :std_logic_vector ( 31 downto 0 );
	  signal Dis_BranchPCBits_gold               :std_logic_vector ( 2 downto 0 ) ;
      signal Issque_IntQueueFull_gold            :std_logic ;
	  signal Issque_IntQueueTwoOrMoreVacant_gold : std_logic;
	  signal Dis_Jr31Inst_gold                   : std_logic;
	  signal Dis_JalInst_gold                    : std_logic;
	  signal Dis_JrRsInst_gold                   : std_logic;
	  
	 -- translate_off 
      signal Dis_instruction_gold                : std_logic_vector(31 downto 0);
	 -- translate_on
	 
     -- Interface with the Issue Unit
      signal IssInt_Rdy_gold                     : std_logic ;
	  signal Iss_Int_gold                        : std_logic ;
		
	  -- Interface with the Multiply execution unit
	  signal Mul_RdPhyAddr_gold                  : std_logic_vector(5 downto 0);
	  signal Mul_ExeRdy_gold                     : std_logic;
	  signal Div_RdPhyAddr_gold                  : std_logic_vector(5 downto 0);
	  signal Div_ExeRdy_gold                     : std_logic;
	  
	  -- Interface with the Physical Register File
      signal Iss_RsPhyAddrAlu_gold               : std_logic_vector(5 downto 0) ; 
      signal Iss_RtPhyAddrAlu_gold               : std_logic_vector(5 downto 0) ; 
     
	  
	  -- Interface with the Execution unit (ALU)
	  signal Iss_RdPhyAddrAlu_gold               : std_logic_vector(5 downto 0) ;
	  signal Iss_RobTagAlu_gold                  : std_logic_vector(4 downto 0);
	  signal Iss_OpcodeAlu_gold                  : std_logic_vector(2 downto 0) ; --add branch information 
	  signal Iss_BranchAddrAlu_gold              : std_logic_vector(31 downto 0);		
      signal Iss_BranchAlu_gold     		     : std_logic;
	  signal Iss_RegWriteAlu_gold                : std_logic;
	  signal Iss_BranchUptAddrAlu_gold           : std_logic_vector(2 downto 0);
	  signal Iss_BranchPredictAlu_gold           : std_logic;
	  signal Iss_JalInstAlu_gold                 : std_logic;
	  signal Iss_JrInstAlu_gold                  : std_logic;
      signal Iss_JrRsInstAlu_gold                : std_logic;  
	  signal Iss_ImmediateAlu_gold               : std_logic_vector(15 downto 0);
	
   	 -- translate_off 
      signal Iss_instructionAlu_gold             : std_logic_vector(31 downto 0);
	 -- translate_on
	 
      --  Interface with ROB 
      signal Cdb_Flush_gold                      : std_logic;
      signal Rob_TopPtr_gold                     : std_logic_vector ( 4 downto 0 ) ;
      signal Cdb_RobDepth_gold                   : std_logic_vector ( 4 downto 0 ); 
   
-- Signals for the student's DUT (Issue_Queue)
   -- Information to be captured from the Output of LsBuffer
     signal Lsbuf_PhyAddr     :  std_logic_vector(5 downto 0) ;
	  signal Lsbuf_RdWrite     :  std_logic;
	  signal Iss_Lsb           :  std_logic;
	  
	    -- Information to be captured from the Write port of Physical Register file
      signal Cdb_RdPhyAddr     :  std_logic_vector(5 downto 0) ;
      signal Cdb_PhyRegWrite   :  std_logic;

      -- Information from the Dispatch Unit 
      signal Dis_Issquenable                : std_logic ; 
      signal Dis_RsDataRdy                  : std_logic ;
      signal Dis_RtDataRdy                  : std_logic ;
	  signal Dis_RegWrite                   : std_logic;
      signal Dis_RsPhyAddr                  : std_logic_vector ( 5 downto 0 ) ;
      signal Dis_RtPhyAddr                  : std_logic_vector ( 5 downto 0 ) ;
      signal Dis_NewRdPhyAddr               : std_logic_vector ( 5 downto 0 ) ;
	  signal Dis_RobTag                     : std_logic_vector ( 4 downto 0 ) ;
      signal Dis_Opcode                     : std_logic_vector ( 2 downto 0 ) ;
	  signal Dis_Immediate                  : std_logic_vector ( 15 downto 0 );
	  signal Dis_Branch                    : std_logic;
	  signal Dis_BranchPredict              : std_logic;
	  signal Dis_BranchOtherAddr            :std_logic_vector ( 31 downto 0 );
	  signal Dis_BranchPCBits               :std_logic_vector ( 2 downto 0 ) ;
      signal Issque_IntQueueFull            :std_logic ;
	  signal Issque_IntQueueTwoOrMoreVacant : std_logic;
	  signal Dis_Jr31Inst                   : std_logic;
	  signal Dis_JalInst                    : std_logic;
	  signal Dis_JrRsInst                   : std_logic;
	  
	 -- translate_off 
      signal Dis_instruction                : std_logic_vector(31 downto 0);
	 -- translate_on
	 
     -- Interface with the Issue Unit
      signal IssInt_Rdy                     : std_logic ;
	  signal Iss_Int                        : std_logic ;
		
	  -- Interface with the Multiply execution unit
	  signal Mul_RdPhyAddr                  : std_logic_vector(5 downto 0);
	  signal Mul_ExeRdy                     : std_logic;
	  signal Div_RdPhyAddr                  : std_logic_vector(5 downto 0);
	  signal Div_ExeRdy                     : std_logic;
	  
	  -- Interface with the Physical Register File
      signal Iss_RsPhyAddrAlu               : std_logic_vector(5 downto 0) ; 
      signal Iss_RtPhyAddrAlu               : std_logic_vector(5 downto 0) ; 
     
	  
	  -- Interface with the Execution unit (ALU)
	  signal Iss_RdPhyAddrAlu               : std_logic_vector(5 downto 0) ;
	  signal Iss_RobTagAlu                  : std_logic_vector(4 downto 0);
	  signal Iss_OpcodeAlu                  : std_logic_vector(2 downto 0) ; --add branch information 
	  signal Iss_BranchAddrAlu              : std_logic_vector(31 downto 0);		
      signal Iss_BranchAlu      		    : std_logic;
	  signal Iss_RegWriteAlu                : std_logic;
	  signal Iss_BranchUptAddrAlu           : std_logic_vector(2 downto 0);
	  signal Iss_BranchPredictAlu           : std_logic;
	  signal Iss_JalInstAlu                 : std_logic;
	  signal Iss_JrInstAlu                  : std_logic;
      signal Iss_JrRsInstAlu                : std_logic;  
	  signal Iss_ImmediateAlu               : std_logic_vector(15 downto 0);
	
   	 -- translate_off 
      signal Iss_instructionAlu             : std_logic_vector(31 downto 0);
	 -- translate_on
	 
      --  Interface with ROB 
      signal Cdb_Flush                      : std_logic;
      signal Rob_TopPtr                     : std_logic_vector ( 4 downto 0 ) ;
      signal Cdb_RobDepth                   : std_logic_vector ( 4 downto 0 ); 

   
 -- component declaration
	component tomasulo_top
	port (
		Reset     : in std_logic;
		Clk : in std_logic;
		-- signals corresponding to Instruction memory
		Fio_Icache_Addr_IM  : in  std_logic_vector(5 downto 0);
		Fio_Icache_Data_In_IM     : in  std_logic_vector(127 downto 0);
		Fio_Icache_Wea_IM   : in  std_logic; 
		Fio_Icache_Data_Out_IM    : out std_logic_vector(127 downto 0);
		Fio_Icache_Ena_IM		     : in  std_logic;
		Fio_Dmem_Addr_DM    : in std_logic_vector(5 downto 0);
		Fio_Dmem_Data_Out_DM: out std_logic_vector(31 downto 0);	
		Fio_Dmem_Data_In_DM : in std_logic_vector(31 downto 0);
		Fio_Dmem_Wea_DM    		  : in std_logic;
		Test_mode     : in std_logic; -- for using the test mode 
		Walking_Led_start   : out std_logic
	);
	end component tomasulo_top;
	
component issueque  
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
end component issueque;

 	
	begin

	UUT: tomasulo_top
	port map (
		Reset  =>   Reset,
		Clk    =>   Clk,
		Fio_Icache_Addr_IM     => Fio_Icache_Addr_IM,
		Fio_Icache_Data_In_IM  => Fio_Icache_Data_In_IM, 
		Fio_Icache_Wea_IM=> Fio_Icache_Wea_IM , 
		Fio_Icache_Data_Out_IM => Fio_Icache_Data_Out_IM,
		Fio_Icache_Ena_IM		    => Fio_Icache_Ena_IM,
		Fio_Dmem_Addr_DM => Fio_Dmem_Addr_DM,
		Fio_Dmem_Data_Out_DM   => Fio_Dmem_Data_Out_DM,	
		Fio_Dmem_Data_In_DM    => Fio_Dmem_Data_In_DM,
		Fio_Dmem_Wea_DM    		  => Fio_Dmem_Wea_DM,
		Test_mode  => '0',  
		Walking_Led_start=> Walking_Led
    );

	issueque_UUT:  issueque
	port map (                
	           Clk                                               => Clk,   
	           Resetb                                            => Resetb,   
	           Lsbuf_PhyAddr                                     => Lsbuf_PhyAddr,  
	           Lsbuf_RdWrite                                     => Lsbuf_RdWrite,  
	           Iss_Lsb                                           => Iss_Lsb,
	           Cdb_RdPhyAddr                                     => Cdb_RdPhyAddr,
               Cdb_PhyRegWrite                                   => Cdb_PhyRegWrite,   
               Dis_Issquenable                                   => Dis_Issquenable, 
               Dis_RsDataRdy                                     => Dis_RsDataRdy,    
               Dis_RtDataRdy                                     => Dis_RtDataRdy,
	           Dis_RegWrite                                      => Dis_RegWrite,     
               Dis_RsPhyAddr                                     => Dis_RsPhyAddr,  
               Dis_RtPhyAddr                                     => Dis_RtPhyAddr,    
               Dis_NewRdPhyAddr                                  => Dis_NewRdPhyAddr,     
	           Dis_RobTag                                        =>  Dis_RobTag,        
               Dis_Opcode                                        =>  Dis_Opcode,       
	           Dis_Immediate                                     => Dis_Immediate,     
	           Dis_Branch                                        => Dis_Branch,        
	           Dis_BranchPredict                                 => Dis_BranchPredict,  
	           Dis_BranchOtherAddr                               => Dis_BranchOtherAddr, 
	           Dis_BranchPCBits                                  => Dis_BranchPCBits,   
               Issque_IntQueueFull                               => Issque_IntQueueFull,
	           Issque_IntQueueTwoOrMoreVacant                    => Issque_IntQueueTwoOrMoreVacant,
	           Dis_Jr31Inst                                      => Dis_Jr31Inst,        
	           Dis_JalInst                                       => Dis_JalInst,     
	           Dis_JrRsInst                                      => Dis_JrRsInst,     
	           Dis_instruction                                   => Dis_instruction,
	           IssInt_Rdy                                        => IssInt_Rdy,      
	           Iss_Int                                           => Iss_Int,          		
	           Mul_RdPhyAddr                                     => Mul_RdPhyAddr,      
	           Mul_ExeRdy                                        => Mul_ExeRdy,       
	           Div_RdPhyAddr                                     => Div_RdPhyAddr,       
	           Div_ExeRdy                                        => Div_ExeRdy,   
			   Iss_RsPhyAddrAlu                                  => Iss_RsPhyAddrAlu,    
               Iss_RtPhyAddrAlu                                  => Iss_RtPhyAddrAlu,   
	           Iss_RdPhyAddrAlu                                  => Iss_RdPhyAddrAlu,    
	           Iss_RobTagAlu                                     => Iss_RobTagAlu,     
	           Iss_OpcodeAlu                                     => Iss_OpcodeAlu,      
	           Iss_BranchAddrAlu                                 => Iss_BranchAddrAlu,   		
               Iss_BranchAlu	                                 => Iss_BranchAlu,	    
	           Iss_RegWriteAlu                                   => Iss_RegWriteAlu ,       
	           Iss_BranchUptAddrAlu                              => Iss_BranchUptAddrAlu,  
	           Iss_BranchPredictAlu                              => Iss_BranchPredictAlu,    
	           Iss_JalInstAlu                                    => Iss_JalInstAlu,      
	           Iss_JrInstAlu                                     => Iss_JrInstAlu,       
               Iss_JrRsInstAlu                                   => Iss_JrRsInstAlu,      
	           Iss_ImmediateAlu                                  => Iss_ImmediateAlu,     
	           Iss_instructionAlu                                => Iss_instructionAlu,    
               Cdb_Flush                                         => Cdb_Flush,            
               Rob_TopPtr                                        => Rob_TopPtr,          
               Cdb_RobDepth                                      => Cdb_RobDepth 
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
		  --check outputs of IssueQue only--
-------------------------------------------------
  
	            
	 
	

	compare_outputs_Clkd: process (Clk_Delayed10, Reset)
		file my_outfile: text open append_mode is "TomasuloCompareTestLog.log";
		variable my_inline, my_outline: line;

		begin
			if (Reset = '0' and (Clk_Delayed10'event and Clk_Delayed10 = '0')) then			--- 10%after the middle of the clock.
				if (Issque_IntQueueFull_gold /=Issque_IntQueueFull) then
					write (my_outline, string'("ERROR! Issque_IntQueueFull of TEST does not match Issque_IntQueueFull_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if ( IssInt_Rdy_gold /=  IssInt_Rdy) then
					write (my_outline, string'("ERROR!  IssInt_Rdy of TEST does not match  IssInt_Rdy_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Iss_RsPhyAddrAlu_gold /= Iss_RsPhyAddrAlu) then
					write (my_outline, string'("ERROR! Iss_RsPhyAddrAlu of TEST does not match Iss_RsPhyAddrAlu_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Iss_RtPhyAddrAlu_gold /= Iss_RtPhyAddrAlu ) then
					write (my_outline, string'("ERROR! Iss_RtPhyAddrAlu of TEST does not match Iss_RtPhyAddrAlu_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				
				if (Iss_RdPhyAddrAlu_gold /=Iss_RdPhyAddrAlu ) then
					write (my_outline, string'("ERROR! Iss_RdPhyAddrAlu  of TEST does not match Iss_RdPhyAddrAlu _gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if ( Iss_RobTagAlu_gold /=  Iss_RobTagAlu) then
					write (my_outline, string'("ERROR!  Iss_RobTagAlu of TEST does not match  Iss_RobTagAlu_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Iss_OpcodeAlu_gold /= Iss_OpcodeAlu) then
					write (my_outline, string'("ERROR! Iss_OpcodeAlu of TEST does not match Iss_OpcodeAlu_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Iss_BranchAddrAlu_gold /= Iss_BranchAddrAlu ) then
					write (my_outline, string'("ERROR! Iss_BranchAddrAlu of TEST does not match Iss_BranchAddrAlu_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				
				
				if (Iss_BranchAlu_gold /= Iss_BranchAlu) then
					write (my_outline, string'("ERROR! Iss_BranchAlu of TEST does not match Iss_BranchAlu_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Iss_RegWriteAlu_gold /= Iss_RegWriteAlu ) then
					write (my_outline, string'("ERROR! Iss_RegWriteAlu of TEST does not match Iss_RegWriteAlu_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				
				if (Iss_BranchUptAddrAlu_gold /= Iss_BranchUptAddrAlu) then
					write (my_outline, string'("ERROR! Iss_BranchUptAddrAlu of TEST does not match Iss_BranchUptAddrAlu_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Iss_BranchPredictAlu_gold /= Iss_BranchPredictAlu ) then
					write (my_outline, string'("ERROR! Iss_BranchPredictAlu of TEST does not match Iss_BranchPredictAlu_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				
				if (Iss_JalInstAlu_gold /= Iss_JalInstAlu) then
					write (my_outline, string'("ERROR! Iss_JalInstAlu of TEST does not match Iss_JalInstAlu_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if (Iss_JrInstAlu_gold /= Iss_JrInstAlu ) then
					write (my_outline, string'("ERROR! Iss_JrInstAlu of TEST does not match Iss_JrInstAlu_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				
				if (Iss_JrRsInstAlu_gold /= Iss_JrRsInstAlu ) then
					write (my_outline, string'("ERROR! Iss_JrRsInstAlu  of TEST does not match Iss_JrRsInstAlu_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				if ( Iss_ImmediateAlu_gold /=  Iss_ImmediateAlu  ) then
					write (my_outline, string'("ERROR!  Iss_ImmediateAlu  of TEST does not match  Iss_ImmediateAlu_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				
				if (Iss_instructionAlu_gold /= Iss_instructionAlu ) then
					write (my_outline, string'("ERROR! Iss_instructionAlu  of TEST does not match Iss_instructionAlu_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				
				if (Issque_IntQueueTwoOrMoreVacant_gold /= Issque_IntQueueTwoOrMoreVacant ) then
					write (my_outline, string'("ERROR! Issque_IntQueueTwoOrMoreVacant  of TEST does not match Issque_IntQueueTwoOrMoreVacant_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				
			end if;
		end process compare_outputs_Clkd;

	spy_process: process
		begin
--inputs
			init_signal_spy("/UUT/integer_queue_inst/Resetb","Resetb",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Resetb","Resetb",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Lsbuf_PhyAddr","Lsbuf_PhyAddr",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Lsbuf_PhyAddr","Lsbuf_PhyAddr",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Lsbuf_RdWrite","Lsbuf_RdWrite",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Lsbuf_RdWrite","Lsbuf_RdWrite",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Iss_Lsb","Iss_Lsb",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Iss_Lsb","Iss_Lsb",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Cdb_PhyRegWrite","Cdb_PhyRegWrite",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Cdb_PhyRegWrite","Cdb_PhyRegWrite",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Cdb_RdPhyAddr","Cdb_RdPhyAddr",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Cdb_RdPhyAddr","Cdb_RdPhyAddr",0);
			----------------
            
			init_signal_spy("/UUT/integer_queue_inst/Dis_Issquenable","Dis_Issquenable",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_Issquenable","Dis_Issquenable",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Dis_RsDataRdy","Dis_RsDataRdy",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_RsDataRdy","Dis_RsDataRdy",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Dis_RtDataRdy","Dis_RtDataRdy",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_RtDataRdy","Dis_RtDataRdy",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Dis_RegWrite","Dis_RegWrite",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_RegWrite","Dis_RegWrite",0);
	   
	        ----------------
            
			init_signal_spy("/UUT/integer_queue_inst/Dis_RsPhyAddr","Dis_RsPhyAddr",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_RsPhyAddr","Dis_RsPhyAddr",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Dis_RtPhyAddr","Dis_RtPhyAddr",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_RtPhyAddr","Dis_RtPhyAddr",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Dis_NewRdPhyAddr","Dis_NewRdPhyAddr",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_NewRdPhyAddr","Dis_NewRdPhyAddr",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Dis_RobTag","Dis_RobTag",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_RobTag","Dis_RobTag",0);
	 
            ----------------
            
			init_signal_spy("/UUT/integer_queue_inst/Dis_Opcode","Dis_Opcode",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_Opcode","Dis_Opcode",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Dis_Immediate","Dis_Immediate",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_Immediate","Dis_Immediate",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Dis_Branch","Dis_Branch",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_Branch","Dis_Branch",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Dis_BranchPredict","Dis_BranchPredict",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_BranchPredict","Dis_BranchPredict",0);
	 
	        ----------------
            
			init_signal_spy("/UUT/integer_queue_inst/Dis_BranchOtherAddr","Dis_BranchOtherAddr",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_BranchOtherAddr","Dis_BranchOtherAddr",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Dis_BranchPCBits","Dis_BranchPCBits",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_BranchPCBits","Dis_BranchPCBits",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Dis_Jr31Inst","Dis_Jr31Inst",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_Jr31Inst","Dis_Jr31Inst",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Dis_JalInst","Dis_JalInst",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_JalInst","Dis_JalInst",0);

			 ----------------
            
			init_signal_spy("/UUT/integer_queue_inst/Dis_JrRsInst","Dis_JrRsInst",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_JrRsInst","Dis_JrRsInst",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Dis_instruction","Dis_instruction",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Dis_instruction","Dis_instruction",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Iss_Int","Iss_Int",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Iss_Int","Iss_Int",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Mul_RdPhyAddr","Mul_RdPhyAddr",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Mul_RdPhyAddr","Mul_RdPhyAddr",0);
	   
	  ----------------
            
			init_signal_spy("/UUT/integer_queue_inst/Mul_ExeRdy","Mul_ExeRdy",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Mul_ExeRdy","Mul_ExeRdy",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Div_RdPhyAddr","Div_RdPhyAddr",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Div_RdPhyAddr","Div_RdPhyAddr",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Div_ExeRdy","Div_ExeRdy",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Div_ExeRdy","Div_ExeRdy",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Cdb_Flush","Cdb_Flush",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Cdb_Flush","Cdb_Flush",0);
	    
		    init_signal_spy("/UUT/integer_queue_inst/Rob_TopPtr","Rob_TopPtr",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Rob_TopPtr","Rob_TopPtr",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Cdb_RobDepth","Cdb_RobDepth",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Cdb_RobDepth","Cdb_RobDepth",0);
	          
							
--outputs--
            init_signal_spy("/UUT/integer_queue_inst/Issque_IntQueueFull","Issque_IntQueueFull_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Issque_IntQueueFull","Issque_IntQueueFull_gold",0);
			
			init_signal_spy("/UUT/integer_queue_inst/IssInt_Rdy","IssInt_Rdy_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/IssInt_Rdy","IssInt_Rdy_gold",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Iss_RsPhyAddrAlu","Iss_RsPhyAddrAlu_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Iss_RsPhyAddrAlu","Iss_RsPhyAddrAlu_gold",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Issque_IntQueueTwoOrMoreVacant","Issque_IntQueueTwoOrMoreVacant_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Issque_IntQueueTwoOrMoreVacant","Issque_IntQueueTwoOrMoreVacant_gold",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Iss_RtPhyAddrAlu ","Iss_RtPhyAddrAlu_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Iss_RtPhyAddrAlu "," Iss_RtPhyAddrAlu _gold",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Iss_RdPhyAddrAlu","Iss_RdPhyAddrAlu_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Iss_RdPhyAddrAlu","Iss_RdPhyAddrAlu_gold",0);
	
            -------
			init_signal_spy("/UUT/integer_queue_inst/Iss_RobTagAlu","Iss_RobTagAlu_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Iss_RobTagAlu","Iss_RobTagAlu_gold",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Iss_OpcodeAlu","Iss_OpcodeAlu_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Iss_OpcodeAlu","Iss_OpcodeAlu_gold",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Iss_BranchAddrAlu","Iss_BranchAddrAlu_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Iss_BranchAddrAlu","Iss_BranchAddrAlu_gold",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Iss_BranchAlu","Iss_BranchAlu_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Iss_BranchAlu","Iss_BranchAlu_gold",0);
			
			-------
			init_signal_spy("/UUT/integer_queue_inst/Iss_RegWriteAlu","Iss_RegWriteAlu_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Iss_RegWriteAlu","Iss_RegWriteAlu_gold",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Iss_BranchUptAddrAlu","Iss_BranchUptAddrAlu_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Iss_BranchUptAddrAlu","Iss_BranchUptAddrAlu_gold",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Iss_JalInstAlu","Iss_JalInstAlu_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Iss_JalInstAlu","Iss_JalInstAlu_gold",0);
			
			-------
			init_signal_spy("/UUT/integer_queue_inst/Iss_JrInstAlu","Iss_JrInstAlu_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Iss_JrInstAlu","Iss_JrInstAlu_gold",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Iss_JrRsInstAlu","Iss_JrRsInstAlu_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Iss_JrRsInstAlu","Iss_JrRsInstAlu_gold",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Iss_ImmediateAlu","Iss_ImmediateAlu_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Iss_ImmediateAlu","Iss_ImmediateAlu_gold",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Iss_instructionAlu","Iss_instructionAlu_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Iss_instructionAlu","Iss_instructionAlu_gold",0);
			
			init_signal_spy("/UUT/integer_queue_inst/Iss_BranchPredictAlu","Iss_BranchPredictAlu_gold",1,1);
			enable_signal_spy("/UUT/integer_queue_inst/Iss_BranchPredictAlu","Iss_BranchPredictAlu_gold",0);
		wait;
	end process spy_process;			

end architecture arch_top_tb_Issue_Queue;
