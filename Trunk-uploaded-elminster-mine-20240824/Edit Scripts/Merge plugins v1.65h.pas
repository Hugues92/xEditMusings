{
  Merge Plugins Script v1.65
  Created by matortheeternal
  http://skyrim.nexusmods.com/mod/37981
  
  *CHANGES*
  v1.65
    - Hotfix for the asset copying error.
  
  *DESCRIPTION*
  This script will allow you to merge ESP files.  This won't work on files with 
  corrupted data.  You can set user variables at in the constansts section (const) 
  to customize how the script runs.
}

unit MergePlugins;

uses mteFunctionsH, Check_For_Errors;

const
  vs = 'v1.65';
  bethesdaFiles = 'Skyrim.esm'#13'Update.esm'#13'Dawnguard.esm'#13'Hearthfires.esm'#13'Dragonborn.esm'#13
  'Skyrim.Hardcoded.keep.this.with.the.exe.and.otherwise.ignore.it.I.really.mean.it.dat'#13
  'FalloutNV.esm'#13'DeadMoney.esm'#13'HonestHearts'#13'OldWorldBlues'#13'LonesomeRoad'#13
  'FalloutNV.Hardcoded.keep.this.with.the.exe.and.otherwise.ignore.it.I.really.mean.it.dat';
	// Other FalloutNV DLC can be merged, though it may not be a great idea.
  debug = true; // debug messages

var
  slMerge, slMasters, slFails, slSelectedFiles, slMgfMasters, slFormIDs, slCopiedFiles: TStringList;
  mm: integer;
  atd, amd, vd, renumber, nddeleted, SkipProcess, skipnavdata, twopasses, preservePlugins, mergeNavdata, mergeUpward, updateOnly, clean: boolean;
  mgf: IInterface;

//=========================================================================
// CopyAssets: copies assets in filename specific directories
procedure CopyAssets(s: string; fn: string; b: boolean; renamedOnly: boolean; d: string);
var
  info, info2: TSearchRec;
  src, dst, old, new: string;
  index: integer;
begin
  SetCurrentDir(s);
	if not Assigned(slCopiedFiles) then
		slCopiedFiles := TStringList.Create;
  if FindFirst(s+'*.*', faAnyFile and faDirectory, info) = 0 then begin
    repeat
      if Lowercase(info.Name) = Lowercase(fn) then begin
        if not b then CreateDir(GetFileName(mgf));
        b := true;
        AddMessage('        Copying assets from directory "'+Copy(s, Pos('\Data', s) + 1, Length(s))+info.Name+'"');
        // copy contents of found directory
        if FindFirst(s+info.Name+'\'+'*.*', faAnyFile and faDirectory, info2) = 0 then begin
          repeat
            if Length(info2.Name) > 8 then begin
              src := info.Name+'\'+info2.name;
              if mergeUpward or renumber then begin
                index := slFormIDs.IndexOf(Copy(info2.name, 1, 8));
                if (index = -1) then begin
                  if not renamedOnly and (slCopiedFiles.IndexOf(s+src)=-1) then begin
										if debug then
											AddMessage('            Copying asset "'+src+'" to "'+dst+'"');
										dst := GetFileName(mgf)+'\'+info2.Name;
										CopyFile(PChar(s + src), PChar(s + dst), True);
									end;
                end
                else begin
                  old := slFormIDs[index];
                  new := '00' + Copy(IntToHex64(Integer(slFormIDs.Objects[index]), 8), 3, 6);
                  dst := GetFileName(mgf)+'\'+StringReplace(Lowercase(info2.name), Lowercase(old), new, [rfReplaceAll]);
                  CopyFile(PChar(s + src), PChar(s + dst), True);
                  if debug then AddMessage('            Copying asset "'+src+'" to "'+dst+'"');
									slCopiedFiles.Add(s + src);
                end;
              end
              else begin
                dst := GetFileName(mgf)+'\'+info2.name;
                CopyFile(PChar(s + src), PChar(s + dst), True);
                if debug then AddMessage('            Copying asset "'+src+'" to "'+dst+'"');
              end;
            end;
          until FindNext(info2) <> 0;
        end;
        Break;
      end;
    until FindNext(info) <> 0;
  end;
end;

//=========================================================================
// CopyVoiceAssets: copies voice assets in filename specific directories
procedure CopyVoiceAssets(s: string; fn: string; b: boolean; renamedOnly: boolean; d: string);
var
  info, info2, info3: TSearchRec;
  src, dst, old, new: string;
  index: integer;
begin
  SetCurrentDir(s);
	if not Assigned(slCopiedFiles) then
		slCopiedFiles := TStringList.Create;
  if FindFirst(s+'*.*', faAnyFile and faDirectory, info) = 0 then begin
    repeat
      if Lowercase(info.Name) = Lowercase(fn) then begin
        if not b then CreateDir(GetFileName(mgf));
        b := true;
        AddMessage('        Copying voice assets from directory "'+Copy(s, Pos('\Data', s) + 1, Length(s))+info.Name+'"');
        // copy subfolders of found directory
        if FindFirst(s+info.Name+'\'+'*', faAnyFile and faDirectory, info2) = 0 then begin
          repeat
            if ((info2.Attr and faDirectory) = faDirectory) and (Pos('.', info2.Name) <> 1) then begin
              SetCurrentDir(s+GetFileName(mgf)+'\');
              CreateDir(info2.Name);
              // copy contents of subdirectory into new directory
              if FindFirst(s+info.Name+'\'+info2.Name+'\'+'*.*', faAnyFile and faDirectory, info3) = 0 then begin
                repeat
                  if Length(info3.Name) > 8 then begin
                    src := info.Name+'\'+info2.name+'\'+info3.Name;
                    if mergeUpward or renumber then begin
                      index := slFormIDs.IndexOf(Copy(info3.name, Pos('_0', info3.Name)+1, 8));
                      if (index = -1) then begin
                        if not renamedOnly and (slCopiedFiles.IndexOf(s + src)=-1) then begin
													if debug then
														AddMessage('            Copying asset "'+src+'" to "'+dst+'"');
													dst := GetFileName(mgf)+'\'+info2.Name+'\'+info3.name;
													CopyFile(PChar(s + src), PChar(s + dst), True);
												end;
                      end
                      else begin
                        old := slFormIDs[index];
                        new := '00' + Copy(IntToHex64(Integer(slFormIDs.Objects[index]), 8), 3, 6);
                        dst := GetFileName(mgf)+'\'+info2.Name+'\'+StringReplace(Lowercase(info3.name), Lowercase(old), new, [rfReplaceAll]);
                        CopyFile(PChar(s + src), PChar(s + dst), True);
                        if debug then AddMessage('            Copying asset "'+src+'" to "'+dst+'"');
												slCopiedFiles.Add(s + src);
                      end;
                    end
                    else begin
                      dst := GetFileName(mgf)+'\'+info2.Name+'\'+info3.name;
                      CopyFile(PChar(s + src), PChar(s + dst), True);
                      if debug then AddMessage('            Copying asset "'+src+'" to "'+dst+'"');
                    end;
                  end;
                until FindNext(info3) <> 0;
              end;
            end;
          until FindNext(info2) <> 0;
        end;
        Break;
      end;
    until FindNext(info) <> 0;
  end;
end;

//=========================================================================
// CopyElement: copies an element to the merged file
procedure CopyElement(e: IInterface);
var
  cr: IInterface;
begin
  // correct Tamriel camera data
  if (geev(e, 'EDID') = 'Tamriel') then begin
    Remove(ElementByPath(e, 'MNAM'));
    Add(e, 'MNAM', True);
    seev(e, 'MNAM\Cell Coordinates\NW Cell\X', '-30');
    seev(e, 'MNAM\Cell Coordinates\NW Cell\Y', '15');
    seev(e, 'MNAM\Cell Coordinates\SE Cell\X', '40');
    seev(e, 'MNAM\Cell Coordinates\SE Cell\Y', '-40');
    seev(e, 'MNAM\Cell Coordinates\SE Cell\Y', '-40');
    seev(e, 'MNAM\Camera Data\Min Height', '50000');
    seev(e, 'MNAM\Camera Data\Max Height', '80000');
    seev(e, 'MNAM\Camera Data\Initial Pitch', '50');
  end;
  
  // skip NAVM/NAVI records if skipnavdata is true
  if skipnavdata then
    if (signature(e) = 'NAVM') or (signature(e) = 'NAVI') then begin
      nddeleted := true;
      exit;
    end;
  
  // attempt to copy record to merged file, alert user on exception
  try
    cr := wbCopyElementToFile(e, mgf, False, True);
    if debug then AddMessage('        Copying '+SmallName(e));
  except
    on x: Exception do begin
      AddMessage('        Failed to copy '+SmallName(e)+'	{'+x.Message+'}');
      slFails.Add(Name(e)+' from file '+GetFileName(GetFile(e)));
    end;
  end;
end;

//=========================================================================
// MergeByRecords: merges by copying records
procedure MergeByRecords(g: IInterface);
var
  i: integer;
  e: IInterface;
begin
  for i := 0 to RecordCount(g) - 1 do begin
    e := RecordByIndex(g, i);
    if Signature(e) = 'TES4' then Continue;
    CopyElement(e);
  end;
end;

//=========================================================================
// MergeIntelligently: merges by copying records, skipping records in group records
procedure MergeIntelligently(g: IInterface);
var
  i: integer;
  e: IInterface;
begin
  for i := 0 to ElementCount(g) - 1 do begin
    e := ElementByIndex(g, i);
    if Signature(e) = 'TES4' then Continue;
    if Signature(e) = 'GRUP' then begin
      if Pos('GRUP Cell', Name(e)) = 1 then CopyElement(e) else 
      if Pos('GRUP Exterior Cell', Name(e)) = 1 then CopyElement(e) 
      else MergeIntelligently(e);
    end
    else CopyElement(e);
  end;
end;

//=========================================================================
// MergeByGroups: merges by copying entire group records
procedure MergeByGroups(g: IInterface);
var
  i: integer;
  e: IInterface;
begin
  for i := 0 to ElementCount(g) - 1 do begin
    e := ElementByIndex(g, i);
    if Signature(e) = 'TES4' then Continue;
    CopyElement(e);
  end;
end;

//=========================================================================
// MergeOneNavdata: merges NAVI records rather than copy them

	// scan a NVMI array for a signature
	function FindNVMIbyFormID(d: IInterface; e: IInterface): IInterface;
	var
	  i: Integer;
	  f: Integer;
	begin
	  f := formID(e); 
	  for i := 0 to ElementCount(d) do
	    if formID(ElementByName(ElementByIndex(e, i), 'Navigation Mesh') = f then begin
		  Result := ElementByIndex(e, i);
		  Exit;
		end;
	end;

	// scan a NVCI array for a signature
	function FindNVCIbyFormID(d: IInterface; e: IInterface): IInterface;
	var
	  i: Integer;
	  f: Integer;
	begin
	  f := formID(e); 
	  for i := 0 to ElementCount(d) do
	    if formID(ElementByName(ElementByIndex(e, i), 'Unknown') = f then begin
		  Result := ElementByIndex(e, i);
		  Exit;
		end;
	end;

procedure MergeOneNavdata(f: IInterface);
const
  NaviPath = 'Navigation Mesh Info Map\00014B92';
  NvmiPath = 'Navigation Map Infos';
  NvciPath = 'Unknown';
var
  i: integer;
  e: IInterface;
  n: IInterface;
  d: IInterface;
  s: IInterface;
begin
  n := ElementByPath(f, NaviPath);
  if not Assigned(d) then Exit;
  
  d := ElementByPath(mgf, NaviPath);
  if not Assigned(d) then begin
	CopyElement(n);
	Exit;
  end;

  // NVMI array
  d := ElementByPath(mgf, NaviPath+'\'+NvmiPath);
  n := ElementByPath(f, NaviPath+'\'+NvmiPath);
  for i := 0 to ElementCount(n) - 1 do begin
    e := ElementByIndex(g, i);
    if Signature(e) = 'TES4' then Continue;
	if Assigned(d) then begin
      s := FindNVMIbyFormID(d, e);
      if Assigned(s) then  // remove the overriden version
	    RemoveElement(d, s);
      AddElement(d, e);
	end else begin
      CopyElement(e);
      d := ElementByPath(mgf, NaviPath+'\'+NvmiPath);
	end;
  end;

   // NVCI array
  d := ElementByPath(mgf, NaviPath+'\'+NvciPath);
  n := ElementByPath(f, NaviPath+'\'+NvciPath);
  for i := 0 to ElementCount(n) - 1 do begin
    e := ElementByIndex(g, i);
    if Signature(e) = 'TES4' then Continue;
	if Assigned(d) then  // remove the overriden version
		AddElement(d, e)
	else begin
		CopyElement(e);
		d := ElementByPath(mgf, NaviPath+'\'+NvciPath);
	end;
  end;
end;

//=========================================================================
// FileSelectM: File selection window for merging
function FileSelectM(lbl: string; upward: boolean): IInterface;
var
  frm: TForm;
  cmbFiles: TComboBox;
  btnOk, btnCancel: TButton;
  lbl01: TLabel;
  i, j, lo, flo, llo: integer;
  s: string;
  f: IInterface;
begin
  frm := TForm.Create(frm);
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
    if not upward then cmbFiles.Items.Add('-- CREATE NEW FILE --');
    cmbFiles.Top := 33 + lbl01.Height;
    cmbFiles.Left := 8;
    cmbFiles.Width := 200;
    llo := 0;
    flo := 255;
		
    if upward or not twopasses then begin
			if upward then begin
			  flo := 255;
				for j := 0 to slMerge.Count - 1 do 
					if flo > Integer(slMerge.Objects[j]) then 
						flo := Integer(slMerge.Objects[j]);
			end 
			else
				for j := 0 to slMerge.Count - 1 do 
					if llo < Integer(slMerge.Objects[j]) then 
						llo := Integer(slMerge.Objects[j]);
      for i := 0 to FileCount - 1 do begin
        s := GetFileName(FileByIndex(i));
        if Pos(s, bethesdaFiles) > 0 then Continue;
        if slMerge.IndexOf(s) > -1 then Continue;
				lo := GetLoadOrder(FileByIndex(i));
				if debug then
					AddMessage('	S	:	'+'"'+s+'"'+' Upward = '+IntToStr(Ord(upward))+' flo= '+IntToStr(flo)+' lo = '+IntToStr(lo));
				if upward and lo > flo then 
					Continue
				else
				if not upward and lo < llo then 
					Continue;
        cmbFiles.Items.Add(s);
      end;
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
        Result := f;
      end
      else begin
        for i := 0 to FileCount - 1 do
          if SameText(cmbFiles.Items[cmbFiles.ItemIndex], GetFileName(FileByIndex(i))) then begin
            Result := FileByIndex(i);
            Exit;
          end;
				AddMessage('The script couldn''t find the file you entered.');
				Result := FileSelectM(lbl, upward);
      end;
    end;
  finally
    frm.Free;
  end;
end;

//=========================================================================
// OptionsForm: Provides user with options for merging
procedure OptionsForm;
var
  frm: TForm;
  btnOk, btnCancel, btnFocus: TButton;
  cb: TGroupBox;
  cbArray: Array[0..254] of TCheckBox;
  cb1, cb2, cb3, cb4, cb5, cb6, cbRenumber: TCheckBox;
  lbl1, lbl2: TLabel;
  rg, rg2: TRadioGroup;
  rb1, rb2, rb3, rb4, rb5, rb6: TRadioButton;
  pnl: TPanel;
  sb: TScrollBox;
  i, j, k, height, m, more: integer;
  holder: TObject;
  masters, e, f: IInterface;
  s: string;
begin
  more := 20;
  frm := TForm.Create(nil);
  try
    frm.Caption := 'Merge Plugins';
    frm.Width := 415;
    frm.Position := poScreenCenter;
    for i := 0 to FileCount - 1 do begin
      s := GetFileName(FileByLoadOrder(i));
      if Pos(s, bethesdaFiles) > 0 then Continue;
      Inc(m);
    end;
    height := m*25 + 240 + 60 + more;
    if height > (Screen.Height - 100) then begin
      frm.Height := Screen.Height - 100;
      sb := TScrollBox.Create(frm);
      sb.Parent := frm;
      sb.Height := Screen.Height - 290;
      sb.Align := alTop;
      holder := sb;
    end
    else begin
      frm.Height := height;
      holder := frm;
    end;

    lbl1 := TLabel.Create(holder);
    lbl1.Parent := holder;
    lbl1.Top := 8;
    lbl1.Left := 8;
    lbl1.AutoSize := False;
    lbl1.Wordwrap := True;
    lbl1.Width := 300;
    lbl1.Height := 50;
    lbl1.Caption := 'Select the plugins you want to merge.';
    
    for i := 0 to FileCount - 1 do begin
      s := GetFileName(FileByIndex(i));
      if (Pos(s, bethesdaFiles) > 0) or (s = '') then Continue;
      j := 25 * k;
      Inc(k);
      cbArray[i] := TCheckBox.Create(holder);
      cbArray[i].Parent := holder;
      cbArray[i].Left := 24;
      cbArray[i].Top := 40 + j;
      cbArray[i].Caption := '  [' + IntToHex(i + 1, 2) + ']  ' + s;
      cbArray[i].Width := 300;
      if (slSelectedFiles.IndexOf(s) > - 1) then cbArray[i].Checked := True;
    end;
    
    if holder = sb then begin
      lbl2 := TLabel.Create(holder);
      lbl2.Parent := holder;
      lbl2.Top := j + 60;
    end;
    
    pnl := TPanel.Create(frm);
    pnl.Parent := frm;
    pnl.BevelOuter := bvNone;
    pnl.Align := alBottom;
    pnl.Height := 190 + 60 + more;
    
    rg := TRadioGroup.Create(frm);
    rg.Parent := pnl;
    rg.Left := 16;
    rg.Height := 60;
    rg.Top := 16;
    rg.Width := 372;
    rg.Caption := 'Merge Method';
    rg.ClientHeight := 45;
    rg.ClientWidth := 368;
    
    rb1 := TRadioButton.Create(rg);
    rb1.Parent := rg;
    rb1.Left := 26;
    rb1.Top := 18;
    rb1.Caption := 'Copy records';
    rb1.Width := 80;
    
    rb2 := TRadioButton.Create(rg);
    rb2.Parent := rg;
    rb2.Left := rb1.Left + rb1.Width + 30;
    rb2.Top := rb1.Top;
    rb2.Caption := 'Copy intelligently';
    rb2.Width := 100;
    rb2.Checked := True;
    
    rb3 := TRadioButton.Create(rg);
    rb3.Parent := rg;
    rb3.Left := rb2.Left + rb2.Width + 30;
    rb3.Top := rb1.Top;
    rb3.Caption := 'Copy groups';
    rb3.Width := 80;
    
    rg2 := TRadioGroup.Create(frm);
    rg2.Parent := pnl;
    rg2.Left := 16;
    rg2.Height := 60;
    rg2.Top := rg.Top + rg.Height + 1;
    rg2.Width := 372;
    rg2.Caption := 'Merge Action';
    rg2.ClientHeight := 45;
    rg2.ClientWidth := 368;
    
    rb4 := TRadioButton.Create(rg);
    rb4.Parent := rg2;
    rb4.Left := 26;
    rb4.Top := 18;
    rb4.Caption := 'Merge';
    rb4.Width := 80;
    rb4.Checked := True;
    
    rb5 := TRadioButton.Create(rg);
    rb5.Parent := rg2;
    rb5.Left := rb1.Left + rb1.Width + 30;
    rb5.Top := rb1.Top;
    rb5.Caption := 'Inject';
    rb5.Width := 100;
    
    rb6 := TRadioButton.Create(rg);
    rb6.Parent := rg2;
    rb6.Left := rb2.Left + rb2.Width + 30;
    rb6.Top := rb1.Top;
    rb6.Caption := 'Update';
    rb6.Width := 80;
    
    cb := TGroupBox.Create(frm);
    cb.Parent := pnl;
    cb.Left := 16;
    cb.Height := 60 + more;
    cb.Top := rg2.Top + rg2.Height + 1;
    cb.Width := 372;
    cb.Caption := 'Advanced Merge Settings';
    cb.ClientHeight := 50 + more;
    cb.ClientWidth := 370;
    
    cb1 := TCheckBox.Create(cb);
    cb1.Parent := cb;
    cb1.Left := 16;
    cb1.Top := 20;
    cb1.Caption := 'Renumber FormIDs';
    cb1.Width := 110;
    cb1.State := cbChecked;
    
    cb2 := TCheckBox.Create(cb);
    cb2.Parent := cb;
    cb2.Left := cb1.Left + cb1.Width + 20;
    cb2.Top := cb1.Top;
    cb2.Caption := 'Two-pass Copying';
    cb2.Width := 110;
    cb2.State := cbChecked;
    
    cb3 := TCheckBox.Create(cb);
    cb3.Parent := cb;
    cb3.Left := cb2.Left + cb2.Width + 20;
    cb3.Top := cb1.Top;
    cb3.Caption := 'Skip Navdata';
    cb3.Width := 80;
    
    cb4 := TCheckBox.Create(cb);
    cb4.Parent := cb;
    cb4.Left := cb1.Left;
    cb4.Top := cb1.Top + more;
    cb4.Caption := 'Preserve Plugins';
    cb4.Width := 110;
    cb4.State := cbChecked;
	
    cb5 := TCheckBox.Create(cb);
    cb5.Parent := cb;
    cb5.Left := cb4.Left + cb4.width + 20;
    cb5.Top := cb1.Top + more;
    cb5.Caption := 'Merge Navdata';
    cb5.Width := 110;
    cb5.State := cbChecked;
	
    cb6 := TCheckBox.Create(cb);
    cb6.Parent := cb;
    cb6.Left := cb5.Left + cb5.width + 20;
    cb6.Top := cb1.Top + more;
    cb6.Caption := 'clean';
    cb6.Width := 110;
		
    btnOk := TButton.Create(frm);
    btnOk.Parent := pnl;
    btnOk.Caption := 'OK';
    btnOk.ModalResult := mrOk;
    btnOk.Left := 120;
    btnOk.Top := pnl.Height - 40;
    
    btnCancel := TButton.Create(frm);
    btnCancel.Parent := pnl;
    btnCancel.Caption := 'Cancel';
    btnCancel.ModalResult := mrCancel;
    btnCancel.Left := btnOk.Left + btnOk.Width + 16;
    btnCancel.Top := btnOk.Top;
    
    frm.ActiveControl := btnOk;
    
    if frm.ShowModal = mrOk then begin
      for i := 0 to FileCount - 1 do begin
        f := FileByIndex(i);
        s := GetFileName(f);
        if Pos(s, bethesdaFiles) > 0 then Continue;        
        
        if cbArray[i].State = cbChecked then begin
          slMerge.AddObject(s, TObject(GetLoadOrder(f)));
          AddMessage('Merging '+s);
          slMasters.Add(s);
          // add masters from files to be merged
          masters := ElementByName(ElementByIndex(f, 0), 'Master Files');
          for j := 0 to ElementCount(masters) - 1 do begin
            e := ElementByIndex(masters, j);
            s := GetElementNativeValues(e, 'MAST');
            slMasters.Add(s);
          end;
        end;
        if rb1.Checked then mm := 0 else
        if rb2.Checked then mm := 1 else
        if rb3.Checked then mm := 2;
        if rb4.Checked then begin mergeUpward := False; updateOnly := false; end else
        if rb5.Checked then begin mergeUpward := true;  updateOnly := false; end else
        if rb6.Checked then begin mergeUpward := true;  updateOnly := true;  end;
        renumber				:= ((cb1.State = cbChecked) or mergeUpward) and not updateOnly;
        twopasses				:= (cb2.State = cbChecked) and not mergeUpward and not updateOnly;
        skipnavdata			:= (cb3.State = cbChecked) and not updateOnly;
        preservePlugins	:= (cb4.State = cbChecked) and not updateOnly;
        mergeNavdata		:= (cb5.State = cbChecked) and not updateOnly;
        clean						:= (cb6.State = cbChecked) or updateOnly;
      end;
    end;
  finally
    frm.Free;
  end;
end;

//=========================================================================
// Initialize
function Initialize: integer;
begin
  // welcome messages
  AddMessage(#13#10#13#10);
  AddMessage('-----------------------------------------------------------------------------');
  AddMessage('Merge plugins '+vs+': Merges files.  For use with TES5Edit and FNVEdit.');
  AddMessage('-----------------------------------------------------------------------------');
 
  // stringlist creation
  slSelectedFiles := TStringList.Create;
  slMerge := TStringList.Create;
  slFails := TStringList.Create;
  slMasters := TStringList.Create;
  slMasters.Sorted := True;
  slMasters.Duplicates := dupIgnore;
  slMgfMasters := TStringList.Create;
  
  // process only file elements
  try 
    ScriptProcessElements := [etFile];
  except on Exception do
    SkipProcess := true;
  end;
end;

//=========================================================================
// Process: put files to be merged into stringlists
function Process(f: IInterface): integer;
var
  i: integer;
  s: string;
begin
  if SkipProcess then 
    exit;
    
  if (ElementType(f) = etMainRecord) then 
    exit;
    
  s := GetFileName(f);
  slSelectedFiles.AddObject(s, TObject(GetLoadOrder(f)));
end;

//=========================================================================
// Finalize: this is where all the good stuff happens
function Finalize: integer;
var
  i, j, k, RC, prc: integer;
  f, e, m, group, masters, master: IInterface;
  merge, s, desc, udir, cdir: string;
  HighestFormID, OldFormID, NewFormID, BaseFormID: Int64;
  id: Int64;
  self, done, hasDuplicates: boolean;
  Records: array [0..$FFFFFF] of IInterface;
begin
  // check version
  try
    k := wbVersionNumber;
  except on Exception do
    AddMessage('The program is out of date, you must update it to use this script!'+#13#10);
  end;
  if k = 0 then begin
    slMerge.Free;
    slMasters.Free;
    exit;
  end;
  
  OptionsForm;
  
  // terminate script if mergelist contains less than one file
  if slMerge.Count < 1 then begin
    AddMessage(#13#10+'Select at least 1 file to merge!  Terminating script.'+#13#10);
    slMerge.Free;
    slMasters.Free;
    exit;
  end;
  
  // Check for Errors
  AddMessage('    Checking for errors...');
	for i := 0 to slMerge.Count - 1 do 
		if CheckForErrors(0, FileByLoadOrder(Integer(slMerge.Objects[i]))) then
			exit;
  
  // Check for Duplicated EditorID
  AddMessage('    Checking for editor IDs...');
	slFormIDs := TStringList.Create;
	try
		slFormIDs.Sorted := true;
		for i := 0 to slMerge.Count - 1 do begin
			f := FileByLoadOrder(Integer(slMerge.Objects[i]));
			RC := RecordCount(f) - 1;
			AddMessage('    Checking for editor IDs in file '+GetFileName(f));

			// create EditorID array for all files
			for j := 0 to RC do begin
			  e := RecordByIndex(f, j);
				s := EditorID(e);
				if (s>'') and (Equals(MasterOrSelf(e), e)) then begin
					if false and debug then AddMessage('    Checking for editor IDs in file '+GetFileName(f)+'	'+s);
					if slFormIDs.IndexOf(s)>-1 then begin
						AddMessage('		--> Warning <--	Duplicate EditorID '+s);
						hasDuplicates := True;
					end
					else
						slFormIDs.AddObject(s, e);
				end;
			end;
		end;
		if hasDuplicates then begin
			if mergeUpward then begin
				AddMessage('    Duplicate EditorID found. Terminating script.'+#13#10);
				Exit;
			end;
			if (Application.MessageBox('Continue ?', 'Duplicates found', MB_OKCANCEL) = 2) then begin
				AddMessage('    Duplicate EditorID found. User terminated script.'+#13#10);
				Exit;
			end;
		end;
	finally
		slFormIDs.Free;
	end;

  // create or identify merge file
  Done := False;
  mgf := nil;
  AddMessage(#13#10+'Preparing merged file...');
  if mergeUpward then
		mgf := FileSelectM('Choose the file you want to merge into below.', true)
	else
		mgf := FileSelectM('Choose the file you want to merge into below, or '+#13#10+'choose -- CREATE NEW FILE -- to create a new one.', false);

  // merge file confirmation or termination
  if not Assigned(mgf) then begin
    AddMessage('    No merge file assigned.  Terminating script.'+#13#10);
    exit;
  end;
  AddMessage('    Script is using ' + GetFileName(mgf) + ' as the merge file.');
  
  // add masters
  if mergeUpward then begin
		AddMessage('    Adding master to merge files...');
		for i := 0 to slMerge.Count-1 do begin
			f := FileByLoadOrder(Integer(slMerge.Objects[i]));
			AddMessage('		'+GetFileName(f)+'	'+GetFileName(mgf));
			AddMasterIfMissing(f, GetFileName(mgf));
		end;
	end
	else begin
		AddMessage('    Adding masters to merge file...');
		AddMastersToFile(mgf, slMasters, true);
	end;
	Application.ProcessMessages;
	
  // renumber forms in files with a master EditorID
  if mergeUpward then begin
    AddMessage(#13#10+'Renumbering FormIDs with identical EditorID...');
    
    // form id renumbering for each file EXCEPT the first so you can start with a previous merged file possibly edited manually.
    for i := 0 to slMerge.Count - 1 do begin
      f := FileByLoadOrder(Integer(slMerge.Objects[i]));
      RC := RecordCount(f) - 1;
      AddMessage('    Renumbering records in file '+GetFileName(f));
      slFormIDs := TStringList.Create;
      atd := false;
      amd := false;
      vd := false;
      
      // create records array for file because the indexed order of records changes as we alter their formIDs
      for j := 0 to RC do
        Records[j] := RecordByIndex(f, j);
      
      // renumber the records in the file
      for j := 0 to RC do begin
        e := Records[j];
        if SameText(Signature(e), 'TES4') then Continue;
        if not Equals(MasterOrSelf(e), e) then Continue;
        if EditorID(e)='' then Continue;
        
				m := RecordByEditorID(mgf, EditorID(e));
				if not Assigned(m) then Continue;

        // keep previous ID if record already exists in the merge file
				s := HexFormID(e);
				OldFormID := StrToInt64('$' + s);
				s := HexFormID(m);
				NewFormID := StrToInt64('$' + s);
				
				// print log message first, then change references, then change form
				if debug then 
					AddMessage(Format('        Changing FormID from [%s] to [%s] on %s', 
					[IntToHex64(OldFormID, 8), IntToHex64(NewFormID, 8), SmallName(e)]));
				prc := 0;
				while ReferencedByCount(e) > 0 do begin
					if prc = ReferencedByCount(e) then exit;
					prc := ReferencedByCount(e);
					try 
						CompareExchangeFormID(ReferencedByIndex(e, 0), OldFormID, NewFormID);
					 except 
						AddMessage(Format('        Referencing FormID from [%s] to [%s] on %s', 
						[IntToHex64(OldFormID, 8), IntToHex64(NewFormID, 8), SmallName(e)]));
						raise; 
					 end;
				end;
				try
					SetLoadOrderFormID(e, NewFormID);
				except 
					AddMessage(Format('        Changing FormID from [%s] to [%s] on %s', 
					[IntToHex64(OldFormID, 8), IntToHex64(NewFormID, 8), SmallName(e)]));
					raise; 
				end;
				slFormIDs.AddObject(s, TObject(NewFormID));
      end;
      
			if not updateOnly then begin
				// copy File/FormID specific assets
				cdir := wbDataPath + '\Textures\Actors\Character\FacegenData\facetint\';
				CopyAssets(cdir, slMerge[i], atd, true, ''); // copy actor textures
				cdir := wbDataPath + '\Meshes\actors\character\facegendata\facegeom\';
				CopyAssets(cdir, slMerge[i], amd, true, ''); // copy actor meshes
				cdir := wbDataPath + '\Sound\Voice\';
				CopyVoiceAssets(cdir, slMerge[i], vd, true, ''); // copy voice assets
      end;
			
      // free form ID stringlist
      slFormIDs.Free;
    end;
  end;
	
  // renumber forms in files to be merged
  if renumber then begin
    AddMessage(#13#10+'Renumbering FormIDs before merging...');
    HighestFormID := 0;
    NewFormID := 0;
    BaseFormID := 0;
    
    // find the ideal NewFormID to start at
    for i := 0 to slMerge.Count - 1 do begin
      f := FileByLoadOrder(Integer(slMerge.Objects[i]));
      for j := 0 to RecordCount(f) - 1 do begin
        e := RecordByIndex(f, j);
        if not Equals(e, MasterOrSelf(e)) then Continue;
				k := FormID(e) and $00FFFFFF;
				if k > HighestFormID then HighestFormID := k;
      end;
    end;
    
    // check merge file for a higher form ID
    for i := 0 to RecordCount(mgf) - 1 do begin
      e := RecordByIndex(mgf, i);
      if not Equals(e, MasterOrSelf(e)) then Continue;
			k := FormID(e) and $00FFFFFF;
      if k > HighestFormID then HighestFormID := k;
    end;
    
		if debug then AddMessage('Highest formID is '+IntToHex(HighestFormID, 8));
		
    for i := 0 to slMerge.Count - 1 do begin
      f := FileByLoadOrder(Integer(slMerge.Objects[i]));
      RC := RecordCount(f) - 1;
      AddMessage('    Renumbering records in file '+GetFileName(f));
      slFormIDs := TStringList.Create;
      atd := false;
      amd := false;
      vd := false;
      
      // create records array for file because the indexed order of records changes as we alter their formIDs
      for j := 0 to RC do
        Records[j] := RecordByIndex(f, j);
      
      if mergeUpward then begin
        // initialize NewFormID based on HighestFormID found
        if BaseFormID = 0 then BaseFormID := HighestFormID + 16;
        // set newformID to use the load order of the file currently being processed.
        NewFormID := StrToInt64('$' + IntToHex(GetLoadOrder(mgf), 2) + IntToHex(BaseFormID, 6));
			end
			else if (i = 0) then
        NewFormID := StrToInt64('$' + IntToHex(Integer(slMerge.Objects[i]), 2) + IntToHex(OldFormID, 6))
      else begin
        // initialize NewFormID based on HighestFormID found
        if BaseFormID = 0 then BaseFormID := HighestFormID + 16;
        // set newformID to use the load order of the file currently being processed.
        NewFormID := StrToInt64('$' + IntToHex(Integer(slMerge.Objects[i]), 2) + IntToHex(BaseFormID, 6));
      end;
      
      // renumber the records in the file
      for j := 0 to RC do begin
        e := Records[j];
        if SameText(Signature(e), 'TES4') then Continue;
        
        // continue if formIDs are identical or if record is override
        s := HexFormID(e);
        OldFormID := StrToInt64('$' + s);
        s := '00' + Copy(s, 3, 6);
        if NewFormID = OldFormID then Continue;
        self := Equals(MasterOrSelf(e), e);
        if not self then begin
          if debug then AddMessage('        Skipping renumbering '+SmallName(e)+', it''s an override record.');
          slFormIDs.AddObject(s, TObject(OldFormID));
          Continue;
        end;
        
        // print log message first, then change references, then change form
        if debug then 
          AddMessage(Format('        Changing FormID from [%s] to [%s] on %s', 
          [IntToHex64(OldFormID, 8), IntToHex64(NewFormID, 8), SmallName(e)]));
        prc := 0;
        while ReferencedByCount(e) > 0 do begin
          if prc = ReferencedByCount(e) then exit;
          prc := ReferencedByCount(e);
          try 
            CompareExchangeFormID(ReferencedByIndex(e, 0), OldFormID, NewFormID);
           except 
            AddMessage(Format('        Referencing FormID from [%s] to [%s] on %s', 
            [IntToHex64(OldFormID, 8), IntToHex64(NewFormID, 8), SmallName(e)]));
            raise; 
           end;
        end;
         try
          SetLoadOrderFormID(e, NewFormID);
         except 
          AddMessage(Format('        Changing FormID from [%s] to [%s] on %s', 
          [IntToHex64(OldFormID, 8), IntToHex64(NewFormID, 8), SmallName(e)]));
          raise; 
         end;
        slFormIDs.AddObject(s, TObject(NewFormID));
        
        // increment formid
        Inc(BaseFormID);
        Inc(NewFormID);
      end;
      
      // copy File/FormID specific assets
      cdir := wbDataPath + '\Textures\Actors\Character\FacegenData\facetint\';
      CopyAssets(cdir, slMerge[i], atd, false, ''); // copy actor textures
      cdir := wbDataPath + '\Meshes\actors\character\facegendata\facegeom\';
      CopyAssets(cdir, slMerge[i], amd, false, ''); // copy actor meshes
      cdir := wbDataPath + '\Sound\Voice\';
      CopyVoiceAssets(cdir, slMerge[i], vd, false, ''); // copy voice assets
      
      // free form ID stringlist
      slFormIDs.Free;
    end;
  end
  else if not updateOnly then begin
    // copy File specific assets
    AddMessage(#13#10+'Copying Assets...');
    for i := 0 to slMerge.Count - 1 do begin
      atd := false;
      amd := false;
      vd := false;
      cdir := wbDataPath + '\Textures\Actors\Character\FacegenData\facetint\';
      CopyAssets(cdir, slMerge[i], atd), false, ''; // copy actor textures
      cdir := wbDataPath + '\Meshes\actors\character\facegendata\facegeom\';
      CopyAssets(cdir, slMerge[i], amd, false, ''); // copy actor meshes
      cdir := wbDataPath + '\Sound\Voice\';
      CopyVoiceAssets(cdir, slMerge[i], vd, false, ''); // copy voice assets
    end;
  end;

	if not updateOnly then begin
		// the merging process
		AddMessage(#13#10+'Beginning merging process...');
		for i := slMerge.Count - 1 downto 0 do begin
			f := FileByLoadOrder(Integer(slMerge.Objects[i]));
			AddMessage('    Copying records from '+GetFileName(f));
			if mm = 0 then MergeByRecords(f) else 
			if mm = 1 then MergeIntelligently(f) else 
			if mm = 2 then MergeByGroups(f);
		end;
	end;
	
  // removing masters
  AddMessage(#13#10+'Removing unnecessary masters...');
  masters := ElementByName(ElementByIndex(mgf, 0), 'Master Files');
  for i := ElementCount(masters) - 1 downto 0 do begin
    e := ElementByIndex(masters, i);
    s := GetElementNativeValues(e, 'MAST');
    if SameText(s, '') then Continue;
    for j := 0 to slMerge.Count - 1 do begin
      if SameText(slMerge[j], s) then begin
        AddMessage('    Removing master '+s);
        RemoveElement(masters, e);
      end;
    end;
  end;
  
	if not updateOnly then begin
		// creating description
		desc := 'Merged Plugin: ';
		s := nil;
		s := geev(ElementByIndex(mgf, 0), 'SNAM');
		if not Assigned(s) then
			Add(ElementByIndex(mgf, 0), 'SNAM', True)
		else if Pos('Merged Plugin', s) > 0 then 
			desc := s;
		for i := 0 to slMerge.Count - 1 do begin
			s := geev(ElementByIndex(FileByLoadOrder(Integer(slMerge.Objects[i])), 0), 'SNAM');
			if Pos('Merged Plugin', s) > 0 then
				desc := desc+StringReplace(s, 'Merged Plugin: ', '', [rfReplaceAll])
			else
				desc := desc+#13#10+'  '+slMerge[i];
		end;
		seev(ElementByIndex(mgf, 0), 'CNAM', 'Various Authors');
		seev(ElementByIndex(mgf, 0), 'SNAM', desc);
	end;
	
  // second pass copying
  if twopasses then begin
    // removing records for second pass copying
    AddMessage(#13#10+'Removing records for second pass...');
    for i := ElementCount(mgf) - 1 downto 1 do begin
      AddMessage('    Removing '+Name(ElementByIndex(mgf, i)));
      Remove(ElementByIndex(mgf, i));
    end;
    
    // second pass copying
    AddMessage(#13#10+'Performing second pass copying...');
    for i := slMerge.Count - 1 downto 0 do begin
      f := FileByLoadOrder(Integer(slMerge.Objects[i]));
      AddMessage('    Copying records from '+GetFileName(f));
      MergeByGroups(f);
    end;
  end;
  
  // remove NAVM/NAVI records if skipnavdata is true
  if skipnavdata then begin
    AddMessage(#13#10+'  Deleting NAVM/NAVI data...');
    RC := RecordCount(mgf) - 1;
    for i := 0 to RC do
      Records[i] := RecordByIndex(mgf, i);
    for i := 0 to RC do begin
        e := Records[i];
        if (signature(e) = 'NAVM') or (signature(e) = 'NAVI') then begin
          AddMessage('    Removed '+Name(e));
          Remove(e);
          nddeleted := true;
        end;
    end;
  end;

  // merge NAVM/NAVI records if mergenavdata is true (Fallout NV only, due to NAVI record definition changes)
  if (wbGameMode = gmFNV) and mergeNavdata then begin
    AddMessage(#13#10+'  Merging NAVI data...');
    for i := 0 to slMerge.Count - 1 do begin
      f := FileByLoadOrder(Integer(slMerge.Objects[i]));
      AddMessage('    Copying records from '+GetFileName(f));
      MergeOneNavdata(f);
    end;
  end;

  // unmodify plugins if preservePlugins is true
  if preservePlugins then begin
    AddMessage(#13#10+'  Unmodifying plugins...');
    for i := slMerge.Count - 1 downto 0 do begin
      f := FileByLoadOrder(Integer(slMerge.Objects[i]));
      AddMessage('    Unmodifying '+GetFileName(f));
      ClearElementState(f, esUnsaved);
    end;
  end;

  // script is done, print confirmation messages
  AddMessage(#13#10);
  AddMessage('-----------------------------------------------------------------------------');
  AddMessage('Your merged file has been created successfully.  It has '+IntToStr(RecordCount(mgf))+' records.');
  if skipnavdata and nddeleted then AddMessage('    Some NAVM/NAVI records were deleted, you may want to re-generate them in the CK!');
  // inform user about records that failed to copy
  if (slFails.Count > 0) then begin
    MessageDlg('Some records failed to copy, so your merged file is incomplete.  '
    'Please refer to the message log so you can address these records manually.  '
    '(the merged file likely will not work without these records!)', mtConfirmation, [mbOk], 0);
    AddMessage('The following records failed to copy: ');
    for i := 0 to slFails.Count - 1 do 
      AddMessage('    '+slFails[i]);
  end;
  AddMessage(#13#10);
  
  // clean stringlists
  slMerge.Free;
  slSelectedFiles.Free;
  slMasters.Free;
  slFails.Free;
  Result := -1;
  
end;


end.
