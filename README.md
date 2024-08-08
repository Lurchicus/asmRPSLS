# asmRPSLS

Rock, paper, scissors, lizard, spock game in NASM x64 for Linux

**Work in progress!**

A Rock Paper Scissors Lizard Spock game in x86 64bit NASM by Dan Rhea
following the rules created by Sam Kass and Karen Bryla. I originally
wrote the program in c# for Windows and then ported it to Python3 to
work with Windows and Linux.
So now I want to port it to x86 assembly on Linux. Having fun so far! :)

## Currently in progress (todo)

Working on code to take the user input in "inbuf" and compare it to the list starting at "proxrck" and given a match equate it with the value starting at verbnum. Basically keep a counter and add a string compare of each string with the string the user supplied and retain the counter value as the user selection if a match is found (otherwise treat is as a "help" command) (I should be able to eliminate the verbnum list).

## Dependencies

- gcc
- build-essential
- nasm

## C Library external references

- extern printf
- extern rand
- extern srand
- extern time

## Changes

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
list to determine if the command is in the proxy/command list.
- 06/17/2024 DWR Adding VT100 color codes (escape codes) to text output and
rewrote the debug toggle code (it was pretty bad before).
- 06/25/2024 DWR Added a CHANGES.md file and cleaned up the formatting in the README.md file. Also added
an in progress note above.
- 07/09/2024 DWR Adding a random number procedure to get a number from 1 to 5.
(in progress).
- 07/12/2024 DWR Removed the .lst file from the remote repository and tweaked the random routine to yield 0-4.
