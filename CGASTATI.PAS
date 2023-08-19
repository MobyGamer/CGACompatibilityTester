{$O-}
unit cgastaticdata;
{has static stuff we want to embed in the application}

interface

procedure t90x30;
procedure g256x200;
procedure g320x100;
procedure zx0_boxes;
procedure zx0_colorf1;
procedure zx0_cga_font;
procedure zx0_indiantp;
procedure zx0_shadcube;
procedure zx0_whichcga;

implementation

procedure t90x30; external;       {$L 90x30.obj}
procedure g256x200; external;     {$L 256x200.obj}
procedure g320x100; external;     {$L 320x100.obj}
procedure zx0_boxes; external;    {$L boxes.obj}
procedure zx0_colorf1; external;  {$L colorf1.obj}
procedure zx0_cga_font; external; {$L cga_font.obj}
procedure zx0_indiantp; external; {$L indiantp.obj}
procedure zx0_shadcube; external; {$L shadcube.obj}
procedure zx0_whichcga; external; {$L whichcga.obj}

end.
