{
  New script template, only shows processed records
  Assigning any nonzero value to Result will terminate script
}
unit CopyArmaNif;

uses
  Check_For_Errors;

var
  dest: IInterface;
  ArraySwap: array[1..65536, 1..2] of IInterface;
  ArrayRef:  array[1..65536] of IInterface;
  ArrayLink: array[1..65536, 1..2] of IInterface;
  LastArraySwap: Integer;
  LastArrayRef:  Integer;
  LastArrayLink: Integer;

function FirstReference(e: IInterface): Boolean;
begin
  Result := (Signature(e) = 'RACE')
         or (Signature(e) = 'FLST');
end;

function AllReference(e: IInterface): Boolean;
begin
  Result := (Signature(e) = 'FLST')
         or (Signature(e) = 'IDLE')
         or (Signature(e) = 'QUST')
         or (Signature(e) = 'DIAL')
         or (Signature(e) = 'INFO')
         or (Signature(e) = 'SCEN')
         or (Signature(e) = 'NPC_')
         or (Signature(e) = 'ACHR')
         or (Signature(e) = 'ACRE')
         or (Signature(e) = 'REFR')
         or (Signature(e) = 'PGRE')
         or (Signature(e) = 'PMIS')
         or (Signature(e) = 'PARW')
         or (Signature(e) = 'PBEA')
         or (Signature(e) = 'PFLA')
         or (Signature(e) = 'PCON')
	     or (Signature(e) = 'PBAR')
         or (Signature(e) = 'PHZD');
end;

function BlockReference(e: IInterface): Boolean;
begin
  Result := AllReference(e) or FirstReference(e);
end;

//=========================================================================
// FileSelectM: File selection window for copying. Taken from Merge plugins v1.65
function FileSelectM(lbl: string): Integer;
var
  frm: TForm;
  cmbFiles: TComboBox;
  btnOk, btnCancel: TButton;
  lbl01: TLabel;
  i, j, llo: integer;
  s: string;
  f: IInterface;
begin
  frm := TForm.Create(frm);
  Result := -2;
  try
    frm.Caption := 'Select File';
    frm.Width := 300;
    frm.Height := 200;
    frm.Position := poScreenCenter;
    
    lbl01 := TLabel.Create(frm);
    lbl01.Parent := frm;
    lbl01.Width := 250;
    lbl01.Height := 60;
    lbl01.Left := 8;
    lbl01.Top := 8;
    lbl01.Caption := lbl;
    lbl01.Autosize := false;
    lbl01.Wordwrap := True;
    
    cmbFiles := TComboBox.Create(frm);
    cmbFiles.Parent := frm;
    cmbFiles.Items.Add('-- CREATE NEW FILE --');
    cmbFiles.Top := 33 + lbl01.Height;
    cmbFiles.Left := 8;
    cmbFiles.Width := 200;
    llo := 0;
    
    for i := 0 to FileCount - 1 do begin
      s := GetFileName(FileByIndex(i));
      cmbFiles.Items.Add(s);
    end;
    cmbFiles.ItemIndex := 0;
    
    btnOk := TButton.Create(frm);
    btnOk.Parent := frm;
    btnOk.Left := 60;
    btnOk.Top := cmbFiles.Top + 50;
    btnOk.Caption := 'OK';
    btnOk.ModalResult := mrOk;
    
    btnCancel := TButton.Create(frm);
    btnCancel.Parent := frm;
    btnCancel.Caption := 'Cancel';
    btnCancel.ModalResult := mrCancel;
    btnCancel.Left := btnOk.Left + btnOk.Width + 16;
    btnCancel.Top := btnOk.Top;
    
    if frm.ShowModal = mrOk then begin
      if SameText(cmbFiles.Items[cmbFiles.ItemIndex], '-- CREATE NEW FILE --') then begin
        f := AddNewFile;
        Result := Pred(FileCount);
      end
      else begin
        for i := 0 to FileCount - 1 do begin
          if SameText(cmbFiles.Items[cmbFiles.ItemIndex], GetFileName(FileByIndex(i))) then begin
            Result := i;
            Continue;
          end;
        end;
        if Result = -2 then begin
          AddMessage('The script couldn''t find the file you entered.');
          Result := FileSelectM(lbl);
        end;
      end;
    end;
  finally
    frm.Free;
  end;
end;

// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
var
  c: Integer;
  i: Integer;
  m: Integer;
  e: String;
  n: String;
begin
  Result := 0;
  c := FileCount;
  AddMessage('Initialize: ' + IntToStr(c) + ' plugins.');
  m := FileSelectM('Copy into which EMPTY plugin?');
  if m = -2 then begin
    Result := 1;
	Exit;
  end;
  dest := FileByIndex(m);
  if not Assigned(dest) then begin
    Result := 1;
	Exit;
  end;
  
  for i := 0 to m do
	BuildRef(FileByIndex(i));
	
  for i := 0 to Pred(m) do begin
    n := GetFileName(FileByIndex(i));
    e := Uppercase(ExtractFileExt(n));
	if (e = '.ESM') or (e = '.ESP') then
      try AddMasterIfMissing(dest, n); except end;
  end;
  
  LastArraySwap := 0;
  LastArrayRef := 0;
  LastArrayLink := 0;
end;

function GetSwap(e: IInterface): IInterface;
var
  i: Integer;
begin
  Result := nil;
  for i := 1 to LastArraySwap do
    if GetLoadOrderFormID(ArraySwap[i, 1]) = GetLoadOrderFormID(e) then begin
      Result := ArraySwap[i, 2];
	  Break;
	end;
end;

procedure SwapRecord(e, c: IInterface);
var
  i: Integer;
  Found: Boolean;
begin
  // e is the original record
  // c is the copy of the record
  Inc(LastArraySwap);
  ArraySwap[LastArraySwap, 1] := e;
  ArraySwap[LastArraySwap, 2] := c;
end;

function GetRef(r: IInterface): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 1 to LastArrayRef do
    if GetLoadOrderFormID(ArrayRef[i]) = GetLoadOrderFormID(r) then begin
      Result := True;
	  Break;
	end;
end;

function RefRecord(r, e: IInterface): Boolean;
var
  i: Integer;
  Found: Boolean;
begin
  // r is the referencing record
  // e is the original record
  Inc(LastArrayLink);
  ArrayLink[LastArrayLink, 1] := r;
  ArrayLink[LastArrayLink, 2] := e;
  if not GetRef(r) then begin
    Inc(LastArrayRef);
    ArrayRef[LastArrayRef] := r;
	Result := True;
  end else
    Result := False;
end;

procedure SwapProcess(r, n, e, c: IInterface);
var
  i,j: Integer;
begin
  // r is the referencing record
  // n is the copy of the referencing record
  // e is the original record
  // c is the copy of the record
  if CanContainFormIDs(r) then begin
    j := ElementType(r);
    if (j = etValue) or (j = etSubRecord) then begin
      // AddMessage('"' + FullPath(r) + '" ? "' + FullPath(e) +'"');
	  if GetNativeValue(r) = FormID(e) then
        try SetNativeValue(n, FormID(c)); except
          AddMessage('>>>Error editing "' + FullPath(r) + '" ? "' + FullPath(e) +'"');
		end;
    end else
      for i := 0 to Pred(ElementCount(r)) do
        SwapProcess(ElementByIndex(r, i), ElementByIndex(n, i), e, c);
  end;
end;

function CheckProcess(e: IInterface): Boolean;
const
  x = '.NIF';
var
  u: String;
  v: String;
  i: Integer;
  p: String;
begin
  Result := False;
  v := GetEditValue(e);
  u := Uppercase(v);
  if (Length(u)>0) and (Pos(x, u)>0) and (Pos(x, u)=(Length(u) - Length(x) + 1)) then begin
    p := wbDataPath+'Meshes\'+v;
    // AddMessage('Testing: for {' + p +'}');
    if FileExists(p) then
      Result := True;
  end;
  if not Result then 
    for i := 0 to Pred(ElementCount(e)) do
      if CheckProcess(ElementByIndex(e, i)) then begin
        Result := True;
        Break;
      end;
 end;

var
  m: Integer;
  s: string;
  
function BoolStr(b: Boolean): String;
begin
  if b then
    return 'True '
  else
    return 'False';
end;

procedure RefProcess(b, e: IInterface; level: Integer);
var
  i: Integer;
  r: IInterface;
  n: Integer;
  Added: Boolean;
begin
  s :=  '  ' + s;
  Inc(level);
  try
    n := ReferencedByCount(e);
    // AddMessage(s + IntToHex(level, 3) + ': (' + IntToStr(n) + ') ' + FullPath(e) + ' from ' + FullPath(b));
    for i := 0 to Pred(n) do begin
      r := ReferencedByIndex(e, i);
      if Assigned(r) and (GetLoadOrderFormID(r)>0) then begin
        Added := not BlockReference(r);
        if not Added and (level < 3) then
          Added := FirstReference(r);
        if Added then
          Added := RefRecord(r, e);
        if Added then begin
          // AddMessage(s + IntToHex(level, 3) + ': (' + IntToStr(n) + ') ' + FullPath(r) + ' from ' + FullPath(e));
          if (level <= m) then begin
            if not BlockReference(r) then begin
              // AddMessage(s + '    [' + Name(r) + ']');
              RefProcess(e, r, level);
            end;
          end else
            AddMessage('Too many nested references [' + InttoStr(level) + '] [' + IntToStr(n) + ']' + FullPath(r) + ' from ' + FullPath(e));
        end
      end;
    end;
  finally
    dec(level);
    Delete(s, 1, 2);
  end;
end;

// called for every record selected in xEdit
function Process(e: IInterface): integer;
var
  c: IInterface;
begin
  Result := 0;

  // comment this out if you don't want those messages
  // AddMessage('Processing: ' + FullPath(e));
  
  if (Signature(e) = 'ARMA') and IsWinningOverride(e) and CheckProcess(e) then begin
    AddMessage('Found: ' + FullPath(e));
    c := wbCopyElementToFile(e, dest, True, True);
    if Assigned(c) then begin
      SwapRecord(e, c);
      m := 20;		// Max Nested Level
      s := '';		// Indentation
      RefProcess(e, e, 0);
    end;
  end;
end;

// Called after processing
// You can remove it if script doesn't require finalization code
function Finalize: integer;
var
  i,j: Integer;
  n: IInterface;
  c: IInterface;
  e: Boolean;
begin
  Result := 0;
  AddMessage('References: ' + IntToStr(LastArrayRef) + ' objects in ' + IntToStr(LastArrayLink) + ' combinations');
  
  e := False;
  for i := 1 to LastArrayRef do begin
    // AddMessage('Check: ' + Name(ArrayRef[i]) + ' : ' + IntToStr(LastArrayRef - i));
    e := e or CheckForErrors(0, ArrayRef[i]);
  end;
  if e then // At least one of the form won't be copied
    Exit;

  for i := 1 to LastArrayRef do begin
    // AddMessage('Copy: ' + Name(ArrayRef[i]) + ' : ' + IntToStr(LastArrayRef - i));
    n := wbCopyElementToFile(ArrayRef[i], dest, True, True);
    if Assigned(n) then begin
      // AddMessage('  Copied as ' + Name(n));
      SwapRecord(ArrayRef[i], n);
    end;
  end;

  for i := 1 to LastArrayRef do begin
    // AddMessage('Reference: ' + Name(ArrayRef[i]) + ' : ' + IntToStr(LastArrayRef - i));
    n := GetSwap(ArrayRef[i]);
    if Assigned(n) then begin
      // AddMessage('  changed to ' + Name(n));
      for j := 1 to LastArrayLink do begin
        // AddMessage('    Link: ' + Name(ArrayLink[j, 1]) + ' links to ' + Name(ArrayLink[j, 2]));
        if GetLoadOrderFormID(ArrayLink[j, 1]) = GetLoadOrderFormID(ArrayRef[i]) then begin
          // AddMessage('  ['+ IntToHex(GetLoadOrderFormID(ArrayRef[i]), 8)+'] links to ['+ IntToHex(GetLoadOrderFormID(ArrayLink[j, 2]), 8)+']');
          // AddMessage('    ' + Name(ArrayLink[j, 1]) + ' links to ' + Name(ArrayLink[j, 2]) + ' (Remains: ' + IntToStr(LastArrayLink - j) + ')');
          c := GetSwap(ArrayLink[j, 2]);
          if Assigned(c) then begin
            // AddMessage('      ['+ IntToHex(GetLoadOrderFormID(n), 8)+'] changed to ' + Name(c) + ' ['+ IntToHex(GetLoadOrderFormID(c), 8)+']');
            SwapProcess(ArrayRef[i], n, ArrayLink[j, 2], c);
          end;
        end;
      end;
    end;
  end;
  CleanMasters(dest);
end;

end.
