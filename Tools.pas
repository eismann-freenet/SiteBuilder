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

unit Tools;

interface

uses
  Classes;

procedure Split(var List: TStringList; const Text: string;
  const Delimiter: Char; const QuoteChar: Char = '"');
function StrCmpLogicalW(const P1, P2: PWideChar): Integer; stdcall;
function ReadColumnIndex(const List: TStringList;
  const Filename, Column: string): Integer;

implementation

uses
  SysUtils, Logger;

function StrCmpLogicalW(const P1, P2: PWideChar): Integer; stdcall;
external 'Shlwapi.dll';

procedure Split(var List: TStringList; const Text: string;
  const Delimiter: Char; const QuoteChar: Char);
var
  I: Integer;
begin
  List.Clear;
  List.Delimiter := Delimiter;
  List.QuoteChar := QuoteChar;
  List.StrictDelimiter := True;
  List.DelimitedText := Text;
  for I := 0 to List.Count - 1 do
  begin
    List[I] := Trim(List[I]);
  end;
end;

function ReadColumnIndex(const List: TStringList;
  const Filename, Column: string): Integer;
begin
  Result := List.IndexOf(Column);
  if Result = -1 then
  begin
    TLogger.LogFatal(Format('Column "%s" is missing in file "%s"!',
        [Column, Filename]));
  end;
end;

end.
