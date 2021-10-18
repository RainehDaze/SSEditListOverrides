{
  List all plugins alongside any plugins that override them.
  Outputs to a file in the xEdit folder named ListOverrides.
}
unit FindPluginConflicts;

var 
  pluginOverrides: array[0..5000, 0..5000] of integer;
  // first dimension is file index (file being overridden)
  // second dimension is plugin order (file overwriting)

procedure FindOverrides(currFile: IInterface; currPluginIndex: integer);
var
  i, j, k, overrideLoadOrder: integer;
  currRecord, currOverride, overridingFile, overriddenOverrideIndex: IInterface;
  currNumOverrides: cardinal;
begin
  AddMessage('Processing ' + Name(currFile) + ' ' + IntToStr(RecordCount(currFile)));
  // iterate over all plugin records
  for i := 0 to Pred(RecordCount(currFile)) do begin
    currRecord := RecordByIndex(currFile, i);
    if i > -1 then
      currNumOverrides := OverrideCount(currRecord);
      if currNumOverrides > 0 then
        for j := 0 to Pred(currNumOverrides) do begin
          currOverride := OverrideByIndex(currRecord, j);
          overridingFile := GetFile(currOverride);
          overrideLoadOrder := GetLoadOrder(overridingFile);
          pluginOverrides[currPluginIndex, overrideLoadOrder] := 1; 
          overriddenOverrideIndex := OverrideLoadOrder+1; 
          for k := j+1 to Pred(currNumOverrides) do begin
            currOverride := OverrideByIndex(currRecord, k);
            overridingFile := GetFile(currOverride);
            overrideLoadOrder := GetLoadOrder(overridingFile);
            pluginOverrides[overriddenOverrideIndex, overrideLoadOrder] := 1; 
          end;
        end;
  end;
end;

//============================================================================

function Initialize: integer;
var
  i, j, currPluginIndex: integer;
  currFile: IInterface;
begin
  // iterate over loaded plugins
  for currPluginIndex := 0 to Pred(FileCount) do begin
    currFile := FileByIndex(currPluginIndex);
    FindOverrides(currFile, currPluginIndex);
  end;
end;

//============================================================================

function Finalize : integer;
var 
  currPluginIndex, currOverrideOrder, overrideCount : integer;
  currFile, currOverride: IInterface;
  filename : string;
  plugins : TStringList;
begin
  filename := ProgramPath + 'ListOverrides.txt';
  plugins := TStringList.Create;
  for currPluginIndex := 0 to Pred(FileCount) do begin
    currFile := FileByIndex(currPluginIndex);
    // don't print overrides of base game files:
    if currPluginIndex < 6 then
      Continue;
    // don't print where there's no overrides 
    overrideCount := 0;
    for currOverrideOrder := 0 to Pred(FileCount) do begin
      if pluginOverrides[currPluginIndex, currOverrideOrder] = 1 then
        inc(overrideCount);
    end;
    if overrideCount = 0 then
      Continue;
    plugins.Add(BaseName(currFile) + ' is overwritten by:');
    for currOverrideOrder := 0 to Pred(FileCount) do begin
      if pluginOverrides[currPluginIndex, currOverrideOrder] = 1 then
        plugins.Add(BaseName(FileByLoadOrder(currOverrideOrder)));
    end;
    plugins.Add(' ');
    plugins.Add('=====');
    plugins.Add(' ');
  end;
  AddMessage('Saving overrides to ' + filename);
  plugins.SaveToFile(filename);
  plugins.Free;
end;


end.
