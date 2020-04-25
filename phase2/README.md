# ode-solver-chip
Design, implementation, test and synthesis of a chip which solves ODE equations.

## Team 5

| Name                  | Section | B. N |
|-----------------------|---------|------|
| Evram Youssef         | 1       | 9    |
| Remonda Talaat        | 1       | 20   |
| Reham Gamal           | 1       | 21   |
| Mahmoud Adas          | 2       | 21   |
| Mohamed Shawky        | 2       | 16   |
| Mazen Amr             | 2       | 8    |
| Mohamed Ahmed Ibrahim | 2       | 9    |
| Mahmoud Mohamed       | 2       | 22   |

# Requirements

* docker `19.03.6` 
* gnu-bash `4.4.19(1)-release` 
* gtkwave (only to view simulation output) `3.3.93` 
* python3
* python3-pip

## After Installing Docker

1. Run Docker Daemon

    `$ sudo systemctl enable --now docker` 

2. To run docker without sudo (https://docs.docker.com/engine/install/linux-postinstall/):

``` 
$ sudo groupadd docker
$ sudo usermod -aG docker $USER
$ newgrp docker 
```

# Run non vunit tests

To compile and run `x.vhdl` in directories `src` or `test/non_vunit` :

`$ ./run x` 

All non-vunit tests has `.do` files, you can load them into modelsim.

# Run vunit tests

* To compile and run **all** vunit tests: 

    `$ ./run-test` 

* To compile and run vunit test `y.vhdl` in directory `test` :

    `$ ./run-test y` 

# View waveform

* If file `y.vhdl` has test case with name `some_test_name` , you can view its waveform (after `./run-test` ) with:

    `$ ./wave y.some_test_case` 

> `$ ./list-tests` lists all available test cases. 

* If `y.vhdl` is not vunit test file, then type `$ ./wave y` 

# View vunit logs

To view logs of test case `some_test_name` of file `y.vhdl` :

`$ ./logs y.some_test_case` 

# Clean output

`$ ./clean`