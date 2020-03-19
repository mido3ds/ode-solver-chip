---
classoption: onecolumn

documentclass: article

title: Shitty Fucking Useless Draft/Design
author: Mahmoud Adas, Evram Youssef, Mohamed Shawky, Remonda Talaat
date: \today

pagestyle: headings
... 

![Overall Design](d0.png)

## Interface:

* CLK
* RESET
    - clears all internal states of all modules:
        * IO internal buffer
        * ERROR/SUCCESS of all modules resets to SUCCESS(1)
        * INTERRUP resets to zero
        * INTERPOLATOR invalidates all its cache, which means it needs to refill it from IO 
        * SOVLER invalidates all its cache and registers, which means it needs to access the ram again 
        * CPY from solver to interp, and ACK from interp to solver are both zeroed to stop any copy operations
    - RAM is NOT cleared
    - ASYNC
    - CPU is expected next clock to turn the `LOAD / PROC / OUT` into `LOAD` state and we will start loding input again.

* LOAD / PROC / OUT (2bit): TODO
* DATA (64bit): TODO
* INTERRUPT: TODO
* ERROR / SUCCESS: TODO

