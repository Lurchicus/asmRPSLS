# asmRPSLS

Rock, paper, scissors, lizard, spock game in NASM x64 for Linux

Work in progress!

A Rock Paper Scissors Lizard Spock game in x86 64bit NASM by Dan Rhea
following the rules created by Sam Kass and Karen Bryla. I originally
wrote the program in Python3 and then ported it to C# on Windows. So
now I want to port it to x86 assembly on Linux. Hahing fun so far! :)

- 03/17/2024 DWR Project added to GitHub
- 03/17/2024 DWR Corrected details text (doubled by)
- 03/24/2024 DWR Added a safe text reader procedure
- 03/25/2024 DWR Having issues echoing read text so I added a few tweaks. Still having issues
- 05/28/2024 DWR Fixed the issue in the subroutine reads. On line 265, for some reason the r14 register
was being cleared with a "mov r14, r14". I replaced this with "mov r14, 0" which properly initializes r14 
with a zero count.
- 06/10/2024 DWR Corrected the previous correction to "xor r14, r14". The "mov" was a typo on my part. I
also added a lot of comment blocks as the data structures needed a better explanation. Sometimes I forget
that assembly code isn't really self documenting. 
- 06/12/2024 DWR Added code to traverse the proxy/command address table. I have it simply printing out
the command strings for now, but this is the start of code to compare the user input to the command
list to determine if the command is valid. 
