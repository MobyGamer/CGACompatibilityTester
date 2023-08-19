{$O+,F+}
unit CGABTESTS;
{Contains all of the benchmarking tests/procedures for the CGA compatibility tester}

interface

Procedure BenchReadSpeed;
Procedure BenchWriteSpeed;
Procedure BenchReadSpeedOpcodes;
Procedure BenchWriteSpeedOpcodes;

implementation

uses
  strings,m6845ctl,totmsg,ztimer,support,totIO1,totfast,cgaccommon,TInterrupts;

Procedure ReportSpeed(s1:string;bs:word;s2,s3:string;ss:word);
begin
  Screen.Write(s1+' '+inttostr(bs)+' '+s2+' ');
  Screen.Writeln(inttostr(_PZTimerCount)+' æsecs.');
  {if machine is WACKO fast then we need to handle things differently}
  if _PZTimerCount=-1 then begin
    PrintInvalidMsg;
    repeat until keypressed;
    PostTest;
    exit;
  end;
  Screen.Writeln(s3+' '+inttostr(round((bs*(1000000/1024)) / _PZTimerCount))+' KB/s.');
  Screen.Writeln('A stock 4.77 MHz 8088 IBM PC with original IBM CGA achieves '+inttostr(ss)+' KB/s.');
  Screen.Writeln('Press any key to continue.');
  repeat until keypressed;
end;

Procedure BenchReadSpeed;
const
  BlockSize=$2000;
begin
  with InfoPrompt do begin
    init(6,strpas(menuLookup[mBMR].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This benchmarks your video adapter RAM''s maximum read');
    AddLine('speed and displays the result.  Use this to compare how');
    AddLine('fast (or slow) your adapter is compared to real CGA.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  PrepTest;
  asm
    push ds
    mov cx,BlockSize
    shr cx,1
    mov ax,$b800
    mov ds,ax
    xor si,si
    cld
    call _PZTimerOn
    rep lodsw
    call _PZTimerOff
    pop ds
  end;

  ReportSpeed('Reading',BlockSize,'bytes of your video adapter RAM took',
  'Your video RAM''s read speed is',291);
  PostTest;
end;

Procedure BenchWriteSpeed;
const
  BlockSize=$2000;
begin
  with InfoPrompt do begin
    init(6,strpas(menuLookup[mBMW].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This benchmarks your video adapter RAM''s maximum write');
    AddLine('speed and displays the result.  Use this to compare how');
    AddLine('fast (or slow) your adapter is to real CGA.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  PrepTest;
  asm
    mov ax,$b800
    mov es,ax
    xor di,di
    mov cx,BlockSize
    shr cx,1
    mov ax,$0F00 {black back, white fore, 00 char}
    cld
    call _PZTimerOn
    rep stosw
    call _PZTimerOff
  end;

  ReportSpeed('Writing',BlockSize,'bytes of your video adapter RAM took',
  'Your video RAM''s write speed is',340);

  PostTest;
end;

Procedure BenchReadSpeedOpcodes;
const
  BlockSize=$1000;
begin
  with InfoPrompt do begin
    init(6,strpas(menuLookup[mOARB].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This benchmarks your video adapter RAM''s read speed');
    AddLine('with CPU no-op instructions interleaved with memory');
    AddLine('accesses.  This can be used to test if CPU caching');
    AddLine('and/or bus speed affects the speed of video adapter RAM.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  PrepTest;
  asm
    push ds
    mov ax,$b800
    mov ds,ax
    xor si,si
    cld
    mov cx,BlockSize
    shr cx,1
    shr cx,1
    shr cx,1
    shr cx,1
    call _PZTimerOn
@loopit: {unrolled a bit, so that the flush at JMP time doesn't totally cripple us}
    lodsb;nop;lodsb;nop;lodsb;nop;lodsb;nop;
    lodsb;nop;lodsb;nop;lodsb;nop;lodsb;nop;
    lodsb;nop;lodsb;nop;lodsb;nop;lodsb;nop;
    lodsb;nop;lodsb;nop;lodsb;nop;lodsb;nop;
    loop @loopit
    call _PZTimerOff
    pop ds
  end;

  ReportSpeed('Reading',BlockSize,'bytes of video RAM mixed with NOPs took',
  'This means our interleaved read speed was',199);

  PostTest;
end;

Procedure BenchWriteSpeedOpcodes;
const
  BlockSize=$1000;
begin
  with InfoPrompt do begin
    init(6,strpas(menuLookup[mOAWB].title));
    WinForm^.vWinPtr^.SetColors(descBorder,descBody,descTitle,descIcons);
    AddLine('');
    AddLine('This benchmarks your video adapter RAM''s write speed');
    AddLine('with CPU no-op instructions interleaved with memory');
    AddLine('accesses.  This can be used to test if CPU caching');
    AddLine('and/or bus speed affects the speed of video adapter RAM.');
    AddLine('');
    SetOption(1,cstring,67,Finished);
    SetOption(2,astring,65,Escaped);
    Result:=Show;
    Done;
  end;
  if Result=Escaped then exit;
  PrepTest;
  asm
    mov ax,$b800
    mov es,ax
    xor di,di
    cld
    mov cx,BlockSize
    shr cx,1
    shr cx,1
    shr cx,1
    shr cx,1
    xor al,al
    call _PZTimerOn
@loopit: {unrolled a bit, so that the flush at JMP time doesn't totally cripple us}
    stosb;nop;stosb;nop;stosb;nop;stosb;nop;
    stosb;nop;stosb;nop;stosb;nop;stosb;nop;
    stosb;nop;stosb;nop;stosb;nop;stosb;nop;
    stosb;nop;stosb;nop;stosb;nop;stosb;nop;
    loop @loopit
    call _PZTimerOff
  end;
  Screen.Clear(TWhite,' '); {repaint the screen since we just trashed it}
  ReportSpeed('Writing',BlockSize,'bytes of video RAM mixed with NOPs took',
  'This means our interleaved write speed was',194);

  PostTest;
end;

end.