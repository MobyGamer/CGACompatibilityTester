unit CGA_OVERLAY;
{must get overlay manager initialized before all others}

{{$DEFINE EMSWTF}

interface

implementation

Uses
  Overlay;
  {support} {do NOT overlay this unit or ovrinit will fail!}

const
  OvrMaxSize:longint=128*1024; {choose a default max size of 128K}
  (*ProgMemNeeds=16*1024; {amount of memory to leave for the program}*)
  ProgMemNeeds=8*1024; {amount of memory to leave for the program}
  AcceptableBufSize=40*1024;
  ovrname='CGA_COMP.OVR';
  foo:longint=0;

Function FileExists(filename:String):Boolean;
Var
  f:File;
Begin
  Assign(f,filename);
  {$I-}
  Reset(f);
  Close(f); {need this or you run out of file handles calling me repeatedly!}
  {$I+}
  FileExists:=(IOResult = 0);
End;

Function SizeOfFile(filename:string):longint;
Var
  f:File;
  foo:LongInt;
Begin
  If fileexists(filename) Then Begin
    Assign(f,filename);
    Reset(f,1);
    foo:=FileSize(f);
    Close(f);
    sizeoffile:=foo;
  End Else SizeOfFile:=-1;
End;

Function KeyPressed:Boolean; Assembler;
Asm
  mov ah, 01h
  int 16h
  mov ax, 00h
  jz @1
  inc ax
  @1:
end;

Function ReadKeyChar:Char; Assembler;
Asm
  mov ah, 00h
  int 16h
  cmp al,0
  jne @endit
  mov al,ah
@endit:
end;

Procedure ReportError;
begin
  case OvrResult of
    ovrOK            :Writeln('Overlay successful.');
    ovrNotFound      :Writeln('Overlay missing!');
    ovrNoMemory      :Writeln('Not enough memory to alter cache.');
    ovrIOError       :Writeln('I/O error!');
    {$IFDEF EMSWTF}
    ovrNoEMSDriver   :Writeln('No EMS driver installed.');
    ovrNoEMSMemory   :Writeln('Not enough EMS available.');}
    {$ENDIF}
  else
    Writeln('Unknown error.');
  end; {case}
end;

begin
  {First, initialize the overlay, since we can't continue until this succeeds.}
  Writeln('Initializing overlay manager...');
  OvrInit('CGA_COMP.OVR');
  if OvrResult <> ovrOk then begin
    ReportError;
    Halt(1);
  end;
  {$IFDEF EMSWTF}
  OvrInitEMS;
  {$ENDIF}
  {if we can see our overlay file, make the max overlay buffer big enough to hold it}
  if fileexists(ovrname)
    then OvrMaxSize:=sizeoffile(ovrname);
  if maxavail > (OvrMaxSize+ProgMemNeeds)
    then foo:=OvrMaxSize {try to max it out}
    else foo:=maxavail - ProgMemNeeds;
  OvrSetBuf(foo);
  if OvrResult <> ovrOk then ReportError;
  if OvrGetBuf < AcceptableBufSize then begin
    Writeln('Not enough memory to increase cache area.');
    Writeln('Cache size: ',OvrGetBuf div 1024,'KB.  Operation will be sluggish.  Press a key.');
    repeat until keypressed; while keypressed do readkeychar;
  end;
end.
