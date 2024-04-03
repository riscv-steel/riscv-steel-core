// ----------------------------------------------------------------------------
// Copyright (c) 2020-2024 RISC-V Steel contributors
//
// This work is licensed under the MIT License, see LICENSE file for details.
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

module gpio_cmod_a7 #( 

  parameter GPIO_WIDTH = 3

  )(

  input   wire clock,
  input   wire reset,
  input   wire uart_rx,
  output  wire uart_tx,
  inout   wire [GPIO_WIDTH-1:0] gpio

  );
  
  wire [GPIO_WIDTH-1:0] gpio_in;
  wire [GPIO_WIDTH-1:0] gpio_oe;
  wire [GPIO_WIDTH-1:0] gpio_out;

  genvar i;
  for (i = 0; i < GPIO_WIDTH; i=i+1) begin
    assign gpio_in[i] = gpio_oe[i] == 1'b1 ? gpio_out[i] : gpio[i];
    assign gpio[i] = gpio_oe[i] == 1'b1 ? gpio_out[i] : 1'bZ;
  end

  // Divides the 100MHz board block by 2
  reg clock_50mhz;
  initial clock_50mhz = 1'b0;
  always @(posedge clock) clock_50mhz <= !clock_50mhz;

  // Buttons debouncing
  reg reset_debounced;
  always @(posedge clock_50mhz) begin
    reset_debounced <= reset;
  end

  rvsteel_soc #(

    .CLOCK_FREQUENCY          (12000000               ),
    .UART_BAUD_RATE           (9600                   ),
    .MEMORY_SIZE              (131072                 ),
    .MEMORY_INIT_FILE         ("gpio_demo.hex"        ),
    .BOOT_ADDRESS             (32'h00000000           ),
    .GPIO_WIDTH               (3                      )

  ) rvsteel_soc_instance (

    .clock                    (clock_50mhz            ),
    .reset                    (reset_debounced        ),
    .halt                     (1'b0                   ),
    .uart_rx                  (uart_rx                ),
    .uart_tx                  (uart_tx                ),
    .gpio_input               (gpio_in                ),
    .gpio_oe                  (gpio_oe                ),
    .gpio_output              (gpio_out               ),
    .sclk                     (), // unused
    .pico                     (), // unused
    .poci                     (1'b0                   ),
    .cs                       ()  // unused

  );

endmodule