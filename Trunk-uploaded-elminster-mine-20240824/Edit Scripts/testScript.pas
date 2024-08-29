{
  New script template, only shows processed records
  Assigning any nonzero value to Result will terminate script
}
unit TestScript;

var
  verbose: Boolean;
  
function GetGlobalByID(id: Integer; f: IInterface; var g: IInterface; var v: float): boolean;
var
  e: IInterface;
  i: Integer;
begin
  e := nil;
  if id > 0 then
    if Assigned(f) then
      g := RecordByFormID(f, LoadOrderFormIDtoFileFormID(f, id), False)
    else
      for i := Pred(FileCount) downto 0 do begin
        f := FileByIndex(i);
        if Assigned(f) then begin
          // if verbose then AddMessage('  file at index ' + IntToStr(i) + ' is "' + GetFileName(f) + '"');
          g := RecordByFormID(f, LoadOrderFormIDtoFileFormID(f, id), False);
          if Assigned(g) then
            Break;
        end;
      end;
  if assigned(g) then
    g := WinningOverride(g);
  if assigned(g) then
    e := ElementBySignature(g, 'FLTV');
  if assigned(e) then begin
    v := GetNativeValue(e);
    Result := true;
  end else
    Result := false;
end;

function GetGlobal(g: IInterface; var v: float): boolean;
var
  e: IInterface;
begin
  e := nil;
  if assigned(g) then
    e := ElementBySignature(g, 'FLTV');
  if assigned(e) then begin
    v := GetNativeValue(e);
    Result := true;
  end else
    Result := false;
end;

function GetAVbyID(id: Integer; f: IInterface; var av: IInterface; var v: float): boolean;
var
  e: IInterface;
  i: Integer;
begin
  e := nil;
  if id > 0 then
    if Assigned(f) then
      av := RecordByFormID(f, LoadOrderFormIDtoFileFormID(f, id), False)
    else
      for i := Pred(FileCount) downto 0 do begin
        f := FileByIndex(i);
        if Assigned(f) then begin
          // if verbose then AddMessage('  file at index ' + IntToStr(i) + ' is "' + GetFileName(f) + '"');
          av := RecordByFormID(f, LoadOrderFormIDtoFileFormID(f, id), False);
          if Assigned(av) then
            Break;
        end;
      end;
  if assigned(av) then
    av := WinningOverride(av);
  if assigned(av) then
    e := ElementBySignature(av, 'NAM0');
  if assigned(e) then begin
    v := GetNativeValue(e);
    Result := true;
  end else
    Result := false;
end;

function GetAVdefault(av: IInterface; var v: float): boolean;
var
  e: IInterface;
begin
  e := nil;
  if assigned(av) then
    e := ElementBySignature(av, 'NAM0');
  if assigned(e) then begin
    v := GetNativeValue(e);
    Result := true;
  end else
    Result := false;
end;

function GetNPCav(a: IInterface; av: IInterface; var v: float): boolean;
var
  e,p,k: IInterface;
  avAR: IInterface;
  avID: Integer;
  i: Integer;
  r: Integer;
  b: Boolean;
begin
  e := nil;
  k := nil;
  p := nil;
  avAR := nil;
  avID := -1;
  if assigned(av) then
    avID := FormID(av)
  else if verbose then AddMessage('av missing');
  if assigned(a) then
    avAR := ElementBySignature(a, 'PRPS')
  else if verbose then AddMessage('av array not found');
  if Assigned(avAR) then
    for i := 0 to Pred(ElementCount(avAR)) do begin
      p := ElementByIndex(avAR, i);
      if Assigned(p) then begin
        k := ElementByIndex(p, 0);
        r := GetNativeValue(k);
        // if verbose then AddMessage('  element at index ' + IntToStr(i) + ' is [' + IntToHex(r, 8) + ']');
      end else if verbose then AddMessage('element not found at index ' + IntToStr(i));
      if r = avID then begin
        e := ElementByIndex(p, 1);
        break;
      end;
    end; 
  if assigned(e) then begin
    v := GetNativeValue(e);
    Result := true;
  end else begin
    b := GetAVdefault(av, v);
    Result := false;
    if verbose then if b then AddMessage('av not set') else AddMessage('av has no default');
  end;
end;

// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
var
  e,f,gf,g,a,av: IInterface;
  b: Boolean;
  v, d: float;
begin
  Result := 0;
  Verbose := True;
  f := nil;
  g := nil;
  e := nil;

  gf := FileByIndex(0);
  f := FileByIndex(2);
  
  b := GetGlobalByID($01000800, nil, g, v);
  if b then
    AddMessage('Test global by ID [01000800] : ' + FloatToStr(v))
  else
    AddMessage('Test global by ID not found');

  if assigned(gf) then
    b := GetAVbyID($000002C8, gf, av, d);
  if b then
    AddMessage('Test AV [000002C8] default : ' + FloatToStr(d))
  else
    AddMessage('Test AV not found');
    
  if assigned(f) then
    g := RecordByFormID(f, $01000800, False);
  if assigned(g) then
    g := WinningOverride(g);
  if assigned(g) then
    b := GetGlobal(g, v);
  if b then
    AddMessage('Test global [01000800] : ' + FloatToStr(v))
  else
    AddMessage('Test global not found');

  if assigned(f) then
    a := RecordByFormID(f, $00000007, False);
  if assigned(a) then
    a := WinningOverride(a);
  if assigned(g) and assigned(av) then
    b := GetNPCav(a, av, v);
  if b then
    AddMessage('Test NPC [00000007] AV [000002C4] : ' + FloatToStr(v))
  else
    AddMessage('Test NPC AV not found');
end;

// called for every record selected in xEdit
{ function Process(e: IInterface): integer;
begin
  Result := 0;

  // comment this out if you don't want those messages
  AddMessage('Processing: ' + FullPath(e));

  // processing code goes here

end;
 }
// Called after processing
// You can remove it if script doesn't require finalization code
function Finalize: integer;
begin
  Result := 0;
end;

end.
