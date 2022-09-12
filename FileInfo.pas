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

unit FileInfo;

interface

uses
  Classes;

type
  TType = (Movie, Image, Archive, URL, Unknown);

  TFileInfo = class(TPersistent)

  strict private
    FDataPath: string;
    FSitePath: string;
    FMTNCommand: string;
    FMTNInfoPattern: string;
    FImageMagickCommand: string;
    FThumbnailExt: string;
    FThumbnailInfoExt: string;
    FThumbnailPath: string;
    FThumbnailInfoPath: string;
    FFilePath: string;
    FFileKey: string;
    FFileOtherNames: string;
    FDescription: string;
    FAudioTracks: string;
    FFileName: string;
    FFileType: TType;
    FFileSize: Integer;
    FFileLength: string;
    FThumbnailFilename: string;
    FThumbnailWidth: Integer;
    FThumbnailHeight: Integer;

    procedure detectType;
    procedure detectSize;
    procedure updateThumbnails;

  published
    property Key: string read FFileKey;
    property FileOtherNames: string read FFileOtherNames;
    property Description: string read FDescription;
    property AudioTracks: string read FAudioTracks;
    property FileName: string read FFileName;
    property FileType: TType read FFileType;
    property FileSize: Integer read FFileSize;
    property FileLength: string read FFileLength;
    property ThumbnailFilename: string read FThumbnailFilename;
    property ThumbnailWidth: Integer read FThumbnailWidth;
    property ThumbnailHeight: Integer read FThumbnailHeight;

  public
    constructor Create(const DataPath, SitePath, MTNCommand, MTNInfoPattern,
      ImageMagickCommand, ThumbnailExt, ThumbnailInfoExt, ThumbnailPath,
      ThumbnailInfoPath, FilePath, FileKey, FileOtherNames, Description,
      AudioTracks: string);
    destructor Destroy; override;
    class function FormatFileSize(Size: Integer): string;
    class function SectionToTitle(const Section: string): string;
    class function SectionToURL(const Section, OutputExtension: string): string;
    class function SectionToPath(const Section: string): string;
  end;

implementation

uses
  IdURI, SysUtils, StrUtils, JPEG, Tools, Logger, Regex,
  PerlRegex, SystemCall, Windows;

{ TFileInfo }

constructor TFileInfo.Create(const DataPath, SitePath, MTNCommand,
  MTNInfoPattern, ImageMagickCommand, ThumbnailExt, ThumbnailInfoExt,
  ThumbnailPath, ThumbnailInfoPath, FilePath, FileKey, FileOtherNames,
  Description, AudioTracks: string);
var
  KeyParts: TStringList;
begin
  FDataPath := DataPath;
  FSitePath := SitePath;
  FMTNCommand := MTNCommand;
  FMTNInfoPattern := MTNInfoPattern;
  FImageMagickCommand := ImageMagickCommand;
  FThumbnailExt := ThumbnailExt;
  FThumbnailInfoExt := ThumbnailInfoExt;
  FThumbnailPath := ThumbnailPath;
  FThumbnailInfoPath := ThumbnailInfoPath;
  FFilePath := FilePath;
  FFileKey := FileKey;
  FDescription := Description;

  FAudioTracks := StringReplace(AudioTracks, '|', #13, [rfReplaceAll]);
  FAudioTracks := StringReplace(FAudioTracks, '–', '-', [rfReplaceAll]);

  FFileOtherNames := StringReplace(FileOtherNames, '|', #13, [rfReplaceAll]);

  if CompareText(Copy(FFileKey, 1, 3), 'USK') = 0 then
  begin
    FFileName := '';
    FFileType := URL;
  end
  else
  begin
    KeyParts := TStringList.Create;
    try
      Split(KeyParts, FFileKey, '/');
      FFileName := TIdURI.URLDecode(KeyParts[1]);

      detectType;
      detectSize;
      updateThumbnails;

    finally
      KeyParts.Free;
    end;
  end;
end;

destructor TFileInfo.Destroy;
begin
  inherited Destroy;
end;

class function TFileInfo.FormatFileSize(Size: Integer): string;
const
  Units: array [1 .. 4] of string = ('Byte', 'KB', 'MB', 'GB');
var
  SizeUnit: Integer;
  FileSizeDbl: Double;
begin
  SizeUnit := 1;
  FileSizeDbl := Size;

  while FileSizeDbl > 1024 do
  begin
    FileSizeDbl := FileSizeDbl / 1024;
    SizeUnit := SizeUnit + 1;
  end;

  if SizeUnit = 1 then
  begin
    Result := Format('%.0f', [FileSizeDbl]) + ' ' + Units[SizeUnit];
  end
  else
  begin
    Result := Format('%.2f', [FileSizeDbl]) + ' ' + Units[SizeUnit];
  end;
end;

class function TFileInfo.SectionToPath(const Section: string): string;
begin
  Result := StringReplace(Section, '\', PathDelim, [rfReplaceAll]);
end;

class function TFileInfo.SectionToTitle(const Section: string): string;
begin
  Result := StringReplace(Section, '\', ' > ', [rfReplaceAll]);
end;

class function TFileInfo.SectionToURL(const Section, OutputExtension: string)
  : string;
begin
  Result := Unicode2Latin(StringReplace(Section, '\', '.', [rfReplaceAll]))
    + OutputExtension;
end;

procedure TFileInfo.detectSize;
var
  DataFile: file of Byte;
begin
  AssignFile(DataFile, FDataPath + PathDelim + SectionToPath(FFilePath)
      + PathDelim + FFileName);
  try
    FileMode := fmOpenRead or fmShareDenyNone;
    Reset(DataFile);
    try
      FFileSize := System.FileSize(DataFile);
    finally
      CloseFile(DataFile);
    end;
  except
    TLogger.LogError('Unable to get size from file "' + FDataPath + PathDelim +
        SectionToPath(FFilePath) + PathDelim + FFileName + '"');
  end;
end;

procedure TFileInfo.detectType;
const
  MovieExt: array [1 .. 21] of string = ('3g2', '3gp', 'asf', 'avi', 'avi',
    'divx', 'flac', 'flv', 'm1v', 'm4v', 'mkv', 'mov', 'mp4', 'mpe', 'mpeg',
    'mpg', 'ogm', 'rm', 'rmvb', 'swf', 'wmv');
  ImageExt: array [1 .. 5] of string = ('bmp', 'gif', 'jpg', 'jpeg', 'png');
  ArchiveExt: array [1 .. 1] of string = ('zip');
var
  Extension: string;
begin
  Extension := ExtractFileExt(FFileName);
  Delete(Extension, 1, 1);

  if MatchText(Extension, MovieExt) then
  begin
    FFileType := Movie;
  end
  else if MatchText(Extension, ImageExt) then
  begin
    FFileType := Image;
  end
  else if MatchText(Extension, ArchiveExt) then
  begin
    FFileType := Archive;
  end
  else
  begin
    FFileType := Unknown;
  end;
end;

procedure TFileInfo.updateThumbnails;
var
  SubPath, CreatedThumbnailFile, ThumbnailFile, CreatedThumbnailInfoFile,
    ThumbnailInfoFile, ThumbnailPath, ThumbnailInfoPath: string;
  ThumbnailImage: TJPEGImage;
  Buffer: TStringList;
  Regex: TPerlRegEx;
begin
  if (FFileType = Movie) or (FFileType = Image) then
  begin
    SubPath := SectionToPath(FFilePath);

    CreatedThumbnailFile := ChangeFileExt(ExtractFileName(FFileName), '')
      + FThumbnailExt;
    ThumbnailFile := Unicode2Latin(FFileName + FThumbnailExt);

    ThumbnailPath := Unicode2Latin
      (FSitePath + PathDelim + FThumbnailPath + PathDelim + SubPath);

    FThumbnailFilename := Unicode2Latin
      (StringReplace(FThumbnailPath + PathDelim + SubPath +
          PathDelim + ThumbnailFile, PathDelim, '/', [rfReplaceAll]));

    if not DirectoryExists(ThumbnailPath) then
    begin
      ForceDirectories(ThumbnailPath);
    end;
  end;

  if FFileType = Movie then
  begin
    CreatedThumbnailInfoFile := ChangeFileExt(ExtractFileName(FFileName), '')
      + FThumbnailInfoExt;
    ThumbnailInfoFile := FFileName + FThumbnailInfoExt;
    ThumbnailInfoPath := FThumbnailInfoPath + PathDelim + SubPath;

    if not DirectoryExists(ThumbnailInfoPath) then
    begin
      ForceDirectories(ThumbnailInfoPath);
    end;

    if not FileExists(ThumbnailPath + PathDelim + ThumbnailFile) then
    begin
      TLogger.LogInfo('Update thumbnails for file "' + FDataPath + PathDelim +
          SubPath + PathDelim + FFileName + '"');
      ExecuteWait(Format(FMTNCommand, [ThumbnailPath,
          FDataPath + PathDelim + SubPath + PathDelim + FFileName]));

      if not FileExists(ThumbnailPath + PathDelim + CreatedThumbnailFile) then
      begin
        TLogger.LogError('Unable to create thumbnail for file "' + FDataPath +
            PathDelim + SubPath + PathDelim + FFileName + '"');
      end;

      SysUtils.DeleteFile(ThumbnailInfoPath + PathDelim + ThumbnailInfoFile);
      RenameFile(ThumbnailPath + PathDelim + CreatedThumbnailInfoFile,
        ThumbnailInfoPath + PathDelim + ThumbnailInfoFile);

      RenameFile(ThumbnailPath + PathDelim + CreatedThumbnailFile,
        Unicode2Latin(ThumbnailPath + PathDelim + ThumbnailFile));
    end;

    Buffer := nil;
    Regex := nil;
    try
      Buffer := TStringList.Create;
      Regex := TPerlRegEx.Create;

      Buffer.LoadFromFile(ThumbnailInfoPath + PathDelim + ThumbnailInfoFile);
      FFileLength := GetRegExResult(Regex, Buffer.Text, FMTNInfoPattern);
    finally
      FreeAndNil(Regex);
      FreeAndNil(Buffer);
    end;
  end;

  if FFileType = Image then
  begin
    if not FileExists(ThumbnailPath + PathDelim + ThumbnailFile) then
    begin
      TLogger.LogInfo('Update thumbnails for file "' + FDataPath + PathDelim +
          SubPath + PathDelim + FFileName + '"');
      ExecuteWait(Format(FImageMagickCommand,
          [FDataPath + PathDelim + SubPath + PathDelim + FFileName,
          ThumbnailPath + PathDelim + ThumbnailFile]));
    end;
  end;

  if (FFileType = Movie) or (FFileType = Image) then
  begin
    ThumbnailImage := TJPEGImage.Create;
    try
      ThumbnailImage.LoadFromFile(ThumbnailPath + PathDelim + ThumbnailFile);
      FThumbnailWidth := ThumbnailImage.Width;
      FThumbnailHeight := ThumbnailImage.Height;
    finally
      ThumbnailImage.Free;
    end;
  end;
end;

end.
