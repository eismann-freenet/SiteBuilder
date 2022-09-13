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

unit SiteBuilder;

interface

uses
  Classes, Generics.Collections, FileInfoList, IndexPageList,
  KeyCache, Thumbnail, StringReplacer, ChangelogEntryList;

const
  ConfigKey = 'SiteBuilder';

type
  TSiteBuilder = class(TPersistent)

  strict private
    FThumbnail: TThumbnail;
    FBigThumbnail: TThumbnail;

    FKeyCacheDatabase: TKeyCache;

    FSourcePath: string;
    FSourceFileExtension: string;

    FChangelogFilename: string;
    FChangelog: TChangelogEntryList;

    FDataPath: string;
    FInfoFilename: string;

    FSitePath: string;
    FSiteAuthor: string;
    FSiteDescription: string;
    FOutputExtension: string;
    FThumbnailPath: string;
    FThumbnailExtension: string;
    FCRCPath: string;
    FCRCExtension: string;
    FSFVExtension: string;
    FSourcePathSite: string;
    FIndexFilename: string;
    FChangelogFilenameSite: string;
    FStaticFiles: string;
    FNewKeyName: string;

    FSiteKey: string;
    FSiteName: string;
    FFiles: TDictionary<string, TFileInfoList>;

    procedure GetFileList(var Files: TStringList);
    procedure ReadAndAddContent(const Filename: string);
    procedure AddFile(const Section: string; Sections: TStringList;
      const FileKey: string; const IsFullThumbnailRequired: Boolean;
      const FileOtherNames, Description, AudioTracks: string);
    procedure ProcessSourceFiles;
    procedure GetPages(var Pages: TIndexPageList);
    procedure GetFiles(const Page: string; var Files: TFileInfoList);
    function GetPageInfo(const Page: string): string;
    procedure CopyStaticFiles;

  public
    constructor Create(const ConfigFilename: string);
    destructor Destroy; override;
    procedure Run;
  end;

implementation

uses
  SysUtils, Tools, FileInfo, IndexPage, Logger, Windows, IniFiles,
  TemplateChangelog, TemplateIndex, TemplateContent;

const
  ColumnSections = 'Sections';
  ColumnKey = 'Key';
  ColumnOtherFilenames = 'Other Filenames';
  ColumnDescription = 'Description';
  ColumnPlayedMusic = 'Played Music';
  ColumnIsNewKey = 'Is New Key';
  ColumnIsFullThumbnailRequired = 'Is Big Thumbnail Required';

  { TSiteBuilder }

constructor TSiteBuilder.Create(const ConfigFilename: string);
var
  ConfigFile: TMemIniFile;
  VideoThumbnailCountHorizontal, VideoThumbnailCountVertical,
    VideoThumbnailMaxWidth, VideoBigThumbnailCountHorizontal,
    VideoBigThumbnailCountVertical, VideoBigThumbnailMaxWidth,
    ImageThumbnailMaxHeight: Integer;
  VideoTimeFormat, FFMPEGPath, ImageMagickPath, KeyCacheFilename: string;
begin
  ConfigFile := TMemIniFile.Create(ConfigFilename, TEncoding.UTF8);
  try
    VideoThumbnailCountHorizontal := ConfigFile.ReadInteger(ConfigKey,
      'VideoThumbnailCountHorizontal', 0);
    VideoThumbnailCountVertical := ConfigFile.ReadInteger(ConfigKey,
      'VideoThumbnailCountVertical', 0);
    VideoThumbnailMaxWidth := ConfigFile.ReadInteger(ConfigKey,
      'VideoThumbnailMaxWidth', 0);
    VideoBigThumbnailCountHorizontal := ConfigFile.ReadInteger(ConfigKey,
      'VideoBigThumbnailCountHorizontal', 0);
    VideoBigThumbnailCountVertical := ConfigFile.ReadInteger(ConfigKey,
      'VideoBigThumbnailCountVertical', 0);
    VideoBigThumbnailMaxWidth := ConfigFile.ReadInteger(ConfigKey,
      'VideoBigThumbnailMaxWidth', 0);
    VideoTimeFormat := ConfigFile.ReadString(ConfigKey, 'VideoTimeFormat', '');
    ImageThumbnailMaxHeight := ConfigFile.ReadInteger(ConfigKey,
      'ImageThumbnailMaxHeight', 0);

    FFMPEGPath := ConfigFile.ReadString(ConfigKey, 'FFMPEGPath', '');
    ImageMagickPath := ConfigFile.ReadString(ConfigKey, 'ImageMagickPath', '');

    FThumbnail := TThumbnail.Create(VideoThumbnailCountHorizontal,
      VideoThumbnailCountVertical, VideoThumbnailMaxWidth, VideoTimeFormat,
      ImageThumbnailMaxHeight, FFMPEGPath, ImageMagickPath);
    FBigThumbnail := TThumbnail.Create(VideoBigThumbnailCountHorizontal,
      VideoBigThumbnailCountVertical, VideoBigThumbnailMaxWidth,
      VideoTimeFormat, ImageThumbnailMaxHeight, FFMPEGPath,
      ImageMagickPath);

    KeyCacheFilename := ConfigFile.ReadString(ConfigKey, 'KeyCacheFilename',
      '');
    FKeyCacheDatabase := TKeyCache.Create(KeyCacheFilename);

    FSourcePath := ConfigFile.ReadString(ConfigKey, 'SourcePath', '');
    FSourceFileExtension := ConfigFile.ReadString(ConfigKey,
      'SourceFileExtension', '');

    FChangelogFilename := ConfigFile.ReadString(ConfigKey, 'ChangelogFilename',
      '');
    FChangelog := TChangelogEntryList.Create(FChangelogFilename);

    FDataPath := ConfigFile.ReadString(ConfigKey, 'DataPath', '');
    FInfoFilename := ConfigFile.ReadString(ConfigKey, 'InfoFilename', '');

    FSitePath := ConfigFile.ReadString(ConfigKey, 'SitePath', '');
    FOutputExtension := ConfigFile.ReadString(ConfigKey, 'OutputExtension', '');
    FThumbnailPath := ConfigFile.ReadString(ConfigKey, 'ThumbnailPath', '');
    FThumbnailExtension := ConfigFile.ReadString(ConfigKey,
      'ThumbnailExtension', '');
    FCRCPath := ConfigFile.ReadString(ConfigKey, 'CRCPath', '');
    FCRCExtension := ConfigFile.ReadString(ConfigKey, 'CRCExtension', '');
    FSFVExtension := ConfigFile.ReadString(ConfigKey, 'SFVExtension', '');
    FSourcePathSite := ConfigFile.ReadString(ConfigKey, 'SourcePathSite', '');
    FIndexFilename := ConfigFile.ReadString(ConfigKey, 'IndexFilename', '');
    FChangelogFilenameSite := ConfigFile.ReadString(ConfigKey,
      'ChangelogFilenameSite', '');
    FStaticFiles := ConfigFile.ReadString(ConfigKey, 'StaticFiles', '');

    FNewKeyName := ConfigFile.ReadString(ConfigKey, 'NewKeyName', '');

    FSiteKey := ConfigFile.ReadString(ConfigKey, 'SiteKey', '');
    FSiteName := ConfigFile.ReadString(ConfigKey, 'SiteName', '');
    FSiteAuthor := ConfigFile.ReadString(ConfigKey, 'SiteAuthor', '');
    FSiteDescription := ConfigFile.ReadString(ConfigKey, 'SiteDescription', '');

    FFiles := TDictionary<string, TFileInfoList>.Create;
  finally
    ConfigFile.Free;
  end;
end;

destructor TSiteBuilder.Destroy;
var
  Key: string;
begin
  if Assigned(FFiles) then
  begin
    for Key in FFiles.Keys do
    begin
      FFiles[Key].Free;
    end;
  end;
  FFiles.Free;

  FChangelog.Free;

  FKeyCacheDatabase.Free;

  FThumbnail.Free;
  FBigThumbnail.Free;

  inherited Destroy;
end;

procedure TSiteBuilder.Run;
var
  Pages: TIndexPageList;
  Page: TIndexPage;
  Files: TFileInfoList;
  InfoContent, CRCFile, SFVFile: string;
begin
  FKeyCacheDatabase.InitUsed;

  ProcessSourceFiles;

  WriteChangelog(FSitePath + PathDelim + FChangelogFilenameSite +
      FOutputExtension, FIndexFilename + FOutputExtension, FChangelog,
    FSiteAuthor, FSiteDescription);

  Pages := TIndexPageList.Create;
  GetPages(Pages);
  try
    WriteIndex(FSitePath + PathDelim + FIndexFilename + FOutputExtension,
      FChangelogFilenameSite + FOutputExtension, FSiteKey, FSiteName,
      FSiteAuthor, FSiteDescription, FChangelog.MaxEdition, Pages);

    for Page in Pages.List do
    begin
      GetFiles(Page.Section, Files);
      InfoContent := GetPageInfo(Page.Section);
      CRCFile := TFileInfo.SectionToUrl(Page.Section, FCRCExtension);
      SFVFile := TFileInfo.SectionToUrl(Page.Section, FSFVExtension);
      WriteContent(FSitePath + PathDelim + Page.URL, Page.Title, InfoContent,
        FIndexFilename + FOutputExtension, Files, FOutputExtension, FSiteKey,
        FCRCPath + TFileInfo.PathDelimiterSite + CRCFile,
        FCRCPath + TFileInfo.PathDelimiterSite + SFVFile,
        FChangelog.MaxEdition, FSiteAuthor, FSiteDescription);
      Files.GenerateCRCFile
        (FSitePath + PathDelim + FCRCPath + PathDelim + CRCFile, CRC);
      Files.GenerateCRCFile
        (FSitePath + PathDelim + FCRCPath + PathDelim + SFVFile, SFV);
    end;

    FKeyCacheDatabase.RemoveUnsed;

    CopyStaticFiles;
  finally
    Pages.Free;
  end;
end;

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

procedure TSiteBuilder.ProcessSourceFiles;
var
  Files: TStringList;
  Filename: string;
begin
  Files := TStringList.Create;
  try
    if not DirectoryExists(FSitePath + PathDelim + FSourcePathSite) then
    begin
      ForceDirectories(FSitePath + PathDelim + FSourcePathSite);
    end;
    CopyFile(PChar(FChangelogFilename),
      PChar(FSitePath + PathDelim + FSourcePathSite + PathDelim +
          ExtractFileName(FChangelogFilename)), False);

    GetFileList(Files);
    for Filename in Files do
    begin
      CopyFile(PChar(FSourcePath + PathDelim + Filename),
        PChar(FSitePath + PathDelim + FSourcePathSite + PathDelim + Filename),
        False);
      ReadAndAddContent(FSourcePath + PathDelim + Filename);
    end;
  finally
    Files.Free;
  end;
end;

procedure TSiteBuilder.GetFileList(var Files: TStringList);
var
  SearchResult: TSearchRec;
begin
  Files.Clear;
  try
    if FindFirst(FSourcePath + PathDelim + '*' + FSourceFileExtension,
      faAnyFile, SearchResult) = 0 then
    begin
      repeat
        if ExtractFileExt(SearchResult.Name) = FSourceFileExtension then
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
  Line, Section: string;
  Stream: TStream;
  IndexSections, IndexKey, IndexOtherFilenames, IndexDescription,
    IndexPlayedMusic, IndexIsNewKey, IndexIsFullThumbnailRequired,
    LineNr: Integer;
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

    IndexSections := -1;
    IndexKey := -1;
    IndexOtherFilenames := -1;
    IndexDescription := -1;
    IndexPlayedMusic := -1;
    IndexIsNewKey := -1;
    IndexIsFullThumbnailRequired := -1;
    LineNr := 0;

    FileContent.LoadFromStream(Stream, TEncoding.UTF8);

    for Line in FileContent do
    begin
      Inc(LineNr);
      if Line <> '' then
      begin
        Split(CSVLine, Line, ',', '"');

        if IndexKey = -1 then
        begin
          IndexSections := ReadColumnIndex(CSVLine, Filename, ColumnSections);
          IndexKey := ReadColumnIndex(CSVLine, Filename, ColumnKey);
          IndexIsNewKey := ReadColumnIndex(CSVLine, Filename, ColumnIsNewKey);
          IndexOtherFilenames := ReadColumnIndex(CSVLine, Filename,
            ColumnOtherFilenames);
          IndexDescription := ReadColumnIndex(CSVLine, Filename,
            ColumnDescription);
          IndexPlayedMusic := ReadColumnIndex(CSVLine, Filename,
            ColumnPlayedMusic);
          IndexIsFullThumbnailRequired := ReadColumnIndex(CSVLine, Filename,
            ColumnIsFullThumbnailRequired);
        end
        else
        begin
          try
            if CSVLine.Count < 2 then
            begin
              TLogger.LogFatal(Format(
                  'To few columns in line %d in the CSV-File "%s". 2 or more columns are required.', [LineNr, Filename]));
            end;

            while CSVLine.Count < 7 do
            begin
              CSVLine.Add('');
            end;

            Split(AltSections, CSVLine[IndexSections], '|');

            if CSVLine[IndexIsNewKey] <> '' then
            begin
              AltSections.Add(FNewKeyName);
            end;

            for Section in AltSections do
            begin
              if not FFiles.ContainsKey(Section) then
              begin
                FFiles.Add(Section, TFileInfoList.Create);
              end;
              AddFile(Section, AltSections, CSVLine[IndexKey],
                CSVLine[IndexIsFullThumbnailRequired] <> '',
                CSVLine[IndexOtherFilenames], CSVLine[IndexDescription],
                CSVLine[IndexPlayedMusic]);
            end;
          except
            on E: EConvertError do
              TLogger.LogFatal(Format('Unable to parse CSV-File "%s".',
                  [Filename]));
          end;
        end;
      end;
    end;
  finally
    FreeAndNil(Stream);
    FreeAndNil(AltSections);
    FreeAndNil(FileContent);
    FreeAndNil(CSVLine);
  end;
end;

procedure TSiteBuilder.AddFile(const Section: string; Sections: TStringList;

  const FileKey: string; const IsFullThumbnailRequired: Boolean;
  const FileOtherNames, Description, AudioTracks: string);
var
  FileInfoList: TFileInfoList;
begin
  FileInfoList := FFiles[Section];

  FileInfoList.Add(TFileInfo.Create(FThumbnail, FBigThumbnail,
      FKeyCacheDatabase, FDataPath, FSitePath,
      FThumbnailExtension, FThumbnailPath, FCRCExtension, Section, Sections,
      FileKey, IsFullThumbnailRequired, FileOtherNames, Description,
      AudioTracks));

  FFiles[Section] := FileInfoList;
end;

procedure TSiteBuilder.GetPages(var Pages: TIndexPageList);
var
  Section: string;
begin
  for Section in FFiles.Keys do
  begin
    if Section <> FNewKeyName then
    begin
      Pages.Add(TIndexPage.Create(Section, FOutputExtension));
    end;
  end;
  Pages.Sort;
  Pages.AddFirst(TIndexPage.Create(FNewKeyName, FOutputExtension));
end;

procedure TSiteBuilder.GetFiles(const Page: string; var Files: TFileInfoList);
begin
  Files := FFiles[Page];
  Files.Sort;
end;

function TSiteBuilder.GetPageInfo(const Page: string): string;
var
  InfoFile: string;
  FileContent: TStringList;
  Stream: TStream;
begin
  Result := '';
  InfoFile := FDataPath + PathDelim + TFileInfo.SectionToPath(Page)
    + PathDelim + FInfoFilename;

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
      if Length(Result) = 0 then
      begin
        TLogger.LogError('Empty info-file!');
      end;
    finally
      FreeAndNil(FileContent);
      FreeAndNil(Stream);
    end;
  end;
end;

end.
