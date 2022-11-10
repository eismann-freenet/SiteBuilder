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

unit CSVFile;

interface

uses
  Classes, SysUtils;

type
  TCSVFile = class

  strict private
    FFileContent: TStringList;
    FCSVLine: TStringList;
    FMaxColumnIndex: Integer;
    FLineNr: Integer;
    FFilename: string;
    FDelimiter: Char;
    FQuoteChar: Char;

  public
    constructor Create(const Filename: string; const Encoding: TEncoding;
      const Delimiter, QuoteChar: Char);
    destructor Destroy; override;

    function GetColumnIndex(const ColumnName: string): Integer;
    function GetValue(const ColumnIndex: Integer): string;
    function IsEndOfFile: Boolean;
    procedure NextLine;

    class procedure Split(var List: TStringList; const Text: string;
      const Delimiter: Char; const QuoteChar: Char = '"');
  end;

implementation

{ TCSVFile }

constructor TCSVFile.Create(const Filename: string; const Encoding: TEncoding;
  const Delimiter, QuoteChar: Char);
var
  Stream: TStream;
begin
  if not FileExists(Filename) then
  begin
    raise Exception.CreateFmt('CSV-File "%s" is missing!', [Filename]);
  end;

  FFilename := Filename;
  FDelimiter := Delimiter;
  FQuoteChar := QuoteChar;

  FFileContent := TStringList.Create;
  FCSVLine := TStringList.Create;

  Stream := TFileStream.Create(Filename, fmOpenRead or fmShareDenyNone);
  try
    FFileContent.LoadFromStream(Stream, Encoding);
  finally
    Stream.Free;
  end;

  if FFileContent.Count = 0 then
  begin
    raise Exception.CreateFmt('No content found in file "%s"!', [Filename]);
  end;

  FLineNr := -1;
  FMaxColumnIndex := -1;

  NextLine;
end;

destructor TCSVFile.Destroy;
begin
  FCSVLine.Free;
  FFileContent.Free;

  inherited Destroy;
end;

class procedure TCSVFile.Split(var List: TStringList; const Text: string;
  const Delimiter, QuoteChar: Char);
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

function TCSVFile.GetColumnIndex(const ColumnName: string): Integer;
begin
  Result := FCSVLine.IndexOf(ColumnName);
  if Result = -1 then
  begin
    raise Exception.CreateFmt('Column "%s" is missing in file "%s"!',
      [ColumnName, FFilename]);
  end;

  if Result > FMaxColumnIndex then
  begin
    FMaxColumnIndex := Result;
  end;
end;

function TCSVFile.GetValue(const ColumnIndex: Integer): string;
begin
  Result := FCSVLine[ColumnIndex];
end;

function TCSVFile.IsEndOfFile: Boolean;
begin
  Result := FLineNr + 1 = FFileContent.Count;
end;

procedure TCSVFile.NextLine;
begin
  Inc(FLineNr);

  // Skip empty lines
  while FFileContent[FLineNr] = '' do
  begin
    Inc(FLineNr);
  end;

  Split(FCSVLine, FFileContent[FLineNr], FDelimiter, FQuoteChar);

  while FCSVLine.Count < FMaxColumnIndex do
  begin
    FCSVLine.Add('');
  end;
end;

end.
