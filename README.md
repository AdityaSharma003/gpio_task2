# Design and Integating the first Memory-Mapped IP

## Aim: Design of a simple memory-mapped IP (GPIO), integrate it into the existing RISC-V SoC, and validate it through simulation and on-board implementation.

## IP Specification

### Functionality 

* One 32-bit GPIO register
* Writing to the register updates an output signal
* Reading the register returns the last written value

### These Steps are involved in the development of this IP

* Defining a new 32 bit register among the other in the whole shared RAM.
* Creating a Write logic to that particular GPIO.
* And a Readback logic.
* Instantiate the IP in the top module
* Define the Address decoder for this IP.
* Expose the Output Signals.
* Validation.
   * Simulation
   * On-board Implementation
 
## 



You’re ready to explore more RISC-V and Verilog labs in this Codespace.
