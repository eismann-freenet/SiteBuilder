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

unit FileInfo;

interface

uses
  SysUtils, Classes, KeyCache, Thumbnail, DuplicateList, Key, BookmarksParser;

type
  TCRC = record
    CRC: string;
    FileSize: Integer;
    Filename: string;
    Path: string;
  end;

  TCRCList = array of TCRC;

  TFileType = (Movie, Image, Archive, URL, Unknown);

  TAudioType = (NotSet, None, Original, Music);

  TFileInfo = class

  strict private
    FThumbnail: TThumbnail;
    FBigThumbnail: TThumbnail;
    FKeyCache: TKeyCache;
    FBookmarksParser: TBookmarksParser;
    FDataPath: string;
    FSitePath: string;
    FThumbnailExt: string;
    FThumbnailPath: string;
    FFilePath: string;
    FFileKey: TKey;
    FHasBigThumbnail: Boolean;
    FFileOtherNames: string;
    FDescription: string;
    FAudioTracks: string;
    FAudioType: TAudioType;
    FFullFileName: string;
    FFileType: TFileType;
    FFileSize: Integer;
    FFileLength: Integer;
    FThumbnailFilename: string;
    FThumbnailWidth: Integer;
    FThumbnailHeight: Integer;
    FBigThumbnailFilename: string;
    FBigThumbnailWidth: Integer;
    FBigThumbnailHeight: Integer;
    FSections: TStringList;
    FCRC: string;
    FExtraCRC: TCRCList;
    FDuplicateList: TDuplicateList;

    procedure DetectSize;
    procedure UpdateThumbnails;
    procedure UpdateCRC;
    function GetIdentifier: string;
    procedure LoadExtraCRCFile(const Filename: string);

  public
    constructor Create(Thumbnail, BigThumbnail: TThumbnail;
      KeyCache: TKeyCache; BookmarksParser: TBookmarksParser;
      const DataPath, SitePath, ThumbnailExt, ThumbnailPath, CRCExtension,
      Sections, FileKey, IsNewKey, IsBigThumbnailRequired, OtherFilenames,
      Description, AudioTracks, AudioType, HasActiveLink: string;
      DuplicateList: TDuplicateList; const NewKeyName: string);
    destructor Destroy; override;
    class function DetectType(const Filename: string): TFileType;
    class function FormatFileSize(const Size: Int64): string;
    class function FormatAudioType(const AudioType: TAudioType): string;
    class function SectionToTitle(const Section: string): string;
    class function SectionToURL(const Section, OutputExtension: string): string;
    class function SectionToPath(const Section: string): string;
    class procedure SectionToSplitTitle(const Section: string;
      var List: TStringList);
    function HasDuplicateList: Boolean;
    function GetFileLength: string;
    procedure GetOtherSections(OtherSections: TStringList;
      const CurrentSection: string);

    property Key: TKey read FFileKey;
    property HasBigThumbnail: Boolean read FHasBigThumbnail;
    property FileOtherNames: string read FFileOtherNames;
    property Description: string read FDescription;
    property AudioTracks: string read FAudioTracks;
    property AudioType: TAudioType read FAudioType;
    property FileType: TFileType read FFileType;
    property FileSize: Integer read FFileSize;

    property ThumbnailFilename: string read FThumbnailFilename;
    property ThumbnailWidth: Integer read FThumbnailWidth;
    property ThumbnailHeight: Integer read FThumbnailHeight;
    property BigThumbnailFilename: string read FBigThumbnailFilename;
    property BigThumbnailWidth: Integer read FBigThumbnailWidth;
    property BigThumbnailHeight: Integer read FBigThumbnailHeight;
    property Sections: TStringList read FSections;
    property CRC: string read FCRC;
    property ExtraCRC: TCRCList read FExtraCRC;
    property Identifier: string read GetIdentifier;
    property DuplicateList: TDuplicateList read FDuplicateList;

  const
    PathDelimiterSite = '/';
    SectionDelimiter = PathDelim;
  end;

implementation

uses
  StrUtils, JPEG, CSVFile, Logger, CRC32, TypInfo, StringReplacer, Sort,
  SystemCall;

{ TFileInfo }

const
  BigThumbnailExt = '.big-thumbnail';

constructor TFileInfo.Create(Thumbnail, BigThumbnail: TThumbnail;
  KeyCache: TKeyCache; BookmarksParser: TBookmarksParser;
  const DataPath, SitePath, ThumbnailExt, ThumbnailPath, CRCExtension,
  Sections, FileKey, IsNewKey, IsBigThumbnailRequired, OtherFilenames,
  Description, AudioTracks, AudioType, HasActiveLink: string;
  DuplicateList: TDuplicateList; const NewKeyName: string);
var
  AudioTypeID, KeyID: Integer;
begin
  FThumbnail := Thumbnail;
  FBigThumbnail := BigThumbnail;
  FKeyCache := KeyCache;
  FDuplicateList := DuplicateList;
  FBookmarksParser := BookmarksParser;

  FSections := TStringList.Create;
  TCSVFile.Split(FSections, Sections, '|');

  if IsNewKey <> '' then
  begin
    FSections.Add(NewKeyName);
  end;

  FDataPath := DataPath;
  FSitePath := SitePath;
  FThumbnailExt := ThumbnailExt;
  FThumbnailPath := ThumbnailPath;

  if FSections.Count > 0 then
  begin
    FFilePath := FSections[0];
  end
  else
  begin
    FFilePath := '';
  end;

  FFileKey := TKey.Create(FileKey, HasActiveLink <> '');
  FHasBigThumbnail := IsBigThumbnailRequired <> '';

  FDescription := TStringReplacer.ReplaceSpecialChars(Description);
  FDescription := TStringReplacer.ReplaceNewLine(FDescription);

  SetLength(FExtraCRC, 0);
  FExtraCRC := nil;

  if FFileKey.KeyType = USK then
  begin
    FFileType := URL;

    if not FFileKey.HasEdition then
    begin
      FFileKey.SetEdition(FBookmarksParser.GetCurrentEdition(FFileKey));
    end;
  end
  else
  begin
    FFullFileName := FDataPath + PathDelim + SectionToPath(FFilePath)
      + PathDelim + Key.Filename;

    if not FileExists(FFullFileName) then
    begin
      raise Exception.CreateFmt('File "%s" is missing!', [FFullFileName]);
    end;

    FAudioTracks := TStringReplacer.ReplaceSpecialChars(AudioTracks);
    FAudioTracks := TStringReplacer.ReplaceNewLine(FAudioTracks);

    AudioTypeID := GetEnumValue(TypeInfo(TAudioType), Trim(AudioType));
    if AudioTypeID < 0 then
    begin
      if AudioType <> '' then
      begin
        TLogger.LogError(Format('Invalid AudioType "%s" for key "%s"!',
            [AudioType, FFileKey.Key]));
      end;
      FAudioType := NotSet;
    end
    else
    begin
      FAudioType := TAudioType(AudioTypeID);
    end;

    FFileOtherNames := SortArrayAsString(OtherFilenames);
    FFileOtherNames := TStringReplacer.ReplaceNewLine(FFileOtherNames);

    LoadExtraCRCFile(FFullFileName + CRCExtension);

    FFileType := DetectType(Key.Filename);

    KeyID := FKeyCache.GetKeyIDByKey(FFileKey.Key);
    if KeyID = -1 then
    begin
      DetectSize;
      UpdateThumbnails;
      UpdateCRC;
      FKeyCache.Add(FFileKey.Key, FFileSize, FThumbnailHeight, FThumbnailWidth,
        FBigThumbnailHeight, FBigThumbnailWidth, FFileLength, FCRC);
    end
    else
    begin
      FKeyCache.SetUsed(KeyID);

      FFileSize := FKeyCache.GetFilesize(KeyID);
      if FFileSize = 0 then
      begin
        DetectSize;
        FKeyCache.UpdateFilesize(KeyID, FFileSize);
      end;

      FThumbnailHeight := FKeyCache.GetThumbnailHeight(KeyID);
      FThumbnailWidth := FKeyCache.GetThumbnailWidth(KeyID);
      FBigThumbnailHeight := FKeyCache.GetBigThumbnailHeight(KeyID);
      FBigThumbnailWidth := FKeyCache.GetBigThumbnailWidth(KeyID);

      FFileLength := FKeyCache.GetVideoLength(KeyID);

      if (FFileType = Movie) and
        ((FThumbnailHeight = 0) or (FThumbnailWidth = 0) or (FFileLength = 0)
          or (FHasBigThumbnail and ((FBigThumbnailHeight = 0) or
              (FBigThumbnailWidth = 0)))) then
      begin
        UpdateThumbnails;
        FKeyCache.UpdateVideoLength(KeyID, FFileLength);
        FKeyCache.UpdateThumbnailHeight(KeyID, FThumbnailHeight);
        FKeyCache.UpdateThumbnailWidth(KeyID, FThumbnailWidth);
        FKeyCache.UpdateBigThumbnailHeight(KeyID, FBigThumbnailHeight);
        FKeyCache.UpdateBigThumbnailWidth(KeyID, FBigThumbnailWidth);
      end;

      if (FFileType = Image) and
        ((FThumbnailHeight = 0) or (FThumbnailWidth = 0)) then
      begin
        UpdateThumbnails;
        FKeyCache.UpdateThumbnailHeight(KeyID, FThumbnailHeight);
        FKeyCache.UpdateThumbnailWidth(KeyID, FThumbnailWidth);
      end;

      FCRC := FKeyCache.GetCRC(KeyID);
      if FCRC = '' then
      begin
        UpdateCRC;
        FKeyCache.UpdateCRC(KeyID, FCRC);
      end;
    end;

    FThumbnailFilename := FThumbnailPath + PathDelim +
      TStringReplacer.Unicode2Latin(SectionToPath(FFilePath))
      + PathDelim + TStringReplacer.Unicode2Latin
      (Key.Filename + FThumbnailExt);
    FBigThumbnailFilename := FThumbnailPath + PathDelim +
      TStringReplacer.Unicode2Latin(SectionToPath(FFilePath))
      + PathDelim + TStringReplacer.Unicode2Latin
      (Key.Filename + BigThumbnailExt + FThumbnailExt);

    if (FFileType in [Movie, Image]) and
      (not FileExists(FSitePath + PathDelim + FThumbnailFilename)) then
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
  end;
end;

destructor TFileInfo.Destroy;
begin
  FSections.Free;
  FFileKey.Free;
  SetLength(FExtraCRC, 0);
  inherited Destroy;
end;

class function TFileInfo.FormatAudioType(const AudioType: TAudioType): string;
begin
  Result := GetEnumName(TypeInfo(TAudioType), Integer(AudioType));
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

function TFileInfo.GetFileLength: string;
begin
  Result := FThumbnail.FormatVideoLength(FFileLength);
end;

function TFileInfo.GetIdentifier: string;
begin
  Result := FCRC + '-' + IntToStr(FFileSize);
end;

procedure TFileInfo.GetOtherSections(OtherSections: TStringList;
  const CurrentSection: string);
var
  I: Integer;
begin
  OtherSections.Clear;
  OtherSections.AddStrings(FSections);

  for I := OtherSections.Count - 1 downto 0 do
  begin
    if OtherSections[I] = CurrentSection then
    begin
      OtherSections.Delete(I);
    end;
  end;

end;

function TFileInfo.HasDuplicateList: Boolean;
begin
  Result := FDuplicateList <> nil;
end;

class function TFileInfo.SectionToPath(const Section: string): string;
begin
  Result := StringReplace(Section, SectionDelimiter, PathDelim, [rfReplaceAll]);
end;

class procedure TFileInfo.SectionToSplitTitle(const Section: string;
  var List: TStringList);
begin
  TCSVFile.Split(List, Section, SectionDelimiter);
end;

procedure TFileInfo.LoadExtraCRCFile(const Filename: string);
var
  FileContent, Parts: TStringList;
  Stream: TStream;
  Line: string;
begin
  if FileExists(Filename) then
  begin
    TLogger.LogInfo(Format('Read CRC-Infos from "%s"', [Filename]));

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
        TCSVFile.Split(Parts, Line, ',');
        SetLength(FExtraCRC, Length(FExtraCRC) + 1);
        FExtraCRC[ High(FExtraCRC)].Filename := Parts[0];
        FExtraCRC[ High(FExtraCRC)].FileSize := StrToInt(Parts[1]);
        FExtraCRC[ High(FExtraCRC)].CRC := Parts[2];
        FExtraCRC[ High(FExtraCRC)].Path := Parts[3];
      end;
      if High(FExtraCRC) = -1 then
      begin
        raise Exception.CreateFmt('No content found in file "%s"!', [Filename]);
      end;
    finally
      Stream.Free;
      Parts.Free;
      FileContent.Free;
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

procedure TFileInfo.DetectSize;
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

class function TFileInfo.DetectType(const Filename: string): TFileType;
const
  MovieExt: array [1 .. 23] of string = ('3g2', '3gp', 'asf', 'avi', 'avi',
    'divx', 'flac', 'f4v', 'flv', 'm1v', 'm4v', 'mkv', 'mov', 'mp4', 'mpe',
    'mpeg', 'mpg', 'mts', 'ogm', 'rm', 'rmvb', 'swf', 'wmv');
  ImageExt: array [1 .. 5] of string = ('bmp', 'gif', 'jpg', 'jpeg', 'png');
  ArchiveExt: array [1 .. 2] of string = ('7z', 'zip');
var
  Extension: string;
begin
  Extension := ExtractFileExt(Filename);
  Delete(Extension, 1, 1);

  if MatchText(Extension, MovieExt) then
  begin
    Result := Movie;
  end
  else if MatchText(Extension, ImageExt) then
  begin
    Result := Image;
  end
  else if MatchText(Extension, ArchiveExt) then
  begin
    Result := Archive;
  end
  else
  begin
    Result := Unknown;
  end;
end;

procedure TFileInfo.UpdateCRC;
begin
  TLogger.LogInfo(Format('Update CRC for file "%s"', [FFullFileName]));
  FCRC := CalcFileCRC32(FFullFileName);
end;

procedure TFileInfo.UpdateThumbnails;
var
  FullThumbnailFilename, FullBigThumbnailFilename, FullThumbnailPath: string;
  ThumbnailImage: TJPEGImage;
begin
  if (FFileType = Movie) or (FFileType = Image) then
  begin
    FullThumbnailPath := FSitePath + PathDelim + FThumbnailPath + PathDelim +
      TStringReplacer.Unicode2Latin(SectionToPath(FFilePath));

    FullThumbnailFilename := FullThumbnailPath + PathDelim +
      TStringReplacer.Unicode2Latin(Key.Filename + FThumbnailExt);
    FullBigThumbnailFilename := FullThumbnailPath + PathDelim +
      TStringReplacer.Unicode2Latin
      (Key.Filename + BigThumbnailExt + FThumbnailExt);

    ForceDirectories(FullThumbnailPath);
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

    FFileLength := FThumbnail.GetVideoLength(FFullFileName);
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
