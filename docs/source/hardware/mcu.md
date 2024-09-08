# RISC-V Steel Microcontroller IP

## Introduction

RISC-V Steel Microcontroller IP is a 32-bit RISC-V microcontroller written in Verilog that features the [Processor Core IP](core.md), memory and timer modules, and UART, GPIO, and SPI controllers.

A top-level view of its architecture and the interconnection between its components is shown in the diagram below.

![Image title](../images/rvsteel_mcu.svg){ width=100% }

## Source files

The table below lists the Microcontroller IP source files.

| Module name | Location | Description|
| ----------- |-|-|
| rvsteel_mcu  | `hardware/mcu/rvsteel_mcu.v` | Top module of the Microcontroller IP |
| rvsteel_core | `hardware/core/rvsteel_core.v` | RISC-V Steel Processor Core IP |
| rvsteel_bus | `hardware/bus/rvsteel_bus.v` | Bus controller |
| rvsteel_ram | `hardware/ram/rvsteel_ram.v` | RAM memory |
| rvsteel_mtimer | `hardware/mtimer/rvsteel_mtimer.v` | RISC-V memory-mapped timer registers |
| rvsteel_uart | `hardware/uart/rvsteel_uart.v` | UART controller |
| rvsteel_gpio | `hardware/gpio/rvsteel_gpio.v` | GPIO controller |
| rvsteel_spi | `hardware/spi/rvsteel_spi.v` | SPI controller |

## Instantiation template

``` systemverilog
rvsteel_mcu #(

  // See 'Configuration paramaters' below for more information.

  .CLOCK_FREQUENCY      (50000000       ),
  .UART_BAUD_RATE       (9600           ),
  .MEMORY_SIZE          (8192           ),
  .MEMORY_INIT_FILE     ("mem_init.hex" ),
  .BOOT_ADDRESS         (32'h00000000   ),
  .GPIO_WIDTH           (1              ),
  .SPI_NUM_CHIP_SELECT  (1              ))

  rvsteel_mcu_instance  (

  // See 'I/O signals' below for more information.

  .clock                (),
  .reset                (),
  .halt                 (),
  .uart_rx              (),
  .uart_tx              (),
  .gpio_input           (),
  .gpio_oe              (),
  .gpio_output          (),
  .sclk                 (),
  .pico                 (),
  .poci                 (),
  .cs                   ());
```

## Configuration parameters

| Parameter name and description        | Value type | Default value    |
| ---------------------- | ---------------- | ---|
| **BOOT_ADDRESS**</br>Memory address of the first instruction to be fetched and executed.  | 32-bit hexadecimal   | `32'h00000000`   |
| **CLOCK_FREQUENCY**</br>Frequency (in Hertz) of the `clock` signal.  | Integer | `50000000`       |
| **UART_BAUD_RATE**</br>Baud rate of the UART module (in bauds per second).   | Integer | `9600`           | 
| **MEMORY_SIZE**</br>Size of the memory module (in bytes).     | Integer | `8192`           | 
| **MEMORY_INIT_FILE**</br>Absolute path to the memory initialization file. | String | `(empty string)` |
| **GPIO_WIDTH**</br>Number of general-purpose I/O pins.     | Integer | `1`           | 
| **SPI_NUM_CHIP_SELECT**</br>Number of Chip Select (CS) lines for the SPI controller. | Integer | `1` |

## I/O signals

| Pin name and description      | Direction | Size  |
| -------------- | --------- | ----- |
| **clock**</br>Clock input.      | Input     | 1 bit |
| **reset**</br>Reset pin (active-high).      | Input     | 1 bit |
| **halt**</br>Halt pin (active-high).       | Input     | 1 bit |
| **uart_rx**</br>UART receiver pin. | Input     | 1 bit |
| **uart_tx**</br>UART transmitter pin. | Output    | 1 bit |
| **gpio_input**</br>GPIO input signals. | Input     | `GPIO_WIDTH` |
| **gpio_oe**</br>GPIO output enable.    | Output    | `GPIO_WIDTH` |
| **gpio_output**</br>GPIO output signals. | Output    | `GPIO_WIDTH` |
| **sclk**</br>SPI Controller clock. | Output    | 1 bit |
| **pico**</br>SPI Peripheral In Controller Out.       | Output    | 1 bit |
| **poci**</br>SPI Peripheral Out Controller In.       | Input     | 1 bit |
| **cs**</br>SPI Chip Select lines.         | Output    | `SPI_NUM_CHIP_SELECT` |

## Memory Map

| Start address | Final address       | Block size (Bytes) | Device                     |
| ------------- | ------------------- | ------------------ | -------------------------- |
| `0x00000000`  | `0x(MEMORY_SIZE-1)` | `MEMORY_SIZE`      | RAM                        |
| `0x80000000`  | `0x8000000f`        | 16                 | UART                       |
| `0x80010000`  | `0x8001001f`        | 32                 | Timer                      |
| `0x80020000`  | `0x8002001f`        | 32                 | GPIO                       |
| `0x80030000`  | `0x8003001f`        | 32                 | SPI                        |

## Adding new devices

You can add other devices to the Microcontroller IP by changing the system bus module configuration. The new devices must comply with the protocol used by the Processor Core IP to issue read/write requests. In the [I/O Operations](core.md#io-operations) section you find a detailed description of this protocol.

The steps below show how to modify the Microcontroller IP source files to add a new device.

<h4>1. Open <code>rvsteel_mcu.v</code> and search for the system bus configuration (lines 40-70)</h4>

``` systemverilog
// System bus configuration

localparam NUM_DEVICES    = 5;
localparam D0_RAM         = 0;
localparam D1_UART        = 1;
localparam D2_MTIMER      = 2;
localparam D3_GPIO        = 3;
localparam D4_SPI         = 4;

wire  [NUM_DEVICES*32-1:0] device_start_address;
wire  [NUM_DEVICES*32-1:0] device_region_size;

assign device_start_address [32*D0_RAM      +: 32]  = 32'h0000_0000;
assign device_region_size   [32*D0_RAM      +: 32]  = MEMORY_SIZE;

assign device_start_address [32*D1_UART     +: 32]  = 32'h8000_0000;
assign device_region_size   [32*D1_UART     +: 32]  = 16;

assign device_start_address [32*D2_MTIMER   +: 32]  = 32'h8001_0000;
assign device_region_size   [32*D2_MTIMER   +: 32]  = 32;

assign device_start_address [32*D3_GPIO     +: 32]  = 32'h8002_0000;
assign device_region_size   [32*D3_GPIO     +: 32]  = 32;

assign device_start_address [32*D4_SPI      +: 32]  = 32'h8003_0000;
assign device_region_size   [32*D4_SPI      +: 32]  = 32;
```

<h4>2. Increment <code>NUM_DEVICES</code></h4>

``` systemverilog
localparam NUM_DEVICES    = 6;
```

<h4>3. Create a new parameter to hold the index that will be used to address the new device</h4>

``` systemverilog
localparam D5_NEW_DEVICE  = 5; // the new device index (NUM_DEVICES - 1)
```

<h4>4. Map the new device registers to a memory region</h4>

You can map the new device to any free region (see [Memory Map](#memory-map)). The region cannot overlap the address space of other devices and its size must be a power of 2. 

In the example below, the new device is assigned a 32KB region starting at `0x80040000`:

``` systemverilog
assign device_start_address [32*D5_NEW_DEVICE+: 32]  = 32'h8004_0000;
assign device_region_size   [32*D5_NEW_DEVICE+: 32]  = 32768;
```

<h4>5. Instantiate the new device</h4>

Finally, instantiate the new device at the end of the module and connect it to the system bus. A template for doing this is provided below:

``` systemverilog
// The new device instantiation should look like this:
new_device
new_device_instance_name (

  .new_device_rw_address      (device_rw_address                        ),
  .new_device_read_data       (device_read_data[32*D5_NEW_DEVICE +: 32] ),
  .new_device_read_request    (device_read_request[D5_NEW_DEVICE]       ),
  .new_device_read_response   (device_read_response[D5_NEW_DEVICE]      ),
  .new_device_write_data      (device_write_data                        ),
  .new_device_write_strobe    (device_write_strobe                      ),
  .new_device_write_request   (device_write_request[D5_NEW_DEVICE]      ),
  .new_device_write_response  (device_write_response[D5_NEW_DEVICE]     ));
```

</br>
</br>