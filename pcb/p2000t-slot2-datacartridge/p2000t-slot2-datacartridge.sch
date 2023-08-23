EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "P2000T I/O Port Cartridge"
Date "2022-10-02"
Rev "1"
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Connector_Generic:Conn_02x15_Row_Letter_Last J1
U 1 1 621614BF
P 5425 7075
F 0 "J1" V 5521 6287 50  0000 R CNN
F 1 "P2000T Port 2" V 5430 6287 50  0000 R CNN
F 2 "p2000t_cartridge:p2000t_cartridge_edge" H 5425 7075 50  0001 C CNN
F 3 "~" H 5425 7075 50  0001 C CNN
	1    5425 7075
	0    -1   -1   0   
$EndComp
Text GLabel 4825 7275 3    50   Input ~ 0
D0
Text GLabel 4925 7275 3    50   Input ~ 0
D2
Text GLabel 5025 7275 3    50   Input ~ 0
D4
Text GLabel 5125 7275 3    50   Input ~ 0
D6
Text GLabel 5225 7275 3    50   Input ~ 0
A0
Text GLabel 5425 7275 3    50   Input ~ 0
A4
Text GLabel 5525 7275 3    50   Input ~ 0
A6
$Comp
L power:GND #PWR010
U 1 1 621707D5
P 6125 7275
F 0 "#PWR010" H 6125 7025 50  0001 C CNN
F 1 "GND" V 6130 7147 50  0000 R CNN
F 2 "" H 6125 7275 50  0001 C CNN
F 3 "" H 6125 7275 50  0001 C CNN
	1    6125 7275
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR09
U 1 1 62171360
P 6125 6775
F 0 "#PWR09" H 6125 6525 50  0001 C CNN
F 1 "GND" V 6130 6647 50  0000 R CNN
F 2 "" H 6125 6775 50  0001 C CNN
F 3 "" H 6125 6775 50  0001 C CNN
	1    6125 6775
	-1   0    0    1   
$EndComp
$Comp
L power:VCC #PWR01
U 1 1 62171A32
P 4725 6775
F 0 "#PWR01" H 4725 6625 50  0001 C CNN
F 1 "VCC" V 4740 6903 50  0000 L CNN
F 2 "" H 4725 6775 50  0001 C CNN
F 3 "" H 4725 6775 50  0001 C CNN
	1    4725 6775
	1    0    0    -1  
$EndComp
NoConn ~ 6025 7275
NoConn ~ 5925 6775
Text GLabel 6025 6775 1    39   Input ~ 0
~WR
Text GLabel 5725 7275 3    39   Input ~ 0
~IORQ
Text GLabel 5625 7275 3    39   Input ~ 0
~RD
Text GLabel 5225 6775 1    50   Input ~ 0
A1
Text GLabel 5425 6775 1    50   Input ~ 0
A5
Text GLabel 5525 6775 1    50   Input ~ 0
A7
Text GLabel 5625 6775 1    39   Input ~ 0
~RES
$Comp
L power:GND #PWR08
U 1 1 6218A7AD
P 5825 6775
F 0 "#PWR08" H 5825 6525 50  0001 C CNN
F 1 "GND" V 5830 6647 50  0000 R CNN
F 2 "" H 5825 6775 50  0001 C CNN
F 3 "" H 5825 6775 50  0001 C CNN
	1    5825 6775
	-1   0    0    1   
$EndComp
NoConn ~ 5925 7275
$Comp
L power:GND #PWR032
U 1 1 620DBC2F
P 2300 3450
F 0 "#PWR032" H 2300 3200 50  0001 C CNN
F 1 "GND" V 2305 3322 50  0000 R CNN
F 2 "" H 2300 3450 50  0001 C CNN
F 3 "" H 2300 3450 50  0001 C CNN
	1    2300 3450
	1    0    0    -1  
$EndComp
$Comp
L power:VCC #PWR031
U 1 1 620DC70E
P 2300 950
F 0 "#PWR031" H 2300 800 50  0001 C CNN
F 1 "VCC" V 2315 1078 50  0000 L CNN
F 2 "" H 2300 950 50  0001 C CNN
F 3 "" H 2300 950 50  0001 C CNN
	1    2300 950 
	1    0    0    -1  
$EndComp
Text GLabel 1700 1050 0    50   Input ~ 0
CA0
Text GLabel 1700 1150 0    50   Input ~ 0
CA1
Text GLabel 1700 1250 0    50   Input ~ 0
CA2
Text GLabel 1700 1350 0    50   Input ~ 0
CA3
Text GLabel 1700 1450 0    50   Input ~ 0
CA4
Text GLabel 1700 1550 0    50   Input ~ 0
CA5
Text GLabel 1700 1650 0    50   Input ~ 0
CA6
Text GLabel 1700 1750 0    50   Input ~ 0
CA7
Text GLabel 1700 1850 0    50   Input ~ 0
CA8
Text GLabel 1700 1950 0    50   Input ~ 0
CA9
Text GLabel 1700 2050 0    50   Input ~ 0
CA10
Text GLabel 1700 2150 0    50   Input ~ 0
CA11
Text GLabel 1700 2250 0    50   Input ~ 0
CA12
Text GLabel 1700 2350 0    50   Input ~ 0
CA13
Text GLabel 1700 2450 0    50   Input ~ 0
CA14
Text GLabel 1700 2550 0    50   Input ~ 0
CA15
NoConn ~ 5825 7275
NoConn ~ 4725 7275
Text GLabel 4550 5775 2    50   Input ~ 0
CA15
Text GLabel 4550 5675 2    50   Input ~ 0
CA14
Text GLabel 4550 5575 2    50   Input ~ 0
CA13
Text GLabel 4550 5475 2    50   Input ~ 0
CA12
Text GLabel 4550 5375 2    50   Input ~ 0
CA11
Text GLabel 4550 5275 2    50   Input ~ 0
CA10
Text GLabel 4550 5175 2    50   Input ~ 0
CA9
$Comp
L power:VCC #PWR025
U 1 1 620E7447
P 4050 4775
F 0 "#PWR025" H 4050 4625 50  0001 C CNN
F 1 "VCC" V 4065 4903 50  0000 L CNN
F 2 "" H 4050 4775 50  0001 C CNN
F 3 "" H 4050 4775 50  0001 C CNN
	1    4050 4775
	0    1    1    0   
$EndComp
$Comp
L power:VCC #PWR023
U 1 1 620E6BAC
P 4075 2750
F 0 "#PWR023" H 4075 2600 50  0001 C CNN
F 1 "VCC" V 4090 2878 50  0000 L CNN
F 2 "" H 4075 2750 50  0001 C CNN
F 3 "" H 4075 2750 50  0001 C CNN
	1    4075 2750
	0    1    1    0   
$EndComp
$Comp
L power:GND #PWR024
U 1 1 620E437E
P 4075 4350
F 0 "#PWR024" H 4075 4100 50  0001 C CNN
F 1 "GND" V 4080 4222 50  0000 R CNN
F 2 "" H 4075 4350 50  0001 C CNN
F 3 "" H 4075 4350 50  0001 C CNN
	1    4075 4350
	0    1    1    0   
$EndComp
Text GLabel 4550 5075 2    50   Input ~ 0
CA8
Text GLabel 4575 3750 2    50   Input ~ 0
CA7
Text GLabel 4575 3650 2    50   Input ~ 0
CA6
Text GLabel 4575 3550 2    50   Input ~ 0
CA5
Text GLabel 4575 3450 2    50   Input ~ 0
CA4
Text GLabel 4575 3350 2    50   Input ~ 0
CA3
Text GLabel 4575 3250 2    50   Input ~ 0
CA2
Text GLabel 4575 3150 2    50   Input ~ 0
CA1
Text GLabel 4575 3050 2    50   Input ~ 0
CA0
$Comp
L 74xx:74HC273 U5
U 1 1 620D2B9B
P 4075 3550
F 0 "U5" H 4075 3650 50  0000 C CNN
F 1 "74HC273" H 4075 3550 50  0000 C CNN
F 2 "Package_DIP:DIP-20_W7.62mm_Socket" H 4075 3550 50  0001 C CNN
F 3 "https://assets.nexperia.com/documents/data-sheet/74HC_HCT273.pdf" H 4075 3550 50  0001 C CNN
	1    4075 3550
	1    0    0    -1  
$EndComp
Text GLabel 3550 6075 0    39   Input ~ 0
~RES
Text GLabel 3575 4050 0    39   Input ~ 0
~RES
$Comp
L 74xx:74LS21 U3
U 1 1 632C3A5F
P 1925 6600
F 0 "U3" H 1925 6975 50  0000 C CNN
F 1 "74HC21" H 1925 6884 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 1925 6600 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS21" H 1925 6600 50  0001 C CNN
	1    1925 6600
	0    -1   -1   0   
$EndComp
$Comp
L 74xx:74HC04 U1
U 1 1 632C78C1
P 2575 7100
F 0 "U1" V 2621 6920 50  0000 R CNN
F 1 "74HC04" V 2530 6920 50  0000 R CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 2575 7100 50  0001 C CNN
F 3 "https://assets.nexperia.com/documents/data-sheet/74HC_HCT04.pdf" H 2575 7100 50  0001 C CNN
	1    2575 7100
	-1   0    0    1   
$EndComp
$Comp
L 74xx:74HC04 U1
U 2 1 632C8125
P 1275 7100
F 0 "U1" V 1229 7280 50  0000 L CNN
F 1 "74HC04" V 1320 7280 50  0000 L CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 1275 7100 50  0001 C CNN
F 3 "https://assets.nexperia.com/documents/data-sheet/74HC_HCT04.pdf" H 1275 7100 50  0001 C CNN
	2    1275 7100
	1    0    0    -1  
$EndComp
Wire Wire Line
	2275 7100 2075 7100
Wire Wire Line
	2075 7100 2075 6900
Wire Wire Line
	1575 7100 1775 7100
Wire Wire Line
	1775 7100 1775 6900
Text GLabel 1425 5075 3    50   Input ~ 0
A0
Text GLabel 1525 5075 3    50   Input ~ 0
A1
Text Notes 1950 7300 1    50   ~ 0
0x6x
$Comp
L 74xx:74HC04 U1
U 7 1 632CEDE4
P 8400 6225
F 0 "U1" V 8033 6225 50  0000 C CNN
F 1 "74HC04" V 8124 6225 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 8400 6225 50  0001 C CNN
F 3 "https://assets.nexperia.com/documents/data-sheet/74HC_HCT04.pdf" H 8400 6225 50  0001 C CNN
	7    8400 6225
	0    1    1    0   
$EndComp
$Comp
L 74xx:74HC04 U1
U 4 1 632CB220
P 6075 5375
F 0 "U1" H 6075 5175 50  0000 C CNN
F 1 "74HC04" H 6075 5075 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 6075 5375 50  0001 C CNN
F 3 "https://assets.nexperia.com/documents/data-sheet/74HC_HCT04.pdf" H 6075 5375 50  0001 C CNN
	4    6075 5375
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74HC04 U1
U 3 1 632C9D4B
P 2125 5575
F 0 "U1" V 2171 5395 50  0000 R CNN
F 1 "74HC04" V 2080 5395 50  0000 R CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 2125 5575 50  0001 C CNN
F 3 "https://assets.nexperia.com/documents/data-sheet/74HC_HCT04.pdf" H 2125 5575 50  0001 C CNN
	3    2125 5575
	0    -1   -1   0   
$EndComp
$Comp
L 74xx:74LS21 U3
U 3 1 632C551B
P 10200 6225
F 0 "U3" V 9833 6225 50  0000 C CNN
F 1 "74HC21" V 9924 6225 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 10200 6225 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS21" H 10200 6225 50  0001 C CNN
	3    10200 6225
	0    1    1    0   
$EndComp
$Comp
L 74xx:74LS21 U3
U 2 1 632C4DF8
P 3925 2325
F 0 "U3" H 3925 2700 50  0000 C CNN
F 1 "74HC21" H 3925 2609 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 3925 2325 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS21" H 3925 2325 50  0001 C CNN
	2    3925 2325
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR026
U 1 1 620E5C37
P 9700 6225
F 0 "#PWR026" H 9700 5975 50  0001 C CNN
F 1 "GND" V 9705 6097 50  0000 R CNN
F 2 "" H 9700 6225 50  0001 C CNN
F 3 "" H 9700 6225 50  0001 C CNN
	1    9700 6225
	0    1    1    0   
$EndComp
$Comp
L power:VCC #PWR017
U 1 1 6213BD10
P 8575 5500
F 0 "#PWR017" H 8575 5350 50  0001 C CNN
F 1 "VCC" V 8590 5628 50  0000 L CNN
F 2 "" H 8575 5500 50  0001 C CNN
F 3 "" H 8575 5500 50  0001 C CNN
	1    8575 5500
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR015
U 1 1 6213B78D
P 8175 5500
F 0 "#PWR015" H 8175 5250 50  0001 C CNN
F 1 "GND" V 8180 5372 50  0000 R CNN
F 2 "" H 8175 5500 50  0001 C CNN
F 3 "" H 8175 5500 50  0001 C CNN
	1    8175 5500
	-1   0    0    1   
$EndComp
$Comp
L power:PWR_FLAG #FLG02
U 1 1 6213B438
P 8575 5500
F 0 "#FLG02" H 8575 5575 50  0001 C CNN
F 1 "PWR_FLAG" H 8575 5673 50  0000 C CNN
F 2 "" H 8575 5500 50  0001 C CNN
F 3 "~" H 8575 5500 50  0001 C CNN
	1    8575 5500
	-1   0    0    1   
$EndComp
$Comp
L power:PWR_FLAG #FLG01
U 1 1 6213AE32
P 8175 5500
F 0 "#FLG01" H 8175 5575 50  0001 C CNN
F 1 "PWR_FLAG" H 8175 5673 50  0000 C CNN
F 2 "" H 8175 5500 50  0001 C CNN
F 3 "~" H 8175 5500 50  0001 C CNN
	1    8175 5500
	-1   0    0    1   
$EndComp
$Comp
L Device:CP C3
U 1 1 6234B7A9
P 10725 5025
F 0 "C3" V 10470 5025 50  0000 C CNN
F 1 "100uF" V 10561 5025 50  0000 C CNN
F 2 "Capacitor_THT:CP_Radial_D6.3mm_P2.50mm" H 10763 4875 50  0001 C CNN
F 3 "~" H 10725 5025 50  0001 C CNN
	1    10725 5025
	0    1    1    0   
$EndComp
$Comp
L power:GND #PWR018
U 1 1 6234CE17
P 10575 5025
F 0 "#PWR018" H 10575 4775 50  0001 C CNN
F 1 "GND" V 10580 4897 50  0000 R CNN
F 2 "" H 10575 5025 50  0001 C CNN
F 3 "" H 10575 5025 50  0001 C CNN
	1    10575 5025
	0    1    1    0   
$EndComp
$Comp
L power:VCC #PWR021
U 1 1 6234DEA4
P 10875 5025
F 0 "#PWR021" H 10875 4875 50  0001 C CNN
F 1 "VCC" V 10890 5153 50  0000 L CNN
F 2 "" H 10875 5025 50  0001 C CNN
F 3 "" H 10875 5025 50  0001 C CNN
	1    10875 5025
	0    1    1    0   
$EndComp
$Comp
L power:GND #PWR0101
U 1 1 63353D8C
P 2425 4575
F 0 "#PWR0101" H 2425 4325 50  0001 C CNN
F 1 "GND" V 2430 4447 50  0000 R CNN
F 2 "" H 2425 4575 50  0001 C CNN
F 3 "" H 2425 4575 50  0001 C CNN
	1    2425 4575
	-1   0    0    1   
$EndComp
$Comp
L power:VCC #PWR0102
U 1 1 63354B8F
P 1125 4575
F 0 "#PWR0102" H 1125 4425 50  0001 C CNN
F 1 "VCC" V 1140 4703 50  0000 L CNN
F 2 "" H 1125 4575 50  0001 C CNN
F 3 "" H 1125 4575 50  0001 C CNN
	1    1125 4575
	-1   0    0    1   
$EndComp
$Comp
L 74xx:74LS138 U2
U 1 1 63356296
P 1725 4575
F 0 "U2" V 1750 4575 50  0000 R CNN
F 1 "74HC138" V 1650 4675 50  0000 R CNN
F 2 "Package_DIP:DIP-16_W7.62mm_Socket" H 1725 4575 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS138" H 1725 4575 50  0001 C CNN
	1    1725 4575
	0    -1   -1   0   
$EndComp
Wire Wire Line
	1925 6300 1925 5075
Text GLabel 2025 5075 3    50   Input ~ 0
~IORQ
Text GLabel 1975 6900 3    50   Input ~ 0
A5
Text GLabel 1875 6900 3    50   Input ~ 0
A6
Text GLabel 975  7100 0    50   Input ~ 0
A4
Text GLabel 2875 7100 2    50   Input ~ 0
A7
Text GLabel 5725 6775 1    50   Input ~ 0
M1
Text GLabel 2125 5875 3    50   Input ~ 0
M1
Wire Wire Line
	2125 5275 2125 5075
Wire Wire Line
	1425 4075 1425 3850
NoConn ~ 1925 4075
NoConn ~ 2025 4075
NoConn ~ 2125 4075
$Comp
L power:GND #PWR0103
U 1 1 6336D8FB
P 4050 6375
F 0 "#PWR0103" H 4050 6125 50  0001 C CNN
F 1 "GND" V 4055 6247 50  0000 R CNN
F 2 "" H 4050 6375 50  0001 C CNN
F 3 "" H 4050 6375 50  0001 C CNN
	1    4050 6375
	0    1    1    0   
$EndComp
$Comp
L 74xx:74HC02 U4
U 1 1 6336F185
P 3275 3950
F 0 "U4" H 3075 4275 50  0000 C CNN
F 1 "74HC02" H 3075 4175 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 3275 3950 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74hc02" H 3275 3950 50  0001 C CNN
	1    3275 3950
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74HC02 U4
U 2 1 633716FD
P 3250 5975
F 0 "U4" H 3125 6300 50  0000 C CNN
F 1 "74HC02" H 3125 6200 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 3250 5975 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74hc02" H 3250 5975 50  0001 C CNN
	2    3250 5975
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74HC02 U4
U 4 1 633766D5
P 5475 5175
F 0 "U4" H 5475 5500 50  0000 C CNN
F 1 "74HC02" H 5475 5409 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 5475 5175 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74hc02" H 5475 5175 50  0001 C CNN
	4    5475 5175
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74HC02 U4
U 5 1 63377939
P 10200 5575
F 0 "U4" V 9833 5575 50  0000 C CNN
F 1 "74HC02" V 9924 5575 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 10200 5575 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74hc02" H 10200 5575 50  0001 C CNN
	5    10200 5575
	0    1    1    0   
$EndComp
Wire Wire Line
	2975 3850 1425 3850
Wire Wire Line
	1525 4075 1525 3925
Wire Wire Line
	1525 3925 2725 3925
Wire Wire Line
	2725 3925 2725 5875
Wire Wire Line
	2725 5875 2950 5875
Text GLabel 2975 4050 0    39   Input ~ 0
~WR
Text GLabel 2950 6075 0    39   Input ~ 0
~WR
Text GLabel 1575 3350 0    39   Input ~ 0
~RD
Wire Wire Line
	1575 3350 1700 3350
$Comp
L power:GND #PWR0104
U 1 1 633D7C57
P 9700 5575
F 0 "#PWR0104" H 9700 5325 50  0001 C CNN
F 1 "GND" V 9705 5447 50  0000 R CNN
F 2 "" H 9700 5575 50  0001 C CNN
F 3 "" H 9700 5575 50  0001 C CNN
	1    9700 5575
	0    1    1    0   
$EndComp
$Comp
L power:GND #PWR0105
U 1 1 633D82B1
P 7900 6225
F 0 "#PWR0105" H 7900 5975 50  0001 C CNN
F 1 "GND" V 7905 6097 50  0000 R CNN
F 2 "" H 7900 6225 50  0001 C CNN
F 3 "" H 7900 6225 50  0001 C CNN
	1    7900 6225
	0    1    1    0   
$EndComp
$Comp
L power:VCC #PWR0106
U 1 1 633D8B28
P 10700 6225
F 0 "#PWR0106" H 10700 6075 50  0001 C CNN
F 1 "VCC" V 10715 6353 50  0000 L CNN
F 2 "" H 10700 6225 50  0001 C CNN
F 3 "" H 10700 6225 50  0001 C CNN
	1    10700 6225
	0    1    1    0   
$EndComp
$Comp
L power:VCC #PWR0107
U 1 1 633D9552
P 10700 5575
F 0 "#PWR0107" H 10700 5425 50  0001 C CNN
F 1 "VCC" V 10715 5703 50  0000 L CNN
F 2 "" H 10700 5575 50  0001 C CNN
F 3 "" H 10700 5575 50  0001 C CNN
	1    10700 5575
	0    1    1    0   
$EndComp
$Comp
L power:VCC #PWR0108
U 1 1 633D9E03
P 8900 6225
F 0 "#PWR0108" H 8900 6075 50  0001 C CNN
F 1 "VCC" V 8915 6353 50  0000 L CNN
F 2 "" H 8900 6225 50  0001 C CNN
F 3 "" H 8900 6225 50  0001 C CNN
	1    8900 6225
	0    1    1    0   
$EndComp
Text GLabel 5125 6775 1    50   Input ~ 0
D7
Text GLabel 5025 6775 1    50   Input ~ 0
D5
Text GLabel 4925 6775 1    50   Input ~ 0
D3
Text GLabel 4825 6775 1    50   Input ~ 0
D1
Text GLabel 2900 1050 2    50   Input ~ 0
D0
Text GLabel 2900 1450 2    50   Input ~ 0
D4
Text GLabel 2900 1650 2    50   Input ~ 0
D6
Text GLabel 2900 1250 2    50   Input ~ 0
D2
Text GLabel 2900 1750 2    50   Input ~ 0
D7
Text GLabel 2900 1550 2    50   Input ~ 0
D5
Text GLabel 2900 1350 2    50   Input ~ 0
D3
Text GLabel 2900 1150 2    50   Input ~ 0
D1
Text GLabel 3575 3050 0    50   Input ~ 0
D0
Text GLabel 3575 3450 0    50   Input ~ 0
D4
Text GLabel 3575 3650 0    50   Input ~ 0
D6
Text GLabel 3575 3250 0    50   Input ~ 0
D2
Text GLabel 3575 3750 0    50   Input ~ 0
D7
Text GLabel 3575 3550 0    50   Input ~ 0
D5
Text GLabel 3575 3350 0    50   Input ~ 0
D3
Text GLabel 3575 3150 0    50   Input ~ 0
D1
Text GLabel 3550 5075 0    50   Input ~ 0
D0
Text GLabel 3550 5475 0    50   Input ~ 0
D4
Text GLabel 3550 5675 0    50   Input ~ 0
D6
Text GLabel 3550 5275 0    50   Input ~ 0
D2
Text GLabel 3550 5775 0    50   Input ~ 0
D7
Text GLabel 3550 5575 0    50   Input ~ 0
D5
Text GLabel 3550 5375 0    50   Input ~ 0
D3
Text GLabel 3550 5175 0    50   Input ~ 0
D1
Text GLabel 6375 4175 0    50   Input ~ 0
D0
Text GLabel 6375 4375 0    50   Input ~ 0
D2
Text GLabel 6375 4275 0    50   Input ~ 0
D1
Text GLabel 5175 5275 0    39   Input ~ 0
~WR
Wire Wire Line
	2650 4000 2650 4500
Wire Wire Line
	2650 4500 4975 4500
Wire Wire Line
	4975 4500 4975 5075
Wire Wire Line
	4975 5075 5175 5075
Text GLabel 5775 5375 0    39   Input ~ 0
~RES
Text GLabel 5325 7275 3    50   Input ~ 0
A2
Text GLabel 1625 5075 3    50   Input ~ 0
A2
$Comp
L Device:C C1
U 1 1 634D685B
P 10700 825
F 0 "C1" V 10448 825 50  0000 C CNN
F 1 "0.1uF" V 10539 825 50  0000 C CNN
F 2 "Capacitor_THT:C_Disc_D5.0mm_W2.5mm_P5.00mm" H 10738 675 50  0001 C CNN
F 3 "~" H 10700 825 50  0001 C CNN
	1    10700 825 
	0    1    1    0   
$EndComp
$Comp
L Device:C C2
U 1 1 634D7D2B
P 10700 1225
F 0 "C2" V 10448 1225 50  0000 C CNN
F 1 "0.1uF" V 10539 1225 50  0000 C CNN
F 2 "Capacitor_THT:C_Disc_D5.0mm_W2.5mm_P5.00mm" H 10738 1075 50  0001 C CNN
F 3 "~" H 10700 1225 50  0001 C CNN
	1    10700 1225
	0    1    1    0   
$EndComp
$Comp
L Device:C C4
U 1 1 634DBA00
P 10700 1625
F 0 "C4" V 10448 1625 50  0000 C CNN
F 1 "0.1uF" V 10539 1625 50  0000 C CNN
F 2 "Capacitor_THT:C_Disc_D5.0mm_W2.5mm_P5.00mm" H 10738 1475 50  0001 C CNN
F 3 "~" H 10700 1625 50  0001 C CNN
	1    10700 1625
	0    1    1    0   
$EndComp
$Comp
L Device:C C5
U 1 1 634DBA06
P 10700 2025
F 0 "C5" V 10448 2025 50  0000 C CNN
F 1 "0.1uF" V 10539 2025 50  0000 C CNN
F 2 "Capacitor_THT:C_Disc_D5.0mm_W2.5mm_P5.00mm" H 10738 1875 50  0001 C CNN
F 3 "~" H 10700 2025 50  0001 C CNN
	1    10700 2025
	0    1    1    0   
$EndComp
$Comp
L Device:C C6
U 1 1 634DFFB9
P 10700 2425
F 0 "C6" V 10448 2425 50  0000 C CNN
F 1 "0.1uF" V 10539 2425 50  0000 C CNN
F 2 "Capacitor_THT:C_Disc_D5.0mm_W2.5mm_P5.00mm" H 10738 2275 50  0001 C CNN
F 3 "~" H 10700 2425 50  0001 C CNN
	1    10700 2425
	0    1    1    0   
$EndComp
$Comp
L Device:C C7
U 1 1 634DFFBF
P 10700 2825
F 0 "C7" V 10448 2825 50  0000 C CNN
F 1 "0.1uF" V 10539 2825 50  0000 C CNN
F 2 "Capacitor_THT:C_Disc_D5.0mm_W2.5mm_P5.00mm" H 10738 2675 50  0001 C CNN
F 3 "~" H 10700 2825 50  0001 C CNN
	1    10700 2825
	0    1    1    0   
$EndComp
$Comp
L Device:C C8
U 1 1 634DFFC5
P 10700 3225
F 0 "C8" V 10448 3225 50  0000 C CNN
F 1 "0.1uF" V 10539 3225 50  0000 C CNN
F 2 "Capacitor_THT:C_Disc_D5.0mm_W2.5mm_P5.00mm" H 10738 3075 50  0001 C CNN
F 3 "~" H 10700 3225 50  0001 C CNN
	1    10700 3225
	0    1    1    0   
$EndComp
$Comp
L Device:C C9
U 1 1 634DFFCB
P 10700 3625
F 0 "C9" V 10448 3625 50  0000 C CNN
F 1 "0.1uF" V 10539 3625 50  0000 C CNN
F 2 "Capacitor_THT:C_Disc_D5.0mm_W2.5mm_P5.00mm" H 10738 3475 50  0001 C CNN
F 3 "~" H 10700 3625 50  0001 C CNN
	1    10700 3625
	0    1    1    0   
$EndComp
Wire Wire Line
	10550 3625 10450 3625
Wire Wire Line
	10450 3625 10450 3225
Wire Wire Line
	10450 825  10550 825 
Wire Wire Line
	10550 1225 10450 1225
Connection ~ 10450 1225
Wire Wire Line
	10450 1225 10450 825 
Wire Wire Line
	10450 1625 10550 1625
Connection ~ 10450 1625
Wire Wire Line
	10450 1625 10450 1225
Wire Wire Line
	10550 2025 10450 2025
Connection ~ 10450 2025
Wire Wire Line
	10450 2025 10450 1625
Wire Wire Line
	10450 2425 10550 2425
Connection ~ 10450 2425
Wire Wire Line
	10450 2425 10450 2225
Wire Wire Line
	10550 2825 10450 2825
Connection ~ 10450 2825
Wire Wire Line
	10450 2825 10450 2425
Wire Wire Line
	10450 3225 10550 3225
Connection ~ 10450 3225
Wire Wire Line
	10450 3225 10450 2825
Wire Wire Line
	10850 3625 10975 3625
Wire Wire Line
	10975 3625 10975 3225
Wire Wire Line
	10975 825  10850 825 
Wire Wire Line
	10850 1225 10975 1225
Connection ~ 10975 1225
Wire Wire Line
	10975 1225 10975 825 
Wire Wire Line
	10850 1625 10975 1625
Connection ~ 10975 1625
Wire Wire Line
	10975 1625 10975 1225
Wire Wire Line
	10850 2025 10975 2025
Connection ~ 10975 2025
Wire Wire Line
	10975 2025 10975 1625
Wire Wire Line
	10850 2425 10975 2425
Connection ~ 10975 2425
Wire Wire Line
	10975 2425 10975 2225
Wire Wire Line
	10975 2825 10850 2825
Connection ~ 10975 2825
Wire Wire Line
	10975 2825 10975 2425
Wire Wire Line
	10850 3225 10975 3225
Connection ~ 10975 3225
Wire Wire Line
	10975 3225 10975 2825
$Comp
L power:GND #PWR0117
U 1 1 6350DBE5
P 10450 2225
F 0 "#PWR0117" H 10450 1975 50  0001 C CNN
F 1 "GND" V 10455 2097 50  0000 R CNN
F 2 "" H 10450 2225 50  0001 C CNN
F 3 "" H 10450 2225 50  0001 C CNN
	1    10450 2225
	0    1    1    0   
$EndComp
Connection ~ 10450 2225
Wire Wire Line
	10450 2225 10450 2025
$Comp
L power:VCC #PWR0118
U 1 1 6350E208
P 10975 2225
F 0 "#PWR0118" H 10975 2075 50  0001 C CNN
F 1 "VCC" V 10990 2353 50  0000 L CNN
F 2 "" H 10975 2225 50  0001 C CNN
F 3 "" H 10975 2225 50  0001 C CNN
	1    10975 2225
	0    1    1    0   
$EndComp
Connection ~ 10975 2225
Wire Wire Line
	10975 2225 10975 2025
$Comp
L Device:C C10
U 1 1 635786B3
P 10700 4025
F 0 "C10" V 10448 4025 50  0000 C CNN
F 1 "0.1uF" V 10539 4025 50  0000 C CNN
F 2 "Capacitor_THT:C_Disc_D5.0mm_W2.5mm_P5.00mm" H 10738 3875 50  0001 C CNN
F 3 "~" H 10700 4025 50  0001 C CNN
	1    10700 4025
	0    1    1    0   
$EndComp
Wire Wire Line
	10850 4025 10975 4025
Wire Wire Line
	10975 4025 10975 3625
Connection ~ 10975 3625
Wire Wire Line
	10550 4025 10450 4025
Wire Wire Line
	10450 4025 10450 3625
Connection ~ 10450 3625
Wire Notes Line
	4525 7675 6825 7675
Wire Notes Line
	6825 7675 6825 6325
Wire Notes Line
	6825 6325 4525 6325
Wire Notes Line
	4525 6325 4525 7675
Text Notes 5925 6450 0    50   ~ 0
PORT 2 cartridge slot
Text Notes 4450 4475 0    50   ~ 0
0x63
Text Notes 3625 4925 0    50   ~ 0
Upper\naddress\nbyte
Text Notes 3675 2900 0    50   ~ 0
Lower\naddress\nbyte
Text Notes 2475 3850 0    50   ~ 0
0x60
Text Notes 2225 3925 0    50   ~ 0
0x61
Text Notes 1850 3750 2    50   ~ 0
0x62
Text Notes 2025 7675 0    50   ~ 0
I/O Control lines for the P2000T\non user port 2 are tied to\n0x4x and 0x6x. The latter is\nused for this cartridge
$Comp
L Memory_Flash:SST39SF040 U7
U 1 1 633B24D5
P 2300 2250
F 0 "U7" H 2300 3731 50  0000 C CNN
F 1 "SST39SF040" H 2350 2250 50  0000 C CNN
F 2 "Package_LCC:PLCC-32_THT-Socket" H 2300 2550 50  0001 C CNN
F 3 "http://ww1.microchip.com/downloads/en/DeviceDoc/25022B.pdf" H 2300 2550 50  0001 C CNN
	1    2300 2250
	1    0    0    -1  
$EndComp
Text GLabel 1700 2650 0    50   Input ~ 0
CA16
Text GLabel 1700 2750 0    50   Input ~ 0
CA17
Text GLabel 1700 2850 0    50   Input ~ 0
CA18
$Comp
L power:GND #PWR012
U 1 1 633BEF9A
P 6875 5675
F 0 "#PWR012" H 6875 5425 50  0001 C CNN
F 1 "GND" V 6880 5547 50  0000 R CNN
F 2 "" H 6875 5675 50  0001 C CNN
F 3 "" H 6875 5675 50  0001 C CNN
	1    6875 5675
	1    0    0    -1  
$EndComp
$Comp
L power:VCC #PWR011
U 1 1 633BFB64
P 6875 3875
F 0 "#PWR011" H 6875 3725 50  0001 C CNN
F 1 "VCC" V 6890 4003 50  0000 L CNN
F 2 "" H 6875 3875 50  0001 C CNN
F 3 "" H 6875 3875 50  0001 C CNN
	1    6875 3875
	0    1    1    0   
$EndComp
Text GLabel 1575 3050 0    39   Input ~ 0
~WR
Wire Wire Line
	1575 3050 1700 3050
Text Notes 550  5800 0    50   ~ 0
Access table\n-------------\n0x60: Address low byte (W)\n0x61: Address high byte (W)\n0x62: ROM chip; lower 64kb (R/W)\n0x63: Bank selection (W)\n0x64: RAM chip (R/W)
$Comp
L 74xx:74HC04 U1
U 6 1 632CDCE0
P 3225 2475
F 0 "U1" H 3225 2300 50  0000 C CNN
F 1 "74HC04" H 3225 2225 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 3225 2475 50  0001 C CNN
F 3 "https://assets.nexperia.com/documents/data-sheet/74HC_HCT04.pdf" H 3225 2475 50  0001 C CNN
	6    3225 2475
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74HC02 U4
U 3 1 633C971B
P 1150 3250
F 0 "U4" H 1150 3050 50  0000 C CNN
F 1 "74HC02" H 1125 2950 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 1150 3250 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74hc02" H 1150 3250 50  0001 C CNN
	3    1150 3250
	1    0    0    -1  
$EndComp
NoConn ~ 5325 6775
$Comp
L 74xx:74LS173 U9
U 1 1 634353B9
P 6875 4775
F 0 "U9" H 6875 5856 50  0000 C CNN
F 1 "74HC173" H 6875 5765 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm_Socket" H 6875 4775 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS173" H 6875 4775 50  0001 C CNN
	1    6875 4775
	1    0    0    -1  
$EndComp
Text GLabel 7375 4375 2    50   Input ~ 0
CA18
Text GLabel 7375 4275 2    50   Input ~ 0
CA17
Text GLabel 7375 4175 2    50   Input ~ 0
CA16
$Comp
L power:GND #PWR02
U 1 1 6344E0CC
P 6250 4725
F 0 "#PWR02" H 6250 4475 50  0001 C CNN
F 1 "GND" V 6255 4597 50  0000 R CNN
F 2 "" H 6250 4725 50  0001 C CNN
F 3 "" H 6250 4725 50  0001 C CNN
	1    6250 4725
	0    1    1    0   
$EndComp
Connection ~ 6375 4725
Wire Wire Line
	6375 4675 6375 4725
Connection ~ 6375 4775
Wire Wire Line
	6375 4775 6375 4975
Connection ~ 6375 4975
Wire Wire Line
	6375 4975 6375 5075
Wire Wire Line
	6375 4725 6250 4725
Wire Wire Line
	6375 4725 6375 4775
Text Notes 6275 4025 0    50   ~ 0
ROM bank\nselection\nregister
$Comp
L 74xx:74HC04 U1
U 5 1 634EABAA
P 4525 2325
F 0 "U1" H 4525 2642 50  0000 C CNN
F 1 "74HC04" H 4525 2551 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket" H 4525 2325 50  0001 C CNN
F 3 "https://assets.nexperia.com/documents/data-sheet/74HC_HCT04.pdf" H 4525 2325 50  0001 C CNN
	5    4525 2325
	1    0    0    -1  
$EndComp
Wire Wire Line
	1725 4075 1725 4000
Wire Wire Line
	1725 4000 2650 4000
$Comp
L 74xx:74HC273 U6
U 1 1 620D55F0
P 4050 5575
F 0 "U6" H 4050 6556 50  0000 C CNN
F 1 "74HC273" H 4050 6465 50  0000 C CNN
F 2 "Package_DIP:DIP-20_W7.62mm_Socket" H 4050 5575 50  0001 C CNN
F 3 "https://assets.nexperia.com/documents/data-sheet/74HC_HCT273.pdf" H 4050 5575 50  0001 C CNN
	1    4050 5575
	1    0    0    -1  
$EndComp
$Comp
L Device:C C11
U 1 1 6355339B
P 10700 4425
F 0 "C11" V 10448 4425 50  0000 C CNN
F 1 "0.1uF" V 10539 4425 50  0000 C CNN
F 2 "Capacitor_THT:C_Disc_D5.0mm_W2.5mm_P5.00mm" H 10738 4275 50  0001 C CNN
F 3 "~" H 10700 4425 50  0001 C CNN
	1    10700 4425
	0    1    1    0   
$EndComp
Wire Wire Line
	10450 4025 10450 4425
Wire Wire Line
	10450 4425 10550 4425
Connection ~ 10450 4025
Wire Wire Line
	10850 4425 10975 4425
Wire Wire Line
	10975 4425 10975 4025
Connection ~ 10975 4025
Text GLabel 6375 4475 0    50   Input ~ 0
D3
Wire Wire Line
	5775 5175 6375 5175
Text GLabel 7375 4475 2    50   Input ~ 0
CA19
NoConn ~ 1825 4075
$Comp
L power:GND #PWR0109
U 1 1 634D37C8
P 5975 3425
F 0 "#PWR0109" H 5975 3175 50  0001 C CNN
F 1 "GND" V 5980 3297 50  0000 R CNN
F 2 "" H 5975 3425 50  0001 C CNN
F 3 "" H 5975 3425 50  0001 C CNN
	1    5975 3425
	1    0    0    -1  
$EndComp
$Comp
L power:VCC #PWR0110
U 1 1 634D37CE
P 5975 925
F 0 "#PWR0110" H 5975 775 50  0001 C CNN
F 1 "VCC" V 5990 1053 50  0000 L CNN
F 2 "" H 5975 925 50  0001 C CNN
F 3 "" H 5975 925 50  0001 C CNN
	1    5975 925 
	1    0    0    -1  
$EndComp
Text GLabel 5375 1025 0    50   Input ~ 0
CA0
Text GLabel 5375 1125 0    50   Input ~ 0
CA1
Text GLabel 5375 1225 0    50   Input ~ 0
CA2
Text GLabel 5375 1325 0    50   Input ~ 0
CA3
Text GLabel 5375 1425 0    50   Input ~ 0
CA4
Text GLabel 5375 1525 0    50   Input ~ 0
CA5
Text GLabel 5375 1625 0    50   Input ~ 0
CA6
Text GLabel 5375 1725 0    50   Input ~ 0
CA7
Text GLabel 5375 1825 0    50   Input ~ 0
CA8
Text GLabel 5375 1925 0    50   Input ~ 0
CA9
Text GLabel 5375 2025 0    50   Input ~ 0
CA10
Text GLabel 5375 2125 0    50   Input ~ 0
CA11
Text GLabel 5375 2225 0    50   Input ~ 0
CA12
Text GLabel 5375 2325 0    50   Input ~ 0
CA13
Text GLabel 5375 2425 0    50   Input ~ 0
CA14
Text GLabel 5375 2525 0    50   Input ~ 0
CA15
Text GLabel 5250 3325 0    39   Input ~ 0
~RD
Wire Wire Line
	5250 3325 5375 3325
Text GLabel 6575 1025 2    50   Input ~ 0
D0
Text GLabel 6575 1425 2    50   Input ~ 0
D4
Text GLabel 6575 1625 2    50   Input ~ 0
D6
Text GLabel 6575 1225 2    50   Input ~ 0
D2
Text GLabel 6575 1725 2    50   Input ~ 0
D7
Text GLabel 6575 1525 2    50   Input ~ 0
D5
Text GLabel 6575 1325 2    50   Input ~ 0
D3
Text GLabel 6575 1125 2    50   Input ~ 0
D1
$Comp
L Memory_Flash:SST39SF040 U8
U 1 1 634D37F1
P 5975 2225
F 0 "U8" H 5975 3706 50  0000 C CNN
F 1 "SST39SF040" H 6025 2225 50  0000 C CNN
F 2 "Package_LCC:PLCC-32_THT-Socket" H 5975 2525 50  0001 C CNN
F 3 "http://ww1.microchip.com/downloads/en/DeviceDoc/25022B.pdf" H 5975 2525 50  0001 C CNN
	1    5975 2225
	1    0    0    -1  
$EndComp
Text GLabel 5375 2625 0    50   Input ~ 0
CA16
Text GLabel 5375 2725 0    50   Input ~ 0
CA17
Text GLabel 5375 2825 0    50   Input ~ 0
CA18
Text GLabel 5250 3025 0    39   Input ~ 0
~WR
Wire Wire Line
	5250 3025 5375 3025
Wire Wire Line
	1625 4075 1625 3775
Wire Wire Line
	1625 3675 650  3675
Wire Wire Line
	650  3675 650  3350
Wire Wire Line
	1450 3250 1700 3250
Wire Wire Line
	650  3350 850  3350
Wire Wire Line
	1625 3775 2850 3775
Wire Wire Line
	2850 3775 2850 2475
Connection ~ 1625 3775
Wire Wire Line
	1625 3775 1625 3675
Wire Wire Line
	3525 2475 3575 2475
Wire Wire Line
	3575 2475 3575 2375
Wire Wire Line
	3575 2375 3625 2375
Connection ~ 3575 2475
Wire Wire Line
	3575 2475 3625 2475
Wire Wire Line
	3550 2225 3625 2225
Wire Wire Line
	3625 2225 3625 2175
Wire Wire Line
	3625 2225 3625 2275
Connection ~ 3625 2225
Wire Wire Line
	2850 2475 2925 2475
Wire Wire Line
	4825 2325 5000 2325
Wire Wire Line
	5000 2325 5000 3225
Wire Wire Line
	5000 3225 5375 3225
Text GLabel 850  3150 0    50   Input ~ 0
CA19
Text GLabel 3550 2225 0    50   Input ~ 0
CA19
$EndSCHEMATC
