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

	  X"00000020_00BF1019_0080F820_00000020", -- Loc 0C, 08, 04, 00
	  X"10C0000C_0082302A_007F2020_00001820", -- Loc 1C, 18, 14, 10
	  X"10C00002_01CD302A_8C8E0000_8C6D0000", -- Loc 2C, 28, 24, 20
	  X"009F2020_007F1820_AC8D0000_AC6E0000", -- Loc 3C, 38, 34, 30

	  X"08000004_005F1022_10C1FFF6_0082302A", -- Loc 4C, 48, 44, 40
	  X"00BFE019_035FD820_0000D020_00000020", -- Loc 5C, 58, 54, 50
	  X"03DDC82A_8F7E0000_8F5D0000_039AE020", -- Loc 6C, 68, 64, 60
	  X"037FD820_035FD020_1000FFFF_13200001", -- Loc 7C, 78, 74, 70

	  X"00000020_00000020_1000FFF7_137C0001", -- Loc 8C, 88, 84, 80
	  X"01215020_00BF4820_00A01020_00000020", -- Loc 9C, 98, 94, 90
	  X"007F6819_00612020_00A01820_00003020", -- Loc AC, A8, A4, A0
	  X"009F7019_02E0B020_01A06020_8DB70000", -- Loc BC, B8, B4, B0    

	  X"01C06020_10C00002_0316302A_8DD80000", -- Loc CC, C8, C4, C0
	  X"1000FFF7_108A0001_00812020_0300B020", -- Loc DC, D8, D4, D0
	  X"00611820_AD970001_ADB60001_00000020", -- Loc EC, E8, E4, E0
	  X"00000020_1000FFEC_10690001_00612020", -- Loc FC, F8, F4, F0

	  X"00BFE019_035FD820_00BFD019_00000020",  -- Loc 10C, 108, 104, 100
	  X"03DDC82A_8F7E0000_8F5D0000_039AE020",  -- Loc 11C, 118, 114, 110
	  X"037FD820_035FD020_1000FFFF_13200001",  -- Loc 12C, 128, 124, 120
	  X"00000020_00000020_1000FFF7_137C0001",  -- Loc 13C, 138, 134, 130
    
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

-- BUBBLE SORT & SELECTION SORT
--
-- Preconditions on Register file
--   Registers set to their register number
--   ex) $0 = 0, $1 = 1, $2 = 2 ...... $31 = 31 
-- Preconditions on Data Memory
--   None. Any data in the first 5 locations will be sorted by Bubble sort.
--   The next 5 data will be sorted by Selection sort.
--
-- Author: Byung-Yeob Kim, EE560 TA
-- Modified: Aug-01-2008
-- University of Southern California
--
--000 00000020 add $0, $0, $0     -- nop *** INITIALIZATION FOR BUBBLE SORT ***
--004 0080F820 add $31, $4, $0    -- $31 = 4 
--008 00BF1019 mul $2, $5, $31    -- ak = 4 * num_of_items
--00c 00000020 add $0, $0, $0     -- noop
--
--010 00001820 add $3, $0, $0     -- ai = 0 *** BUBBLE SORT STARTS ***
--014 007F2020 add $4, $3, $31    -- aj = ai + 4
--018 0082302A slt $6, $4, $2     -- (aj < ak) ?
--01c 10C0000C beq $6, $0, 12     -- if no, program finishes. goto chcker
--
--020 8C6D0000 lw  $13, 0($3)     -- mi = M(ai)       (LABEL: LOAD)
--024 8C8E0000 lw  $14, 0($4)     -- mj = M(aj)
--028 01CD302A slt $6, $14, $13   -- (mj < mi) ?
--02c 10C00002 beq $6, $0, 2      -- if no, skip swap
-- 
--030 AC6E0000 sw  $14, 0($3)     -- M(ai) = mj // swap
--034 AC8D0000 sw  $13, 0($4)     -- M(aj) = mi // swap
--038 007F1820 add $3, $3, $31    -- ai = ai + 4      (LABEL: SKIP SWAP)
--03c 009F2020 add $4, $4, $31    -- aj = aj + 4
--
--  
--040 0082302A slt $6, $4, $2     -- (aj < ak) ?
--044 10C1FFF6 beq $6, $1, -10    -- if yes, goto LOAD
--048 005F1022 sub $2, $2, $31    -- ak = ak - 4
--04c 08000004 jmp 4              -- goto BEGIN
-- 
--050 00000020 add $0,  $0,  $0    -- nop *** CHECKER FOR FIRST 5 ITEMS *** 
--054 0000D020 add $26, $0,  $0    -- addr1 = 0
--058 035FD820 add $27, $26, $31   -- addr2 = addr1 + 4
--05c 00BFE019 mul $28, $5, $31    -- addr3 = num_of_items * 4
-- 
--060 039AE020 add $28, $28, $26   -- addr3 = addr3 + addr1
--064 8F5D0000 lw  $29, 0 ($26)    -- maddr1 = M(addr1)
--068 8F7E0000 lw  $30, 0 ($27)    -- maddr2 = M(addr2)
--06c 03DDC82A slt $25, $30, $29   -- (maddr2 < maddr1) ?
--
--070 13200001 beq $25, $0,  1     -- if no, proceed to the next data
--074 1000FFFF beq $0,  $0, -1     -- else, You're stuck here
--078 035FD020 add $26, $26, $31   -- addr1 = addr1 + 4
--07c 037FD820 add $27, $27, $31   -- addr2 = addr2 + 4
--
--
--080 137C0001 beq $27, $28, 1     -- if all tested, proceed to the next program
--084 1000FFF7 beq $0,  $0, -9     -- else test next data 
--088 00000020 add $0, $0, $0      -- noop
--08c 00000020 add $0, $0, $0      -- noop
--
--090 00000020 add $0, $0, $0    -- nop *** INITIALIZATION FOR SELECTION SORT ***
--094 00A01020 add $2, $5, $0    -- set min = 5
--098 00BF4820 add $9, $5, $31   -- $9  = 9 
--09c 01215020 add $10, $9, $1   -- $10 = 10
--
--0A0 00003020 add $6, $0, $0    -- slt_result = 0
--0A4 00A01820 add $3, $5, $0    -- i = 5
--0A8 00612020 add $4, $3, $1    -- j = i+1   *** SELECTION SORT STARTS HERE ***
--0Ac 007F6819 mul $13, $3, $31  -- ai = i*4   
--
--0B0 8DB70000 lw  $23, 0($13)   -- mi = M(ai)
--0B4 01A06020 add $12, $13, $0  -- amin = ai
--0B8 02E0B020 add $22, $23, $0  -- mmin = mi
--0Bc 009F7019 mul $14, $4, $31  -- aj  = j*4
--
--
--0C0 8DD80000 lw  $24, 0($14)   -- mj = M(aj)
--0C4 0316302A slt $6, $24, $22  -- (mj < mmin)
--0C8 10C00002 beq $6, $0, 2     -- if(no)
--0Cc 01C06020 add $12, $14, $0  -- amin = aj
--
--0D0 0300B020 add $22, $24, $0  -- mmin = mj
--0D4 00812020 add $4, $4, $1    -- j++
--0D8 108A0001 beq $4, $10, 1    -- (j = 10)
--0Dc 1000FFF7 beq $0, $0, -9    -- if(no)
--
--0E0 00000020 add $0, $0, $0    -- nop
--0E4 ADB60001 sw  $22, 0 ($13)  -- M(ai) = mmin // swap
--0E8 AD970001 sw  $23, 0 ($12)  -- M(amin) = mi // swap
--0Ec 00611820 add $3, $3, $1    -- i++
--
--0F0 00612020 add $4, $3, $1    -- j = i+1
--0F4 10690001 beq $3, $9, 1     -- (i==9)
--0F8 1000FFEC beq $0, $0, -20   -- if(no)
--0Fc 00000020 add $0,  $0,  $0  -- nop 
--
--
--100 00000020 add $0,  $0,  $0    -- *** CHECKER FOR THE NEXT 5 ITEMS *** 
--104 00BFD019 mul $26, $5,  $31   -- addr1 = num_of_items * 4
--108 035FD820 add $27, $26, $31   -- addr2 = addr1 + 4
--10c 00BFE019 mul $28, $5, $31    -- addr3 = num_of_items * 4
-- 
--110 039AE020 add $28, $28, $26   -- addr3 = addr3 + addr1
--114 8F5D0000 lw  $29, 0 ($26)    -- maddr1 = M(addr1)
--118 8F7E0000 lw  $30, 0 ($27)    -- maddr2 = M(addr2)
--06c 03DDC82A slt $25, $30, $29   -- (maddr2 < maddr1) ? -- corrected
--
--070 13200001 beq $25, $0,  1     -- if no, proceed to the next data -- corrected
--124 1000FFFF beq $0,  $0, -1     -- else, You're stuck here
--128 035FD020 add $26, $26, $31   -- addr1 = addr1 + 4
--12c 037FD820 add $27, $27, $31   -- addr2 = addr2 + 4
-- 
--130 137C0001 beq $27, $28, 1     -- if all tested, proceed to the next program
--134 1000FFF7 beq $0,  $0, -9     -- else test next data 
--138 00000020 add $0, $0, $0      -- noop
--13c 00000020 add $0, $0, $0      -- noop
--
--
--REG FILE USED BY BUBBLE SORT
--Initilaly, the content of a register is assumed to be same as its register number.
--
--$0   ----> 0        constant
--$1   ----> 1        constant
--$2   ----> ak       address of k  
--$3   ----> ai       address of i
--$4   ----> aj       address of j
--$5   ----> 5        num_of_items (items at location 0~4 will be sorted)
--$6   ----> result_of_slt 
--$13  ----> mi       M(ai)
--$14  ----> mj       M(aj)
--$25~$30 -> RESERVED for the checker
--$31  ----> 4        conatant for calculating word address
--
--REG FILE USED BY SELECTION SORT
--
--$0   ----> 0       constant
--$1   ----> 1       constant
--$2   ----> min     index of the minimum value
--$3   ----> i       index i
--$4   ----> j       index j
--$5   ----> 5       num_of_items (items at location 5~9 will be sorted)     
--$6   ----> result of slt
--$9   ----> 9       constant
--$10  ----> 10      constant
--$12  ----> amin    address of min
--$13  ----> ai      address of i 
--$14  ----> aj      address of j 
--$15~$21 -> don't care
--$22  ----> mmin    M(amin)
--$23  ----> mi      M(ai)
--$24  ----> mj      M(aj)
--$25~$30 -> RESERVED for checker
--$31  ----> 4       for calculating word address 
--    
--REG FILE USED BY CHECKER
--
--$26  ----> addr1    starting point  
--$27  ----> addr2    ending point
--$28  ----> addr3    bound
--$29  ----> maddr1   M(addr1)
--$30  ----> maddr2   M(addr2)
--
