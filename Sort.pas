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

unit Sort;

interface

function SortCompare(const Text1, Text2: string): Integer;
function SortArrayAsString(const Text: string): string;

implementation

uses
  SystemCall, CSVFile, Classes;

function SortCompare(const Text1, Text2: string): Integer;
begin
  Result := StringCompare(Text1, Text2);
end;

function SortCompareList(List: TStringList; Index1, Index2: Integer): Integer;
begin
  Result := SortCompare(List[Index1], List[Index2]);
end;

function SortArrayAsString(const Text: string): string;
var
  StringList: TStringList;
begin
  StringList := TStringList.Create;
  try
    TCSVFile.Split(StringList, Text, '|');
    StringList.CustomSort(SortCompareList);
    StringList.Delimiter := '|';
    Result := StringList.DelimitedText;
  finally
    StringList.Free;
  end;
end;

end.
