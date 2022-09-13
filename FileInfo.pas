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

unit FileInfo;

interface

uses
  Classes, KeyCache, Thumbnail, StringReplacer;

type
  TCRC = record
    CRC: string;
    FileSize: Integer;
    Filename: string;
    Path: string;
  end;

  TCRCList = array of TCRC;

  TType = (Movie, Image, Archive, URL, Unknown);

  TFileInfo = class(TPersistent)

  strict private
    FThumbnail: TThumbnail;
    FBigThumbnail: TThumbnail;
    FKeyCache: TKeyCache;
    FDataPath: string;
    FSitePath: string;
    FThumbnailExt: string;
    FThumbnailPath: string;
    FFilePath: string;
    FFileKey: string;
    FHasBigThumbnail: Boolean;
    FFileOtherNames: string;
    FDescription: string;
    FAudioTracks: string;
    FFileName: string;
    FFullFileName: string;
    FFileType: TType;
    FFileSize: Integer;
    FFileLength: string;
    FFileLengthRaw: Integer;
    FThumbnailFilename: string;
    FThumbnailWidth: Integer;
    FThumbnailHeight: Integer;
    FBigThumbnailFilename: string;
    FBigThumbnailWidth: Integer;
    FBigThumbnailHeight: Integer;
    FSections: TStringList;
    FCRC: string;
    FExtraCRC: TCRCList;

    procedure detectType;
    procedure detectSize;
    procedure updateThumbnails;
    procedure updateCRC;
  private
    procedure loadExtraCRCFile(const Filename: string);

  published
    property Key: string read FFileKey;
    property HasBigThumbnail: Boolean read FHasBigThumbnail;
    property FileOtherNames: string read FFileOtherNames;
    property Description: string read FDescription;
    property AudioTracks: string read FAudioTracks;
    property Filename: string read FFileName;
    property FileType: TType read FFileType;
    property FileSize: Integer read FFileSize;
    property FileLength: string read FFileLength;
    property ThumbnailFilename: string read FThumbnailFilename;
    property ThumbnailWidth: Integer read FThumbnailWidth;
    property ThumbnailHeight: Integer read FThumbnailHeight;
    property BigThumbnailFilename: string read FBigThumbnailFilename;
    property BigThumbnailWidth: Integer read FBigThumbnailWidth;
    property BigThumbnailHeight: Integer read FBigThumbnailHeight;
    property Sections: TStringList read FSections;
    property CRC: string read FCRC;
    property ExtraCRC: TCRCList read FExtraCRC;

  public
    constructor Create(Thumbnail, BigThumbnail: TThumbnail;
      KeyCache: TKeyCache; const DataPath, SitePath, ThumbnailExt,
      ThumbnailPath, CRCExtension, Section: string; OtherSections: TStringList;
      const FileKey: string; const IsBigThumbnailRequired: Boolean;
      const OtherFilenames, Description, AudioTracks: string);
    destructor Destroy; override;
    class function FormatFileSize(const Size: Int64): string;
    class function SectionToTitle(const Section: string): string;
    class function SectionToURL(const Section, OutputExtension: string): string;
    class function SectionToPath(const Section: string): string;
    class procedure SectionToSplitTitle(const Section: string;
      List: TStringList);

  const
    PathDelimiterSite = '/';
    SectionDelimiter = '\';

  end;

implementation

uses
  IdURI, SysUtils, StrUtils, JPEG, Tools, Logger, SystemCall, Windows, CRC32;

const
  BigThumbnailExt = '.big-thumbnail';

  { TFileInfo }

constructor TFileInfo.Create(Thumbnail, BigThumbnail: TThumbnail;
  KeyCache: TKeyCache; const DataPath, SitePath, ThumbnailExt, ThumbnailPath,
  CRCExtension, Section: string; OtherSections: TStringList;
  const FileKey: string; const IsBigThumbnailRequired: Boolean;
  const OtherFilenames, Description, AudioTracks: string);
var
  KeyParts: TStringList;
  KeyID, I: Integer;
begin
  FThumbnail := Thumbnail;
  FBigThumbnail := BigThumbnail;
  FKeyCache := KeyCache;

  FDataPath := DataPath;
  FSitePath := SitePath;
  FThumbnailExt := ThumbnailExt;
  FThumbnailPath := ThumbnailPath;
  FFilePath := OtherSections[0];
  FFileKey := FileKey;
  FHasBigThumbnail := IsBigThumbnailRequired;
  FDescription := TStringReplacer.ReplacesQuotes(Description);

  FAudioTracks := StringReplace(AudioTracks, '|', #13, [rfReplaceAll]);
  FAudioTracks := StringReplace(FAudioTracks, '–', '-', [rfReplaceAll]);

  FFileOtherNames := StringReplace(OtherFilenames, '|', #13, [rfReplaceAll]);

  FSections := TStringList.Create;
  SetLength(FExtraCRC, 0);

  FSections.AddStrings(OtherSections);
  for I := FSections.Count - 1 downto 0 do
  begin
    if FSections[I] = Section then
    begin
      FSections.Delete(I);
    end;
  end;

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
      FFullFileName := FDataPath + PathDelim + SectionToPath(FFilePath)
        + PathDelim + FFileName;

      if not FileExists(FFullFileName) then
      begin
        TLogger.LogFatal(Format('File "%s" is missing!', [FFullFileName]));
      end;

      loadExtraCRCFile(FFullFileName + CRCExtension);

      detectType;

      KeyID := FKeyCache.GetKeyID(FFileKey);
      if KeyID = -1 then
      begin
        detectSize;
        updateThumbnails;
        updateCRC;
        FKeyCache.Add(FFileKey, FFileSize, FThumbnailHeight, FThumbnailWidth,
          FBigThumbnailHeight, FBigThumbnailWidth, FFileLengthRaw, FCRC);
      end
      else
      begin
        FKeyCache.SetUsed(KeyID);

        FFileSize := FKeyCache.GetFilesize(KeyID);
        if FFileSize = 0 then
        begin
          detectSize;
          FKeyCache.UpdateFilesize(KeyID, FFileSize);
        end;

        FThumbnailHeight := FKeyCache.GetThumbnailHeight(KeyID);
        FThumbnailWidth := FKeyCache.GetThumbnailWidth(KeyID);
        FBigThumbnailHeight := FKeyCache.GetBigThumbnailHeight(KeyID);
        FBigThumbnailWidth := FKeyCache.GetBigThumbnailWidth(KeyID);

        FFileLengthRaw := FKeyCache.GetVideoLength(KeyID);

        if (FFileType = Movie) and
          ((FThumbnailHeight = 0) or (FThumbnailWidth = 0) or
            (FFileLengthRaw = 0) or (IsBigThumbnailRequired and
              ((FBigThumbnailHeight = 0) or (FBigThumbnailWidth = 0)))) then
        begin
          updateThumbnails;
          FKeyCache.UpdateVideoLength(KeyID, FFileLengthRaw);
          FKeyCache.UpdateThumbnailHeight(KeyID, FThumbnailHeight);
          FKeyCache.UpdateThumbnailWidth(KeyID, FThumbnailWidth);
          FKeyCache.UpdateBigThumbnailHeight(KeyID, FBigThumbnailHeight);
          FKeyCache.UpdateBigThumbnailWidth(KeyID, FBigThumbnailWidth);
        end;

        if (FFileType = Image) and
          ((FThumbnailHeight = 0) or (FThumbnailWidth = 0)) then
        begin
          updateThumbnails;
          FKeyCache.UpdateThumbnailHeight(KeyID, FThumbnailHeight);
          FKeyCache.UpdateThumbnailWidth(KeyID, FThumbnailWidth);
        end;

        FCRC := FKeyCache.GetCRC(KeyID);
        if FCRC = '' then
        begin
          updateCRC;
          FKeyCache.updateCRC(KeyID, FCRC);
        end;
      end;

      FFileLength := FThumbnail.FormatVideoLength(FFileLengthRaw);

      FThumbnailFilename := FThumbnailPath + PathDelim +
        TStringReplacer.Unicode2Latin(SectionToPath(FFilePath))
        + PathDelim + TStringReplacer.Unicode2Latin(FFileName + FThumbnailExt);
      FBigThumbnailFilename := FThumbnailPath + PathDelim +
        TStringReplacer.Unicode2Latin(SectionToPath(FFilePath))
        + PathDelim + TStringReplacer.Unicode2Latin
        (FFileName + BigThumbnailExt + FThumbnailExt);

      if (FFileType in [Movie, Image]) and
        (not FileExists(FSitePath + PathDelim + FThumbnailFilename))
        then
      begin
        TLogger.LogError(Format('Thumbnail "%s" is missing!',
            [FSitePath + PathDelim + FThumbnailFilename]));
      end;
      if (FFileType in [Movie, Image]) and HasBigThumbnail and
        (not FileExists(FSitePath + PathDelim + FBigThumbnailFilename)) then
      begin
        TLogger.LogError(Format('Thumbnail "%s" is missing!',
            [FSitePath + PathDelim + FBigThumbnailFilename]));
      end;

      FThumbnailFilename := StringReplace(FThumbnailFilename, PathDelim,
        PathDelimiterSite, [rfReplaceAll]);
      FBigThumbnailFilename := StringReplace(FBigThumbnailFilename, PathDelim,
        PathDelimiterSite, [rfReplaceAll]);

    finally
      KeyParts.Free;
    end;
  end;
end;

destructor TFileInfo.Destroy;
begin
  FSections.Free;
  SetLength(FExtraCRC, 0);
  inherited Destroy;
end;

class function TFileInfo.FormatFileSize(const Size: Int64): string;
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
  Result := StringReplace(Section, SectionDelimiter, PathDelim, [rfReplaceAll]);
end;

class procedure TFileInfo.SectionToSplitTitle(const Section: string;
  List: TStringList);
begin
  Split(List, Section, SectionDelimiter);
end;

procedure TFileInfo.loadExtraCRCFile(const Filename: string);
var
  FileContent, Parts: TStringList;
  Stream: TStream;
  Line: string;
begin
  if FileExists(Filename) then
  begin
    TLogger.LogInfo(Format('Load extra CRC-Infos from file "%s"', [Filename]));

    Parts := nil;
    Stream := nil;
    FileContent := nil;
    try
      Parts := TStringList.Create;
      FileContent := TStringList.Create;
      Stream := TFileStream.Create(Filename, fmOpenRead or fmShareDenyNone);

      FileContent.LoadFromStream(Stream, TEncoding.UTF8);
      for Line in FileContent do
      begin
        Split(Parts, Line, ',');
        SetLength(FExtraCRC, Length(FExtraCRC) + 1);
        FExtraCRC[ High(FExtraCRC)].Filename := Parts[0];
        FExtraCRC[ High(FExtraCRC)].FileSize := StrToInt(Parts[1]);
        FExtraCRC[ High(FExtraCRC)].CRC := Parts[2];
        FExtraCRC[ High(FExtraCRC)].Path := Parts[3];
      end;
    finally
      FreeAndNil(Stream);
      FreeAndNil(Parts);
      FreeAndNil(FileContent);
    end;
  end;
end;

class function TFileInfo.SectionToTitle(const Section: string): string;
begin
  Result := StringReplace(Section, SectionDelimiter, ' > ', [rfReplaceAll]);
end;

class function TFileInfo.SectionToURL(const Section, OutputExtension: string)
  : string;
begin
  Result := TStringReplacer.Unicode2Latin(StringReplace(Section,
      SectionDelimiter, '.', [rfReplaceAll])) + OutputExtension;
end;

procedure TFileInfo.detectSize;
var
  DataFile: file of Byte;
begin
  AssignFile(DataFile, FFullFileName);
  try
    FileMode := fmOpenRead or fmShareDenyNone;
    Reset(DataFile);
    try
      FFileSize := System.FileSize(DataFile);
    finally
      CloseFile(DataFile);
    end;
  except
    TLogger.LogError(Format('Unable to get size from file "%s"',
        [FFullFileName]));
  end;
end;

procedure TFileInfo.detectType;
const
  MovieExt: array [1 .. 22] of string = ('3g2', '3gp', 'asf', 'avi', 'avi',
    'divx', 'flac', 'f4v', 'flv', 'm1v', 'm4v', 'mkv', 'mov', 'mp4', 'mpe',
    'mpeg', 'mpg', 'ogm', 'rm', 'rmvb', 'swf', 'wmv');
  ImageExt: array [1 .. 5] of string = ('bmp', 'gif', 'jpg', 'jpeg', 'png');
  ArchiveExt: array [1 .. 2] of string = ('7z', 'zip');
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

procedure TFileInfo.updateCRC;
begin
  TLogger.LogInfo(Format('Update CRC for file "%s"', [FFullFileName]));
  FCRC := CalcFileCRC32(FFullFileName);
end;

procedure TFileInfo.updateThumbnails;
var
  SubPath, FullThumbnailFilename, FullBigThumbnailFilename,
    FullThumbnailPath: string;
  ThumbnailImage: TJPEGImage;
begin
  if (FFileType = Movie) or (FFileType = Image) then
  begin
    SubPath := SectionToPath(FFilePath);

    FullThumbnailPath := FSitePath + PathDelim + FThumbnailPath + PathDelim +
      TStringReplacer.Unicode2Latin(SubPath);

    FullThumbnailFilename := FullThumbnailPath + PathDelim +
      TStringReplacer.Unicode2Latin(FFileName + FThumbnailExt);
    FullBigThumbnailFilename := FullThumbnailPath + PathDelim +
      TStringReplacer.Unicode2Latin
      (FFileName + BigThumbnailExt + FThumbnailExt);

    if not DirectoryExists(FullThumbnailPath) then
    begin
      ForceDirectories(FullThumbnailPath);
    end;
  end;

  if FFileType = Movie then
  begin
    TLogger.LogInfo(Format('Update thumbnails for file "%s"', [FFullFileName]));
    FThumbnail.GenerateVideoThumbnail(FFullFileName, FullThumbnailFilename);
    if HasBigThumbnail then
    begin
      FBigThumbnail.GenerateVideoThumbnail(FFullFileName,
        FullBigThumbnailFilename);
    end;

    FFileLengthRaw := FThumbnail.GetVideoLength(FFullFileName);
  end;

  if FFileType = Image then
  begin
    TLogger.LogInfo(Format('Update thumbnails for file "%s"', [FFullFileName]));
    FThumbnail.GenerateImageThumbnail(FFullFileName, FullThumbnailFilename);
  end;

  FThumbnail.ClearCache;
  FBigThumbnail.ClearCache;

  if (FFileType = Movie) or (FFileType = Image) then
  begin
    ThumbnailImage := TJPEGImage.Create;
    try
      ThumbnailImage.LoadFromFile(FullThumbnailFilename);
      FThumbnailWidth := ThumbnailImage.Width;
      FThumbnailHeight := ThumbnailImage.Height;
      if HasBigThumbnail then
      begin
        ThumbnailImage.LoadFromFile(FullBigThumbnailFilename);
        FBigThumbnailWidth := ThumbnailImage.Width;
        FBigThumbnailHeight := ThumbnailImage.Height;
      end;
    finally
      ThumbnailImage.Free;
    end;
  end;
end;

end.
