library ieee;
use ieee.std_logic_1164.all;



package vga is

    component sync_generator is
        generic
        (
            -- these values depend on the input clock and scan frequencies
            -- The following defaults are HSYNC ones
            -- for a 25 MHz pixel clock and 60 Hz scan frequency on 640x480 resolution display.

            -- how many pixel clock cycles are spent on the display surface
            t_display       : positive;
            -- how many pixel clock cycles we wait before dropping SYNC current
            t_fp            : positive;
            -- how many pixel clock cycles we wait before starting drawing
            t_bp            : positive;
            -- how many pixel clock cycles are needed for the magnetic field to lapse
            t_pw            : positive;

            -- TODO(1): compute this on the fly (and possibly several of the above as well)
            -- TODO(2): can it ever be natural (i.e. includes 0)?
            counter_width   : positive
        );
        port
        (
            clock_i         : in     std_logic; -- main clock
            reset_i         : in     std_logic; -- main reset
            enable_i        : in     std_logic; -- enable -- pixel clock/row clock

            sync_o          : out    std_logic; -- output of HSYNC
            sig_cycle_o     : out    std_logic; -- row clock -- enable for vsync

            en_draw_o       : out    std_logic; -- enable drawing (on display surface)
            pixel_pos_o     : out    std_logic_vector (counter_width - 1 downto 0)
        );
    end component sync_generator;


    component VGA_controller is
        generic
        (
            row_width       : integer := 9;
            column_width    : integer := 10
        );
        port
        (
            clock_i         : in     std_logic;
            reset_i         : in     std_logic;
            pixelclock_i    : in     std_logic;

            vsync_o         : out    std_logic;
            hsync_o         : out    std_logic;
            col_o           : out    std_logic_vector (column_width - 1 downto 0);
            row_o           : out    std_logic_vector (row_width - 1 downto 0);
            en_draw_o       : out    std_logic;

            screen_end_o    : out    std_logic;
            off_screen_o    : out    std_logic
        );
    end component VGA_controller;

end package vga;
