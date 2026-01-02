`timescale 1ns/1ps

module riscv_edited_tb();

    reg clk;
    reg reset;
    wire [4:0] leds;
    wire txd;
    wire [31:0] gpio_out; // Monitor our new signal

    // Instantiate the modified SOC
    SOC uut (
        //.CLK(clk), // Commented out because SOC generates its own internal clock usually, 
                     // BUT for simulation, we often override internal oscillators.
                     // In your code, SOC uses SB_HFOSC. In simulation, that might need 
                     // a specific model or we assume 'clk' is internal.
                     // IMPORTANT: Your SOC generates 'clk' internally via Clockworks.
                     // Ideally, for simulation, we force the 'clk' signal inside SOC 
                     // or we bypass the oscillator.
        .CLK(clk), // Connect clk for simulation purposes
        .RESET(reset),
        .LEDS(leds),
        .RXD(1'b1),
        .TXD(txd),
        .GPIO_OUT(gpio_out)
    );

    // Generate a clock to drive the internal logic if needed, 
    // or just rely on the internal oscillator model if your simulator supports it.
    // Assuming we need to drive the internal clock net for simple simulation:
    initial begin
        clk= 0; 
        forever #41 clk = ~clk; // ~12 MHz
    end

    initial begin
        // 1. Initialize
        reset = 0; // Active High Reset in your code? (Clockworks takes RESET input)
        // Check Clockworks: if RESET input is 1, it resets.
        
        //$dumpfile("waveform.vcd");
        //$dumpvars(0, riscv_edited_tb);
            $dumpfile("waveform.vcd");
            $dumpvars(0, riscv_edited_tb);

        // 2. Apply Reset
        reset = 1; 
        #100;
        reset = 0;
        
        // 3. Wait for Processor to execute instructions
        // The processor will execute code from firmware.hex
        
        // We wait long enough for the CPU to fetch and execute the write
        #20000; 
        
        // 4. Check the Result
        if (gpio_out == 32'hDEADAEEF) begin
            $display("SUCCESS: GPIO Register updated correctly to 0xdeadbeef");
        end else begin
            $display("FAILURE: GPIO Register is %H expected 0xdeadbeef", gpio_out);
        end

        $finish;
    end

endmodule