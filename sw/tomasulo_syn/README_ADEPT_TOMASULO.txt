Author: Suvil Singh
This file explains how to use Adept to test the Tomasulo design.

1. Connect the board with your computer.
2. Program it using the generated bit file.
3. Go to RegisterI/O tab.

Registers Used:

REGISTER NUMBER		VALUE TO BE WRITTEN					OPERATION	
---------------------------------------------------------------------------------------------	
	43 						3				RESET TOMASULO and TO select TEST MODE
---------------------------------------------------------------------------------------------
	43						0						TO Select Normal Mode
---------------------------------------------------------------------------------------------
	42						0						  To Select IM
---------------------------------------------------------------------------------------------
	42						0						  To Select DM
---------------------------------------------------------------------------------------------	
	41						0					   STREAMING REGISTER
---------------------------------------------------------------------------------------------	
	40						0						  MEMORY POINTER
---------------------------------------------------------------------------------------------	

*** NOTE: REG-43(bit:0) is for TEST MODE/NORMAL MODE.
*** NOTE: REG-43(bit:1) is for TOMASULO RESET.
*** NOTE: REG-42(bit:0) is for DM/IM.

4. Write "3" to register number 43. This will put the design in TEST mode and RESET Tomasulo code.
5. Write "0" to register number 42.	This will select IM for Read or write operation.
6. Write "0" to register number 40.
7. Go to FileI/O tab. select the instruction stream for which you want to test the design in the upload section. (which has to be written).
8  Make Register Address = 41 and File Start Location =0.
9. Fill in the Length of the file in "Length"(2176 for IM).
10. Press the file transfer button.
11. You can check the contents of Register number 40 by reading it. Its vale should be 40Hex after transfering the data.
12. Write "0" to register number 43. This will put the design in NORMAL mode.
13. Take a breath.
14. Write "3" to register number 43. This will put the design back in test mode so that you can read now.
15. Write "1" to register number 42. This will select DM for Read or write operation.
16. Write "0" to register number 40.
17. Go to FileI/O tab. select the DM out file in the download section.
18  Make Register Address = 41 and File Start Location =0.
19. Fill in the Length of the file in "Length"(640 for DM).
20. Press the file transfer button.
21. You can check the contents of Register number 40 by reading it. Its vale should be 40Hex after transfering the data.
22. Once you have the DM out file compare it with the gold file for that instruction stream provided along with the automated file IO.

Repeat the above procedure for all the instruction streams.


 

