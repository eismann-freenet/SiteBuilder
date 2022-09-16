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

unit SiteEncoding;

interface

uses
  SysUtils;

type
  TSiteEncoding = class

  strict private
    class var FEncoding: TEncoding;
    class function GetEncoding: TEncoding; static;

  protected
    class constructor Create;
    class destructor Destroy;

  public
    class property Encoding: TEncoding read GetEncoding;
  end;

implementation

uses
  UTF8EncodingNoBOM;

{ TSiteEncoding }

class constructor TSiteEncoding.Create;
begin
  FEncoding := TUTF8EncodingNoBOM.Create;
end;

class destructor TSiteEncoding.Destroy;
begin
  FEncoding.Free;
end;

class function TSiteEncoding.GetEncoding: TEncoding;
begin
  Result := FEncoding;
end;

end.
