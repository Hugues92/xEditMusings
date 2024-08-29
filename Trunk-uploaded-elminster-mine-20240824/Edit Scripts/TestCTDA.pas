{
  New script template, only shows processed records
  Assigning any nonzero value to Result will terminate script
}
unit userscript;

// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
begin
  Result := 0;
end;

function ParseConditions(conditions: IInterface): string;
var
  ctda: IInterface;
  i: integer;
  func: string;
begin
  for i := 0 to ElementCount(conditions) - 1 do begin
    ctda := ElementByIndex(conditions, i);

    func := GetElementEditValues(ctda, 'Function');
    if func = 'GetIsSex' then begin
      if GetElementEditValues(ctda, 'Sex') = 'Male' then
        AddMessage('Found Male   : ' + FullPath(conditions))
      else
        AddMessage('Found Female : ' + FullPath(conditions));
    end;
  end;
end;

procedure recurse(e: IInterface);
var
  i: Integer;
begin
  // AddMessage('  Recursing: ' + FullPath(e));

  if Signature(e)='CTDA' then
  begin
    // comment this out if you don't want those messages
    // AddMessage('    Processing: ' + FullPath(e));
    ParseConditions(e);
  end else
    for i := 0 to Pred(ElementCount(e)) do
      Recurse(ElementByIndex(e, i));

end;

// called for every record selected in xEdit
function Process(e: IInterface): integer;
begin
  Result := 0;

  // AddMessage('Entering: ' + FullPath(e));

  Recurse(e);

  // processing code goes here

end;

// Called after processing
// You can remove it if script doesn't require finalization code
function Finalize: integer;
begin
  Result := 0;
end;

end.
