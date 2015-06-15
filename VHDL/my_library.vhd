LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;
use work.types.all;
--Package Types is
--Subtype Segment is std_logic_vector(11 downto 0);
--type memoryDAC is array (INTEGER range <>) of Segment;
--end types;


entity my_library is
port(
                 DAC_SIGNAL: OUT memoryDAC(0 to 10); --:= ((others=> (others=>'0')));
                 RESET : IN STD_LOGIC
	 );
end my_library;
architecture a of my_library is

begin
DAC_SIGNAL(0) <= conv_std_logic_vector(4095,12) WHEN RESET = '1' ELSE (others=>'0');
DAC_SIGNAL(1) <= conv_std_logic_vector(3978,12) WHEN RESET = '1' ELSE (others=>'0');
DAC_SIGNAL(2) <= conv_std_logic_vector(3647,12) WHEN RESET = '1' ELSE (others=>'0');
DAC_SIGNAL(3) <= conv_std_logic_vector(3158,12) WHEN RESET = '1' ELSE (others=>'0');
DAC_SIGNAL(4) <= conv_std_logic_vector(2593,12) WHEN RESET = '1' ELSE (others=>'0');
DAC_SIGNAL(5) <= conv_std_logic_vector(2040,12) WHEN RESET = '1' ELSE (others=>'0');
DAC_SIGNAL(6) <= conv_std_logic_vector(1582,12) WHEN RESET = '1' ELSE (others=>'0');
DAC_SIGNAL(7) <= conv_std_logic_vector(1275,12) WHEN RESET = '1' ELSE (others=>'0');
DAC_SIGNAL(8) <= conv_std_logic_vector(1143,12) WHEN RESET = '1' ELSE (others=>'0');
DAC_SIGNAL(9) <= conv_std_logic_vector(1176,12) WHEN RESET = '1' ELSE (others=>'0');
DAC_SIGNAL(10)<= conv_std_logic_vector(1333,12) WHEN RESET = '1' ELSE (others=>'0');
end a;