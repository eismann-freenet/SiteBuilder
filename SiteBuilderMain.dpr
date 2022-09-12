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

program SiteBuilderMain;
{$APPTYPE CONSOLE}

uses
  SysUtils,
  IniFiles,
  Classes,
  FileInfo in 'FileInfo.pas',
  SiteBuilder in 'SiteBuilder.pas',
  TemplateIndex in 'TemplateIndex.pas',
  TemplateContent in 'TemplateContent.pas',
  Tools in 'Tools.pas',
  IndexPage in 'IndexPage.pas',
  ChangelogEntry in 'ChangelogEntry.pas',
  TemplateChangelog in 'TemplateChangelog.pas',
  FileInfoList in 'FileInfoList.pas',
  IndexPageList in 'IndexPageList.pas',
  Logger in 'Logger.pas';

{$R *.res}

const
  ConfigKey = 'SiteBuilder';
  ConfigFilename = '.\Options.ini';

var
  ConfigFile: TIniFile;
  SiteBuilder: TSiteBuilder;
  Files: TFileInfoList;
  Pages: TIndexPageList;
  Page: TIndexPage;
  Changelog: TChangelogEntryList;
  DataPath, ChangelogSourceFile, SitePath, CSVPath, MTNCommand, MTNInfoPattern,
    ImageMagickCommand, ThumbnailExt, ThumbnailInfoExt, ThumbnailPath,
    ThumbnailInfoPath, OutputExtension, IndexFile, ChangelogFile, InfoFile,
    InputFilesExtension, InfoContent, SiteKey, SiteName, StaticFiles: string;

begin
  ConfigFile := nil;
  SiteBuilder := nil;
  Pages := nil;
  Changelog := nil;

  try
    ConfigFile := TIniFile.Create(ConfigFilename);

    DataPath := ConfigFile.ReadString(ConfigKey, 'DataPath', '');
    ChangelogSourceFile := ConfigFile.ReadString(ConfigKey,
      'ChangelogSourceFile', '');
    SitePath := ConfigFile.ReadString(ConfigKey, 'SitePath', '');
    CSVPath := ConfigFile.ReadString(ConfigKey, 'CSVPath', '');
    InputFilesExtension := ConfigFile.ReadString(ConfigKey,
      'InputFilesExtension', '');
    MTNCommand := ConfigFile.ReadString(ConfigKey, 'MTNCommand', '');
    MTNInfoPattern := ConfigFile.ReadString(ConfigKey, 'MTNInfoPattern', '');
    ImageMagickCommand := ConfigFile.ReadString(ConfigKey,
      'ImageMagickCommand', '');
    ThumbnailExt := ConfigFile.ReadString(ConfigKey, 'ThumbnailExt', '');
    ThumbnailInfoExt := ConfigFile.ReadString(ConfigKey, 'ThumbnailInfoExt',
      '');
    ThumbnailPath := ConfigFile.ReadString(ConfigKey, 'ThumbnailPath', '');
    ThumbnailInfoPath := ConfigFile.ReadString(ConfigKey, 'ThumbnailInfoPath',
      '');
    OutputExtension := ConfigFile.ReadString(ConfigKey, 'OutputExtension', '');
    IndexFile := ConfigFile.ReadString(ConfigKey, 'IndexFile', '');
    ChangelogFile := ConfigFile.ReadString(ConfigKey, 'ChangelogFile', '');
    InfoFile := ConfigFile.ReadString(ConfigKey, 'InfoFile', '');
    SiteKey := ConfigFile.ReadString(ConfigKey, 'SiteKey', '');
    SiteName := ConfigFile.ReadString(ConfigKey, 'SiteName', '');
    StaticFiles := ConfigFile.ReadString(ConfigKey, 'StaticFiles', '');

    SiteBuilder := TSiteBuilder.Create(DataPath, ChangelogSourceFile, SitePath,
      MTNCommand, MTNInfoPattern, ImageMagickCommand, ThumbnailExt,
      ThumbnailInfoExt, ThumbnailPath, ThumbnailInfoPath, InfoFile, CSVPath,
      InputFilesExtension, OutputExtension, StaticFiles);

    SiteBuilder.ProcessCSVFiles;

    SiteBuilder.CopyStaticFiles;

    Pages := TIndexPageList.Create;
    SiteBuilder.GetPages(Pages);
    WriteIndex(SitePath + PathDelim + IndexFile + OutputExtension,
      ChangelogFile + OutputExtension, SiteKey, SiteName, Pages);

    Changelog := TChangelogEntryList.Create;
    SiteBuilder.GetChangelog(Changelog);
    WriteChangelog(SitePath + PathDelim + ChangelogFile + OutputExtension,
      IndexFile + OutputExtension, Changelog);

    for Page in Pages.GetContent do
    begin
      SiteBuilder.GetFiles(Page.Section, Files);
      InfoContent := SiteBuilder.GetPageInfo(Page.Section);
      WriteContent(SitePath + PathDelim + Page.URL, Page.Title, InfoContent,
        IndexFile + OutputExtension, Files);
    end;

  finally
    FreeAndNil(Changelog);
    FreeAndNil(Pages);
    FreeAndNil(SiteBuilder);
    FreeAndNil(ConfigFile);
  end;

  writeln('Press ENTER to exit...');
  readln;

end.
