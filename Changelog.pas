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

unit Changelog;

interface

uses
  Generics.Collections, ChangelogEntry;

type
  TChangelog = class(TObjectList<TChangelogEntry>)

  strict private
    FMaxEdition: Integer;

  public
    constructor Create(const ChangelogFile: string);
    destructor Destroy; override;
    property MaxEdition: Integer read FMaxEdition;
  end;

implementation

uses
  SysUtils, StringReplacer, CSVFile;

{ TChangelogEntryList }

constructor TChangelog.Create(const ChangelogFile: string);
var
  IndexEdition, IndexChanges, Edition: Integer;
  CurrentChangelogEntry: TChangelogEntry;
  Changes: string;
  CSVFile: TCSVFile;
begin
  inherited Create;

  FMaxEdition := 0;
  Clear;

  CSVFile := TCSVFile.Create(ChangelogFile, TEncoding.UTF8, ',', '"');
  try
    IndexEdition := CSVFile.GetColumnIndex('Edition');
    IndexChanges := CSVFile.GetColumnIndex('Changes');

    while not CSVFile.IsEndOfFile do
    begin
      CSVFile.NextLine;

      try
        Edition := StrToInt(CSVFile.GetValue(IndexEdition));
      except
        raise Exception.CreateFmt('Invalid edition "%s" in CSV-File "%s"!',
          [CSVFile.GetValue(IndexEdition), ChangelogFile]);
      end;

      if Edition > FMaxEdition then
      begin
        FMaxEdition := Edition;
      end;

      Changes := CSVFile.GetValue(IndexChanges);
      Changes := TStringReplacer.ReplaceSpecialChars(Changes);
      Changes := TStringReplacer.ReplaceNewLine(Changes);

      CurrentChangelogEntry := TChangelogEntry.Create(Edition, Changes);

      Add(CurrentChangelogEntry);
    end;
    Reverse;

  finally
    CSVFile.Free;
  end;
end;

destructor TChangelog.Destroy;
begin
  inherited Destroy;
end;

end.
