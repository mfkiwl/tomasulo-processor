------------------------------------------------------------------------------
--  File name: top_cpu.vhd 
--  Function : Top file for the Tomasulo CPU project with file i/o
-- Modified by : Prasanjeet Das
-- Date        : 7/20/09, 7/24/09, 7/25/09
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;




library UNISIM;
use UNISIM.VComponents.all; -- Xilinx primitive BUFGP


entity top_cpu is
port    (
         CLK_PORT                                                    : in  std_logic;
			sw0, sw1, sw2, sw3, sw4, sw5, sw6, sw7                      : in std_logic; --changed by PRASANJEET
         btn3                                                        : in std_logic; 
         btn2                                                        : in std_logic; 
         btn1, btn0                                                  : in std_logic; 
         St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_we_bar, Mt_St_oe_bar : out std_logic;
         LD7, LD6, LD5, LD4, LD3, LD2, LD1, LD0                      : out std_logic; 
         ca, cb, cc, cd, ce, cf, cg, dp                              : out std_logic;
         AN0, AN1, AN2, AN3                                          : out std_logic;
			------------------------------------------------------------------------
	      --   Epp-like bus signals (ports to connect to the Cypress USB intrerface)
         EppAstb: in std_logic;        -- Address strobe   --changed by PRASANJEET
         EppDstb: in std_logic;        -- Data strobe      --changed by PRASANJEET
         EppWr  : in std_logic;        -- Port write signal  --changed by PRASANJEET
         EppDB  : inout std_logic_vector(7 downto 0); -- port data bus  --changed by PRASANJEET
         EppWait: out std_logic;        -- Port wait signal   --changed by PRASANJEET
         ------------------------------------------------------------------------
         -- user extended signals 
         Led  : in std_logic_vector(7 downto 0);   -- 0x01     8 virtual LEDs on the PC I/O Ex GUI  --changed by PRASANJEET
         LBar : in std_logic_vector(23 downto 0);  -- 0x02..4  24 lights on the PC I/O Ex GUI light bar  --changed by PRASANJEET
         Sw   : out std_logic_vector(15 downto 0);  -- 0x05..6  16 switches, bottom row on the PC I/O Ex GUI  --changed by PRASANJEET
         dwOut: out std_logic_vector(31 downto 0); -- 0x09..b  32 Bits user output  --changed by PRASANJEET
         dwIn : in std_logic_vector(31 downto 0)   -- 0x0d..10 32 Bits user input  --changed by PRASANJEET
        );
end  top_cpu ;
------------------------------------------------------------------------------
architecture top_cpu_arc of top_cpu   is

    SIGNAL clock_half               : std_logic ;
    signal Resetb                    : std_logic; 
    signal BCLK                     : std_logic; 
    signal BCLK_TEMP                : std_logic; 

-- signals to go into the logic under test
    signal clk_top, resetb_top      : std_logic;
    

-- component declarations




component tomasulo_top 
port (
      Reset                 : in std_logic;
      --digi_address          : in std_logic_vector(5 downto 0); -- input ID for the register we want to see
      --digi_data             : out std_logic_vector(31 downto 0); -- output data given by the register
      Clk                   : in std_logic;
		--modified by Prasanjeet
		-- signals corresponding to Instruction memory
		fio_icache_addr_IM        : in  std_logic_vector(5 downto 0); --changed by PRASANJEET
      fio_icache_data_in_IM     : in  std_logic_vector(127 downto 0); --changed by PRASANJEET
      fio_icache_wea_IM         : in  std_logic; --changed by PRASANJEET 
      fio_icache_data_out_IM    : out std_logic_vector(127 downto 0); --changed by PRASANJEET
	   fio_icache_ena_IM		     : in  std_logic; -- changed by PRASANJEET

      fio_dmem_addr_DM          : in std_logic_vector(5 downto 0); --changed by PRASANJEET
      fio_dmem_data_out_DM      : out std_logic_vector(31 downto 0); --changed by PRASANJEET	
      
      fio_dmem_data_in_DM       : in std_logic_vector(31 downto 0); --changed by PRASANJEET
      fio_dmem_wea_DM    		  : in std_logic; --changed by PRASANJEET
		
		Test_mode                 : in std_logic; -- for using the test mode 
      
      walking_led_start         : out std_logic		
		-- end modified by Prasanjeet
     );


end  component ;

-- debouncer
component ee560_debounce is
generic  (N_dc:                 positive := 23);
port     (CLK, RESETB_DEBOUNCE   :in  std_logic; -- CLK = 50 MHz
                 PB            :in  std_logic; -- push button
                 DPB, SCEN, MCEN, CCEN :out std_logic           );
end  component ee560_debounce ;

--bufgp for clock

   component BUFGP
         port (I: in std_logic; O: out std_logic);
   end component;
	
	component BUFG
         port (I: in std_logic; O: out std_logic);
   end component;
	
	--signals for file i/o
	signal Addr_Mem_IM, Addr_Mem_DM, Addr_Mem  :  std_logic_vector(5 downto 0);   -- address going to user memory -- here it is 4 bits
   signal WE_Mem_IM, WE_Mem_DM: std_logic; -- Write Enable, Read Enable control signals to user memory
   signal Data_to_Mem_IM, Data_to_Mem: std_logic_vector(127 downto 0); -- data to be written to memory
   signal Data_to_Mem_DM : std_logic_vector(31 downto 0);
   signal Data_from_Mem_IM, Data_from_Mem: std_logic_vector(127 downto 0); -- data to be read from memory
   signal Data_from_Mem_DM : std_logic_vector(31 downto 0);
	
	signal test_in: std_logic;
	
	------------

  signal regEppAdr: std_logic_vector (7 downto 0); -- Epp address register 
  signal regVer: std_logic_vector(7 downto 0); --  0x00    I/O returns the complement of written value -- for I/O Ex Tab
  signal busEppInternal: std_logic_vector(7 downto 0);  -- internal bus (before tristate)
	
	
	
	
	
	
	
	
	
	
	-- added by Sabya --
	signal Mem_Select_Reg: 	std_logic_vector (7 downto 0);	-- 0x2A; we get Sel_IM_Bar_Slash_DM from this
	signal Control_Reg:		std_logic_vector (7 downto 0);	-- 0x2B; We get test mode from this. Not needed in the current design.
  
  
  
  
  
  
  
  
  
  
  
  
  
  -- Type declaration
  type state_type is (IDLE,                -- idle state(1)
                      A_RD_FINISH,         -- finish reading from address register (2)
                      A_WR_START,          -- start writing to address register(3) 
                      A_WR_FINISH,         -- finish writing from address register (4)
                      
							 OTHER_RD_FINISH,     -- finish reading from other than pointer and data memory (5)
							 OTHER_WR_FINISH,     -- finish writing to other than pointer and data memory   (6)
							 OTHER_WR_START,      -- start writing to other than pointer and data memory    (7)
							 
					       PNTR_RD_START,       -- start reading the memory pointer (8)
                      PNTR_RD_FINISH,      -- finish reading the memory pointer(9)
                      PNTR_WR_START,       -- start writing the memory pointer(10)
                      PNTR_WR_FINISH,      -- finish writing the memory pointer(11)
							 
                      M_RD_START_1_8,     -- start reading data memory (12)
                      M_RD_FINISH_1_8,    -- finish reading data memory(13)
							 
					       M_RD_START_9_10,    -- deals with carriage return and line feed (14)
                      M_RD_FINISH_9_10,   -- deals with carriage return and line feed (15)
							 
                      M_WR_START_1_8,     -- start writing data memory (16)
                      M_WR_FINISH_1_8,    -- finish writing data memory(17)
                       
                      M_WR_START_9_10,    	-- deals with carriage return and line feed  (18)
                      M_WR_FINISH_9_10,   	-- deals with carriage return and line feed (19)
							 
                      INC_NIB_COUNT,       	-- increment the nibble counter (20)
                      INC_MEM_PNTR			-- increment the mem_pointer (21)
					  );       

-- Intermediate signal declarations 
signal current_state  : state_type;



--intermediate signals of the state machine
signal EN_A_RD, EN_M_RD, EN_A_WR, EN_M_WR, EN_PNTR_RD, EN_PNTR_WR, EN_OTHER_RD: std_logic; -- all the read and write enable signals
signal EN_REG_WR, EN_REG_RD: std_logic; -- read and write signals for register file
signal ASTB_S, DSTB_S, ASTB_SS, DSTB_SS : std_logic; -- signals used for double synchronizing address and data strobe
signal D_int1, D_int2, D_int3: std_logic_vector(7 downto 0);  -- signals used for registering the Eppdata
signal A_int1, A_int2, A_int3: std_logic_vector(7 downto 0); -- signals used for registering the EppAddress
signal wait_Epp: std_logic; -- internal signal used for EppWait;
signal pointer: std_logic_vector(7 downto 0); -- pointer to memory
signal i: std_logic_vector(1 downto 0); --internal counter
--signal clk, resetb: std_logic; -- clk and Resetb signals
signal nib_count: std_logic_vector(5 downto 0); -- to count the nibbles
signal nib_on_file: std_logic_vector(7 downto 0); -- show the nibbles on the file
signal Sel_IM_Bar_Slash_DM: std_logic; --  A Flip-Flop Resetb or set by SW0 to select between IM/DM; --  FF output = '0' => IM, '1' => DM
-- *****************************************************************************************
-- constant declarations
-- 40, 41 for instruction memory
-- *****************************************************************************************
constant addr_mem_pointer: std_logic_vector(7 downto 0) := X"28";  --40 dec - 28 hex
constant addr_memory: std_logic_vector(7 downto 0) := X"29"; --41 dec - 29 hex






-- added by sabya



constant addr_Mem_Select_Reg: std_logic_vector(7 downto 0) := X"2A";
constant addr_Control_Reg: std_logic_vector(7 downto 0) := X"2B";
--******************************************************************************************

-- intermediate signals for data conversion
signal BINARY, binary_in : std_logic_vector(3 downto 0); -- - BINARY for  FPGA ==> File and binary_in  for File  ==> FPGA
signal ASCII, ascii_out: std_logic_vector(7 downto 0);   -- ASCII for ,File  ==> FPGA and  ascii_out   for FPGA ==> File 
signal extended_zero : std_logic_vector(95 downto 0);

-- signals used for the array of registers to store the nibbles
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
subtype reg_mem is std_logic_vector(3 downto 0);  --register array declaration
type reg_type is array (0 to 31) of reg_mem;
signal reg_array : reg_type;     
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

signal divclk: std_logic_vector(1 downto 0); -- the divided clock
--***************************************************************

signal reset_fileio, reset_tomasulo: std_logic;
--signal r_sw2, r_sw3: std_logic; -- Resetb signals
--++++++++++++++++++++++++++++++++++++++++++++
signal walking_led: std_logic_vector(7 downto 0); -- walking led counter.
signal walking_led_en: std_logic;
signal walking_led_clk: std_logic_vector(22 downto 0);
signal w_led: std_logic_vector(2 downto 0); -- encoded walking led pattern

--++++++++++++++++++++++++++++++++++++++++++++++++
-- signals from debouncers
signal db_btn0,db_btn1: std_logic;
--++++++++++++++++++++++++++++++++++++++++++++++++++

begin

  
  cpu_2_inst : tomasulo_top
  port map (
            Reset            => reset_tomasulo,
            Clk               => clk_top,
				fio_icache_addr_IM  =>  Addr_Mem_IM, --changed by PRASANJEET
            fio_icache_data_in_IM  => Data_to_Mem_IM, --changed by PRASANJEET
            fio_icache_wea_IM      => WE_Mem_IM, --changed by PRASANJEET 
            fio_icache_data_out_IM   =>  Data_from_Mem_IM,--changed by PRASANJEET
	         fio_icache_ena_IM		    => '1', -- changed by PRASANJEET

            fio_dmem_addr_DM         =>  Addr_Mem_DM,--changed by PRASANJEET
            fio_dmem_data_out_DM     =>  Data_from_Mem_DM, --changed by PRASANJEET	
            fio_dmem_data_in_DM      =>  Data_to_Mem_DM, --changed by PRASANJEET
            fio_dmem_wea_DM          =>  WE_Mem_DM, --changed by PRASANJEET				
		
		      Test_mode                => test_in, -- changed by PRASANJEET		
            walking_led_start        => walking_led_en --changed by PRASANJEET
          );

  BUF_GP_1:   BUFGP   port map (I => CLK_PORT, O => BCLK_TEMP);
  
  ------------
	--concurrent assignments
	
     -- send address and data to both the memories, it's the control signal WE which will determine which memory to write	
	  Data_to_mem_IM <= Data_to_mem; 
	  Data_to_mem_DM <= Data_to_mem(127 downto 96); 
     Addr_mem_IM <= Addr_mem; 
	  Addr_mem_DM <= Addr_mem; 
	  
	  Data_from_mem <= Data_from_mem_IM when Sel_IM_Bar_Slash_DM = '0' else Data_from_mem_DM&extended_zero; --Data to be read from memory is sent to the file on the control of swith sw0
	  
	  WE_Mem_IM <= EN_M_WR when Sel_IM_Bar_Slash_DM = '0' else '0'; -- the Sel_IM_Bar_Slash_DM is  controlled by sw0
	  WE_Mem_DM <= EN_M_WR when Sel_IM_Bar_Slash_DM = '1' else '0'; 
				
     extended_zero <= (others =>'0');
     						  
     ------------------------------------------------------------------------------

  
  
  --Clock Divider derives slower clocks from the 50 MHz clock on s2 board
	CLOCK_DIVIDER1: process (BCLK_TEMP, resetb_top)
						 begin
							 if (resetb_top = '0') then
								 divclk <= (others => '0');
							 elsif (BCLK_TEMP'event and BCLK_TEMP = '1') then
								 divclk <= divclk + '1';
							 end if;
						 end process CLOCK_DIVIDER1;

						 --da  cheng july17 2011
  clock_half <= divclk(1); -- this is 25MHz clock
  BUF_G_3:   BUFG   port map (I => clock_half, O => BCLK);
  
  ---------------------------------------------------------------------
  
  walking_led_pro: process(clk_top, resetb_top)
               begin
					  if(resetb_top = '0')then
					     walking_led_clk <= (others =>'0');
					  elsif(clk_top'event and clk_top = '1')then
                     if(walking_led_en = '1')then
                        walking_led_clk <= walking_led_clk + '1';
                     end if;
                 end if;							
					end process walking_led_pro;
					
--	---------------------------------------------------------				
   --w_led <= walking_led_clk(20 downto 18);
	--Da Cheng modified at July 17  2011
	w_led <= walking_led_clk(22 downto 20);
--	-- decoder to produce one hot signals
	walking_led <= "00000001" when w_led = "000" else
	               "00000010" when w_led = "001" else
						"00000100" when w_led = "010" else
						"00001000" when w_led = "011" else
						"00010000" when w_led = "100" else
						"00100000" when w_led = "101" else
						"01000000" when w_led = "110" else
						"10000000" when w_led = "111" else
						"11111111";
--	----------------------------------------------------------
--	
  ---------------------------
  --concurrent assignments
  
  Resetb <= btn3;--this is active high system Resetb
  --added by PRASANJEET
  -------------------------------------------------------
  resetb_top <= not(btn3); --the Resetb to the debouncer (this is system reset)
  -------------------------------------------------------
  clk_top <= BCLK;
   
  
  
  --process to store the nibbles into the register file 
    write_reg: process(clk_top)
     begin
         if(clk_top'event and clk_top = '1')then
	 	   if(EN_REG_WR = '1')then
           reg_array(CONV_INTEGER(UNSIGNED(nib_count(4 downto 0)))) <= binary_in;
	   end if;
         end if;
    end process write_reg;
   -------------------------------------------------------------------------------
  
  

  -- disabling the seven segment display 
  ca      <= '1' ;
  cb      <= '1' ;
  cc      <= '1' ;
  cd      <= '1' ;
  ce      <= '1' ;
  cf      <= '1' ;
  cg      <= '1' ;
  dp      <= sw3 and sw4 and sw5 and sw6 and sw7 and btn0 and btn2 ; -- just to remove the synthesis warnings let all the unused switches and buttons drive something
  AN0     <= '1' ; 
  AN1     <= '1' ; 
  AN2     <= '1' ; 
  AN3     <= '1' ; 

  -- disabling the flash / memory 
  St_ce_bar    <= '1';  
  Mt_ce_bar    <= '1';  
  St_rp_bar    <= '1';    
  Mt_St_we_bar <= '1';  
  Mt_St_oe_bar <= '1'; 

    --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	 LD6 <= walking_led(6);
	 LD7 <= walking_led(7);-- just to check for wait signal 	 
	 LD5 <= walking_led(5);        LD4 <= walking_led(4);
    LD3 <= walking_led(3);    LD2 <= walking_led(2) ;    LD1 <= walking_led(1);    LD0 <= walking_led(0);
--	 --****************************************************************************************************
	
	 
	 --++++++++++++++++++++++++++++++++
   Addr_mem <= pointer(5 downto 0); -- 6 bit address
   --++++++++++++++++++++++++++++++++
	
-- Epp signals
   -- Port signals
   EppWait <= wait_Epp;
	
	
   EppDB <= busEppInternal when (EppWr = '1') else "ZZZZZZZZ";

   busEppInternal <= 
       regEppAdr when (EN_A_RD = '1') else
	    nib_on_file when (EN_M_RD = '1')else --this is the nibble being sent to the file
	    pointer when (EN_PNTR_RD = '1')else
		
		
		
		
		
		
		
		
		
		--@Sabya:- add Mem_Select_Reg and Control_Reg here
		Mem_Select_Reg when (EN_OTHER_RD = '1') and (regEppAdr = addr_Mem_Select_Reg) else
		Control_Reg when (EN_OTHER_RD = '1') and (regEppAdr = addr_Control_Reg) else
		
		
		
		
	    regVer when (EN_OTHER_RD = '1') else  --later on to be expanded and qualified with address (regEppAdr = x00)
       Led when (regEppAdr = x"01") else
       LBar(7 downto 0) when (regEppAdr = x"02") else
       LBar(15 downto 8) when (regEppAdr = x"03") else
       LBar(23 downto 16) when (regEppAdr = x"04") else
       dwIn(7 downto 0) when (regEppAdr = x"0d") else
       dwIn(15 downto 8) when (regEppAdr = x"0e") else
       dwIn(23 downto 16) when (regEppAdr = x"0f") else
       dwIn(31 downto 24) ;
	   
	
	
	   --output function logic
	   EN_A_RD    <= '1' when (current_state = A_RD_FINISH) else '0';
		EN_OTHER_RD   <= '1' when (current_state = OTHER_RD_FINISH) else '0';
		EN_REG_RD  <= '1'; --always read the register file
		EN_REG_WR  <= '1' when (current_state = M_WR_START_1_8 or current_state = M_WR_FINISH_1_8) else '0';
	   EN_M_RD   <= '1' when (current_state = M_RD_START_1_8 or current_state = M_RD_FINISH_1_8 or current_state = M_RD_START_9_10 or current_state = M_RD_FINISH_9_10) else '0';
	   EN_PNTR_RD <= '1' when (current_state = PNTR_RD_START or current_state = PNTR_RD_FINISH) else '0';
	   EN_A_WR    <= '1' when (current_state = A_WR_START or current_state = A_WR_FINISH) else '0';
	   EN_M_WR   <= '1' when (current_state = M_WR_START_9_10 or current_state = M_WR_FINISH_9_10) else '0';
	   EN_PNTR_WR <= '1' when (current_state = PNTR_WR_START or current_state = PNTR_WR_FINISH) else '0';
	   
	   							  
	   wait_Epp <= '1' when (current_state = A_WR_FINISH or current_state = A_RD_FINISH or current_state = M_WR_FINISH_9_10 or current_state = M_RD_FINISH_9_10
		                      or current_state = PNTR_WR_FINISH or current_state = PNTR_RD_FINISH or current_state = OTHER_WR_FINISH or current_state = OTHER_RD_FINISH
									 or current_state = M_WR_FINISH_1_8 or current_state = M_RD_FINISH_1_8 or current_state = INC_NIB_COUNT or current_state = INC_MEM_PNTR) 
						else '0';
									
		nib_on_file <=  X"0D" when ((nib_count = "001000" and Sel_IM_Bar_Slash_DM = '1') or (nib_count = "100000" and Sel_IM_Bar_Slash_DM = '0') )else -- carriage return --0D
                      X"0A" when ((nib_count = "001001" and Sel_IM_Bar_Slash_DM = '1') or (nib_count = "100001" and Sel_IM_Bar_Slash_DM = '0') )else  --line feed --0A
		                ascii_out;                            -- the nibble being read from memory
		--***********************************************************
       ascii_out <= X"30" when (BINARY = "0000")  else  --hex 0
                    X"31" when (BINARY = "0001")  else  --hex 1
                    X"32" when (BINARY = "0010")  else  --hex 2
                    X"33" when (BINARY = "0011")  else  --hex 3
                    X"34" when (BINARY = "0100")  else  --hex 4
                    X"35" when (BINARY = "0101")  else  --hex 5
                    X"36" when (BINARY = "0110")  else  --hex 6
                    X"37" when (BINARY = "0111")  else  --hex 7
                    X"38" when (BINARY = "1000")  else  --hex 8
                    X"39" when (BINARY = "1001")  else  --hex 9
                    X"41" when (BINARY = "1010")  else  --hex A
                    X"42" when (BINARY = "1011")  else  --hex B
                    X"43" when (BINARY = "1100")  else  --hex C
                    X"44" when (BINARY = "1101")  else  --hex D
                    X"45" when (BINARY = "1110")  else  --hex E
                    X"46" when (BINARY = "1111")  else  --hex F
						  X"37";
             

      binary_in <=  "0000" when (ASCII = X"30") else
                    "0001" when (ASCII = X"31") else
                    "0010" when (ASCII = X"32") else
                    "0011" when (ASCII = X"33") else
                    "0100" when (ASCII = X"34") else
                    "0101" when (ASCII = X"35") else
                    "0110" when (ASCII = X"36") else
                    "0111" when (ASCII = X"37") else
                    "1000" when (ASCII = X"38") else
                    "1001" when (ASCII = X"39") else
                    "1010" when (ASCII = X"41") else
                    "1011" when (ASCII = X"42") else
                    "1100" when (ASCII = X"43") else
                    "1101" when (ASCII = X"44") else
                    "1110" when (ASCII = X"45") else
                    "1111" when (ASCII = X"46") else
						  "0110";
--************************************************************	
	
	   BINARY <= Data_from_mem(3 downto 0)   when (nib_count = "011111")else
                Data_from_mem(7 downto 4)   when (nib_count = "011110")else
                Data_from_mem(11 downto 8)  when (nib_count = "011101")else
					 Data_from_mem(15 downto 12) when (nib_count = "011100")else
					 Data_from_mem(19 downto 16) when (nib_count = "011011")else
					 Data_from_mem(23 downto 20) when (nib_count = "011010")else
					 Data_from_mem(27 downto 24) when (nib_count = "011001")else
					 Data_from_mem(31 downto 28) when (nib_count = "011000")else
           		 Data_from_mem(35 downto 32) when (nib_count = "010111")else
                Data_from_mem(39 downto 36) when (nib_count = "010110")else
                Data_from_mem(43 downto 40) when (nib_count = "010101")else	
                Data_from_mem(47 downto 44) when (nib_count = "010100")else	
                Data_from_mem(51 downto 48) when (nib_count = "010011")else
                Data_from_mem(55 downto 52) when (nib_count = "010010")else	
                Data_from_mem(59 downto 56) when (nib_count = "010001")else
                Data_from_mem(63 downto 60) when (nib_count = "010000")else
                Data_from_mem(67 downto 64) when (nib_count = "001111")else
					 Data_from_mem(71 downto 68) when (nib_count = "001110")else
					 Data_from_mem(75 downto 72) when (nib_count = "001101")else
					 Data_from_mem(79 downto 76) when (nib_count = "001100")else
					 Data_from_mem(83 downto 80) when (nib_count = "001011")else
					 Data_from_mem(87 downto 84) when (nib_count = "001010")else
					 Data_from_mem(91 downto 88) when (nib_count = "001001")else
					 Data_from_mem(95 downto 92) when (nib_count = "001000")else
					 Data_from_mem(99 downto 96) when (nib_count = "000111")else
					 Data_from_mem(103 downto 100) when (nib_count = "000110")else
					 Data_from_mem(107 downto 104) when (nib_count = "000101")else
					 Data_from_mem(111 downto 108) when (nib_count = "000100")else
					 Data_from_mem(115 downto 112) when (nib_count = "000011")else
					 Data_from_mem(119 downto 116) when (nib_count = "000010")else
					 Data_from_mem(123 downto 120) when (nib_count = "000001")else
					 Data_from_mem(127 downto 124) when (nib_count = "000000")else
					 "1010";
	 -- notice that we start with most significant nibble and end with the least significant nibble
	 
	 --clocked process with asynchronous active low Resetb for double synchronization
	double_sync: process (clk_top, reset_fileio) --double synchronizing to safeguard against metastability
	begin
	   if (reset_fileio = '0') then
	     ASTB_S  <= '1';
		  DSTB_S  <= '1';
		  ASTB_SS <= '1';
		  DSTB_SS <= '1';
	   elsif (clk_top'event and clk_top = '1') then
	     ASTB_S  <= EppAstb;
	     ASTB_SS <= ASTB_S;
		  DSTB_S  <= EppDstb;
		  DSTB_SS <= DSTB_S;
	   end if; 
	end process double_sync;
	
	-- clocked process with asynchronous active low Resetb for combined CU and DPU
	
	CU_DPU: process (clk_top, reset_fileio)
	begin

	  if (reset_fileio = '0') then
	    current_state <= IDLE;
	    i <= (others => 'X');    
	    pointer <= (others => '0'); 
       nib_count <= (others=> '0');		 
       D_int1 <= (others => 'X');
		 D_int2 <= (others => 'X');
		 D_int3 <= (others => 'X');
		 A_int1 <= (others => 'X');
		 A_int2 <= (others => 'X');
		 A_int3 <= (others => 'X');
		 ASCII <= (others =>'X');
       regver <=(others =>'X');
		
		
		
		
		
		--added by sabya
		Mem_Select_Reg <= (others =>'X');
		Control_Reg <= (others =>'X');
       regEppAdr <= (others =>'X');		 
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	   
	  elsif (clk_top'event and clk_top = '1') then

	    case (current_state) is

	      when IDLE =>   --(1)
				
            -- CU state transitions
			   if(ASTB_SS = '0')then   -- if adress strobe asserted and intent to write 
				  if(EppWr = '0')then
				    current_state <= A_WR_START;
				  else
                current_state <= A_RD_FINISH;
              end if;					
			   elsif(DSTB_SS = '0')then  -- if data strobe asserted and intent to write
              if(EppWr = '0')then
				    if(regEppAdr = addr_memory)then
					  if(((nib_count = "001001" and Sel_IM_Bar_Slash_DM = '1')or (nib_count = "100001" and Sel_IM_Bar_Slash_DM = '0')) or ((nib_count = "001000" and Sel_IM_Bar_Slash_DM = '1' )or(nib_count = "100000" and Sel_IM_Bar_Slash_DM = '0')))then -- for nibble count >= 8(DM) or >= 32(IM) 
				       current_state <= M_WR_START_9_10;
					  else
                   current_state <= M_WR_START_1_8;
                 end if;						 
					 elsif(regeppadr = addr_mem_pointer)then
					   current_state <= PNTR_WR_START;
					 else
                  current_state <= OTHER_WR_START;	
 					 end if;  
        					 
            else  -- if data strobe asserted and intent to read
                if(regeppadr = addr_memory)then
					  if(((nib_count = "001001" and Sel_IM_Bar_Slash_DM = '1')or (nib_count = "100001" and Sel_IM_Bar_Slash_DM = '0')) or ((nib_count = "001000" and Sel_IM_Bar_Slash_DM = '1' )or(nib_count = "100000" and Sel_IM_Bar_Slash_DM = '0')))then -- for nibble count >= 8(DM) or >= 32(IM) 
				       current_state <= M_RD_START_9_10;
					  else
                   current_state <= M_RD_START_1_8;
                 end if;						 
					 elsif(regeppadr = addr_mem_pointer)then
					    current_state <= PNTR_RD_START;
					 else
						 current_state <= OTHER_RD_FINISH;	
 					 end if; 	
               end if;
            elsif (ASTB_SS = '1' and DSTB_SS = '1') then
				    current_state <= IDLE;
		      end if;
		            
            -- DPU RTL				
				i <= (others => '0'); 
				

	      when A_RD_FINISH =>  --(2)
				
            -- CU state transitions
				if (ASTB_SS = '1') then
				   current_state <= IDLE;
				end if;
		            
            -- DPU RTL
                i <= (others => '0');    
            
	      when A_WR_START =>  --(3)
                        
            -- CU state transitions  
		        if ( i = "11") then
				    current_state <= A_WR_FINISH;
				  end if;
                        
            -- DPU RTL
			     i <= i + "01";
				  A_int1 <= EppDB;
		        A_int2 <= A_int1;
		        A_int3 <= A_int2;
				  regeppadr <= A_int3;
           
		   when A_WR_FINISH => --(4)
				
          -- CU state transitions
				if (ASTB_SS = '1') then
				   current_state <= IDLE;
				end if;
		            
          -- DPU RTL
              A_int1 <= EppDB;
		        A_int2 <= A_int1;
		        A_int3 <= A_int2;
				  regeppadr <= A_int3;
				  
			 when OTHER_RD_FINISH =>  --(5)
                        
            -- CU state transitions  
		        if ( DSTB_SS = '1') then
				    current_state <= IDLE;
				  end if;
                        
            -- DPU RTL
				  -- NO DPU RTL          
			  
			  when OTHER_WR_START =>  --(6)
                        
            -- CU state transitions  
		        if ( i = "11") then
				    current_state <= OTHER_WR_FINISH;
				  end if;
                        
            -- DPU RTL
			        i <= i + "01";
				     D_int1 <= EppDB;  --applicable only for regeppaddr = x00
		           D_int2 <= D_int1;
		           D_int3 <= D_int2;
				   
				   
				   
				   
				   
				   
				   
					  --@Sabya:- qualify this with regEppadr
					  -- default  	- regver
					  -- 0x2A 		- Mem_select_reg
					  -- 0x2B 		- Control_register
					  case regEppAdr is
						when addr_Mem_Select_Reg => Mem_Select_Reg <= D_int3;
						when addr_Control_Reg => Control_Reg <= D_int3;
						when others => regver <= not(D_int3);
						
						
						
						
						
					  end case;
					  
				               
				when OTHER_WR_FINISH => --(7)
				
               -- CU state transitions
				    if (DSTB_SS = '1') then
				     current_state <= IDLE;
				    end if;
		             
              -- DPU RTL
                   D_int1 <= EppDB; --applicable only for regeppaddr = x00
		             D_int2 <= D_int1;
		             D_int3 <= D_int2;
					 
					 
					 
					 
					 
					 --@Sabya:- qualify this with regEppadr
					  -- default  	- regver
					  -- 0x2A 		- Mem_select_reg
					  -- 0x2B 		- Control_register
					  case regEppAdr is
						when addr_Mem_Select_Reg => Mem_Select_Reg <= D_int3;
						when addr_Control_Reg => Control_Reg <= D_int3;
						when others => regver <= not(D_int3);
						
						
					  end case;
					   
					    					 
			  when PNTR_RD_START => --(8)

		   -- CU state transitions  
		        if ( i = "11") then
				   current_state <= PNTR_RD_FINISH;
				  end if;
                        
            -- DPU RTL
			      i <= i + "01";
				
           when PNTR_RD_FINISH => --(9)

		   -- CU state transitions  
		        if ( DSTB_SS = '1') then
				   current_state <= IDLE;
				  end if;
                        
            -- DPU RTL
			    --NO DPU RTL

          when PNTR_WR_START =>  --(10)
                        
            -- CU state transitions  
		        if ( i = "11") then
				    current_state <= PNTR_WR_FINISH;
				  end if;
                        
            -- DPU RTL
			       i <= i + "01";
				    D_int1 <= EppDB;
		          D_int2 <= D_int1;
		          D_int3 <= D_int2;
				    Pointer <= D_int3;

           when PNTR_WR_FINISH =>  --(11)
                        
            -- CU state transitions  
		        if ( DSTB_SS = '1') then
				    current_state <= IDLE;
				  end if;
                        
            -- DPU RTL
				    D_int1 <= EppDB;
		          D_int2 <= D_int1;
		          D_int3 <= D_int2;
				    Pointer <= D_int3;	

          when M_RD_START_1_8 =>  --(12)

		      -- CU state transitions  
		        if ( i = "11") then
				    current_state <= M_RD_FINISH_1_8;
				  end if;
                        
            -- DPU RTL
			     i <= i + "01";
				
          when M_RD_FINISH_1_8 =>  --(13)

		       -- CU state transitions  
		        if ( DSTB_SS = '1') then
				    current_state <= INC_NIB_COUNT;
				  end if;
                        
            -- DPU RTL
			    --NO DPU RTL

         when M_RD_START_9_10 =>  --(14)

		   -- CU state transitions  
		        if ( i = "11") then
				    current_state <= M_RD_FINISH_9_10;
				  end if;
                        
            -- DPU RTL
			    i <= i + "01";
				
         when M_RD_FINISH_9_10 =>  --(15)

		   -- CU state transitions  
		        if ( DSTB_SS = '1') then
				     current_state <= INC_NIB_COUNT;
              end if;
                        
            -- DPU RTL
			    --NO DPU RTL

          when M_WR_START_1_8 => --(16)
                        
           -- CU state transitions  
		       if ( i = "11") then
				   current_state <= M_WR_FINISH_1_8;
				 end if;
                        
            -- DPU RTL
			     i <= i + "01";
				  D_int1 <= EppDB;
		        D_int2 <= D_int1;
		        D_int3 <= D_int2; 
				  ASCII <= D_int3; -- the data read from the file

         when M_WR_FINISH_1_8 =>  --(17)
                        
            -- CU state transitions  
		          if(DSTB_SS = '1')then 
				     current_state <= INC_NIB_COUNT;
				    end if;
                        
            -- DPU RTL
				    D_int1 <= EppDB;
		          D_int2 <= D_int1;
		          D_int3 <= D_int2; 
				    ASCII <=  D_int3; -- the data read from the file



         when M_WR_START_9_10 => --(18)
                        
            -- CU state transitions  
		        if ( i = "11") then
				   current_state <= M_WR_FINISH_9_10;
				  end if;
                        
            -- DPU RTL
			     i <= i + "01";
				 Data_to_mem <= reg_array(0)&reg_array(1)&reg_array(2)&reg_array(3)&reg_array(4)&reg_array(5)&reg_array(6)&reg_array(7)
				              & reg_array(8)&reg_array(9)&reg_array(10)&reg_array(11)&reg_array(12)&reg_array(13)&reg_array(14)&reg_array(15)
								  & reg_array(16)&reg_array(17)&reg_array(18)&reg_array(19)&reg_array(20)&reg_array(21)&reg_array(22)&reg_array(23)
								  & reg_array(24)&reg_array(25)&reg_array(26)&reg_array(27)&reg_array(28)&reg_array(29)&reg_array(30)&reg_array(31);
								  
								  

         
			when M_WR_FINISH_9_10 =>  --(19)
                        
            -- CU state transitions  
		          if(DSTB_SS = '1')then 
					   current_state <= INC_NIB_COUNT;
					 end if;						 
				    
                        
            -- DPU RTL
				    
				    Data_to_mem <= reg_array(0)&reg_array(1)&reg_array(2)&reg_array(3)&reg_array(4)&reg_array(5)&reg_array(6)&reg_array(7)
				              & reg_array(8)&reg_array(9)&reg_array(10)&reg_array(11)&reg_array(12)&reg_array(13)&reg_array(14)&reg_array(15)
								  & reg_array(16)&reg_array(17)&reg_array(18)&reg_array(19)&reg_array(20)&reg_array(21)&reg_array(22)&reg_array(23)
								  & reg_array(24)&reg_array(25)&reg_array(26)&reg_array(27)&reg_array(28)&reg_array(29)&reg_array(30)&reg_array(31);
							

         when INC_NIB_COUNT =>  --(20) 

		    -- CU state transitions 
              if((nib_count < "001001" and Sel_IM_Bar_Slash_DM = '1') or (nib_count < "100001" and Sel_IM_Bar_Slash_DM = '0'))then			 
		         current_state <= IDLE;
				  else
               current_state <= INC_MEM_PNTR;				  
              end if;          
            -- DPU RTL
			      nib_count <= nib_count + "000001";
        

         when INC_MEM_PNTR =>  --(21)

		   -- CU state transitions			
		        current_state <= IDLE;
                        
            -- DPU RTL
			       pointer <= pointer + "00000001";
			       nib_count <= "000000";
			when others =>
                   current_state <= IDLE;			
			  
		 end case;
		
	  end if;

	end process CU_DPU;
	
	
	
	
	
--@Sabya: Changed this so that it comes from the PC
	Sel_IM_Bar_Slash_DM <= Mem_Select_Reg(0);
	test_in<= Control_Reg(0);
	reset_tomasulo<=Control_Reg(1);
	
	
	
	
	
	
	
   --process to store the data sent by sw0 into a register sel_IM_Slash_DM
	-- Sel_IM_Bar_Slash_DM_process: process (clk_top)
		-- begin
			-- if (clk_top'event and clk_top = '1') then
				-- Sel_IM_Bar_Slash_DM <= sw0;
				-- test_in <= sw1; -- NOTE test mode is set by switch 1.
				-- reset_tomasulo <= sw2; --reset_tomasulo
				--r_sw2 <= sw2;
				--r_sw3 <= sw3;
			-- end if;
	-- end process Sel_IM_Bar_Slash_DM_process;	
	
	 btn1_debouncer: ee560_debounce  --btn1 used as Resetb for fileio
               generic map (N_dc => 25)
               port  map   (clk => clk_top, RESETB_DEBOUNCE => reset_fileio,  -- CLK = 50 MHz
                 PB => btn1,
                 DPB => db_btn1, SCEN => open, MCEN => open, CCEN => open ); 
reset_fileio <= not(db_btn1);
			  


end top_cpu_arc ;
------------------------------------------------------------------------------
