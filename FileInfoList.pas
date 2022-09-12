{
  Copyright 2014 eismann@5H+yXYkQHMnwtQDzJB8thVYAAIs

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
  TFileInfoList = class(TPersistent)

  strict private
    FData: TObjectList<TFileInfo>;

  public
    procedure Add(Value: TFileInfo);
    procedure Sort;
    function FileSizeSum: Integer;
    function Count: Integer;
    function GetContent: TObjectList<TFileInfo>;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  Tools, Generics.Defaults;

{ TFileInfoList }

procedure TFileInfoList.Add(Value: TFileInfo);
begin
  FData.Add(Value);
end;

function TFileInfoList.Count: Integer;
begin
  Result := FData.Count;
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

function TFileInfoList.FileSizeSum: Integer;
var
  FileInfo: TFileInfo;
begin
  Result := 0;
  for FileInfo in FData do
  begin
    Result := Result + FileInfo.FileSize;
  end;
end;

function TFileInfoList.GetContent: TObjectList<TFileInfo>;
begin
  Result := FData;
end;

procedure TFileInfoList.Sort;
begin
  FData.Sort(TComparer<TFileInfo>.Construct( function(const L,
        R: TFileInfo): Integer begin Result := StrCmpLogicalW
        (PChar(L.FileName), PChar(R.FileName)); end));
end;

end.
