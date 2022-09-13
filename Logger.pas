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

unit Logger;

interface

uses
  Classes;

type
  TLogger = class(TPersistent)

  strict private
    class var ErrorCount: Integer;

    class procedure Log(const Msg: string);

  protected
    class constructor Create;
    class destructor Destroy;

  public
    class procedure LogFatal(const Msg: string);
    class procedure LogError(const Msg: string);
    class procedure LogInfo(const Msg: string);
    class function IsError: Boolean;
  end;

implementation

uses
  SysUtils;

{ TLogger }

class constructor TLogger.Create;
begin
  ErrorCount := 0;
end;

class destructor TLogger.Destroy;
begin
  // nothing do to here
end;

class function TLogger.IsError: Boolean;
begin
  Result := ErrorCount > 0;
end;

class procedure TLogger.Log(const Msg: string);
begin
  Inc(ErrorCount);
  writeln(Msg);
end;

class procedure TLogger.LogFatal(const Msg: string);
begin
  Log('Fatal: ' + Msg);
  raise Exception.Create(Msg);
end;

class procedure TLogger.LogInfo(const Msg: string);
begin
  Log('Info : ' + Msg);
end;

class procedure TLogger.LogError(const Msg: string);
begin
  Log('Error: ' + Msg);
end;

end.
