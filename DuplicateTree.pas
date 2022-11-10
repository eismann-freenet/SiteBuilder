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

unit DuplicateTree;

interface

uses
  Generics.Collections, Classes, DuplicateList;

type
  TDuplicateTree = class(TDictionary<string, TDuplicateList>)

  strict private
    procedure Sort;

  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadData(Filenames: TStringList);
  end;

implementation

uses
  SysUtils, CSVFile, DuplicateEntry, Logger;

{ TDuplicateTree }

constructor TDuplicateTree.Create;
begin
  inherited Create;
end;

destructor TDuplicateTree.Destroy;
var
  Key: string;
begin
  for Key in Keys do
  begin
    Items[Key].Free;
  end;

  inherited Destroy;
end;

procedure TDuplicateTree.LoadData(Filenames: TStringList);
var
  IndexFilename, IndexPlayedMusic, IndexCRC, IndexOriginalKey,
    IndexReason: Integer;
  CurrentDuplicateEntry, SearchDuplicateEntry: TDuplicateEntry;
  Filename, OriginalKey: string;
  OriginalKeyList: TStringList;
  EntryFound: Boolean;
  CSVFile: TCSVFile;
begin
  for Filename in Filenames do
  begin
    TLogger.LogInfo(Format('Read "%s"', [Filename]));
    CSVFile := TCSVFile.Create(Filename, TEncoding.UTF8, ',', '"');
    try
      IndexFilename := CSVFile.GetColumnIndex('Filenames');
      IndexPlayedMusic := CSVFile.GetColumnIndex('Played Music');
      IndexCRC := CSVFile.GetColumnIndex('CRC');
      IndexOriginalKey := CSVFile.GetColumnIndex('Original Keys');
      IndexReason := CSVFile.GetColumnIndex('Reason');

      OriginalKeyList := TStringList.Create;
      try
        while not CSVFile.IsEndOfFile do
        begin
          CSVFile.NextLine;

          TCSVFile.Split(OriginalKeyList,
            CSVFile.GetValue(IndexOriginalKey), '|');

          CurrentDuplicateEntry := TDuplicateEntry.Create
            (CSVFile.GetValue(IndexFilename),
            CSVFile.GetValue(IndexPlayedMusic), CSVFile.GetValue(IndexCRC),
            CSVFile.GetValue(IndexOriginalKey), CSVFile.GetValue(IndexReason));

          for OriginalKey in OriginalKeyList do
          begin

            if OriginalKey <> '' then
            begin

              if not ContainsKey(OriginalKey) then
              begin
                Add(OriginalKey, TDuplicateList.Create(false));
              end;

              EntryFound := false;
              for SearchDuplicateEntry in Items[OriginalKey] do
              begin
                if SearchDuplicateEntry.CRC = CurrentDuplicateEntry.CRC then
                begin
                  EntryFound := true;
                end;
              end;

              if not EntryFound then
              begin
                Items[OriginalKey].Add(CurrentDuplicateEntry);
              end;
            end;
          end;
        end;
      finally
        OriginalKeyList.Free;
      end;
    finally
      CSVFile.Free;
    end;
  end;

  Sort;
end;

procedure TDuplicateTree.Sort;
var
  Key: string;
begin
  for Key in Keys do
  begin
    Items[Key].Sort;
  end;
end;

end.
