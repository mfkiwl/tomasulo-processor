-------------------------------------------------------------------------------
-- Design   : Signal Spy testbench for Branch Prediction Buffer
-- Project  : Tomasulo Processor 
-- Author   : Da Cheng
-- Data		: June,2010
-- Company  : University of Southern California 
-------------------------------------------------------------------------------
library std,ieee;
library modelsim_lib;
use ieee.std_logic_1164.all;
use modelsim_lib.util.all;
use std.textio.all;
use ieee.std_logic_textio.all;

-- synopsys translate_off
--use reverseAssemblyFunctionPkg.all; --modified by sabya - not needed in top!
-- synopsys translate_on
-----------------------------------------------------------------------------

--added by Sabya to use compiled library
library ee560;
use ee560.all;
------------------------------------------------------------------------------

entity top_tb is
end entity top_tb;

architecture arch_top_tb_ROB of top_tb is

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
	
-- Hierarchy signals (Golden CFC)


signal			Cfc_RdPhyAddr_gold            :std_logic_vector(5 downto 0); 	     --Previous Physical Register Address of Rd
signal			Cfc_RsPhyAddr_gold	         :std_logic_vector(5 downto 0);          --Latest Physical Register Address of Rs
signal			Cfc_RtPhyAddr_gold	         :std_logic_vector(5 downto 0);          --Latest Physical Register Address of Rt
signal			Cfc_Full_gold                 :std_logic;							 --Flag indicating whether checkpoint table is full or not
		
		--signals from cfc to ROB in case of CDB flush
signal			Cfc_RobTag_gold               :std_logic_vector(4 downto 0);          --Rob Tag of the instruction to which rob_bottom is moved after branch misprediction (also to php)
	
		--interface with FRL

signal			Cfc_FrlHeadPtr_gold           :std_logic_vector(4 downto 0);          --Value to which FRL has to jump on CDB Flush

	
	
	
	
	
-- Signals for the student's UUT (CFC)



signal		Resetb			         : std_logic;                              --Global Reset Signal
		--interface with dispatch unit
signal		Dis_CfcInstValid            : std_logic;                              --Flag indicating if the instruction dispatched is valid or not
signal		Dis_CfcBranchTag         : std_logic_vector(4 downto 0);           --ROB Tag of the branch instruction 
signal			Dis_CfcRdAddr            : std_logic_vector(4 downto 0);           --Rd Logical Address
signal			Dis_CfcRsAddr            : std_logic_vector(4 downto 0);			 --Rs Logical Address
signal			Dis_CfcRtAddr            : std_logic_vector(4 downto 0);			 --Rt Logical Address
signal			Dis_CfcNewRdPhyAddr      : std_logic_vector(5 downto 0);           --New Physical Register Address assigned to Rd by Dispatch
signal			Dis_CfcRegWrite          : std_logic;                              --Flag indicating whether current instruction being dispatched is register writing or not
signal			Dis_CfcBranch            : std_logic;                              --Flag indicating whether current instruction being dispatched is branch or not
signal			Dis_RasJr31Inst             : std_logic;                              --Flag indicating if the current instruction is Jr 31 or not
		
signal			Cfc_RdPhyAddr            :std_logic_vector(5 downto 0); 	     --Previous Physical Register Address of Rd
signal			Cfc_RsPhyAddr	         :std_logic_vector(5 downto 0);          --Latest Physical Register Address of Rs
signal			Cfc_RtPhyAddr	         :std_logic_vector(5 downto 0);          --Latest Physical Register Address of Rt
signal			Cfc_Full                 :std_logic;							 --Flag indicating whether checkpoint table is full or not
						
		--interface with ROB
signal			Rob_TopPtr		         :std_logic_vector(4 downto 0);		     --ROB tag of the intruction at the Top
signal			Rob_Commit               :std_logic;                              --Flag indicating whether instruction is committing in this cycle or not
signal			Rob_CommitRdAddr         :std_logic_vector(4 downto 0);           --Rd Logical Address of committing instruction
signal			Rob_CommitRegWrite       :std_logic;					             --Indicates if instruction is writing to register or not
signal			Rob_CommitCurrPhyAddr    :std_logic_vector(5 downto 0);			 --Physical Register Address of Rd of committing instruction			
		
		--signals from cfc to ROB in case of CDB flush
signal			Cfc_RobTag               :std_logic_vector(4 downto 0);          --Rob Tag of the instruction to which rob_bottom is moved after branch misprediction (also to php)
	
		--interface with FRL
signal			Frl_HeadPtr              :std_logic_vector(4 downto 0);           --Head Pointer of the FRL when a branch is dispatched
signal			Cfc_FrlHeadPtr           :std_logic_vector(4 downto 0);          --Value to which FRL has to jump on CDB Flush
 		
		--interface with CDB
signal			Cdb_Flush  		         :std_logic;                              --Flag indicating that current instruction is mispredicted or not
signal			Cdb_RobTag               :std_logic_vector(4 downto 0);		     --ROB Tag of the mispredicted branch
signal			Cdb_RobDepth		     :std_logic_vector(4 downto 0);			 --Depth of mispredicted branch from ROB Top





  	
	
 -- component declaration
	component tomasulo_top
	port (
		Reset     : in std_logic;
		Clk : in std_logic;
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

 
	for	CFC_UUT: cfc use entity work.cfc(cfc_arch);
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

	CFC_UUT : cfc
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
		  --check outputs of Branch Prediction Buffer only--
-------------------------------------------------
	compare_outputs_Clkd: process (Clk_Delayed10, Reset)
		file my_outfile: text open write_mode is "TomasuloCompareTestLog.log";
		variable my_inline, my_outline: line;

		begin
			if (Reset = '0' and (Clk_Delayed10'event and Clk_Delayed10 = '0')) then			--- 10%after the middle of the clock.
				--if (Bpb_BranchPrediction_gold /= Bpb_BranchPrediction) then
				--	write (my_outline, string'("ERROR! Bpb_BranchPrediction of TEST does not match Bpb_BranchPrediction_gold at clock_count = " & integer'image(Clk_Count)));
				--	writeline (my_outfile, my_outline);
				--end if;
				
					
					
				
					
					
							
				
				if ( Cfc_RdPhyAddr/= Cfc_RdPhyAddr_gold) then
					write (my_outline, string'("ERROR!  Cfc_RdPhyAddr of TEST does not match Cfc_RdPhyAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;
				
				if ( Cfc_RsPhyAddr/= Cfc_RsPhyAddr_gold) then
					write (my_outline, string'("ERROR! Cfc_RsPhyAddr  of TEST does not match  Cfc_RsPhyAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;

				if ( Cfc_RtPhyAddr /= Cfc_RtPhyAddr_gold	) then
					write (my_outline, string'("ERROR! Cfc_RtPhyAddr of TEST does not match Cfc_RtPhyAddr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;

				if ( Cfc_FrlHeadPtr /= Cfc_FrlHeadPtr_gold) then
					write (my_outline, string'("ERROR! Cfc_FrlHeadPtr of TEST does not match Cfc_FrlHeadPtr_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;

				if ( Cfc_RobTag /= Cfc_RobTag_gold		) then
					write (my_outline, string'("ERROR! Cfc_RobTag of TEST does not match Cfc_RobTag_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;

				if ( Cfc_Full /= Cfc_Full_gold) then
					write (my_outline, string'("ERROR! Cfc_Full of TEST does not match Cfc_Full_gold at clock_count = " & integer'image(Clk_Count)));
					writeline (my_outfile, my_outline);
				end if;				
				
			end if;
		end process compare_outputs_Clkd;

	spy_process: process
		begin
--inputs
			init_signal_spy("/UUT/Resetb","Resetb",1,1);
--			enable_signal_spy("/UUT/Resetb","Resetb",0);
			
			init_signal_spy("/UUT/Dis_CfcInstValid","Dis_CfcInstValid",1,1);
			init_signal_spy("/UUT/Dis_CfcBranchTag","Dis_CfcBranchTag",1,1);
			init_signal_spy("/UUT/Dis_CfcRdAddr","Dis_CfcRdAddr",1,1);
			init_signal_spy("/UUT/Dis_CfcRsAddr","Dis_CfcRsAddr",1,1);
			init_signal_spy("/UUT/Dis_CfcRtAddr","Dis_CfcRtAddr",1,1);
			init_signal_spy("/UUT/Dis_CfcNewRdPhyAddr","Dis_CfcNewRdPhyAddr",1,1);
			init_signal_spy("/UUT/Dis_CfcRegWrite","Dis_CfcRegWrite",1,1);
			init_signal_spy("/UUT/Dis_CfcBranch","Dis_CfcBranch",1,1);
			init_signal_spy("/UUT/Dis_RasJr31Inst","Dis_RasJr31Inst",1,1);
			init_signal_spy("/UUT/Rob_TopPtr","Rob_TopPtr",1,1);
			init_signal_spy("/UUT/Rob_Commit","Rob_Commit",1,1);
			init_signal_spy("/UUT/Rob_CommitRdAddr","Rob_CommitRdAddr",1,1);
			init_signal_spy("/UUT/Rob_CommitRegWrite","Rob_CommitRegWrite",1,1);
			
			init_signal_spy("/UUT/Rob_CommitCurrPhyAddr","Rob_CommitCurrPhyAddr",1,1);
			init_signal_spy("/UUT/Frl_HeadPtr","Frl_HeadPtr",1,1);
			init_signal_spy("/UUT/Cdb_Flush","Cdb_Flush",1,1);
			init_signal_spy("/UUT/Cdb_RobTag","Cdb_RobTag",1,1);
			init_signal_spy("/UUT/Cdb_RobDepth","Cdb_RobDepth",1,1);	    
			
--outputs--
			init_signal_spy("/UUT/Cfc_RdPhyAddr","Cfc_RdPhyAddr_gold",1,1);
			init_signal_spy("/UUT/Cfc_RsPhyAddr","Cfc_RsPhyAddr_gold",1,1);
			init_signal_spy("/UUT/Cfc_RtPhyAddr","Cfc_RtPhyAddr_gold",1,1);
			init_signal_spy("/UUT/Cfc_FrlHeadPtr","Cfc_FrlHeadPtr_gold",1,1);
			init_signal_spy("/UUT/Cfc_RobTag","Cfc_RobTag_gold",1,1);
			init_signal_spy("/UUT/Cfc_Full","Cfc_Full_gold",1,1);


--			init_signal_spy("/UUT/Bpb_BranchPrediction","Bpb_BranchPrediction_gold",1,1);
--			enable_signal_spy("/UUT/Bpb_BranchPrediction","Bpb_BranchPrediction_gold",0);
			
		wait;
	end process spy_process;			

end architecture arch_top_tb_ROB;
