# Micro Modules Report
This report documents some of the implementation details in the micro modules, plus it contains the synthesis statistics for those modules. 

# FPU (Float/Fixed Point Unit)

The fpu is a component that mux-es between an adder/subtractor, multiplier and divider, all of which operate only on floats/fixed point numbers. 
The fpu itself is not instantited in the project, but rather its subunits. 

All fpu subunits follow the fpu specs (including all ports except `operation` and all logic and state) in `0.14.4` in the main document. 

FPU is implemented in `src/fpu.vhdl` , while its subunits are implemented in `src/fpu_subunits` . 

Each fpu subunit has multiple architectures. 
They are: 

* `with_operators` : copied from phase1, used temporarily in macro modules while other architectures are developed. 
* `first_algo` . 
* `sec_algo` : divider does have only first_algo and with_operators. 

## FPU Adder/Subtractor

### Synthesis Statistics

| Architecture | Area | Power | Time |
|--------------|------|-------|------|
| first_algo   | TODO | TODO  | TODO |
| sec_algo     | TODO | TODO  | TODO |

## FPU Multiplier

### Synthesis Statistics

| Architecture | Area | Power | Time |
|--------------|------|-------|------|
| first_algo   | TODO | TODO  | TODO |
| sec_algo     | TODO | TODO  | TODO |

## FPU Divider

### Synthesis Statistics

| Architecture | Area | Power | Time |
|--------------|------|-------|------|
| first_algo   | TODO | TODO  | TODO |
| sec_algo     | TODO | TODO  | TODO |

## RAM

RAM is generic in:

* number of words
* width of address bus
* width of data bus

RAM has seperate bus for read and write, and performas both on falling edge of the clock. 

RAM also has asyncrounous reset signal that performs parallel load into all internal lateches. 

### Synthesis Statistics

| Area | Power | Time |
|------|-------|------|
| TODO | TODO  | TODO |

## CPU

Composed of 3 parts:

1. `scripts/preprocessor.py` : reads input json and outputs `.in` file that contains ASCII 0s and 1s in lines, each line is 32 byte in width. 
1. `test/cpu_tb.vhdl` : testbench that reads `.in` files in `input` directory and performs the main simulation by feeding the compressed data and switching state input and receiving output data and writing them back to `out/*.out` files. 

Some lines in `cpu_tb.vhdl` are commented for this phase, because they are integration points for next phases. 

1. `scripts/output_fromatter.py` : convert ASCII output (0s and 1s) from `cpu_tb.vhdl` into human readable json. 

