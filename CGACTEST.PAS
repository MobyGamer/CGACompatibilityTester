{$O+,F+}
unit CGACTESTS;
{Contains all of the color select register tests for the CGA compatibility tester}

interface

Procedure TestBorder;
Procedure TestBackCol;
Procedure TestForeCol;
Procedure TestPalettes;

implementation

uses
  strings,m6845ctl,ztimer,support,cgaccommon,cgalib,{cgalib_g,}
  totmsg,totinput,totIO1,totfast;

Procedure CycleColors;
var
  x:byte;
  oldtick:longint;
  exitnow,paused:boolean;
begin
  x:=0; exitnow:=false; paused:=false;
  repeat
    if not paused then begin
      inc(x); x:=x AND $0f; m6845_SetColor(x);
      oldtick:=tickssincemidnight; repeat until tickssincemidnight > (oldtick+9);
    end;
    if keypressed then
      case upcase(readkeychar) of
      'P':paused:=not paused;
      else
        exitnow:=true;
      end;
  until exitnow;
end;

Procedure TestBorder;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mBCol].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This test alters the M6845 Color Select Register');
    AddLine('while in text mode to change the border color.');
    AddLine('You can press "P" to pause/unpause the color cycling.');
    AddLine('');
    AddLine('This test is meant for RGB monitors only.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  Preptest;
  Screen.Writeln('This test changes the color of the border ("overscan") area.');
  Screen.Writeln('The border should be cycling through all 16 colors, one every half-second.');
  Screen.Writeln('If you don''t see any colors changing, your monitor is most likely sized to the');
  Screen.Writeln('edges of the viewable area, which doesn''t leave space for overscan.');
  Screen.Writeln('');
  Screen.Writeln('Press any key to exit.');
  CycleColors;
  m6845_SetColor(0);
  PostTest;
end;

Procedure TestBackCol;
var
  smsg:string;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mMCol].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This test alters the M6845 Color Select Register while');
    AddLine('in medium-res graphics mode to change the background color.');
    AddLine('');
    AddLine('You can press "P" to pause/unpause the color cycling.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  Preptest;
  vs:=new(pvidCGAGmode4,Init(mode4,false));
  asm
    mov ax,0004h
    int 10h
  end;
  DrawTestplate;
  smsg:='Welcome to medium-res graphics.'#13#10; BIOSWriteStr(smsg);
  smsg:='This test changes the background color.'#13#10; BIOSWriteStr(smsg);
  smsg:='The background, INCLUDING the'#13#10; BIOSWriteStr(smsg);
  smsg:='border/overscan area, should be cycling'#13#10; BIOSWriteStr(smsg);
  smsg:='through all sixteen colors, one every'#13#10; BIOSWriteStr(smsg);
  smsg:='half-second.'#13#10#10; BIOSWriteStr(smsg);
  smsg:='Press any key to exit.'#13#10; BIOSWriteStr(smsg);
  CycleColors;
  dispose(vs,done);
  PostTest;
end;

Procedure TestForeCol;
var
  smsg:string;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mHCol].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This test alters the M6845 Color Select Register while');
    AddLine('in high-res graphics mode to change the foreground color.');
    AddLine('You can press "P" to pause/unpause the color cycling.');
    AddLine('');
    AddLine('This test does nothing on Composite monitors.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  Preptest;
  {vs^.init(mode6,true);}
  vs:=new(pvidCGAGmode6,Init(mode6,true));
  asm
    mov ax,0006h
    int 10h
  end;
  DrawTestplate;
  smsg:='Welcome to high-res graphics.  This test changes the foreground color.'#13#10; BIOSWriteStr(smsg);
  smsg:='The foreground should be cycling through all 16 colors, one every half-second.'#13#10; BIOSWriteStr(smsg);
  smsg:='Press any key to exit.'#13#10; BIOSWriteStr(smsg);
  CycleColors;
  dispose(vs,done);
  PostTest;
end;

Procedure TestPalettes;
const
  boxx=50; boxy=50; boxdim=100;
var
  x:byte;
  oldtick:longint;
  smsg:string;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mPal].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This test displays all six CGA foreground palettes');
    AddLine('available in medium-res graphics mode.');
    AddLine('');
    AddLine('On an RGB monitor, the last two palettes will be');
    AddLine('cyan, red, white (low) and cyan, red, white (high).');
    AddLine('');
    AddLine('On a composite monitor, the last two palettes will');
    AddLine('have no color at all, which is normal.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  Preptest;
  x:=0;
  vs:=new(pvidCGAGmode4,Init(mode4,false));
  asm
    mov ax,0004h
    int 10h
  end;
  DrawTestplate;
  vs^.box(boxx   ,boxy   ,boxx+boxdim   ,boxy+boxdim   ,1);
  vs^.box(boxx+50,boxy+40,boxx+boxdim+50,boxy+boxdim+40,2);
  vs^.box(boxx+100,boxy+20,boxx+boxdim+100,boxy+boxdim+20,3);
  smsg:='Welcome to medium-res graphics.'#13#10; BIOSWriteStr(smsg);
  smsg:='Press any key to cycle through palettes.'#13#10#10; BIOSWriteStr(smsg);

  m6845_SetColor(c_paletteCMW);
  smsg:='This is cyan/magenta/white (low). '#13; BIOSWriteStr(smsg); PauseUser;

  m6845_SetColor(c_paletteCMW+c_alternate_intensity);
  smsg:='This is cyan/magenta/white (high).'#13; BIOSWriteStr(smsg); PauseUser;

  m6845_SetColor(0);
  smsg:='This is green/red/yellow (low).   '#13; BIOSWriteStr(smsg); PauseUser;

  m6845_SetColor(c_alternate_intensity);
  smsg:='This is green/red/yellow (high).  '#13; BIOSWriteStr(smsg); PauseUser;

  m6845_SetColor(c_paletteCMW);
  m6845_Setmode(c_graphics_enable+c_videosignal_enable+c_blackandwhite_enable);
  smsg:='This is cyan/red/white (low).     '#13; BIOSWriteStr(smsg); PauseUser;

  m6845_SetColor(c_paletteCMW+c_alternate_intensity);
  smsg:='This is cyan/red/white (high).    '#13; BIOSWriteStr(smsg); PauseUser;
  dispose(vs,done);
  PostTest;
end;

end.
