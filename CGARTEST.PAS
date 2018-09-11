{$O+,F+}
unit CGARTESTS;
{Contains all of the M6845 register tests}

interface

Procedure VertDetect;
Procedure HorizDetect;
Procedure ShowText90x30;
Procedure ShowText80x100;
Procedure TestInterlace;
Procedure TestPosition;
Procedure TestStartAddress;

implementation

uses
  strings,support,m6845ctl,{ztimer,}cgaccommon,cgastaticdata,
  TInterrupts,{cgalib_g,}cgalib,tfastwrite,
  totsys,totmsg,totIO1,totfast;

var
  Screen90:ScreenOBJ;

Procedure VertDetect;
const
  dampening=171; {least common multiple of 18 cycles (DRAM) and 76 (# of cycles per CGA horizontal line), divided by 4}
  TargetCycles:word=CGAFrameCycles;
var
  rhz,avghz,minhz,maxhz:real;
  rst:string;
  w:word;
  l:longint;
  b:byte;
  counter:byte;
  samples:array[0..dampening-1] of word;
  sp:pointer;
  s:string;

begin
  {!Should this start with 59.92 as default?
  Any way to get more accurate on first try?}
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mVert].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This test will monitor the m6845 status register');
    AddLine('to determine the vertical refresh rate.  Use this');
    AddLine('test to determine if your adapter is correctly');
    AddLine('reproducing the refresh rate of stock CGA.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  PrepTest;
  m6845_SetCursorLoc(80*25); {hide cursor offscreen}
  tfastinit(80,25);
  tfpreventsnow:=true;
  sp:=ptr($b800,0);
  rhz:=PITFreq/262/76;
  str(rhz:2:4,rst);
  s:='CGA''s true vertical refresh: '+rst+' Hz';
  tfastwritexy(@s,sp,0,4,$0F);
  s:='Note: These values may never settle due to interrupt jitter and DRAM refresh.';
  tfastwritexy(@s,sp,0,6,$07);
  s:='Press any key to exit the measurement.';
  tfastwritexy(@s,sp,0,8,$07);

  s:='Refresh rate detected (now):         Hz';
  tfastwritexy(@s,sp,0,0,$07);
  s:='Refresh rate detected (min):         Hz';
  tfastwritexy(@s,sp,0,1,$07);
  s:='Refresh rate detected (max):         Hz';
  tfastwritexy(@s,sp,0,2,$07);
  s:='Refresh rate detected (avg):         Hz';
  tfastwritexy(@s,sp,0,3,$0F);


  {init channel 0, 3=access mode lobyte/hibyte, mode 2, 16-bit binary}
  {We do this so we can get a sensible countdown value from mode 2 instead
  of the 2xspeedup var from mode 3.  I have no idea why old BIOSes init
  mode 3; everything 486 and later inits mode 2.  Go figure.  This should
  not damage anything in DOS or TSRs, in case you were wondering.}
  InitChannel(0,3,2,$0000);
  w:=TargetCycles;
  for b:=0 to dampening-1 do samples[b]:=w;
  counter:=0;

  repeat
    {we will measure the amount of time it takes to go from one retrace start
    to another and use that to determine the vertical refresh rate}
    asm
        mov     bl,c_vertical_sync
        mov     bh,iMC_Chan0 + iMC_LatchCounter + iMC_OpMode2 + iMC_BinaryMode
        mov     dx,m6845_status

        {wait for retrace, take a measurement, repeat. Sub to find elapsed.}
        cli

@WDR: {wait during retrace, because we don't know where we are in the cycle}
        in      al,dx
        test    al,bl {if our bit is 1, then we're already in retrace, which means we missed it}
        jnz     @WDR  {jump if 1 (not 0) = keep looping as long as we're retracing}
@WDD: {wait for display to be over}
        in      al,dx
        test    al,bl
        jz      @WDD  {loop until we aren't drawing any more (ie. retracing)}

        mov     al,bh          {Begin building timer count}
        out     43h,al         {Tell timer about it}
        in      al,40h         {Get LSB of timer counter}
        xchg    al,ah          {Save it in ah}
        in      al,40h         {Get MSB of timer counter}
        xchg    al,ah          {Put things in the right order; AX:=starting timer}
        xchg    di,ax          {store in di for later}

@WDR2: {wait during retrace, because we don't know where we are in the cycle}
        in      al,dx
        test    al,bl {if our bit is 1, then we're already in retrace, which means we missed it}
        jnz     @WDR2  {jump if 1 (not 0) = keep looping as long as we're retracing}
@WDD2: {wait for display to be over}
        in      al,dx
        test    al,bl
        jz      @WDD2  {loop until we aren't drawing any more (ie. retracing)}

        mov     al,bh          {Begin building timer count}
        out     43h,al         {Tell timer about it}
        in      al,40h         {Get LSB of timer counter}
        xchg    al,ah          {Save it in ah}
        in      al,40h         {Get MSB of timer counter}
        sti                    {Exhale}
        xchg    al,ah          {Put things in the right order; AX:=starting timer}
        sub     di,ax          {subtract new value from old value}

        mov     w,di
    end;

    {store cycles elapsed}
    samples[counter]:=w;
    inc(counter);
    {clamp to non-power-of-2 dampening bound}
    if counter>=dampening
      then counter:=0;
    {what is our immediately-measured refresh rate?  Average rate?}
    rhz:=PITFreq/w;
    {what's our average cycle count?}
    l:=0;
    for b:=0 to dampening-1 do l:=l+samples[b];
    l:=l div dampening;
    avghz:=PITFreq/l;

    {what's our minimum hz?}
    l:=w;
    for b:=0 to dampening-1 do
      if l<samples[b]
        then l:=samples[b];
    minhz:=PITFreq/l;

    {what's our maximum hz?}
    l:=w;
    for b:=0 to dampening-1 do
      if l>samples[b]
        then l:=samples[b];
    maxhz:=PITFreq/l;

    str(  rhz:2:4,rst); tfastwritexy(@rst,sp,29,0,$07);
    str(minhz:2:4,rst); tfastwritexy(@rst,sp,29,1,$07);
    str(maxhz:2:4,rst); tfastwritexy(@rst,sp,29,2,$07);
    str(avghz:2:4,rst); tfastwritexy(@rst,sp,29,3,$0F);

  until keypressed;

  PostTest;
end;

Procedure HorizDetect;
const
  barsize=20;
  coppersize=170+barsize;
  height=coppersize-barsize-10; {to make sure last color is always 0}
  startr:byte=barsize * 0;
  startg:byte=barsize * 1;
  startb:byte=barsize * 2;
  starti:byte=barsize * 3;
  startsize=256{128};

type
  coplisttype=array [0..coppersize] of byte;

var
  startlist:array [0..startsize-1] of byte;
  copperlist:coplisttype;
  j:word;
  smsg:string;
  foo,bar,baz:byte;
  foow:word;
  fooptr:pointer;

  procedure DoCopper(coplist:coplisttype); assembler;
  asm
    push    ds
    cld
    mov     dx,m6845_status {m6845_status is how we monitor retrace}
    mov     cx,coppersize {number of lines to set}
    lds     si,coplist
    mov     bx,0108h {bh=c_display_enable, bl=c_vertical_sync}
  @wait:
    in      al,dx
    test    al,bl
    jnz     @wait    {loop if in already in retrace}
  @retrace:
    in      al,dx
    test    al,bl
    jz      @retrace {loop if not; when we exit this loop, we're in vert. retrace}
    dec     dx       {get dx ready by setting to $3d9 for what we're going to do with it}
    cli              {shut off interrupts (entering time-critical part)}
  @loop:
    inc     dx       {increment dx to 03DA which is m6845_status}
    lodsb            {load our color from the list of scanline colors}
    mov     ah,al    {save it for right when we need it}
  @w:
    in      al,dx
    test    al,bh
    jnz     @w       {loop if in horizontal retrace (just in case we're already in the middle of it}
  @r:
    in      al,dx
    test    al,bh
    jz      @r       {loop if NOT in horizontal retrace -- when loop ends, we are in horizontal retrace}
    dec     dx       {move dx back down to 03D9 which is m6845_color_select}
    mov     al,ah    {get our color back into al...}
    out     dx,al    {...so we can change the background color}
    loop    @loop    {loop for the rest of the scanlines}
    sti              {enable software interrupts (done with critical part)}
    pop     ds
  end;

begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mHoriz].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This test will monitor the m6845 status register');
    AddLine('for the horizontal retrace activity bit and uses');
    AddLine('it to draw a test pattern.  If the horizontal');
    AddLine('retrace bit is present and working, you should see');
    AddLine('bars of color moving up and down the screen.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  PrepTest;
  for j:=0 to startsize-1 do {build the sin array}
    startlist[j]:=round(height/2*sin(j*pi/{64}(startsize div 2))+height/2)+1;
  vs:=new(pvidCGAGmode4,Init(mode4,false));
  asm
    mov ax,0004h
    int 10h
  end;
  DrawTestplate;
  smsg:='Welcome to medium-res graphics.'#13#10; BIOSWriteStr(smsg);
  smsg:='If your horizontal retrace bit'#13#10; BIOSWriteStr(smsg);
  smsg:='is functional, you should be'#13#10; BIOSWriteStr(smsg);
  smsg:='seeing some moving color bars.'#13#10; BIOSWriteStr(smsg);
  smsg:='The bars should extend into the'#13#10; BIOSWriteStr(smsg);
  smsg:='border/overscan area.'#13#10#10; BIOSWriteStr(smsg);

  smsg:='If you see no color activity,'#13#10; BIOSWriteStr(smsg);
  smsg:='then your video adapter is not'#13#10; BIOSWriteStr(smsg);
  smsg:='emulating the m6845 properly.'#13#10#10; BIOSWriteStr(smsg);

  smsg:='Press a key to exit the test.'#13#10; BIOSWriteStr(smsg);

  fooptr:=@copperlist;
  repeat
    (*fillchar(copperlist, coppersize, 0); {init copperlist to 0}*)
    asm
      {erase the copperlist}
      les di,fooptr
      cld
      xor ax,ax
      mov cx,coppersize / 2
      rep stosw
    end;
    foow:=startlist[startr];
    asm
      les di,fooptr
      add di,foow
      push ds
      mov ax,es
      mov ds,ax
      mov si,di
      mov cx,barsize
    @orred:
      lodsb
      or al,c_red
      stosb
      loop @orred
      pop ds
    end;

    foow:=startlist[startg];
    asm
      les di,fooptr
      add di,foow
      push ds
      mov ax,es
      mov ds,ax
      mov si,di
      mov cx,barsize
    @orgreen:
      lodsb
      or al,c_green
      stosb
      loop @orgreen
      pop ds
    end;

    foow:=startlist[startb];
    asm
      les di,fooptr
      add di,foow
      push ds
      mov ax,es
      mov ds,ax
      mov si,di
      mov cx,barsize
    @orblue:
      lodsb
      or al,c_blue
      stosb
      loop @orblue
      pop ds
    end;

    foow:=startlist[starti];
    asm
      les di,fooptr
      add di,foow
      push ds
      mov ax,es
      mov ds,ax
      mov si,di
      mov cx,barsize
    @ori:
      lodsb
      or al,c_bright
      stosb
      loop @ori
      pop ds
    end;
    {for foo:=startlist[startr] to startlist[startr]+barsize do copperlist[foo]:=copperlist[foo] OR c_red;
    for foo:=startlist[startg] to startlist[startg]+barsize do copperlist[foo]:=copperlist[foo] OR c_green;
    for foo:=startlist[startb] to startlist[startb]+barsize do copperlist[foo]:=copperlist[foo] OR c_blue;
    for foo:=startlist[starti] to startlist[starti]+barsize do copperlist[foo]:=copperlist[foo] OR c_bright;}
    (*move(bardata, copperlist[startlist[start]], barsize); {copy our copper bar into the copperlist at start point}*)
    DoCopper(copperlist);
    asm {advance the indexes - no need to mask because lookup table is 256 entries}
      inc startr
      inc startg
      inc startb
      inc starti
    end;
  until keypressed {mem[0:$41A] <> mem[0:$41C]};
  dispose(vs,done);
  PostTest;
end;

Procedure ShowText90x30;
var
  Screen90:ScreenOBJ;
  x,y:byte;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mTCustom90].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This test reprograms the m6845 horizontal and vertical');
    AddLine('registers to expand the typical 80x25 text mode to 90x30.');
    AddLine('The goal of this test is to see if the number of columns');
    AddLine('can successfully be reprogramed.');
    AddLine('');
    AddLine('If your video adapter or monitor cannot handle the timings');
    AddLine('of this mode, the display will lose sync, appear garbled,');
    AddLine('and may roll continuously.  If this happens, immediately');
    AddLine('press a key to restore sync timings to defaults.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  PrepTest;

  {display 80x25}
  with Screen do begin
    FillBox(1,1,vwidth,vdepth,$1e,4);
    for x:=1 to 7 do VertLine(x*10,2,vdepth-1,$1e,4);
    for y:=1 to 5 do HorizLine(2,vwidth-1,y*5,$1e,4);
    {do numbers on all edges}
    for x:=0 to vwidth-1 do begin
      WritePlain(x+1,1,inttostr(x mod 10));
      WritePlain(x+1,vdepth,inttostr(x mod 10));
    end;
    for y:=1 to vdepth-2 do begin
      WritePlain(1,y+1,inttostr(y mod 10));
      WritePlain(vwidth,y+1,inttostr(y mod 10));
    end;
    WriteCenter(3,$1f,'80x25 Text Mode.  Border/Overscan area should be present and visible.');
  end;
  Pauseuser;

  {display 90x30}
  m6845_SetUserModeTable(@t90x30);
  with Screen90 do begin;
    init;
    Create(0,0,0); vWidth:=90; vDepth:=30;
    oWritePtr^.SetScreen(vScreenPtr,vWidth); {force writing routines to pick up new dimensions}
    FillBox(1,1,vwidth,vdepth,$1e,4);
    for x:=1 to 8 do VertLine(x*10,2,vdepth-1,$1e,4);
    for y:=1 to 6 do HorizLine(2,vwidth-1,y*5,$1e,4);
    for x:=0 to vwidth-1 do begin
      WritePlain(x+1,1,inttostr(x mod 10));
      WritePlain(x+1,vdepth,inttostr(x mod 10));
    end;
    for y:=1 to vdepth-2 do begin
      WritePlain(1,y+1,inttostr(y mod 10));
      WritePlain(vwidth,y+1,inttostr(y mod 10));
    end;
    WriteCenter(3,$1f,'90x30 Text Mode.  Border/Overscan area should be nearly or completely absent.');
  end;
  Pauseuser;

  PostTest;
  Screen90.done;
end;

Procedure ShowText80x100;
var
  f:file;
  fdata:pointer;
  pmda,pcgathin,pcgathick:pbyte;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mTCustom80].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This test reprograms the maximum scanline and');
    AddLine('vertical total registers to increase the number');
    AddLine('of lines in text mode from 25 to 100.  This is');
    AddLine('a common ''tweaked'' mode used in some CGA games');
    AddLine('like ICON, Seven Spirits of Ra, Round 42, Styx,');
    AddLine('Moon Bugs, and others.  By using the ± character,');
    AddLine('it is possible to simulate dozens of colors, a');
    AddLine('technique which will be demonstrated in this test.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  PrepTest;

  vs:=new(pvidCGAT80x100,Init(text80x100,true));
  fdata:=ptr($b800,0);
  assign(f,datafile);
  reset(f,1);
  seek(f,8192); {seek to where pictures start}
  blockread(f,fdata^,16000);
  pauseuser;
  blockread(f,fdata^,16000);
  pauseuser;
  close(f);
  dispose(vs,done);
  PostTest;
end;

Procedure TestInterlace;
var
  f:file;
  fdata:pointer;
  pmda,pcgathin,pcgathick:pbyte;
  loop:byte;
  s:string;

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
      Screen.WriteAt(bx+1,by+y,$0f,s);
      inc(word(fontdata));
    end;
  end;

begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mInterlace].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This test will enable interlaced video generation');
    AddLine('to turn 80x25 text mode into 80x50.  However, the');
    AddLine('usefulness of this mode is dubious, as IBM did not');
    AddLine('properly implement interlacing on CGA cards.');
    AddLine('No CGA program ever used interlacing, but we are');
    AddLine('including the test here for completeness.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  asm
    mov ax,$b800
    mov es,ax
    xor di,di
    xor ax,ax
    mov cx,8192
    rep stosw
  end;

  PrepTest;

  getmem(fdata,8192);
  assign(f,datafile);
  reset(f,1);
  blockread(f,fdata^,8192);
  close(f);
  pmda:=fdata; pcgathin:=pmda; pcgathick:=pmda;
  inc(word(pcgathick),6144);
  inc(word(pcgathin),4096);
  with Screen do begin
    Writeln('This is regular 80x25 text mode.');
    Writeln('Press a key to enable interlacing; when done viewing, press any key to exit.');
    PauseUser;
    m6845_SetRegData(m6845_interlace_mode,3);
    Writeln('Interlaced mode enabled.');
    s:='Interlaced'; for loop:=0 to length(s)-1 do DrawCharBox(loop*8,4,s[loop+1],pcgathin);
    s:='mode on.';   for loop:=0 to length(s)-1 do DrawCharBox(loop*8,12,s[loop+1],pcgathin);
    s:='Press key';  for loop:=0 to length(s)-1 do DrawCharBox(loop*8,20,s[loop+1],pcgathick);
    s:='to exit.';   for loop:=0 to length(s)-1 do DrawCharBox(loop*8,28,s[loop+1],pcgathick);
  end;

  PauseUser;
  m6845_SetRegData(m6845_interlace_mode,2);
  freemem(fdata,8192);

  PostTest;
end;

Procedure TestPosition;
var
  oldregs,newregs:m6845_moderegs;
  oldh,oldv:byte;
  x:byte;
  oldtick:longint;
  smsg:string;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mPos].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This test alters the horizontal and vertical sync');
    AddLine('position registers.  These registers are used by');
    AddLine('some early games and utilities to allow the user');
    AddLine('to reposition the horizontal and vertical centering');
    AddLine('of the screen.  This test will reposition the viewable');
    AddLine('area of the screen until the user hits a key to exit.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  {preptest} {we want to reposition the existing screen}
  {Grab the textmode regs from the BIOS data area}
  move(Int1D_Mode_Table^.modes[1{80x25}],oldregs,sizeof(oldregs));
  {make a copy}
  move(oldregs,newregs,sizeof(newregs));
  oldh:=oldregs.horizontal_sync_position;
  oldv:=oldregs.vertical_sync_position;
  repeat
    inc(x); x:=x AND $07;
    with newregs do
      case x of
        0:begin horizontal_sync_position:=oldh-1; vertical_sync_position:=oldv-1; end;
        1:begin horizontal_sync_position:=oldh  ; vertical_sync_position:=oldv-1; end;
        2:begin horizontal_sync_position:=oldh+1; vertical_sync_position:=oldv-1; end;
        3:begin horizontal_sync_position:=oldh+1; vertical_sync_position:=oldv  ; end;
        4:begin horizontal_sync_position:=oldh+1; vertical_sync_position:=oldv+1; end;
        5:begin horizontal_sync_position:=oldh  ; vertical_sync_position:=oldv+1; end;
        6:begin horizontal_sync_position:=oldh-1; vertical_sync_position:=oldv+1; end;
        7:begin horizontal_sync_position:=oldh-1; vertical_sync_position:=oldv  ; end;
      end; {case}
    m6845_SetUserModeTable(@newregs);
    oldtick:=tickssincemidnight; repeat until tickssincemidnight > (oldtick+9);
  until keypressed;
  PostTest;
end;

Procedure TestStartAddress;
var
  oldregs,newregs:m6845_moderegs;
  oldh,oldv:byte;
  x:byte;
  oldtick:longint;
  smsg:string;
  starta:word;
begin
  with InfoPrompt do begin
    init(2,strpas(menuLookup[mAddr].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This test alters the Start Address register');
    AddLine('to change the starting memory location used');
    AddLine('by the m6845.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  preptest;
  vs:=new(pvidCGAGmode4,Init(mode4,false));
  asm
    mov ax,0004h
    int 10h
  end;
  DrawTestplate;
  smsg:='Welcome to medium-res graphics.'#13#10; BIOSWriteStr(smsg);
  smsg:='This test will roll the screen'#13#10; BIOSWriteStr(smsg);
  smsg:='using the m6845 start address register.'#13#10; BIOSWriteStr(smsg);
  smsg:='The first test will scroll vertically,'#13#10; BIOSWriteStr(smsg);
  smsg:='and the second horizontally.'#13#10; BIOSWriteStr(smsg);
  smsg:='Press a key to advance through'#13#10; BIOSWriteStr(smsg);
  smsg:='each test.'#13#10; BIOSWriteStr(smsg);
  pauseuser;
  starta:=0;
  repeat
    m6845_WaitVertRetrace;
    m6845_SetDisplayAddress(starta);
    starta:=(starta + 40) and $3fff;
  until keypressed; while keypressed do readkeychar;
  starta:=40;
  repeat
    m6845_WaitVertRetrace;
    m6845_SetDisplayAddress(starta);
    starta:=(starta+1) mod 40;
  until keypressed;
  dispose(vs,done);
  PostTest;
end;

end.
