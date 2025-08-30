/*
 * Language Translator Test Firmware
 * 
 * This firmware configures the Caravel management SoC for testing
 * the language translator functionality.
 */

#include <firmware_apis.h>

void language_translator_test() {
    // Configure management GPIO for signaling
    ManagmentGpio_outputEnable();
    ManagmentGpio_write(0);
    
    // Configure housekeeping SPI
    enableHkSpi(0); // Disable housekeeping SPI to give user project control
    
    // Configure user project I/O pads
    // SPI0 pads (7-10)
    GPIOs_configure(7, GPIO_MODE_MGMT_STD_INPUT_NOPULL);   // SPI0 MISO
    GPIOs_configure(8, GPIO_MODE_MGMT_STD_OUTPUT);         // SPI0 MOSI
    GPIOs_configure(9, GPIO_MODE_MGMT_STD_OUTPUT);         // SPI0 SCLK
    GPIOs_configure(10, GPIO_MODE_MGMT_STD_OUTPUT);        // SPI0 CSB
    
    // SPI1 pads (11-14)
    GPIOs_configure(11, GPIO_MODE_MGMT_STD_INPUT_NOPULL);  // SPI1 MISO
    GPIOs_configure(12, GPIO_MODE_MGMT_STD_OUTPUT);        // SPI1 MOSI
    GPIOs_configure(13, GPIO_MODE_MGMT_STD_OUTPUT);        // SPI1 SCLK
    GPIOs_configure(14, GPIO_MODE_MGMT_STD_OUTPUT);        // SPI1 CSB
    
    // I2C pads (15-16) - open drain
    GPIOs_configure(15, GPIO_MODE_MGMT_STD_BIDIRECTIONAL); // I2C SCL
    GPIOs_configure(16, GPIO_MODE_MGMT_STD_BIDIRECTIONAL); // I2C SDA
    
    // GPIO pads (17-18)
    GPIOs_configure(17, GPIO_MODE_MGMT_STD_BIDIRECTIONAL); // GPIO0
    GPIOs_configure(18, GPIO_MODE_MGMT_STD_BIDIRECTIONAL); // GPIO1
    
    // Configure remaining pads for user project (translator interface via LA)
    for (int i = 19; i <= 37; i++) {
        GPIOs_configure(i, GPIO_MODE_MGMT_STD_INPUT_NOPULL);
    }
    
    // Enable user project power
    PowerGate_enable();
    
    // Signal to Python test that configuration is complete
    ManagmentGpio_write(1);
    
    // Keep firmware running
    while (1) {
        // Monitor user interrupts and provide debug info if needed
        // In a real application, this could handle interrupt processing
    }
}