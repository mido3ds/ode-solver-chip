# Abstract
This doc describes the vunit+ghdl stack and the provided wrapping scripts and how to use them to compile/run the src/test files quickly instead of using cumbersome and slow guis.

# Introduction

[VUnit](https://vunit.github.io/about.html) is an open source unit testing framework for VHDL. It helps speed up testing.

VUnit collects all test logs and outputs in a nice way. Each test-case has its own signals dump and logs file.

[GHDL](https://github.com/ghdl/ghdl) is an open-source simulator for the VHDL language. GHDL allows you to compile and execute VHDL code from command line. GHDL input is set of vhdl files, and its output is an executable binary of the simulation. The output of the simulation is `.vcd` file containing the signals dump.

[GTKWave](http://gtkwave.sourceforge.net/) is an open-source signals dump viewer. It's used to view `.vcd` files that the simulations outputs.

I wrote the following scripts to ease the use of vunit+ghdl stack.
---

# Requirements

* docker `19.03.6` 
* gnu-bash `4.4.19(1)-release` 
* gtkwave (only to view simulation output) `3.3.93` 

# Optional Requirements

For auto-* scripts: 

* entr `release 4.1` 

# Scripts

## run-test

Runs the `vunit` vhdl testbench files.

Without any arguments, the script runs all available `vunit` tests.

To specify a test, write the test file name without the `.vhdl` part.e.g. If the testbench is `ayhabal.vhdl` , then you need to type `$ ./run-test anyhabal` 

Ignores files starting with `--%IGNORE%--`

## wave

Opens the signal dump of given testbench name.

To use a save file (so you don't need each time to organize the signals) you can give it the path of the save file as the second argument.

e.g. `$ ./wave ayhabal /tmp/mysave.save` 

## logs

Opens the logs dump of given testbench name.

## new

Creates new `src` and `test` files for given unit name, following a default template for `vunit` .

e.g. `$ ./new ayhabal` will create `src/ayhabal.vhdl` and `test/ayhabal_tb.vhdl` 

## run

Compiles and runs any non-vunit vhdl files (either in src or test).

e.g. `$ ./run foo` will compile src/foo.vhdl
and `$ ./run bar_tb` will compile and run src/bar_tb.vhdl

DOES NOT ignore files starting with `--%IGNORE%--`

## auto-run

Watch `src` and `test` directories for any change and run `run <unit name>` 

## auto-run-test

Same as `auto-run` , but runs `vunit` tests instead of general ghdl files.

## clean

Clean all outputs(waves, logs, compiled files) and removes the ghdld_vlsi container daemon.

## list-tests

List test cases for given testbench name, or for all project testbenches if no argument is specified.

Ignores files starting with `--%IGNORE%--`