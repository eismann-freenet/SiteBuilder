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

unit SiteBuilder;

interface

uses
  Classes, FileInfoList, IndexPageList, KeyCache, Thumbnail, Changelog,
  DuplicateTree, FileInfoTree, BookmarksParser;

const
  ConfigKey = 'SiteBuilder';

type
  TSiteBuilder = class

  strict private
    FThumbnail: TThumbnail;
    FBigThumbnail: TThumbnail;

    FKeyCacheDatabase: TKeyCache;

    FBookmarksParser: TBookmarksParser;

    FContentPath: string;
    FContentFileExtension: string;

    FDuplicatePath: string;
    FDuplicateFileExtension: string;

    FChangelogFilename: string;
    FChangelog: TChangelog;

    FDataPath: string;
    FInfoFilename: string;

    FSitePath: string;
    FSiteAuthor: string;
    FSiteDescription: string;
    FSiteKeywords: string;
    FOutputExtension: string;

    FThumbnailPath: string;
    FThumbnailExtension: string;

    FCRCPath: string;
    FCRCExtension: string;
    FSFVExtension: string;

    FSourceFolderSite: string;
    FContentFolderSite: string;
    FDuplicateFolderSite: string;

    FIndexFilename: string;
    FChangelogFilenameSite: string;
    FStaticFiles: string;
    FNewKeyName: string;

    FSiteKey: string;
    FSiteName: string;

    FDuplicateTree: TDuplicateTree;
    FFileInfoTree: TFileInfoTree;

    procedure ProcessSourceFiles;
    procedure GetPages(var Pages: TIndexPageList);
    procedure GetFiles(const Page: string; var Files: TFileInfoList);
    function GetPageInfo(const Page: string): string;
    procedure ProcessStaticFiles;

  public
    constructor Create(const ConfigFilename: string);
    destructor Destroy; override;
    procedure Run;

    // For DuplicateChecker
    class procedure GetFileList(const Path: string; const Extension: string;
      const IsRequired: Boolean; var Files: TStringList);
  end;

implementation

uses
  SysUtils, FileInfo, IndexPage, Logger, IniFiles,
  TemplateChangelog, TemplateIndex, TemplateContent, SystemCall, CSVFile,
  DuplicateList, Generics.Collections, StringReplacer, Key, SiteEncoding;

{ TSiteBuilder }

constructor TSiteBuilder.Create(const ConfigFilename: string);
var
  VideoThumbnailCountHorizontal, VideoThumbnailCountVertical,
    VideoThumbnailMaxWidth, VideoBigThumbnailCountHorizontal,
    VideoBigThumbnailCountVertical, VideoBigThumbnailMaxWidth,
    ImageThumbnailMaxHeight: Integer;
  VideoTimeFormat, FFMPEGPath, ImageMagickPath, KeyCacheFilename,
    BookmarksParserFilename: string;
  ConfigFile: TMemIniFile;
begin
  if not FileExists(ConfigFilename) then
  begin
    raise Exception.CreateFmt('Configuration-File "%s" is missing!',
      [ConfigFilename]);
  end;

  ConfigFile := TMemIniFile.Create(ConfigFilename, TEncoding.UTF8);
  try
    VideoThumbnailCountHorizontal := ConfigFile.ReadInteger(ConfigKey,
      'VideoThumbnailCountHorizontal', 4);
    VideoThumbnailCountVertical := ConfigFile.ReadInteger(ConfigKey,
      'VideoThumbnailCountVertical', 1);
    VideoThumbnailMaxWidth := ConfigFile.ReadInteger(ConfigKey,
      'VideoThumbnailMaxWidth', 992);
    VideoBigThumbnailCountHorizontal := ConfigFile.ReadInteger(ConfigKey,
      'VideoBigThumbnailCountHorizontal', 4);
    VideoBigThumbnailCountVertical := ConfigFile.ReadInteger(ConfigKey,
      'VideoBigThumbnailCountVertical', 4);
    VideoBigThumbnailMaxWidth := ConfigFile.ReadInteger(ConfigKey,
      'VideoBigThumbnailMaxWidth', 1024);
    VideoTimeFormat := ConfigFile.ReadString(ConfigKey, 'VideoTimeFormat',
      '%.2d:%.2d:%.2d');
    ImageThumbnailMaxHeight := ConfigFile.ReadInteger(ConfigKey,
      'ImageThumbnailMaxHeight', 186);

    FFMPEGPath := ConfigFile.ReadString(ConfigKey, 'FFMPEGPath',
      '.\programs\FFmpeg\bin\');
    ImageMagickPath := ConfigFile.ReadString(ConfigKey, 'ImageMagickPath',
      '.\programs\ImageMagick\');

    FThumbnail := TThumbnail.Create(VideoThumbnailCountHorizontal,
      VideoThumbnailCountVertical, VideoThumbnailMaxWidth, VideoTimeFormat,
      ImageThumbnailMaxHeight, FFMPEGPath, ImageMagickPath);
    FBigThumbnail := TThumbnail.Create(VideoBigThumbnailCountHorizontal,
      VideoBigThumbnailCountVertical, VideoBigThumbnailMaxWidth,
      VideoTimeFormat, ImageThumbnailMaxHeight, FFMPEGPath,
      ImageMagickPath);

    KeyCacheFilename := ConfigFile.ReadString(ConfigKey, 'KeyCacheFilename',
      '.\key-cache.db3');
    FKeyCacheDatabase := TKeyCache.Create(KeyCacheFilename);

    FContentPath := ConfigFile.ReadString(ConfigKey, 'ContentPath',
      '.\data\content');
    FContentFileExtension := ConfigFile.ReadString(ConfigKey,
      'ContentFileExtension', '.csv');

    FDuplicatePath := ConfigFile.ReadString(ConfigKey, 'DuplicatePath',
      '.\data\duplicate');
    FDuplicateFileExtension := ConfigFile.ReadString(ConfigKey,
      'DuplicateFileExtension', '.csv');

    FChangelogFilename := ConfigFile.ReadString(ConfigKey, 'ChangelogFilename',
      '.\data\Changelog.csv');
    FChangelog := TChangelog.Create(FChangelogFilename);

    FDataPath := ConfigFile.ReadString(ConfigKey, 'DataPath', '.\data-files');
    FInfoFilename := ConfigFile.ReadString(ConfigKey, 'InfoFilename',
      'Info.txt');

    FSitePath := ConfigFile.ReadString(ConfigKey, 'SitePath', '.\site');
    FOutputExtension := ConfigFile.ReadString(ConfigKey, 'OutputExtension',
      '.htm');

    FThumbnailPath := ConfigFile.ReadString(ConfigKey, 'ThumbnailPath',
      'Thumbnails');
    FThumbnailExtension := ConfigFile.ReadString(ConfigKey,
      'ThumbnailExtension', '.jpg');

    FCRCPath := ConfigFile.ReadString(ConfigKey, 'CRCPath', 'CRCs');
    FCRCExtension := ConfigFile.ReadString(ConfigKey, 'CRCExtension', '.csv');
    FSFVExtension := ConfigFile.ReadString(ConfigKey, 'SFVExtension', '.sfv');

    FSourceFolderSite := ConfigFile.ReadString(ConfigKey, 'SourceFolderSite',
      'Sources');
    FContentFolderSite := ConfigFile.ReadString(ConfigKey, 'ContentFolderSite',
      'Content');
    FDuplicateFolderSite := ConfigFile.ReadString(ConfigKey,
      'DuplicateFolderSite', 'Duplicate');

    FIndexFilename := ConfigFile.ReadString(ConfigKey, 'IndexFilename',
      'index');
    FChangelogFilenameSite := ConfigFile.ReadString(ConfigKey,
      'ChangelogFilenameSite', 'changelog');
    FStaticFiles := ConfigFile.ReadString(ConfigKey, 'StaticFiles',
      'design.css|activelink.png|about.htm');

    FNewKeyName := ConfigFile.ReadString(ConfigKey, 'NewKeyName', 'New Keys');

    FSiteKey := ConfigFile.ReadString(ConfigKey, 'SiteKey',
      'USK@yoursitekey/site/');
    FSiteName := ConfigFile.ReadString(ConfigKey, 'SiteName', 'MySite');
    FSiteAuthor := ConfigFile.ReadString(ConfigKey, 'SiteAuthor', 'MyName');
    FSiteDescription := ConfigFile.ReadString(ConfigKey, 'SiteDescription',
      'Some nice freesite');
    FSiteKeywords := ConfigFile.ReadString(ConfigKey, 'SiteKeywords',
      'keyword1, keyword2'); ;

    BookmarksParserFilename := ConfigFile.ReadString(ConfigKey,
      'Bookmarks-File', '.\bookmarks.dat');

    FDuplicateTree := TDuplicateTree.Create;
    FFileInfoTree := TFileInfoTree.Create;

    TLogger.LogInfo(Format('Read Bookmarks-File "%s"',
        [BookmarksParserFilename]));
    if not FileExists(BookmarksParserFilename) then
    begin
      TLogger.LogError(Format('Bookmarks-File "%s" is missing!',
          [BookmarksParserFilename]));
    end;
    FBookmarksParser := TBookmarksParser.Create(BookmarksParserFilename,
      TEncoding.UTF8);
  finally
    ConfigFile.Free;
  end;
end;

destructor TSiteBuilder.Destroy;
begin
  FDuplicateTree.Free;
  FFileInfoTree.Free;

  FChangelog.Free;

  FKeyCacheDatabase.Free;

  FThumbnail.Free;
  FBigThumbnail.Free;

  FBookmarksParser.Free;

  inherited Destroy;
end;

procedure TSiteBuilder.Run;
var
  InfoContent, FullCRCPath, CRCFile, SFVFile: string;
  Pages: TIndexPageList;
  Files: TFileInfoList;
  Page: TIndexPage;
begin
  FKeyCacheDatabase.InitUsed;

  ProcessSourceFiles;

  WriteChangelog(FSitePath + PathDelim + FChangelogFilenameSite +
      FOutputExtension, FIndexFilename + FOutputExtension, FChangelog,
    FSiteAuthor, FSiteDescription, FSiteKeywords);

  Pages := TIndexPageList.Create;
  GetPages(Pages);
  try
    WriteIndex(FSitePath + PathDelim + FIndexFilename + FOutputExtension,
      FChangelogFilenameSite + FOutputExtension, FSiteKey, FSiteName,
      FSiteAuthor, FSiteDescription, FSiteKeywords, FChangelog.MaxEdition,
      Pages);

    FullCRCPath := FSitePath + PathDelim + FCRCPath + PathDelim;
    for Page in Pages do
    begin
      GetFiles(Page.Section, Files);
      InfoContent := GetPageInfo(Page.Section);
      CRCFile := TFileInfo.SectionToUrl(Page.Section, FCRCExtension);
      SFVFile := TFileInfo.SectionToUrl(Page.Section, FSFVExtension);
      WriteContent(Page.Section, FSitePath + PathDelim + Page.URL, Page.Title,
        InfoContent, FIndexFilename + FOutputExtension, Files,
        FOutputExtension, FSiteKey, FCRCPath + TFileInfo.PathDelimiterSite,
        CRCFile, SFVFile, FChangelog.MaxEdition, FSiteAuthor, FSiteDescription,
        FSiteKeywords);
      Files.GenerateCRCFile(FullCRCPath + CRCFile, CRC);
      Files.GenerateCRCFile(FullCRCPath + SFVFile, SFV);
    end;

    FKeyCacheDatabase.RemoveUnsed;

    ProcessStaticFiles;
  finally
    Pages.Free;
  end;

end;

procedure TSiteBuilder.ProcessStaticFiles;
var
  Replacer: TDictionary<string, string>;
  Key, SearchPattern, StaticFile: string;
  StreamIn, StreamOut: TStream;
  StaticFileList: TStringList;
  FileInfoList: TFileInfoList;
  FileContent: TStringList;
  FileInfo: TFileInfo;
begin
  Replacer := TDictionary<string, string>.Create;

  try
    // Scan FileInfoTree for USKs and add them to the replacer-dictionary
    for Key in FFileInfoTree.Keys do
    begin
      FileInfoList := FFileInfoTree[Key];
      for FileInfo in FileInfoList do
      begin
        SearchPattern := '{link:' + FileInfo.Key.KeyWitoutEdition + '}';
        if (FileInfo.Key.KeyType = USK) and
          (not Replacer.ContainsKey(SearchPattern)) then
        begin
          Replacer.Add(SearchPattern, TStringReplacer.FormatKey(FileInfo.Key,
              FileInfo.Description));
        end;
      end;
    end;

    StaticFileList := TStringList.Create;
    try
      TCSVFile.Split(StaticFileList, FStaticFiles, '|');
      for StaticFile in StaticFileList do
      begin
        if not FileExists(StaticFile) then
        begin
          raise Exception.CreateFmt('Static file "%s" is missing!',
            [StaticFile]);
        end;

        if not(TFileInfo.DetectType(StaticFile) in [Image, Movie, Archive]) then
        begin
          StreamIn := nil;
          StreamOut := nil;
          FileContent := nil;

          try
            StreamIn := TFileStream.Create(StaticFile,
              fmOpenRead or fmShareDenyNone);
            StreamOut := TFileStream.Create(FSitePath + PathDelim + StaticFile,
              fmCreate or fmShareExclusive);

            FileContent := TStringList.Create;

            FileContent.LoadFromStream(StreamIn, TEncoding.UTF8);

            FileContent.Text := TStringReplacer.ReplaceWithDictionary
              (FileContent.Text, Replacer);

            FileContent.SaveToStream(StreamOut, TSiteEncoding.Encoding);
          finally
            FileContent.Free;
            StreamIn.Free;
            StreamOut.Free;
          end;
        end
        else
        begin
          CopyFile(StaticFile, FSitePath + PathDelim + StaticFile);
        end;
      end;
    finally
      StaticFileList.Free;
    end;
  finally
    Replacer.Free;
  end;
end;

procedure TSiteBuilder.ProcessSourceFiles;
var
  ContentFiles, DuplicateFiles: TStringList;
  SourcePath, Filename, Key: string;
begin
  SourcePath := FSitePath + PathDelim + FSourceFolderSite + PathDelim;

  ForceDirectories(SourcePath + FContentFolderSite);
  ForceDirectories(SourcePath + FDuplicateFolderSite);

  CopyFile(FChangelogFilename,
    SourcePath + ExtractFileName(FChangelogFilename));

  DuplicateFiles := TStringList.Create;
  try
    GetFileList(FDuplicatePath, FDuplicateFileExtension, False, DuplicateFiles);
    FDuplicateTree.LoadData(DuplicateFiles);

    for Filename in DuplicateFiles do
    begin
      CopyFile(Filename,
        SourcePath + FDuplicateFolderSite + PathDelim + ExtractFileName
          (Filename));
    end;
  finally
    DuplicateFiles.Free;
  end;

  ContentFiles := TStringList.Create;
  try
    GetFileList(FContentPath, FContentFileExtension, True, ContentFiles);
    FFileInfoTree.LoadData(ContentFiles, FThumbnail, FBigThumbnail,
      FKeyCacheDatabase, FBookmarksParser, FNewKeyName, FDataPath, FSitePath,
      FThumbnailExtension, FThumbnailPath, FCRCExtension, FDuplicateTree);
    for Filename in ContentFiles do
    begin
      CopyFile(Filename,
        SourcePath + FContentFolderSite + PathDelim + ExtractFileName(Filename)
        );
    end;
  finally
    ContentFiles.Free;
  end;

  // Check for unused duplicates
  for Key in FDuplicateTree.Keys do
  begin
    if not FDuplicateTree[Key].IsUsed then
    begin
      TLogger.LogError(Format('Duplicates for key "%s" were not used!', [Key]));
    end;
  end;
end;

class procedure TSiteBuilder.GetFileList(const Path: string;
  const Extension: string; const IsRequired: Boolean; var Files: TStringList);
var
  SearchResult: TSearchRec;
begin
  Files.Clear;
  try
    if FindFirst(Path + PathDelim + '*' + Extension, faAnyFile, SearchResult)
      = 0 then
    begin
      repeat
        if ExtractFileExt(SearchResult.Name) = Extension then
        begin
          Files.Add(Path + PathDelim + SearchResult.Name);
        end;
      until FindNext(SearchResult) <> 0;
    end;
  finally
    SysUtils.FindClose(SearchResult);

    if (Files.Count = 0) and IsRequired then
    begin
      raise Exception.CreateFmt
        ('No input-files were found in the folder "%s"!', [Path]);
    end;
  end;
end;

procedure TSiteBuilder.GetPages(var Pages: TIndexPageList);
var
  Section: string;
begin
  for Section in FFileInfoTree.Keys do
  begin
    if (Section <> FNewKeyName) and (Section <> '') then
    begin
      Pages.Add(TIndexPage.Create(Section, FOutputExtension));
    end;
  end;
  Pages.Sort;
  if FFileInfoTree.ContainsKey(FNewKeyName) then
  begin
    Pages.AddFirst(TIndexPage.Create(FNewKeyName, FOutputExtension));
  end;
end;

procedure TSiteBuilder.GetFiles(const Page: string; var Files: TFileInfoList);
begin
  Files := FFileInfoTree[Page];
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
    TLogger.LogInfo(Format('Read "%s"', [InfoFile]));
    FileContent := nil;
    Stream := nil;

    try
      FileContent := TStringList.Create;
      Stream := TFileStream.Create(InfoFile, fmOpenRead or fmShareDenyNone);
      FileContent.LoadFromStream(Stream, TEncoding.UTF8);
      Result := Trim(FileContent.Text);
      Result := TStringReplacer.ReplaceSpecialChars(Result);
      Result := TStringReplacer.ReplaceNewLine(Result);
      if Length(Result) = 0 then
      begin
        raise Exception.CreateFmt('No content found in file "%s"!', [InfoFile]);
      end;
    finally
      FreeAndNil(FileContent);
      FreeAndNil(Stream);
    end;
  end;
end;

end.
