{
  "Copy as override" implemented via script, limited to NPC.
  Can be used to copy only filtered results, which xEdit's internal function can't do.
}
unit CopyNPCAsOverride;

uses
	'Check For Errors';
	
var
  ToFile: IInterface;

function Process(e: IInterface): integer;
var
  i: integer;
  frm: TForm;
  clb: TCheckListBox;
	r: IInterface;
begin
  if Signature(e) <> 'NPC_' then
    Exit;
  if not IsWinningOverride(e) then
		Exit;
		
  if not Assigned(ToFile) then begin
    frm := frmFileSelect;
    try
      frm.Caption := 'Select a plugin';
      clb := TCheckListBox(frm.FindComponent('CheckListBox1'));
      clb.Items.Add('<new file>');
      for i := Pred(FileCount) downto 0 do
        if GetFileName(e) <> GetFileName(FileByIndex(i)) then
          clb.Items.InsertObject(1, GetFileName(FileByIndex(i)), FileByIndex(i))
        else
          Break;
      if frm.ShowModal <> mrOk then begin
        Result := 1;
        Exit;
      end;
      for i := 0 to Pred(clb.Items.Count) do
        if clb.Checked[i] then begin
          if i = 0 then ToFile := AddNewFile else
            ToFile := ObjectToElement(clb.Items.Objects[i]);
          Break;
        end;
    finally
      frm.Free;
    end;
    if not Assigned(ToFile) then begin
      Result := 1;
      Exit;
    end;
  end;
	try
		if not CheckForErrors(1, e) then begin
			AddRequiredElementMasters(e, ToFile, False);
			r := wbCopyElementToFile(e, ToFile, False, True);
		end;
	except
	end;
end;

end.