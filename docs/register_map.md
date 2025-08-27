# Multi-Peripheral Register Map

This document describes the register map for the multi-peripheral user project integrated into Caravel SoC.

## Base Addresses

| Peripheral | Base Address | Size | Description |
|------------|-------------|------|-------------|
| SPI Master 0 | 0x3000_0000 | 256 bytes | First SPI master controller |
| SPI Master 1 | 0x3000_0100 | 256 bytes | Second SPI master controller |
| I2C Controller | 0x3000_1000 | 256 bytes | I2C master controller |
| GPIO Controller | 0x3000_2000 | 256 bytes | 2-line GPIO with edge detection |

## SPI Master Registers (CF_SPI_WB)

Both SPI masters have identical register maps at their respective base addresses.

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | TXDATA | W | 0x00 | Transmit data register |
| 0x04 | RXDATA | R | 0x00 | Receive data register |
| 0x08 | CFG | RW | 0x00 | Configuration register |
| 0x0C | CTRL | RW | 0x00 | Control register |
| 0x10 | PR | RW | 0x00 | Prescaler register |
| 0x14 | STATUS | R | 0x00 | Status register |
| 0x18 | RX_FIFO_LEVEL | R | 0x00 | RX FIFO level |
| 0x1C | RX_FIFO_THRESHOLD | RW | 0x00 | RX FIFO threshold |
| 0x20 | RX_FIFO_FLUSH | W | 0x00 | RX FIFO flush |
| 0x24 | TX_FIFO_LEVEL | R | 0x00 | TX FIFO level |
| 0x28 | TX_FIFO_THRESHOLD | RW | 0x00 | TX FIFO threshold |
| 0x2C | TX_FIFO_FLUSH | W | 0x00 | TX FIFO flush |
| 0x30 | IM | RW | 0x00 | Interrupt mask |
| 0x34 | MIS | R | 0x00 | Masked interrupt status |
| 0x38 | RIS | R | 0x00 | Raw interrupt status |
| 0x3C | IC | W | 0x00 | Interrupt clear |

### SPI Configuration Register (CFG)
| Bit | Name | Description |
|-----|------|-------------|
| 0 | CPOL | Clock polarity |
| 1 | CPHA | Clock phase |

### SPI Control Register (CTRL)
| Bit | Name | Description |
|-----|------|-------------|
| 0 | EN | SPI enable |
| 1 | SS | Slave select |
| 2 | GO | Start transaction |

### SPI Status Register (STATUS)
| Bit | Name | Description |
|-----|------|-------------|
| 0 | TIP | Transfer in progress |
| 1 | BUSY | SPI busy |
| 2 | RX_EMPTY | RX FIFO empty |
| 3 | RX_FULL | RX FIFO full |
| 4 | TX_EMPTY | TX FIFO empty |
| 5 | TX_FULL | TX FIFO full |

## I2C Controller Registers (EF_I2C_WB)

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | PRESCALER | RW | 0x0000 | Clock prescaler (16-bit) |
| 0x04 | CONTROL | RW | 0x00 | Control register |
| 0x08 | DATA | RW | 0x00 | Data register |
| 0x0C | STATUS | R | 0x00 | Status register |
| 0x10 | GCLK | RW | 0x01 | Clock gating control |

### I2C Control Register (CONTROL)
| Bit | Name | Description |
|-----|------|-------------|
| 0 | EN | I2C enable |
| 1 | IEN | Interrupt enable |

### I2C Status Register (STATUS)
| Bit | Name | Description |
|-----|------|-------------|
| 0 | IF | Interrupt flag |
| 1 | TIP | Transfer in progress |
| 2 | BUSY | I2C busy |
| 3 | AL | Arbitration lost |
| 4 | RXACK | Received acknowledge |

## GPIO Controller Registers

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | DATA | RW | 0x00 | GPIO data register |
| 0x04 | DIR | RW | 0x00 | GPIO direction register |
| 0x08 | EDGE_CFG | RW | 0x00 | Edge detection configuration |
| 0x0C | IRQ_STATUS | R | 0x00 | Interrupt status |
| 0x10 | IRQ_MASK | RW | 0x00 | Interrupt mask |
| 0x14 | IRQ_CLEAR | W | 0x00 | Interrupt clear (W1C) |

### GPIO Data Register (DATA)
| Bit | Name | Description |
|-----|------|-------------|
| 0 | GPIO0 | GPIO line 0 data |
| 1 | GPIO1 | GPIO line 1 data |

### GPIO Direction Register (DIR)
| Bit | Name | Description |
|-----|------|-------------|
| 0 | DIR0 | GPIO line 0 direction (0=input, 1=output) |
| 1 | DIR1 | GPIO line 1 direction (0=input, 1=output) |

### GPIO Edge Configuration Register (EDGE_CFG)
| Bit | Name | Description |
|-----|------|-------------|
| 1:0 | EDGE0 | GPIO line 0 edge config (00=none, 01=rising, 10=falling, 11=both) |
| 3:2 | EDGE1 | GPIO line 1 edge config (00=none, 01=rising, 10=falling, 11=both) |

### GPIO Interrupt Status Register (IRQ_STATUS)
| Bit | Name | Description |
|-----|------|-------------|
| 0 | IRQ0 | GPIO line 0 interrupt status |
| 1 | IRQ1 | GPIO line 1 interrupt status |

### GPIO Interrupt Mask Register (IRQ_MASK)
| Bit | Name | Description |
|-----|------|-------------|
| 0 | MASK0 | GPIO line 0 interrupt mask (1=enabled) |
| 1 | MASK1 | GPIO line 1 interrupt mask (1=enabled) |

## Interrupt Mapping

The peripheral interrupts are mapped to Caravel's user_irq signals:

| user_irq | Source | Description |
|----------|--------|-------------|
| user_irq[0] | SPI0 | SPI Master 0 interrupts (OR of all SPI0 interrupt sources) |
| user_irq[1] | SPI1 + I2C | SPI Master 1 and I2C interrupts (OR combined) |
| user_irq[2] | GPIO | GPIO edge detection interrupts (OR of both GPIO lines) |

## Access Notes

- All registers are 32-bit aligned
- Byte writes are supported via Wishbone byte select signals
- Interrupt status bits are cleared by writing 1 to the corresponding bit (W1C)
- Reserved bits should be written as 0 and will read as 0