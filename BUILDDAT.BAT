rem copy /b cga_font.rom+shadcube.raw+tylerpic.raw+aspect.raw cga_comp.dat
rem copy /b cga_font.rom+shadcube.raw+colorf1.raw+aspect.raw+whichcga.bin cga_comp.dat

dir cga_font.rom
dir shadcube.raw
pause
dir colorf1.raw
dir indiantp.raw
pause
dir whichcga.bin
dir boxes.bin

copy /b cga_font.rom+shadcube.raw+colorf1.raw+indiantp.raw+whichcga.bin+boxes.bin cga_comp.dat
