{
  Copy the text of scripts in selected dialogues.
}
unit UserScript;

var
  slB, slE: TStringList;
  basePath, extension: string;
	first, hasB, hasE, debug: boolean;
		
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
  if Signature(e) = 'INFO' then begin
    b := ElementByPath(e, 'Script (Begin)\Embedded Script');
		t := ElementBySignature(b, 'SCTX');
		if Assigned(t) then 
			if first then begin 
				slB.Text := GetEditValue(t);
				if debug then AddMessage('1: New value '+slB.Text);
				hasB := True;
			end else if not hasB then begin
				if debug then AddMessage('2: RemoveElement(b, ''SCTX'')');
				RemoveElement(b, t);
			end else begin
				if debug then AddMessage('3: SetEditValue(t, slB.Text) '+slB.Text);
				SetEditValue(t, slB.Text);
			end
		else if hasB then begin
			if debug then AddMessage('4: Add(b, ''SCTX'')');
			t := Add(b, 'SCTX', True);
			if debug then AddMessage('5: SetEditValue(t, slB.Text) '+slB.Text);
			SetEditValue(t, slB.Text);
		end else begin
			if debug then AddMessage('6: nothing to do');
		end;

    b := ElementByPath(e, 'Script (End)\Embedded Script');
		t := ElementBySignature(b, 'SCTX');
		if Assigned(t) then 
			if first then begin
				slE.Text := GetEditValue(t);
				if debug then AddMessage('11: New value '+slE.Text);
				hasB := True;
			end else if not hasB then begin
				if debug then AddMessage('12: RemoveElement(b, ''SCTX'')');
				RemoveElement(b, t);
			end else begin
				if debug then AddMessage('13: SetEditValue(t, slE.Text) '+ slE.Text);
				SetEditValue(t, slE.Text);
			end
		else if hasE then begin
			if debug then AddMessage('14: AddElement(b, ''SCTX'')');
			t := Add(b, 'SCTX', True);
			if debug then AddMessage('15: SetEditValue(t, slB.Text) '+slE.Text);
			SetEditValue(t, slE.Text);
		end else begin
			if debug then AddMessage('16: nothing to do');
		end;
		
		first := false;
  end;
  
end;

function finalize: integer;
begin
  slB.Free;
  slE.Free;
end;

end.
