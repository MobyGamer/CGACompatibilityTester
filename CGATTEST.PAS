{$O+,F+}
unit CGATTESTS;
{Contains all of the textmode tests/procedures for the CGA compatibility tester}

interface

Procedure Test40col;
Procedure TestSnow;
Procedure TestBlinkBit;
Procedure TestCursor;
Procedure TestFont;

implementation

uses
  strings,m6845ctl,ztimer,support,cgaccommon,cgastaticdata,TInterrupts,
  totmsg,totinput,totIO1,totfast;

Procedure TestSnow;
var
  w:word;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mTSnow].title));
    WinForm^.Win^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This test writes to CGA adapter RAM in a way that');
    AddLine('directly exposes CGA "snow", which is an artifact');
    AddLine('of using single-ported RAM on a CGA adapter.');
    AddLine('');
    AddLine('CGA "snow" looks like noise/static overlaid on the');
    AddLine('screen, and is only visible in fast character-clock');
    AddLine('text modes (ie. 80x25).  The original IBM CGA adapter');
    AddLine('suffered from this problem, as do some compatibles.');
    AddLine('All other video adapters do not have this problem.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  PrepTest;
  Screen.Writeln('If your adapter suffers from CGA "Snow", you should be seeing random noise');
  Screen.Writeln('below this message.  Press a key to exit the test.');
  {To show snow, we deliberately stomp all over screen RAM.  But we wait
  until our informational message has been drawn before doing so, so that
  the message can be read, not covered in snow!}
  w:=0;
  repeat
    asm
      cli
      {wait two line's worth of scanlines}
      call  m6845_WaitStartDisplayCycle
      MOV   DX,m6845_status
      mov   bh,c_display_enable
      mov   cx,(8*2)-1 {need to skip two lines of text}
@hr: {wait during retrace}
      in    AL,DX
      test  AL,bh
      jz    @hr {loop while not in horizontal retrace (ie. still drawing)}
@hor1:
      in    AL,DX
      test  AL,bh
      jnz   @hor1 {loop if in horizontal retrace}
      loop  @hr

      {read and write video memory during beam access to generate snow}
      push ds
      mov ax,$b800
      mov es,ax
      mov ds,ax
      xor si,si
      xor di,di
      mov cx,w
      cld
      rep movsw
      pop ds
      sti
      inc w
      and w,$3ff
    end;
  until keypressed;
  PostTest;
end;

Procedure TestBlinkBit;
var
  foo,fooattr:byte;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mTHCB].title));
    WinForm^.Win^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This test disables the "blink" bit to enable');
    AddLine('the use of all 16 background colors in textmode.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  PrepTest;
  {WriteAT(X,Y,Attr:byte; Str:string);}
  Screen.WriteAT(1,1,$87,'Your video adapter should be blinking this sentence.');
  Screen.WriteAT(1,2,$07,'Press a key to turn off the blink bit and display all background colors.');
  PauseUser;
  Screen.Clear(TWhite,' ');
  m6845_SetMode(c_fast_char_clock+c_videosignal_enable);
  for foo:=0 to 15 do begin
    {build rotating text attribute byte}
    asm
      mov cl,4
      mov al,foo
      mov bl,al
      shl al,cl
      add bl,1
      and bl,00001111b
      or  al,bl
      mov fooattr,al
    end;
    Screen.WriteAT((foo*5)+1,1,fooattr,'text ');
    Screen.WriteAT((foo*5)+1,2,fooattr,'text ');
  end;
  Screen.WriteAT(1,3,$0F,'You should see 16 different BACKGROUND colors above, without any blinking.');
  Screen.WriteAT(1,5,$0F,'Press a key to end the test.');
  PauseUser;
  m6845_SetMode(c_fast_char_clock+c_videosignal_enable+c_blinking_text);
  PostTest;
end;

Procedure TestCursor;
var
  curs,oldcurs:word;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mTCur].title));
    WinForm^.Win^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This test changes the shape of the');
    AddLine('text cursor by directly manipulating');
    AddLine('the M6845 cursor control registers.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  PrepTest;
  Screen.Writeln('Press a key to advance through these tests.');
  Screen.Write('Regular cursor: '); m6845_SetCursorSize($0607);
  PauseUser; Screen.Writeln('');
  Screen.Write('Upside-down cursor: '); m6845_SetCursorSize($0001);
  PauseUser; Screen.Writeln('');
  Screen.Write('Full block cursor: '); m6845_SetCursorSize($0007);
  PauseUser; Screen.Writeln('');
  Screen.Write('Top-and-bottom dual line cursor: '); m6845_SetCursorSize($0601);
  PauseUser; Screen.Writeln('');
  Screen.Write('Strikethrough cursor: '); m6845_SetCursorSize($0503);
  PauseUser; Screen.Writeln('');
  Screen.Write('Back to regular cursor: '); m6845_SetCursorSize($0607);
  PauseUser;
  PostTest;
end;

Procedure Test40col;
var
  x,y:byte;
  smsg:string;
  f:file;
begin
  if interactive then begin
    with InfoPrompt do begin
      init(2,strpas(menuLookup[m40col].title));
      WinForm^.Win^.SetColors(descBorder,descBody,descTitle,descIcons);
      AddLine('');
      AddLine('This test switches into 40-column textmode.');
      AddLine('The most common use of this test is to see');
      AddLine('how thorough CGA "emulation" programs are.');
      AddLine('For example, most "CGA simulator" programs');
      AddLine('for Hercules cards do not make any attempt');
      AddLine('at supporting 40-column mode (although this');
      AddLine('test gives them every chance to, since only');
      AddLine('the BIOS is used to set the mode and print');
      AddLine('the sample text).');
      AddLine('');
      AddLine('This screen also has varying widths of veritcal');
      AddLine('and horizontal bars, making it useful for');
      AddLine('checking for horizontal or vertical jitter.');
      AddLine('');
      SetOption(1,cstring,67,Finished);
      SetOption(2,astring,65,Escaped);
      Result:=Show;
      Done;
    end;
    if Result=Escaped then exit;
  end;
  Preptest;
  asm
    mov ax,0001h {40-column color}
    int 10h
  end;
  smsg:='Welcome to 40-column text mode.'#13#10; BIOSWriteStr(smsg);
  smsg:='Here is the width of this mode:'#13#10#10; BIOSWriteStr(smsg);
  smsg:='0000000000111111111122222222223333333333'#13; BIOSWriteStr(smsg);
  smsg:='0123456789012345678901234567890123456789'#13#10; BIOSWriteStr(smsg);
  smsg:='This should stretch from the left edge'#13#10'to the right edge of the viewable area'#13#10'of the monitor.'#13#10;
  BIOSWriteStr(smsg);
  smsg:='If it only takes up the left half of'#13#10; BIOSWriteStr(smsg);
  smsg:='the monitor, your 40-col mode is broken.'#13#10#10; BIOSWriteStr(smsg);
  if interactive then begin
  smsg:='Press any key to exit the test.'#13#10; BIOSWriteStr(smsg);
  end;
  assign(f,datafile);
  reset(f,1);
  seek(f,(8192+(16000*2)+16384+15360)); {seek to where box data is}

  blockread(f,ptr($b800,40*15*2)^,40*10*2);
  close(f);
  PauseUser;
  PostTest;
end;

Procedure TestFont;
const
  charboxlabel='Character: ';
  charboxx=1+length(charboxlabel); charboxy=11;
  bigcharboxx=charboxx+5; bigcharboxy=charboxy;
  boxofsx=12;
type
  pbyte=^byte;

  Procedure DrawCharBox(bx,by:byte;ic:char;fontdata:pbyte);
  var
    x,y,mask:byte;
    s:string[8];
  begin
    inc(word(fontdata),8*byte(ic)); {advance to char in rom font data}
    for y:=0 to 7 do begin
      mask:=$80; s:='';
      for x:=0 to 7 do begin
        if (fontdata^ AND mask)=mask then s:=s+#219 else s:=s+#0;
        mask:=mask SHR 1;
      end;
      Screen.WriteAt(bx,by+y,$0f,s);
      inc(word(fontdata));
    end;
  end;

var
  f:file;
  fdata:pointer;
  pmda,pcgathin,pcgathick:pbyte;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mFont].title));
    WinForm^.Win^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This test displays a single character and then');
    AddLine('enlarges it 8x so you can compare if your adapter');
    AddLine('is using the typical CGA 8x8 ROM font.');
    AddLine('The enlargement is performed using the data from');
    AddLine('the original CGA character ROM for authenticity.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  PrepTest;
  {set up pointers to rom font data}
  getmem(fdata,8192);
  assign(f,datafile);
  reset(f,1);
  blockread(f,fdata^,8192);
  close(f);
  pmda:=fdata; pcgathin:=pmda; pcgathick:=pmda;
  inc(word(pcgathick),6144);
  inc(word(pcgathin),4096);

  with Screen do begin
    Writeln('Press any key to display that key''s character in regular and large sizes.');
    Writeln('Use the enlarged displays to check if your adapter''s font matches');
    Writeln('what the real IBM CGA uses.  Most CGA adapters are jumpered to use the "thick"');
    Writeln('font; consequently, that font is what most programs expect to be in use.');
    Writeln('');
    Writeln('Try these characters, as they differ visibly between thick and thin fonts:');
    Writeln('@ X W Y U S M');
    Writeln('');
    Writeln('Press ESC to exit the test.');
    WriteAT(charboxx-length(charboxlabel)+1,charboxy+1,$07,charboxlabel);
    Box(charboxx,charboxy,charboxx+2,charboxy+2,$07,1);
    TitledBox(bigcharboxx,bigcharboxy,bigcharboxx+8+1,bigcharboxy+8+1,$07,$07,$07,2,'Thick');
    TitledBox(boxofsx+bigcharboxx,bigcharboxy,boxofsx+bigcharboxx+8+1,bigcharboxy+8+1,$07,$07,$07,1,'Thin');
    repeat
      Key.GetInput;
      WriteAt(charboxx+1,charboxy+1,$0f,Key.LastChar);
      DrawCharBox(bigcharboxx+1,bigcharboxy+1,Key.LastChar,pcgathick);
      DrawCharBox(bigcharboxx+1+boxofsx,bigcharboxy+1,Key.LastChar,pcgathin);
    until Key.LastKey=27{esc};
  end;
  freemem(fdata,8192);

  PostTest;
end;

end.
