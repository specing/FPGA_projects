## This file is a general .xdc for the Nexys4 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

### Clock signal
# Sch name = CLK100MHZ, Bank = 35, Pin name = IO_L12P_T1_MRCC_35
set_property PACKAGE_PIN  E3        [get_ports clock_i]
set_property IOSTANDARD   LVCMOS33  [get_ports clock_i]

create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clock_i]


### Switches
# Sch name = SW0,  Bank = 34, Pin name = IO_L21P_T3_DQS_34
set_property PACKAGE_PIN  U9        [get_ports {switches_i[0]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {switches_i[0]}]
# Sch name = SW1,  Bank = 34, Pin name = IO_25_34
set_property PACKAGE_PIN  U8        [get_ports {switches_i[1]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {switches_i[1]}]
# Sch name = SW2,  Bank = 34, Pin name = IO_L23P_T3_34
set_property PACKAGE_PIN  R7        [get_ports {switches_i[2]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {switches_i[2]}]
# Sch name = SW3,  Bank = 34, Pin name = IO_L19P_T3_34
set_property PACKAGE_PIN  R6        [get_ports {switches_i[3]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {switches_i[3]}]
# Sch name = SW4,  Bank = 34, Pin name = IO_L19N_T3_VREF_34
set_property PACKAGE_PIN  R5        [get_ports {switches_i[4]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {switches_i[4]}]
# Sch name = SW5,  Bank = 34, Pin name = IO_L20P_T3_34
set_property PACKAGE_PIN  V7        [get_ports {switches_i[5]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {switches_i[5]}]
# Sch name = SW6,  Bank = 34, Pin name = IO_L20N_T3_34
set_property PACKAGE_PIN  V6        [get_ports {switches_i[6]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {switches_i[6]}]
# Sch name = SW7,  Bank = 34, Pin name = IO_L10P_T1_34
set_property PACKAGE_PIN  V5        [get_ports {switches_i[7]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {switches_i[7]}]
# Sch name = SW8,  Bank = 34, Pin name = IO_L8P_T1-34
set_property PACKAGE_PIN  U4        [get_ports {switches_i[8]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {switches_i[8]}]
# Sch name = SW9,  Bank = 34, Pin name = IO_L9N_T1_DQS_34
set_property PACKAGE_PIN  V2        [get_ports {switches_i[9]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {switches_i[9]}]
# Sch name = SW10, Bank = 34, Pin name = IO_L9P_T1_DQS_34
set_property PACKAGE_PIN  U2        [get_ports {switches_i[10]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {switches_i[10]}]
# Sch name = SW11, Bank = 34, Pin name = IO_L11N_T1_MRCC_34
set_property PACKAGE_PIN  T3        [get_ports {switches_i[11]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {switches_i[11]}]
# Sch name = SW12, Bank = 34, Pin name = IO_L17N_T2_34
set_property PACKAGE_PIN  T1        [get_ports {switches_i[12]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {switches_i[12]}]
# Sch name = SW13, Bank = 34, Pin name = IO_L11P_T1_SRCC_34
set_property PACKAGE_PIN  R3        [get_ports {switches_i[13]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {switches_i[13]}]
# Sch name = SW14, Bank = 34, Pin name = IO_L14N_T2_SRCC_34
set_property PACKAGE_PIN  P3        [get_ports {switches_i[14]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {switches_i[14]}]
# Sch name = SW15, Bank = 34, Pin name = IO_L14P_T2_SRCC_34
set_property PACKAGE_PIN  P4        [get_ports {switches_i[15]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {switches_i[15]}]



### LEDs
# Sch name = LED0,  Bank = 34, Pin name = IO_L24N_T3_34,
set_property PACKAGE_PIN  T8        [get_ports {led_o[0]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {led_o[0]}]
# Sch name = LED1,  Bank = 34, Pin name = IO_L21N_T3_DQS_34,
set_property PACKAGE_PIN  V9        [get_ports {led_o[1]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {led_o[1]}]
# Sch name = LED2,  Bank = 34, Pin name = IO_L24P_T3_34,
set_property PACKAGE_PIN  R8        [get_ports {led_o[2]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {led_o[2]}]
# Sch name = LED3,  Bank = 34, Pin name = IO_L23N_T3_34,
set_property PACKAGE_PIN  T6        [get_ports {led_o[3]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {led_o[3]}]
# Sch name = LED4,  Bank = 34, Pin name = IO_L12P_T1_MRCC_34,
set_property PACKAGE_PIN  T5        [get_ports {led_o[4]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {led_o[4]}]
# Sch name = LED5,  Bank = 34, Pin name = IO_L12N_T1_MRCC_34,
set_property PACKAGE_PIN  T4        [get_ports {led_o[5]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {led_o[5]}]
# Sch name = LED6,  Bank = 34, Pin name = IO_L22P_T3_34,
set_property PACKAGE_PIN  U7        [get_ports {led_o[6]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {led_o[6]}]
# Sch name = LED7,  Bank = 34, Pin name = IO_L22N_T3_34,
set_property PACKAGE_PIN  U6        [get_ports {led_o[7]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {led_o[7]}]
# Sch name = LED8,  Bank = 34, Pin name = IO_L10N_T1_34,
set_property PACKAGE_PIN  V4        [get_ports {led_o[8]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {led_o[8]}]
# Sch name = LED9,  Bank = 34, Pin name = IO_L8N_T1_34,
set_property PACKAGE_PIN  U3        [get_ports {led_o[9]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {led_o[9]}]
# Sch name = LED10, Bank = 34, Pin name = IO_L7N_T1_34,
set_property PACKAGE_PIN  V1        [get_ports {led_o[10]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {led_o[10]}]
# Sch name = LED11, Bank = 34, Pin name = IO_L17P_T2_34,
set_property PACKAGE_PIN  R1        [get_ports {led_o[11]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {led_o[11]}]
# Sch name = LED12, Bank = 34, Pin name = IO_L13N_T2_MRCC_34,
set_property PACKAGE_PIN  P5        [get_ports {led_o[12]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {led_o[12]}]
# Sch name = LED13, Bank = 34, Pin name = IO_L7P_T1_34,
set_property PACKAGE_PIN  U1        [get_ports {led_o[13]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {led_o[13]}]
# Sch name = LED14, Bank = 34, Pin name = IO_L15N_T2_DQS_34,
set_property PACKAGE_PIN  R2        [get_ports {led_o[14]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {led_o[14]}]
# Sch name = LED15, Bank = 34, Pin name = IO_L15P_T2_DQS_34,
set_property PACKAGE_PIN  P2        [get_ports {led_o[15]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {led_o[15]}]



### Buttons
# Sch name = CPU_RESET, Bank = 15, Pin name = IO_L3P_T0_DQS_AD1P_15
set_property PACKAGE_PIN  C12       [get_ports reset_low_i]
set_property IOSTANDARD   LVCMOS33  [get_ports reset_low_i]
# Sch name = BTNC, Bank = 15, Pin name = IO_L11N_T1_SRCC_15
#set_property PACKAGE_PIN  E16       [get_ports btnC_i]
#set_property IOSTANDARD   LVCMOS33  [get_ports btnC_i]
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
set_property PACKAGE_PIN  A3        [get_ports {vga_red_o[0]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {vga_red_o[0]}]
# Sch name = VGA_R1, Bank = 35, Pin name = IO_L7N_T1_AD6N_35
set_property PACKAGE_PIN  B4        [get_ports {vga_red_o[1]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {vga_red_o[1]}]
# Sch name = VGA_R2, Bank = 35, Pin name = IO_L1N_T0_AD4N_35
set_property PACKAGE_PIN  C5        [get_ports {vga_red_o[2]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {vga_red_o[2]}]
# Sch name = VGA_R3, Bank = 35, Pin name = IO_L8P_T1_AD14P_35
set_property PACKAGE_PIN  A4        [get_ports {vga_red_o[3]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {vga_red_o[3]}]

# Sch name = VGA_B0, Bank = 35, Pin name = IO_L2P_T0_AD12P_35
set_property PACKAGE_PIN  B7        [get_ports {vga_blue_o[0]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {vga_blue_o[0]}]
# Sch name = VGA_B1, Bank = 35, Pin name = IO_L4N_T0_35
set_property PACKAGE_PIN  C7        [get_ports {vga_blue_o[1]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {vga_blue_o[1]}]
# Sch name = VGA_B2, Bank = 35, Pin name = IO_L6N_T0_VREF_35
set_property PACKAGE_PIN  D7        [get_ports {vga_blue_o[2]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {vga_blue_o[2]}]
# Sch name = VGA_B3, Bank = 35, Pin name = IO_L4P_T0_35
set_property PACKAGE_PIN  D8        [get_ports {vga_blue_o[3]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {vga_blue_o[3]}]

# Sch name = VGA_G0, Bank = 35, Pin name = IO_L1P_T0_AD4P_35
set_property PACKAGE_PIN  C6        [get_ports {vga_green_o[0]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {vga_green_o[0]}]
# Sch name = VGA_G1, Bank = 35, Pin name = IO_L3N_T0_DQS_AD5N_35
set_property PACKAGE_PIN  A5        [get_ports {vga_green_o[1]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {vga_green_o[1]}]
# Sch name = VGA_G2, Bank = 35, Pin name = IO_L2N_T0_AD12N_35
set_property PACKAGE_PIN  B6        [get_ports {vga_green_o[2]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {vga_green_o[2]}]
# Sch name = VGA_G3, Bank = 35, Pin name = IO_L3P_T0_DQS_AD5P_35
set_property PACKAGE_PIN  A6        [get_ports {vga_green_o[3]}]
set_property IOSTANDARD   LVCMOS33  [get_ports {vga_green_o[3]}]

# Sch name = VGA_HS, Bank = 15, Pin name = IO_L4P_T0_15
set_property PACKAGE_PIN  B11       [get_ports hsync_o]
set_property IOSTANDARD   LVCMOS33  [get_ports hsync_o]
# Sch name = VGA_VS, Bank = 15, Pin name = IO_L3N_T0_DQS_AD1N_15
set_property PACKAGE_PIN  B12       [get_ports vsync_o]
set_property IOSTANDARD   LVCMOS33  [get_ports vsync_o]
