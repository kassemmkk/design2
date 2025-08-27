# Pad Mapping

This document describes the I/O pad assignments for the multi-peripheral user project.

## Default Pad Assignments

| Signal | Pad | Direction | Type | Description |
|--------|-----|-----------|------|-------------|
| spi0_miso | io_in[7] | Input | Digital | SPI Master 0 MISO |
| spi0_mosi | io_out[8] | Output | Digital | SPI Master 0 MOSI |
| spi0_sclk | io_out[9] | Output | Digital | SPI Master 0 Clock |
| spi0_csb | io_out[10] | Output | Digital | SPI Master 0 Chip Select (active low) |
| spi1_miso | io_in[11] | Input | Digital | SPI Master 1 MISO |
| spi1_mosi | io_out[12] | Output | Digital | SPI Master 1 MOSI |
| spi1_sclk | io_out[13] | Output | Digital | SPI Master 1 Clock |
| spi1_csb | io_out[14] | Output | Digital | SPI Master 1 Chip Select (active low) |
| i2c_scl | io[15] | Bidirectional | Open-drain | I2C Clock |
| i2c_sda | io[16] | Bidirectional | Open-drain | I2C Data |
| gpio[0] | io[17] | Bidirectional | Digital | GPIO Line 0 |
| gpio[1] | io[18] | Bidirectional | Digital | GPIO Line 1 |

## Pad Configuration Details

### SPI Master Pads
- **MISO (Master In, Slave Out)**: Input pads with pull-up enabled
- **MOSI (Master Out, Slave In)**: Push-pull output pads
- **SCLK (Serial Clock)**: Push-pull output pads
- **CSB (Chip Select)**: Push-pull output pads, active low

### I2C Pads
- **SCL/SDA**: Open-drain configuration with external pull-up resistors required
- The I2C controller drives '0' or releases the line (high-Z)
- Pull-up resistors (typically 4.7kΩ) must be connected externally

### GPIO Pads
- **Bidirectional**: Can be configured as input or output via DIR register
- **Input mode**: High impedance with optional pull-up/pull-down
- **Output mode**: Push-pull drive

## Unused Pads

All unused I/O pads are configured as inputs with the following settings:
- io_out = 0 (output value when enabled)
- io_oeb = 1 (output enable = 0, i.e., input mode)

## Changing Pad Assignments

To change the pad assignments:

1. **Modify user_project_wrapper.v**: Update the port connections in the multi_periph_wb_wrapper instantiation
2. **Update constraints**: If using timing constraints, update the I/O delay constraints
3. **Verify routing**: Ensure the new pad assignments don't conflict with other signals

### Example: Moving SPI0 to different pads

```verilog
// Original assignment
.spi0_miso(io_in[7]),
.spi0_mosi(io_out[8]),
.spi0_sclk(io_out[9]),
.spi0_csb(io_out[10]),

// New assignment (moving to pads 20-23)
.spi0_miso(io_in[20]),
.spi0_mosi(io_out[21]),
.spi0_sclk(io_out[22]),
.spi0_csb(io_out[23]),
```

Don't forget to update the unused pad assignments accordingly.

## External Connections

### SPI Master Connections
```
Caravel Pad    External Device
-----------    ---------------
spi0_mosi  --> MOSI (or DI)
spi0_miso  <-- MISO (or DO)  
spi0_sclk  --> SCLK (or CLK)
spi0_csb   --> CS# (or SS#)
```

### I2C Connections
```
Caravel Pad    External Device    Pull-up
-----------    ---------------    -------
i2c_scl    <-> SCL               4.7kΩ to VDD
i2c_sda    <-> SDA               4.7kΩ to VDD
```

### GPIO Connections
```
Caravel Pad    External Device
-----------    ---------------
gpio[0]    <-> User-defined
gpio[1]    <-> User-defined
```

## Power Supply

All I/O pads operate at the Caravel I/O voltage level:
- **VDDIO**: 3.3V (typical)
- **VSSIO**: 0V (ground)

Ensure external devices are compatible with this voltage level or use appropriate level shifters.