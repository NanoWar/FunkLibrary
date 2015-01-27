# FunkLibrary
Functions and macros library that extends SPASM (z80 assembler) for Texas Instruments calculators

---

## Configuration

```
Source  = main source file (with extension)
Target  = on calc file name (max 8 characters, no extension), can be derived from source file name
Folder  = optional code folder relative to this config file where the main source resides, default is none (this folder)
Name    = on calc shell displayed name (also used for compile script console info), can be derived from source file name
Calc    = supported calclator platform: ti83/ti83p*
Type    = output type: nostub*/ion/mirageos/app
Options = any SPASM compile parameter like -T or -L, default is none
Debug   = FunkLibrary switch that outputs debug information on compile time: true/false*
```
\* default


Example configuration file `funk.config` in base folder:
```
Source  = Main.z80
Target  = PROGRAM
Folder  = code
Name    = My Program
Calc    = ti83p
Type    = ion
Options = -T
```

Minimal configuration file `MyProg.config` in same folder as source file:
```
Source  = MyProg.z80
```
Outputs: MyProg.8xp

---
