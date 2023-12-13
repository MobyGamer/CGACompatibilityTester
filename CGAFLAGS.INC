{$M 10240,0,262144}
{compilation flags}

{{$DEFINE OVERLAY} {use overlays} {only for when trying to develop on 5160}
{{$DEFINE EXTREMEOVERLAY} {overlay EVERYTHING -- may not be what you want!}

{{$DEFINE DEBUG}

{$IFDEF DEBUG}
{$A+,D+,I+,Q+,R+,S+,V+,X+}
{$ENDIF}
