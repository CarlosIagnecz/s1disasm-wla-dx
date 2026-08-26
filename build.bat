:: Build ROMs on Windows operating systems
:: TODO: Merge both build scripts into a makefile
@echo OFF
Title Compiling the Sonic 1 Disassembly (wla-dx)

:: Change path to include wla-dx if you haven't
::set path=%PATH%;path/to/wla-dx

set output_filename=s1built

:: Compiler Flags
set flags_z80=-v -o
set flags_68k=-v -o
set flags_lnk=-r -S

:: Delete old ROM.
del /F Build\%output_filename%.prev.gen
del /F Build\pcm_driver.z80
del /F Build\z80_boot.z80

:: Backup the most recent ROM.
move /Y Build\%output_filename%.gen Build\%output_filename%.prev.gen

echo ----------------------------------------
echo ---           Compiling...           ---
echo ----------------------------------------

:: Link compiled binaries to make ROM file.

:: Compile libraries.
:: By default there are no libraries with ROM data.

:: Compile object files.
echo:
echo -----------------------------[Sound/z80.asm]

wla-z80 %flags_z80% Build\pcm_driver.o Sound\z80.asm
cd Build
::wlalink %flags_lnk% link_pcm.def pcm_driver.z80
cd ..
echo:
echo ------------------------[misc/Z80 Boot.asm]

wla-z80 %flags_z80% Build\z80_boot.o "misc\Z80 Boot.asm"
cd Build
wlalink %flags_lnk% link_z80_boot.def z80_boot.z80
cd ..
echo:
echo --------------------------------[sonic.asm]
wla-68000 %flags_68k% Build\sonic.o sonic.asm
cd Build
wlalink %flags_lnk% link_main.def "%output_filename%.gen"
cd ..
