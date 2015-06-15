LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;
USE  IEEE.numeric_std.all;

use work.isp_hal.all;
use work.isp_drv.all;
use work.devreq_inc.all;

--USE  WORK.MY_PACKAGE.all;
--USE  IEEE.math_real.all;
LIBRARY IEEE_PROPOSED;
use IEEE_PROPOSED.fixed_float_types.all;
use IEEE_PROPOSED.fixed_pkg.all;
--use IEEE_PROPOSED.fixed_alg_pkg.all;
use IEEE_PROPOSED.float_pkg.all;
--use work.MY_LIBRARY.all;
use work.types.all; --needed for my_library (declarations)

ENTITY DE2_CLOCK IS
	PORT(--DE2 board config USB
  OTG_FSPEED  : out    std_logic;            --USB Full Speed 
  OTG_LSPEED  : out    std_logic;            --USB Low Speed 
  --ISP1368  
  OTG_DATA  : inout    std_logic_vector(15 downto 0);  --ISP1362 Data bus 16 bits
  OTG_INT1  : in    std_logic;                  --ISP1362 Interrupt 2 (Peripheral Interrupts) 
  OTG_RST_N  : out    std_logic;                --ISP1362 Reset pin
  OTG_ADDR  : out    std_logic_vector(1 downto 0);      --ISP1362 Address 2 Bits[peripheral,command]
  OTG_CS_N  : out    std_logic;                  --ISP1362 Chip Select 
  OTG_RD_N  : out    std_logic;                  --ISP1362 Write 
  OTG_WR_N  : out    std_logic;                  --ISP1362 Read   
  -- not used
  OTG_DACK0_N  : out    std_logic;                --ISP1362 DMA Acknowledge 1 
  OTG_DACK1_N  : out    std_logic;                --ISP1362 DMA Acknowledge 2
 --I/O...
 -- KEY                  : in  std_logic_vector(3 downto 0); --key(0) is reset
  SW                    : in  std_logic_vector(17 downto 0);
  LEDR                  : out  std_logic_vector(16 downto 0) := "00000000000000000"; --LED 17 is the SEC_LED
------------LCD------------------- 
	reset, clk_50Mhz	: IN	STD_LOGIC;
		 LCD_RS, LCD_E, LCD_ON, RESET_LED, SEC_LED		: OUT	STD_LOGIC;
		 LCD_RW				   : BUFFER STD_LOGIC;
		 GPIO0				   : INOUT	STD_LOGIC_VECTOR(35 DOWNTO 0);
		 GPIO1					: INOUT	STD_LOGIC_VECTOR(35 DOWNTO 0);
		 DATA_BUS				: INOUT	STD_LOGIC_VECTOR(7 DOWNTO 0));
END DE2_CLOCK;

ARCHITECTURE a OF DE2_CLOCK IS
	TYPE STATE_TYPE IS (HOLD, FUNC_SET, DISPLAY_ON, MODE_SET, WRITE_CHAR1,
	WRITE_CHAR2,WRITE_CHAR3, RETURN_HOME, TOGGLE_E, RESET1, RESET2, 
	RESET3, DISPLAY_OFF, DISPLAY_CLEAR); -- WRITE_CHAR4,WRITE_CHAR5,WRITE_CHAR6,WRITE_CHAR7,WRITE_CHAR8, WRITE_CHAR9, WRITE_CHAR10,
	type memory is array (INTEGER range <>) of std_logic_vector(7 downto 0);
	type memoryint is array (INTEGER range <>) of float (float_exponent_width downto -float_fraction_width);
	--type memoryDAC is array (INTEGER range <>) of std_logic_vector(11 downto 0);
	SIGNAL state, next_command: STATE_TYPE;
	SIGNAL DATA_BUS_VALUE: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL CLK_COUNT_400HZ: STD_LOGIC_VECTOR(19 DOWNTO 0);
	SIGNAL CLK_COUNT_10HZ: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL CLK_COUNT_12MHZ: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL BCD_SECD0,BCD_SECD1,BCD_MIND0,BCD_MIND1: STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL BCD_HRD0,BCD_HRD1,BCD_TSEC: STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL DAC_SIGNAL: memoryDAC(0 to 10) := ((others=> (others=>'0')));
	SIGNAL CLK_400HZ, CLK_10HZ, CLK_12MHZ : STD_LOGIC;
	SIGNAL ADC1, ADC2, ADC3: memoryint(0 to 9) := ((others=> (others=>'0'))); --(3999999 downto 0);
	--SIGNAL ADC1: memoryDAC(24999 downto 0) := ((others=> (others=>'0'))); --(3999999 downto 0);
	--SIGNAL FREQ_DIV: INTEGER RANGE 40 to 400000;
	SIGNAL COUNT_RMS, COUNT_RMS2: INTEGER RANGE 0 to 9:= 0;
	SIGNAL COUNT_DAC: INTEGER RANGE 0 to 11:= 0;	
	--SIGNAL j: INTEGER := 0;
	--SIGNAL ADC1_MAX: INTEGER RANGE 0 to 250 := 0;
	--SIGNAL ADC2_MAX: INTEGER RANGE 0 to 250 := 0;
	--SIGNAL ADC3_MAX: INTEGER RANGE 0 to 250 := 0;
	SIGNAL ADC1_AVC: STD_LOGIC_VECTOR(2 DOWNTO 0) := "000"; --(GPIO0 (14), GPIO0 (16),GPIO0 (18) A
	SIGNAL ADC2_AVC: STD_LOGIC_VECTOR(2 DOWNTO 0) := "000"; --(GPIO1 (13), GPIO1 (15),GPIO1 (17) A
	SIGNAL ADC3_AVC: STD_LOGIC_VECTOR(2 DOWNTO 0) := "000"; --(GPIO0 (21), GPIO0 (23),GPIO0 (25) A
	CONSTANT COUNT_RMS_FINAL: INTEGER := 9;--24999;
	SHARED VARIABLE x, x2:    float (float_exponent_width downto -float_fraction_width) := (others=>'0');
	SIGNAL realW: memoryint(0 to 19); 
	SIGNAL imagW: memoryint(0 to 19); 
	--SIGNAL IMP: memoryint(0 to 0):= ((others=> (others=>'0')));  --100k is OK
	SIGNAL IMP_DUMMY: memory(0 to 19) := ((others=> (others=>'0'))); --(3999999 downto 0);  --  STD_LOGIC_VECTOR(7 DOWNTO 0) :="00000000";
	--SHARED VARIABLE BLA:    signed(23 downto 0) ;
	--SHARED VARIABLE FLAG: integer := 0;
	--function  sqrt  ( d : UNSIGNED ) return UNSIGNED ;
	signal clk,clk1     : std_logic;
	signal slowclk_en : bit;
	signal reset_usb, reset_synch   : std_logic;
	--USB stuff
	signal hal_i : isp_hal_in_t;
	signal hal_o : isp_hal_out_t;
	signal drv_i : isp_drv_in_t;
	signal drv_o : isp_drv_out_t;
	type stateT is (loopOuter, loopInner);
	signal state_usb: stateT;
	signal counter, innerCounter, counter1: integer := 0;
	signal sending: std_logic := '0';

	component my_library
		port (
                 DAC_SIGNAL: OUT memoryDAC(0 to 10);-- := ((others=> (others=>'0')));
                 RESET : IN STD_LOGIC
           );
	end component;
	
BEGIN

A1: my_library port map(
DAC_SIGNAL => DAC_SIGNAL,
RESET => RESET
);

	--(GPIO0 (21), GPIO0 (19),GPIO0 (17)) <= ADC1_AVC; OK
	--(GPIO1 (22), GPIO1 (20),GPIO1 (18)) <= ADC2_AVC; --(GPIO1 (13), GPIO1 (15),GPIO1 (17)) <= ADC2_AVC;
   --(GPIO1 (14), GPIO1 (12),GPIO1 (10)) <= ADC3_AVC;--(GPIO1 (21), GPIO1 (23),GPIO1 (25)) <= ADC3_AVC;
	LCD_ON <= '1';
	RESET_LED <= NOT RESET;
	SEC_LED <= BCD_SECD0(0);
-- BIDIRECTIONAL TRI STATE LCD DATA BUS
	DATA_BUS <= DATA_BUS_VALUE WHEN LCD_RW = '0' ELSE "ZZZZZZZZ";
	realW(0) <= to_float(1.75265,realW(0)); --to_s(2*cos(0.00628),d1_1); 			  --gravar as 20 freq            --Goertzel
	imagW(0) <= to_float(0.4818,realW(0)); --sin(2.0*pi*k(j)./Fs(z));                   --K sï¿½o as freq injetadas no tecido
	realW(1) <= to_float(1.8285,realW(0)); --to_s(2*cos(0.00628),d1_1); 			  --gravar as 20 freq            --Goertzel
	imagW(1) <= to_float(0.4052,realW(0)); --sin(2.0*pi*k(j)./Fs(z));                   --K sï¿½o as freq injetadas no tecido
	realW(2) <= to_float(1.8876,realW(0)); --to_s(2*cos(0.00628),d1_1); 			  --gravar as 20 freq            --Goertzel
	imagW(2) <= to_float(0.3304,realW(0)); 	--sin(2.0*pi*k(j)./Fs(z));                   --K sï¿½o as freq injetadas no tecido
	ADC1(0) <= to_float(11.0,realW(0));
	ADC1(1) <= to_float(10.686,realW(0));
	ADC1(2) <= to_float(9.7963,realW(0));
	ADC1(3) <= to_float(8.4832,realW(0));
	ADC1(4) <= to_float(6.9640,realW(0));
	ADC1(5) <= to_float(5.4799,realW(0));
	ADC1(6) <= to_float(4.2485,realW(0));
	ADC1(7) <= to_float(3.4239,realW(0));
	ADC1(8) <= to_float(3.0710,realW(0));
	ADC1(9) <= to_float(3.1599,realW(0));	
	
	ADC2(0) <= to_float(13.0,realW(0));
	ADC2(1) <= to_float(12.685,realW(0));
	ADC2(2) <= to_float(11.796,realW(0));
	ADC2(3) <= to_float(10.483,realW(0));
	ADC2(4) <= to_float(8.963,realW(0));
	ADC2(5) <= to_float(7.479,realW(0));
	ADC2(6) <= to_float(6.2484,realW(0));
	ADC2(7) <= to_float(5.423,realW(0));
	ADC2(8) <= to_float(5.071,realW(0));
	ADC2(9) <= to_float(5.159,realW(0));	
	GPIO0 (12) <= '0'; --CS = 0 Enable DAC
-------------------------------USB------------------------------	
--DE2 USB config
OTG_FSPEED  <='0';            -- 0 = Enable, Z = Disable 
OTG_LSPEED  <='Z';            -- 0 = Enable, Z = Disable 

--DE2 clock and reset config
clk <= clk_50Mhz;

p_reset: process
begin
  wait until rising_edge(clk);
  reset_synch <= not(RESET);
  reset_usb <= reset_synch;
end process;
                                 
--produces 25MHz clock enable pulse for HAL 
--assumes 50MHz clk, if this assumption changes,
--this code needs to be modified
p_pulse25MHz: process

-- Example 1:  design clk is @ 50MHz
--                   _   _   _   _   _   _   _   _  
--clk @ 50MHz       | |_| |_| |_| |_| |_| |_| |_| |_
--                   _ _     _ _     _ _     _ _    
--pulse @ 25MHz     |   |_ _|   |_ _|   |_ _|   |_ _
--
-- Example 2:  design clk is @ 200MHz
--                   _   _   _   _   _   _   _   _  
--clk @ 200MHz      | |_| |_| |_| |_| |_| |_| |_| |_
--                   _ _             _ _    
--pulse @ 25MHz     |   |_ _ _ _ _ _|   |_ _ _ _ _ _

begin
  WAIT UNTIL CLK_50MHZ'EVENT AND CLK_50MHZ = '1';
  slowclk_en <= not(slowclk_en);
end process;

-- hal port map
hal_i.slowclk_en <= slowclk_en;
OTG_RST_N <= hal_o.rst_n;
OTG_ADDR <= hal_o.addr;
OTG_CS_N <= hal_o.cs_n;
OTG_RD_N <= hal_o.rd_n;
OTG_WR_N <= hal_o.wr_n;  
OTG_DACK0_N <= hal_o.dack0_n;
OTG_DACK1_N <= hal_o.dack1_n;

--hal
hal_i.drv <= drv_o.hal;  
h: hal port map (clk, reset_usb, OTG_DATA , hal_i, hal_o);

--driver port map
drv_i.int <= OTG_INT1; --IF LOOPBACK, DON'T NEED
--driver
drv_i.hal <= hal_o.drv;
d: drv port map(clk,reset_usb, drv_i , drv_o);

--device request handler
dvrq: devreq port map(clk, reset_usb, drv_o.devreq, drv_i.devreq);

--loopback (for demo)
--drv_i.io <= drv_o.io; --when io.SData is ready, io.RDy will pulse for one clock cycle.
--drv_i.io.Sdata(drv_o.io.Sdata'high downto 0) <= "00000000" & IMP_DUMMY1;

demo_send: process(clk, SW)
VARIABLE a: integer range 0 to 3 := 0;
VARIABLE k: integer range 0 to 1 := 0;
VARIABLE dummy_std:  STD_LOGIC_VECTOR(15 DOWNTO 0);
begin
  if rising_edge(clk) then
    if SW(0) = '1' then
     if counter < 10 then
	  	case k is
			when 1 => dummy_std := "0000000000000001";--
			when others => dummy_std := "0000000000010000";--
	   end case;
		case a is 
			when 0 => drv_i.io.Sdata(drv_o.io.Sdata'high downto 0) <= dummy_std;--"0000000000000011";--			
			k := k+1;
			when 1 => drv_i.io.Sdata(drv_o.io.Sdata'high downto 0) <= "00000000" & IMP_DUMMY(0);--"0000000000000011";--
			when 2 => drv_i.io.Sdata(drv_o.io.Sdata'high downto 0) <= "00000000" & IMP_DUMMY(1);--"0000000000000011";--
			when others => drv_i.io.Sdata(drv_o.io.Sdata'high downto 0) <= "00000000" & IMP_DUMMY(2);--"0000000000000011";--
			--when others => dummy_std <= "0000000000010000";--
	   end case;
		
--	   if a =0 then
----		 if k = 0 then
----       drv_i.io.Sdata(drv_o.io.Sdata'high downto 0) <= "0000000000000001";--
----		 k := 1;
----		 else
----		 drv_i.io.Sdata(drv_o.io.Sdata'high downto 0) <= "0000000000010000";--
----		 k := 0;
----		 end if;
--		 elsif a = 1 then
--		 drv_i.io.Sdata(drv_o.io.Sdata'high downto 0) <= "00000000" & IMP_DUMMY(0);--"0000000000000011";--
--		 elsif a = 2 then
--		 drv_i.io.Sdata(drv_o.io.Sdata'high downto 0) <= "00000000" & IMP_DUMMY(1);--"0000000000000011";--
--		 elsif a = 3 then
--		 drv_i.io.Sdata(drv_o.io.Sdata'high downto 0) <= "00000000" & IMP_DUMMY(2);--"0000000000000011";--
--		 --else
--		 --drv_i.io.Sdata(drv_o.io.Sdata'high downto 0) <= "0000000000000100";--
--		 end if;
 
--		 if a = 4 then
--		 a := 0;
--		 else
   	 a := a +1;
--		 end if;
		 
		 
		--drv_i.io.Sdata(7 downto 0) <= IMP_DUMMY1;--"0000000000000011";--
		--counter1 <= counter1 +1;
		--if counter1 = 10 then
		--counter1 <= 0;
		--end if;
		--drv_i.io.Sdata(drv_o.io.Sdata'high downto 0) <= std_logic_vector(to_unsigned(counter, 16));
		--drv_i.io.Sdata,(7 downto 0) <= std_logic_vector(to_unsigned(counter, 8));
      if innerCounter = 0 then
        drv_i.io.Rdy <= '1';
      -- LEDR(drv_o.io.Sdata'high downto 0) <= "1111111111111111";
       innerCounter <= innerCounter + 1;
      elsif innerCounter > 0 and innerCounter < 1500 then
         drv_i.io.Rdy <= '0';
      -- LEDR(drv_o.io.Sdata'high downto 0) <= "1000111100001111";
       innerCounter <= innerCounter + 1;
      elsif innerCounter = 1500 then
        innerCounter <= 0;
       counter <= counter + 1;
      end if;
      elsif counter = 10 then 
       counter <= 0;
      innerCounter <= 0;
      drv_i.io.Rdy <= '0';
       LEDR(drv_o.io.Sdata'high downto 0) <= "0000000000000000";
      drv_i.io.Sdata(drv_o.io.Sdata'high downto 0) <= (others => '0');
    end if;
   else
     counter <= 0;
    innerCounter <= 0;
     drv_i.io.Rdy <= '0';
     drv_i.io.Sdata(drv_o.io.Sdata'high downto 0) <= (others => '0');
    end if;
  end if;
end process;
-------------------------------USB------------------------------		
	PROCESS	
	BEGIN
	 WAIT UNTIL CLK_50MHZ'EVENT AND CLK_50MHZ = '1';
		IF RESET = '0' THEN
		 CLK_COUNT_400HZ <= X"00000";
		 CLK_400HZ <= '0';
		ELSE
				IF CLK_COUNT_400HZ < X"0F424" THEN 
				 CLK_COUNT_400HZ <= CLK_COUNT_400HZ + 1;
				ELSE
		    	 CLK_COUNT_400HZ <= X"00000";
				 CLK_400HZ <= NOT CLK_400HZ;
				END IF;
		END IF;
	END PROCESS;
	PROCESS (CLK_400HZ, reset)
	BEGIN
		IF reset = '0' THEN
			state <= RESET1;
			DATA_BUS_VALUE <= X"38";
			next_command <= RESET2;
			LCD_E <= '1';
			LCD_RS <= '0';
			LCD_RW <= '0';

		ELSIF CLK_400HZ'EVENT AND CLK_400HZ = '1' THEN
-- GENERATE 1/10 SEC CLOCK SIGNAL FOR SECOND COUNT PROCESS

			IF CLK_COUNT_10HZ < 19 THEN
				CLK_COUNT_10HZ <= CLK_COUNT_10HZ + 1;
			ELSE
				CLK_COUNT_10HZ <= X"00";
				CLK_10HZ <= NOT CLK_10HZ;
			END IF;
-- SEND TIME TO LCD			
			CASE state IS
-- Set Function to 8-bit transfer and 2 line display with 5x8 Font size
-- see Hitachi HD44780 family data sheet for LCD command and timing details
				WHEN RESET1 =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"38";
						state <= TOGGLE_E;
						next_command <= RESET2;
				WHEN RESET2 =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"38";
						state <= TOGGLE_E;
						next_command <= RESET3;
				WHEN RESET3 =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"38";
						state <= TOGGLE_E;
						next_command <= FUNC_SET;
-- EXTRA STATES ABOVE ARE NEEDED FOR RELIABLE PUSHBUTTON RESET OF LCD
				WHEN FUNC_SET =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"38";
						state <= TOGGLE_E;
						next_command <= DISPLAY_OFF;
-- Turn off Display and Turn off cursor
				WHEN DISPLAY_OFF =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"08";
						state <= TOGGLE_E;
						next_command <= DISPLAY_CLEAR;
-- Turn on Display and Turn off cursor
				WHEN DISPLAY_CLEAR =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"01";
						state <= TOGGLE_E;
						next_command <= DISPLAY_ON;
-- Turn on Display and Turn off cursor
				WHEN DISPLAY_ON =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"0C";
						state <= TOGGLE_E;
						next_command <= MODE_SET;
-- Set write mode to auto increment address and move cursor to the right
				WHEN MODE_SET =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"06";
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR1;
-- Write ASCII hex character in first LCD character location R
				WHEN WRITE_CHAR1 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"52";
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR2;
						
-- Write ASCII hex character in second LCD character location " "
				WHEN WRITE_CHAR2 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"20";
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR3;
-- Write ASCII hex character in third LCD character location =
--				WHEN WRITE_CHAR3 =>
--						LCD_E <= '1';
--						LCD_RS <= '1';
--						LCD_RW <= '0';
--						DATA_BUS_VALUE <= X"3D" ;
--						state <= TOGGLE_E;
--						next_command <= RETURN_HOME; --WRITE_CHAR4;
						
				WHEN WRITE_CHAR3 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
--						IF FLAG = 20 THEN
--						DATA_BUS_VALUE <= X"3E";
--						ELSE
						DATA_BUS_VALUE <= X"3D" ; --IMP_DUMMY1; --
--						END IF;
						state <= TOGGLE_E;
						next_command <= RETURN_HOME; --WRITE_CHAR4;

-- Return write address to first character postion
				WHEN RETURN_HOME =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"80";
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR1;
-- The next two states occur at the end of each command to the LCD
-- Toggle E line - falling edge loads inst/data to LCD controller
				WHEN TOGGLE_E =>
						LCD_E <= '0';
						state <= HOLD;
-- Hold LCD inst/data valid after falling edge of E line				
				WHEN HOLD =>
						state <= next_command;
			END CASE;
		END IF;
	END PROCESS;
--	PROCESS	(CLK_10HZ, reset)
--	BEGIN
--	    IF RESET = '0' THEN
--		 CLK_COUNT_1HZ <= X"00";
--		 CLK_1HZ <= '0';
--		ELSE
--				IF CLK_COUNT_1HZ < X"0A" THEN 
--				 CLK_COUNT_1HZ <= CLK_COUNT_1HZ + 1;
--				ELSE
--		    	 CLK_COUNT_1HZ <= X"00";
--				 CLK_1HZ <= NOT CLK_1HZ;
--				END IF;
--		END IF;
--	END PROCESS;
	PROCESS (Clk_10hz, reset)
	BEGIN
		--IMP_DUMMY1 <= to_slv(resize(x*0.1,7,0));X
		IF reset = '0' THEN	
			BCD_HRD1 <= X"0";			
			BCD_HRD0 <= X"0";
			BCD_MIND1 <= X"0";
			BCD_MIND0 <= X"0";
			BCD_SECD1 <= X"0";
			BCD_SECD0 <= X"0";
			BCD_TSEC  <= X"0";

		ELSIF clk_10HZ'EVENT AND clk_10HZ = '1' THEN
-- TENTHS OF SECONDS
		IF BCD_TSEC < 9 THEN
		 BCD_TSEC <= BCD_TSEC + 1;
		ELSE
		 BCD_TSEC <= X"0";
-- SECONDS
		IF BCD_SECD0 < 9 THEN
	 	 BCD_SECD0 <= BCD_SECD0 + 1;
		ELSE
-- TENS OF SECONDS
		 BCD_SECD0 <= "0000";
	 	  IF BCD_SECD1 < 5 THEN
	  	 BCD_SECD1 <= BCD_SECD1 + 1;
	 	 ELSE
-- MINUTES
	  	 BCD_SECD1 <= "0000";
	  	 IF BCD_MIND0 < 9 THEN
	   	  BCD_MIND0 <= BCD_MIND0 + 1;
	  	 ELSE
-- TENS OF MINUTES
	   	  BCD_MIND0 <= "0000";
	   	  IF BCD_MIND1 < 5 THEN
	       BCD_MIND1 <= BCD_MIND1 + 1;
	   	  ELSE
-- HOURS
	    	BCD_MIND1 <= "0000";
	    	IF BCD_HRD0 < 9 AND NOT((BCD_HRD1 = 2) AND (BCD_HRD0 = 3))THEN
	     	 BCD_HRD0 <= BCD_HRD0 + 1;
	    	ELSE
-- TENS OF HOURS
	     	 IF NOT((BCD_HRD1 = 2) AND (BCD_HRD0 = 3)) THEN
	      	  BCD_HRD1 <= BCD_HRD1 + 1;
	      	  BCD_HRD0 <= "0000";
	     	 ELSE
-- NEW DAY
	      	 BCD_HRD1 <= "0000";
          	 BCD_HRD0 <= "0000";
         	END IF;
           END IF;
          END IF;
         END IF;
        END IF;
       END IF;
	  END IF;
	END IF;
 END PROCESS;
  PROCESS	
	BEGIN
	 WAIT UNTIL CLK_50MHZ'EVENT AND CLK_50MHZ = '1';
		IF RESET = '0' THEN
		 CLK_COUNT_12MHZ <= X"00";
		 CLK_12MHZ <= '0';
		ELSE
				IF CLK_COUNT_12MHZ < 4 THEN 
				 CLK_COUNT_12MHZ <= CLK_COUNT_12MHZ + 1;
				ELSE
		    	 CLK_COUNT_12MHZ <= X"00";
				 CLK_12MHZ <= NOT CLK_12MHZ;
				END IF;
		END IF;
  END PROCESS;
	PROCESS --(CLK_12MHZ, reset) --it enter in the rising and falling edge, the freq is acctually 6,25Mhz
	VARIABLE d1_1: float (float_exponent_width downto -float_fraction_width) := (others=>'0');
	VARIABLE d1_2: float (float_exponent_width downto -float_fraction_width) := (others=>'0');
	VARIABLE y:    float (float_exponent_width downto -float_fraction_width) := (others=>'0');
	BEGIN
	WAIT UNTIL CLK_50MHZ'EVENT AND CLK_50MHZ = '1';

		IF RESET = '0' THEN
	    COUNT_RMS <= 0;
		 
		ELSIF COUNT_RMS = COUNT_RMS_FINAL THEN
			FOR j in 0 to 2 loop
			d1_1 :=  to_float(0.0,y);
			d1_2 :=  to_float(0.0,y);
			y :=     to_float(0.0,y);
		FOR k in 0 to COUNT_RMS_FINAL LOOP
		-- y <= resize(to_float("000000000000000000000000" & ADC1(COUNT_RMS))*33000/1020+30000/4,y);
		-- y <= resize(to_float("000000000000000000000000" & ADC1(COUNT_RMS))+resize(multiply(realW(j),d1_1),y) - d1_2,y);
		-- y <= resize(to_float("000000000000000000000000" & ADC1(COUNT_RMS))*32.3529+7500,y);
		-- y <= resize(divide(y,resize((1-y*0.0001),y))+resize(multiply(realW(j),d1_1),y) - d1_2,y);		
		-- y := resize(to_float("000000000000000000000000" & ADC1(k))+resize(multiply(realW(j),d1_1),y) - d1_2,y);
		y := resize(ADC2(k)+resize(multiply(realW(j),d1_1),y) - d1_2,y);
		d1_2 := d1_1;
		d1_1 := y;
		END LOOP;		
		x := resize((sqrt((realW(j)*d1_1*to_float(0.5) - d1_2) * (realW(j)*d1_1*to_float(0.5) - d1_2)+(imagW(j)*d1_1)*(imagW(j)*d1_1))),y);
		
				--IMP_DUMMY := std_logic_vector(UNSIGNED(x));
				--BLA := to_integer(x);
				--IMP_DUMMY := std_logic_vector(x);
		FOR k in 0 to 255 LOOP
		if x > k then
		IMP_DUMMY(j) <= std_logic_vector(to_unsigned(k,8));
		end if;
		end loop;
		
--		IF X>10 THEN
--		IMP_DUMMY1 <= "00111010";
--		ELSIF X>9 THEN
--		IMP_DUMMY1 <= "00111001";
--		ELSIF X>8 THEN
--		IMP_DUMMY1 <= "00111000";
--		ELSIF X>7 THEN
--		IMP_DUMMY1 <= "00110111";
--		ELSIF X>6 THEN
--		IMP_DUMMY1 <= "00110110";
--		ELSIF X>5 THEN
--		IMP_DUMMY1 <= "00110101";
--		ELSIF X>4 THEN
--		IMP_DUMMY1 <= "00110100";
--		ELSIF X>3 THEN
--		IMP_DUMMY1 <= "00110011";
--		ELSIF X>2 THEN
--		IMP_DUMMY1 <= "00110010";
--		ELSIF X>1 THEN
--		IMP_DUMMY1 <= "00110001";
--		ELSIF X>0 THEN
--		IMP_DUMMY1 <= "00110000";
--		END IF;

		--IMP_DUMMY1 := 48 + IMP_DUMMY1;
		COUNT_RMS <= 0;
		END LOOP;
		ELSE
		--ADC1(COUNT_RMS) <= GPIO0 (17) & GPIO0 (15) & GPIO0 (13) & GPIO0 (11) & GPIO0 (9) & GPIO0 (7) & GPIO0 (5) & GPIO0 (3);     OK --ADC1(COUNT_RMS) <= GPIO0 (18) & GPIO0 (20) & GPIO0 (22) & GPIO0 (24) & GPIO0 (26) & GPIO0 (28) & GPIO0 (30) & GPIO0 (32);
		--ADC2(COUNT_RMS) <= GPIO1 (24) & GPIO1 (26) & GPIO1 (28) & GPIO1 (30) & GPIO1 (32) & GPIO1 (34) & GPIO1 (35) & GPIO1 (33); OK    --ADC2(COUNT_RMS) <= GPIO1 (11) & GPIO1 (9) & GPIO1 (7) & GPIO1 (5) & GPIO1 (3) & GPIO1 (1) & GPIO1 (0) & GPIO1 (2);
		--ADC3(COUNT_RMS) <= GPIO1 (17) & GPIO1 (19) & GPIO1 (21) & GPIO1 (23) & GPIO1 (25) & GPIO1 (27) & GPIO1 (29) & GPIO1 (31); OK--ADC3(COUNT_RMS) <= GPIO1 (18) & GPIO1 (16) & GPIO1 (14) & GPIO1 (12) & GPIO1 (10) & GPIO1 (8) & GPIO1 (6) & GPIO1 (4);
		COUNT_RMS <= COUNT_RMS +1; -- if the smallest freq is 100HZ it will save 100000
		END IF;
	END PROCESS;
-------------------------------------ADC2-------------------------------------------
--PROCESS --(CLK_12MHZ, reset) --it enter in the rising and falling edge, the freq is acctually 6,25Mhz
--	VARIABLE d1_1: float (float_exponent_width downto -float_fraction_width) := (others=>'0');
--	VARIABLE d1_2: float (float_exponent_width downto -float_fraction_width) := (others=>'0');
--	VARIABLE y:    float (float_exponent_width downto -float_fraction_width) := (others=>'0');
--	BEGIN
--	WAIT UNTIL CLK_50MHZ'EVENT AND CLK_50MHZ = '1';
--
--		IF RESET = '0' THEN
--	    COUNT_RMS2 <= 0;
--		 
--		ELSIF COUNT_RMS = COUNT_RMS_FINAL THEN
--			FOR j in 0 to 0 LOOP
--			d1_1 :=  to_float(0.0,y);
--			d1_2 :=  to_float(0.0,y);
--			y :=     to_float(0.0,y);
--				FOR k in 0 to COUNT_RMS_FINAL LOOP
--					y := resize(ADC1(k)+resize(multiply(realW(j),d1_1),y) - d1_2,y);
--					d1_2 := d1_1;
--					d1_1 := y;
--				END LOOP;		
--			x2 := resize((sqrt((realW(j)*d1_1*to_float(0.5) - d1_2) * (realW(j)*d1_1*to_float(0.5) - d1_2)+(imagW(j)*d1_1)*(imagW(j)*d1_1))),y);
--				FOR k in 0 to 255 LOOP
--					if x2 > k then
--						IMP_DUMMY2 <= std_logic_vector(to_unsigned(k,8));
--					end if;
--				end loop;
--			COUNT_RMS2 <= 0;
--			END LOOP;
--		ELSE
--			COUNT_RMS2 <= COUNT_RMS2 +1; -- if the smallest freq is 100HZ it will save 100000
--		END IF;
--END PROCESS;
	
PROCESS	(CLK_12MHZ, reset)
	BEGIN
	    IF RESET = '0' THEN
		 (GPIO0 (10), GPIO0 (8),GPIO0 (6),GPIO0 (4),GPIO0 (2),GPIO0 (0),GPIO0 (1),GPIO0 (3),GPIO0 (5),GPIO0 (7),GPIO0 (9),GPIO0 (11)) <= conv_std_logic_vector(0,12); --OK
		 COUNT_DAC <= 0;
		 ELSE --IF CLK_12MHZ'EVENT AND CLK_12MHZ = '1' THEN
			COUNT_DAC <= COUNT_DAC +1;
			IF COUNT_DAC = 10 THEN
				COUNT_DAC <= 0;
			END IF;
			--(GPIO0 (25), GPIO0 (27),GPIO0 (29),GPIO0 (31),GPIO0 (33),GPIO0 (35),GPIO0 (34),GPIO0 (32),GPIO0 (30),GPIO0 (28),GPIO0 (26),GPIO0 (24)) <= DAC_SIGNAL(COUNT_DAC);
			(GPIO0 (10), GPIO0 (8),GPIO0 (6),GPIO0 (4),GPIO0 (2),GPIO0 (0),GPIO0 (1),GPIO0 (3),GPIO0 (5),GPIO0 (7),GPIO0 (9),GPIO0 (11)) <= conv_std_logic_vector(1023,12); --OK
		END IF;
END PROCESS;
END a;
