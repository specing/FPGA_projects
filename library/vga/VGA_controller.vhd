library ieee;
use ieee.std_logic_1164.all;

library flib;
use flib.vga.all;



entity VGA_controller is
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
        -- signals where we are
        en_draw_o       : out    std_logic;
        screen_end_o    : out    std_logic -- signals the end of drawing (1-cycle pulse)
    );
end VGA_controller;



architecture Behavioral of VGA_controller is

    alias colclock is pixelclock_i;
    signal rowclock         : std_logic;

    signal en_draw_row      : std_logic;
    signal en_draw_col      : std_logic;

begin

    -- draw only when both HSYNC and VSYNC modules say so
    en_draw_o   <= en_draw_row and en_draw_col;

    Inst_hsync: entity work.sync_generator
    generic map
    (
        t_display       => 640,
        t_fp            => 16,
        t_bp            => 48,
        t_pw            => 96,
        counter_width   => column_width
    )
    port map
    (
        clock_i         => clock_i,
        reset_i         => reset_i,
        enable_i        => colclock,
        sync_o          => hsync_o,
        sig_cycle_o     => rowclock,
        en_draw_o       => en_draw_col,
        pixel_pos_o     => col_o
    );


    Inst_vsync: entity work.sync_generator
    generic map
    (
        t_display       => 480,
        t_fp            => 10,
        t_bp            => 29,
        t_pw            => 2,
        counter_width   => row_width
    )
    port map
    (
        clock_i         => clock_i,
        reset_i         => reset_i,
        enable_i        => rowclock,
        sync_o          => vsync_o,
        sig_cycle_o     => screen_end_o,
        en_draw_o       => en_draw_row,
        pixel_pos_o     => row_o
    );

end Behavioral;
