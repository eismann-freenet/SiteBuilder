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

unit DuplicateEntry;

interface

type
  TDuplicateEntry = class

  strict private
    FFilenames: string;
    FAudioTracks: string;
    FCRC: string;
    FOriginalKeys: string;
    FReason: string;

    class function GetFormatedIndex(const Index: Integer): string;

  public
    constructor Create(const Filenames, AudioTracks, CRC, OriginalKeys,
      Reason: string);
    destructor Destroy; override;
    function GetFormatedReason(const OriginalKey: string): string;

    property Filenames: string read FFilenames;
    property AudioTracks: string read FAudioTracks;
    property CRC: string read FCRC;
    property OriginalKeys: string read FOriginalKeys;
    property Reason: string read FReason;
  end;

implementation

uses
  Classes, SysUtils, Key, StringReplacer, CSVFile, Sort;

{ TDuplicateEntry }

constructor TDuplicateEntry.Create(const Filenames, AudioTracks, CRC,
  OriginalKeys, Reason: string);
begin
  FFilenames := SortArrayAsString(Filenames);
  FFilenames := TStringReplacer.ReplaceNewLine(FFilenames);

  FAudioTracks := TStringReplacer.ReplaceSpecialChars(AudioTracks);
  FAudioTracks := TStringReplacer.ReplaceNewLine(FAudioTracks);

  FCRC := CRC;
  FOriginalKeys := OriginalKeys;

  FReason := TStringReplacer.ReplaceSpecialChars(Reason);
  FReason := TStringReplacer.ReplaceNewLine(FReason);
  FReason := StringReplace(FReason, '%OriginalKey%', '%0:s', [rfReplaceAll]);
  FReason := StringReplace(FReason, '%Index%', '%1:s', [rfReplaceAll]);
end;

destructor TDuplicateEntry.Destroy;
begin
  inherited Destroy;
end;

class function TDuplicateEntry.GetFormatedIndex(const Index: Integer): string;
begin
  Result := IntToStr(Index);
  case Index of
    1:
      Result := Result + 'st';
    2:
      Result := Result + 'nd';
    3:
      Result := Result + 'rd';
  else
    Result := Result + 'th';
  end;
end;

function TDuplicateEntry.GetFormatedReason(const OriginalKey: string): string;
var
  OriginalKeyList: TStringList;
  FirstValue: Boolean;
  Positions: string;
  Index: Integer;
  Key: TKey;
begin
  OriginalKeyList := nil;
  Key := nil;
  try
    Key := TKey.Create(OriginalKey);
    OriginalKeyList := TStringList.Create;

    TCSVFile.Split(OriginalKeyList, FOriginalKeys, '|');

    Positions := '';
    FirstValue := true;
    for Index := 0 to OriginalKeyList.Count - 1 do
    begin
      if OriginalKeyList[Index] = Key.Key then
      begin
        if FirstValue then
        begin
          FirstValue := false;
        end
        else
        begin
          Positions := Positions + ' and ';
        end;
        Positions := Positions + GetFormatedIndex(Index + 1);
      end;
    end;

    Result := Format(FReason, [Key.Filename, Positions]);
  finally
    Key.Free;
    OriginalKeyList.Free;
  end;
end;

end.
