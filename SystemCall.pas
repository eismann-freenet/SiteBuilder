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

unit SystemCall;

interface

uses
  Classes;

function ExecuteOutput(const Command: string; var Output: string): Boolean;
function ExecuteWait(const Command: string): Boolean;
function GetRandomTempFilename: string;
function DeleteFile(const Filename: string): Boolean;
function DeleteFiles(Files: TStringList): Boolean;
function CopyFile(const Source, Destination: string): Boolean;
function GetDecimalSeparator: Char;
function StringCompare(const Text1, Text2: string): Integer;

implementation

uses
  Windows, Vcl.Forms, SysUtils, IOUtils;

function ReadPipe(Pipe: THandle): string;
var
  Stream: TStringStream;
  Buffer: array [0 .. 255] of Char;
  NumberOfBytesRead: Cardinal;
begin
  Stream := TStringStream.Create('');
  NumberOfBytesRead := 0;
  try
    while ReadFile(Pipe, Buffer, 255, NumberOfBytesRead, nil) do
    begin
      Stream.Write(Buffer, NumberOfBytesRead);
    end;
    Result := Stream.DataString;
  finally
    Stream.Free;
  end;
end;

function ExecuteOutput(const Command: string; var Output: string): Boolean;
var
  PipeOutputRead, PipeOutputWrite: THandle;
  SecurityAttr: TSecurityAttributes;
  ProcessInfo: TProcessInformation;
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

  FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
  with StartupInfo do
  begin
    cb := SizeOf(TStartupInfo);
    hStdInput := GetStdHandle(STD_INPUT_HANDLE);
    hStdOutput := PipeOutputWrite;
    hStdError := PipeOutputWrite;
    wShowWindow := SW_HIDE;
    dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
  end;

  Result := CreateProcess(nil, PChar(Trim(Command)), nil, nil, True,
    CREATE_DEFAULT_ERROR_MODE or CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS,
    nil, nil, StartupInfo, ProcessInfo);

  CloseHandle(PipeOutputWrite);

  if Result then
  begin
    Output := ReadPipe(PipeOutputRead);

    while WaitForSingleObject(ProcessInfo.hProcess, 10) > 0 do
    begin
      Application.ProcessMessages;
    end;

    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
  end;

  CloseHandle(PipeOutputRead);
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
  Result := TPath.GetTempFileName;
  SysUtils.DeleteFile(Result);
end;

function DeleteFile(const Filename: string): Boolean;
begin
  Result := SysUtils.DeleteFile(Filename);
end;

function DeleteFiles(Files: TStringList): Boolean;
var
  OneFile: string;
begin
  Result := True;
  for OneFile in Files do
  begin
    if FileExists(OneFile) and not DeleteFile(OneFile) then
    begin
      Result := False;
    end;
  end;
end;

function CopyFile(const Source, Destination: string): Boolean;
begin
  Result := Windows.CopyFile(PChar(Source), PChar(Destination), False);
end;

function GetDecimalSeparator: Char;
var
  Format: TFormatSettings;
begin
  GetLocaleFormatSettings(LOCALE_SYSTEM_DEFAULT, Format);
  Result := Format.DecimalSeparator;
end;

function StrCmpLogicalW(const P1, P2: PWideChar): Integer; stdcall;
  external 'Shlwapi.dll';

function StringCompare(const Text1, Text2: string): Integer;
begin
  Result := StrCmpLogicalW(PChar(Text1), PChar(Text2));
end;

end.
