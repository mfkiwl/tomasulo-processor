-- CHECKED AND MODIFIED BY PRASANJEET
-------------------------------------------
--UPDATED ON: 7/14/09, 7/13/10

-------------------------------------------
-------------------------------------------
-- CHECKED AND MODIFIED BY WALEED
-------------------------------------------
--UPDATED ON: 6/4/10

-------------------------------------------

-------------------------------------------------------------------------------
--
-- Design   : Load - Store Queue
-- Project  : Tomasulo Processor 
-- Author   : Rohit Goel 
-- Company  : University of Southern California 
--
-------------------------------------------------------------------------------
--
-- File         : lsq.vhd
-- Version      : 1.0
--
-------------------------------------------------------------------------------
--
-- Description : The load store queue stores lw - sw instructions and dispatches 
--               instructions to the issue block as and when they are ready to be 
--               executed. Higher priority is given to instructions which has been 
--               in the queue for a longer period
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;

-- Entity declaration
entity lsq is 
port (
      -- Global Clk and Resetb Signals
      Clk                  : in  std_logic;
      Resetb               : in  std_logic;

      -- Information to be captured from the CDB (Common Data Bus)
      Cdb_RdPhyAddr        : in  std_logic_vector(5 downto 0);
	  Cdb_PhyRegWrite      : in  std_logic;
      Cdb_Valid            : in  std_logic ;

      -- Information from the Dispatch Unit 
	  
      Dis_Opcode           : in  std_logic; 
      Dis_Immediate        : in  std_logic_vector(15 downto 0 );
      Dis_RsDataRdy        : in  std_logic;
      Dis_RsPhyAddr        : in  std_logic_vector(5 downto 0 ); 
      Dis_RobTag           : in  std_logic_vector(4 downto 0);
	  Dis_NewRdPhyAddr     : in  std_logic_vector(5 downto 0);
      Dis_LdIssquenable    : in  std_logic; 
      Issque_LdStQueueFull : out std_logic;
	  Issque_LdStQueueTwoOrMoreVacant: out std_logic;
	  
	  -- translate_off 
     Dis_instruction       : in std_logic_vector(31 downto 0);
	 -- translate_on
	 
	 -- translate_off 
     Iss_instructionLsq    : out std_logic_vector(31 downto 0);
	 -- translate_on
	 
      -- interface with PRF
	  Iss_RsPhyAddrLsq     : out std_logic_vector(5 downto 0);
	  PhyReg_LsqRsData	   : in std_logic_vector(31 downto 0);
	  -- Interface with the Issue Unit
      Iss_LdStReady        : out std_logic ;
      Iss_LdStOpcode       : out std_logic ;  
      Iss_LdStRobTag       : out std_logic_vector(4 downto 0);
      Iss_LdStAddr         : out std_logic_vector(31 downto 0); 
      Iss_LdStIssued       : in  std_logic;
	  Iss_LdStPhyAddr      : out  std_logic_vector(5 downto 0);
      DCE_ReadBusy         : in  std_logic;
      Lsbuf_Done           : in std_logic;
    --  Interface with ROB 
      Cdb_Flush            : in std_logic;
      Rob_TopPtr           : in std_logic_vector (4 downto 0);
      Cdb_RobDepth         : in std_logic_vector (4 downto 0);
      SB_FlushSw           : in std_logic; 
      --SB_FlushSwTag            : in std_logic_vector (4 downto 0)    --Modified by Waleed 06/04/10
	  SB_FlushSwTag        : in std_logic_vector (1 downto 0);
	  SBTag_counter		   : in std_logic_vector (1 downto 0);         --Added by Waleed 06/04/10
      --Interface with ROB , Added by Waleed 06/04/10
	  Rob_CommitMemWrite   : in std_logic	  
     );
end lsq;

-- Architecture begins here
architecture behave of lsq is

-- Component declarations
component Lsquectrl 
port (
      -- Global Clk and Resetb Signals
      Clk                  : in  std_logic;
      Resetb               : in  std_logic;

      -- cdb interface
      Cdb_RdPhyAddr        : in  std_logic_vector(5 downto 0);
	  Cdb_PhyRegWrite      : in  std_logic;
      Cdb_Valid            : in  std_logic;

      -- dispatch / issue unit interface
      Dis_LdIssquenable    : in  std_logic; 
      Iss_LdStIssued       : in  std_logic;
      DCE_ReadBusy         : in std_logic;
      Lsbuf_Done           : in  std_logic;
           
      -- address calc section
      Opcode               : in  std_logic_vector(7 downto 0); -- '1' indicates lw and '0' is a sw 
      AddrReadyBit         : in  std_logic_vector(7 downto 0); -- '1' indicates address has been calculated 
      AddrUpdate           : out std_logic_vector(7 downto 0); -- '1' indicates calculated address is being updated to the given buffer
      AddrUpdateSel        : out std_logic_vector(7 downto 0); -- '1' indicates calculated address is updated from the buffer above
                                                                --     else indicates updation from the contents of the same buffer
      -- shift register inputs
      InstructionValidBit  : in  std_logic_vector(7 downto 0); -- '1' indicates instruction is valid in the buffer
      RsDataValidBit       : in  std_logic_vector(7 downto 0); -- '1' indicates rs data is valid in the buffer
      

      Buffer0RsTag         : in  std_logic_vector(5 downto 0);  --from the issue queues!!
      Buffer1RsTag         : in  std_logic_vector(5 downto 0); 
      Buffer2RsTag         : in  std_logic_vector(5 downto 0); 
      Buffer3RsTag         : in  std_logic_vector(5 downto 0); 
	  Buffer4RsTag         : in  std_logic_vector(5 downto 0);  
      Buffer5RsTag         : in  std_logic_vector(5 downto 0); 
      Buffer6RsTag         : in  std_logic_vector(5 downto 0); 
      Buffer7RsTag         : in  std_logic_vector(5 downto 0); 

      Buffer0RdTag         : in  std_logic_vector(4 downto 0); 
      Buffer1RdTag         : in  std_logic_vector(4 downto 0); 
      Buffer2RdTag         : in  std_logic_vector(4 downto 0); 
      Buffer3RdTag         : in  std_logic_vector(4 downto 0); 
      Buffer4RdTag         : in  std_logic_vector(4 downto 0); 
      Buffer5RdTag         : in  std_logic_vector(4 downto 0); 
      Buffer6RdTag         : in  std_logic_vector(4 downto 0); 
      Buffer7RdTag         : in  std_logic_vector(4 downto 0); 
      
	  IssuqueCounter0      : in std_logic_vector ( 2 downto 0 );  -- counter to store the no. of "sw" bypassing a "lw"
      IssuqueCounter1      : in std_logic_vector ( 2 downto 0 );
      IssuqueCounter2      : in std_logic_vector ( 2 downto 0 );
      IssuqueCounter3      : in std_logic_vector ( 2 downto 0 );
	  IssuqueCounter4      : in std_logic_vector ( 2 downto 0 );  
      IssuqueCounter5      : in std_logic_vector ( 2 downto 0 );
      IssuqueCounter6      : in std_logic_vector ( 2 downto 0 );
      IssuqueCounter7      : in std_logic_vector ( 2 downto 0 );


      -- output control signals - group 1
      Sel0                  : out std_logic;  -- '1' indicates update from dispatch 
      Flush                 : out std_logic_vector(7 downto 0);
      Sel1Rs                : out std_logic_vector(7 downto 0); -- '1' indicates update from cdb
      En                    : out std_logic_vector(7 downto 0); -- '1' indicates update / shift / cdb update
      OutSelect             : out std_logic_vector(2 downto 0);  
      IncrementCounter      : out std_logic_vector(7 downto 0);
      -- issue que unit control signals
      Issque_LdStQueueFull  : out std_logic; 
	  IssuequefullTemp_Upper: out std_logic ;
	  IssuequefullTemp_Lower: out std_logic ;
      Iss_LdStReady         : out std_logic;
      -- Address Buffer Signal 
      AddrBuffFull          : in std_logic;
      AddrMatch0            : in std_logic;
      AddrMatch1            : in std_logic;
      AddrMatch2            : in std_logic;
      AddrMatch3            : in std_logic;
      AddrMatch4            : in std_logic;
      AddrMatch5            : in std_logic;
      AddrMatch6            : in std_logic;
      AddrMatch7            : in std_logic;
	  
      AddrMatch0Num         : in std_logic_vector ( 2 downto 0 );
      AddrMatch1Num         : in std_logic_vector ( 2 downto 0 );
      AddrMatch2Num         : in std_logic_vector ( 2 downto 0 );
      AddrMatch3Num         : in std_logic_vector ( 2 downto 0 );
      AddrMatch4Num         : in std_logic_vector ( 2 downto 0 );
      AddrMatch5Num         : in std_logic_vector ( 2 downto 0 );
      AddrMatch6Num         : in std_logic_vector ( 2 downto 0 );
      AddrMatch7Num         : in std_logic_vector ( 2 downto 0 );
        
       
      ScanAddr0             : in std_logic_vector ( 31 downto 0 );
      ScanAddr1             : in std_logic_vector ( 31 downto 0 );
      ScanAddr2             : in std_logic_vector ( 31 downto 0 );
      ScanAddr3             : in std_logic_vector ( 31 downto 0 );     
      ScanAddr4             : in std_logic_vector ( 31 downto 0 );
      ScanAddr5             : in std_logic_vector ( 31 downto 0 );
      ScanAddr6             : in std_logic_vector ( 31 downto 0 );
      ScanAddr7             : in std_logic_vector ( 31 downto 0 );     
     --
	  --  ROB
      Cdb_Flush             : in std_logic;
      Rob_TopPtr            : in std_logic_vector ( 4 downto 0 );
      Cdb_RobDepth          : in std_logic_vector ( 4 downto 0 )
     );
end component;

component AddBuff 
port (
                    -- Global Clk and Resetb Signals
                   Clk                   : in  std_logic;
                   Resetb                 : in  std_logic;

                   AddrBuffFull          : out std_logic;
                   AddrMatch0            : out std_logic;
                   AddrMatch1            : out std_logic;
                   AddrMatch2            : out std_logic;
                   AddrMatch3            : out std_logic;
				   AddrMatch4            : out std_logic;
                   AddrMatch5            : out std_logic;
                   AddrMatch6            : out std_logic;
                   AddrMatch7            : out std_logic;
                   AddrMatch0Num         : out std_logic_vector (2 downto 0);
                   AddrMatch1Num         : out std_logic_vector (2 downto 0);
                   AddrMatch2Num         : out std_logic_vector (2 downto 0);
                   AddrMatch3Num         : out std_logic_vector (2 downto 0);
				   AddrMatch4Num         : out std_logic_vector (2 downto 0);
                   AddrMatch5Num         : out std_logic_vector (2 downto 0);
                   AddrMatch6Num         : out std_logic_vector (2 downto 0);
                   AddrMatch7Num         : out std_logic_vector (2 downto 0);
                    
                   
                   ScanAddr0             : in std_logic_vector (31 downto 0);
                   ScanAddr1             : in std_logic_vector (31 downto 0);
                   ScanAddr2             : in std_logic_vector (31 downto 0);
                   ScanAddr3             : in std_logic_vector (31 downto 0);
				   ScanAddr4             : in std_logic_vector (31 downto 0);
                   ScanAddr5             : in std_logic_vector (31 downto 0);
                   ScanAddr6             : in std_logic_vector (31 downto 0);
                   ScanAddr7             : in std_logic_vector (31 downto 0);
                        
                   LsqSwAddr             : in std_logic_vector (36 downto 0);
                   StrAddr               : in std_logic ; 
                   
                   Cdb_Flush              : in std_logic;
                   Rob_TopPtr         : in std_logic_vector (4 downto 0);
                   Cdb_RobDepth              : in std_logic_vector (4 downto 0);
                   SB_FlushSw               : in std_logic;
                   --SB_FlushSwTag            : in std_logic_vector (4 downto 0)    --Modified by Waleed 06/04/10
				   SB_FlushSwTag            : in std_logic_vector (1 downto 0);
				   SBTag_counter			: in std_logic_vector (1 downto 0);    --Added by Waleed 06/04/10
                   --Interface with ROB , Added by Waleed 06/04/10
				   Rob_CommitMemWrite      : in std_logic			   
                  );
end component;

-- Type declarations
-- Declarations of Register Array for the Issue Queue and Issue Priority Register

type array_4_6 is array (0 to 7) of std_logic_vector(5 downto 0);
type array_4_5 is array (0 to 7) of std_logic_vector(4 downto 0); 
type array_4_3 is array (0 to 7) of std_logic_vector(2 downto 0); 
type array_4_32 is array (0 to 7) of std_logic_vector(31 downto 0) ; 
type array_4_33 is array ( 0 to 7 ) of std_logic_vector( 2 downto 0 );

    SIGNAL IssuqueCounter     	 : array_4_33;
    SIGNAL IssuequeRstagReg  	 : array_4_6;
	SIGNAL IssuequeRdtagReg   	 : array_4_6;
    SIGNAL IssuequeRobTag   	 : array_4_5;
    SIGNAL IssuequeOpcodeReg  	 : std_logic_vector(7 downto 0);
    SIGNAL IssuequeAddressReg    : array_4_32;
	SIGNAL IssuequeInstructReg   : array_4_32;
    SIGNAL IssuequeOpcodeTemp    : std_logic ;
    SIGNAL IssuequeRsdataValReg  : std_logic_vector (7 downto 0);
    SIGNAL IssuequeInstrValReg   : std_logic_vector (7 downto 0);
    SIGNAL IssuequeAddrReadyReg  : std_logic_vector (7 downto 0);
    signal AddrUpdate            : std_logic_vector (7 downto 0);
    signal AddrUpdateSel         : std_logic_vector (7 downto 0);
    signal Sel0,StrAddrTemp      : std_logic;
    signal OutSelect             : std_logic_vector (2 downto 0) ;
    signal En , Flush            : std_logic_vector (7 downto 0);
    signal Sel1Rs                : std_logic_vector (7 downto 0);
    signal DisAddrTemp           : std_logic_vector (31 downto 0);
    signal AddrBuffFull,AddrMatch0,AddrMatch1,AddrMatch2,AddrMatch3,AddrMatch4,AddrMatch5,AddrMatch6,AddrMatch7 : std_logic ;
    signal LsqSwAddr             : std_logic_vector (36 downto 0);  --37 bits = tag + address??
    signal IncrementCounter      : std_logic_vector (7 downto 0);
    signal AddrMatch0Num,AddrMatch1Num,AddrMatch2Num,AddrMatch3Num,AddrMatch4Num,AddrMatch5Num,AddrMatch6Num,AddrMatch7Num : std_logic_vector ( 2 downto 0 ) ;       
    signal IssuequefullTemp_Lower,IssuequefullTemp_Upper,UpperHalf_Has_Two_or_More_vacant,LowerHalf_Has_Two_or_More_vacant 	 : std_logic; 

begin   
    DisAddrTemp(31 downto 16) <= (others => Dis_Immediate(15));
    DisAddrTemp(15 downto 0)  <= Dis_Immediate;
	StrAddrTemp <= Iss_LdStIssued and (not (IssuequeOpcodeTemp) );  --one bit signal telling wether to store the address of "sw" or not
    Iss_LdStOpcode <= IssuequeOpcodeTemp;
	
AddBudd:   AddBuff 
port map (
                    -- Global Clk and Resetb Signals
                   Clk                 =>  Clk  , 
                   Resetb               =>  Resetb , 
                   AddrBuffFull        => AddrBuffFull,
                   AddrMatch0           => AddrMatch0,
                   AddrMatch1           => AddrMatch1,
                   AddrMatch2           => AddrMatch2,
                   AddrMatch3           => AddrMatch3,
				   AddrMatch4           => AddrMatch4,
                   AddrMatch5           => AddrMatch5,
                   AddrMatch6           => AddrMatch6,
                   AddrMatch7           => AddrMatch7,
                   
                   AddrMatch0Num        => AddrMatch0Num,
                   AddrMatch1Num        => AddrMatch1Num,
                   AddrMatch2Num        => AddrMatch2Num,
                   AddrMatch3Num        => AddrMatch3Num,
				   AddrMatch4Num        => AddrMatch4Num,
                   AddrMatch5Num        => AddrMatch5Num,
                   AddrMatch6Num        => AddrMatch6Num,
                   AddrMatch7Num        => AddrMatch7Num,
                 
                   ScanAddr0            =>  IssuequeAddressReg(0),
                   ScanAddr1            =>  IssuequeAddressReg(1),
                   ScanAddr2            =>  IssuequeAddressReg(2),
                   ScanAddr3            =>  IssuequeAddressReg(3),
				   ScanAddr4            =>  IssuequeAddressReg(4),
                   ScanAddr5            =>  IssuequeAddressReg(5),
                   ScanAddr6            =>  IssuequeAddressReg(6),
                   ScanAddr7            =>  IssuequeAddressReg(7),
                   
                   Cdb_Flush            => Cdb_Flush,  
                   Rob_TopPtr       => Rob_TopPtr,  
                   Cdb_RobDepth            => Cdb_RobDepth,
                   
                   LsqSwAddr           => LsqSwAddr,
                   StrAddr             => StrAddrTemp, 
                   SB_FlushSw             => SB_FlushSw,
                   SB_FlushSwTag          => SB_FlushSwTag, 
				   SBTag_counter	   => SBTag_counter, --Added by Waleed 06/04/10
				   Rob_CommitMemWrite  => Rob_CommitMemWrite--Added by Waleed 06/04/10
                  );


lsquectrl_inst : lsquectrl 
port map (
      -- Global Clk and Resetb Signals
      Clk                  => Clk,
      Resetb                => Resetb,

      -- cdb interface
      Cdb_RdPhyAddr               => Cdb_RdPhyAddr,
	   Cdb_PhyRegWrite=> Cdb_PhyRegWrite,
      Cdb_Valid             => Cdb_Valid,

      -- dispatch / issue unit interface
      Dis_LdIssquenable      	   => Dis_LdIssquenable,
      Iss_LdStIssued         => Iss_LdStIssued,
      DCE_ReadBusy              => DCE_ReadBusy,
      Lsbuf_Done         => Lsbuf_Done,
      --------------------------------------------------------------------------------------------------------------
      --------------------------------------------------------------------------------------------------------------
      -- 
      -- address calc section
      Opcode               => IssuequeOpcodeReg,
      AddrReadyBit         => IssuequeAddrReadyReg,
      AddrUpdate           => AddrUpdate,
      AddrUpdatesel        => AddrUpdateSel,

      
      --------------------------------------------------------------------------------------------------------------
      --------------------------------------------------------------------------------------------------------------

      -- shift register inputs
      InstructionValidBit => IssuequeInstrValReg,
      RsDataValidBit      => IssuequeRsdataValReg,
	  
      Buffer0RsTag        => IssuequeRstagReg(0), 
      Buffer1RsTag        => IssuequeRstagReg(1), 
      Buffer2RsTag        => IssuequeRstagReg(2), 
      Buffer3RsTag        => IssuequeRstagReg(3),
	  Buffer4RsTag        => IssuequeRstagReg(4), 
      Buffer5RsTag        => IssuequeRstagReg(5), 
      Buffer6RsTag        => IssuequeRstagReg(6), 
      Buffer7RsTag        => IssuequeRstagReg(7),	  

       
      Buffer0RdTag        => IssuequeRobTag(0),  
      Buffer1RdTag        => IssuequeRobTag(1),  
      Buffer2RdTag        => IssuequeRobTag(2),  
      Buffer3RdTag        => IssuequeRobTag(3), 
	  Buffer4RdTag        => IssuequeRobTag(4),  
      Buffer5RdTag        => IssuequeRobTag(5),  
      Buffer6RdTag        => IssuequeRobTag(6),  
      Buffer7RdTag        => IssuequeRobTag(7),  
      
      IssuqueCounter0     => IssuqueCounter(0),
      IssuqueCounter1     => IssuqueCounter(1),
      IssuqueCounter2     => IssuqueCounter(2),
      IssuqueCounter3     => IssuqueCounter(3),
	  IssuqueCounter4     => IssuqueCounter(4),
      IssuqueCounter5     => IssuqueCounter(5),
      IssuqueCounter6     => IssuqueCounter(6),
      IssuqueCounter7     => IssuqueCounter(7),


      -- output control signals - group 1
      Sel0                => Sel0,
      Sel1Rs              => Sel1Rs,
      Flush               => Flush,
      En                  => En,
      OutSelect           => OutSelect,
      IncrementCounter    => IncrementCounter,
      -- issue que unit control signals
      Issque_LdStQueueFull   => Issque_LdStQueueFull,
	  IssuequefullTemp_Upper => IssuequefullTemp_Upper,
	  IssuequefullTemp_Lower => IssuequefullTemp_Lower,
      Iss_LdStReady       => Iss_LdStReady,
      
       AddrBuffFull       => AddrBuffFull,
       AddrMatch0         => AddrMatch0,
       AddrMatch1         => AddrMatch1,
       AddrMatch2         => AddrMatch2,
       AddrMatch3         => AddrMatch3,
	   AddrMatch4         => AddrMatch4,
       AddrMatch5         => AddrMatch5,
       AddrMatch6         => AddrMatch6,
       AddrMatch7         => AddrMatch7,
      
       AddrMatch0Num      => AddrMatch0Num,
       AddrMatch1Num      => AddrMatch1Num,
       AddrMatch2Num      => AddrMatch2Num,
       AddrMatch3Num      => AddrMatch3Num,
	   AddrMatch4Num      => AddrMatch4Num,
       AddrMatch5Num      => AddrMatch5Num,
       AddrMatch6Num      => AddrMatch6Num,
       AddrMatch7Num      => AddrMatch7Num,      
       
       ScanAddr0          =>  IssuequeAddressReg(0),
       ScanAddr1          =>  IssuequeAddressReg(1),
       ScanAddr2          =>  IssuequeAddressReg(2),
       ScanAddr3          =>  IssuequeAddressReg(3),
	   ScanAddr4          =>  IssuequeAddressReg(4),
       ScanAddr5          =>  IssuequeAddressReg(5),
       ScanAddr6          =>  IssuequeAddressReg(6),
       ScanAddr7          =>  IssuequeAddressReg(7),
       
       Cdb_Flush          => Cdb_Flush,
       Rob_TopPtr         => Rob_TopPtr,
       Cdb_RobDepth       => Cdb_RobDepth  
);

    
    process ( Clk ,Resetb )
	    begin
            if ( Resetb = '0' ) then
             IssuequeInstrValReg <= "00000000" ;
             IssuqueCounter(0) <= "000";  -- these are counters to keep track of sw skipping lw
             IssuqueCounter(1) <= "000";
             IssuqueCounter(2) <= "000";
             IssuqueCounter(3) <= "000";             
             IssuqueCounter(4) <= "000";  -- these are counters to keep track of sw skipping lw
             IssuqueCounter(5) <= "000";
             IssuqueCounter(6) <= "000";
             IssuqueCounter(7) <= "000";
             
            elsif ( Clk'event and Clk='1' ) then
                
          ---- Selecting the Instrvalid for individual register in issuequeue  
		  -- you start from seven the top one
              if ( Flush(7) = '1' ) then  --flush has the highest priority 
                IssuequeInstrValReg(7) <= '0' ;
              else   
               if ( En(7) = '1' ) then  --update 
                if(Sel0 = '1'  ) then  --update from dispatch
                   IssuequeInstrValReg(7) <= '1';
	             else
                   IssuequeInstrValReg(7) <= '0';  
	            end if;   
               else
                   IssuequeInstrValReg(7) <= IssuequeInstrValReg(7);
               end if;
              end if;
            ----------------------------------------------- 
               if ( Flush(6) = '1') then
                 IssuequeInstrValReg(6) <= '0';
             else   
                 if ( En(6) = '1' ) then 
                  IssuequeInstrValReg(6) <= IssuequeInstrValReg(7); 
                 else
                  IssuequeInstrValReg(6) <= IssuequeInstrValReg(6); 
                 end if;
               end if;
              
               if ( Flush(5) = '1' ) then
                  IssuequeInstrValReg(5) <= '0';
                else   
                if ( En(5) = '1' ) then 
                  IssuequeInstrValReg(5) <= IssuequeInstrValReg(6); 
                  else
                  IssuequeInstrValReg(5) <= IssuequeInstrValReg(5); 
                end if;
               end if;
               
               if ( Flush(4) = '1' ) then
                   IssuequeInstrValReg(4) <= '0';
               else   
                if ( En(4) = '1' ) then 
                   IssuequeInstrValReg(4) <= IssuequeInstrValReg(5); 
                else
                   IssuequeInstrValReg(4) <= IssuequeInstrValReg(4); 
                end if;
               end if;
				
			   if ( Flush(3) = '1' ) then
                   IssuequeInstrValReg(3) <= '0';
               else   
                if ( En(3) = '1' ) then 
                   IssuequeInstrValReg(3) <= IssuequeInstrValReg(4); 
                else
                   IssuequeInstrValReg(3) <= IssuequeInstrValReg(3); 
                end if;
               end if;
				
			   if ( Flush(2) = '1') then
                 IssuequeInstrValReg(2) <= '0';
               else   
                 if ( En(2) = '1' ) then 
                  IssuequeInstrValReg(2) <= IssuequeInstrValReg(3); 
                 else
                  IssuequeInstrValReg(2) <= IssuequeInstrValReg(2); 
                 end if;
               end if;
              
               if ( Flush(1) = '1' ) then
                  IssuequeInstrValReg(1) <= '0';
                else   
                if ( En(1) = '1' ) then 
                  IssuequeInstrValReg(1) <= IssuequeInstrValReg(2); 
                  else
                  IssuequeInstrValReg(1) <= IssuequeInstrValReg(1); 
                end if;
               end if;
               
                if ( Flush(0) = '1' ) then
                   IssuequeInstrValReg(0) <= '0';
                else   
                 if ( En(0) = '1' ) then 
                   IssuequeInstrValReg(0) <= IssuequeInstrValReg(1); 
                 else
                   IssuequeInstrValReg(0) <= IssuequeInstrValReg(0); 
                 end if;
                end if;
				
		-- translate_off
           if ( Flush(7) = '1' ) then  --flush has the highest priority 
                IssuequeInstructReg(7) <="00000000000000000000000000000000";
              else   
               if ( En(7) = '1' ) then  --update 
			    if(Sel0 = '1'  ) then  --update from dispatch
                   IssuequeInstructReg(7) <=Dis_instruction;
	             else
                   IssuequeInstructReg(7) <="00000000000000000000000000000000";
	            end if;   
               else
				   IssuequeInstructReg(7) <= IssuequeInstructReg(7);
               end if;
              end if;
            ----------------------------------------------- 
               if ( Flush(6) = '1') then
                 IssuequeInstructReg(7) <="00000000000000000000000000000000";
             else   
                 if ( En(6) = '1' ) then 
                  IssuequeInstructReg(6) <= IssuequeInstructReg(7);  
                 else
                  IssuequeInstructReg(6) <= IssuequeInstructReg(6); 
                 end if;
               end if;
			   
			   if ( Flush(5) = '1') then
                 IssuequeInstructReg(7) <="00000000000000000000000000000000";
             else   
                 if ( En(5) = '1' ) then 
                  IssuequeInstructReg(5) <= IssuequeInstructReg(6);  
                 else
                  IssuequeInstructReg(5) <= IssuequeInstructReg(5); 
                 end if;
               end if;
			   
			   if ( Flush(4) = '1') then
                 IssuequeInstructReg(7) <="00000000000000000000000000000000";
             else   
                 if ( En(4) = '1' ) then 
                  IssuequeInstructReg(4) <= IssuequeInstructReg(5);  
                 else
                  IssuequeInstructReg(4) <= IssuequeInstructReg(4); 
                 end if;
               end if;
			   
			   if ( Flush(3) = '1') then
                 IssuequeInstructReg(7) <="00000000000000000000000000000000";
             else   
                 if ( En(3) = '1' ) then 
                  IssuequeInstructReg(3) <= IssuequeInstructReg(4);  
                 else
                  IssuequeInstructReg(3) <= IssuequeInstructReg(3); 
                 end if;
               end if;
			   
			   if ( Flush(2) = '1') then
                 IssuequeInstructReg(7) <="00000000000000000000000000000000";
             else   
                 if ( En(2) = '1' ) then 
                  IssuequeInstructReg(2) <= IssuequeInstructReg(3);  
                 else
                  IssuequeInstructReg(2) <= IssuequeInstructReg(2); 
                 end if;
               end if;
			   
			   if ( Flush(1) = '1') then
                 IssuequeInstructReg(7) <="00000000000000000000000000000000";
             else   
                 if ( En(1) = '1' ) then 
                  IssuequeInstructReg(1) <= IssuequeInstructReg(2);  
                 else
                  IssuequeInstructReg(1) <= IssuequeInstructReg(1); 
                 end if;
               end if;
			   
			   if ( Flush(0) = '1') then
                 IssuequeInstructReg(7) <="00000000000000000000000000000000";
             else   
                 if ( En(0) = '1' ) then 
                  IssuequeInstructReg(0) <= IssuequeInstructReg(1);  
                 else
                  IssuequeInstructReg(0) <= IssuequeInstructReg(0); 
                 end if;
               end if;
              -- translate_on
            -----------------For the counter -----------------------
			--=============================================================================================
            
            if ( En(7) = '1' ) then 
                  IssuqueCounter(7) <= "000";
           else -- if no shifting taking place here
              if ( IncrementCounter(7) = '1' ) then -- count enable from controller 
                  IssuqueCounter(7) <=  unsigned(IssuqueCounter(7)) + '1' ;
              else
                  IssuqueCounter(7) <=  IssuqueCounter(7) ;
              end if ;
            end if ;			 
			
			if ( En(6) = '1' ) then --increment the above one in case of shifting
              if ( IncrementCounter(7) = '1' ) then  
                  IssuqueCounter(6) <=  unsigned(IssuqueCounter(7)) + '1' ;
              else
                 IssuqueCounter(6) <=  IssuqueCounter(7) ;
              end if ;
            else
              if ( IncrementCounter(6) = '1' ) then
                  IssuqueCounter(6) <=  unsigned(IssuqueCounter(6)) + '1' ;
              else
                  IssuqueCounter(6) <=  IssuqueCounter(6) ;
              end if ;
            end if ;
            
            if ( En(5) = '1' ) then 
              if ( IncrementCounter(6) = '1' ) then 
                  IssuqueCounter(5) <=  unsigned(IssuqueCounter(6)) + '1' ;
              else
                 IssuqueCounter(5) <=  IssuqueCounter(6) ;
              end if ;
            else
              if ( IncrementCounter(5) = '1' ) then
                  IssuqueCounter(5) <=  unsigned(IssuqueCounter(5)) + '1' ;
              else
                  IssuqueCounter(5) <=  IssuqueCounter(5) ;
              end if ;
            end if ;
            
            if ( En(4) = '1' ) then 
              if ( IncrementCounter(5) = '1' ) then 
                  IssuqueCounter(4) <=  unsigned(IssuqueCounter(5)) + '1' ;
              else
                 IssuqueCounter(4) <=  IssuqueCounter(5) ;
              end if ;
            else
              if ( IncrementCounter(4) = '1' ) then
                  IssuqueCounter(4) <=  unsigned(IssuqueCounter(4)) + '1' ;
              else
                  IssuqueCounter(4) <=  IssuqueCounter(4) ;
              end if ;
            end if ;
			
			if ( En(3) = '1' ) then 
              if ( IncrementCounter(4) = '1' ) then 
                  IssuqueCounter(3) <=  unsigned(IssuqueCounter(4)) + '1' ;
              else
                 IssuqueCounter(3) <=  IssuqueCounter(4) ;
              end if ;
            else
              if ( IncrementCounter(3) = '1' ) then
                  IssuqueCounter(3) <=  unsigned(IssuqueCounter(3)) + '1' ;
              else
                  IssuqueCounter(3) <=  IssuqueCounter(3) ;
              end if ;
            end if ;
            
            if ( En(2) = '1' ) then --increment the above one in case of shifting
              if ( IncrementCounter(3) = '1' ) then  
                  IssuqueCounter(2) <=  unsigned(IssuqueCounter(3)) + '1' ;
              else
                 IssuqueCounter(2) <=  IssuqueCounter(3) ;
              end if ;
            else
              if ( IncrementCounter(2) = '1' ) then
                  IssuqueCounter(2) <=  unsigned(IssuqueCounter(2)) + '1' ;
              else
                  IssuqueCounter(2) <=  IssuqueCounter(2) ;
              end if ;
            end if ;
            
            if ( En(1) = '1' ) then 
              if ( IncrementCounter(2) = '1' ) then 
                  IssuqueCounter(1) <=  unsigned(IssuqueCounter(2)) + '1' ;
              else
                 IssuqueCounter(1) <=  IssuqueCounter(2) ;
              end if ;
            else
              if ( IncrementCounter(1) = '1' ) then
                  IssuqueCounter(1) <=  unsigned(IssuqueCounter(1)) + '1' ;
              else
                  IssuqueCounter(1) <=  IssuqueCounter(1) ;
              end if ;
            end if ;
            
            if ( En(0) = '1' ) then 
              if ( IncrementCounter(1) = '1' ) then 
                  IssuqueCounter(0) <=  unsigned(IssuqueCounter(1)) + '1' ;
              else
                 IssuqueCounter(0) <=  IssuqueCounter(1) ;
              end if ;
            else
              if ( IncrementCounter(0) = '1' ) then
                  IssuqueCounter(0) <=  unsigned(IssuqueCounter(0)) + '1' ;
              else
                  IssuqueCounter(0) <=  IssuqueCounter(0) ;
              end if ;
            end if ;
			 
			 --========================================================================
            
            ---- Selecting the RsData for individual register in issuequeue  
                          
                          if ( Sel1Rs(7) = '1') then --update from CDB
                             
                              IssuequeRsdataValReg(7) <= '1';
                        else
                            if ( En(7) = '1' ) then 
                                if ( Sel0 = '1' ) then --update from dispatch 
                                  
                                  IssuequeRsdataValReg(7) <= Dis_RsDataRdy;
                                else
                                   
                                   IssuequeRsdataValReg(7) <= '0';
                                end if;
                            else
                                  
                                  IssuequeRsdataValReg(7) <= IssuequeRsdataValReg(7);  -- it is important as no updation from dispatch
                            end if;
                        end if;   
                        
						if ( Sel1Rs(6) = '1') then 
                             
                             IssuequeRsdataValReg(6) <= '1';
                        else
                            if ( En(6) = '1') then 
                              
                              IssuequeRsdataValReg(6) <= IssuequeRsdataValReg(7); 
                            else
                                 
                                 IssuequeRsdataValReg(6) <= IssuequeRsdataValReg(6); 
                            end if;
                        end if;   
                        
                        if ( Sel1Rs(5) = '1') then 
                             
                             IssuequeRsdataValReg(5) <= '1';
                        else
                            if ( En(5) = '1') then 
                               
                               IssuequeRsdataValReg(5) <= IssuequeRsdataValReg(6); 
                            else
                               
                               IssuequeRsdataValReg(5) <= IssuequeRsdataValReg(5); 
                            end if;
                        end if;                       
                       
                        if ( Sel1Rs(4) = '1') then 
                             
                             IssuequeRsdataValReg(4) <= '1';
                           else
                             if ( En(4) = '1') then 
                               
                               IssuequeRsdataValReg(4) <= IssuequeRsdataValReg(5); 
                              else
                              
                               IssuequeRsdataValReg(4) <= IssuequeRsdataValReg(4); 
                           end if;
                        end if;
                        
						if ( Sel1Rs(3) = '1') then 
                             
                             IssuequeRsdataValReg(3) <= '1';
                           else
                             if ( En(3) = '1') then 
                               
                               IssuequeRsdataValReg(3) <= IssuequeRsdataValReg(4); 
                              else
                              
                               IssuequeRsdataValReg(3) <= IssuequeRsdataValReg(3); 
                           end if;
                        end if;
                       
                        if ( Sel1Rs(2) = '1') then 
                             
                             IssuequeRsdataValReg(2) <= '1';
                        else
                            if ( En(2) = '1') then 
                              
                              IssuequeRsdataValReg(2) <= IssuequeRsdataValReg(3); 
                            else
                                 
                                 IssuequeRsdataValReg(2) <= IssuequeRsdataValReg(2); 
                            end if;
                        end if;   
                        
                        if ( Sel1Rs(1) = '1'  ) then 
                             
                             IssuequeRsdataValReg(1) <= '1';
                        else
                            if ( En(1) = '1') then 
                               
                               IssuequeRsdataValReg(1) <= IssuequeRsdataValReg(2); 
                            else
                              
                               IssuequeRsdataValReg(1) <= IssuequeRsdataValReg(1); 
                            end if;
                        end if;                       
                       
                        if ( Sel1Rs(0) = '1') then 
                             
                             IssuequeRsdataValReg(0) <= '1';
                           else
                             if ( En(0) = '1') then 
                               
                               IssuequeRsdataValReg(0) <= IssuequeRsdataValReg(1); 
                              else
                               
                               IssuequeRsdataValReg(0) <= IssuequeRsdataValReg(0); 
                           end if;
                       end if;
                       
                       
                      ---- Selecting the Rdtag and Opcode for individual register in issuequeue  
                      
                        if (En(7) = '1') then 
                            if ( Sel0 = '1') then --update from dispatch
								IssuequeRobTag(7)    <= Dis_RobTag ;
								IssuequeOpcodeReg(7)   <= Dis_Opcode;
								IssuequeRstagReg(7)    <= Dis_RsPhyAddr ;
								IssuequeRdtagReg(7)    <= Dis_NewRdPhyAddr ;
                            else
								IssuequeRobTag(7)    <= (others => '0');
								IssuequeOpcodeReg(7)   <= '0';
								IssuequeRstagReg(7)    <= (others => '0' );
								IssuequeRdtagReg(7)    <= (others => '0' );
                            end if;
                        end if;  
                         
                        if (En(6) = '1') then  --update
                                IssuequeRobTag(6)    <= IssuequeRobTag(7);
                                IssuequeOpcodeReg(6)   <= IssuequeOpcodeReg(7);
                                IssuequeRstagReg(6)    <= IssuequeRstagReg(7);
								IssuequeRdtagReg(6)    <= IssuequeRdtagReg(7);
                        else  --keep as it is
                                IssuequeRobTag(6)    <= IssuequeRobTag(6);
                                IssuequeOpcodeReg(6)   <= IssuequeOpcodeReg(6); 
                                IssuequeRstagReg(6)    <= IssuequeRstagReg(6);
								IssuequeRdtagReg(6)    <= IssuequeRdtagReg(6);								
                        end if;
                            
                        if (En(5) = '1') then 
                                IssuequeRobTag(5)    <= IssuequeRobTag (6);
                                IssuequeOpcodeReg(5)   <= IssuequeOpcodeReg(6);
                                IssuequeRstagReg(5)    <= IssuequeRstagReg(6);
								IssuequeRdtagReg(5)    <= IssuequeRdtagReg(6);
                        else
                                IssuequeRobTag(5)    <= IssuequeRobTag(5);
                                IssuequeOpcodeReg(5)   <= IssuequeOpcodeReg(5); 
                                IssuequeRstagReg(5)    <= IssuequeRstagReg(5);
								IssuequeRdtagReg(5)    <= IssuequeRdtagReg(5);  -- corrected
                        end if;
						
                        if ( En(4) = '1' ) then 
                                IssuequeRobTag(4)    <= IssuequeRobTag(5);
                                IssuequeOpcodeReg(4)   <= IssuequeOpcodeReg(5);
                                IssuequeRstagReg(4)    <= IssuequeRstagReg(5);
								IssuequeRdtagReg(4)    <= IssuequeRdtagReg(5);
                        else
                                IssuequeRobTag(4)    <= IssuequeRobTag(4);
                                IssuequeOpcodeReg(4)   <= IssuequeOpcodeReg(4); 
                                IssuequeRstagReg(4)    <= IssuequeRstagReg(4);
								IssuequeRdtagReg(4)    <= IssuequeRdtagReg(4);
                        end if;
                        
						if ( En(3) = '1' ) then 
                                IssuequeRobTag(3)    <= IssuequeRobTag(4);
                                IssuequeOpcodeReg(3)   <= IssuequeOpcodeReg(4);
                                IssuequeRstagReg(3)    <= IssuequeRstagReg(4);
								IssuequeRdtagReg(3)    <= IssuequeRdtagReg(4);
                        else
                                IssuequeRobTag(3)    <= IssuequeRobTag(3);
                                IssuequeOpcodeReg(3)   <= IssuequeOpcodeReg(3); 
                                IssuequeRstagReg(3)    <= IssuequeRstagReg(3);
								IssuequeRdtagReg(3)    <= IssuequeRdtagReg(3);
                        end if;
                        						
                        if (En(2) = '1') then  --update
                                IssuequeRobTag(2)    <= IssuequeRobTag(3);
                                IssuequeOpcodeReg(2)   <= IssuequeOpcodeReg(3);
                                IssuequeRstagReg(2)    <= IssuequeRstagReg(3);
                                IssuequeRdtagReg(2)    <= IssuequeRdtagReg(3);
                        else  --keep as it is
                                IssuequeRobTag(2)    <= IssuequeRobTag(2);
                                IssuequeOpcodeReg(2)   <= IssuequeOpcodeReg(2); 
                                IssuequeRstagReg(2)    <= IssuequeRstagReg(2);
                                IssuequeRdtagReg(2)    <= IssuequeRdtagReg(2);
                        end if;
                            
                        if (En(1) = '1') then 
                                IssuequeRobTag(1)    <= IssuequeRobTag (2);
                                IssuequeOpcodeReg(1)   <= IssuequeOpcodeReg(2);
                                IssuequeRstagReg(1)    <= IssuequeRstagReg(2);
                                IssuequeRdtagReg(1)    <= IssuequeRdtagReg(2);
                        else
                                IssuequeRobTag(1)    <= IssuequeRobTag(1);
                                IssuequeOpcodeReg(1)   <= IssuequeOpcodeReg(1); 
                                IssuequeRstagReg(1)    <= IssuequeRstagReg(1);
                                IssuequeRdtagReg(1)    <= IssuequeRdtagReg(1);
                        end if;
						
                        if ( En(0) = '1' ) then 
                                IssuequeRobTag(0)    <= IssuequeRobTag(1);
                                IssuequeOpcodeReg(0)   <= IssuequeOpcodeReg(1);
                                IssuequeRstagReg(0)    <= IssuequeRstagReg(1);
                                IssuequeRdtagReg(0)    <= IssuequeRdtagReg(1);
                        else
                                IssuequeRobTag(0)    <= IssuequeRobTag(0);
                                IssuequeOpcodeReg(0)   <= IssuequeOpcodeReg(0); 
                                IssuequeRstagReg(0)    <= IssuequeRstagReg(0);
                                IssuequeRdtagReg(0)    <= IssuequeRdtagReg(0);
                        end if;
                                           
                     
                     -- Selectig the Address 
					 
					 --===========================================================================================
					if ( AddrUpdate(7) = '1' )  then  --this signal is coming from lsq_cntrl
						    IssuequeAddrReadyReg(7) <= '1' ;
							IssuequeAddressReg(7)   <= unsigned(PhyReg_LsqRsData) + unsigned(IssuequeAddressReg(7)) ;
                        else
                            if ( Sel0 = '1' ) then  --update from dispatch but address is not ready
                                IssuequeAddrReadyReg(7) <= '0' ;
                                IssuequeAddressReg(7)   <= DisAddrTemp;
                            else 
								if ( En(7) = '1' ) then  --since dispatch is not ready hence all zeros
                                    IssuequeAddrReadyReg(7) <= '0' ;
                                    IssuequeAddressReg(7)   <= (others => '0'); 
                                else
                                    IssuequeAddrReadyReg(7)   <= IssuequeAddrReadyReg(7);
                                    IssuequeAddressReg(7)     <= IssuequeAddressReg(7) ;
                                end if ;
                            end if ;
						end if;
                                                
                        if ( AddrUpdate(6) = '1' )  then
                            if ( AddrUpdateSel(6) = '1' ) then  -- notice the shift in update also
                                IssuequeAddrReadyReg(6) <= '1' ;
                                IssuequeAddressReg(6)   <= unsigned(PhyReg_LsqRsData) + unsigned(IssuequeAddressReg(7)) ;
                            else
                                IssuequeAddrReadyReg(6) <= '1' ;
                                IssuequeAddressReg(6)   <= unsigned(PhyReg_LsqRsData) + unsigned(IssuequeAddressReg(6)) ;
                            end if;
                        else 
                            if ( En(6) = '1' ) then 
                                IssuequeAddrReadyReg(6)  <= IssuequeAddrReadyReg(7);
                                IssuequeAddressReg(6)     <= IssuequeAddressReg(7);
                            else
                                IssuequeAddrReadyReg(6) <= IssuequeAddrReadyReg(6);
                                IssuequeAddressReg(6)    <= IssuequeAddressReg(6); 
                            end if ;
                        end if ;
                           
                        if ( AddrUpdate(5) = '1' )  then
                            if ( AddrUpdateSel(5) = '1' ) then  -- notice the shift in update also
                                IssuequeAddrReadyReg(5) <= '1' ;
                                IssuequeAddressReg(5)   <= unsigned(PhyReg_LsqRsData) + unsigned(IssuequeAddressReg(6)) ;
                            else
                                IssuequeAddrReadyReg(5) <= '1' ;
                                IssuequeAddressReg(5)   <= unsigned(PhyReg_LsqRsData) + unsigned(IssuequeAddressReg(5)) ;
                            end if;
                        else 
                            if ( En(5) = '1' ) then 
                                IssuequeAddrReadyReg(5)  <= IssuequeAddrReadyReg(6);
                                IssuequeAddressReg(5)     <= IssuequeAddressReg(6);
                            else
                                IssuequeAddrReadyReg(5) <= IssuequeAddrReadyReg(5);
                                IssuequeAddressReg(5)    <= IssuequeAddressReg(5); 
                            end if ;
                        end if ;
                           
                        if ( AddrUpdate(4) = '1' )  then
                            if ( AddrUpdateSel(4) = '1' ) then  -- notice the shift in update also
                                IssuequeAddrReadyReg(4) <= '1' ;
                                IssuequeAddressReg(4)   <= unsigned(PhyReg_LsqRsData) + unsigned(IssuequeAddressReg(5)) ;
                            else
                                IssuequeAddrReadyReg(4) <= '1' ;
                                IssuequeAddressReg(4)   <= unsigned(PhyReg_LsqRsData) + unsigned(IssuequeAddressReg(4)) ;
                            end if;
                        else 
                            if ( En(4) = '1' ) then 
                                IssuequeAddrReadyReg(4)  <= IssuequeAddrReadyReg(5);
                                IssuequeAddressReg(4)     <= IssuequeAddressReg(5);
                            else
                                IssuequeAddrReadyReg(4) <= IssuequeAddrReadyReg(4);
                                IssuequeAddressReg(4)    <= IssuequeAddressReg(4); 
                            end if ;
                        end if ;
						
						if ( AddrUpdate(3) = '1' )  then
                            if ( AddrUpdateSel(3) = '1' ) then  -- notice the shift in update also
                                IssuequeAddrReadyReg(3) <= '1' ;
                                IssuequeAddressReg(3)   <= unsigned(PhyReg_LsqRsData) + unsigned(IssuequeAddressReg(4)) ;
                            else
                                IssuequeAddrReadyReg(3) <= '1' ;
                                IssuequeAddressReg(3)   <= unsigned(PhyReg_LsqRsData) + unsigned(IssuequeAddressReg(3)) ;
                            end if;
                        else 
                            if ( En(3) = '1' ) then 
                                IssuequeAddrReadyReg(3)  <= IssuequeAddrReadyReg(4);
                                IssuequeAddressReg(3)     <= IssuequeAddressReg(4);
                            else
                                IssuequeAddrReadyReg(3) <= IssuequeAddrReadyReg(3);
                                IssuequeAddressReg(3)    <= IssuequeAddressReg(3); 
                            end if ;
                        end if ;
						
						if ( AddrUpdate(2) = '1' )  then
                            if ( AddrUpdateSel(2) = '1' ) then  -- notice the shift in update also
                                IssuequeAddrReadyReg(2) <= '1' ;
                                IssuequeAddressReg(2)   <= unsigned(PhyReg_LsqRsData) + unsigned(IssuequeAddressReg(3)) ;
                            else
                                IssuequeAddrReadyReg(2) <= '1' ;
                                IssuequeAddressReg(2)   <= unsigned(PhyReg_LsqRsData) + unsigned(IssuequeAddressReg(2)) ;
                            end if;
                        else 
                            if ( En(2) = '1' ) then 
                                IssuequeAddrReadyReg(2)  <= IssuequeAddrReadyReg(3);
                                IssuequeAddressReg(2)     <= IssuequeAddressReg(3);
                            else
                                IssuequeAddrReadyReg(2) <= IssuequeAddrReadyReg(2);
                                IssuequeAddressReg(2)    <= IssuequeAddressReg(2); 
                            end if ;
                        end if ;
						
						if ( AddrUpdate(1) = '1' )  then
                            if ( AddrUpdateSel(1) = '1' ) then  -- notice the shift in update also
                                IssuequeAddrReadyReg(1) <= '1' ;
                                IssuequeAddressReg(1)   <= unsigned(PhyReg_LsqRsData) + unsigned(IssuequeAddressReg(2)) ;
                            else
                                IssuequeAddrReadyReg(1) <= '1' ;
                                IssuequeAddressReg(1)   <= unsigned(PhyReg_LsqRsData) + unsigned(IssuequeAddressReg(1)) ;
                            end if;
                        else 
                            if ( En(1) = '1' ) then 
                                IssuequeAddrReadyReg(1)  <= IssuequeAddrReadyReg(2);
                                IssuequeAddressReg(1)     <= IssuequeAddressReg(2);
                            else
                                IssuequeAddrReadyReg(1) <= IssuequeAddrReadyReg(1);
                                IssuequeAddressReg(1)    <= IssuequeAddressReg(1); 
                            end if ;
                        end if ;
						
						if ( AddrUpdate(0) = '1' )  then
                            if ( AddrUpdateSel(0) = '1' ) then  -- notice the shift in update also
                                IssuequeAddrReadyReg(0) <= '1' ;
                                IssuequeAddressReg(0)   <= unsigned(PhyReg_LsqRsData) + unsigned(IssuequeAddressReg(1)) ;
                            else
                                IssuequeAddrReadyReg(0) <= '1' ;
                                IssuequeAddressReg(0)   <= unsigned(PhyReg_LsqRsData) + unsigned(IssuequeAddressReg(0)) ;
                            end if;
                        else 
                            if ( En(0) = '1' ) then 
                                IssuequeAddrReadyReg(0)  <= IssuequeAddrReadyReg(1);
                                IssuequeAddressReg(0)     <= IssuequeAddressReg(1);
                            else
                                IssuequeAddrReadyReg(0) <= IssuequeAddrReadyReg(0);
                                IssuequeAddressReg(0)    <= IssuequeAddressReg(0); 
                            end if ;
                        end if ;
                    end if;
                end process;
  
	--------------- Nearly Full Signal ------------------------------
   
   
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
									  
   Issque_LdStQueueTwoOrMoreVacant  <= UpperHalf_Has_Two_or_More_vacant or LowerHalf_Has_Two_or_More_vacant or ((not(IssuequefullTemp_Lower)) and (not(IssuequefullTemp_Upper)));

	Process(AddrUpdate,AddrUpdateSel,IssuequeRstagReg)
		begin             
                        if ( AddrUpdate(0) = '1' )  then
                            if ( AddrUpdateSel(0) = '1' ) then  -- notice the shift in update also
                               Iss_RsPhyAddrLsq<=IssuequeRstagReg(1);
							else
                               Iss_RsPhyAddrLsq<=IssuequeRstagReg(0);
				            end if;
                        elsif ( AddrUpdate(1) = '1' )  then
                            if ( AddrUpdateSel(1) = '1' ) then  -- notice the shift in update also
                              Iss_RsPhyAddrLsq<=IssuequeRstagReg(2);
							else
                              Iss_RsPhyAddrLsq<=IssuequeRstagReg(1);
							end if;
                        elsif ( AddrUpdate(2) = '1' )  then
                            if ( AddrUpdateSel(2) = '1' ) then  -- notice the shift in update also
                              Iss_RsPhyAddrLsq<=IssuequeRstagReg(3);
							else
                              Iss_RsPhyAddrLsq<=IssuequeRstagReg(2);
							end if;
                        elsif ( AddrUpdate(3) = '1' )  then
                            if ( AddrUpdateSel(3) = '1' ) then  -- notice the shift in update also
                              Iss_RsPhyAddrLsq<=IssuequeRstagReg(4);
							else
                              Iss_RsPhyAddrLsq<=IssuequeRstagReg(3);
							end if;
						elsif ( AddrUpdate(4) = '1' )  then
                            if ( AddrUpdateSel(4) = '1' ) then  -- notice the shift in update also
                              Iss_RsPhyAddrLsq<=IssuequeRstagReg(5);
							else
                              Iss_RsPhyAddrLsq<=IssuequeRstagReg(4);
							end if;
						elsif ( AddrUpdate(5) = '1' )  then
                            if ( AddrUpdateSel(5) = '1' ) then  -- notice the shift in update also
                              Iss_RsPhyAddrLsq<=IssuequeRstagReg(6);
							else
                              Iss_RsPhyAddrLsq<=IssuequeRstagReg(5);
							end if;
						elsif ( AddrUpdate(6) = '1' )  then
                            if ( AddrUpdateSel(6) = '1' ) then  -- notice the shift in update also
                              Iss_RsPhyAddrLsq<=IssuequeRstagReg(7);
							else
                              Iss_RsPhyAddrLsq<=IssuequeRstagReg(6);
							end if;
						else
							Iss_RsPhyAddrLsq<=IssuequeRstagReg(7);
							end if;
end process	;
				
  process  (IssuequeRobTag,IssuequeOpcodeReg,OutSelect,IssuequeAddressReg,IssuequeRdtagReg) 
    begin
        case (OutSelect) is  -- to send out the selected information to issue unit
                    when "000" =>     
                              Iss_LdStAddr         <= IssuequeAddressReg(0);
                              Iss_LdStRobTag        <= IssuequeRobTag (0); 
                              IssuequeOpcodeTemp   <= IssuequeOpcodeReg(0);
							  Iss_LdStPhyAddr      <= IssuequeRdtagReg(0); 
							  LsqSwAddr            <= IssuequeRobTag (0) & IssuequeAddressReg(0); 
							--translate_off
							  Iss_instructionLsq     <=IssuequeInstructReg(0);
                            --translate_on   
                    when "001" =>   
                              Iss_LdStAddr         <= IssuequeAddressReg(1);
                              Iss_LdStRobTag        <= IssuequeRobTag (1); 
                              IssuequeOpcodeTemp   <= IssuequeOpcodeReg(1);
							  Iss_LdStPhyAddr      <= IssuequeRdtagReg(1); 
							  LsqSwAddr            <= IssuequeRobTag (1) & IssuequeAddressReg(1); 
							--translate_off
							  Iss_instructionLsq     <=IssuequeInstructReg(1);
                            --translate_on  
                                
                    when "010" =>   
                              Iss_LdStAddr         <= IssuequeAddressReg(2);
                              Iss_LdStRobTag        <= IssuequeRobTag (2); 
                              IssuequeOpcodeTemp   <= IssuequeOpcodeReg(2);
							  Iss_LdStPhyAddr      <= IssuequeRdtagReg(2); 
							  LsqSwAddr            <= IssuequeRobTag (2) & IssuequeAddressReg(2); 
							--translate_off
							  Iss_instructionLsq     <=IssuequeInstructReg(2);
                            --translate_on  
                                          
                                         
                    when "011"  => 
                              Iss_LdStAddr         <= IssuequeAddressReg(3);
                              Iss_LdStRobTag        <= IssuequeRobTag (3); 
                              IssuequeOpcodeTemp   <= IssuequeOpcodeReg(3);
							  Iss_LdStPhyAddr      <= IssuequeRdtagReg(3); 
							  LsqSwAddr            <= IssuequeRobTag (3) & IssuequeAddressReg(3);
							--translate_off
							  Iss_instructionLsq     <=IssuequeInstructReg(3);
                            --translate_on  
							  
					when "100" =>     
                              Iss_LdStAddr         <= IssuequeAddressReg(4);
                              Iss_LdStRobTag        <= IssuequeRobTag (4); 
                              IssuequeOpcodeTemp   <= IssuequeOpcodeReg(4);
							  Iss_LdStPhyAddr      <= IssuequeRdtagReg(4); 
							  LsqSwAddr            <= IssuequeRobTag (4) & IssuequeAddressReg(4); 
							--translate_off
							  Iss_instructionLsq     <=IssuequeInstructReg(4);
                            --translate_on  
                               
                    when "101" =>   
                              Iss_LdStAddr         <= IssuequeAddressReg(5);
                              Iss_LdStRobTag        <= IssuequeRobTag (5); 
                              IssuequeOpcodeTemp   <= IssuequeOpcodeReg(5);
							  Iss_LdStPhyAddr      <= IssuequeRdtagReg(5); 
							  LsqSwAddr            <= IssuequeRobTag (5) & IssuequeAddressReg(5); 
							--translate_off
							  Iss_instructionLsq     <=IssuequeInstructReg(5);
                            --translate_on  
                                
                    when "110" =>   
                              Iss_LdStAddr         <= IssuequeAddressReg(6);
                              Iss_LdStRobTag        <= IssuequeRobTag (6); 
                              IssuequeOpcodeTemp   <= IssuequeOpcodeReg(6);
							  Iss_LdStPhyAddr      <= IssuequeRdtagReg(6); 
							  LsqSwAddr            <= IssuequeRobTag (6) & IssuequeAddressReg(6);  
							--translate_off
							  Iss_instructionLsq     <=IssuequeInstructReg(6);
                            --translate_on  
                                          
                                         
                    when others  => 
                              Iss_LdStAddr         <= IssuequeAddressReg(7);
                              Iss_LdStRobTag        <= IssuequeRobTag (7); 
                              IssuequeOpcodeTemp   <= IssuequeOpcodeReg(7);
							  Iss_LdStPhyAddr      <= IssuequeRdtagReg(7); 
							  LsqSwAddr            <= IssuequeRobTag (7) & IssuequeAddressReg(7);
							--translate_off
							  Iss_instructionLsq     <=IssuequeInstructReg(7);
                            --translate_on  
		end case ; 
  end process ;               
end behave ;
                             