# SiteBuilder

SiteBuilder is a tool to generate a freesite based on keys stored in CSV files. My freesite [Collection](http://localhost:8888/USK@aOuGVQTefnmtK7bsTNZzQEBL3ah00LZggreGuNMG7lg,FBBMoVkxtEdXNj1bjBvopBof7aQugbqf4tV4Ti0~pIU,AQACAAE/collection/73/) [^2] was generated using SiteBuilder.

Some of the features:

- Automatic generation of a complete freesite. You just need some keys, which you want to share.
- Fully configurable by a INI file and the CSV files.
- Automatic generation of thumbnails.
- Automatic generation of CRC and SFV files.

SiteBuilder is bundled with some very handy programs:

| Program              | Description                                                                                                         |
| -------------------- | ------------------------------------------------------------------------------------------------------------------- |
| SiteBuilder          | See above                                                                                                           |
| CopyFilesFromSection | Copy all files of a section to a folder                                                                             |
| DuplicateChecker     | Checks if a file is already on the freesite. It also looks for known duplicate files and try to find similar videos |
| ThumbnailMaker       | Generate thumbnails of videos                                                                                       |

## Terminology

- A **section** is used to group files into pages. SiteBuilder mirrors your existing directory structure for the usage on the freesite. A full filename is split into `DataPath`, a section and the key. The key correspondences to a existing file, the section is one or more sub folders and the `DataPath` is the remaining part of the full filename. Each key can have multiple sections such that the same key can appear on multiple pages. The first section is the real location of a file.
- **Thumbnails** are reduced-size versions of pictures or videos. For images the thumbnail is always a smaller version of the original image. For videos several frames are extracted, shrinked and added to one image. Normal thumbnails consists of 4 frames per video.
- **Big thumbnails** are normal thumbnails, but with more images, usually consist of 16 frames per video. They will be shown if the user clicks on the thumbnail.

## Requirements

- [Embarcadero Delphi 10.4.2 Sydney Community Edition](https://www.embarcadero.com/products/delphi/starter)
- [FFmpeg](https://ffmpeg.org/), (binary release for Windows)
- [ImageMagick](https://imagemagick.org/), (binary release for Windows)
- [Hyphanet](https://www.hyphanet.org/)

## Build

Pick a program you want to build, open one of the listed project files and press the "Play" button.

| Program              | Project files                                               |
| -------------------- | ----------------------------------------------------------- |
| SiteBuilder          | `SiteBuilderMain.dpr` and `SiteBuilderMain.dproj`           |
| CopyFilesFromSection | `CopyFilesFromSection.dpr` and `CopyFilesFromSection.dproj` |
| DuplicateChecker     | `DuplicateChecker.dpr` and `DuplicateChecker.dproj`         |
| ThumbnailMaker       | `ThumbnailMaker.dpr` and `ThumbnailMaker.dproj`             |

## Additional files

Besides of the compiled program you need these additional files:

- `sqlite3.dll`, for SiteBuilder, CopyFilesFromSection and DuplicateChecker (already included).
- `SiteBuilder.ini` for SiteBuilder, CopyFilesFromSection and DuplicateChecker (see chapter [INI file](#INI-file); already included).
- `ThumbnailMaker-4x1.ini` or `ThumbnailMaker-4x4.ini` for ThumbnailMaker (see chapter [INI file](#INI-file); already included).

## Configuration

The configuration of SiteBuilder is split into these parts:

- Some data files to define the content of the freesite.
- A INI file for the basic configuration.

### Data files

SiteBuilder uses several CSV files to generate your freesite. These files are:

#### Changelog

The changelog contains information about the changes in each edition of the freesite. The CSV file consists of the following columns:

| Column  | Required | Content |
| ------- | -------- | ------- |
| Edition | Yes      | Edition |
| Changes | No       | Changes |

#### Content

The CSV file(s) for the content contains the keys to share. The CSV file(s) consists of the following columns:

| Column                    | Required | Content                                          |
| ------------------------- | -------- | ------------------------------------------------ |
| Sections                  | Yes      | Sections (separated with "\|")                   |
| Key                       | Yes      | Key of the shared file                           |
| Is Big Thumbnail Required | No       | "x" indicates that big thumbnails are required   |
| Is New Key                | No       | "x" indicates a new key                          |
| Other Filenames           | No       | Other filenames (separated with "\|")            |
| Description               | No       | Description                                      |
| Audio Type                | No       | None or Original or Music                        |
| Played Music              | No       | Played music (separated with "\|")               |
| Has Active Link           | No       | "x" indicates freesites, which has an activelink |

#### Duplicates

The CSV file(s) for the duplicates contains information about known duplicate files. The CSV file(s) consists of the following columns:

| Column        | Required | Content                                                                                                                  |
| ------------- | -------- | ------------------------------------------------------------------------------------------------------------------------ |
| Filenames     | No       | Other filenames (separated with "\|")                                                                                    |
| Played Music  | No       | Played music (separated with "\|")                                                                                       |
| CRC           | No       | CRC of the duplicate file                                                                                                |
| Original Keys | No       | Original key(s) (separated with "\|")                                                                                    |
| Reason        | No       | Reason why this file is a duplicate. %OriginalKey% is replaced by the original key, %Index% is replaced by 1st, 2nd, ... |

### INI file

The basic configuration of SiteBuilder is done using a [INI file](https://en.wikipedia.org/wiki/INI_file). Included are 3 versions of this INI file:

- `SiteBuilder.ini` should be used for SiteBuilder, as it contains all required properties.
- `ThumbnailMaker-4x1.ini` should be used with ThumbnailMaker to create thumbnails of 4 columns and 1 row.
- `ThumbnailMaker-4x4.ini` should be used with ThumbnailMaker to create thumbnails of 4 columns and 4 rows.

If SiteBuilder reads a property which does not exists in the given INI file, a default value is used. "" is the default value for strings, 0 is the default value for numbers and false is the default value for boolean.

| Property                         | Type    | Description |
| -------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| VideoBigThumbnailCountHorizontal | Number  | Count of frames in a row of a big thumbnail of a video                                                                                            |
| VideoBigThumbnailCountVertical   | Number  | Count of frames in a column of a big thumbnail of a video                                                                                         |
| VideoBigThumbnailMaxWidth        | Number  | Total width in pixel of a big thumbnail of a video. The width of a single frame is `VideoBigThumbnailMaxWidth` / `VideoBigThumbnailCountVertical` |
| VideoThumbnailCountHorizontal    | Number  | Count of frames in a row of a thumbnail of a video                                                                                                |
| VideoThumbnailCountVertical      | Number  | Count of frames in a column of a thumbnail of a video                                                                                             |
| VideoThumbnailMaxWidth           | Number  | Total width in pixel of the thumbnail of a video. The width of a single frame is `VideoThumbnailMaxWidth` / `VideoThumbnailCountVertical`         |
| VideoTimeFormat                  | String  | Display [format](https://docwiki.embarcadero.com/Libraries/Alexandria/en/System.SysUtils.Format) of the timestamp in each frame                   |
| ImageThumbnailMaxHeight          | Number  | Maximum height of the thumbnail of an image                                                                                                       |
| ThumbnailQuality                 | Number  | Compression level for the thumbnails, 1 = lowest image to 100 = best quality. Value is passed to ImageMagick as `-quality value`                  |
| FFmpegPath                       | String  | Path to FFmpeg. This is the path where `FFmpeg.exe` is located                                                                                    |
| ImageMagickPath                  | String  | Path to ImageMagick. This is the path where `convert.exe` and `montage.exe` are located                                                           |
| KeyCacheFilename                 | String  | Filename of the SQLite database of SiteBuilder. The database is used to cache various information like file size or length of a video             |
| ContentPath                      | String  | Folder of the [content](#Content) files for SiteBuilder. Place your CSV files with the keys here                                                  |
| ContentFileExtension             | String  | Filename extension of the content files                                                                                                           |
| DuplicatePath                    | String  | Folder of the [duplicate](#Duplicates) files for SiteBuilder. Place your CSV-Files with the duplicates here                                       |
| DuplicateFileExtension           | String  | Filename extension of the duplicate files                                                                                                         |
| ChangelogFilename                | String  | Filename of the [Changelog](#Changelog) file                                                                                                      |
| DataPath                         | String  | This is the folder, where SiteBuilder looks for the data files                                                                                    |
| InfoFilename                     | String  | Filename of the Info file, which is read and displayed for each section                                                                           |
| SitePath                         | String  | This is the folder, where SiteBuilder generates your freesite.                                                                                    |
| OutputExtension                  | String  | Filename extension of your HTML files of your freesite                                                                                            |
| ThumbnailPath                    | String  | Folder inside your `SitePath`. All generated thumbnails are stored in sub folders within this folder                                              |
| ThumbnailExtension               | String  | The filename extension of your thumbnails                                                                                                         |
| CRCPath                          | String  | Folder inside your `SitePath`. All generated CRC files and SFV files are stored in sub folders within this folder                                 |
| CRCExtension                     | String  | Filename extension for the generated CRC files                                                                                                    |
| SFVExtension                     | String  | Filename extension for the generated SFV files                                                                                                    |
| SourceFolderSite                 | String  | Folder inside your `SitePath`                                                                                                                     |
| ContentFolderSite                | String  | Folder inside your `SitePath`. All content files are copied into this folder                                                                      |
| DuplicateFolderSite              | String  | Folder inside your `SitePath`. All duplicate files are copied into this folder                                                                    |
| IndexFilename                    | String  | Filename without extension of the index page                                                                                                      |
| ChangelogFilenameSite            | String  | Filename without extension of your changelog page                                                                                                 |
| StaticFiles                      | String  | List of files, which are simply copied from the current folder into `SitePath`. The files are separated with "\|"                                 |
| NewKeyName                       | String  | Name of the section, which shows your newest keys                                                                                                 |
| SiteKey                          | String  | Keys of your site without the edition                                                                                                             |
| SiteName                         | String  | Name of your freesite                                                                                                                             |
| SiteAuthor                       | String  | Author of the freesite                                                                                                                            |
| SiteDescription                  | String  | Description of your freesite                                                                                                                      |
| SiteKeywords                     | String  | Keywords of your freesite                                                                                                                         |
| BookmarksFile                    | String  | Filename of the bookmarks.dat in your installation of Hyphanet. Required to find the latest edition of USK keys                                   |
| TrimHTML                         | Boolean | 1 = remove trailing and leading spaces of the HTML output, 0 = HTML output is nicely formated                                                     |
| PauseOnExit                      | Boolean | 1 = Pause on exit, 0 = No pause on exit (useful when used from command line)                                                                      |

## Example

Use the INI file `SiteBuilder.ini` with the CSV files in `data` and the sample files in `data-files` to generate a example freesite. You just have to add FFmpeg and ImageMagick.

## Run

| Program              | Usage                                                                                                            |
| -------------------- | ---------------------------------------------------------------------------------------------------------------- |
| SiteBuilder          | `SiteBuilderMain.exe SiteBuilder.ini`                                                                            |
| CopyFilesFromSection | `CopyFilesFromSection.exe SiteBuilder.ini section-to-copy target-path`                                           |
| DuplicateChecker     | `DuplicateChecker.exe SiteBuilder.ini file-to-check`                                                             |
| ThumbnailMaker       | `ThumbnailMaker.exe ThumbnailMaker-4x1.ini video-file` or `ThumbnailMaker.exe ThumbnailMaker-4x4.ini video-file` |

## Libraries

SiteBuilder is using the following libraries, which are included in the archive:

- [CRC32.pas](http://web.archive.org/web/20190612171808/http://efg2.com/Lab/Mathematics/FileCheck.htm) from [FileCheck.zip](http://web.archive.org/web/20140706173556/http://efg2.com/Lab/Mathematics/FileCheck.ZIP) (slightly modified)
- [SQLite](https://github.com/plashenkov/SQLite3-Delphi-FPC) (requires [sqlite3.dll](https://www.sqlite.org/download.html))

## Contact

Author: eismann

Freemail: eismann@vu6osveg7rpxh2ckrh7ivdyilprn52px2gtxtp4bxjckn46oc6ia.freemail [^1]

Frost: eismann@5H+yXYkQHMnwtQDzJB8thVYAAIs

FMS: eismann

Sone: [eismann](http://localhost:8888/Sone/viewSone.html?sone=rTzpVIb8X3PoSon~io8IW~Le6ffRp3m-gbpEpvPOF5A) [^2]

I do not regularly read the email associated with GitHub.

## License

SiteBuilder by eismann@5H+yXYkQHMnwtQDzJB8thVYAAIs is licensed under the [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).

[^1]: Freemail requires a running Hyphanet node
[^2]: Link requires a running Hyphanet node at http://localhost:8888/
