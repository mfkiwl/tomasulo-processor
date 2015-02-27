Jul 08, 2011
Sabyasachi Ghosh (560 TA in 2009)
-------------------------------------------------
How to use automated file IO for Tomasulo Project
-------------------------------------------------

History
--------
For the Tomasulo Project in EE560, we have different instruction streams with which one can test different aspects of the tomasulo CPU. For example, we have instruction streams testing the divider, or selective flushing, memory disambiguation, or selective flushing and  memory disambiguation at the same time. 

In 2008, one had to compile and produce the bit file for the CPU each time a new instruction stream needed to be tested. This was obviously very time-consuming and caused several frustrating hours for TAs and students alike.

In 2009, Prasanjeet and Prof Puvvada made a drastic improvement to this procedure by adding File I/O to the Tomasulo project. Now, one could generate the bit file just once, and transfer the instruction streams directly from the PC to the instruction cache on the board, and read back the values of the data cache after execution.

In 2010, we made a few improvements to the simulation project's testing procedure by introducing signalspy (for testing individual components) and mega-testbench (for testing all instruction streams at one go).

In 2011, we decided to do something similar to megatestbench for the implementation project, and automate the file IO process. So now, all instruction streams can be tested at one go instead of the student having to manually transfer the files for each instruction stream. We do this using an API provided by Digilent using which custom programs can be written in C which can interact with the board. So we do not use Adept Tool's file IO component; however, we could still use that instead of this newer automation program and manually do the testing. I talk about that in README_code. 

Relevant Files
---------------

fileIO.exe - this is the automation program written in C

i_fetch_test_stream*.txt - These files contain different instruction streams.

golden_outfile*.txt - These files contain the expected outputs in the Data Memory

infile_DM.txt - the default contents of data memory

_file_list.txt - this file contains a list of instruction streams to be tested. Each row denotes an instruction stream. It has the following format for each row:

<instruction stream file> <infile_DM.txt> <output DM file name> <golden DM file name>

Each column is separated by whitespace. If a row is not in this format, it is ignored by fileIO.exe. fileIO.exe basically goes through the _file_list.txt file and runs each instruction stream listed there, one by one, and compares all the output files generated to the golden output files.

Usage
---------

First, we need to let the program know which device to use. This only needs to be done once, or whenever you have a new board or PC. Here are the steps:

0. Connect your board to the PC
1. Run cmd.exe
2. Run "fileIO -x" on the command prompt. You need to be the directory where fileIO.exe is present.
3. Select your device, give it an alias and save. 

Now, make sure that your board has been programmed with the Tomasulo bit file. 

Next, run "fileIO.exe" on the command prompt. Make sure that your current directory contains fileIO.exe, _file_list.txt, and all infiles and golden outfiles. It will print out messages saying whether each comparison succeeded or failed.

Congratulations! You now know how to test Tomasulo Implementation using File I/O automation.
