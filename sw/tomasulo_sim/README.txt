MEGA TESTBENCH
Data - 14 July 2010
Author - Sabyasachi Ghosh
----------------------------------------

Contents of this folder:
1)This README.txt file - explains how to use the mega testbench
2)mega_tb.vhd
3)instruction stream vhd files
4)Expected final contents of DRAM, PRF and CRAT for each of these instruction streams after running for 35us (_gold.mem files)
5)mega_comp.do - simulates your design with the mega_tb and runs it for 35us with each instruction stream. Compares final DRAM contents and architectural register contents with the expected output. Errors are reported in mega_log.txt
6)inst_cache_dpram_r2_sim.vhd

Steps to use the mega testbench:
1) I assume you have a simulatable tomasulo project with you already. This will work with the compiled library as well.
2) Copy everything from this folder to your project folder.
3) Add mega_tb.vhd to your project. Compile.
4) on the modelsim command line, type:
	do mega_comp.do
5)Any errors will be reported in mega_log.txt. 
6)You can now manually simulate your design with those test streams which fail and look for errors.

Cheers!

-----------------
mega_log.txt description
Each stream name which is checked is written to the file. Register and DRAM content errors are reported.

Sample error:

i_fetch_test_stream_jal_jr_factorial_simple.vhd

REGISTER comparison failed for Line number 13
REGISTER comparison failed for Line number 17
DRAM comparison failed for Line number 9
DRAM comparison failed for Line number 19

How to interpret this:
Error is in test stream i_fetch_test_stream_jal_jr_factorial_simple.vhd.
For dram errors, please look at the file <stream name>_dram.mem and <stream name>_dram_gold.mem. These two files would differ on lines 9 and 19 according to the above error report. These files have some initial header for the first 3 lines, so the actual DRAM indices which are differing are 9-4=5 and 19-4=15 (index starting from 0). 

Architectural register values are only compared. So to interpret register errors, you have to look into both CRAT and PRF mem files. First compare the CRAT line number 13 and 17 of the test stream and the golden design. IF they are the same, then your CRAT is fine, but the actual value written in the PRF would differ. CRAT file values give a PRF index between 0-47. To check the corresponding PRF value, go to the PRF file for this stream. The corresponding line number would be indexno+4 (since there is some header in the beginning).