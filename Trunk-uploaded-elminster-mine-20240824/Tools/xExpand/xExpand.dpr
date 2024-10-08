program xExpand;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Windows,
  Classes,
  lz4 in '..\..\External\lz4\lib\delphi\lz4.pas',
  lz4Common in '..\..\External\lz4\lib\delphi\lz4Common.pas';

const
  SSEMagic = 'TESV_SAVEGAME';

type
  TSSESaveHeader = record
    Magic:              array[1..13] of Byte;
    HeaderSize:         Integer;
    Version:            Integer;
    Header:             TBytes;
    ScreenshotWidth:    Integer;
    Screenshotheight:   Integer;
    CompressionType:    Word;
    UncompressedSize:   Integer;
    CompressedSize:     Integer;
  end;

var
  bs: TBytes;
  bd: TBytes;
  sh: TSSESaveHeader;
  ss: TBytes;
  hs: Integer;
  si: Integer;

function ReadSSEHeader(S: TFileStream; var SaveHeader: TSSESaveHeader): Boolean;
var
  i:  Integer;
begin
  Result := False;

  FillChar(SaveHeader, SizeOf(TSSESaveHeader), 0);

  if (13 = S.Read(SaveHeader.Magic, 13)) then
    for i := 1 to Length(SSEMagic) do
      if (Ord(SSEMagic[i]) <> SaveHeader.Magic[i])
        then Exit;

  S.Read(SaveHeader.HeaderSize, 4);
  S.Read(SaveHeader.Version, 4);
  hs := SaveHeader.HeaderSize - 4 - 4 - 4;  // Version, Width and Height
  if SaveHeader.Version > 10 then Dec(hs, 2); // CompressionSize

  SetLength(SaveHeader.Header, hs);
  S.Read(SaveHeader.Header[0], hs);
  S.Read(SaveHeader.ScreenshotWidth, 4);
  S.Read(SaveHeader.ScreenshotHeight, 4);
  if SaveHeader.Version >  9 then si := 4 else si := 3;
  if SaveHeader.Version > 10 then S.Read(SaveHeader.CompressionType, 2);
  si := si * SaveHeader.ScreenshotWidth * SaveHeader.ScreenshotHeight;
  SetLength(ss, si);
  S.Read(ss[0], si);
  if SaveHeader.CompressionType <> 0 then begin
    S.Read(SaveHeader.UncompressedSize, 4);
    S.Read(SaveHeader.CompressedSize, 4);
  end;

  Result := True;
end;

function WriteSSEHeader(D: TFileStream; var SaveHeader: TSSESaveHeader): Boolean;
var
  nc: Word;
begin
  try
    D.Write(SaveHeader.Magic, 13);
    D.Write(SaveHeader.HeaderSize, 4);
    D.Write(SaveHeader.Version, 4);
    D.Write(SaveHeader.Header[0], hs);
    D.Write(SaveHeader.ScreenshotWidth, 4);
    D.Write(SaveHeader.ScreenshotHeight, 4);
    if SaveHeader.Version >  9 then si := 4 else si := 3;
    nc := 0;
    if SaveHeader.Version > 10 then D.Write(nc, 2);
    si := si * SaveHeader.ScreenshotWidth * SaveHeader.ScreenshotHeight;
    D.Write(ss[0], si);
    Result := True;
  except
    Result := False;
  end;
end;

procedure DecompressSSE(n: String);
var
  S,
  D:    TFileStream;
  l:    Int64;
  b:    Int64;
  z:    Int64;
//  r:    Integer;
begin
  WriteLN(n);
  try  {$I+}
    S := TFileStream.Create(n, fmOpenRead);
    S.Seek(0, soFromEnd);
    z := S.Position;
    S.Seek(0, soFromBeginning);
    if ReadSSEHeader(S, sh) and (sh.CompressionType=2) then
      try
        D := TFileStream.Create(ChangeFileExt(n, '.uncompressed_ess'), fmCreate);
        if WriteSSEHeader(D, sh) then begin
          WriteLN(' Position=' + IntToStr(S.Position) + ' Size=' + IntToStr(z) + ' USize=' +
            IntToStr(sh.UncompressedSize) + ' CSize=' + IntToStr(sh.CompressedSize) +
             ' FSize=' + IntToStr(S.Position + sh.UncompressedSize));
          SetLength(bd, sh.UncompressedSize);
          SetLength(bs, sh.CompressedSize);
          b := sh.CompressedSize;
          l := S.Read(bs, b);
          if b = l then begin
            {r :=} LZ4_decompress_safe(@bs[0], @bd[0], sh.CompressedSize, sh.UncompressedSize);
            D.Write(bd, sh.UncompressedSize);
          end else
            WriteLN('  Invalid read: Expected=' + IntToStr(b) + ' Actual=' + IntToStr(l));
//          b := 0;
        end;
      finally
        SetLength(bd, 0);
        SetLength(bs, 0);
        SetLength(ss, 0);
        FreeAndNil(D);
      end;
  finally
    FreeAndNil(S);
  end;
end;

procedure ExpandAndApply(s: String);
var
  n: String;
  p: String;
  r: TSearchRec;
  v: Integer;
begin
  n := ExpandFileName(s);
  if DirectoryExists(n) then n := n+'\*.*';
  p := ExtractFilePath(n);

  v := FindFirst(n, faAnyFile, R);
  if v = 0 then
    try
      repeat
        if (R.Attr and faDirectory) = faDirectory then begin
          if (R.Name<>'.') and (R.Name<>'..') then
          else
            if Pos('*', n) > 0 then
              ExpandAndApply(p+R.Name)
        end else begin
          if SameStr(ExtractFileExt(n), '.ess') then
            DecompressSSE(ExpandFileName(p+R.Name));
        end;
        v := FindNext(R);
      until v <> 0
    finally
      SysUtils.FindClose(R);
    end
  else
    WriteLN('File not found: '+s);
end;

var
  pi: Integer;
  pn: Integer;

begin
  try
    pn := ParamCount;
    if pn=0 then
      WriteLN('Usage: ' + ParamStr(0) + ' [path](mask|name) [..[path](mask|name) ]')
    else
      for pi := 1 to pn do
        ExpandAndApply(ParamStr(pi));
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  if IsDebuggerPresent then ReadLN;

end.
