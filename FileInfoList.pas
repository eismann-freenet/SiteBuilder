{
  Copyright 2014 - 2017 eismann@5H+yXYkQHMnwtQDzJB8thVYAAIs

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
  FileInfo, Generics.Collections, Classes;

type
  TCRCType = (CRC, SFV);

  TFileInfoList = class(TObjectList<TFileInfo>)

  strict private
    class procedure AddCRCLine(List: TStringList;
      const Filename, Path, CRC: string; const Size: Integer);
    class procedure AddSFVLine(List: TStringList;
      const Filename, Path, CRC: string);

  public
    function FileSizeSum: Int64;
    procedure GenerateCRCFile(const Filename: string; const CRCType: TCRCType);

    constructor Create(const AOwnsObjects: Boolean = True);
    destructor Destroy; override;
  end;

implementation

uses
  Generics.Defaults, SysUtils, SiteEncoding, Sort, Key, FileInfoComparer;

{ TFileInfoList }

class procedure TFileInfoList.AddCRCLine(List: TStringList;
  const Filename, Path, CRC: string; const Size: Integer);
begin
  if Filename <> '' then
  begin
    if Pos(',', Filename) > 0 then
    begin
      List.Add(Format('"%s",%d,%s,%s,', [Filename, Size, CRC, Path]));
    end
    else
    begin
      List.Add(Format('%s,%d,%s,%s,', [Filename, Size, CRC, Path]));
    end;
  end;
end;

class procedure TFileInfoList.AddSFVLine(List: TStringList;
  const Filename, Path, CRC: string);
begin
  if Filename <> '' then
  begin
    List.Add(Format('%s%s %s', [Path, Filename, CRC]));
  end;
end;

constructor TFileInfoList.Create(const AOwnsObjects: Boolean);
begin
  inherited Create(TFileInfoComparer.Create, AOwnsObjects);
end;

destructor TFileInfoList.Destroy;
begin
  // The object of TFileInfoComparer is automatically destroyed.
  inherited Destroy;
end;

function TFileInfoList.FileSizeSum: Int64;
var
  FileInfo: TFileInfo;
begin
  Result := 0;
  for FileInfo in Self do
  begin
    Result := Result + FileInfo.FileSize;
  end;
end;

procedure TFileInfoList.GenerateCRCFile(const Filename: string;
  const CRCType: TCRCType);
var
  Output: TStringList;
  FileInfo: TFileInfo;
  CRCEntry: TCRC;
begin
  ForceDirectories(ExtractFilePath(Filename));

  Output := TStringList.Create;
  try
    for FileInfo in Self do
    begin
      if (CRCType = CRC) and (FileInfo.Key.KeyType = CHK) then
      begin
        AddCRCLine(Output, FileInfo.Key.Filename, PathDelim, FileInfo.CRC,
          FileInfo.FileSize);
      end
      else if (CRCType = SFV) and (FileInfo.Key.KeyType = CHK) then
      begin
        AddSFVLine(Output, FileInfo.Key.Filename, '', FileInfo.CRC);
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
            AddSFVLine(Output, CRCEntry.Filename,
              Copy(CRCEntry.Path, 2, Length(CRCEntry.Path) - 1), CRCEntry.CRC);
          end;
        end;
      end;
    end;
    Output.SaveToFile(Filename, TSiteEncoding.Encoding);
  finally
    Output.Free;
  end;
end;

end.
