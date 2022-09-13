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

program SiteBuilderMain;
{$APPTYPE CONSOLE}

uses
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
  Logger in 'Logger.pas',
  Thumbnail in 'Thumbnail.pas',
  KeyCache in 'KeyCache.pas',
  SystemCall in 'SystemCall.pas',
  StringReplacer in 'StringReplacer.pas',
  ChangelogEntryList in 'ChangelogEntryList.pas',
  CRC32 in 'CRC32.pas',
  SysUtils,
  RegEx in 'RegEx.pas',
  UTF8EncodingNoBOM in 'UTF8EncodingNoBOM.pas',
  SiteEncoding in 'SiteEncoding.pas';
{$R *.res}

const
  ConfigFilename = '.\Options.ini';

var
  SiteBuilder: TSiteBuilder;

begin
  try
    SiteBuilder := TSiteBuilder.Create(ConfigFilename);
    try
      SiteBuilder.Run;
    finally
      SiteBuilder.Free;
    end;
  except
  end;
  writeln('Press ENTER to exit...');
  readln;

end.
