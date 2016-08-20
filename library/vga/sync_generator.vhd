library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.numeric_std_unsigned.all;

library flib;
use flib.vga.all;



entity sync_generator is
    generic
    (
        -- these values depend on the input clock and scan frequencies
        -- The following defaults are HSYNC ones
        -- for a 25 MHz pixel clock and 60 Hz scan frequency

        -- how many pixel clock cycles are spent on the display surface
        t_display       : positive := 640;
        -- how many pixel clock cycles we wait before dropping SYNC current
        t_fp            : positive := 16;
        -- how many pixel clock cycles we wait before starting drawing
        t_bp            : positive := 16;
        -- how many pixel clock cycles are needed for the magnetic field to lapse
        t_pw            : positive := 64;

        -- TODO(1): compute this on the fly (and possibly several of the above as well)
        -- TODO(2): can it ever be natural (i.e. includes 0)?
        counter_width   : positive := 10
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
end sync_generator;



architecture Behavioral of sync_generator is

    signal scancounter          : std_logic_vector (counter_width - 1 downto 0);
    signal scancounter_reset    : std_logic;

    signal sig_cycle            : std_logic;

    signal sig_sync_off         : std_logic;
    signal sig_sync_on          : std_logic;
    signal sig_display_off      : std_logic;
    signal sig_display_on       : std_logic;

    signal sync_on              : std_logic;
    signal draw_on              : std_logic;

begin
    sig_cycle_o         <= sig_cycle;
    sig_cycle           <= sig_display_on;

    scancounter_reset   <= reset_i or sig_cycle;
    pixel_pos_o         <= scancounter;


    -- start of count is at beginning of display
    Inst_sync_counter: entity work.counter
    generic map         (width => counter_width)
    port map
    (
        clock_i         => clock_i,
        reset_i         => scancounter_reset,
        count_enable_i  => enable_i,
        count_o         => scancounter
    );

    -- comparators
    sig_display_off <= '1' when scancounter = To_SLV (t_display, counter_width)
                  else '0';

    sig_sync_off    <= '1' when scancounter = To_SLV (t_display + t_fp, counter_width)
                  else '0';

    sig_sync_on     <= '1' when scancounter = To_SLV (t_display + t_fp + t_pw, counter_width)
                  else '0';

    sig_display_on  <= '1' when scancounter = To_SLV (t_display + t_fp + t_pw + t_bp, counter_width)
                  else '0';


    process (sig_display_on, sig_display_off, draw_on)
    begin
        if sig_display_on = '1' then
            en_draw_o <= '1';
        elsif draw_on = '1' and sig_display_off = '0' then
            en_draw_o <= '1';
        else
            en_draw_o <= '0';
        end if;
    end process;


    process (sig_sync_on, sig_sync_off, sync_on)
    begin
        if (sig_sync_on = '1' or sync_on = '1') and sig_sync_off = '0' then
            sync_o <= '1';
        else
            sync_o <= '0';
        end if;
    end process;


    Inst_flip_flop_jk_sync: entity work.flip_flop_jk
    port map
    (
        clock_i => clock_i,
        reset_i => reset_i,
        j_i     => sig_sync_on,
        k_i     => sig_sync_off,
        q_o     => sync_on
    );


    Inst_flip_flop_jk_draw: entity work.flip_flop_jk
    port map
    (
        clock_i => clock_i,
        reset_i => reset_i,
        j_i     => sig_display_on,
        k_i     => sig_display_off,
        q_o     => draw_on
    );

end Behavioral;
