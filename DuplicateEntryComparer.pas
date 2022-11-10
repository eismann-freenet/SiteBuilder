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

unit DuplicateEntryComparer;

interface

uses
  DuplicateEntry, Generics.Defaults;

type
  TDuplicateEntryComparer = class(TComparer<TDuplicateEntry>)
  public
    function Compare(const Left, Right: TDuplicateEntry): Integer; override;
  end;

implementation

uses
  Sort;

{ TDuplicateEntryComparer }

function TDuplicateEntryComparer.Compare(const Left,
  Right: TDuplicateEntry): Integer;
begin
  Result := SortCompare(Left.Filenames, Right.Filenames);
end;

end.
