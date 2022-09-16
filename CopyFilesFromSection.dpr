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

program CopyFilesFromSection;
{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
  IniFiles,
  IOUtils,
  FileInfo in 'FileInfo.pas',
  FileInfoList in 'FileInfoList.pas',
  FileInfoTree in 'FileInfoTree.pas',
  KeyCache in 'KeyCache.pas',
  Logger in 'Logger.pas',
  SiteBuilder in 'SiteBuilder.pas',
  Thumbnail in 'Thumbnail.pas',
  DuplicateEntry in 'DuplicateEntry.pas',
  DuplicateList in 'DuplicateList.pas',
  DuplicateTree in 'DuplicateTree.pas',
  BookmarksParser in 'BookmarksParser.pas',
  Key in 'Key.pas';
{$R *.res}

const
  ConfigKey = 'SiteBuilder';
  ConfigFilename = '.\Options.ini';

var
  SourceFile, ExePath, Section, TargetPath: string;
  Files: TStringList;
  FileInfoTree: TFileInfoTree;
  FileInfo: TFileInfo;
  ConfigFile: TMemIniFile;
  Thumbnail: TThumbnail;
  KeyCacheDatabase: TKeyCache;
  DuplicateTree: TDuplicateTree;
  BookmarksParser: TBookmarksParser;

begin
  try
    ExePath := ExtractFilePath(ParamStr(0));
    Section := ParamStr(1);
    TargetPath := ParamStr(2);

    if Section = '' then
    begin
      raise Exception.Create('Param 1 have to be a Section!');
    end;

    if TargetPath = '' then
    begin
      raise Exception.Create('Param 2 have to be a TargetPath!');
    end;

    if not DirectoryExists(TargetPath) then
    begin
      TLogger.LogInfo(Format('Create directory "%s"...', [TargetPath]));
      ForceDirectories(TargetPath);
    end;

    if not FileExists(ConfigFilename) then
    begin
      raise Exception.CreateFmt('Configuration-File "%s" is missing!',
        [ConfigFilename]);
    end;

    Files := nil;
    BookmarksParser := nil;
    ConfigFile := nil;
    KeyCacheDatabase := nil;
    Thumbnail := nil;
    DuplicateTree := nil;
    try
      Files := TStringList.Create;
      DuplicateTree := TDuplicateTree.Create;
      ConfigFile := TMemIniFile.Create(ConfigFilename, TEncoding.UTF8);

      KeyCacheDatabase := TKeyCache.Create(ConfigFile.ReadString(ConfigKey,
          'KeyCacheFilename', '.\key-cache.db3'));

      Thumbnail := TThumbnail.Create(4, 4, 1024, '%.2d:%.2d:%.2d', 186,
        ExePath + 'programs\ffmpeg\bin\',
        ExePath + 'programs\ImageMagick\');

      BookmarksParser := TBookmarksParser.Create
        (ConfigFile.ReadString(ConfigKey, 'Bookmarks-File',
          '.\bookmarks.dat'), TEncoding.UTF8);

      TSiteBuilder.GetFileList(ExePath + 'data\content', '.csv', false, Files);

      FileInfoTree := TFileInfoTree.Create;
      FileInfoTree.LoadData(Files, Thumbnail, Thumbnail, KeyCacheDatabase,
        BookmarksParser, ConfigFile.ReadString(ConfigKey, 'NewKeyName',
          'New Keys'), ConfigFile.ReadString(ConfigKey, 'DataPath',
          '.\data-files'), ConfigFile.ReadString(ConfigKey, 'SitePath',
          '.\site'), ConfigFile.ReadString(ConfigKey,
          'ThumbnailExtension', '.jpg'), ConfigFile.ReadString(ConfigKey,
          'ThumbnailPath', 'Thumbnails'), ConfigFile.ReadString(ConfigKey,
          'CRCPath', 'CRCs'), DuplicateTree);

      for FileInfo in FileInfoTree[Section] do
      begin
        SourceFile := ConfigFile.ReadString(ConfigKey, 'DataPath',
          '.\data-files') + PathDelim + TFileInfo.SectionToPath
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
      BookmarksParser.Free;
      Files.Free;
      ConfigFile.Free;
      KeyCacheDatabase.Free;
      Thumbnail.Free;
      DuplicateTree.Free;
    end;
  except
    on E: Exception do
      TLogger.LogFatal(E.Message);
  end;

  writeln('Press ENTER to exit...');
  readln;

end.
