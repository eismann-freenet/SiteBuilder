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

unit FileInfoTree;

interface

uses
  Generics.Collections, Classes, FileInfoList, KeyCache, Thumbnail,
  DuplicateTree, BookmarksParser;

type
  TFileInfoTree = class(TDictionary<string, TFileInfoList>)

  strict private
    FFileInfoList: TFileInfoList;

  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadData(Filenames: TStringList;
      Thumbnail, BigThumbnail: TThumbnail; KeyCache: TKeyCache;
      BookmarksParser: TBookmarksParser; const NewKeyName, DataPath, SitePath,
      ThumbnailExtension, ThumbnailPath, CRCExtension: string;
      DuplicateTree: TDuplicateTree);
  end;

implementation

uses
  SysUtils, CSVFile, FileInfo, DuplicateList, Logger;

{ TDuplicateTree }

constructor TFileInfoTree.Create;
begin
  inherited Create;
  FFileInfoList := TFileInfoList.Create;
end;

destructor TFileInfoTree.Destroy;
var
  Key: string;
begin
  for Key in Keys do
  begin
    Items[Key].Free;
  end;
  FFileInfoList.Free;

  inherited Destroy;
end;

procedure TFileInfoTree.LoadData(Filenames: TStringList;
  Thumbnail, BigThumbnail: TThumbnail; KeyCache: TKeyCache;
  BookmarksParser: TBookmarksParser; const NewKeyName, DataPath, SitePath,
  ThumbnailExtension, ThumbnailPath, CRCExtension: string;
  DuplicateTree: TDuplicateTree);
var
  IndexSections, IndexKey, IndexOtherFilenames, IndexDescription,
    IndexAudioType, IndexPlayedMusic, IndexIsNewKey,
    IndexIsFullThumbnailRequired, IndexHasActiveLink: Integer;
  DuplicateList: TDuplicateList;
  CurrentFileInfo: TFileInfo;
  Section, Filename: string;
  AltSections: TStringList;
  CSVFile: TCSVFile;
begin
  for Filename in Filenames do
  begin
    TLogger.LogInfo(Format('Read "%s"', [Filename]));
    AltSections := nil;
    CSVFile := nil;
    try
      AltSections := TStringList.Create;
      CSVFile := TCSVFile.Create(Filename, TEncoding.UTF8, ',', '"');

      IndexSections := CSVFile.GetColumnIndex('Sections');
      IndexKey := CSVFile.GetColumnIndex('Key');
      IndexIsNewKey := CSVFile.GetColumnIndex('Is New Key');
      IndexOtherFilenames := CSVFile.GetColumnIndex('Other Filenames');
      IndexDescription := CSVFile.GetColumnIndex('Description');
      IndexAudioType := CSVFile.GetColumnIndex('Audio Type');
      IndexPlayedMusic := CSVFile.GetColumnIndex('Played Music');
      IndexIsFullThumbnailRequired := CSVFile.GetColumnIndex
        ('Is Big Thumbnail Required');
      IndexHasActiveLink := CSVFile.GetColumnIndex('Has Active Link');

      while not CSVFile.IsEndOfFile do
      begin
        CSVFile.NextLine;

        TCSVFile.Split(AltSections, CSVFile.GetValue(IndexSections), '|');

        if AltSections.Count = 0 then
        begin
          AltSections.Add(''); // dummy section, which is not displayed
        end;

        if CSVFile.GetValue(IndexIsNewKey) <> '' then
        begin
          AltSections.Add(NewKeyName);
        end;

        if DuplicateTree.ContainsKey(CSVFile.GetValue(IndexKey)) then
        begin
          DuplicateList := DuplicateTree[CSVFile.GetValue(IndexKey)];
          DuplicateTree[CSVFile.GetValue(IndexKey)].SetUsed(true);
        end
        else
        begin
          DuplicateList := nil;
        end;

        CurrentFileInfo := TFileInfo.Create(Thumbnail, BigThumbnail, KeyCache,
          BookmarksParser, DataPath, SitePath, ThumbnailExtension,
          ThumbnailPath, CRCExtension, CSVFile.GetValue(IndexSections),
          CSVFile.GetValue(IndexKey), CSVFile.GetValue(IndexIsNewKey),
          CSVFile.GetValue(IndexIsFullThumbnailRequired),
          CSVFile.GetValue(IndexOtherFilenames),
          CSVFile.GetValue(IndexDescription),
          CSVFile.GetValue(IndexPlayedMusic), CSVFile.GetValue(IndexAudioType),
          CSVFile.GetValue(IndexHasActiveLink), DuplicateList, NewKeyName);

        for Section in AltSections do
        begin
          if not ContainsKey(Section) then
          begin
            Add(Section, TFileInfoList.Create(false));
          end;

          Items[Section].Add(CurrentFileInfo);
        end;
      end;
    finally
      AltSections.Free;
      CSVFile.Free;
    end;
  end;
end;

end.
