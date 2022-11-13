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

program DuplicateChecker;
{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
  DuplicateEntry in 'DuplicateEntry.pas',
  DuplicateList in 'DuplicateList.pas',
  DuplicateTree in 'DuplicateTree.pas',
  KeyCache in 'KeyCache.pas',
  CRC32 in 'CRC32.pas',
  Logger in 'Logger.pas',
  SiteBuilder in 'SiteBuilder.pas',
  Key in 'Key.pas',
  Thumbnail in 'Thumbnail.pas',
  Config in 'Config.pas';
{$R *.res}

var
  ConfigFile, DuplicateFile, CRC, Key: string;
  KeyCacheFile, DuplicatePath, DuplicateFileExtension, VideoTimeFormat,
    FFMPEGPath, ImageMagickPath: string;
  VideoThumbnailCountHorizontal, VideoThumbnailCountVertical,
    VideoThumbnailMaxWidth, ImageThumbnailMaxHeight, ThumbnailQuality: Integer;
  Files: TStringList;
  KeyCache: TKeyCache;
  DuplicateTree: TDuplicateTree;
  DuplicateList: TDuplicateList;
  DuplicateEntry: TDuplicateEntry;
  Thumbnail: TThumbnail;
  KeyID, VideoLength: Integer;
  FoundDuplicate: Boolean;
  SimilarVideoLength: TIntegerArray;
  Config: TConfig;

procedure ShowKey(Key: string);
var
  OriginalKey: TKey;
begin
  OriginalKey := TKey.Create(Key);
  try
    TLogger.LogInfo(Format('Filename: %s', [OriginalKey.Filename]));
    TLogger.LogInfo(Format('Key     : %s', [OriginalKey.Key]));
  finally
    OriginalKey.Free;
  end;
end;

begin
  Config := nil;
  KeyCache := nil;
  Files := nil;
  DuplicateTree := nil;
  Thumbnail := nil;
  try
    ConfigFile := ParamStr(1);
    if ConfigFile = '' then
    begin
      raise Exception.Create
        ('Parameter 1 have to be a configuration filename!');
    end;

    DuplicateFile := ParamStr(2);
    if DuplicateFile = '' then
    begin
      raise Exception.Create('Parameter 2 have to be a filename!');
    end;
    if not FileExists(DuplicateFile) then
    begin
      raise Exception.CreateFmt('File "%s" is missing!', [DuplicateFile]);
    end;

    try
      Config := TConfig.Create(ConfigFile);

      KeyCacheFile := Config.ReadString(KEY_CACHE_FILENAME);
      KeyCache := TKeyCache.Create(KeyCacheFile);

      DuplicatePath := Config.ReadString(DUPLICATE_PATH);
      DuplicateFileExtension := Config.ReadString(DUPLICATE_FILE_EXTENSION);
      Files := TStringList.Create;
      TSiteBuilder.GetFileList(DuplicatePath, DuplicateFileExtension,
        false, Files);
      DuplicateTree := TDuplicateTree.Create;
      DuplicateTree.LoadData(Files);

      VideoThumbnailCountHorizontal :=
        Config.ReadInteger(VIDEO_THUMBNAIL_COUNT_HORIZONTAL);
      VideoThumbnailCountVertical :=
        Config.ReadInteger(VIDEO_THUMBNAIL_COUNT_VERTICAL);
      VideoThumbnailMaxWidth := Config.ReadInteger(VIDEO_THUMBNAIL_MAX_WIDTH);
      VideoTimeFormat := Config.ReadString(VIDEO_TIME_FORMAT);
      ImageThumbnailMaxHeight := Config.ReadInteger(IMAGE_THUMBNAIL_MAX_HEIGHT);
      ThumbnailQuality := Config.ReadInteger(THUMBNAIL_QUALITY);
      FFMPEGPath := Config.ReadString(FFMPEG_PATH);
      ImageMagickPath := Config.ReadString(IMAGEMAGICK_PATH);
      Thumbnail := TThumbnail.Create(VideoThumbnailCountHorizontal,
        VideoThumbnailCountVertical, VideoThumbnailMaxWidth, VideoTimeFormat,
        ImageThumbnailMaxHeight, ThumbnailQuality, FFMPEGPath, ImageMagickPath,
        TConfig.GetFFmpegLocale);

      FoundDuplicate := false;

      TLogger.LogInfo(Format('Calc CRC for file "%s"...', [DuplicateFile]));
      CRC := CalcFileCRC32(DuplicateFile);
      TLogger.LogInfo(Format('CRC is "%s".', [CRC]));

      TLogger.LogInfo('Search for file in the database...');
      KeyID := KeyCache.GetKeyIDByCRC(CRC);
      if KeyID <> -1 then
      begin
        ShowKey(KeyCache.GetKey(KeyID));
        FoundDuplicate := true;
      end;

      if not FoundDuplicate then
      begin
        TLogger.LogInfo('Search for file in duplicate-list...');
        for Key in DuplicateTree.Keys do
        begin
          DuplicateList := DuplicateTree[Key];
          for DuplicateEntry in DuplicateList do
          begin
            if DuplicateEntry.CRC = CRC then
            begin
              ShowKey(Key);
              FoundDuplicate := true;
            end;
          end;
        end;
      end;

      if not FoundDuplicate then
      begin
        TLogger.LogInfo('Search for similar file based on the video-length...');
        VideoLength := Thumbnail.GetVideoLength(DuplicateFile);
        if VideoLength = 0 then
        begin
          TLogger.LogInfo('No valid video-file.');
        end
        else
        begin
          SimilarVideoLength := KeyCache.GetSimilarVideoLength
            (VideoLength, 1000);
          for KeyID in SimilarVideoLength do
          begin
            ShowKey(KeyCache.GetKey(KeyID));
            TLogger.LogInfo('');
          end;
        end;
      end;
    finally
      Config.Free;
      KeyCache.Free;
      Files.Free;
      DuplicateTree.Free;
      Thumbnail.Free;
    end;
  except
    on E: Exception do
      TLogger.LogFatal(E.Message);
  end;
  writeln('Press ENTER to exit...');
  readln;

end.
