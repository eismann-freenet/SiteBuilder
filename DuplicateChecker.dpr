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

program DuplicateChecker;
{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
  CSVFile in 'CSVFile.pas',
  DuplicateEntry in 'DuplicateEntry.pas',
  DuplicateList in 'DuplicateList.pas',
  DuplicateTree in 'DuplicateTree.pas',
  KeyCache in 'KeyCache.pas',
  CRC32 in 'CRC32.pas',
  Logger in 'Logger.pas',
  SiteBuilder in 'SiteBuilder.pas',
  Key in 'Key.pas',
  Thumbnail in 'Thumbnail.pas',
  SystemCall in 'SystemCall.pas',
  RegEx in 'RegEx.pas',
  BookmarksParser in 'BookmarksParser.pas',
  Changelog in 'Changelog.pas',
  ChangelogEntry in 'ChangelogEntry.pas',
  DuplicateEntryComparer in 'DuplicateEntryComparer.pas',
  FileInfo in 'FileInfo.pas',
  FileInfoComparer in 'FileInfoComparer.pas',
  FileInfoList in 'FileInfoList.pas',
  FileInfoTree in 'FileInfoTree.pas',
  IndexPage in 'IndexPage.pas',
  IndexPageComparer in 'IndexPageComparer.pas',
  IndexPageList in 'IndexPageList.pas',
  TemplateChangelog in 'TemplateChangelog.pas',
  TemplateContent in 'TemplateContent.pas',
  TemplateIndex in 'TemplateIndex.pas',
  StringReplacer in 'StringReplacer.pas',
  SiteEncoding in 'SiteEncoding.pas',
  Sort in 'Sort.pas';
{$R *.res}

var
  ExePath, DuplicateFile, CRC, OriginalKeyRaw, Key: string;
  Files: TStringList;
  KeyCache: TKeyCache;
  DuplicateTree: TDuplicateTree;
  DuplicateList: TDuplicateList;
  DuplicateEntry: TDuplicateEntry;
  Thumbnail: TThumbnail;
  KeyID, VideoLength: Integer;
  OriginalKey: TKey;
  FoundDuplicate: Boolean;
  SimilarVideoLength: TIntegerArray;

begin
  try
    FoundDuplicate := false;
    ExePath := ExtractFilePath(ParamStr(0));
    DuplicateFile := ParamStr(1);

    if DuplicateFile = '' then
    begin
      raise Exception.Create('Param 1 have to be a filename!');
    end;

    if not FileExists(DuplicateFile) then
    begin
      raise Exception.CreateFmt('File "%s" is missing!', [DuplicateFile]);
    end;

    TLogger.LogInfo(Format('Calc CRC for file "%s"...', [DuplicateFile]));
    CRC := CalcFileCRC32(DuplicateFile);
    TLogger.LogInfo(Format('CRC is "%s".', [CRC]));

    KeyCache := TKeyCache.Create(ExePath + 'key-cache.db3');
    try

      TLogger.LogInfo('Search for file in the database...');
      KeyID := KeyCache.GetKeyIDByCRC(CRC);
      if KeyID <> -1 then
      begin
        OriginalKey := TKey.Create(KeyCache.GetKey(KeyID));
        try
          TLogger.LogInfo(Format('Filename: %s', [OriginalKey.Filename]));
          TLogger.LogInfo(Format('Key     : %s', [OriginalKey.Key]));
          FoundDuplicate := true;
        finally
          OriginalKey.Free;
        end;
      end;

      if not FoundDuplicate then
      begin
        TLogger.LogInfo('Search for file in duplicate-list...');
        DuplicateTree := nil;
        Files := nil;
        try
          Files := TStringList.Create;
          TSiteBuilder.GetFileList(ExePath + 'data\duplicate', '.csv', false,
            Files);
          DuplicateTree := TDuplicateTree.Create;
          DuplicateTree.LoadData(Files);
          for Key in DuplicateTree.Keys do
          begin
            DuplicateList := DuplicateTree[Key];
            for DuplicateEntry in DuplicateList do
            begin
              if DuplicateEntry.CRC = CRC then
              begin
                OriginalKey := TKey.Create(Key);
                try
                  TLogger.LogInfo(Format('Filename: %s', [OriginalKey.Filename])
                    );
                  TLogger.LogInfo(Format('Key     : %s', [OriginalKey.Key]));
                  FoundDuplicate := true;
                finally
                  OriginalKey.Free;
                end;
              end;
            end;
          end;
        finally
          Files.Free;
          DuplicateTree.Free;
        end;
      end;

      if not FoundDuplicate then
      begin
        TLogger.LogInfo('Search for similar file based on the video-length...');
        Thumbnail := TThumbnail.Create(4, 4, 1024, '%.2d:%.2d:%.2d', 186,
          ExePath + 'programs\ffmpeg\bin\', ExePath + 'programs\ImageMagick\');
        try
          VideoLength := Thumbnail.GetVideoLength(DuplicateFile);
          if VideoLength = 0 then
          begin
            TLogger.LogInfo('No valid video-file.');
          end
          else
          begin
            SimilarVideoLength := KeyCache.GetSimilarVideoLength(VideoLength,
              1000);
            for KeyID in SimilarVideoLength do
            begin
              OriginalKey := TKey.Create(KeyCache.GetKey(KeyID));
              try
                TLogger.LogInfo(Format('Filename: %s', [OriginalKey.Filename]));
                TLogger.LogInfo(Format('Key     : %s', [OriginalKey.Key]));
                TLogger.LogInfo('');
              finally
                OriginalKey.Free;
              end;
            end;
          end;
        finally
          Thumbnail.Free;
        end;
      end;

    finally
      KeyCache.Free;
    end;
  except
    on E: Exception do
      TLogger.LogFatal(E.Message);
  end;
  writeln('Press ENTER to exit...');
  readln;

end.
