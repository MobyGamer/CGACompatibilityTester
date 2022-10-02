{$I cgaflags.inc}

{
CGA Compatibility tester, trixter@oldskool.org

Created at the request of the community, to benchmark CGA video adapters
for speed and compatibility with real IBM CGA.
}

program cga_comp;

uses
  {$IFDEF OVERLAY} overlay,cga_overlay, {$ENDIF}
  cgacmain;

{$IFDEF OVERLAY}
  {Note: documentation discourages overlaying TOTSYS, TOTINPUT, and TOTFAST}
  {$IFDEF EXTREMEOVERLAY}
  {$O totfast}
  {$O totsys}
  {$O totinput}
  {$ENDIF}
  {$O support}

  {$O totmsg}
  {$O totIO1}
  {$O totmenu}
  {$O totwin}
  {$O totlook}

  {$O cgacmain}
  {$O cgaccommon}
  {$O cgabtests}
  {$O cgattests}
  {$O cgactests}
  {$O cgamtests}
  {$O cgartests}
  {$O comptests}
  {$O cgacapture}

  {$O cgalib}

{$ENDIF}

begin
  InitCCT;
  doCCT;
  DoneCCT;
end.
