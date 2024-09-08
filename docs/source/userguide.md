---
hide: navigation
---

# Introduction

Developing a new embedded application with RISC-V Steel involves two steps:

1. [Writing the software for the application.](#writing-the-software-for-the-application)
2. [Running and testing the application on an FPGA](#running-and-testing-the-application-on-an-fpga).

In the first step, you write the source code for the new application and build it using the RISC-V GNU Toolchain. The building process generates a `.hex` file that is used later to initialize the memory of the Microcontroller IP.

In the second step, you create a new Verilog module with an instance of the Microcontroller IP and implement it on an FPGA. The Microcontroller IP instance is configured to fit on the FPGA and initialized to run the application you wrote in the first step.

## Prerequisites

To build software for RISC-V Steel you'll need the [RISC-V GNU Toolchain](https://github.com/riscv/riscv-gnu-toolchain), a suite of compilers and development tools for the RISC-V architecture. 

Run the commands below to install and configure the toolchain for RISC-V Steel:

!!! note ""

    __Important!__ The `--prefix` option defines the installation folder. You need to set it to a folder where you have `rwx` permissions. The commands below assume you have `rwx` permissions on `/opt`.

=== "Ubuntu"

    ```
    # Clone the RISC-V GNU Toolchain repo
    git clone https://github.com/riscv-collab/riscv-gnu-toolchain

    # Install dependencies
    sudo apt-get install autoconf automake autotools-dev curl python3 python3-pip libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build git cmake libglib2.0-dev libslirp-dev

    # Configure the toolchain for RISC-V Steel
    cd riscv-gnu-toolchain && ./configure --with-arch=rv32izicsr --with-abi=ilp32 --prefix=/opt/riscv

    # Compile and install
    make -j $(nproc)
    ```

=== "Fedora/CentOS/RHEL/Rocky"

    ```
    # Clone the RISC-V GNU Toolchain repo
    git clone https://github.com/riscv-collab/riscv-gnu-toolchain

    # Install dependencies
    sudo yum install autoconf automake python3 libmpc-devel mpfr-devel gmp-devel gawk  bison flex texinfo patchutils gcc gcc-c++ zlib-devel expat-devel libslirp-devel

    # Configure the toolchain for RISC-V Steel
    cd riscv-gnu-toolchain && ./configure --with-arch=rv32izicsr --with-abi=ilp32 --prefix=/opt/riscv

    # Compile and install
    make -j $(nproc)
    ```

=== "Arch Linux"

    ```
    # Clone the RISC-V GNU Toolchain repo
    git clone https://github.com/riscv-collab/riscv-gnu-toolchain

    # Install dependencies
    sudo pacman -Syyu autoconf automake curl python3 libmpc mpfr gmp gawk base-devel bison flex texinfo gperf libtool patchutils bc zlib expat libslirp

    # Configure the toolchain for RISC-V Steel
    cd riscv-gnu-toolchain && ./configure --with-arch=rv32izicsr --with-abi=ilp32 --prefix=/opt/riscv

    # Compile and install
    make -j $(nproc)
    ```

=== "OS X"

    ```
    # Clone the RISC-V GNU Toolchain repo
    git clone https://github.com/riscv-collab/riscv-gnu-toolchain

    # Install dependencies
    brew install python3 gawk gnu-sed gmp mpfr libmpc isl zlib expat texinfo flock libslirp

    # Configure the toolchain for RISC-V Steel
    cd riscv-gnu-toolchain && ./configure --with-arch=rv32izicsr --with-abi=ilp32 --prefix=/opt/riscv

    # Compile and install
    make -j $(nproc)
    ```

## Writing the software for the application

The quickest way to start a new application is to make a copy of the `template/` folder, which is a template software project containing a linker script and a `CMakeLists.txt` file that instructs CMake to build software for RISC-V Steel.

By starting from the template project, you don't have to worry about setting up the compiler and linker and can jump straight to writing the application.

    # Clone RISC-V Steel repository (if not cloned yet)
    git clone https://github.com/riscv-steel/riscv-steel
    
    # Make a copy of the template software project
    cp riscv-steel/template/ new_project/

The template project contains a `main.c` file, where the source code for the new application must go. Check out our [code examples](#writing-the-software-for-the-application) to learn how to develop software for the features in the Microcontroller IP.

To build the application you wrote, simply run `make` from the project root folder:

    cd new_project/
    make

A successfull build ends with a message like this:

```
Memory region         Used Size  Region Size  %age Used
             RAM:        1264 B         8 KB     15.43%
-------------------------------------------------------
Build outputs:
-- ELF executable:    build/myapp.elf
-- Memory init file:  build/myapp.hex
-- Disassembly:       build/myapp.objdump
```

## Running and testing the application on an FPGA

Implementing the Microcontroller IP on an FPGA consists of two steps:

- First, you need to create a wrapper module with an instance of the Microcontroller IP and configure it for the application it will run.

- Then, using the FPGA vendor's EDA tool, you will synthesize this wrapper module and program the FPGA to finally run the application.

Let's do the first part. Using your preferred text editor, create a Verilog file named `rvsteel_mcu_wrapper.v` and add the code below. 

!!! note ""

    __Important:__ Don't forget to change the file as instructed in the comments!

```verilog

module rvsteel_mcu_wrapper (
  
  input   wire          clock       ,
  input   wire          reset       ,
  input   wire          halt        ,

  // UART
  // Remove it if your application does not use the UART.
  input   wire          uart_rx     ,
  output  wire          uart_tx     ,

  // General Purpose I/O
  // Remove it if your application does not use the GPIO.
  input   wire  [3:0]   gpio_input  ,
  output  wire  [3:0]   gpio_oe     ,
  output  wire  [3:0]   gpio_output ,

  // Serial Peripheral Interface (SPI)
  // Remove it if your application does not use the SPI controller.
  output  wire          sclk        ,
  output  wire          pico        ,
  input   wire          poci        ,
  output  wire  [0:0]   cs
  
  );

  reg reset_debounced;
  always @(posedge clock) reset_debounced <= reset;

  reg halt_debounced;
  always @(posedge clock) halt_debounced <= halt;

  rvsteel_mcu #(

    // Frequency (in Hertz) of your FPGA board's clock
    .CLOCK_FREQUENCY          (50000000                   ),
    // Absolute path to the .hex init file
    // This file is generated when you build the application and is saved in
    // the `build` folder
    .MEMORY_INIT_FILE         ("/path/to/myapp.hex"       ),    
    // Set here the size you want for the memory (in bytes)
    .MEMORY_SIZE              (8192                       ),
    // Set here the UART baud rate (in bauds per second)
    .UART_BAUD_RATE           (9600                       ),
    // Leave it as it is, unless you explicitly changed the boot address
    .BOOT_ADDRESS             (32'h00000000               ),
    // Width of the gpio_* ports
    .GPIO_WIDTH               (4                          ),
    // Width of the cs port
    .SPI_NUM_CHIP_SELECT      (1                          ))
    
    rvsteel_mcu_instance      (
    
    .clock                    (clock                      ),
    .reset                    (reset_debounced            ),
    .halt                     (halt_debounced             ),
    .uart_rx                  (uart_rx                    ),
    .uart_tx                  (uart_tx                    ),
    .gpio_input               (gpio_input                 ),
    .gpio_oe                  (gpio_oe                    ),
    .gpio_output              (gpio_output                ),
    .sclk                     (sclk                       ),
    .pico                     (pico                       ),
    .poci                     (poci                       ),
    .cs                       (cs                         ));

endmodule
```

Now you need to synthesize the module above on an FPGA to finally run the application. The steps to synthesize it vary depending on the FPGA model and vendor, but generally follow this order:

- Start a new project on the EDA tool provided by your FPGA vendor (e.g. AMD Vivado, Intel Quartus, Lattice iCEcube)
- Add the following files to the project:
    - The Verilog file created above, `rvsteel_mcu_wrapper.v`.
    - All Microcontroller IP [source files](hardware/mcu.md#source-files).
- Create a design constraints file and map the ports of `rvsteel_mcu_wrapper.v` to the respective devices on the FPGA board
- Run synthesis, place and route, and any other intermediate step needed to generate a bitstream for the FPGA
- Generate the bitstream and program the FPGA with it

After programming the FPGA, the application should start running immediately!

</br>
</br>