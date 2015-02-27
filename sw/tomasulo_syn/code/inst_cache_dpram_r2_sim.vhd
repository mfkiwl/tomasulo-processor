-------------------------------------------------------------------------------
--
-- Design       		:  inst_cache_dpram (Dual Port RAM holding cache data)
--		In summer 2008, it was inst_cache_sprom  (Single Port ROM holding the cache data)
-- Project      		: ee560 Tomosulo -- Instruction Cache Emulator
-- Author       		: Srinivas Vaduvatha , Gandhi Puvvada
-- Company      		: University of Southern California 
-- Date last revised	: 7/23/2008, 7/15/2009
-------------------------------------------------------------------------------
--
-- File         : inst_cache_dpram_r2.vhd (produced by modifying Summer 2008 inst_cache_sprom_r1.vhd and data_mem_dp.vhd)
--
-------------------------------------------------------------------------------
--
-- Description  :  This BRAM is instantiated by the instr_cache module. 
--			This holds the instructions. 
--				In Summer 2008, it was a ROM (BRAM acting like a ROM) with  inital 
--				content (instruction stream) defined through a package called
--				instr_stream_pkg.
--			In Summer 2009, it is converted to a dual port RAM. The first port (Port a) is of read/write type
--			and it faciliatates downloading a file containing cache contents from a text file holding instructions 
--			in hex notation, 4 instruction per line, with Instruction0 on the right-end of the line:
--				 Instruction3_ Instruction2_Instruction1_Instruction0 
--	 	Module features: 
--		Data width & Address width - Generics
--                Port b:  synchronous Read only (for the processor cache read operation) 
--	         Port a: synchronous Read/Write (for File I/O through Adept 2.0)
--                Infers BRAM resource in Xilinx FPGAs.
--                If the width / depth specified require more bits than in a single 
--                BRAM, multiple BRAMs are automatically cascaded to form a larger 
--                memory by the Xilinx XST.  Memory has to be of (2**n) depth.
--
-------------------------------------------------------------------------------

-- libraries and use clauses
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
-- use ieee.std_logic_unsigned.all;


use work.instr_stream_pkg.all; -- instruction stream defining package


entity inst_cache_dpram is 
generic (
         DATA_WIDTH     : integer := 128; --DATA_WIDTH_CONSTANT; -- defined as 128 in the instr_stream_pkg; 
         ADDR_WIDTH     : integer := 6 --ADDR_WIDTH_CONSTANT  -- defined as 6 in the instr_stream_pkg; 
        );
port (
      clka          : in std_logic;
      addr_a        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      data_in_a     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      wea           : in  std_logic; 
      data_out_a    : out std_logic_vector(DATA_WIDTH-1 downto 0);
		ena			  : in  std_logic;	

      clkb          : in  std_logic; 
      addr_b        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      -- data_in_b     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      -- web           : in  std_logic; 
      data_out_b    : out std_logic_vector(DATA_WIDTH-1 downto 0)
     ); 

end inst_cache_dpram ; 


architecture inferable of inst_cache_dpram is 

-- signals declarations.
	
-- Note: A signal called "mem" of user defined type "mem_type" was declared 
-- in a package called "instr_stream_pkg" refered in the use clause above.
-- It has lines similar to the following lines. 
-- The initial content defines the stream of instructions.
-- -- type declarations
type mem_type is array (0 to (2**ADDR_WIDTH)-1) of std_logic_vector((DATA_WIDTH-1) downto 0); 


--*****************************************************************************************
-- This stream is used to generate the walking led pattern using memory mapped i/0
--*****************************************************************************************


signal mem : mem_type
 := (
     X"00000020_AC0200FC_00421020_00000020", -- Loc 0C --nop, 08-- sw $2, 252($0) --[ 252 byte address = 64 word address], 04-- add $2, $2, $2 , 00- nop
	  X"00000020_00000020_00000020_08000000", -- Loc 1C, 18, 14, 10 --jump Loc 00 --rest all are NOP's 
	  X"00000020_00000020_00000020_00000020",  -- Loc 2C, 28, 24, 20   
	  X"00000020_00000020_00000020_00000020",  -- Loc 3C, 38, 34, 30  
    
	  X"00000020_00000020_00000020_00000020",  -- Loc 4C, 48, 44, 40  
	  X"00000020_00000020_00000020_00000020",  -- Loc 5C, 58, 54, 50  
	  X"00000020_00000020_00000020_00000020",  -- Loc 6C, 68, 64, 60  
	  X"00000020_00000020_00000020_00000020",  -- Loc 7C, 78, 74, 70   
    
	  X"00000020_00000020_00000020_00000020",  -- Loc 8C, 88, 84, 80   
	  X"00000020_00000020_00000020_00000020",  -- Loc 9C, 98, 94, 90 
	  X"00000020_00000020_00000020_00000020",  -- Loc AC, A8, A4, A0 
 	  X"00000020_00000020_00000020_00000020",  -- Loc BC, B8, B4, B0    
    
	  X"00000020_00000020_00000020_00000020",  -- Loc CC, C8, C4, C0
	  X"00000020_00000020_00000020_00000020",  -- Loc DC, D8, D4, D0
	  X"00000020_00000020_00000020_00000020",  -- Loc EC, E8, E4, E0
	  X"00000020_00000020_00000020_00000020",  -- Loc FC, F8, F4, F0
    
	  X"00000020_00000020_00000020_00000020",  -- Loc 10C, 108, 104, 100
	  X"00000020_00000020_00000020_00000020",  -- Loc 11C, 118, 114, 110
	  X"00000020_00000020_00000020_00000020",  -- Loc 12C, 128, 124, 120
	  X"00000020_00000020_00000020_00000020",  -- Loc 13C, 138, 134, 130
	  X"00000020_00000020_00000020_00000020",  -- Loc 14C, 148, 144, 140
	  X"00000020_00000020_00000020_00000020",  -- Loc 15C, 158, 154, 150
	  X"00000020_00000020_00000020_00000020",  -- Loc 16C, 168, 164, 160
	  X"00000020_00000020_00000020_00000020",  -- Loc 17C, 178, 174, 170
	  
    X"00000020_00000020_00000020_00000020",  -- Loc 18C, 188, 184, 180
	  X"00000020_00000020_00000020_00000020",  -- Loc 19C, 198, 194, 190
	  X"00000020_00000020_00000020_00000020",  -- Loc 1AC, 1A8, 1A4, 1A0
	  X"00000020_00000020_00000020_00000020",  -- Loc 1BC, 1B8, 1B4, 1B0
	  X"00000020_00000020_00000020_00000020",  -- Loc 1CC, 1C8, 1C4, 1C0
	  X"00000020_00000020_00000020_00000020",  -- Loc 1DC, 1D8, 1D4, 1D0
	  X"00000020_00000020_00000020_00000020",  -- Loc 1EC, 1E8, 1E4, 1E0
	  X"00000020_00000020_00000020_00000020",  -- Loc 1FC, 1F8, 1F4, 1F0

	  X"00000020_00000020_00000020_00000020",  -- Loc 20C, 208, 204, 200
	  X"00000020_00000020_00000020_00000020",  -- Loc 21C, 218, 214, 221
	  X"00000020_00000020_00000020_00000020",  -- Loc 22C, 228, 224, 220
	  X"00000020_00000020_00000020_00000020",  -- Loc 23C, 238, 234, 230
	  X"00000020_00000020_00000020_00000020",  -- Loc 24C, 248, 244, 240
	  X"00000020_00000020_00000020_00000020",  -- Loc 25C, 258, 254, 250
	  X"00000020_00000020_00000020_00000020",  -- Loc 26C, 268, 264, 260
	  X"00000020_00000020_00000020_00000020",  -- Loc 27C, 278, 274, 270

	  X"00000020_00000020_00000020_00000020",  -- Loc 28C, 288, 284, 280
	  X"00000020_00000020_00000020_00000020",  -- Loc 29C, 298, 294, 290
	  X"00000020_00000020_00000020_00000020",  -- Loc 2AC, 2A8, 2A4, 2A0
	  X"00000020_00000020_00000020_00000020",  -- Loc 2BC, 2B8, 2B4, 2B0
	  X"00000020_00000020_00000020_00000020",  -- Loc 2CC, 2C8, 2C4, 2C0
	  X"00000020_00000020_00000020_00000020",  -- Loc 2DC, 2D8, 2D4, 2D0
	  X"00000020_00000020_00000020_00000020",  -- Loc 2EC, 2E8, 2E4, 2E0
	  X"00000020_00000020_00000020_00000020",  -- Loc 2FC, 2F8, 2F4, 2F0

	  X"00000020_00000020_00000020_00000020",  -- Loc 30C, 308, 304, 300
	  X"00000020_00000020_00000020_00000020",  -- Loc 31C, 318, 314, 331
	  X"00000020_00000020_00000020_00000020",  -- Loc 32C, 328, 324, 320
	  X"00000020_00000020_00000020_00000020",  -- Loc 33C, 338, 334, 330
	  X"00000020_00000020_00000020_00000020",  -- Loc 34C, 348, 344, 340
	  X"00000020_00000020_00000020_00000020",  -- Loc 35C, 358, 354, 350
	  X"00000020_00000020_00000020_00000020",  -- Loc 36C, 368, 364, 360
	  X"00000020_00000020_00000020_00000020",  -- Loc 37C, 378, 374, 370

	  X"00000020_00000020_00000020_00000020",  -- Loc 38C, 388, 384, 380
	  X"00000020_00000020_00000020_00000020",  -- Loc 39C, 398, 394, 390
	  X"00000020_00000020_00000020_00000020",  -- Loc 3AC, 3A8, 3A4, 3A0
	  X"00000020_00000020_00000020_00000020",  -- Loc 3BC, 3B8, 3B4, 3B0
	  
	  -- the last 16 instructions are looping jump instructions 
	  X"080000F3_080000F2_080000F1_080000F0",  -- Loc 3CC, 3C8, 3C4, 3C0
	  X"080000F7_080000F6_080000F5_080000F4",  -- Loc 3DC, 3D8, 3D4, 3D0
	  X"080000FB_080000FA_080000F9_080000F8",  -- Loc 3EC, 3E8, 3E4, 3E0
	  X"080000FF_080000FE_080000FD_080000FC"   -- Loc 3FC, 3F8, 3F4, 3F0
	  	  ) ;


begin 
porta_oper : process (clka) 
begin 
    if (clka = '1' and clka'event) then
        if (wea = '1' and ena='1') then 
            mem(CONV_INTEGER(unsigned(addr_a)))     <= data_in_a; 
        end if;
		  if( ena='1')then
			data_out_a          <= mem(CONV_INTEGER(unsigned(addr_a)));
		  end if;	
    end if;
end process; 

portb_oper : process (clkb) 
begin 
    if (clkb = '1' and clkb'event) then
    --    if (web = '1') then 
    --        mem(CONV_INTEGER(addr_b))     := data_in_b; 
    --    end if;
        data_out_b          <= mem(CONV_INTEGER(unsigned(addr_b))); 
    end if;
end process; 

end inferable ;
--- ===========================================================
