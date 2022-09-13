{
  Copyright 2014 - 2015 eismann@5H+yXYkQHMnwtQDzJB8thVYAAIs

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
}

unit FileInfoList;

interface

uses
  FileInfo, Generics.Collections, ComCtrls, Classes;

type
  TCRCType = (CRC, SFV);

  TFileInfoList = class(TPersistent)

  strict private
    FData: TObjectList<TFileInfo>;
    procedure AddCRCLine(List: TStringList; const Filename, Path, CRC: string;
      const Size: Integer);
    procedure AddSFVLine(List: TStringList; const Filename, Path, CRC: string);

  published
    property List: TObjectList<TFileInfo>read FData;

  public
    procedure Add(Value: TFileInfo);
    procedure Sort;
    function FileSizeSum: Int64;

    constructor Create;
    destructor Destroy; override;
    procedure GenerateCRCFile(const Filename: string; const CRCType: TCRCType);
  end;

implementation

uses
  Tools, Generics.Defaults, SysUtils, SiteEncoding;

{ TFileInfoList }

procedure TFileInfoList.Add(Value: TFileInfo);
begin
  FData.Add(Value);
end;

procedure TFileInfoList.AddCRCLine(List: TStringList;
  const Filename, Path, CRC: string; const Size: Integer);
var
  Line: string;
begin
  if Filename <> '' then
  begin
    if Pos(',', Filename) > 0 then
    begin
      Line := '"' + Filename + '"';
    end
    else
    begin
      Line := Filename;
    end;
    Line := Line + ',' + IntToStr(Size) + ',' + CRC + ',' + Path + ',';
    List.Add(Line);
  end;
end;

procedure TFileInfoList.AddSFVLine(List: TStringList;
  const Filename, Path, CRC: string);
begin
  if Filename <> '' then
  begin
    List.Add(Path + Filename + ' ' + CRC);
  end;
end;

constructor TFileInfoList.Create;
begin
  FData := TObjectList<TFileInfo>.Create;
end;

destructor TFileInfoList.Destroy;
begin
  FData.Free;
  inherited Destroy;
end;

function TFileInfoList.FileSizeSum: Int64;
var
  FileInfo: TFileInfo;
begin
  Result := 0;
  for FileInfo in FData do
  begin
    Result := Result + FileInfo.FileSize;
  end;
end;

procedure TFileInfoList.GenerateCRCFile(const Filename: string;
  const CRCType: TCRCType);
var
  Output: TStringList;
  FileInfo: TFileInfo;
  Path: string;
  CRCEntry: TCRC;
begin
  Path := ExtractFilePath(Filename);
  if not DirectoryExists(Path) then
  begin
    ForceDirectories(Path);
  end;

  Output := TStringList.Create;
  try
    for FileInfo in FData do
    begin
      if CRCType = CRC then
      begin
        AddCRCLine(Output, FileInfo.Filename, PathDelim, FileInfo.CRC,
          FileInfo.FileSize);
      end
      else if CRCType = SFV then
      begin
        AddSFVLine(Output, FileInfo.Filename, '', FileInfo.CRC);
      end;
      if (Length(FileInfo.ExtraCRC) > 0) then
      begin
        for CRCEntry in FileInfo.ExtraCRC do
        begin
          if CRCType = CRC then
          begin
            AddCRCLine(Output, CRCEntry.Filename, CRCEntry.Path, CRCEntry.CRC,
              CRCEntry.FileSize);
          end
          else if CRCType = SFV then
          begin
            AddSFVLine(Output, CRCEntry.Filename, Copy(CRCEntry.Path, 2,
                Length(CRCEntry.Path) - 1), CRCEntry.CRC);
          end;
        end;
      end;
    end;
    Output.SaveToFile(Filename, TSiteEncoding.Encoding);
  finally
    Output.Free;
  end;
end;

procedure TFileInfoList.Sort;
begin
  FData.Sort(TComparer<TFileInfo>.Construct( function(const L,
        R: TFileInfo): Integer begin Result := StrCmpLogicalW
        (PChar(L.Filename), PChar(R.Filename)); end));
end;

end.
