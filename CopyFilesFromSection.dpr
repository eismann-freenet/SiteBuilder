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

program CopyFilesFromSection;
{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
  IOUtils,
  FileInfo in 'FileInfo.pas',
  FileInfoTree in 'FileInfoTree.pas',
  KeyCache in 'KeyCache.pas',
  Logger in 'Logger.pas',
  SiteBuilder in 'SiteBuilder.pas',
  Thumbnail in 'Thumbnail.pas',
  DuplicateTree in 'DuplicateTree.pas',
  BookmarksParser in 'BookmarksParser.pas',
  Key in 'Key.pas',
  Config in 'Config.pas';
{$R *.res}

var
  ConfigFile, SourceFile, Section, TargetPath: string;
  ContentPath, ContentFileExtension, VideoTimeFormat, FFMPEGPath,
    ImageMagickPath, KeyCacheFile, BookmarksParserFilename, NewKeyName,
    DataPath, SitePath, ThumbnailPath, ThumbnailExtension,
    CRCPath: string;
  VideoThumbnailCountHorizontal, VideoThumbnailCountVertical,
    VideoThumbnailMaxWidth, ImageThumbnailMaxHeight, ThumbnailQuality: Integer;
  Files: TStringList;
  FileInfoTree: TFileInfoTree;
  FileInfo: TFileInfo;
  Thumbnail: TThumbnail;
  KeyCache: TKeyCache;
  DuplicateTree: TDuplicateTree;
  BookmarksParser: TBookmarksParser;
  Config: TConfig;

begin
  try
    ConfigFile := ParamStr(1);
    if ConfigFile = '' then
    begin
      raise Exception.Create
        ('Parameter 1 have to be a configuration filename!');
    end;

    Section := ParamStr(2);
    if Section = '' then
    begin
      raise Exception.Create('Parameter 2 have to be a section!');
    end;

    TargetPath := ParamStr(3);
    if TargetPath = '' then
    begin
      raise Exception.Create('Parameter 3 have to be a target path!');
    end;

    if not DirectoryExists(TargetPath) then
    begin
      TLogger.LogInfo(Format('Create directory "%s"...', [TargetPath]));
      ForceDirectories(TargetPath);
    end;

    Config := nil;
    Files := nil;
    Thumbnail := nil;
    KeyCache := nil;
    BookmarksParser := nil;
    DuplicateTree := nil;
    FileInfoTree := nil;
    try
      Config := TConfig.Create(ConfigFile);

      ContentPath := Config.ReadString(CONTENT_PATH);
      ContentFileExtension := Config.ReadString(CONTENT_FILE_EXTENSION);
      Files := TStringList.Create;
      TSiteBuilder.GetFileList(ContentPath, ContentFileExtension, false, Files);

      VideoThumbnailCountHorizontal := Config.ReadInteger
        (VIDEO_THUMBNAIL_COUNT_HORIZONTAL);
      VideoThumbnailCountVertical := Config.ReadInteger
        (VIDEO_THUMBNAIL_COUNT_VERTICAL);
      VideoThumbnailMaxWidth := Config.ReadInteger(VIDEO_THUMBNAIL_MAX_WIDTH);
      VideoTimeFormat := Config.ReadString(VIDEO_TIME_FORMAT);
      ImageThumbnailMaxHeight := Config.ReadInteger(IMAGE_THUMBNAIL_MAX_HEIGHT);
      ThumbnailQuality := Config.ReadInteger(THUMBNAIL_QUALITY);
      FFMPEGPath := Config.ReadString(FFMPEG_PATH);
      ImageMagickPath := Config.ReadString(IMAGEMAGICK_PATH);
      Thumbnail := TThumbnail.Create(VideoThumbnailCountHorizontal,
        VideoThumbnailCountVertical, VideoThumbnailMaxWidth, VideoTimeFormat,
        ImageThumbnailMaxHeight, ThumbnailQuality, FFMPEGPath, ImageMagickPath);

      KeyCacheFile := Config.ReadString(KEY_CACHE_FILENAME);
      KeyCache := TKeyCache.Create(KeyCacheFile);

      BookmarksParserFilename := Config.ReadString(BOOKMARKS_FILE);
      BookmarksParser := TBookmarksParser.Create(BookmarksParserFilename,
        TEncoding.UTF8);

      DuplicateTree := TDuplicateTree.Create;

      NewKeyName := Config.ReadString(NEW_KEY_NAME);
      DataPath := Config.ReadString(DATA_PATH);
      SitePath := Config.ReadString(SITE_PATH);
      ThumbnailPath := Config.ReadString(THUMBNAIL_PATH);
      ThumbnailExtension := Config.ReadString(THUMBNAIL_EXTENSION);
      CRCPath := Config.ReadString(CRC_PATH);
      FileInfoTree := TFileInfoTree.Create;
      FileInfoTree.LoadData(Files, Thumbnail, Thumbnail, KeyCache,
        BookmarksParser, NewKeyName, DataPath, SitePath, ThumbnailExtension,
        ThumbnailPath, CRCPath, DuplicateTree);

      if not FileInfoTree.ContainsKey(Section) then
      begin
        raise Exception.CreateFmt('Section "%s" was not found!', [Section]);
      end;
      for FileInfo in FileInfoTree[Section] do
      begin
        SourceFile := DataPath + PathDelim + TFileInfo.SectionToPath
          (FileInfo.Sections[0]) + PathDelim + FileInfo.Key.FileName;
        if FileInfo.Key.KeyType = USK then
        begin
          continue;
        end;
        if not FileExists(TargetPath + PathDelim + FileInfo.Key.FileName) then
        begin
          TLogger.LogInfo(Format('Copy file "%s" to "%s"...', [SourceFile,
              TargetPath]));
          TFile.Copy(SourceFile,
            TargetPath + PathDelim + FileInfo.Key.FileName);
        end
        else
        begin
          TLogger.LogError(Format(
              'TargetFile "%s" exists! File will be skipped!',
              [TargetPath + PathDelim + FileInfo.Key.FileName]));
        end;
      end;

    finally
      Config.Free;
      Files.Free;
      Thumbnail.Free;
      KeyCache.Free;
      BookmarksParser.Free;
      DuplicateTree.Free;
      FileInfoTree.Free;
    end;
  except
    on E: Exception do
      TLogger.LogFatal(E.Message);
  end;

  writeln('Press ENTER to exit...');
  readln;

end.
