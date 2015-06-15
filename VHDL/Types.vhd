LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;
Package Types is
Subtype Segment is std_logic_vector(11 downto 0);
type memoryDAC is array (INTEGER range <>) of Segment;
end types;
