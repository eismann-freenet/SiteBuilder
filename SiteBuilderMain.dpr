﻿{
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

program SiteBuilderMain;
{$APPTYPE CONSOLE}

uses
  BookmarksParser in 'BookmarksParser.pas',
  Changelog in 'Changelog.pas',
  ChangelogEntry in 'ChangelogEntry.pas',
  CRC32 in 'CRC32.pas',
  CSVFile in 'CSVFile.pas',
  DuplicateEntry in 'DuplicateEntry.pas',
  DuplicateEntryComparer in 'DuplicateEntryComparer.pas',
  DuplicateList in 'DuplicateList.pas',
  DuplicateTree in 'DuplicateTree.pas',
  FileInfo in 'FileInfo.pas',
  FileInfoComparer in 'FileInfoComparer.pas',
  FileInfoList in 'FileInfoList.pas',
  FileInfoTree in 'FileInfoTree.pas',
  IndexPage in 'IndexPage.pas',
  IndexPageComparer in 'IndexPageComparer.pas',
  IndexPageList in 'IndexPageList.pas',
  Key in 'Key.pas',
  KeyCache in 'KeyCache.pas',
  Logger in 'Logger.pas',
  RegEx in 'RegEx.pas',
  SiteBuilder in 'SiteBuilder.pas',
  SiteEncoding in 'SiteEncoding.pas',
  Sort in 'Sort.pas',
  StringReplacer in 'StringReplacer.pas',
  SystemCall in 'SystemCall.pas',
  TemplateChangelog in 'TemplateChangelog.pas',
  TemplateContent in 'TemplateContent.pas',
  TemplateIndex in 'TemplateIndex.pas',
  Thumbnail in 'Thumbnail.pas',
  UTF8EncodingNoBOM in 'UTF8EncodingNoBOM.pas',
  SysUtils,
  Config in 'Config.pas';

{$R *.res}

var
  SiteBuilder: TSiteBuilder;
  ExePath: string;

begin
  try
    ExePath := ExtractFilePath(ParamStr(0));
    SiteBuilder := TSiteBuilder.Create(ExePath + 'Options.ini');
    try
      SiteBuilder.Run;
    finally
      SiteBuilder.Free;
    end;
  except
    on E: Exception do
      TLogger.LogFatal(E.Message);
  end;
  writeln('Press ENTER to exit...');
  readln;

end.
