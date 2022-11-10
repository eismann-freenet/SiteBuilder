{
  Copyright 2014 - 2022 eismann@5H+yXYkQHMnwtQDzJB8thVYAAIs

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

unit RegEx;

interface

uses
  SysUtils;

type
  EInvalidRegEx = class(Exception)
  end;

function GetRegExResult(const Subject, Pattern: string): string;

implementation

uses
  RegularExpressions;

function GetRegExResult(const Subject, Pattern: string): string;
var
  i: Integer;
  Match: TMatch;
  Groups: TGroupCollection;
begin
  Match := TRegEx.Match(Subject, Pattern);
  if not Match.Success then
  begin
    raise EInvalidRegEx.CreateFmt('No match for regex "%s" and subject "%s"!',
      [Pattern, Subject]);
  end;
  Groups := Match.Groups;
  for i := 1 to Groups.Count - 1 do // index 0 = full matched text
  begin
    Result := Groups.Item[i].Value;
  end;
end;

end.
