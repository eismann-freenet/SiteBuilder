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

unit Thumbnail;

interface

uses
  Classes, Generics.Collections;

type
  TThumbnail = class

  strict private
    FVideoThumbnailCountHorizontal: Integer;
    FVideoThumbnailCountVertical: Integer;
    FVideoThumbnailMaxWidth: Integer;
    FImageThumbnailMaxHeight: Integer;
    FThumbnailQuality: Integer;
    FFFMPEG: string;
    FConvert: string;
    FMontage: string;
    FVideoTimeFormat: string;
    FOneThumbnailWidth: string;

    FCommandCache: TDictionary<string, string>;

    class function FormatVideoLength(const Length: Integer;
      const OutputFormat: string): string; overload;
    function ExecuteOutputCached(const Command: string;
      var Output: string): Boolean;
    class procedure CheckCommand(const Command: string);

  public
    constructor Create(const VideoThumbnailCountHorizontal,
      VideoThumbnailCountVertical, VideoThumbnailMaxWidth: Integer;
      const VideoTimeFormat: string; const ImageThumbnailMaxHeight,
      ThumbnailQuality: Integer; const FFMPEGPath, ImageMagickPath: string);
    destructor Destroy; override;

    function GetVideoLength(const Filename: string): Integer;
    function FormatVideoLength(const Length: Integer): string; overload;

    procedure GenerateVideoThumbnail(const Filename, OutputFilename: string);
    procedure GenerateImageThumbnail(const Filename, OutputFilename: string);

    procedure ClearCache;
  end;

implementation

uses
  SysUtils, SystemCall, RegEx, PerlRegEx, CSVFile, StrUtils, Logger;

{ TThumbnail }

const
  FFMPEGExe = 'ffmpeg.exe';
  ConvertExe = 'convert.exe';
  MontageExe = 'montage.exe';

  ScreenShotCommand = '%s -ss %s -i "%s" -ss %s -frames:v 1 "%s"';
  ScreenShotMissingKeyFrameCommand = '%s -i "%s" -ss %s -frames:v 1 "%s"';
  ScreenShotErrorCommand =
    '%s -background white -fill black -font "Arial" -pointsize 20 label:"%s" "%s"';
  ScreenShotSeekFormat = '%.2d:%.2d:%.2d.%.3d';
  ScreenShotEditAllFiles = '"%s" ';
  ScreenShotEditCommand =
    '%s "%s" -resize %sx -font "Arial" -fill white -undercolor "#00000080" -gravity SouthEast -annotate +5+5 %s "%s"';

  MontageCommand = '%s -tile %sx%s -geometry +0+0 -quality %s %s "%s"';

  VideoLengthCommand = '%s -i "%s"';
  VideoLengthPattern = 'Duration: (.*?),';
  VideoLengthFailDetection =
    'Estimating duration from bitrate, this may be inaccurate';
  VideoLengthFallbackCommand = '%s -i "%s" -f null -';
  VideoLengthFailPattern = 'Lsize=.*? time=(.*?) ';
  VideoLengthSeparator = ':';
  VideoLengthDecimalSeparator = '.';

  ImageThumbnailCommand = '%s "%s" -thumbnail x%s -quality %s "%s"';

  InternalImageExt = '.png';

  PreSeekDefault = 15000;

procedure TThumbnail.GenerateImageThumbnail(const Filename,
  OutputFilename: string);
begin
  DeleteFile(OutputFilename);
  ExecuteWait(Format(ImageThumbnailCommand, [FConvert, Filename,
    IntToStr(FImageThumbnailMaxHeight), IntToStr(FThumbnailQuality),
    OutputFilename]));
end;

procedure TThumbnail.GenerateVideoThumbnail(const Filename,
  OutputFilename: string);
var
  CurrentSeekPos, CurrentPos, CurrentDisplayPos, ScreenShotFilename,
    EditScreenShotFilename, AllFiles, Output: string;
  SubLength, I, ThumbnailCount, SeekPos, RenderPos: Integer;
  FilesToDelete: TStringList;
  RegEx: TPerlRegEx;
begin
  AllFiles := '';
  Output := '';
  ThumbnailCount := FVideoThumbnailCountHorizontal *
    FVideoThumbnailCountVertical;
  SubLength := GetVideoLength(Filename) div (ThumbnailCount + 1);
  DeleteFile(OutputFilename);

  RegEx := nil;
  FilesToDelete := nil;
  try
    RegEx := TPerlRegEx.Create;
    FilesToDelete := TStringList.Create;

    for I := 1 to ThumbnailCount do
    begin

      SeekPos := (SubLength * I) - PreSeekDefault;
      RenderPos := PreSeekDefault;

      ScreenShotFilename := GetRandomTempFilename + InternalImageExt;
      EditScreenShotFilename := GetRandomTempFilename + InternalImageExt;

      FilesToDelete.Add(ScreenShotFilename);
      FilesToDelete.Add(EditScreenShotFilename);

      if SeekPos < 0 then
      begin
        SeekPos := 0;
        RenderPos := SubLength * I;
      end;

      CurrentPos := FormatVideoLength(RenderPos, ScreenShotSeekFormat);
      CurrentSeekPos := FormatVideoLength(SeekPos, ScreenShotSeekFormat);
      CurrentDisplayPos := FormatVideoLength(SubLength * I, FVideoTimeFormat);

      if SeekPos = 0 then
      begin
        // Don't seek to 00:00:00 to avoid a possible missing key-frame.
        ExecuteWait(Format(ScreenShotMissingKeyFrameCommand, [FFFMPEG, Filename,
          CurrentPos, ScreenShotFilename]));
      end
      else
      begin
        ExecuteWait(Format(ScreenShotCommand, [FFFMPEG, CurrentSeekPos,
          Filename, CurrentPos, ScreenShotFilename]))
      end;

      ExecuteWait(Format(ScreenShotEditCommand, [FConvert, ScreenShotFilename,
        FOneThumbnailWidth, CurrentDisplayPos, EditScreenShotFilename]));

      AllFiles := AllFiles + Format(ScreenShotEditAllFiles,
        [EditScreenShotFilename]);
    end;
    ExecuteWait(Format(MontageCommand,
      [FMontage, IntToStr(FVideoThumbnailCountHorizontal),
      IntToStr(FVideoThumbnailCountVertical), IntToStr(FThumbnailQuality),
      AllFiles, OutputFilename]));

    if not DeleteFiles(FilesToDelete) then
    begin
      TLogger.LogError('Unable to delete the temporary files!');
    end;
  finally
    FilesToDelete.Free;
    RegEx.Free;
  end;
  if not FileExists(OutputFilename) then
  begin
    TLogger.LogError
      (Format('Unable to generate a thumbnail for file "%s". Generating an thumbnail which shows that error-message.',
      [Filename]));
    ExecuteWait(Format(ScreenShotErrorCommand,
      [FConvert, 'No thumbnail available!', OutputFilename]));
  end;
end;

function TThumbnail.GetVideoLength(const Filename: string): Integer;
var
  Output, LengthRaw: string;
  LengthParts: TStringList;
  RegEx: TPerlRegEx;
  IsError: Boolean;
begin
  RegEx := nil;
  LengthParts := nil;
  Output := '';
  try
    IsError := false;
    RegEx := TPerlRegEx.Create;
    LengthParts := TStringList.Create;

    try
      ExecuteOutputCached(Format(VideoLengthCommand, [FFFMPEG, Filename]
        ), Output);

      if AnsiContainsText(Output, VideoLengthFailDetection) then
      begin
        TLogger.LogError
          (Format('Unable to determine correct duration for file "%s". Try a slower approach.',
          [Filename]));
        ExecuteOutputCached(Format(VideoLengthFallbackCommand,
          [FFFMPEG, Filename]), Output);
        LengthRaw := GetRegExResult(RegEx, Output, VideoLengthFailPattern);
      end
      else
      begin
        LengthRaw := GetRegExResult(RegEx, Output, VideoLengthPattern);
      end;

      TCSVFile.Split(LengthParts, LengthRaw, VideoLengthSeparator, '"');
      LengthParts[2] := StringReplace(LengthParts[2],
        VideoLengthDecimalSeparator, GetDecimalSeparator, [rfReplaceAll]);
    except
      on EStringListError do
      begin
        IsError := true;
      end;
      on EInvalidRegEx do
      begin
        IsError := true;
      end;
    end;

    if IsError then
    begin
      TLogger.LogError(Format('Unable to determine duration for file "%s".',
        [Filename]));
      LengthParts.Clear;
      LengthParts.Add('0');
      LengthParts.Add('0');
      LengthParts.Add('0');
    end;

    Result := (StrToInt(LengthParts[0]) * 3600000) +
      (StrToInt(LengthParts[1]) * 60000) +
      Trunc(StrToFloat(LengthParts[2]) * 1000);
  finally
    RegEx.Free;
    LengthParts.Free;
  end;
end;

class procedure TThumbnail.CheckCommand(const Command: string);
begin
  if not FileExists(Command) then
  begin
    raise Exception.CreateFmt('File "%s" does not exist.', [Command]);
  end;
end;

procedure TThumbnail.ClearCache;
begin
  FCommandCache.Clear;
end;

constructor TThumbnail.Create(const VideoThumbnailCountHorizontal,
  VideoThumbnailCountVertical, VideoThumbnailMaxWidth: Integer;
  const VideoTimeFormat: string; const ImageThumbnailMaxHeight, ThumbnailQuality
  : Integer; const FFMPEGPath, ImageMagickPath: string);
begin
  FVideoThumbnailCountHorizontal := VideoThumbnailCountHorizontal;
  FVideoThumbnailCountVertical := VideoThumbnailCountVertical;
  FVideoThumbnailMaxWidth := VideoThumbnailMaxWidth;
  FImageThumbnailMaxHeight := ImageThumbnailMaxHeight;
  FThumbnailQuality := ThumbnailQuality;
  FOneThumbnailWidth :=
    IntToStr(FVideoThumbnailMaxWidth div VideoThumbnailCountHorizontal);
  FVideoTimeFormat := VideoTimeFormat;
  FFFMPEG := FFMPEGPath + FFMPEGExe;
  CheckCommand(FFFMPEG);
  FConvert := ImageMagickPath + ConvertExe;
  CheckCommand(FConvert);
  FMontage := ImageMagickPath + MontageExe;
  CheckCommand(FMontage);
  FCommandCache := TDictionary<string, string>.Create;
end;

destructor TThumbnail.Destroy;
begin
  FCommandCache.Free;
  inherited Destroy;
end;

function TThumbnail.ExecuteOutputCached(const Command: string;
  var Output: string): Boolean;
begin
  if FCommandCache.ContainsKey(Command) then
  begin
    Output := FCommandCache[Command];
    Result := true;
  end
  else
  begin
    Result := ExecuteOutput(Command, Output);
    FCommandCache.Add(Command, Output);
  end;
end;

function TThumbnail.FormatVideoLength(const Length: Integer): string;
begin
  Result := FormatVideoLength(Length, FVideoTimeFormat);
end;

class function TThumbnail.FormatVideoLength(const Length: Integer;
  const OutputFormat: string): string;
var
  Hour, Minute, Second, MSecond: Integer;
begin
  Hour := Length div 3600000;
  Minute := (Length mod 3600000) div 60000;
  Second := (Length mod 60000) div 1000;
  MSecond := Length mod 1000;
  Result := Format(OutputFormat, [Hour, Minute, Second, MSecond]);
end;

end.
