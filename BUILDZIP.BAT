call c cga_comp
pklite \compiled\cga_comp.exe
sled file_id.diz cga_comp.txt
pkzip -ex -u cga_comp.zip \compiled\cga_comp.exe cga_comp.txt file_id.diz
