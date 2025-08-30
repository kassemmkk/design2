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
#define TRANSLATOR_BASE_ADDR 0x30003000

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

// Language Translator Register offsets
#define TRANS_CONTROL_OFFSET    0x00
#define TRANS_STATUS_OFFSET     0x04
#define TRANS_SRC_LANG_OFFSET   0x08
#define TRANS_DST_LANG_OFFSET   0x0C
#define TRANS_INPUT_DATA_OFFSET 0x10
#define TRANS_OUTPUT_DATA_OFFSET 0x14
#define TRANS_INPUT_LEN_OFFSET  0x18
#define TRANS_OUTPUT_LEN_OFFSET 0x1C
#define TRANS_IRQ_MASK_OFFSET   0x20
#define TRANS_IRQ_STATUS_OFFSET 0x24
#define TRANS_IRQ_CLEAR_OFFSET  0x28
#define TRANS_BUFFER_CTRL_OFFSET 0x2C

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

// Language Translator Control bits
#define TRANS_CTRL_START        (1 << 0)
#define TRANS_CTRL_RESET_BUF    (1 << 1)
#define TRANS_CTRL_ENABLE       (1 << 2)

// Language Translator Status bits
#define TRANS_STATUS_ERROR      (1 << 15)
#define TRANS_STATUS_DONE       (1 << 14)
#define TRANS_STATUS_BUSY       (1 << 13)
#define TRANS_STATUS_IN_FULL    (1 << 11)
#define TRANS_STATUS_IN_EMPTY   (1 << 10)
#define TRANS_STATUS_OUT_FULL   (1 << 9)
#define TRANS_STATUS_OUT_EMPTY  (1 << 8)

// Language Translator Interrupt bits
#define TRANS_IRQ_DONE          (1 << 0)
#define TRANS_IRQ_ERROR         (1 << 1)
#define TRANS_IRQ_BUFFER_FULL   (1 << 2)

// Language codes
#define LANG_ENGLISH            0x01
#define LANG_SPANISH            0x02
#define LANG_FRENCH             0x03
#define LANG_GERMAN             0x04
#define LANG_ITALIAN            0x05
#define LANG_PORTUGUESE         0x06
#define LANG_CHINESE            0x07
#define LANG_JAPANESE           0x08
#define LANG_KOREAN             0x09
#define LANG_ARABIC             0x0A

// Register access macros
#define REG32(addr) (*(volatile uint32_t *)(addr))

// SPI register access macros
#define SPI0_REG(offset) REG32(SPI0_BASE_ADDR + (offset))
#define SPI1_REG(offset) REG32(SPI1_BASE_ADDR + (offset))

// I2C register access macros  
#define I2C_REG(offset) REG32(I2C_BASE_ADDR + (offset))

// GPIO register access macros
#define GPIO_REG(offset) REG32(GPIO_BASE_ADDR + (offset))

// Language Translator register access macros
#define TRANS_REG(offset) REG32(TRANSLATOR_BASE_ADDR + (offset))

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

// Language Translator helper functions
void translator_init(void);
void translator_set_languages(uint8_t src_lang, uint8_t dst_lang);
int translator_write_input(const char* text, uint16_t length);
int translator_read_output(char* buffer, uint16_t max_length);
int translator_start_translation(void);
uint32_t translator_get_status(void);
void translator_enable_interrupt(uint8_t irq_mask);
uint8_t translator_get_interrupt_status(void);
void translator_clear_interrupt(uint8_t irq_bits);
void translator_reset_buffers(void);

#endif // MULTI_PERIPH_H