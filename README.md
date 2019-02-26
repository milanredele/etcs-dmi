# etcs-dmi

## European Train Control System - Driver Machine Interface (ETCS DMI)
### Goal
The goal is to implement Version 3.4.0 of the ETCS DMI according to specifications published by the European Railway Agency.
Written in Ada2012 with a strong focus on applicability in resource-limited embedded devices: 
primary performance goal is to run on 32bit 200MHz ARM/POWER MCU with 128kB RAM and 1MB ROM, without OS.

### Zero dependency
No library is used other than provided by GNAT. 

### Fonts
Fonts are embedded as bitmaps in source code. FreeSans font is used due to licensing issues which is inspired by Helvetica (which is recommended by the ERA). 
A Freetype based C-program was used to generate Ada code from the TrueType font. It is easily replacable with other font if needed.
