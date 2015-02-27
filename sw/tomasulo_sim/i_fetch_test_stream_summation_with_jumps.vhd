

-- i_fetch_test_stream_summation_with_jumps.vhd
-- Date 7/31/08
-- This test stream is essentially same as i_fetch_test_stream_summation.vhd
-- except that we added 8 jump instructions to make sure that a student design behaves properly
-- when a sequence of jumps are issued. Here we added 8 jumps but in execution, only 6 jumps are executed in a row.
-- Please use the file, inst_cache_r1_zero_latency.vhd, with this test stream. Because the latency entries in this file
-- are all turned to zero, we should see that the 6 jump instructions are executed on consecutive clock. 
-- We want to make sure that our implementation of the i_fetch_q_efficient_r1.vhd is as per our plan of conveying
-- target address to the i_cache quickly and forward the target instruction to the dispatch unit quickly.

-- file: i_fetch_test_stream_instr_stream_pkg.vhd (version: i_fetch_test_stream_instr_stream_pkg_non_aligned_branches.vhd)
-- Written by Gandhi Puvvada
-- date of last rivision: 7/23/2008 
--
-- A package file to define the instruction stream to be placed in the instr_cache.
-- This package, "instr_stream_pkg", is refered in a use clause in the inst_cache_sprom module.
-- We will use several files similar to this containining different instruction streams.
-- The package name will remain the same, namely instr_stream_pkg.
-- Only the file name changes from, say  i_fetch_test_stream_instr_stream_pkg.vhd
-- to say mult_test_stream_instr_stream_pkg.vhd.
-- Depending on which instr_stream_pkg file was analysed/compiled  most recently,
-- that stream will be used for simulation/synthesis.
----------------------------------------------------------
library std, ieee;
use ieee.std_logic_1164.all;

package instr_stream_pkg is

    constant DATA_WIDTH_CONSTANT     : integer := 128; -- data width of of our cache
    constant ADDR_WIDTH_CONSTANT     : integer :=   6; -- address width of our cache

	-- type declarations
	type mem_type is array (0 to (2**ADDR_WIDTH_CONSTANT)-1) of std_logic_vector((DATA_WIDTH_CONSTANT-1) downto 0); 
  
	signal mem : mem_type := (
    
	  X"00002020_00001820_01401020_0080F820", -- Loc 0C, 08, 04, 00
	  X"00000020_00003820_00003020_00002820", -- Loc 1C, 18, 14, 10
	  
	  X"0800000C_0800000B_0800000A_08000009", -- Loc 2C, 28, 24, 20 -- SERIES OF JUMPS
	  X"08000018_08000010_08000018_0800000E", -- Loc 3C, 38, 34, 30 -- SERIES OF JUMPS

	  X"00C53020_8C850000_007F2019_005F3819", -- Loc 4C, 48, 44, 40
	  X"1000FFF9_10620001_00611820_ACE60000", -- Loc 5C, 58, 54, 50

	  X"00000020_00000020_00000020_00000020", -- Loc 6C, 68, 64, 60
	  X"00000020_00000020_00000020_00000020", -- Loc 7C, 78, 74, 70

	  X"00000020_00000020_00000020_00000020", -- Loc 8C, 88, 84, 80
	  X"00000020_00000020_00000020_00000020", -- Loc 9C, 98, 94, 90
	  X"00000020_00000020_00000020_00000020", -- Loc AC, A8, A4, A0
	  X"00000020_00000020_00000020_00000020", -- Loc BC, B8, B4, B0    
    
	  X"00000020_00000020_00000020_00000020", -- Loc CC, C8, C4, C0
	  X"00000020_00000020_00000020_00000020", -- Loc DC, D8, D4, D0
	  X"00000020_00000020_00000020_00000020", -- Loc EC, E8, E4, E0
	  X"00000020_00000020_00000020_00000020", -- Loc FC, F8, F4, F0

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
end package instr_stream_pkg;


-- loc (00)  -- 0080F820 -- ADD $31, $4, $0  -- $31 = 4
-- loc (04)  -- 01401020 -- ADD $2, $10, $0  -- num_of_items = 10
-- loc (08)  -- 00001820 -- ADD $3, $0, $0   -- read_index = 0
-- loc (0C)  -- 00002020 -- ADD $4, $0, $0   -- read_addr = 0
-- loc (10)  -- 00002820 -- ADD $5, $0, $0   -- read_val = 0
-- loc (14)  -- 00003020 -- ADD $6, $0, $0   -- sum = 0
-- loc (18)  -- 00003820 -- ADD $7, $0, $0   -- write_addr = 0
-- loc (1C)  -- 00000020 -- noop

-- loc (20)  -- 08000009-- j   9 -- jump to the next loc.
-- loc (24)  -- 0800000A -- j   A -- jump to the next loc.
-- loc (28)  -- 0800000B -- j   B -- jump to the next loc.
-- loc (2C)  -- 0800000C -- j   C -- jump to the next loc.
-- loc (30)  -- 0800000E -- j   E -- skip a line and jump to next to next loc. (loc 38)
-- loc (34)  -- 08000018 -- j  18 -- abort and jump out.
-- loc (38)  -- 08000010 -- j   10 -- jump to the MUL at loc 40.
-- loc (3C)  -- 08000018 -- j  18 -- abort and jump out.

-- loc (40) -- 005F3819 -- MUL $7, $2, $31   -- write_addr = num_of_items * 4
-- loc (44) -- 007F2019 -- MUL $4, $3, $31   -- read_addr = index * 4
-- loc (48) -- 8C850000 -- LW $5 ,0( $4)     -- read_val = M(read_addr)
-- loc (4C) -- 00C53020 -- Add $6, $6, $5    -- sum = sum + value
-- loc (50) -- ACE60000 -- SW $6 ,0( $7)     -- M(write_addr) = sum
-- loc (54) -- 00611820 -- Add $3, $3, $1    -- index++
-- loc (58) -- 10620001 -- BEQ $3 ,$2 ,1     -- (index = num_of_items)?
-- loc (5C) -- 1000FFF9 -- BEQ $0 ,$0 ,-7    -- jmp
-- loc (60) -- 00000020 -- noop
--
-- REGISTERS
-- $0  --> 0
-- $1  --> 1
-- $2  --> 10 num_of_items
-- $3  --> 0  read index
-- $4  --> 0  read addr
-- $5  --> 0  mem_value
-- $6  --> 0  sum
-- $7  --> 0  write addr (0 for version 1, 40 for version 2)
-- $31 --> 4  for address calculation
--
-- MEM
-- Put first n numbers starting from the beginning of the memory.
-- You will get the sum of them at n+1
