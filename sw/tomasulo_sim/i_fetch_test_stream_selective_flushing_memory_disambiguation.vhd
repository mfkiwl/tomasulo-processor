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

  
	  X"008C6819_0202601B_00000020_00000020",  -- Loc 0C, 08, 04, 00  
	  X"11C40006_AC0C0000_8C890000_0182701B",  -- Loc 1C, 18, 14, 10  -- corrected
	  X"8C840000_00030820_00020820_00232819",  -- Loc 2C, 28, 24, 20   
	  X"AC050014_AC0E0010_AC0C0010_0242601B",  -- Loc 3C, 38, 34, 30  
	  
	  X"00000020_AC0C0020_AC04001C_AC010018",  -- Loc 4C, 48, 44, 40  
	  X"00000020_00000020_00000020_00000020",  -- Loc 5C, 58, 54, 50  
	  X"0180C01B_0182681B_0202601B_00000020",  -- Loc 6C, 68, 64, 60  
	  X"AC130004_AC120004_8DA90000_AC180004",  -- Loc 7C, 78, 74, 70   
    
	  X"00000020_00000020_00000020_AC09000C",  -- Loc 8C, 88, 84, 80   
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

end package instr_stream_pkg;

-- MEMORY DISAMBIGUATION
-- Sukhun Kang
-- Date : 07/27/09

--0202601B   DIV $12, $16, $2   $12 = 16/2 = 8
--006C6819   MUL $13, $4, $12   $13 = 8*4 = 32
--0182701B   DIV $14, $12, $2   $14 = 8/2 = 4
--8C890000   LW $9,  0($4)     $9 = dmem(1) = 16
--AC0C0000   SD $12, 0($0)     dmem(0) = 8
--11C40006   BEQ $14, $4, 6   IF $4 = $14, jump to the instruction after SD $12, 4($0) skips 6 instructions
--00232819   MUL $5, $1, $3     $5 = 1*3 = 3 * should be flushed*
--00020820   ADD $1, $0, $2     $1 = 0+2 = 2 *should be flushed*
--00030820   ADD $1, $0, $3     $1 = 0+3 = 3* should be flushed*
--8C840000   LD  $4, 0($4)      $4 = dmem(1) = 8  *should be flushed*
--0242601B   DIV $12, $18, $2   $12 = 18/2 = 9  *should flushed*

--AC0C0010   SD  $12, 16($0)     dmem(4) = 9 *should flushed*
--AC0E0010   SD  $14, 16($0)     dmem(4) = 4  BRANCH TARGET
--AC050014   SD  $5, 20($0)      dmem(5) = $5 = 5 not 3
--AC010018   SD  $1, 24($0)     dmem(6) = $1 = 1 not 3
--AC04001C   SD  $4, 28($0)     dmem(7) = $4 = 4 not 8
--AC0C0020   SD  $12, 32($0)    dmem(8) = $12 = 8 not 9

--************************************************
--************************************************
-- tag opcode    mnemonics           result
--************************************************
-- 0   0202601B  div $12, $16, $2    $12 =  (16/2 = 8)  
-- 1   0182681B  div $13, $12, $2    $13 =  (8/2 = 4)  
-- 2   0180C01B  div $24, $12, $0    $24 =  (8/0 = FFFFFFFF)
-- 3   AC180004  sw $24, 4($0)       dmem(1) = FFFFFFFF  
-- 4   8DA90000  lw $9,  0($13)      $9 = dmem(1) = FFFFFFFF
-- 5   AC120004  sw $18, 4($0)       dmem(1)= 18
-- 6   AC130004  sw $19, 4($0)       dmem(1)= 19
-- 7   AC09000C  sw $9, 12($0)       dmem(3)= FFFFFFFFF
--*************************************************
-- "lw" will be waiting for $13 for about 16 clocks 
--  for address calculation.
-- 1st "sw" will be waiting for $24 for about 24 clocks
-- the last two "sw"'s will wait until the "lw" has its address
-- then the last two "sw"'s will bypass "lw", count = 2, addbuffmatch = 2
-- then the first "sw" will leave and addbuffmatch = 3 
-- then the first "sw" commits and addbuffmatch = 2
-- Now that the "lw" has no "sw" older in the queue and addbuffmatch = count
-- It gets issued.
-- We can see the CDB tag and CDB valid to recognize the order of appearance on CDB
-- ==================================================================================
-- *******************************************************
-- The expected order of appearance on CDB leaving NOP's
-- ******************************************************
-- first   0   0050601B  div $12, $2, $16
-- second  1   004C681B  div $13, $2, $12
-- third   5   AC120004  sw $18, 4($0)
-- fourth  6   AC130004  sw $19, 4($0)
-- fifth   2   000CC01B  div $24, $0, $12
-- sixth   3   AC180004  sw $24, 4($0)
-- seventh 4   8DA90000  lw $9,  0($13)
-- *****************************************************
