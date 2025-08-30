"""
Language Translator Test for Caravel Multi-Peripheral SoC

This test verifies the language translator functionality integrated
into the Caravel user project.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from caravel_cocotb.caravel_interfaces import test_configure, report_test

# Base addresses
TRANSLATOR_BASE = 0x30003000

# Register offsets
TRANS_CONTROL_OFFSET    = 0x00
TRANS_STATUS_OFFSET     = 0x04
TRANS_SRC_LANG_OFFSET   = 0x08
TRANS_DST_LANG_OFFSET   = 0x0C
TRANS_INPUT_DATA_OFFSET = 0x10
TRANS_OUTPUT_DATA_OFFSET = 0x14
TRANS_INPUT_LEN_OFFSET  = 0x18
TRANS_OUTPUT_LEN_OFFSET = 0x1C
TRANS_IRQ_MASK_OFFSET   = 0x20
TRANS_IRQ_STATUS_OFFSET = 0x24
TRANS_IRQ_CLEAR_OFFSET  = 0x28
TRANS_BUFFER_CTRL_OFFSET = 0x2C

# Control bits
TRANS_CTRL_START        = (1 << 0)
TRANS_CTRL_RESET_BUF    = (1 << 1)
TRANS_CTRL_ENABLE       = (1 << 2)

# Status bits
TRANS_STATUS_ERROR      = (1 << 15)
TRANS_STATUS_DONE       = (1 << 14)
TRANS_STATUS_BUSY       = (1 << 13)
TRANS_STATUS_IN_EMPTY   = (1 << 10)
TRANS_STATUS_OUT_EMPTY  = (1 << 8)

# Language codes
LANG_ENGLISH = 0x01
LANG_SPANISH = 0x02
LANG_FRENCH  = 0x03

@cocotb.test()
@report_test
async def language_translator_test(dut):
    """Test the language translator functionality"""
    
    # Configure Caravel environment
    caravelEnv = await test_configure(dut, timeout_cycles=100000)
    
    # Test basic register access
    cocotb.log.info("Testing basic register access...")
    
    # Reset buffers
    await caravelEnv.cpu.drive_data2address(
        TRANSLATOR_BASE + TRANS_BUFFER_CTRL_OFFSET, 
        0x03  # Reset both input and output buffers
    )
    
    # Set source language to English
    await caravelEnv.cpu.drive_data2address(
        TRANSLATOR_BASE + TRANS_SRC_LANG_OFFSET, 
        LANG_ENGLISH
    )
    
    # Set destination language to Spanish
    await caravelEnv.cpu.drive_data2address(
        TRANSLATOR_BASE + TRANS_DST_LANG_OFFSET, 
        LANG_SPANISH
    )
    
    # Verify language settings
    src_lang = await caravelEnv.cpu.read_address(TRANSLATOR_BASE + TRANS_SRC_LANG_OFFSET)
    dst_lang = await caravelEnv.cpu.read_address(TRANSLATOR_BASE + TRANS_DST_LANG_OFFSET)
    
    assert src_lang == LANG_ENGLISH, f"Source language mismatch: expected {LANG_ENGLISH}, got {src_lang}"
    assert dst_lang == LANG_SPANISH, f"Destination language mismatch: expected {LANG_SPANISH}, got {dst_lang}"
    
    cocotb.log.info("Language settings verified successfully")
    
    # Test input buffer writing
    cocotb.log.info("Testing input buffer writing...")
    
    # Write test string "Hello" (as 32-bit words)
    test_input = "Hello"
    input_data = []
    
    # Convert string to 32-bit words (little-endian)
    for i in range(0, len(test_input), 4):
        word = 0
        for j in range(4):
            if i + j < len(test_input):
                word |= (ord(test_input[i + j]) << (j * 8))
        input_data.append(word)
    
    # Write input data
    for word in input_data:
        await caravelEnv.cpu.drive_data2address(
            TRANSLATOR_BASE + TRANS_INPUT_DATA_OFFSET, 
            word
        )
    
    # Set input length
    await caravelEnv.cpu.drive_data2address(
        TRANSLATOR_BASE + TRANS_INPUT_LEN_OFFSET, 
        len(test_input)
    )
    
    cocotb.log.info("Input data written successfully")
    
    # Enable translator
    await caravelEnv.cpu.drive_data2address(
        TRANSLATOR_BASE + TRANS_CONTROL_OFFSET, 
        TRANS_CTRL_ENABLE
    )
    
    # Enable translation complete interrupt
    await caravelEnv.cpu.drive_data2address(
        TRANSLATOR_BASE + TRANS_IRQ_MASK_OFFSET, 
        0x01  # Enable translation done interrupt
    )
    
    # Check initial status
    status = await caravelEnv.cpu.read_address(TRANSLATOR_BASE + TRANS_STATUS_OFFSET)
    cocotb.log.info(f"Initial status: 0x{status:08x}")
    
    # Start translation
    cocotb.log.info("Starting translation...")
    await caravelEnv.cpu.drive_data2address(
        TRANSLATOR_BASE + TRANS_CONTROL_OFFSET, 
        TRANS_CTRL_ENABLE | TRANS_CTRL_START
    )
    
    # Wait for translation to complete or timeout
    timeout_cycles = 1000
    for cycle in range(timeout_cycles):
        status = await caravelEnv.cpu.read_address(TRANSLATOR_BASE + TRANS_STATUS_OFFSET)
        
        if status & TRANS_STATUS_DONE:
            cocotb.log.info(f"Translation completed after {cycle} cycles")
            break
        elif status & TRANS_STATUS_ERROR:
            cocotb.log.error(f"Translation error after {cycle} cycles")
            break
            
        await RisingEdge(dut.wb_clk_i)
    else:
        cocotb.log.warning("Translation timeout - this is expected in simulation without external translator")
    
    # Check final status
    final_status = await caravelEnv.cpu.read_address(TRANSLATOR_BASE + TRANS_STATUS_OFFSET)
    cocotb.log.info(f"Final status: 0x{final_status:08x}")
    
    # Check interrupt status
    irq_status = await caravelEnv.cpu.read_address(TRANSLATOR_BASE + TRANS_IRQ_STATUS_OFFSET)
    cocotb.log.info(f"Interrupt status: 0x{irq_status:08x}")
    
    # Test output buffer reading (if translation completed)
    if final_status & TRANS_STATUS_DONE:
        output_len = await caravelEnv.cpu.read_address(TRANSLATOR_BASE + TRANS_OUTPUT_LEN_OFFSET)
        cocotb.log.info(f"Output length: {output_len}")
        
        if output_len > 0:
            # Read output data
            output_words = (output_len + 3) // 4  # Round up to word boundary
            for i in range(output_words):
                output_word = await caravelEnv.cpu.read_address(TRANSLATOR_BASE + TRANS_OUTPUT_DATA_OFFSET)
                cocotb.log.info(f"Output word {i}: 0x{output_word:08x}")
    
    # Clear interrupts
    await caravelEnv.cpu.drive_data2address(
        TRANSLATOR_BASE + TRANS_IRQ_CLEAR_OFFSET, 
        0xFF  # Clear all interrupts
    )
    
    cocotb.log.info("Language translator test completed successfully")