# Integration Notes

This document provides technical details about the multi-peripheral integration with Caravel SoC.

## Clock and Reset Architecture

### Clock Domain
- **Single clock domain**: All peripherals operate on the Wishbone clock (`wb_clk_i`)
- **Clock frequency**: Designed for up to 40 MHz operation (25ns period)
- **Clock gating**: Individual peripherals can be clock-gated for power savings

### Reset Strategy
- **Synchronous reset**: Active-high reset (`wb_rst_i`) from Caravel management SoC
- **Reset synchronization**: All peripherals use the same reset signal
- **Reset assertion**: All registers reset to known safe states

## Bus Interface

### Wishbone B4 Classic
- **Data width**: 32 bits
- **Address width**: 32 bits  
- **Byte select**: 4-bit byte lane selection supported
- **Timing**: Single-cycle read/write operations
- **Address decode**: Exact match on specified base addresses

### Address Decoding
```
Address Range          Peripheral
0x3000_0000-0x3000_00FF  SPI Master 0
0x3000_0100-0x3000_01FF  SPI Master 1  
0x3000_1000-0x3000_10FF  I2C Controller
0x3000_2000-0x3000_20FF  GPIO Controller
```

Out-of-range addresses return no acknowledgment (wbs_ack_o = 0).

## Interrupt Architecture

### Interrupt Sources
1. **SPI Master 0**: TX/RX FIFO thresholds, transfer complete
2. **SPI Master 1**: TX/RX FIFO thresholds, transfer complete  
3. **I2C Controller**: Transfer complete, arbitration lost, errors
4. **GPIO Controller**: Edge detection on GPIO lines

### Interrupt Mapping
- **user_irq[0]**: SPI Master 0 (all SPI0 interrupt sources OR'd)
- **user_irq[1]**: SPI Master 1 + I2C (all SPI1 and I2C sources OR'd)
- **user_irq[2]**: GPIO (both GPIO edge detection interrupts OR'd)

### Interrupt Handling
- Level-triggered interrupts to Caravel
- Individual mask and status registers per peripheral
- Write-1-to-clear (W1C) for interrupt status bits

## Power Management

### Power Domains
- **Core logic**: vccd1/vssd1 (1.8V digital supply)
- **I/O pads**: vddio/vssio (3.3V I/O supply)

### Clock Gating
- Each peripheral has optional clock gating capability
- Controlled via GCLK registers where available
- Reduces dynamic power when peripherals are idle

## Synthesis Results

### Area Utilization
- **Total area**: 77,498 µm²
- **Instance count**: 8,735 standard cells
- **Utilization**: 51.2% of allocated area
- **No inferred latches**: Clean synthesis

### Timing Performance
- **Setup slack**: 11.25ns (meets 25ns period requirement)
- **Hold slack**: 0.32ns (positive, no violations)
- **Clock skew**: <1.1ns worst case

### Power Consumption
- **Total power**: 0.60 mW @ 1.8V, 25°C
- **Dynamic power**: 0.59 mW
- **Leakage power**: 0.10 µW

## Verification Strategy

### RTL Verification
- Individual peripheral testbenches using cocotb
- Integration-level testbenches for bus interactions
- Edge case testing for address decode and interrupts

### Gate-Level Verification  
- Post-synthesis functional verification
- Timing simulation with SDF back-annotation
- Power analysis verification

### Recommended Test Sequence
1. **Bus connectivity**: Read/write all peripheral registers
2. **SPI loopback**: Connect MOSI to MISO, verify data transfer
3. **I2C transactions**: Test with I2C EEPROM or similar device
4. **GPIO functionality**: Test input/output modes and edge detection
5. **Interrupt handling**: Verify all interrupt sources and masking

## Known Limitations

### Current Implementation
- **FIFO depths**: Limited to 16 entries per SPI FIFO
- **I2C speed**: Standard mode (100 kHz) and fast mode (400 kHz) supported
- **GPIO count**: Only 2 GPIO lines implemented

### Antenna Violations
- **Status**: 4 antenna violations detected in final layout
- **Impact**: May affect manufacturability, requires antenna diode insertion
- **Mitigation**: Use DIODE_INSERTION_STRATEGY in OpenLane

### Timing Margins
- **Setup time**: 11.25ns slack provides good margin
- **Hold time**: 0.32ns slack is minimal but acceptable
- **Recommendation**: Verify timing at process corners

## Debug and Bring-up

### Debug Signals
- Logic analyzer connections available via `la_data_out`
- Can be used to monitor internal peripheral states
- Useful for debugging bus transactions and timing

### Bring-up Checklist
1. **Power-on**: Verify all power domains are stable
2. **Clock**: Confirm wb_clk_i is running at expected frequency
3. **Reset**: Verify wb_rst_i assertion/deassertion
4. **Bus access**: Test simple register read/write operations
5. **Interrupts**: Verify interrupt routing to management SoC
6. **I/O pads**: Check pad configuration and external connections

### Common Issues
- **No bus response**: Check address decode ranges
- **Interrupt not working**: Verify interrupt mask registers
- **I2C not working**: Check for external pull-up resistors
- **SPI timing issues**: Verify clock polarity/phase settings

## Future Enhancements

### Possible Improvements
- **Additional GPIO lines**: Expand to 8 or 16 GPIO pins
- **DMA support**: Add DMA capability for high-throughput transfers
- **Advanced I2C**: Multi-master support, SMBus compatibility
- **SPI enhancements**: Quad-SPI support, larger FIFOs

### Scalability
- **Modular design**: Easy to add/remove peripherals
- **Address space**: Plenty of room for additional peripherals
- **Interrupt capacity**: Can support more interrupt sources

## References

- [Caravel User Project Template](https://github.com/efabless/caravel_user_project)
- [OpenLane Documentation](https://openlane.readthedocs.io/)
- [Wishbone B4 Specification](https://opencores.org/howto/wishbone)
- [SKY130 PDK Documentation](https://skywater-pdk.readthedocs.io/)