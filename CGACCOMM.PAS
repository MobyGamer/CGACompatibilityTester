{$O+,F+}
unit cgaccommon;
{common constants and procedures to make conditional compilation a bit easier}

interface

uses
  totmsg,totIO1,cgalib;

type
  {Order is important here, do not rearrange unless you know what you're doing}
  userActions=(
  mBMR,mBMW,mOARB,mOAWB,
  mBCol,mMCol,mHCol,mPal,
  m40col,mTHCB,mTCur,mTSnow,mFont,
  mBCal,mCCal,mColor,mMono,mMoire,mMoireColor,mUniform,mLinearRGB,mMultiburst,
  mVert,mHoriz,mTCustom80,mTCustom90,mInterlace,mPos,mAddr,
  mCompWhich,mCompLo,mCompHi,mAspectNTSC,
  mCapBarsRGB,mCapBarsComp,mCapMotion,mCapRGBI,mSync,mCamera,
  mIntro,mAbout,
  mnull
  );
  menuLookuptype=record
    id:word;
    title,blurb:pchar;
  end;
  menuArray=array[userActions] of menuLookuptype;

const
  interactive:boolean=true;
  timeoutsecs:word=5;
  cstring:string[14]='  ~C~ontinue  ';
  astring:string[11]='  ~A~bort  ';
  {
  To cut down on the .exe and memory size, we keep larger chunks
  of data in a seperate file.  Contents, in order:
    cga/mda font data:     8192 bytes
    shaded cubes picture: 16000 bytes
    Painted face picture: 16000 bytes
    aspect ratio pattern: 16384 bytes
    whichCGA pic:         15360 bytes
    boxdata:                800 bytes
  }
  menuLookup:menuArray=(
    (id:10; {mBMR} title:'Block Memory Read';
    blurb:'Adapter RAM read speeds'),
    (id:11; {mBMW} title:'Block Memory Write';
    blurb:'Adapter RAM write speeds'),
    (id:12; {mOARB} title:'Interleaved Read';
    blurb:'Adapter RAM reads mixed with CPU opcodes'),
    (id:13; {mOAWB} title:'Interleaved Write';
    blurb:'Adapter RAM writes mixed with CPU opcodes'),

    (id:20; {mBCol} title:'Border/Overscan color';
    blurb:'Checks Border/Overscan color'),
    (id:21; {mMCol} title:'Medium-res background';
    blurb:'Checks Background color in graphics mode'),
    (id:22; {mHCol} title:'High-res foreground';
    blurb:'Checks Foreground color in graphics mode'),
    (id:23; {mPal} title:'Medium-res palettes';
    blurb:'Checks all six medium-res graphics palettes'),

    (id:30; {m40col} title:'40-column display';
    blurb:'Checks existence of 40-column textmode'),
    (id:31; {mTHCB} title:'Text mode highcolor';
    blurb:'Checks text mode highcolor backgrounds'),
    (id:32; {mTCur} title:'Cursor control';
    blurb:'Checks cursor manipulation'),
    (id:33; {mTSnow} title:'CGA Snow';
    blurb:'Checks for CGA "Snow" noise'),
    (id:34; {mFont} title:'8x8 Font display';
    blurb:'CGA 8x8 font check'),

    (id:40; {mBCal} title:'Brightness';
    blurb:'Calibrate your monitor''s Brightness control'),
    (id:41; {mCCal} title:'Contrast';
    blurb:'Calibrate your monitor''s Contrast and color controls'),
    (id:42; {mColor} title:'Color';
    blurb:'Calibrate all monitor controls'),
    (id:43; {mMono} title:'Monochrome';
    blurb:'Calibrate all monitor controls for "monochrome" CGA monitors'),
    (id:44; {mMoire} title:'Focus, moire, interference';
    blurb:'Calibrate horizontal/vertical size and aperture'),
    (id:45; {mMoireColor} title:'Moire (color/shadowmask)';
    blurb:'Shadow mask adjustments and scaler conversions'),
    (id:46; {mUniform} title:'Uniformity and Convergence';
    blurb:'Examine monitor for color uniformity/purity and convergence/pincushion'),
    (id:47; {mLinearRGB} title:'Linearity';
    blurb:'Examine monitor for display linearity'),
    (id:48; {mMultiburst} title:'Multiburst';
    blurb:'Examine frequency response'),

    (id:50; {mVert} title:'Vertical retrace';
    blurb:'Detect and display vertical refresh rate'),
    (id:51; {mHoriz} title:'Horizontal retrace';
    blurb:'Test presence and functionality of the Horizontal Retrace detect bit'),
    (id:52; {mTCustom80} title:'Row Reprogramming';
    blurb:'Reprogram the number of rows displayed'),
    (id:53; {mTCustom90} title:'Row/Column Reprogramming';
    blurb:'Reprogram the number of columns and rows displayed'),
    (*
    (id:54; {mGCustom} title:'Graphics reprogramming';
    blurb:'Test m6845 compatibility with custom graphics modes'),
    *)
    (id:55; {mInterlace} title:'Interlaced video mode';
    blurb:'Test m6845 interlaced video generation'),
    (id:56; {mPos} title:'Display Positioning';
    blurb:'Test m6845 horizontal and vertical sync position register'),
    (id:57; {mPos} title:'Start Address reprogramming';
    blurb:'Test m6845 start address register'),

    (id:60; {mCompWhich} title:'CGA card determination';
    blurb:'Displays test pattern that identifies your CGA card type'),
    (id:61; {mCompLo} title:'Composite: Low-res text';
    blurb:'Simple 40-column color plate for composite color monitors'),
    (id:62; {mCompHi} title:'Composite: Low-res graphics';
    blurb:'Simple 160x200 color plate for composite color monitors'),
    (id:63; {mAspectNTSC} title:'Aspect Ratio & Crosshatch';
    blurb:'Calibrate horizontal/vertical size adjustment.  Also includes crosshatches.'),

    (id:70; {mCapBarsRGB} title:' RGB Color Bars ';
    blurb:'All 16 RGB color bars for calibrating capture cards'),
    (id:71; {mCapBarsComp} title:' Composite Color Bars ';
    blurb:'16 solid composite color bars for calibrating capture cards'),
    (id:72; {mCapMotion} title:' Motion test plate ';
    blurb:'Horizontal and vertical motion test plate'),
    (id:73; {mCapRGBI} title:' RGBI Calibration bars ';
    blurb:'RGB displayed in both intensities for calibration'),
    (id:74; {mSync} title:' Audio/Video sync drift ';
    blurb:'Displays longform timer with audio queues'),
    (id:75; {mCamera} title:' Camera calibration ';
    blurb:'A few screens to help calibrate camera focus and white balance'),

    (id:1000; {mIntro} title:' Introduction ';
    blurb:'What this program does and why you would want to use it'),
    (id:1001; {mAbout} title:' About this program ';
    blurb:'Version and contact information'),

    (id:2000; {mAbout} title:'null title';
    blurb:'nullblurb')
  );

var
  {default colors}
  descBorder,descBody,descTitle,descIcons:byte;
  InfoPrompt:PromptOBJ;
  Result:tAction;
  vs:pvidSystem;
  framecounter:longint;

Procedure PrepTest; {preps the screen for a test}
Procedure PostTest; {recovers after a test}
Procedure BIOSWriteStr(var s:string); {prints a string using only the BIOS}
Procedure BIOSGotoXY(x,y:byte); {Positions the cursor}
Procedure PauseUser;
Procedure DrawTestplate;
Procedure PrintInvalidMsg;
Function  zx0_decomp(inb,outb:pointer):word;

implementation

uses
  m6845ctl,totfast,tinterrupts,support;

Procedure PrintInvalidMsg;
begin
  with Screen do begin
    Writeln('This result is invalid; you are likely running this program on a machine made');
    Writeln('after the 1990s.  As such, the test is running faster than the internal 8253');
    Writeln('timer chip has resolution to measure.  Press any key to exit.');
  end;
end;

Procedure DrawTestplate;
begin
  vs^.rect(0,0,vs^.width-1,vs^.height-1,1);
  vs^.line(0,0,vs^.width-1,vs^.height-1,1);
  vs^.line(vs^.width-1,0,0,vs^.height-1,1);
end;

Procedure PauseUser;
var
  wticks:word;
  oldt:longint;
begin
  if interactive then begin
    repeat until keypressed;
    while keypressed do readkeychar;
  end else begin
    wticks:=round(18.2 * timeoutsecs);
    oldt:=ticksSinceMidnight;
    repeat
      repeat until oldt<>ticksSinceMidnight;
      oldt:=ticksSinceMidnight;
      dec(wticks);
    until (wticks=0) or keypressed;
  end;
end;

Procedure PrepTest;
{Prepare the screen for a test.  This is clunky, should revisit if possible.}
begin
  if interactive then begin
    Screen.ResetWindow;
    Screen.Clear($0F,' '); {paint the screen}
    Screen.gotoxy(1,1);
    crt.textattr:=$0F;
  end;
end;

Procedure PostTest;
{Clean up after a test: empty keyb buffer; re-init 80x25 textmode}
begin
  {empty keyboard buffer}
  while keypressed do readkeychar;
  (*
  {set 80x25 textmode sync from BIOS table}
  m6845_SetModeTable(1);
  {set 80x25 textmode mode itself}
  m6845_SetMode(c_fast_char_clock+c_videosignal_enable+c_blinking_text);
  {set black border color}
  m6845_SetColor(0);
  *)
  asm
        mov     ax,0003h
        int     10h
        in      al,61h
        and     al,11111100b
        out     61h,al
  end;
end;

Procedure BIOSWriteStr;assembler;
asm
        push    ds
        lds     si,s
        xor     ax,ax
        lodsb
        mov     cx,ax   {get length of string}
        xor     bh,bh   {point to a video page, required in old BIOSes - we force page 0}
        mov     bl,3    {color if in graphics mode -- does this work in 640x200?}
@writeit:
        mov     ah,0eh  {teletype write mode} {have to keep setting this because something trashes AH!}
        lodsb           {get character}
        int     10h     {print in teletype mode}
        loop    @writeit
        pop     ds
end;

Procedure BIOSGotoXY;assembler;
asm
        mov     ah,02
        xor     bh,bh
        mov     dl,x
        mov     dh,y
        int     10h
end;

Procedure zx0_decompress_speed; external;
{$L zx0_8086.obj}

Function zx0_decomp(inb,outb:pointer):word; assembler;
asm
        push    ds
        lds     si,inb
        les     di,outb
        call    zx0_decompress_speed
        pop     ds
end;

begin
  {set informational box colors}
  descBorder:=cattr(tWhite,tBlue);
  descBody:=cattr(tWhite,tBlue);
  descTitle:=cattr(tYellow,tBlue);
  descIcons:=cattr(tLightRed,tBlue);
end.
