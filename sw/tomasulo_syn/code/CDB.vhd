------------------------------------------
-- cdb_r1.vhd
-- Author : Vaibhav Dhotre
-- Date : 05/02/2010
-- Tomasulo 2010
-- cdb control mux
-- University of Southern California 
-------------------------------------------
-- This CDB is the same as pervious design. Only modification is Rob depth 
-- of the instruction on CDB is calculated and given to all modules.
-- For a branch, jr $31 instruction if mispredicted a flush signal is generated
-- and informed to all the required modules. 
-------------------------------------------
--LIBRARY DECLARATION
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

--ENTITY DECLARATION
entity cdb is
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
		 Cdb_PhyRegWrite     :   out  std_logic;
         Cdb_Data            :   out  std_logic_vector(31 downto 0);
         Cdb_RobTag          :   out  std_logic_vector(4 downto 0);
		 Cdb_BranchAddr      :   out  std_logic_vector(31 downto 0);
         Cdb_BranchOutcome   :   out  std_logic;
		 Cdb_BranchUpdtAddr  :   out  std_logic_vector( 2 downto 0 );
         Cdb_Branch          :   out  std_logic;
         Cdb_Flush           :   out  std_logic;
		 Cdb_RobDepth        :   out  std_logic_vector (4 downto 0 );
		 Cdb_RdPhyAddr       :   out  std_logic_vector (5 downto 0 );
		 Cdb_SwAddr          :   out  std_logic_vector (31 downto 0)
			
        );
    end cdb;


    architecture Behavioral of cdb is
	    -- depth of instruction in various queues
       signal Int_instDepth            : std_logic_vector ( 4 downto 0 ); --from the various issue queues
       signal Lsbuf_instDepth             : std_logic_vector ( 4 downto 0 );
       signal Mult_instDepth           : std_logic_vector ( 4 downto 0 );
       signal Div_instDepth            : std_logic_vector ( 4 downto 0 );
       -- intermediate signals
       signal issue_int_temp           : std_logic ;
       signal issue_Lsbuf_temp            : std_logic ;
       signal issue_Mult_temp          : std_logic ;
       signal issue_Div_temp           : std_logic ;
       signal Cdb_RobTag_temp          : std_logic_vector ( 4 downto 0 ) ;
	   signal Cdb_RobDepth_temp        : std_logic_vector (4 downto 0 ) ;
	   signal Cdb_Flush_temp           : std_logic;
      
       begin
          
		-- to calculate the depth of the instruction 
		-- tells you how many instructions are there between the current instruction and comitting instruction 		  
        Int_instDepth  <= unsigned(Alu_RobTag)    -  unsigned(Rob_TopPtr ) ; 
        Lsbuf_instDepth   <= unsigned(Lsbuf_RobTag) -  unsigned(Rob_TopPtr ) ;
        Mult_instDepth <= unsigned(Mul_RobTag)   -  unsigned(Rob_TopPtr ) ;
        Div_instDepth  <= unsigned(Div_RobTag)    -  unsigned(Rob_TopPtr ) ;
         
  --CDB will calculate the depth of the current instrcution.
               
					Cdb_RobDepth_temp <= Cdb_RobTag_temp - Rob_TopPtr + 32;	
					Cdb_RobDepth <= Cdb_RobDepth_temp;
					Cdb_RobTag   <= Cdb_RobTag_temp;
					Cdb_Flush    <= Cdb_Flush_temp;
					
           process ( Iss_Int , Int_instDepth , Cdb_Flush_temp , Cdb_RobDepth_temp ) -- if robflush is true and instruction is younger to branch instruction flush the instruction
               begin
                if ( Cdb_Flush_temp = '1' and Int_instDepth > Cdb_RobDepth_temp ) then
                   issue_int_temp <= '0';  -- if flush then invalidate the data coming on CDB
                   else
                   issue_int_temp  <= Iss_Int ;
               end if ;
           end process ;
           
           process ( Iss_Lsb , Lsbuf_instDepth , Cdb_Flush_temp , Cdb_RobDepth_temp ) -- if robflush is true and instruction is younger to branch instruction flush the instruction
                begin
                 if ( Cdb_Flush_temp = '1' and Lsbuf_instDepth > Cdb_RobDepth_temp ) then
                    issue_Lsbuf_temp <= '0';  -- if flush then invalidate the data coming on CDB
                    else
                    issue_Lsbuf_temp  <= Iss_Lsb ;
                end if ;
            end process ;
            --------------------------------------------------
            
           process ( Mul_Done, Mult_instDepth , Cdb_Flush_temp , Cdb_RobDepth_temp ) -- if robflush is true and instruction is younger to branch instruction, flush the instruction
               begin
                if ( Cdb_Flush_temp = '1' and  Mult_instDepth > Cdb_RobDepth_temp )then 
                    issue_Mult_temp <= '0' ;  -- if flush then invalidate the data coming on CDB
                    else
                    issue_Mult_temp  <=  Mul_Done  ; 
                end if ;
            end process ;
                  
						
           process ( Div_Done, Div_instDepth, Cdb_Flush_temp , Cdb_RobDepth_temp ) -- if robflush is true and instruction is younger to branch instruction, flush the instruction
               begin
                if ( Cdb_Flush_temp = '1' and  Div_instDepth > Cdb_RobDepth_temp ) then 
                    issue_Div_temp <= '0' ;  -- if flush then invalidate the data coming on CDB
                    else
                    issue_Div_temp   <=  Div_Done ; 
                end if ;
            end process ; 
                  
                  
                
          process ( Clk,Resetb ) 
              
          begin
              if ( Resetb = '0' ) then
                Cdb_Valid             <= '0' ;
                Cdb_BranchOutcome     <= '0' ;
                Cdb_Branch            <= '0' ;
			       Cdb_PhyRegWrite       <= '0' ;
			       Cdb_Flush_temp        <= '0' ;
                Cdb_Data              <= ( others => 'X' ) ;
					 Cdb_BranchUpdtAddr    <= ( others => 'X' ) ;
                elsif( Clk'event and Clk = '1' ) then 
                Cdb_Valid             <= issue_int_temp  or issue_Lsbuf_temp  or issue_Mult_temp or  issue_Div_temp ;
                Cdb_BranchOutcome     <= '0' ;
                Cdb_Branch            <= '0' ;
					 Cdb_PhyRegWrite       <= '0' ;
					 Cdb_SwAddr            <= (others => '0');
			       Cdb_Flush_temp        <= Alu_JrFlush and Iss_Int; -- changed by Manpreet Alu_JrFlush is generated by ALU continuously without validating it with ISS_Int
					 Cdb_BranchUpdtAddr    <= Alu_BranchUptAddr;
                  
                   if(  issue_int_temp = '1' ) then 
                      
                      Cdb_Data          <= Alu_RdData;   
                      Cdb_RdPhyAddr     <= Alu_RdPhyAddr  ;
					       Cdb_RobTag_Temp   <= Alu_RobTag;
					       Cdb_BranchAddr    <= Alu_BranchAddr;                   
                      Cdb_BranchOutcome <= Alu_BranchOutcome;
							 Cdb_PhyRegWrite   <= Alu_RdWrite;
							  -- translate_off 
							 Cdb_instruction   <= Alu_instruction;
							  -- translate_on
                      Cdb_Branch        <= Alu_Branch;
							if(Alu_Branch = '1') then
								 if(Alu_BranchOutcome = Alu_BranchPredict) then
								        Cdb_Flush_temp <= Alu_JrFlush;  --Flush if mispredicted.
										  else
										  Cdb_Flush_temp <= '1';
								   end if;
									else
									     Cdb_Flush_temp <= Alu_JrFlush;
                     end if ;
							end if;
                     
                     
                     if(  issue_Lsbuf_temp  = '1' ) then 
                         Cdb_Data       <= Lsbuf_Data ;   
                         Cdb_RdPhyAddr  <= Lsbuf_PhyAddr ;
						       Cdb_RobTag_temp<= Lsbuf_RobTag;
								 Cdb_SwAddr     <= Lsbuf_SwAddr;
								 Cdb_PhyRegWrite<= Lsbuf_RdWrite;
								  -- translate_off 
								 Cdb_instruction   <= Lsbuf_instruction;
								  -- translate_on
                       end if ;
                         
                       
                      
                      if(  issue_Mult_temp = '1'  ) then 
                         Cdb_Data        <=   Mul_RdData  ;
                         Cdb_RdPhyAddr   <=   Mul_RdPhyAddr ;
						       Cdb_RobTag_temp <=   Mul_RobTag;
								 Cdb_PhyRegWrite <= Mul_RdWrite;
								  -- translate_off 
								 Cdb_instruction   <= Mul_instruction;
								  -- translate_on
                        end if ;
                        
                       if(  issue_Div_temp = '1'  ) then 
                          Cdb_Data       <= Div_Rddata  ;
                          Cdb_RdPhyAddr  <= Div_RdPhyAddr ;  
                          Cdb_RobTag_temp<= Div_RobTag;
                          Cdb_PhyRegWrite<= Div_RdWrite;
						   -- translate_off 
                          Cdb_instruction   <= Div_instruction;						  
						   -- translate_on
                          end if ;   
                  
                     end if ;
          end process ;
          
                 
       end Behavioral;
