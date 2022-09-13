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

unit ChangelogEntryList;

interface

uses
  Generics.Collections, ChangelogEntry, Classes;

type
  TChangelogEntryList = class(TPersistent)

  strict private
    FData: TObjectList<TChangelogEntry>;
    FChangelogFile: string;
    FMaxEdition: Integer;
    procedure GenerateChangelog;

  published
    property List: TObjectList<TChangelogEntry>read FData;
    property MaxEdition: Integer read FMaxEdition;

  public
    constructor Create(const ChangelogFile: string);
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils, Tools, StringReplacer, Logger;

const
  ColumnEdition = 'Edition';
  ColumnChanges = 'Changes';

  { TChangelogEntryList }

constructor TChangelogEntryList.Create(const ChangelogFile: string);
begin
  FData := TObjectList<TChangelogEntry>.Create;
  FChangelogFile := ChangelogFile;
  FMaxEdition := 0;
  GenerateChangelog;
end;

destructor TChangelogEntryList.Destroy;
begin
  FData.Free;
  inherited Destroy;
end;

procedure TChangelogEntryList.GenerateChangelog;
var
  CSVLine, FileContent: TStringList;
  Stream: TStream;
  Line: string;
  IndexEdition, IndexChanges, Edition, LineNr: Integer;
begin
  FData.Clear;

  CSVLine := nil;
  FileContent := nil;
  Stream := nil;

  try
    CSVLine := TStringList.Create;
    FileContent := TStringList.Create;
    Stream := TFileStream.Create(FChangelogFile, fmOpenRead or fmShareDenyNone);

    IndexEdition := -1;
    IndexChanges := -1;
    Edition := 0;
    LineNr := 0;

    FileContent.LoadFromStream(Stream, TEncoding.UTF8);

    for Line in FileContent do
    begin
      Inc(LineNr);
      if Line <> '' then
      begin
        Split(CSVLine, Line, ',', '"');

        if IndexEdition = -1 then
        begin
          IndexEdition := ReadColumnIndex(CSVLine, FChangelogFile,
            ColumnEdition);
          IndexChanges := ReadColumnIndex(CSVLine, FChangelogFile,
            ColumnChanges);
        end
        else
        begin
          if CSVLine.Count < 2 then
          begin
            TLogger.LogFatal(Format(
                'To few columns in line %d in the CSV-File "%s". 2 columns are required.',
                [LineNr, FChangelogFile]));
          end;
          try
            Edition := StrToInt(CSVLine[IndexEdition]);
          except
            TLogger.LogFatal(Format('Invalid edition "%s" in CSV-File "%s".',
                [CSVLine[IndexEdition], FChangelogFile]));
          end;
          if Edition > FMaxEdition then
          begin
            FMaxEdition := Edition;
          end;

          FData.Add(TChangelogEntry.Create(Edition,
              TStringReplacer.ReplacesQuotes(CSVLine[IndexChanges])));
        end;
      end;
    end;

    FData.Reverse;
  finally
    FreeAndNil(Stream);
    FreeAndNil(FileContent);
    FreeAndNil(CSVLine);
  end;
end;

end.
