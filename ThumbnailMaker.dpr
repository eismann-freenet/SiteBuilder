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

program ThumbnailMaker;
{$APPTYPE CONSOLE}

uses
  RegEx in 'RegEx.pas',
  SysUtils,
  Logger in 'Logger.pas',
  Thumbnail in 'Thumbnail.pas';
{$R *.res}

var
  Thumbnail: TThumbnail;
  ExePath, VideoFile: string;

begin
  try
    ExePath := ExtractFilePath(ParamStr(0));
    VideoFile := ParamStr(1);
    if VideoFile = '' then
    begin
      TLogger.LogFatal('Param 1 have to be a filename of a video!');
    end;
    Thumbnail := TThumbnail.Create(4, 4, 1024, '%.2d:%.2d:%.2d', 186,
      ExePath + 'programs\ffmpeg\bin\', ExePath + 'programs\ImageMagick\');
    try
      TLogger.LogInfo(Format('Update thumbnails for file "%s"', [VideoFile]));
      Thumbnail.GenerateVideoThumbnail(VideoFile, VideoFile + '.jpg');
    finally
      Thumbnail.Free;
    end;
  except
  end;
  writeln('Press ENTER to exit...');
  readln;

end.
