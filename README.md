# HEX2BIN_0x01
A simple Intel HEX to BINARY File Converter

A simple Intel .hex file to .bin command line application without limitations made in AutoIt.
It incrementally reads the origin Intel HEX file and converts it into a binary (.bin) file without making any kind of sum checking, redundancy analysis, data overlappings or syntax in the origin file.
It just reads the .hex file from line 1 until it finds the EOF marker.

It supports Extended Linear and Segment Address Records (HEX386 & HEX86).

# Usage
0x01.exe "Input file.hex" [-offset<hex>] [-signed]
  
  -offsetFFFFFF   
  The starting offset in hexadecimal. This will add the specified value (FFFFFF) to the address value read in the origin .hex file. It can be a positive (-offset+FFFFFF) or negative (-offset-FFFFFF) value. 
  
  -signed  
  This will make the program assume that the address values specified in the origin file are hexadecimal signed positive values.
  
The output file will be a .bin file with the input file name:
  "Output file.bin"
