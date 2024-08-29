{
  New script template, only shows processed records
  Assigning any nonzero value to Result will terminate script
}
unit userscript;

var
	shifter: String;
	frm: TForm;
	edFilter: TLabeledEdit;
	btnOk: TButton;
	
function ReadShifter: Sring;
begin
  frm := TForm.Create(nil);
  try
    frm.Caption := wbGameName + ' Assets Browser';
    frm.Width := 900;
    frm.Height := 550;
    frm.Position := poScreenCenter;

    edFilter := TLabeledEdit.Create(frm);
    edFilter.Parent := frm;
    edFilter.LabelPosition := lpLeft;
    edFilter.EditLabel.Caption := 'Shift by';
    edFilter.Left := 72;
    edFilter.Top := 8;
    edFilter.Width := 250;

    btnOk := TButton.Create(frm);
    btnOk.Parent := frm;
    btnOk.Top := edFilter.Top;
    btnOk.Left := edFilter.Left + edFilter.Width + 36;
    btnOk.Width := 120;
    btnOk.Caption := 'Ok';
    btnOk.Anchors := [akRight, akBottom];
    btnOk.ModalResult := mrOk;
    btnOK.Visible := True;
	
    if mrOk = frm.ShowModal then
		shifter := edFilter.Text;

  finally
    frm.Free;
  end;
end;

// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
begin
  Result := 0;
  shifter := 'JaneBod';
  if Length(shifter)=0 then
	Result := 1;
end;

function SubProcess(e: IInterface): Boolean;
const
  x = '.NIF';
var
  u: String;
  v: String;
  i: Integer;
  
begin
  Result := False;
  v := GetEditValue(e);
  u := Uppercase(v);
  if (Length(u)>0) and (Pos(x, u)>0) and (Pos(x, u)=(Length(u) - Length(x) + 1)) then begin
    // AddMessage(v);
	SetEditValue(e, shifter+'\'+v);
	Result := True;
  end;
  for i := 0 to Pred(ElementCount(e)) do
    Result := Result or SubProcess(ElementByIndex(e, i));
 end;
  
// called for every record selected in xEdit
function Process(e: IInterface): integer;
var
  i: Integer;
  s: string;
  r: IInterface;
  f: IInterface;
begin
  Result := 0;

  // comment this out if you don't want those messages
  AddMessage('Processing: ' + FullPath(e));
  if GetLoadOrder(GetFile(MasterOrSelf(e))) = 0 then Exit;
  
  // processing code goes here
  if SubProcess(e) then begin
    s := EditorID(e);
	if (s<>'') and (Pos(UpperCase(Shifter), UpperCase(s))=0) then begin
      SetEditorID(e, s+'_'+Shifter);
	  for i := 0 to Pred(ReferencedByCount(e)) do begin
	    r := ReferencedByIndex(e, i);
	    if Assigned(r) then begin
		  s := EditorID(r);
          if (s<>'') and (Pos(UpperCase(Shifter), UpperCase(s))=0) then
	        SetEditorID(r, s+'_'+Shifter);
          f := ElementBySignature(r, 'FULL');
          if Assigned(f) then
            s := GetEditValue(f)
          else
            s := '';
        if (s<>'') and (Pos(UpperCase(Shifter), UpperCase(s))=0) then
          SetEditValue(f, s+' ('+Shifter+')');
		end;
	  end;
	end;
  end;
end;

// Called after processing
// You can remove it if script doesn't require finalization code
function Finalize: integer;
begin
  Result := 0;
end;

end.