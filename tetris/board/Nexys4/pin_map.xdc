## This file is a general .xdc for the Nexys4 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

### Clock signal
# Sch name = CLK100MHZ, Bank = 35, Pin name = IO_L12P_T1_MRCC_35
set_property PACKAGE_PIN  E3        [get_ports clock_i]
set_property IOSTANDARD   LVCMOS33  [get_ports clock_i]

create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clock_i]



### 7 segment display
# Sch name = CA, Bank = 34, Pin name = IO_L2N_T0_34
set_property PACKAGE_PIN  L3        [get_ports {cathode_o[0]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {cathode_o[0]}]
# Sch name = CB, Bank = 34, Pin name = IO_L3N_T0_DQS_34
set_property PACKAGE_PIN  N1        [get_ports {cathode_o[1]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {cathode_o[1]}]
# Sch name = CC, Bank = 34, Pin name = IO_L6N_T0_VREF_34
set_property PACKAGE_PIN  L5        [get_ports {cathode_o[2]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {cathode_o[2]}]
# Sch name = CD, Bank = 34, Pin name = IO_L5N_T0_34
set_property PACKAGE_PIN  L4        [get_ports {cathode_o[3]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {cathode_o[3]}]
# Sch name = CE, Bank = 34, Pin name = IO_L2P_T0_34
set_property PACKAGE_PIN  K3        [get_ports {cathode_o[4]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {cathode_o[4]}]
# Sch name = CF, Bank = 34, Pin name = IO_L4N_T0_34
set_property PACKAGE_PIN  M2        [get_ports {cathode_o[5]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {cathode_o[5]}]
# Sch name = CG, Bank = 34, Pin name = IO_L6P_T0_34
set_property PACKAGE_PIN  L6        [get_ports {cathode_o[6]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {cathode_o[6]}]
# Sch name = DP, Bank = 34, Pin name = IO_L16P_T2_34
#set_property PACKAGE_PIN  M4        [get_ports dp]
#set_property IOSTANDARD   LVCMOS33  [get_ports dp]

# Sch name = AN0, Bank = 34, Pin name = IO_L18N_T2_34
set_property PACKAGE_PIN  N6        [get_ports {anode_o[0]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {anode_o[0]}]
# Sch name = AN1, Bank = 34, Pin name = IO_L18P_T2_34,
set_property PACKAGE_PIN  M6        [get_ports {anode_o[1]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {anode_o[1]}]
# Sch name = AN2, Bank = 34, Pin name = IO_L4P_T0_34
set_property PACKAGE_PIN  M3        [get_ports {anode_o[2]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {anode_o[2]}]
# Sch name = AN3, Bank = 34, Pin name = IO_L13_T2_MRCC_34
set_property PACKAGE_PIN  N5        [get_ports {anode_o[3]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {anode_o[3]}]
# Sch name = AN4, Bank = 34, Pin name = IO_L3P_T0_DQS_34
set_property PACKAGE_PIN  N2        [get_ports {anode_o[4]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {anode_o[4]}]
# Sch name = AN5, Bank = 34, Pin name = IO_L16N_T2_34
set_property PACKAGE_PIN  N4        [get_ports {anode_o[5]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {anode_o[5]}]
# Sch name = AN6, Bank = 34, Pin name = IO_L1P_T0_34
set_property PACKAGE_PIN  L1        [get_ports {anode_o[6]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {anode_o[6]}]
# Sch name = AN7, Bank = 34, Pin name = IO_L1N_T034
set_property PACKAGE_PIN  M1        [get_ports {anode_o[7]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {anode_o[7]}]



### Buttons
# Sch name = CPU_RESET, Bank = 15, Pin name = IO_L3P_T0_DQS_AD1P_15
set_property PACKAGE_PIN  C12       [get_ports reset_low_i]
set_property IOSTANDARD   LVCMOS33  [get_ports reset_low_i]
# Sch name = BTNC, Bank = 15, Pin name = IO_L11N_T1_SRCC_15
set_property PACKAGE_PIN  E16       [get_ports btnC_i]
set_property IOSTANDARD   LVCMOS33  [get_ports btnC_i]
# Sch name = BTNU, Bank = 15, Pin name = IO_L14P_T2_SRCC_15
set_property PACKAGE_PIN  F15       [get_ports btnU_i]
set_property IOSTANDARD   LVCMOS33  [get_ports btnU_i]
# Sch name = BTNL, Bank = CONFIG, Pin name = IO_L15N_T2_DQS_DOUT_CSO_B_14
set_property PACKAGE_PIN  T16       [get_ports btnL_i]
set_property IOSTANDARD   LVCMOS33  [get_ports btnL_i]
# Sch name = BTNR, Bank = 14, Pin name = IO_25_14
set_property PACKAGE_PIN  R10       [get_ports btnR_i]
set_property IOSTANDARD   LVCMOS33  [get_ports btnR_i]
# Sch name = BTND, Bank = 14, Pin name = IO_L21P_T3_DQS_14
set_property PACKAGE_PIN  V10       [get_ports btnD_i]
set_property IOSTANDARD   LVCMOS33  [get_ports btnD_i]



### VGA Connector
# Sch name = VGA_R0, Bank = 35, Pin name = IO_L8N_T1_AD14N_35
set_property PACKAGE_PIN  A3        [get_ports {display_o[c][red][0]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {display_o[c][red][0]}]
# Sch name = VGA_R1, Bank = 35, Pin name = IO_L7N_T1_AD6N_35
set_property PACKAGE_PIN  B4        [get_ports {display_o[c][red][1]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {display_o[c][red][1]}]
# Sch name = VGA_R2, Bank = 35, Pin name = IO_L1N_T0_AD4N_35
set_property PACKAGE_PIN  C5        [get_ports {display_o[c][red][2]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {display_o[c][red][2]}]
# Sch name = VGA_R3, Bank = 35, Pin name = IO_L8P_T1_AD14P_35
set_property PACKAGE_PIN  A4        [get_ports {display_o[c][red][3]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {display_o[c][red][3]}]

# Sch name = VGA_B0, Bank = 35, Pin name = IO_L2P_T0_AD12P_35
set_property PACKAGE_PIN  B7        [get_ports {display_o[c][blue][0]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {display_o[c][blue][0]}]
# Sch name = VGA_B1, Bank = 35, Pin name = IO_L4N_T0_35
set_property PACKAGE_PIN  C7        [get_ports {display_o[c][blue][1]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {display_o[c][blue][1]}]
# Sch name = VGA_B2, Bank = 35, Pin name = IO_L6N_T0_VREF_35
set_property PACKAGE_PIN  D7        [get_ports {display_o[c][blue][2]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {display_o[c][blue][2]}]
# Sch name = VGA_B3, Bank = 35, Pin name = IO_L4P_T0_35
set_property PACKAGE_PIN  D8        [get_ports {display_o[c][blue][3]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {display_o[c][blue][3]}]

# Sch name = VGA_G0, Bank = 35, Pin name = IO_L1P_T0_AD4P_35
set_property PACKAGE_PIN  C6        [get_ports {display_o[c][green][0]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {display_o[c][green][0]}]
# Sch name = VGA_G1, Bank = 35, Pin name = IO_L3N_T0_DQS_AD5N_35
set_property PACKAGE_PIN  A5        [get_ports {display_o[c][green][1]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {display_o[c][green][1]}]
# Sch name = VGA_G2, Bank = 35, Pin name = IO_L2N_T0_AD12N_35
set_property PACKAGE_PIN  B6        [get_ports {display_o[c][green][2]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {display_o[c][green][2]}]
# Sch name = VGA_G3, Bank = 35, Pin name = IO_L3P_T0_DQS_AD5P_35
set_property PACKAGE_PIN  A6        [get_ports {display_o[c][green][3]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {display_o[c][green][3]}]

# Sch name = VGA_HS, Bank = 15, Pin name = IO_L4P_T0_15
set_property PACKAGE_PIN  B11       [get_ports {display_o[sync][h]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {display_o[sync][h]}]
# Sch name = VGA_VS, Bank = 15, Pin name = IO_L3N_T0_DQS_AD1N_15
set_property PACKAGE_PIN  B12       [get_ports {display_o[sync][v]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {display_o[sync][v]}]
