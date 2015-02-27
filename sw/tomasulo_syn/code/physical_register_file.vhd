-------------------------------------------------------------------------------
--
-- Design   : Physical Register File
-- Project  : Tomasulo Processor 
-- Entity	: register_file
-- Author   : Vaibhav Dhotre
-- Company  : University of Southern California 
-- Updated  : 03/15/2010
-------------------------------------------------------------------------------
--
-- Description : 	32 wide 48 deep register file. $0 is never written during circuit
-- operation. So it is replaced with hard wired 0s by synthesis tool
--	It has 8 read port and 1 write port. Reading is asynchronous and writing is synchronous.
-- When an instruction is dispatched the ready signal for new physical register for the Rd
-- is made 0.
-- When an instruction is on CDB the ready signal for new physical register for the Rd
-- is made 1.
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-------------------------------------------------------------------------------------------------------------
entity physicalregister_file is
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
end physicalregister_file;


	architecture regfile of physicalregister_file is

		
	-- Register file Declaration
	subtype reg is std_logic_vector(31 downto 0);
	type reg_file is array (0 to 47) of reg;

	signal physical_register_r: reg_file ;
	signal physical_reg_ready : std_logic_vector(47 downto 0);

	begin

			PhyReg_AluRsData  <= Cdb_RdData when ( Cdb_RdPhyAddr = Iss_RsPhyAddrAlu and Cdb_Valid = '1' and Cdb_PhyRegWrite = '1')--cdbWrite 
			                 else physical_register_r (CONV_INTEGER(Iss_RsPhyAddrAlu));  -- Internal forwarding from write port
			PhyReg_AluRtData  <= Cdb_RdData when ( Cdb_RdPhyAddr  = Iss_RtPhyAddrAlu and Cdb_Valid = '1'and Cdb_PhyRegWrite = '1') 
			                 else physical_register_r (CONV_INTEGER(Iss_RtPhyAddrAlu));  -- Internal forwarding from write port
							 
		   PhyReg_LsqRsData  <= Cdb_RdData when ( Cdb_RdPhyAddr = Iss_RsPhyAddrLsq and Cdb_Valid = '1' and Cdb_PhyRegWrite = '1') 
			                 else physical_register_r (CONV_INTEGER(Iss_RsPhyAddrLsq));  -- Internal forwarding from write port
			
			PhyReg_MultRsData <= Cdb_RdData when ( Cdb_RdPhyAddr = Iss_RsPhyAddrMul and Cdb_Valid = '1' and Cdb_PhyRegWrite = '1') 
			                 else physical_register_r (CONV_INTEGER(Iss_RsPhyAddrMul));  -- Internal forwarding from write port
			PhyReg_MultRtData <= Cdb_RdData when ( Cdb_RdPhyAddr = Iss_RtPhyAddrMul and Cdb_Valid = '1' and Cdb_PhyRegWrite = '1') 
			                 else physical_register_r (CONV_INTEGER(Iss_RtPhyAddrMul));  -- Internal forwarding from write port
							 
		   PhyReg_DivRsData  <= Cdb_RdData when ( Cdb_RdPhyAddr = Iss_RsPhyAddrDiv and Cdb_Valid = '1' and Cdb_PhyRegWrite = '1') 
			                 else physical_register_r (CONV_INTEGER(Iss_RsPhyAddrDiv));  -- Internal forwarding from write port
			PhyReg_DivRtData  <= Cdb_RdData when ( Cdb_RdPhyAddr = Iss_RtPhyAddrDiv and Cdb_Valid =  '1' and Cdb_PhyRegWrite = '1') 
			                 else physical_register_r (CONV_INTEGER(Iss_RtPhyAddrDiv));  -- Internal forwarding from write port
								  
								  
			PhyReg_StoreData  <= Cdb_RdData when ( Cdb_RdPhyAddr = Rob_CommitCurrPhyAddr and Cdb_Valid =  '1' and Cdb_PhyRegWrite = '1') 
			                 else physical_register_r (CONV_INTEGER(Rob_CommitCurrPhyAddr));  -- Internal forwarding from write port
								  
								  
							 
							 
	reg_file_read_write: process(Clk,Resetb)
	begin
	-------------------------------Initialize register file contents here----------------------------------
		if Resetb ='0' then
			physical_register_r <= (	
				"00000000000000000000000000000000",            -- $0
				"00000000000000000000000000000001",            -- $1
				"00000000000000000000000000000010",            -- $2
				"00000000000000000000000000000011",            -- $3
				"00000000000000000000000000000100",            -- $4
				"00000000000000000000000000000101",            -- $5
				"00000000000000000000000000000110",            -- $6
				"00000000000000000000000000000111",            -- $7
				"00000000000000000000000000001000",            -- $8
				"00000000000000000000000000001001",            -- $9
				"00000000000000000000000000001010",            -- $10
				"00000000000000000000000000001011",            -- $11
				"00000000000000000000000000001100",            -- $12
				"00000000000000000000000000001101",            -- $13
				"00000000000000000000000000001110",            -- $14
				"00000000000000000000000000001111",            -- $15
				"00000000000000000000000000010000",            -- $16
				"00000000000000000000000000010001",            -- $17
				"00000000000000000000000000010010",            -- $18
				"00000000000000000000000000010011",            -- $19
				"00000000000000000000000000010100",            -- $20
				"00000000000000000000000000010101",            -- $21
				"00000000000000000000000000010110",            -- $22
				"00000000000000000000000000010111",            -- $23
				"00000000000000000000000000011000",            -- $24
				"00000000000000000000000000011001",            -- $25
				"00000000000000000000000000011010",            -- $26
				"00000000000000000000000000011011",            -- $27
				"00000000000000000000000000011100",            -- $28
				"00000000000000000000000000011101",            -- $29
				"00000000000000000000000000011110",            -- $30
				"00000000000000000000000000011111",            -- $31
				"00000000000000000000000000100000",            -- $32
				"00000000000000000000000000100001",            -- $33
				"00000000000000000000000000100010",            -- $34
				"00000000000000000000000000100011",            -- $35
				"00000000000000000000000000100100",            -- $36
				"00000000000000000000000000100101",            -- $37
				"00000000000000000000000000100110",            -- $38
				"00000000000000000000000000100111",            -- $39
				"00000000000000000000000000101000",            -- $40
				"00000000000000000000000000101001",            -- $41
				"00000000000000000000000000101010",            -- $42
				"00000000000000000000000000101011",            -- $43
				"00000000000000000000000000101100",            -- $44
				"00000000000000000000000000101101",            -- $45
				"00000000000000000000000000101110",            -- $46
				"00000000000000000000000000101111"             -- $47
			);
			for i in 0 to 47 loop --intialization of ready signal for each location of physical register file.
			if( i > 31 ) then
			physical_reg_ready(i) <= '0';
			else
			physical_reg_ready(i) <= '1';
			end if;
			end loop;

		elsif(Clk'event and Clk= '1') then
		         if(Cdb_Valid = '1')and(Cdb_PhyRegWrite = '1') then
					physical_register_r(CONV_INTEGER(Cdb_RdPhyAddr))<= Cdb_RdData;
					physical_reg_ready(CONV_INTEGER(Cdb_RdPhyAddr))<= '1';
					end if;
					
					if(Dis_RegWrite = '1') then
					physical_reg_ready(CONV_INTEGER(Dis_NewRdPhyAddr))<= '0';--From DISPATCH
					end if;
			
			
			
		end if;

	end process reg_file_read_write;
	
ready_signal : process(Cdb_RdPhyAddr , Dis_RsAddr , Cdb_Valid, Cdb_PhyRegWrite, Dis_RtAddr, physical_reg_ready)
begin
  PhyReg_RsDataRdy <= '0' ;
  PhyReg_RtDataRdy <= '0' ;
  if( Cdb_RdPhyAddr = Dis_RsAddr and Cdb_Valid =  '1' and Cdb_PhyRegWrite = '1') then--CDBRegWrite
			PhyReg_RsDataRdy <= '1';
			else
			PhyReg_RsDataRdy <= physical_reg_ready(CONV_INTEGER(Dis_RsAddr));
			end if;
			
			if( Cdb_RdPhyAddr = Dis_RtAddr and Cdb_Valid =  '1' and Cdb_PhyRegWrite = '1') then--CDBRegWrite
			PhyReg_RtDataRdy <= '1';
			else
			PhyReg_RtDataRdy <= physical_reg_ready(CONV_INTEGER(Dis_RtAddr));
			end if;
end process ready_signal;
end regfile;