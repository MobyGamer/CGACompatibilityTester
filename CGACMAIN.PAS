{$O+,F+}

unit CGACMAIN;
{Contains the main hunk of the program.  We do this so that it can be socked
away in an overlay, saving memory space for the .exe}

interface

Procedure InitCCT;
Procedure DoCCT;
Procedure DoneCCT;

implementation

uses
  support,strings,m6845ctl,cmdlin,
  totmsg,totmenu,totinput,totfast,totIO1,
  {$IFDEF DETECT} topb_detect, {$ENDIF}
  cgabtests,cgattests,cgactests,cgamtests,cgartests,comptests,cgacapture,cgaccommon;

var
  MainMenu,SpeedMenu,ColorMenu,TextMenu,CalibMenu,Regmenu,CompMenu,CapMenu:MenuOBJ;

Procedure PopIntro;

var
  foomsg:MessageObj;
  loop:byte;
begin
  with foomsg do begin
    init(2,strpas(menuLookup[mIntro].title));
    AddLine('');
    AddLine(' The CGA Compatibility Tester stresses nearly every capability of ');
    AddLine(' the IBM Color Graphics Adapter (CGA).  This can be used to:');
    AddLine('');
    AddLine(' - Verify your CGA card is 100% compatible with the real IBM CGA ');
    AddLine(' - Calibrate your RGB or Composite monitor');
    AddLine(' - Benchmark adapter RAM speed');
    AddLine(' - Satisfy your curiousity about how CGA can be tweaked');
    AddLine('');
    AddLine(' Consult CGA_COMP.TXT for more info.');
    AddLine('');
    {for loop:=0 to 12 do AddLine(strpas(IntroText[loop]));}
    show;
    done;
  end;
end;

Procedure PopAbout;
{const
  AboutText:array[0..5] of pChar=(
    '',
    ' The CGA Compatibility Tester',
    ' Version 1.11, 20160320',
    ' by Jim Leonard',
    ' trixter@oldskool.org',
    ''
  );}

var
  foomsg:MessageObj;
  loop:byte;
  s:string[80];
begin
  with foomsg do begin
    init(2,strpas(menuLookup[mAbout].title));
    {for loop:=0 to 5 do AddLine(strpas(AboutText[loop]));}
    AddLine('');
    AddLine(' The CGA Compatibility Tester');
    AddLine(' Version 1.26.1, 20180910');
    {AddLine(' by Jim Leonard');}
    AddLine(' trixter@oldskool.org');
    AddLine('');

    s:=' Free heap: '+inttostr(memavail div 1024)+' KB '; AddLine(s);
    s:=''; AddLine(s);
    show;
    done;
  end;
end;

{$IFDEF DETECT}
Procedure PopDetect;
var
  foomsg:MessageObj;
begin
  with foomsg do begin
    init(2,strpas(menuLookup[mDetect].title));
    Addline('');
    AddLine('We are now going to detect your system hardware.');
    AddLine('This is an intensive process that takes a while');
    AddLine('to run on slow hardware.  Please wait up to fifteen');
    AddLine('seconds for the results.');
    SetOption('  ~D~etect Hardware  ',68);
    show;
    done;

    init(2,strpas(menuLookup[mDetect].title));
    Addline('');
    AddLine('Machine type: '+WhatMachineType);
    AddLine('CPU type: '+WhatCPU);
    AddLine('CPU speed: '+WhatMHz);
    AddLine('Video adapter: '+WhatVideoAdapter);
    AddLine(WhatBIOS);
    Addline('');
    show;
    done;
  end;
end;
{$ENDIF}

procedure InitCCT;
{const
  DisclaimerText:array[0..11] of pChar=(
    '',
    'This program benchmarks and stresses nearly every aspect of the IBM CGA',
    '(Color Graphics Adapter).  Because this program stresses your display',
    'system, there is a remote possibility that the use of this program could',
    'damage your monitor.  The author developed this program on a true IBM',
    'CGA with a true IBM 5153 color display, and has taken every precaution',
    'to avoid settings that would damage a monitor -- but if you continue to',
    'use this program, you agree that the author is NOT RESPONSIBLE for any',
    'damage that may occur during its use.',
    '',
    'Do you agree to these terms?',
    ''
  );}

var
  PromptWin:PromptOBJ;
  Result:tAction;
  actloop:userActions;
  loop:byte;
begin
  if not fileexists(datafile) then fatalerror(3,'Data file "'+datafile+'" not found.');

  {determine if we are doing the full interactive interface,
  or going to fire up individual tests}
  if paramcount<>0 then interactive:=false;

  {display usage and confirm execution}
  if interactive then begin
    Mouse.setForceOff(true); {cursor keeps disappearing and it's just not necessary}
    {make sure our data file is available}
    SnowProne:=1; {normally we'd test to set this properly, but we are assuming a CGA card for obvious reasons}
    Screen.Clear(TWhite,'°'); {paint the screen}
    with PromptWin do begin
      Init(1,' Disclaimer and Terms of Use ');
      AddLine('');
      AddLine('This program benchmarks and stresses nearly every aspect of the IBM CGA');
      AddLine('(Color Graphics Adapter).  Because this program stresses your display');
      AddLine('system, there is a remote possibility that using this program could');
      AddLine('damage your monitor.  The author developed this program on a true IBM');
      AddLine('CGA+5153 color display, and has taken every precaution to avoid');
      AddLine('settings that would damage a monitor.  However, if you continue to use');
      AddLine('this program, you agree that the author is NOT RESPONSIBLE for any');
      AddLine('accidental damage that may occur.');
      AddLine('');
      AddLine('Do you agree to these terms?');
      AddLine('');
      {for loop:=0 to 11 do AddLine(strpas(DisclaimerText[loop]));}
      SetOption(1,'  ~Y~es  ',89,Finished);
      SetOption(2,'  ~N~o  ',78,Escaped);
      Result := Show;
      Done;
    end;
    if Result = Escaped then begin
      Preptest; {lazy way to clear screen}
      Writeln('Exited at user request.');
      halt(2);
    end;

    Screen.PartClear(1,25,80,25,TWhite,' '); {prepare status line}

    {Build menus}
    with MainMenu do begin
      Init;
      SetStyleTitle(6,'The CGA Compatibility Tester');
      AddFullItem(strpas(menuLookup[mIntro].title),menuLookup[mIntro].id,0,strpas(menuLookup[mIntro].blurb),nil);
      AddFullItem(' Monitor Calibration        ',0,0,'Various patterns/procedures to calibrate your RGB monitor',@CalibMenu);
      AddFullItem(' Video RAM Speed Benchmark  ',0,0,'Video Adapter RAM speed Benchmarks',@SpeedMenu);
      AddFullItem(' Color Select Register      ',0,0,'Color Select Register and palette tests',@ColorMenu);
      AddFullItem(' Textmode Manipulation      ',0,0,'Tests and sets various textmode attributes',@TextMenu);
      AddFullItem(' M6845 Compatibility        ',0,0,'Reprograms the Motorola 6845 Character Generator',@RegMenu);
      AddFullItem(' Composite Monitor Tests    ',0,0,'Calibration tests specific to a Composite Color monitor',@CompMenu);
      AddFullItem(' Capture Calibration Plates ',0,0,'Test plates to help calibrate capture cards',@CapMenu);
      {$IFDEF DETECT}
      AddFullItem(strpas(menuLookup[mDetect].title),menuLookup[mDetect].id,0,strpas(menuLookup[mDetect].blurb),nil);
      {$ENDIF}
      AddFullItem(strpas(menuLookup[mAbout].title),menuLookup[mAbout].id,0,strpas(menuLookup[mAbout].blurb),nil);
      SetMessageXY(1,25);
    end;

    with SpeedMenu do begin
      Init;
      SetStyleTitle(6,'Speed Benchmarks');
      SetMessageXY(1,25);
      for actloop:=mBMR to mOAWB do
        AddFullItem(strpas(menuLookup[actLoop].title),menuLookup[actLoop].id,0,strpas(menuLookup[actLoop].blurb),nil);
    end;

    with ColorMenu do begin
      Init;
      SetStyleTitle(6,'Color Select Register Tests');
      SetMessageXY(1,25);
      for actloop:=mBCol to mPal do
        AddFullItem(strpas(menuLookup[actLoop].title),menuLookup[actLoop].id,0,strpas(menuLookup[actLoop].blurb),nil);
    end;

    with TextMenu do begin
      Init;
      SetStyleTitle(6,'Textmode Manipulation');
      SetMessageXY(1,25);
      for actloop:=m40col to mFont do
        AddFullItem(strpas(menuLookup[actLoop].title),menuLookup[actLoop].id,0,strpas(menuLookup[actLoop].blurb),nil);
    end;

    with CalibMenu do begin
      Init;
      SetStyleTitle(6,'Monitor Calibration');
      SetMessageXY(1,25);
      for actloop:=mBCal to mLinearComp do
        AddFullItem(strpas(menuLookup[actLoop].title),menuLookup[actLoop].id,0,strpas(menuLookup[actLoop].blurb),nil);
    end;

    with CompMenu do begin
      Init;
      SetStyleTitle(6,'Composite Monitor Tests');
      SetMessageXY(1,25);
      for actloop:=mCompWhich to mAspectNTSC do
        AddFullItem(strpas(menuLookup[actLoop].title),menuLookup[actLoop].id,0,strpas(menuLookup[actLoop].blurb),nil);
    end;

    with Regmenu do begin
      Init;
      SetStyleTitle(6,'M6845 Tests');
      SetMessageXY(1,25);
      for actloop:=mVert to mAddr do
        AddFullItem(strpas(menuLookup[actLoop].title),menuLookup[actLoop].id,0,strpas(menuLookup[actLoop].blurb),nil);
    end;

    with CapMenu do begin
      Init;
      SetStyleTitle(6,'Video capture Tests');
      SetMessageXY(1,25);
      for actloop:=mCapBarsRGB to mSync do
        AddFullItem(strpas(menuLookup[actLoop].title),menuLookup[actLoop].id,0,strpas(menuLookup[actLoop].blurb),nil);
    end;
  end;
end;

procedure DoCCT;
const
  ni=' NOT IMPLEMENTED ';
var
  MenuChoice:byte;
  SaveScreen:ScreenOBJ;
  Msg:MessageObj;
  menuaction,loop:userActions;
  actions:byte;
  astring:string;
begin
  if interactive then begin
    repeat
      MenuChoice:=MainMenu.Activate;
      SaveScreen.init;
      SaveScreen.save; {save current screen}
      {Translate menu choice into constant because case statements only take constants}
      for loop:=low(userActions) to high(userActions) do begin
        if MenuChoice=menuLookup[loop].id then menuAction:=loop;
      end;
      if MenuChoice=0 then menuaction:=mnull;
      case menuAction of
        mnull:{do nothing, user hit escape or something};
        mIntro:PopIntro;
        mAbout:PopAbout;
        {$IFDEF DETECT}
        mDetect:PopDetect;
        {$ENDIF}
        mTSnow:TestSnow;
        mBMR:BenchReadSpeed;
        mBMW:BenchWriteSpeed;
        mOARB:BenchReadSpeedOpcodes;
        mOAWB:BenchWriteSpeedOpcodes;
        m40col:Test40Col;
        mTHCB:TestBlinkBit;
        mTCur:TestCursor;
        mFont:TestFont;
        mBCol:TestBorder;
        mMcol:TestBackCol;
        mHcol:TestForeCol;
        mPal:TestPalettes;
        mBCal:CalibBrightness;
        mCCal:CalibContrast;
        mMoire:CalibMoire;
        mMoireColor:CalibMoireColor;
        mColor:CalibColor;
        mMono:CalibMonochrome;
        mVert:VertDetect;
        mHoriz:HorizDetect;
        mTCustom80:ShowText80x100;
        mTCustom90:ShowText90x30;
        mInterlace:TestInterlace;
        mPos:TestPosition;
        mAddr:TestStartAddress;
        mCompLo:LoTextColors;
        mCompHi:LoGrafColors;
        mCompWhich:DetermineCardType;
        mAspectNTSC:CalibAspectNTSC;
        mUniform:CalibUniform;
        mLinearRGB:CalibLinearRGB;
        mLinearComp:CalibLinearComp;
        mCapBarsRGB:BarsRGB;
        mCapBarsComp:BarsComp;
        mCapMotion:MotionTest;
        mCapRGBI:BarsRGBI;
        mSync:audioSync;
      else
        begin
          with msg do begin
            Init(1,ni);
            Addline('');
            AddLine(ni);
            Addline('');
            Show;
            Done;
          end;
        end;
      end; {case}
      SaveScreen.Display;
      SaveScreen.done; {restore current screen}
    until MenuChoice=0;
  end else begin
    {loop through all command-line requests}
    if is_param('h') or is_param('?') then begin
      asm
        push ds
        jmp @start
@message:
        db 0dh,0ah,'Command-line arguments are:',0dh,0ah,0ah
        {db 'ÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',0dh,0ah}
        db 'Argument ³Action',0dh,0ah
        db 'ÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',0dh,0ah
        db '/nXXXX   ³Delay XXXX seconds (default = 5) before exiting a test plate.',0dh,0ah
        db 'aspect   ³Display the NTSC monitor aspect ratio calibration test.',0dh,0ah
        db 'cbars    ³Display composite default color bars sorted by luminance.',0dh,0ah
        db 'rbars    ³Display RGBI calibration bars (meant for capture devices).',0dh,0ah
        db 'motion   ³Display 60Hz motion test. (Fixed for 8 seconds; ignores /n values)',0dh,0ah
        db 'audiosync³Display video+audio sync test.',0dh,0ah
        db '40col    ³Display 40-column test.',0dh,0ah
        db '/?       ³Display this help text.',0dh,0ah
        db '$'
@start:
        mov ax,0900h
        lea dx,@message
        mov bx,cs
        mov ds,bx
        int 21h
        pop ds
      end;
    end else begin
      writeln('Beginning automatic test plate generation.');
      writeln('If nothing happens, review command-line help with "/h".');
    end;

    if is_param('n') then timeoutsecs:=param_int('n');
    for actions:=1 to non_flag_count do begin
      astring:=downstring(non_flag_param(actions));
      {sure wish I could use a case statement with a string!}
      if astring='aspect' then CalibAspectNTSC;
      if astring='cbars' then BarsComp;
      if astring='rbars' then BarsRGBI;
      if astring='motion' then MotionTest;
      if astring='audiosync' then audioSync;
      if astring='40col' then test40col;
    end;
  end;
end;

procedure DoneCCT;
begin
  if not interactive then exit;
  MainMenu.done;
  SpeedMenu.done;
  ColorMenu.done;
  TextMenu.done;
  CalibMenu.done;
  Regmenu.done;
  Screen.Clear(TLightGray,' '); {paint the screen}
end;

end.
