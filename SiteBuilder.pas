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

unit SiteBuilder;

interface

uses
  Classes, Generics.Collections, ChangelogEntry, FileInfoList, IndexPageList;

type
  TChangelogEntryList = TObjectList<TChangelogEntry>;

  TSiteBuilder = class(TPersistent)

  strict private
    FDataPath: string;
    FChangelogFile: string;
    FSitePath: string;
    FMTNCommand: string;
    FMTNInfoPattern: string;
    FImageMagickCommand: string;
    FThumbnailExt: string;
    FThumbnailInfoExt: string;
    FThumbnailPath: string;
    FThumbnailInfoPath: string;
    FInfoFile: string;
    FCSVPath: string;
    FInputFilesExtension: string;
    FOutputExtension: string;
    FStaticFiles: string;
    FFiles: TDictionary<string, TFileInfoList>;

    procedure GetFileList(var Files: TStringList);
    procedure ReadAndAddContent(const Filename: string);
    procedure AddFile(const Section, FilePath, FileKey, FileOtherNames,
      Description, AudioTracks: string);

  public
    constructor Create(const DataPath, ChangelogFile, SitePath, MTNCommand,
      MTNInfoPattern, ImageMagickCommand, ThumbnailExt, ThumbnailInfoExt,
      ThumbnailPath, ThumbnailInfoPath, InfoFile, CSVPath, InputFilesExtension,
      OutputExtension, StaticFiles: string);
    destructor Destroy; override;

    procedure ProcessCSVFiles;

    procedure GetPages(var Pages: TIndexPageList);
    procedure GetChangelog(var Entries: TChangelogEntryList);
    procedure GetFiles(const Page: string; var Files: TFileInfoList);
    function GetPageInfo(const Page: string): string;
    procedure CopyStaticFiles;
  end;

implementation

uses
  SysUtils, Tools, FileInfo, IndexPage, Logger, Windows;

{ TSiteBuilder }

procedure TSiteBuilder.CopyStaticFiles;
var
  StaticFileList: TStringList;
  StaticFile: string;
begin
  StaticFileList := TStringList.Create;
  try
    Split(StaticFileList, FStaticFiles, '|');
    for StaticFile in StaticFileList do
    begin
      CopyFile(PChar(StaticFile), PChar(FSitePath + PathDelim + StaticFile),
        False);
    end;
  finally
    StaticFileList.Free;
  end;
end;

procedure TSiteBuilder.ProcessCSVFiles;
var
  Files: TStringList;
  Filename: string;
begin
  Files := TStringList.Create;
  try
    GetFileList(Files);
    for Filename in Files do
    begin
      ReadAndAddContent(FCSVPath + PathDelim + Filename);
    end;
  finally
    Files.Free;
  end;
end;

constructor TSiteBuilder.Create(const DataPath, ChangelogFile, SitePath,
  MTNCommand, MTNInfoPattern, ImageMagickCommand, ThumbnailExt,
  ThumbnailInfoExt, ThumbnailPath, ThumbnailInfoPath, InfoFile,
  CSVPath, InputFilesExtension, OutputExtension, StaticFiles: string);
begin
  FFiles := TDictionary<string, TFileInfoList>.Create;

  FDataPath := DataPath;
  FChangelogFile := ChangelogFile;
  FSitePath := SitePath;
  FMTNCommand := MTNCommand;
  FMTNInfoPattern := MTNInfoPattern;
  FImageMagickCommand := ImageMagickCommand;
  FThumbnailExt := ThumbnailExt;
  FThumbnailInfoExt := ThumbnailInfoExt;
  FThumbnailPath := ThumbnailPath;
  FThumbnailInfoPath := ThumbnailInfoPath;
  FInfoFile := InfoFile;
  FCSVPath := CSVPath;
  FInputFilesExtension := InputFilesExtension;
  FOutputExtension := OutputExtension;
  FStaticFiles := StaticFiles;
end;

destructor TSiteBuilder.Destroy;
var
  Key: string;
begin
  for Key in FFiles.Keys do
  begin
    FFiles[Key].Free;
  end;
  FFiles.Free;

  inherited Destroy;
end;

procedure TSiteBuilder.GetChangelog(var Entries: TChangelogEntryList);
var
  CSVLine, FileContent: TStringList;
  Stream: TStream;
  Line: string;
begin
  Entries.Clear;

  CSVLine := nil;
  FileContent := nil;
  Stream := nil;
  try
    CSVLine := TStringList.Create;
    FileContent := TStringList.Create;
    Stream := TFileStream.Create(FChangelogFile, fmOpenRead or fmShareDenyNone);

    FileContent.LoadFromStream(Stream, TEncoding.UTF8);

    for Line in FileContent do
    begin
      Split(CSVLine, Line, ',', '"');

      Entries.Add(TChangelogEntry.Create(StrToInt(CSVLine[0]),
          ReplacesQuotes(CSVLine[1])));
    end;

    Entries.Reverse;
  finally
    FreeAndNil(Stream);
    FreeAndNil(FileContent);
    FreeAndNil(CSVLine);
  end;
end;

procedure TSiteBuilder.GetFileList(var Files: TStringList);
var
  SearchResult: TSearchRec;
begin
  Files.Clear;
  try
    if FindFirst(FCSVPath + PathDelim + '*' + FInputFilesExtension, faAnyFile,
      SearchResult) = 0 then
    begin
      repeat
        if ExtractFileExt(SearchResult.Name) = FInputFilesExtension then
        begin
          Files.Add(SearchResult.Name);
        end;
      until FindNext(SearchResult) <> 0;
    end;
  finally
    SysUtils.FindClose(SearchResult);
  end;
end;

procedure TSiteBuilder.ReadAndAddContent(const Filename: string);
var
  CSVLine, FileContent, AltSections: TStringList;
  Line, Section, RealSection: string;
  Stream: TStream;
begin
  CSVLine := nil;
  FileContent := nil;
  AltSections := nil;
  Stream := nil;
  try
    CSVLine := TStringList.Create;
    FileContent := TStringList.Create;
    AltSections := TStringList.Create;
    Stream := TFileStream.Create(Filename, fmOpenRead or fmShareDenyNone);

    FileContent.LoadFromStream(Stream, TEncoding.UTF8);

    for Line in FileContent do
    begin
      Split(CSVLine, Line, ',', '"');

      while CSVLine.Count < 5 do
      begin
        CSVLine.Add('');
      end;

      Split(AltSections, CSVLine[0], '|');
      RealSection := AltSections[0];

      for Section in AltSections do
      begin
        if not FFiles.ContainsKey(Section) then
        begin
          FFiles.Add(Section, TFileInfoList.Create);
        end;
        AddFile(Section, RealSection, CSVLine[1], CSVLine[2],
          ReplacesQuotes(CSVLine[3]), CSVLine[4]);
      end;

    end;
  finally
    FreeAndNil(Stream);
    FreeAndNil(AltSections);
    FreeAndNil(FileContent);
    FreeAndNil(CSVLine);
  end;
end;

procedure TSiteBuilder.AddFile(const Section, FilePath, FileKey,
  FileOtherNames, Description, AudioTracks: string);
var
  FileInfoList: TFileInfoList;
begin
  FileInfoList := FFiles[Section];

  FileInfoList.Add(TFileInfo.Create(FDataPath, FSitePath, FMTNCommand,
      FMTNInfoPattern, FImageMagickCommand, FThumbnailExt, FThumbnailInfoExt,
      FThumbnailPath, FThumbnailInfoPath, FilePath, FileKey, FileOtherNames,
      Description, AudioTracks));

  FFiles[Section] := FileInfoList;
end;

function TSiteBuilder.GetPageInfo(const Page: string): string;
var
  InfoFile: string;
  FileContent: TStringList;
  Stream: TStream;
begin
  Result := '';
  InfoFile := FDataPath + PathDelim + TFileInfo.SectionToPath(Page)
    + PathDelim + FInfoFile;

  if FileExists(InfoFile) then
  begin
    TLogger.LogInfo('Read "' + InfoFile + '"');
    FileContent := nil;
    Stream := nil;

    try
      FileContent := TStringList.Create;
      Stream := TFileStream.Create(InfoFile, fmOpenRead or fmShareDenyNone);

      FileContent.LoadFromStream(Stream, TEncoding.UTF8);
      Result := Trim(FileContent.Text);
    finally
      FreeAndNil(FileContent);
      FreeAndNil(Stream);
    end;
  end;
end;

procedure TSiteBuilder.GetPages(var Pages: TIndexPageList);
var
  Section: string;
begin
  for Section in FFiles.Keys do
  begin
    Pages.Add(TIndexPage.Create(Section, FOutputExtension));
  end;
  Pages.Sort;
end;

procedure TSiteBuilder.GetFiles(const Page: string; var Files: TFileInfoList);
begin
  Files := FFiles[Page];
  Files.Sort;
end;

end.
