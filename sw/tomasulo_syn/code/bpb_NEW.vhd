------------------------------------------------------------------------------
--
-- Design           : Branch Predicton Buffer
-- Project          : Tomasulo Processor 
-- Entity           : bpb
-- Author           : kapil 
-- Company          : University of Southern California 
-- Last Updated     : June 24, 2010
-- Last Updated by	: Waleed Dweik
-- Modification		: 1. Modify the branch prediction to use the most well-known state machine of the 2-bit saturating counter
--					  2. Update old comments	
-------------------------------------------------------------------------------
--
-- Description :    2 - bit wide / 8 deep 
--                  each 2 bit locn is a state machine
--                  2 bit saturating counter   
--                   00 strongly nottaken
--                   01 mildly nottaken
--                   10 mildly taken
--                   11 strongly taken 
--                    
-------------------------------------------------------------------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-------------------------------------------------------------------------------------------------------------
entity bpb is
   port (
         Clk                  : in std_logic;
         Resetb               : in std_logic; 
         ---- Interaction with Cdb -------------------
            Dis_CdbUpdBranch         : in  std_logic; -- indicates that a branch appears on Cdb(wen to bpb)
            Dis_CdbUpdBranchAddr     : in std_logic_vector(2 downto 0);-- indiactes the last 3 bit addr of the branch on the Cdb
            Dis_CdbBranchOutcome     : in std_logic; -- indiacates the outocome of the branch to the bpb: 0 means nottaken and 1 means taken 
			
         ---- Interaction with dispatch --------------
            Bpb_BranchPrediction        : out std_logic;  --This bit tells the dispatch what the prediction actually based on bpb state-mc
            Dis_BpbBranchPCBits         : in std_logic_vector(2 downto 0) ;--indiaces the 3 least sig bits of the current instr being dispatched
            Dis_BpbBranch               : in std_logic -- indiactes that there is a branch instr in the dispatch (ren to the bpb)
         );
end bpb;



architecture behv of bpb is

   subtype sat_counters is std_logic_vector(1 downto 0);
   type bpb_array is array (0 to 7) of sat_counters ;	
   signal bpb_array_r: bpb_array ;						-- An array of 8 2-bit saturating counters represents 8 location bpb.
   signal Bpb_read_status,Bpb_write_status : std_logic_vector(1 downto 0);
   

begin



---------------------------------------------------------------------------
-- Task1: Complete the following 2 concurrent statements for Bpb read and write status:
-- Hint: You may want to use CONV_INTEGER function to convert from std_logic_vector to an integer

-- Bpb_read_status represets the 2-bit counter value in the Bpb entry addressed by the branch instruction in dispatch. 
-- Bpb_read_status tells whether branch should predicted Taken (11,10) or not Taken (00,01)

 Bpb_read_status <= bpb_array_r(0) when Dis_BpbBranchPCBits = "000" else
					bpb_array_r(1) when Dis_BpbBranchPCBits = "001" else
					bpb_array_r(2) when Dis_BpbBranchPCBits = "010" else
					bpb_array_r(3) when Dis_BpbBranchPCBits = "011" else
					bpb_array_r(4) when Dis_BpbBranchPCBits = "100" else
					bpb_array_r(5) when Dis_BpbBranchPCBits = "101" else
					bpb_array_r(6) when Dis_BpbBranchPCBits = "110" else
					bpb_array_r(7) when Dis_BpbBranchPCBits = "111";

-- Bpb_write_status represents the 2-bit counter value in the Bpb entry addressed by the branch instruction on the Cdb.
-- Bpb_write_status is used along with the actual outcome of the branch on Cdb to update the corresponding Bpb entry.     

--Bpb_write_status <= --
---------------------------------------------------------------------------



-- Update Process
-- This prcoess is used to update the Bpb entry indexed by the PC[4:2] of the branch instruction which appears on Cdb.
-- The update process is based on the State machine for a 2-bit saturating counter which is given in the slide set.
bpb_write: process (Clk,Resetb)

variable write_data_bpb: std_logic_vector(1 downto 0);
variable bpb_waddr_mask ,bpb_index_addr,raw_bpb_addr: std_logic_vector(7 downto 0);
begin
    if (Resetb = '0') then
   -------------------------------Initialize register file contents(!! weakly taken, weakly not taken alternatvely!!) here----------------------------------
       bpb_array_r <= ( 
                      "01",            -- $0
                      "10",            -- $1
                      "01",            -- $2
                      "10",            -- $3
                      "01",            -- $4
                      "10",            -- $5
                      "01",            -- $6
                      "10"            -- $7
                      
                      );
                      
	elsif(Clk'event and Clk='1') then
       
		if (Dis_CdbUpdBranch = '1')then
			bpb_waddr_mask := X"FF";
		else
			bpb_waddr_mask := X"00";
		end if ;
    
		case Dis_CdbUpdBranchAddr is
            when "000" => raw_bpb_addr := ("00000001");  
            when "001" => raw_bpb_addr := ("00000010"); 
            when "010" => raw_bpb_addr := ("00000100"); 
            when "011" => raw_bpb_addr := ("00001000"); 
            when "100" => raw_bpb_addr := ("00010000"); 
            when "101" => raw_bpb_addr := ("00100000"); 
            when "110" => raw_bpb_addr := ("01000000");
            when others => raw_bpb_addr := ("10000000"); 
        end case ; 
            
        bpb_index_addr := raw_bpb_addr and  bpb_waddr_mask ; 
		
---------------------------------------------------------------------------
-- Task2: Add the Code inside the for loop to modify Bpb entries:
-- Hint: According to the current counter value of the corresponding entry and the actual outcome of the branch on Cdb you can
--       decide what is the new prediction value should be based on the state machine given in the slides.
---------------------------------------------------------------------------		
            

		for i in 0 to 7 loop      
			if (bpb_index_addr(i) = '1') then
				case (bpb_array_r(i)) is
					when "00" =>
						if (Dis_CdbBranchOutcome = '1') then
							bpb_array_r(i) <= "01";
						end if;
					when "01" =>
						if (Dis_CdbBranchOutcome = '1') then
							bpb_array_r(i) <= "10";
						else
							bpb_array_r(i) <= "00";
						end if;
					when "10" =>
						if (Dis_CdbBranchOutcome = '1') then
							bpb_array_r(i) <= "11";
						else
							bpb_array_r(i) <= "01";
						end if;	
					when others =>
						if (Dis_CdbBranchOutcome = '0') then
							bpb_array_r(i) <= "10";
						end if;
					
				end case;
			end if;
		end loop;
	end if;
end process bpb_write;


-- Prediction Process
-- This prcoess generates Bpb_BranchPrediction signal which indicates the prediction for branch instruction
-- The signal is always set to '0' except when there is a branch instruction in dispatch and the prediction is either Strongly Taken or Taken.
bpb_predict : process(Bpb_read_status ,Dis_BpbBranch)
begin
    Bpb_BranchPrediction<= '0';
    if (Bpb_read_status(1) = '0' ) then 
        Bpb_BranchPrediction<= '0';
    else
       Bpb_BranchPrediction<= '1' and Dis_BpbBranch;
   end if ;
   
end process;
    

   
end behv;
