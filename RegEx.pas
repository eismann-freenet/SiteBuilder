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

unit RegEx;

interface

uses
  PerlRegEx;

function GetRegExResult(var RegexObj: TPerlRegEx; const Subject, RegEx: string)
  : string;
function RegExReplace(var RegexObj: TPerlRegEx; const Subject, RegEx,
  Replace: string): string;

implementation

uses
  SysUtils, Logger;

function GetRegExResult(var RegexObj: TPerlRegEx; const Subject, RegEx: string)
  : string;
var
  i: Integer;
begin
  Result := '';
  RegexObj.Subject := UTF8Encode(Subject);

  RegexObj.RegEx := UTF8Encode(RegEx);
  if RegexObj.Match then
  begin
    RegexObj.StoreGroups;
    for i := 1 to RegexObj.GroupCount do
    begin
      if length(RegexObj.Groups[i]) > 0 then
      begin
        Result := UTF8ToString(RegexObj.Groups[i]);
      end;
    end;
  end
  else
  begin
    TLogger.LogFatal(Format('No match for regex "%s" and subject "%s"!',
        [RegEx, Subject]));
  end;
end;

function RegExReplace(var RegexObj: TPerlRegEx; const Subject, RegEx,
  Replace: string): string;
begin
  Result := Subject;
  RegexObj.Subject := UTF8Encode(Subject);
  RegexObj.RegEx := UTF8Encode(RegEx);
  RegexObj.Replacement := UTF8Encode(Replace);

  if RegexObj.Match then
  begin
    RegexObj.ReplaceAll;
    Result := UTF8ToString(RegexObj.Subject);
  end;
end;

end.
