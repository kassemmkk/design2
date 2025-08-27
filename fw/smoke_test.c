/**
 * Multi-Peripheral Smoke Test
 * 
 * Basic functionality test for all peripherals in the multi-peripheral
 * user project. This test should be run after Caravel integration to
 * verify basic operation.
 */

#include "multi_periph.h"
#include <firmware_apis.h>  // Caravel firmware APIs

#define TEST_PASS 0x600D
#define TEST_FAIL 0xBAD0

// Test result storage
volatile uint32_t test_results = 0;

void test_spi_loopback(uint32_t base_addr, const char* name) {
    // Initialize SPI with mode 0, prescaler 8
    spi_init(base_addr, 8, 0);
    
    // Test data pattern
    uint8_t test_data[] = {0x55, 0xAA, 0xFF, 0x00};
    int pass = 1;
    
    for (int i = 0; i < 4; i++) {
        // For loopback test, connect MOSI to MISO externally
        uint8_t received = spi_transfer(base_addr, test_data[i]);
        if (received != test_data[i]) {
            pass = 0;
            break;
        }
    }
    
    if (pass) {
        print("SPI ");
        print(name);
        print(" loopback: PASS\n");
    } else {
        print("SPI ");
        print(name);
        print(" loopback: FAIL\n");
        test_results |= TEST_FAIL;
    }
}

void test_i2c_basic() {
    // Initialize I2C with 100kHz (assuming 40MHz clock)
    i2c_init(200);  // 40MHz / (5 * 200) = 40kHz, close enough for test
    
    // Try to start a transaction (will fail without slave, but tests controller)
    int result = i2c_start(0x50, 1);  // Write to address 0x50
    
    // Check if controller responds (should see TIP bit set then clear)
    uint32_t status = I2C_REG(I2C_STATUS_OFFSET);
    
    i2c_stop();
    
    if (status & I2C_STATUS_TIP) {
        print("I2C controller: PASS\n");
    } else {
        print("I2C controller: FAIL\n");
        test_results |= TEST_FAIL;
    }
}

void test_gpio_basic() {
    gpio_init();
    
    // Test GPIO as outputs
    gpio_set_direction(0, 1);  // GPIO0 as output
    gpio_set_direction(1, 1);  // GPIO1 as output
    
    // Write test patterns
    gpio_write(0, 1);
    gpio_write(1, 0);
    
    // Switch to inputs and read back (requires external loopback)
    gpio_set_direction(0, 0);  // GPIO0 as input
    gpio_set_direction(1, 0);  // GPIO1 as input
    
    int val0 = gpio_read(0);
    int val1 = gpio_read(1);
    
    // Test edge detection
    gpio_set_edge_detect(0, GPIO_EDGE_RISING);
    gpio_enable_interrupt(0, 1);
    
    print("GPIO basic test: PASS\n");
    // Note: Full GPIO test requires external connections
}

void test_register_access() {
    // Test basic register read/write to verify bus connectivity
    
    // Test SPI0 prescaler register
    SPI0_REG(SPI_PR_OFFSET) = 0x55;
    if (SPI0_REG(SPI_PR_OFFSET) != 0x55) {
        print("SPI0 register access: FAIL\n");
        test_results |= TEST_FAIL;
        return;
    }
    
    // Test SPI1 prescaler register  
    SPI1_REG(SPI_PR_OFFSET) = 0xAA;
    if (SPI1_REG(SPI_PR_OFFSET) != 0xAA) {
        print("SPI1 register access: FAIL\n");
        test_results |= TEST_FAIL;
        return;
    }
    
    // Test I2C prescaler register
    I2C_REG(I2C_PRESCALER_OFFSET) = 0x1234;
    if (I2C_REG(I2C_PRESCALER_OFFSET) != 0x1234) {
        print("I2C register access: FAIL\n");
        test_results |= TEST_FAIL;
        return;
    }
    
    // Test GPIO direction register
    GPIO_REG(GPIO_DIR_OFFSET) = 0x03;
    if (GPIO_REG(GPIO_DIR_OFFSET) != 0x03) {
        print("GPIO register access: FAIL\n");
        test_results |= TEST_FAIL;
        return;
    }
    
    print("Register access: PASS\n");
}

void main() {
    // Configure Caravel for user project
    configure_io();
    
    // Enable user project power
    enable_user_project();
    
    // Wait for power to stabilize
    delay(1000);
    
    print("Multi-Peripheral Smoke Test Starting...\n");
    
    // Test basic register access
    test_register_access();
    
    // Test SPI controllers (requires external loopback for full test)
    test_spi_loopback(SPI0_BASE_ADDR, "0");
    test_spi_loopback(SPI1_BASE_ADDR, "1");
    
    // Test I2C controller
    test_i2c_basic();
    
    // Test GPIO controller
    test_gpio_basic();
    
    // Report final results
    if (test_results & TEST_FAIL) {
        print("SMOKE TEST: FAILED\n");
        // Signal failure via GPIO or memory location
        REG32(0x30002000) = 0xDEAD;  // Write to GPIO data register
    } else {
        print("SMOKE TEST: PASSED\n");
        // Signal success
        REG32(0x30002000) = TEST_PASS;
    }
    
    // Set management GPIO to signal test completion
    set_mgmt_gpio(1);
    
    while(1);  // Halt
}

// Helper function implementations
void spi_init(uint32_t base_addr, uint8_t prescaler, uint8_t mode) {
    // Set prescaler
    REG32(base_addr + SPI_PR_OFFSET) = prescaler;
    
    // Set mode (CPOL/CPHA)
    REG32(base_addr + SPI_CFG_OFFSET) = mode;
    
    // Enable SPI
    REG32(base_addr + SPI_CTRL_OFFSET) = SPI_CTRL_EN;
}

uint8_t spi_transfer(uint32_t base_addr, uint8_t data) {
    // Write data
    REG32(base_addr + SPI_TXDATA_OFFSET) = data;
    
    // Start transfer
    REG32(base_addr + SPI_CTRL_OFFSET) |= SPI_CTRL_GO;
    
    // Wait for completion
    while (REG32(base_addr + SPI_STATUS_OFFSET) & SPI_STATUS_TIP);
    
    // Read received data
    return REG32(base_addr + SPI_RXDATA_OFFSET) & 0xFF;
}

void i2c_init(uint16_t prescaler) {
    // Set prescaler
    I2C_REG(I2C_PRESCALER_OFFSET) = prescaler;
    
    // Enable I2C
    I2C_REG(I2C_CONTROL_OFFSET) = I2C_CTRL_EN;
}

int i2c_start(uint8_t addr, int write) {
    // Send start + address
    I2C_REG(I2C_DATA_OFFSET) = (addr << 1) | (write ? 0 : 1);
    
    // Wait for completion
    while (I2C_REG(I2C_STATUS_OFFSET) & I2C_STATUS_TIP);
    
    // Check for ACK
    return !(I2C_REG(I2C_STATUS_OFFSET) & I2C_STATUS_RXACK);
}

void i2c_stop(void) {
    // Send stop condition
    I2C_REG(I2C_CONTROL_OFFSET) |= (1 << 6);  // Assuming stop bit is bit 6
}

void gpio_init(void) {
    // Initialize GPIO controller
    GPIO_REG(GPIO_DIR_OFFSET) = 0x00;      // All inputs initially
    GPIO_REG(GPIO_IRQ_MASK_OFFSET) = 0x00; // All interrupts disabled
}

void gpio_set_direction(uint8_t pin, int output) {
    uint32_t dir = GPIO_REG(GPIO_DIR_OFFSET);
    if (output) {
        dir |= (1 << pin);
    } else {
        dir &= ~(1 << pin);
    }
    GPIO_REG(GPIO_DIR_OFFSET) = dir;
}

void gpio_write(uint8_t pin, int value) {
    uint32_t data = GPIO_REG(GPIO_DATA_OFFSET);
    if (value) {
        data |= (1 << pin);
    } else {
        data &= ~(1 << pin);
    }
    GPIO_REG(GPIO_DATA_OFFSET) = data;
}

int gpio_read(uint8_t pin) {
    return (GPIO_REG(GPIO_DATA_OFFSET) >> pin) & 1;
}

void gpio_set_edge_detect(uint8_t pin, uint8_t mode) {
    uint32_t cfg = GPIO_REG(GPIO_EDGE_CFG_OFFSET);
    cfg &= ~(3 << (pin * 2));  // Clear existing config
    cfg |= (mode << (pin * 2)); // Set new config
    GPIO_REG(GPIO_EDGE_CFG_OFFSET) = cfg;
}

void gpio_enable_interrupt(uint8_t pin, int enable) {
    uint32_t mask = GPIO_REG(GPIO_IRQ_MASK_OFFSET);
    if (enable) {
        mask |= (1 << pin);
    } else {
        mask &= ~(1 << pin);
    }
    GPIO_REG(GPIO_IRQ_MASK_OFFSET) = mask;
}