call c cga_comp
pklite \compiled\cga_comp.exe
rem not distributing overlay version
rem pkzip -ex -u cga_comp.zip \compiled\cga_comp.exe \compiled\cga_comp.ovr cga_comp.dat cga_comp.txt file_id.diz
sled file_id.diz cga_comp.txt
pkzip -ex -u cga_comp.zip \compiled\cga_comp.exe cga_comp.dat cga_comp.txt file_id.diz
