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

unit FileInfoComparer;

interface

uses
  FileInfo, Generics.Defaults;

type
  TFileInfoComparer = class(TComparer<TFileInfo>)
  public
    function Compare(const Left, Right: TFileInfo): Integer; override;
  end;

implementation

uses
  Sort, Key;

{ TFileInfoComparer }

function TFileInfoComparer.Compare(const Left, Right: TFileInfo): Integer;
begin
  if Left.Key.KeyType = Right.Key.KeyType then
  begin
    if Left.Key.KeyType = USK then
    begin
      Result := SortCompare(Left.Description, Right.Description);
    end
    else
    begin
      Result := SortCompare(Left.Key.Filename, Right.Key.Filename);
    end;
  end
  else
  begin
    if Left.Key.KeyType = USK then
    begin
      Result := -1;
    end
    else
    begin
      Result := 1;
    end;
  end;
end;

end.
