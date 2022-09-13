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

unit SystemCall;

interface

uses
  Classes, SysUtils;

function ExecuteOutput(const Command: string; Output, Errors: TStringList)
  : Boolean;
function ExecuteWait(const Command: string): Boolean;
function GetRandomTempFilename: string;
function DeleteFiles(Files: TStringList): Boolean;

implementation

uses
  Windows, Forms, IOUtils;

procedure ReadPipe(Pipe: THandle; Output: TStringList);
var
  Stream: TMemoryStream;
  Buffer: array [0 .. 255] of Char;
  NumberOfBytesRead: Cardinal;
begin
  Stream := TMemoryStream.Create;
  try
    while ReadFile(Pipe, Buffer, 255, NumberOfBytesRead, nil) do
    begin
      Stream.Write(Buffer, NumberOfBytesRead);
    end;
    Stream.Position := 0;
    Output.LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

function ExecuteOutput(const Command: string; Output, Errors: TStringList)
  : Boolean;
var
  PipeErrorsRead, PipeErrorsWrite, PipeOutputRead, PipeOutputWrite: THandle;
  ProcessInfo: TProcessInformation;
  SecurityAttr: TSecurityAttributes;
  StartupInfo: TStartupInfo;
begin
  FillChar(ProcessInfo, SizeOf(TProcessInformation), 0);

  FillChar(SecurityAttr, SizeOf(TSecurityAttributes), 0);
  with SecurityAttr do
  begin
    nLength := SizeOf(TSecurityAttributes);
    bInheritHandle := True;
    lpSecurityDescriptor := nil;
  end;

  CreatePipe(PipeOutputRead, PipeOutputWrite, @SecurityAttr, 0);
  CreatePipe(PipeErrorsRead, PipeErrorsWrite, @SecurityAttr, 0);

  FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
  with StartupInfo do
  begin
    cb := SizeOf(TStartupInfo);
    hStdInput := 0;
    hStdOutput := PipeOutputWrite;
    hStdError := PipeErrorsWrite;
    wShowWindow := SW_HIDE;
    dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
  end;

  if CreateProcess(nil, PChar(Trim(Command)), nil, nil, True,
    CREATE_DEFAULT_ERROR_MODE or CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS,
    nil, nil, StartupInfo, ProcessInfo) then
  begin
    Result := True;

    CloseHandle(PipeOutputWrite);
    CloseHandle(PipeErrorsWrite);

    ReadPipe(PipeOutputRead, Output);
    CloseHandle(PipeOutputRead);

    ReadPipe(PipeErrorsRead, Errors);
    CloseHandle(PipeErrorsRead);

    while WaitForSingleObject(ProcessInfo.hProcess, 10) > 0 do
    begin
      Application.ProcessMessages;
    end;

    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
  end
  else
  begin
    Result := False;
    CloseHandle(PipeOutputRead);
    CloseHandle(PipeOutputWrite);
    CloseHandle(PipeErrorsRead);
    CloseHandle(PipeErrorsWrite);
  end;
end;

function ExecuteWait(const Command: string): Boolean;
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  FillChar(ProcessInfo, SizeOf(TProcessInformation), 0);

  FillChar(StartupInfo, SizeOf(StartupInfo), 0);
  with StartupInfo do
  begin
    cb := SizeOf(TStartupInfo);
    wShowWindow := SW_HIDE;
    dwFlags := STARTF_USESHOWWINDOW;
  end;

  if CreateProcess(nil, PChar(Trim(Command)), nil, nil, True, CREATE_NO_WINDOW,
    nil, nil, StartupInfo, ProcessInfo) then
  begin
    Result := True;

    while WaitForSingleObject(ProcessInfo.hProcess, 10) > 0 do
    begin
      Application.ProcessMessages;
    end;

    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
  end
  else
  begin
    Result := False;
  end;
end;

function GetRandomTempFilename: string;
begin
  Result := TPath.GetTempFilename;
  Result := StrPas(PChar(Result));
  SysUtils.DeleteFile(Result);
end;

function DeleteFiles(Files: TStringList): Boolean;
var
  OneFile: string;
begin
  Result := True;
  for OneFile in Files do
  begin
    if not SysUtils.DeleteFile(OneFile) then
    begin
      Result := False;
    end;
  end;
end;

end.