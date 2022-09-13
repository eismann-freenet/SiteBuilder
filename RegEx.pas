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

unit RegEx;

interface

uses
  PerlRegEx;

function GetRegExResult(var RegexObj: TPerlRegEx; const Subject, RegEx: string)
  : string;

implementation

uses
  SysUtils;

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
    raise EAssertionFailed.Create('No match for regex ''' + RegEx + '''!');
  end;
end;

end.