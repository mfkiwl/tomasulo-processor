---
layout: project
title: tomasulo-processor
subtitle: A Tomasulo-based processor system implemented in VHDL on a Nexys3 FPGA.
---

<img src="http://niftyhedgehog.com/tomasulo-processor/images/architecture_snip.jpg">

## Overview
An out-of-order (OoO) processor utilizing the Tomasulo hardware algorithm for dynamic scheduling was implemented in VHDL on a Nexys 3 FPGA. The architecture supported basic MIPS ISA instructions, complete with IFQ, dispatch units, BPB, RAS, FRL, PRF, CFC, functional units, CDB, instruction and data caches, ROB, LSQ, store buffer.

This project was developed in the summer of 2011 with lab partner, Max Chin, for USC's Digital Design Tools & Techniques (EE-645) course, taught by professor Gandhi Puvvada.

## Hardware
This project was implemented on a [Digilent Nexys 3 Spartan-6 FPGA board](http://www.digilentinc.com/Products/Detail.cfm?NavPath=2,400,897&Prod=NEXYS3&CFID=8760039&CFTOKEN=c6463f3d9216e84e-58132DE0-5056-0201-02184BF1EA12A8C4). The Nexys 3 was a digital system development platform featuring: 

* Xilinx Spartan6 XC6LX16-CS324
* 16MB Micron Cellular RAM
* 16MB Micron Parallel PCM
* 16MB Micron Quad-mode SPI PCM
* 10/100 SMSC LAN8710 PHY
* Digilent Adept USB port for power, programming & data transfers
* USB-UART
* Type-A USB host for mouse, keyboard or memory stick
* 8-bit VGA
* 100MHz fixed-frequency oscillator
* 8 slide switches, 5 push buttons, 4-digit 7seg display, 8 LEDs

## Software
For development, the Nexys 3 FPGA was used with Xilinx tools such as ISE, EDK, and Chipscope. 

* architecture
* algorithms
* functionality
* debugging