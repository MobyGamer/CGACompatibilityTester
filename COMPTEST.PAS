{$O+,F+}
unit COMPTESTS;
{Contains all of the Composite Monitor tests for the CGA compatibility tester}

interface

Procedure DetermineCardType;
Procedure LoTextColors;
Procedure LoGrafColors;

implementation

uses
  strings,m6845ctl,ztimer,support,cgaccommon,cgalib,TInterrupts,
  totmsg,totinput,totIO1,totfast;

const
  componly='COMPOSITE ONLY -- Do not view on RGB!';

procedure show_oldornew; external; {$L oldornew.obj}

Procedure DetermineCardType;
const
  scrsize=40*192*2;
var
  f:file;
  fdata:pointer;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mCompWhich].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('IBM issued two basic models of CGA cards, which had slightly');
    AddLine('different color output between both models.');
    AddLine('');
    AddLine('Knowing this information can help you experience programs');
    AddLine('that use composite color as the authors originally intended.');
    AddLine('For example, early games like Pitstop II, Burgertime,');
    AddLine('and Microsoft Decathlon display properly on older cards,');
    AddLine('while later games like California Games targeted newer cards.');
    AddLine('');
    AddLine('This test pattern helps determine which CGA card model is');
    AddLine('installed.  The display will change to an image with the words');
    AddLine('"OLD" and "NEW" overlaid on top of each other.  The word that');
    AddLine('appears most distinct indicates the type of card installed.');
    AddLine('');
    AddLine('THE KEYBOARD IS DISABLED WHILE THE TEST PATTERN IS DISPLAYED.');
    AddLine('After 20 seconds, this pattern will exit to the main menu.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  Preptest;
  {PauseUser;}
  asm
        mov     ax,0001h
        int     10h
  end;
  fdata:=ptr($b800,0);
  assign(f,datafile);
  reset(f,1);
  seek(f,8192+16000+16000+16384); {seek to where screen is}
  blockread(f,fdata^,scrsize);
  close(f);
  asm
        mov     ax,0b800h
        mov     es,ax
        xor     di,di
        cld
        mov     cx,8192-40*192
        xor     ax,ax
        rep     stosw
        call    show_oldornew
  end;
  PostTest;
end;

Procedure LoTextColors;
const
  {bits for 6845 $3d8 video control}
  c_80cols=1;
  c_graphicsmode=2;
  c_blackandwhite=4;
  c_videosignalenable=8;
  c_640graphics=16;
  c_blink=32;

  {bits for 6845 $3d9 color control}
  c_red=1;
  c_green=2;
  c_blue=4;
  c_intensity=8;
  c_backgroundintensity=16;
  c_palette1=32;

  cols=40;
  rows=25;

  width=20;
  height=3;
  {labels:array[0..7] of string[40]=(
    '00:Black            08:Dark Gray    ',
    '01:Blue             09:Violet       ',
    '02:Green            10:Light Green  ',
    '03:Forest Green     11:Seafoam      ',
    '04:Brick Red        12:Pink         ',
    '05:Magenta          13:Light Magenta',
    '06:Forest Green     14:Olive        ',
    '07:Grey             15:White        ');}

var
  y,x,baz:byte;

  procedure putcharxy(x,y,ch:byte);
  begin
    mem[$b800:(y*80)+(x*2)]:=ch;
  end;

  procedure putAttrXY(x,y,fore,back:byte);
  begin
    mem[$b800:(y*80)+(x*2)+1]:=(back SHL 4) or fore;
  end;

  procedure dumbWriteXY(x,y:word;s:string);
  var
    w:word;
  begin
    for w:=0 to 40-1 do begin
      putcharxy(x+w,y,byte(s[w+1]));
    end;
  end;

begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mCompLo].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('What follows is a simple color test plate');
    AddLine('in 40-column color text mode.  Text mode');
    AddLine('colors on a composite monitor differ from');
    AddLine('those on an RGB monitor.');
    AddLine('');
    AddLine('The color labels in this test were derived');
    AddLine('from an "old-style" CGA card.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  Preptest;
  asm
    mov ax,0001
    int 10h
    mov dx,3d8h
    mov al,c_videosignalenable {see c_??? const section for explanation}
    out dx,al
    mov cx,rows*cols
    mov ax,$b800
    mov es,ax
    xor di,di
    mov ax,0720h {0=back, 7=fore, 20=space}
    rep stosw
  end;
  for y:=0 to 7 do begin
    for x:=0 to width-1 do begin
      for baz:=0 to height-1 do begin
        {left bar}
        putAttrXY(x,(y*height)+baz,15,y);{15=white text}
        {right bar}
        putAttrXY(x+width,(y*height)+baz,0,y+8);{0=black text}
      end;
    end;
  end;
  {Write out the labels.  This is very dumb but we do it this way
  so that we can get the strings in the overlaid code segment.}
  dumbWriteXY(0,1, '00:Black            08:Dark Gray    ');
  dumbWriteXY(0,4, '01:Blue             09:Violet       ');
  dumbWriteXY(0,7, '02:Green            10:Light Green  ');
  dumbWriteXY(0,10,'03:Moss Green       11:Seafoam      ');
  dumbWriteXY(0,13,'04:Brick Red        12:Pink         ');
  dumbWriteXY(0,16,'05:Magenta          13:Light Magenta');
  dumbWriteXY(0,19,'06:Forest Green     14:Olive        ');
  dumbWriteXY(0,22,'07:Grey             15:White        ');

  {for y:=0 to 7 do begin
    for x:=0 to 40-1 do begin
      putcharxy(x,(y*height)+1,byte(labels[y][x+1]));
    end;
  end;}
  dumbWriteXY(0,24,componly);
  PauseUser;
  PostTest;
end;

Procedure LoGrafColors;
const
  barheight=8*3;
  barwidth=80;
  {labels:array[0..15] of pchar=(
  '00:Black',
  '01:Dark Green',
  '02:Royal Blue',
  '03:Medium Blue',
  '04:Dark Red',
  '05:Gray',
  '06:Purple',
  '07:Periwinkle',
  '08:Dark YellowGreen',
  '09:Green',
  '10:Gray',
  '11:Aquamarine',
  '12:Red',
  '13:Yellow',
  '14:Rose',
  '15:White'
  );}
var
  x,y,c:word;
  s:string;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mCompHi].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('What follows is a simple color test plate using the most');
    AddLine('common low-res composite color graphics mode used by');
    AddLine('older CGA games.');
    AddLine('');
    AddLine('The colors are labeled according to how they appear on an');
    AddLine('old-style CGA card connected to a composite color monitor.');
    AddLine('Note: BIOSes that are not 100% IBM compatible may fail to');
    AddLine('draw the labels.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  Preptest;
  vs:=new(pvidCGAGcomposite,Init(composite,false)); {compatibility=false so BIOS isn't called to set mode}
  asm
    {fool BIOS into thinking we're in 320x200 mode so char printing works}
    mov ax,$40
    mov es,ax
    mov di,$49 {40:49 location of screen mode}
    mov al,4
    stosb
    mov al,40  {40:4a number of screen columns}
    stosb
  end;
  for y:=0 to 7 do begin
    {left bar}
    vs^.box(0,y*barheight,barwidth-1,(y*barheight)+barheight-1,y);
    {BIOSGotoXY(0,(y*3)+1); s:=strpas(labels[y]); BIOSWriteStr(s);}
    {right bar}
    vs^.box(barwidth,y*barheight,(barwidth*2)-1,(y*barheight)+barheight-1,y+8);
    {BIOSGotoXY(20,(y*3)+1); s:=strpas(labels[y+8]); BIOSWriteStr(s);}
  end;
  BIOSGotoXY(0, (0*3)+1); s:='00:Black';            BIOSWriteStr(s);
  BIOSGotoXY(20,(0*3)+1); s:='08:Dark YellowGreen'; BIOSWriteStr(s);
  BIOSGotoXY(0, (1*3)+1); s:='01:Dark Green';       BIOSWriteStr(s);
  BIOSGotoXY(20,(1*3)+1); s:='09:Green';            BIOSWriteStr(s);
  BIOSGotoXY(0, (2*3)+1); s:='02:Royal Blue';       BIOSWriteStr(s);
  BIOSGotoXY(20,(2*3)+1); s:='10:Gray';             BIOSWriteStr(s);
  BIOSGotoXY(0, (3*3)+1); s:='03:Medium Blue';      BIOSWriteStr(s);
  BIOSGotoXY(20,(3*3)+1); s:='11:Aquamarine';       BIOSWriteStr(s);
  BIOSGotoXY(0, (4*3)+1); s:='04:Dark Red';         BIOSWriteStr(s);
  BIOSGotoXY(20,(4*3)+1); s:='12:Red';              BIOSWriteStr(s);
  BIOSGotoXY(0, (5*3)+1); s:='05:Gray';             BIOSWriteStr(s);
  BIOSGotoXY(20,(5*3)+1); s:='13:Yellow';           BIOSWriteStr(s);
  BIOSGotoXY(0, (6*3)+1); s:='06:Purple';           BIOSWriteStr(s);
  BIOSGotoXY(20,(6*3)+1); s:='14:Rose';             BIOSWriteStr(s);
  BIOSGotoXY(0, (7*3)+1); s:='07:Periwinkle';       BIOSWriteStr(s);
  BIOSGotoXY(20,(7*3)+1); s:='15:White';            BIOSWriteStr(s);

  BIOSGotoXY(0,24); s:=componly; BIOSWriteStr(s);
  PauseUser;
  dispose(vs,done);
  PostTest;
end;

end.
