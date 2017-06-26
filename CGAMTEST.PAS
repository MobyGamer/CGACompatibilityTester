{$O+,F+}
unit CGAMTESTS;
{Contains all of the Monitor calibration tests for the CGA compatibility tester}

interface

Procedure CalibBrightness;
Procedure CalibContrast;
Procedure CalibMoire;
Procedure CalibColor;
Procedure CalibAspectNTSC;
Procedure CalibUniform;
Procedure CalibLinearRGB;
Procedure CalibLinearComp;

implementation

uses
  strings,m6845ctl,ztimer,support,cgaccommon,cgalib,TInterrupts,tfastwrite,
  totmsg,totinput,totIO1,totfast;

Procedure CalibBrightness;
var
  foo:byte;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mBCal].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This test pattern assists in calibrating');
    AddLine('the brightness control on your monitor.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  PrepTest;
  m6845_SetMode(c_fast_char_clock+c_videosignal_enable); {turn off blink}
  with Screen do begin
    FillBox(1,1,3,2,$FF,1);
    FillBox(80-2,1,80,2,$FF,1);
    FillBox(1,25-1,3,25,$FF,1);
    FillBox(80-2,25-1,80,25,$FF,1);
    FillBox(40-2,11,40+2,13,$FF,1);
    WriteCenter(4,$07,'This pattern helps calibrate the brightness control on your RGB monitor.');
    WriteCenter(5,$07,'To start, turn your brightness control all the way up.');
    WriteCenter(19,$07,'Now examine the screen:');
    WriteCenter(20,07,'If the background is now dark gray, turn it down until it is black again.');
    WriteCenter(21,$07,'If any box edges are fuzzy ("blooming"), turn it down until they are sharp.');
    WriteCenter(25,$07,'Press any key to exit.');
  end;
  PauseUser;
  PostTest;
end;

Procedure BrownNote;
begin
  with InfoPrompt do begin
    AddLine('A working IBM RGBI monitor shows color index #6 as brown, not dark yellow.');
    AddLine('(Color #6 was intentionally darkened by IBM using monitor electronics.)');
    AddLine('This pattern clearly labels brown so you know what to expect.');
  end;
end;

Procedure CalibContrast;
var
  foo:byte;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mCCal].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This test pattern assists in calibrating your monitor''s contrast control.');
    AddLine('');
    AddLine('Use this pattern to adjust any color, saturation, or hue controls if');
    AddLine('present on your RGB output device.  The goal is to get each color as');
    AddLine('rich as possible without overdriving the monitor (ie. making the colors');
    AddLine('''fuzzy'' or blurred).');
    AddLine('All text should be clear and distinct against the background.');
    AddLine('');
    BrownNote;
    AddLine('');
    AddLine('This test is not intended for composite monitors.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  PrepTest;
  with Screen do begin
    TitledBox( 1,1,20,8, $08,$08,$08,4,'|Dark Gray->black');
    TitledBox(21,1,40,8, $19,$19,$19,4,'|Light Blue->blue');
    TitledBox(41,1,60,8, $2a,$2a,$2a,4,'|Light Green->green');
    TitledBox(61,1,80,8, $3b,$3b,$3b,4,'|Light Cyan->cyan');
    TitledBox( 1,9,20,17,$4c,$4c,$4c,4,'|Light Red->red');
    TitledBox(21,9,40,17,$5d,$5d,$5d,4,'|Light Mag->magenta');
    TitledBox(41,9,60,17,$6e,$6e,$6e,4,'|Yellow->brown');
    TitledBox(61,9,80,17,$7f,$7f,$7f,4,'|White->gray');

    WriteCenter(18,$07,'This pattern helps calibrate the contrast control on your RGB monitor.');
    WriteCenter(19,$07,'Each of these boxes has a title and border in a lighter color than the');
    WriteCenter(20,$07,'box itself.  Adjust your contrast control until you can clearly see the');
    WriteCenter(21,$07,'titles/borders stand out against the boxes.');
    WriteCenter(23,$0F,'If you cannot see the titles/borders, there is something wrong with the');
    WriteCenter(24,$0F,'intensity pin of your adapter or monitor.  Consult a CGA pinout to fix.');
    WriteCenter(25,$07,'Press any key to exit.');
  end;
  PauseUser;
  PostTest;
end;

Procedure CalibMoire;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mMoire].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('What follows are three test patterns to help calibrate');
    AddLine('any horizontal, vertical, or rotational monitor controls.');
    AddLine('The patterns are engineered to display "moire" interference');
    AddLine('patterns on monitors that are not properly calibrated.');
    AddLine('Press any key during the test to move to the next pattern.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  Preptest;
  asm
    mov ax,0006h
    int 10h

    {first test pattern: horizontal lines}
    mov ax,$b800
    mov es,ax
    xor di,di
    mov cx,(80*100) / 2
    mov ax,$ffff
    rep stosw
  end;
  PauseUser;

  asm
    {second pattern: vertical lines}
    mov ax,$b800
    mov es,ax
    xor di,di
    mov cx,$2000
    mov ax,0011001100110011b
    rep stosw
  end;
  PauseUser;

  asm
    {last pattern: 50%}
    mov ax,$b800
    mov es,ax
    xor di,di
    mov cx,$1000
    mov ax,0101010101010101b
    rep stosw
    mov ax,$ba00
    mov es,ax
    xor di,di
    mov cx,$1000
    mov ax,1010101010101010b
    rep stosw
  end;
  PauseUser;

  PostTest;
end;

Procedure CalibAspectNTSC;
{show test pattern with 4:3 DAR composite monitor}
var
  f:file;
  fdata:pointer;
begin
  if interactive then begin
    with InfoPrompt do begin
      init(2,strpas(menuLookup[mAspectNTSC].title));
      WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
      AddLine('');
      AddLine('What follows is a classic test pattern designed to help you');
      AddLine('adjust the vertical size controls on your composite monitor');
      AddLine('so that the aspect ratio appear correct.  (Incorrect aspect');
      AddLine('leads to geometric distortion, such as circles looking like');
      AddLine('ovals, squares looking like rectangles, etc.)');
      AddLine('');
      AddLine('Adjust the vertical size control (and horizontal, if you have');
      AddLine('one) until the circles appear perfectly circular.');
      AddLine('');
      AddLine('This test may not be appropriate for all CGA RGB monitors.');
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
    mov ax,0006h
    int 10h
  end;
  fdata:=ptr($b800,0);
  assign(f,datafile);
  reset(f,1);
  seek(f,8192+16000+16000); {seek to where aspect diag is}
  blockread(f,fdata^,16384);
  close(f);
  PauseUser;
  PostTest;
end;

Procedure CalibColor;
const
  labello1='                                                                        Light   ';
  labello2='  Black      Blue     Green      Cyan      Red     Magenta    Brown     Gray    ';
  labelhi1='   Dark     Light     Light     Light     Light     Light                       ';
  labelhi2='   Gray      Blue     Green      Cyan      Red     Magenta    Yellow    White   ';

(*
  blabels:array[0..15] of string[15]=(
  'Black',
  'Blue',
  'Green',
  'Cyan',
  'Red',
  'Magenta',
  'Brown',
  'Light Gray',
  'Dark Gray',
  'Light Blue',
  'Light Green',
  'Light Cyan',
  'Light Red',
  'Light Magenta',
  'Yellow',
  'White'
  );
*)
var
  foo,fooattr:byte;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mColor].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('The following test pattern displays all available colors, with each');
    AddLine('color labeled.  Use this pattern to adjust any color, saturation, or hue');
    AddLine('controls if present on your RGB monitor.  The goal of this is to get');
    AddLine('each color as rich as possible without overdriving the monitor (ie.');
    AddLine('making the colors ''fuzzy'' or blurred).  As for hue adjustment, a good');
    AddLine('rule of thumb is that "yellow" (the color next to white) should be the');
    AddLine('color of a lemon, and not reddish or greenish in tint.');
    AddLine('');
    BrownNote;
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  Preptest;

  m6845_SetMode(c_fast_char_clock+c_videosignal_enable);
  for foo:=0 to 7 do begin
    {build rotating text attribute byte}
    asm
      mov cl,4
      mov al,foo
      mov bl,al
      shl al,cl
      add bl,2 {shifting only one over makes some hard to read}
      and bl,00001111b
      or  al,bl
      mov fooattr,al
    end;
    Screen.FillBox(1+(foo*10),1,10+(foo*10),12,fooattr,0);
  end;
  for foo:=8 to 15 do begin
    {build rotating text attribute byte}
    asm
      mov cl,4
      mov al,foo
      mov bl,al
      shl al,cl
      add bl,2
      and bl,00001111b
      or  al,bl
      mov fooattr,al
    end;
    Screen.FillBox(1+(foo*10),12,10+(foo*10),23,fooattr,0);
  end;

  Screen.WritePlain(1,2,labello1);
  Screen.WritePlain(1,3,labello2);
  Screen.WritePlain(1,23,labelhi1);
  Screen.WritePlain(1,24,labelhi2);

  for foo:=0 to 7 do Screen.WritePlain((foo*10)+1,1,' Color #'+inttostr(foo));
  for foo:=8 to 15 do Screen.WritePlain((foo*10)+1,21,' Color #'+inttostr(foo));
  {Screen.WriteCenter(25,$0F,'Press any key to rearrange into horizontal bars.');}
  PauseUser;

  Screen.clear($0e,#0);
  with screen do begin
    fillbox(1,1,80,1,$00,0);
    fillbox(1,2,80,2,$01,220);
    fillbox(1,3,80,3,$11,0);

    fillbox(1,4,80,4,$22,0);
    fillbox(1,5,80,5,$23,220);
    fillbox(1,6,80,6,$33,0);

    fillbox(1,7,80,7,$44,0);
    fillbox(1,8,80,8,$45,220);
    fillbox(1,9,80,9,$55,0);

    fillbox(1,10,80,10,$66,0);
    fillbox(1,11,80,11,$67,220);
    fillbox(1,12,80,12,$77,0);

    fillbox(1,13,80,13,$88,0);
    fillbox(1,14,80,14,$89,220);
    fillbox(1,15,80,15,$99,0);

    fillbox(1,16,80,16,$aa,0);
    fillbox(1,17,80,17,$ab,220);
    fillbox(1,18,80,18,$bb,0);

    fillbox(1,19,80,19,$cc,0);
    fillbox(1,20,80,20,$cd,220);
    fillbox(1,21,80,21,$dd,0);

    fillbox(1,22,80,22,$ee,0);
    fillbox(1,23,80,23,$ef,220);
    fillbox(1,24,80,24,$ff,0);
  end;

  {Screen.WriteCenter(25,$0F,'Press any key to rearrange into vertical bars.');}
  PauseUser;
  Screen.clear($0e,#0);

  for foo:=0 to 15 do
    Screen.FillBox((foo*5)+1,1,(foo*5)+5,24,(foo shl 4) OR foo,0);

  {Screen.WriteCenter(25,$0F,'Press any key to exit.');}
  PauseUser;
  m6845_SetMode(c_fast_char_clock+c_videosignal_enable+c_blinking_text);
  PostTest;
end;

Procedure CalibUniform;
const
  pins:array[0..3] of byte=(c_red,c_green,c_blue,c_bright);
  labels:boolean=true;
var
  c:char;
  colr,cidx:byte;
  s:string;
  sp:pointer;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mUniform].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('The following screens allow you to inspect your RGB monitor');
    AddLine('for color uniformity and purity.  We will rotate through the');
    AddLine('RED, GREEN, BLUE, and INTENSITY pins on your RGB monitor to');
    AddLine('fill the entire screen with a solid color, which allows you');
    AddLine('to inspect for dark areas or other purity issues.');
    AddLine('');
    AddLine('Controls: SPACE advances through each pin');
    AddLine('          0-9,A-F will force a specific color to be displayed');
    AddLine('');
    AddLine('During this test, the hsync and vsync pulses are disabled,');
    AddLine('allowing for better measurement of the CGA composite signal');
    AddLine('for diagnostic purposes.  This will not harm your monitor,');
    AddLine('although it will confuse capture devices and scan converters.');
    AddLine('Sync will be re-established when you exit the test.');
    AddLine('');
    AddLine('Press ESC when finished.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  Preptest;
  asm
        mov     ax,0004
        int     10h
        {disable hsync and vsync pulses}
        mov     dx,$3d4
        xor     ax,ax
        out     dx,ax
        inc     dx
        mov     al,$10
        out     dx,al

        dec     dx
        mov     al,4
        out     dx,ax
        inc     dx
        mov     al,$10
        out     dx,al
  end;
  {tfastinit(40,25*4);
  tfpreventsnow:=false;
  sp:=ptr($b800,0);
  m6845_SetMode(c_videosignal_enable);}
  cidx:=0;
  colr:=pins[cidx];
  repeat
    {m6845_waitvertretrace;}
    m6845_setcolor(colr);
    {asm
        mov     ax,$b800
        mov     es,ax
        xor     di,di
        mov     ah,colr
        mov     al,219
        mov     cx,1000
        rep     stosw
    end;
    if labels then begin
      s:='';
      if (colr and 8)=8 then s:=s+'I' else s:=s+'i';
      if (colr and 4)=4 then s:=s+'R' else s:=s+'r';
      if (colr and 2)=2 then s:=s+'G' else s:=s+'g';
      if (colr and 1)=1 then s:=s+'B' else s:=s+'b';
      s:=s+': '+strpas(CGAColorLabels[colr]);
      tfastwritexy(@s,sp,15,12,$0F);
    end;}
    c:=upcase(readkeychar);
    case c of
      #32:begin
            inc(cidx); cidx:=cidx AND 3; colr:=pins[cidx];
          end;
      {#13:begin
            labels:=false;
          end;}
      'A'..'F':colr:=10+byte(c)-ord('A');
      '0'..'9':colr:=1 +byte(c)-ord('1');
    end;
  until c=#27;
  PostTest;
end;

Procedure AddLinearityText;
begin
  with InfoPrompt do begin
    AddLine('This test helps measure monitor linearity and convergence.');
    AddLine('Two patterns will be displayed; press a key to advance them.');
    AddLine('');
    AddLine('Linearity: A grid of rectangles will be shown.  Each complete');
    AddLine('rectangle should be the same size as every other complete rectangle.');
    AddLine('');
    AddLine('Convergence: A grid of dots will be shown.  Each dot should be');
    AddLine('as pure to "white" as possible without any color fringing.');
  end;
end;

Procedure CalibLinearRGB;
const
  xdiv=20;
  ydiv=20;
  xofs=0;
  yofs=0;
var
  x,y,c:word;
  xcoll,xcolr,ycolt,ycolb:integer;
  s:string;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mLinearRGB].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLinearityText;
    AddLine('');
    {AddLine('The geometry in this test is for RGB monitors.');}
    AddLine('The video mode used in this test is intended for RGB monitors.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  Preptest;
  vs:=new(pvidCGAGmode4,Init(mode4,true));
  with vs^ do begin
    {rect(0,0,width-1,height-1,maxcolors-1);
    rect(1,1,width-2,height-2,maxcolors-1);}
    xcoll:=(width div 2)-1; xcolr:=xcoll+1;
    while xcoll>0 do begin
      line(xcoll+0,0,xcoll+0,height-1,maxcolors-1);
      line(xcoll+1,0,xcoll+1,height-1,maxcolors-1);
      line(xcolr-0,0,xcolr-0,height-1,maxcolors-1);
      line(xcolr-1,0,xcolr-1,height-1,maxcolors-1);
      xcoll:=xcoll-xdiv; xcolr:=xcolr+xdiv;
    end;
    ycolt:=(height div 2)-1; ycolb:=ycolt+1;
    while ycolt>0 do begin
      line(0,ycolt+0,width-1,ycolt+0,maxcolors-1);
      line(0,ycolt+1,width-1,ycolt+1,maxcolors-1);
      line(0,ycolb-0,width-1,ycolb-0,maxcolors-1);
      line(0,ycolb-1,width-1,ycolb-1,maxcolors-1);
      ycolt:=ycolt-ydiv; ycolb:=ycolb+ydiv;
    end;
    PauseUser;
    {now make a convergence pattern}
    for xcoll:=0 to (width div 2)-1 do line(xcoll*2,0,xcoll*2,height-1,0);
    for ycolt:=0 to (height div 2)-1 do line(0,ycolt*2,width-1,ycolt*2,0);
    PauseUser;
  end;
  dispose(vs,done);
  PostTest;
end;

Procedure CalibLinearComp;
const
  xdiv=12;
  ydiv=20;
  xofs=0;
  yofs=0;
var
  x,y,c:word;
  xcoll,xcolr,ycolt,ycolb:integer;
  s:string;

begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mLinearComp].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLinearityText;
    AddLine('');
    {AddLine('The geometry in this test is for composite monitors.');}
    AddLine('The video mode used in this test is intended for composite monitors.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  Preptest;
  vs:=new(pvidCGAGcomposite,Init(composite,true)); {compatibility=true so BIOS is called to set mode}
  with vs^ do begin
    {rect(0,0,width-1,height-1,maxcolors-1);
    rect(1,1,width-2,height-2,maxcolors-1);}
    xcoll:=(width div 2)-1; xcolr:=xcoll+1;
    while xcoll>0 do begin
      line(xcoll+0,0,xcoll+0,height-1,maxcolors-1);
      line(xcoll+1,0,xcoll+1,height-1,maxcolors-1);
      line(xcolr-0,0,xcolr-0,height-1,maxcolors-1);
      line(xcolr-1,0,xcolr-1,height-1,maxcolors-1);
      xcoll:=xcoll-xdiv; xcolr:=xcolr+xdiv;
    end;
    ycolt:=(height div 2)-1; ycolb:=ycolt+1;
    while ycolt>0 do begin
      line(0,ycolt+0,width-1,ycolt+0,maxcolors-1);
      line(0,ycolt+1,width-1,ycolt+1,maxcolors-1);
      line(0,ycolb-0,width-1,ycolb-0,maxcolors-1);
      line(0,ycolb-1,width-1,ycolb-1,maxcolors-1);
      ycolt:=ycolt-ydiv; ycolb:=ycolb+ydiv;
    end;
    PauseUser;
    {now make a convergence pattern}
    for xcoll:=0 to (width div 2)-1 do line(xcoll*2,0,xcoll*2,height-1,0);
    for ycolt:=0 to (height div 2)-1 do line(0,ycolt*2,width-1,ycolt*2,0);
    PauseUser;
  end;
  dispose(vs,done);
  PostTest;
end;


end.
