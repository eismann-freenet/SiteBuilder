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

unit Thumbnail;

interface

uses
  Classes, Generics.Collections;

type
  TThumbnail = class(TPersistent)

  strict private
    FVideoThumbnailCountHorizontal: Integer;
    FVideoThumbnailCountVertical: Integer;
    FVideoThumbnailMaxWidth: Integer;
    FImageThumbnailMaxHeight: Integer;
    FFFMPEG: string;
    FConvert: string;
    FMontage: string;
    FVideoTimeFormat: string;
    FOneThumbnailWidth: string;

    FCommandCache: TDictionary<string, string>;

    function FormatVideoLength(const Length: Integer;
      const OutputFormat: string): string; overload;
    function ExecuteOutputCached(const Command: string;
      var Output: string): Boolean;
    procedure CheckCommand(const Command: string);
    function GetDecimalSeparator: Char;

  public
    constructor Create(const VideoThumbnailCountHorizontal,
      VideoThumbnailCountVertical, VideoThumbnailMaxWidth: Integer;
      const VideoTimeFormat: string;
      const ImageThumbnailMaxHeight: Integer; const FFMPEGPath,
      ImageMagickPath: string);
    destructor Destroy; override;

    function GetVideoLength(const Filename: string): Integer;
    function FormatVideoLength(const Length: Integer): string; overload;

    procedure GenerateVideoThumbnail(const Filename, OutputFilename: string);
    procedure GenerateImageThumbnail(const Filename, OutputFilename: string);

    procedure ClearCache;
  end;

implementation

uses
  SysUtils, SystemCall, RegEx, PerlRegEx, Tools, StrUtils, Logger, Windows;

const
  FFMPEGExe = 'ffmpeg.exe';
  ConvertExe = 'convert.exe';
  MontageExe = 'montage.exe';

  ScreenShotCommand = '%s -ss %s -i "%s" -frames:v 1 "%s"';
  ScreenShotErrorCommand =
    '%s -background white -fill black -font "Arial" -pointsize 20 label:"%s" "%s"';
  ScreenShotSeekFormat = '%.2d:%.2d:%.2d.%.3d';
  ScreenShotEditAllFiles = '"%s" ';
  ScreenShotEditCommand =
    '%s "%s" -resize %sx -font "Arial" -fill white -undercolor "#00000080" -gravity SouthEast -annotate +5+5 %s "%s"';

  MontageCommand = '%s -tile %sx%s -geometry +0+0 %s "%s"';

  VideoLengthCommand = '%s -i "%s"';
  VideoLengthPattern = 'Duration: (.*?),';
  VideoLengthFailDetection =
    'Estimating duration from bitrate, this may be inaccurate';
  VideoErrorDetection = 'Invalid data found when processing input';
  VideoLengthFallbackCommand = '%s -i "%s" -f null -';
  VideoLengthFailPattern = 'Lsize=.*? time=(.*?) ';
  VideoLengthSeparator = ':';
  VideoLengthDecimalSeparator = '.';
  VideoTBRPattern = '.*, (.*?) tbr, ';
  VideoTBRK = 'k';
  VideoTBRThreshold = 20;
  VideoDamagedDetection = 'Error, header damaged';
  VideoConvertCommand = '%s -i "%s" "%s"';

  ImageThumbnailCommand = '%s "%s" -thumbnail x%s "%s"';

  InternalImageExt = '.png';
  InternalVideoExt = '.avi';

  { TThumbnail }

procedure TThumbnail.GenerateImageThumbnail(const Filename,
  OutputFilename: string);
begin
  SysUtils.DeleteFile(OutputFilename);
  ExecuteWait(Format(ImageThumbnailCommand, [FConvert, Filename,
      IntToStr(FImageThumbnailMaxHeight), OutputFilename]));
end;

procedure TThumbnail.GenerateVideoThumbnail(const Filename,
  OutputFilename: string);
var
  SubLength, I, ThumbnailCount: Integer;
  TBR: Double;
  CurrentPos, CurrentDisplayPos, ScreenShotFilename, EditScreenShotFilename,
    SourceFilename, AllFiles, Output, TBRRaw: string;
  FilesToDelete: TStringList;
  RegEx: TPerlRegEx;
begin
  AllFiles := '';
  Output := '';
  ThumbnailCount := FVideoThumbnailCountHorizontal *
    FVideoThumbnailCountVertical;
  SubLength := GetVideoLength(Filename) div (ThumbnailCount + 1);
  SysUtils.DeleteFile(OutputFilename);

  RegEx := nil;
  FilesToDelete := nil;
  try
    RegEx := TPerlRegEx.Create;
    FilesToDelete := TStringList.Create;

    SourceFilename := Filename;
    if SubLength > 0 then
    begin
      TBR := 1;
      ExecuteOutputCached(Format(VideoLengthCommand, [FFFMPEG, Filename]),
        Output);
      TBRRaw := StringReplace(GetRegExResult(RegEx, Output, VideoTBRPattern),
        VideoLengthDecimalSeparator, GetDecimalSeparator, [rfReplaceAll]);
      if AnsiContainsText(TBRRaw, VideoTBRK) then
      begin
        TBR := 1000;
        TBRRaw := StringReplace(TBRRaw, VideoTBRK, EmptyStr, [rfReplaceAll])
      end;
      TBR := TBR * StrToFloat(TBRRaw);
      if (TBR < VideoTBRThreshold) or AnsiContainsText(Output,
        VideoDamagedDetection) then
      begin
        TLogger.LogInfo(Format(
            'Converting video "%s" to avi to get better screenshots.',
            [Filename]));
        SourceFilename := GetRandomTempFilename + InternalVideoExt;
        ExecuteWait(Format(VideoConvertCommand, [FFFMPEG, Filename,
            SourceFilename]))
      end;
    end;

    for I := 1 to ThumbnailCount do
    begin
      ScreenShotFilename := GetRandomTempFilename + InternalImageExt;
      EditScreenShotFilename := GetRandomTempFilename + InternalImageExt;

      FilesToDelete.Add(ScreenShotFilename);
      FilesToDelete.Add(EditScreenShotFilename);

      CurrentPos := FormatVideoLength(SubLength * I, ScreenShotSeekFormat);
      CurrentDisplayPos := FormatVideoLength(SubLength * I, FVideoTimeFormat);

      ExecuteWait(Format(ScreenShotCommand, [FFFMPEG, CurrentPos,
          SourceFilename, ScreenShotFilename]));

      ExecuteWait(Format(ScreenShotEditCommand, [FConvert, ScreenShotFilename,
          FOneThumbnailWidth, CurrentDisplayPos, EditScreenShotFilename]));

      AllFiles := AllFiles + Format(ScreenShotEditAllFiles,
        [EditScreenShotFilename]);
    end;
    ExecuteWait(Format(MontageCommand, [FMontage,
        IntToStr(FVideoThumbnailCountHorizontal),
        IntToStr(FVideoThumbnailCountVertical), AllFiles, OutputFilename]));

    DeleteFiles(FilesToDelete);
    if SourceFilename <> Filename then
    begin
      SysUtils.DeleteFile(SourceFilename);
    end;
  finally
    FreeAndnil(FilesToDelete);
    FreeAndnil(RegEx);
  end;
  if not FileExists(OutputFilename) then
  begin
    TLogger.LogError(Format(
        'Unable to generate a thumbnail for file "%s". Generating an thumbnail which shows that error-message.', [Filename]));
    ExecuteWait(Format(ScreenShotErrorCommand, [FConvert,
        'No thumbnail available!', OutputFilename]));
  end;
end;

function TThumbnail.GetDecimalSeparator: Char;
var
  Format: TFormatSettings;
begin
  GetLocaleFormatSettings(LOCALE_SYSTEM_DEFAULT, Format);
  Result := Format.DecimalSeparator;
end;

function TThumbnail.GetVideoLength(const Filename: string): Integer;
var
  LengthParts: TStringList;
  RegEx: TPerlRegEx;
  Output, LengthRaw: string;
begin
  RegEx := nil;
  LengthParts := nil;
  Output := '';
  try
    RegEx := TPerlRegEx.Create;
    LengthParts := TStringList.Create;

    ExecuteOutputCached(Format(VideoLengthCommand, [FFFMPEG, Filename]),
      Output);

    if AnsiContainsText(Output, VideoLengthFailDetection) then
    begin
      TLogger.LogError(Format(
          'Unable to determine correct duration for file "%s". Try a slower approach.'
            , [Filename]));
      ExecuteOutputCached(Format(VideoLengthFallbackCommand,
          [FFFMPEG, Filename]), Output);
      LengthRaw := GetRegExResult(RegEx, Output, VideoLengthFailPattern);
    end
    else if AnsiContainsText(Output, VideoErrorDetection) then
    begin
      TLogger.LogError(Format('Unable to determine duration for file "%s".',
          [Filename]));
      LengthRaw := Format(ScreenShotSeekFormat, [0, 0, 0, 0]);
    end
    else
    begin
      LengthRaw := GetRegExResult(RegEx, Output, VideoLengthPattern);
    end;

    Split(LengthParts, LengthRaw, VideoLengthSeparator, '"');
    LengthParts[2] := StringReplace(LengthParts[2],
      VideoLengthDecimalSeparator, GetDecimalSeparator, [rfReplaceAll]);

    Result := (StrToInt(LengthParts[0]) * 3600000) +
      (StrToInt(LengthParts[1]) * 60000) + Trunc
      (StrToFloat(LengthParts[2]) * 1000);
  finally
    FreeAndnil(RegEx);
    FreeAndnil(LengthParts);
  end;
end;

procedure TThumbnail.CheckCommand(const Command: string);
begin
  if not FileExists(Command) then
  begin
    TLogger.LogFatal(Format('File "%s" does not exist.', [Command]));
  end;
end;

procedure TThumbnail.ClearCache;
begin
  FCommandCache.Clear;
end;

constructor TThumbnail.Create(const VideoThumbnailCountHorizontal,
  VideoThumbnailCountVertical, VideoThumbnailMaxWidth: Integer;
  const VideoTimeFormat: string; const ImageThumbnailMaxHeight: Integer;
  const FFMPEGPath, ImageMagickPath: string);
begin
  FVideoThumbnailCountHorizontal := VideoThumbnailCountHorizontal;
  FVideoThumbnailCountVertical := VideoThumbnailCountVertical;
  FVideoThumbnailMaxWidth := VideoThumbnailMaxWidth;
  FImageThumbnailMaxHeight := ImageThumbnailMaxHeight;
  FOneThumbnailWidth := IntToStr(FVideoThumbnailMaxWidth div
      VideoThumbnailCountHorizontal);
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

function TThumbnail.FormatVideoLength(const Length: Integer;
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
