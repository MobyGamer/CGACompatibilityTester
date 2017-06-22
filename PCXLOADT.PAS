program pcxloadt;

uses
  graph,
  dos,
  support,
  pcx_load;

var
  filestr:pathstr;
  f:file;

begin
  if paramcount<1 then fatalerror(1,'No filename given');
  filestr:=paramstr(1);
  if not fileexists(filestr) then fatalerror(2,filestr+' not found');
  asm
    mov ax,0006
    int 10h
  end;
  read_pcx_file(CGA,filestr);
  fillchar(ptr($b800,0)^,$4000,$00);
  move(buff0^,ptr($b800,0000)^,8000);
  move(buff1^,ptr($ba00,0000)^,8000);
  assign(f,'cga.dmp');
  rewrite(f,1);
  blockwrite(f,ptr($b800,0)^,$4000);
  close(f);
  readkeychar;
end.