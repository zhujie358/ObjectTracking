# Producing VGA Output 
### Overview
The goal of this experiment was to generate an arbitrary VGA display using the DE2 board. To get the display working, the VGA interface signals must be driven directly by the FPGA, or driven indirectly by using the ADV7123 10-bit high-speed video DAC. These signals represent the VGA interface:
- `VGA_HS` - Horizontal sync pulse, driven directly to the interface. Different VGA resolutions have different polarities (active-high or active-low), so depending on the polarity the value of the pulse will signify the start and end of valid pixel data in a row.
- `VGA_VS` - Vertical sync pulse, driven directly to the interface. Similar idea as the horizontal sync pulse, but for the start and end of valid lines.
- `VGA_R, VGA_G, VGA_B` - RGB data, driven to the ADV7123. Simply the 8-bit color values of the current pixel.
- `VGA_BLANK_N` - ADV7123 control signal, driven to the ADV7123. Drive this signal low during blanking periods to have the RGB data inputs be ignored.
- `VGA_SYNC_N` - ADV7123 control signal, driven to the ADV7123. This is a current source setting on the DAC, this was set high to ignore the setting.
- `VGA_CLK` - ADV7123 clock, driven to the ADV7123. In some examples they would just pass the clock used in the VGA module directly, or invert it.  Inverting it worked successfully in this experiment.

To properly drive these signals, the VGA timing specifications needed to be understood. There are a lot of resources on VGA timing a Google search away. The basics is that you need to get the number of pixels horizontally and vertically for the four regions of the VGA display: front porch, sync, actual visible area, and back porch. The sum of the regions that aren't the visible area are the blanking periods. This is where the `VGA_HS`, `VGA_VS` signals get toggled. Each set of parameters comes with a necessary clock frequency and a polarity for the sync signals. You just need to pick a set of parameters, generate two counters for the pixels and lines, and then drive the signals in the appropriate regions.

The two sources used when writing the module `vga_sync.v`.

1. Terasic provides an example design for working with video input and output on the DE2 board, located in the `DE2_115_demonstrations/DE2_115_TV` directory of the system CD that comes with the board. In this demonstration is a Verilog module named `VGA_Ctrl.v` that was referenced heavily.
2. This [video tutorial](https://www.youtube.com/watch?v=WK5FT5RD1sU).

### Required Hardware
This experiment can be recreated locally by using the Quartus II and Verilog files in this directory, as well as the following hardware.
1. Altera DE2 board. The components used are just the Cyclone IV FPGA and the ADV7123.
2. VGA cable and a display with a VGA port.

### Challenges
The biggest challenge faced when making this module was trying to use the parameters the Terasic demo had used. In the demo, a 640x480 resolution is used which requires a 25 MHz clock. The only clock available in the experiment top-level was the 50 MHz clock, so a clock-divider module was created to try to reduce it. This did not work, as the clock produced by the clock-divider was not stable enough for the VGA interface. Instead, a 800x600 resolution was used since it required a 50 MHz clock. In retrospect, the 25 MHz clock could have been taken from the TV decoder chip or generated with a PLL.