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

program ThumbnailMaker;
{$APPTYPE CONSOLE}

uses
  SysUtils,
  Logger in 'Logger.pas',
  Thumbnail in 'Thumbnail.pas',
  Config in 'Config.pas';
{$R *.res}

var
  ConfigFile, VideoFile: string;
  VideoTimeFormat, FFMPEGPath, ImageMagickPath, ThumbnailExtension: string;
  VideoThumbnailCountHorizontal, VideoThumbnailCountVertical,
    VideoThumbnailMaxWidth, ImageThumbnailMaxHeight: Integer;
  Thumbnail: TThumbnail;
  Config: TConfig;
  I: Integer;

begin
  try
    ConfigFile := ParamStr(1);
    if ConfigFile = '' then
    begin
      raise Exception.Create
        ('Parameter 1 have to be a configuration filename!');
    end;

    if ParamCount < 2 then
    begin
      raise Exception.Create(
        'Parameter(s) 2..n have to be a filename of a video!');
    end;

    Config := nil;
    Thumbnail := nil;
    try
      Config := TConfig.Create(ConfigFile);

      VideoThumbnailCountHorizontal := Config.ReadInteger
        (VIDEO_THUMBNAIL_COUNT_HORIZONTAL);
      VideoThumbnailCountVertical := Config.ReadInteger
        (VIDEO_THUMBNAIL_COUNT_VERTICAL);
      VideoThumbnailMaxWidth := Config.ReadInteger(VIDEO_THUMBNAIL_MAX_WIDTH);
      VideoTimeFormat := Config.ReadString(VIDEO_TIME_FORMAT);
      ImageThumbnailMaxHeight := Config.ReadInteger(IMAGE_THUMBNAIL_MAX_HEIGHT);
      FFMPEGPath := Config.ReadString(FFMPEG_PATH);
      ImageMagickPath := Config.ReadString(IMAGEMAGICK_PATH);
      ThumbnailExtension := Config.ReadString(THUMBNAIL_EXTENSION);
      Thumbnail := TThumbnail.Create(VideoThumbnailCountHorizontal,
        VideoThumbnailCountVertical, VideoThumbnailMaxWidth, VideoTimeFormat,
        ImageThumbnailMaxHeight, FFMPEGPath, ImageMagickPath);

      for I := 2 to ParamCount do
      begin
        VideoFile := ParamStr(I);
        TLogger.LogInfo(Format('Update thumbnails for file "%s"', [VideoFile]));
        Thumbnail.GenerateVideoThumbnail(VideoFile,
          VideoFile + ThumbnailExtension);
      end;
    finally
      Config.Free;
      Thumbnail.Free;
    end;
  except
    on E: Exception do
      TLogger.LogFatal(E.Message);
  end;
  writeln('Press ENTER to exit...');
  readln;

end.
