{
  Duplicate the conditions in the first selected form to all other selected forms.
}
unit UserScript;

var
  slB, slE: TStringList;
  basePath, extension: string;
	first, hasB, hasE, debug: boolean;
  theFirst: IInterface;
  
function Initialize: integer;
var
  i: TIniFile;
begin
  slB := TStringList.Create;
  slE := TStringList.Create;
	debug := False;
	first := True;
	hasB := False;
	hasE := False;
end;

function Process(e: IInterface): integer;
var
  b, t: IInterface;
begin
  if not (ElementType(e) = etMainRecord) then Exit;
  
  t := ElementByName(e, 'Conditions');
  if Assigned(t) then 
    if first then begin 
      theFirst := t;
      first := false;
    end else begin
      ElementAssign(t, MinInt, theFirst, False);
    end;

end;

function finalize: integer;
begin
  slB.Free;
  slE.Free;
end;

end.
