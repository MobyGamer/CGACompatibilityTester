{$O-}
unit cgastaticdata;
{has static stuff we want to embed in the application}

interface

procedure t90x30;
procedure g256x200;
procedure g320x100;

implementation

procedure t90x30; external; {$L 90x30.obj}
procedure g256x200; external; {$L 256x200.obj}
procedure g320x100; external; {$L 320x100.obj}

end.
