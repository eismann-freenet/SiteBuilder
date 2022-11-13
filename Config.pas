{
  Copyright 2022 eismann@5H+yXYkQHMnwtQDzJB8thVYAAIs

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

unit Config;

interface

uses
  SysUtils, IniFiles;

type
  TConfig = class

  strict private
    FConfigFile: TMemIniFile;

  public
    constructor Create(const Filename: string);
    destructor Destroy; override;
    function ReadString(Ident: string): string;
    function ReadInteger(Ident: string): Integer;
    function ReadBoolean(Ident: string): Boolean;
    class function GetOutputLocale(): TFormatSettings;
    class function GetFFmpegLocale(): TFormatSettings;
  end;

const
  VIDEO_BIG_THUMBNAIL_COUNT_HORIZONTAL = 'VideoBigThumbnailCountHorizontal';
  VIDEO_BIG_THUMBNAIL_COUNT_VERTICAL = 'VideoBigThumbnailCountVertical';
  VIDEO_BIG_THUMBNAIL_MAX_WIDTH = 'VideoBigThumbnailMaxWidth';
  VIDEO_THUMBNAIL_COUNT_HORIZONTAL = 'VideoThumbnailCountHorizontal';
  VIDEO_THUMBNAIL_COUNT_VERTICAL = 'VideoThumbnailCountVertical';
  VIDEO_THUMBNAIL_MAX_WIDTH = 'VideoThumbnailMaxWidth';
  VIDEO_TIME_FORMAT = 'VideoTimeFormat';
  IMAGE_THUMBNAIL_MAX_HEIGHT = 'ImageThumbnailMaxHeight';
  THUMBNAIL_QUALITY = 'ThumbnailQuality';
  FFMPEG_PATH = 'FFmpegPath';
  IMAGEMAGICK_PATH = 'ImageMagickPath';
  KEY_CACHE_FILENAME = 'KeyCacheFilename';
  CONTENT_PATH = 'ContentPath';
  CONTENT_FILE_EXTENSION = 'ContentFileExtension';
  DUPLICATE_PATH = 'DuplicatePath';
  DUPLICATE_FILE_EXTENSION = 'DuplicateFileExtension';
  CHANGELOG_FILENAME = 'ChangelogFilename';
  DATA_PATH = 'DataPath';
  INFO_FILENAME = 'InfoFilename';
  SITE_PATH = 'SitePath';
  OUTPUT_EXTENSION = 'OutputExtension';
  THUMBNAIL_PATH = 'ThumbnailPath';
  THUMBNAIL_EXTENSION = 'ThumbnailExtension';
  CRC_PATH = 'CRCPath';
  CRC_EXTENSION = 'CRCExtension';
  SFV_EXTENSION = 'SFVExtension';
  SOURCE_FOLDER_SITE = 'SourceFolderSite';
  CONTENT_FOLDER_SITE = 'ContentFolderSite';
  DUPLICATE_FOLDER_SITE = 'DuplicateFolderSite';
  INDEX_FILENAME = 'IndexFilename';
  CHANGELOG_FILENAME_SITE = 'ChangelogFilenameSite';
  STATIC_FILES = 'StaticFiles';
  NEW_KEY_NAME = 'NewKeyName';
  SITE_KEY = 'SiteKey';
  SITE_NAME = 'SiteName';
  SITE_AUTHOR = 'SiteAuthor';
  SITE_DESCRIPTION = 'SiteDescription';
  SITE_KEYWORDS = 'SiteKeywords';
  BOOKMARKS_FILE = 'BookmarksFile';
  TRIM_HTML = 'TrimHTML';

implementation

const
  ConfigKey = 'SiteBuilder';

  OUTPUT_LOCALE = 'en-US';
  FFMPEG_LOCALE = 'en-US';

constructor TConfig.Create(const Filename: string);
begin
  if not FileExists(Filename) then
  begin
    raise Exception.CreateFmt('Configuration-File "%s" is missing!',
      [Filename]);
  end;
  FConfigFile := TMemIniFile.Create(Filename, TEncoding.UTF8);
end;

destructor TConfig.Destroy;
begin
  FConfigFile.Free;
end;

function TConfig.ReadString(Ident: string): string;
begin
  Result := FConfigFile.ReadString(ConfigKey, Ident, '');
end;

function TConfig.ReadInteger(Ident: string): Integer;
begin
  Result := FConfigFile.ReadInteger(ConfigKey, Ident, 0);
end;

function TConfig.ReadBoolean(Ident: string): Boolean;
begin
  Result := FConfigFile.ReadBool(ConfigKey, Ident, false);
end;

class function TConfig.GetOutputLocale(): TFormatSettings;
begin
  Result := TFormatSettings.Create(OUTPUT_LOCALE);
end;

class function TConfig.GetFFmpegLocale(): TFormatSettings;
begin
  Result := TFormatSettings.Create(FFMPEG_LOCALE);
end;

end.
