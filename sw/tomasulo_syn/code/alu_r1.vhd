------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;-- for slt and not sltu

------------------------------------------------------------------------------
-- New instructions introduced in the Design
-- JR $Rs, JR $31, Bne $rt, $rs, offset, Addi $rd, $rs, Immediate
-- Other instructions same as previous design 
------------------------------------------------------------------------------
entity ALU is
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
end ALU;

architecture comput of ALU is

begin
	Alu_RdPhyAddr     <= Iss_RdPhyAddrAlu;
	Alu_BranchPredict <= Iss_BranchPredictAlu;
	Alu_BranchUptAddr <= Iss_BranchUptAddrAlu;
	Alu_Branch        <= Iss_BranchAlu;
	Alu_RobTag        <= Iss_RobTagAlu;
	Alu_RdWrite   <= Iss_RegWriteAlu;
	 -- translate_off 
	Alu_instruction <= Iss_instructionAlu;
	 -- translate_on
	ALU_COMPUT: process (PhyReg_AluRtData, PhyReg_AluRsData, Iss_OpcodeAlu, Iss_BranchAddrAlu , Iss_JalInstAlu, Iss_JrRsInstAlu, Iss_JrInstAlu, Iss_ImmediateAlu)
	begin
		
		Alu_BranchOutcome <= '0';
		Alu_BranchAddr    <= Iss_BranchAddrAlu;
		Alu_JrFlush       <= '0';
		
		case Iss_OpcodeAlu is
			when "000" => -- Addition
				Alu_RdData <= PhyReg_AluRsData + PhyReg_AluRtData;
			when "001" => -- Subtraction
				Alu_RdData <= PhyReg_AluRsData - PhyReg_AluRtData;
			when "010" => -- And operation
				Alu_RdData <= PhyReg_AluRsData and PhyReg_AluRtData;
			when "011" => -- Or operation
				Alu_RdData <= PhyReg_AluRsData or PhyReg_AluRtData;
			when "100" =>  -- Add immediate 
			   if (Iss_ImmediateAlu(15) = '1') then
			     
			    Alu_RdData <= PhyReg_AluRsData + ("1111111111111111" & Iss_ImmediateAlu); --do sign extend
			   else 
			    Alu_RdData <= PhyReg_AluRsData + ("0000000000000000" & Iss_ImmediateAlu); 
			end if;
			when "101" => -- slt
				Alu_RdData(31 downto 1) <= (others => '0');
				
				if ( PhyReg_AluRsData < PhyReg_AluRtData ) then
					Alu_RdData(0) <= '1';
				else
					Alu_RdData(0) <= '0';
				end if;
			when "110" =>  -- beq
				if(PhyReg_AluRsData = PhyReg_AluRtData) then
					Alu_BranchOutcome	<= '1';
					else
					Alu_BranchOutcome	<= '0';
				end if;
				Alu_RdData <= (others => '0');	
           when "111" =>  -- bne
				if(PhyReg_AluRsData = PhyReg_AluRtData) then
					Alu_BranchOutcome	<= '0';
					else
					Alu_BranchOutcome	<= '1';
				end if;
				Alu_RdData <= (others => '0');					
			when others => 
				Alu_RdData <= (others => '0');
			
		end case;
		
		if(Iss_JalInstAlu = '1') then -- jal instruction
		Alu_RdData	    <= Iss_BranchAddrAlu;
		end if;
		
		if(Iss_JrInstAlu = '1') then -- Jr $31
		if(Iss_BranchAddrAlu = PhyReg_AluRsData) then
		Alu_JrFlush     <= '0';
		else 
		Alu_BranchAddr  <= PhyReg_AluRsData;
		Alu_JrFlush     <= '1';
		end if;
		end if;
		
	   if(Iss_JrRsInstAlu = '1') then -- Jr Rs
		Alu_JrFlush     <= '0';
		Alu_BranchAddr  <= PhyReg_AluRsData;
		end if;
	end process ALU_COMPUT;

end architecture comput;