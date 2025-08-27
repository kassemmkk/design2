/**
 * Multi-Peripheral Controller Header
 * 
 * Provides register definitions and helper functions for the
 * multi-peripheral user project integrated into Caravel SoC.
 */

#ifndef MULTI_PERIPH_H
#define MULTI_PERIPH_H

#include <stdint.h>

// Base addresses
#define SPI0_BASE_ADDR      0x30000000
#define SPI1_BASE_ADDR      0x30000100  
#define I2C_BASE_ADDR       0x30001000
#define GPIO_BASE_ADDR      0x30002000

// SPI Register offsets
#define SPI_TXDATA_OFFSET       0x00
#define SPI_RXDATA_OFFSET       0x04
#define SPI_CFG_OFFSET          0x08
#define SPI_CTRL_OFFSET         0x0C
#define SPI_PR_OFFSET           0x10
#define SPI_STATUS_OFFSET       0x14
#define SPI_RX_FIFO_LEVEL_OFFSET    0x18
#define SPI_RX_FIFO_THRESHOLD_OFFSET 0x1C
#define SPI_RX_FIFO_FLUSH_OFFSET    0x20
#define SPI_TX_FIFO_LEVEL_OFFSET    0x24
#define SPI_TX_FIFO_THRESHOLD_OFFSET 0x28
#define SPI_TX_FIFO_FLUSH_OFFSET    0x2C
#define SPI_IM_OFFSET           0x30
#define SPI_MIS_OFFSET          0x34
#define SPI_RIS_OFFSET          0x38
#define SPI_IC_OFFSET           0x3C

// I2C Register offsets
#define I2C_PRESCALER_OFFSET    0x00
#define I2C_CONTROL_OFFSET      0x04
#define I2C_DATA_OFFSET         0x08
#define I2C_STATUS_OFFSET       0x0C
#define I2C_GCLK_OFFSET         0x10

// GPIO Register offsets
#define GPIO_DATA_OFFSET        0x00
#define GPIO_DIR_OFFSET         0x04
#define GPIO_EDGE_CFG_OFFSET    0x08
#define GPIO_IRQ_STATUS_OFFSET  0x0C
#define GPIO_IRQ_MASK_OFFSET    0x10
#define GPIO_IRQ_CLEAR_OFFSET   0x14

// SPI Configuration bits
#define SPI_CFG_CPOL            (1 << 0)
#define SPI_CFG_CPHA            (1 << 1)

// SPI Control bits
#define SPI_CTRL_EN             (1 << 0)
#define SPI_CTRL_SS             (1 << 1)
#define SPI_CTRL_GO             (1 << 2)

// SPI Status bits
#define SPI_STATUS_TIP          (1 << 0)
#define SPI_STATUS_BUSY         (1 << 1)
#define SPI_STATUS_RX_EMPTY     (1 << 2)
#define SPI_STATUS_RX_FULL      (1 << 3)
#define SPI_STATUS_TX_EMPTY     (1 << 4)
#define SPI_STATUS_TX_FULL      (1 << 5)

// I2C Control bits
#define I2C_CTRL_EN             (1 << 0)
#define I2C_CTRL_IEN            (1 << 1)

// I2C Status bits
#define I2C_STATUS_IF           (1 << 0)
#define I2C_STATUS_TIP          (1 << 1)
#define I2C_STATUS_BUSY         (1 << 2)
#define I2C_STATUS_AL           (1 << 3)
#define I2C_STATUS_RXACK        (1 << 4)

// GPIO Edge detection modes
#define GPIO_EDGE_NONE          0
#define GPIO_EDGE_RISING        1
#define GPIO_EDGE_FALLING       2
#define GPIO_EDGE_BOTH          3

// Register access macros
#define REG32(addr) (*(volatile uint32_t *)(addr))

// SPI register access macros
#define SPI0_REG(offset) REG32(SPI0_BASE_ADDR + (offset))
#define SPI1_REG(offset) REG32(SPI1_BASE_ADDR + (offset))

// I2C register access macros  
#define I2C_REG(offset) REG32(I2C_BASE_ADDR + (offset))

// GPIO register access macros
#define GPIO_REG(offset) REG32(GPIO_BASE_ADDR + (offset))

// Helper function prototypes
void spi_init(uint32_t base_addr, uint8_t prescaler, uint8_t mode);
uint8_t spi_transfer(uint32_t base_addr, uint8_t data);
void spi_set_cs(uint32_t base_addr, int active);

void i2c_init(uint16_t prescaler);
int i2c_start(uint8_t addr, int write);
int i2c_write(uint8_t data);
uint8_t i2c_read(int ack);
void i2c_stop(void);

void gpio_init(void);
void gpio_set_direction(uint8_t pin, int output);
void gpio_write(uint8_t pin, int value);
int gpio_read(uint8_t pin);
void gpio_set_edge_detect(uint8_t pin, uint8_t mode);
void gpio_enable_interrupt(uint8_t pin, int enable);
uint8_t gpio_get_interrupt_status(void);
void gpio_clear_interrupt(uint8_t pin);

#endif // MULTI_PERIPH_H