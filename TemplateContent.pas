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

unit TemplateContent;

interface

uses
  SiteBuilder, FileInfoList;

procedure WriteContent(const Filename, Title, InfoContent,
  IndexFilename: string; const Files: TFileInfoList;
  const OutputExtension, SiteKey, CRCFile, SFVFile: string;
  const MaxEdition: Integer; const SiteAuthor, SiteDescription: string);

implementation

uses
  Classes, SysUtils, FileInfo, HTTPUtil, StringReplacer, SiteEncoding;

procedure WriteContent(const Filename, Title, InfoContent,
  IndexFilename: string; const Files: TFileInfoList;
  const OutputExtension, SiteKey, CRCFile, SFVFile: string;
  const MaxEdition: Integer; const SiteAuthor, SiteDescription: string);
var
  Output: TStringList;
  FileInfo: TFileInfo;
  I, J: Integer;
  OtherSection: string;
begin
  Output := TStringList.Create;
  try
    Output.Add('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"');
    Output.Add('  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">');
    Output.Add(
      '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">');
    Output.Add('<head>');
    Output.Add(
      '  <meta http-equiv="content-type" content="text/html; charset=utf-8" />'
      );
    Output.Add('  <meta http-equiv="content-language" content="en" />');
    Output.Add('  <meta name="language" content="en" />');
    Output.Add('  <meta name="author" content="' + HTMLEscape(SiteAuthor)
        + '" />');
    Output.Add('  <meta name="description" content="' + HTMLEscape
        (SiteDescription) + '" />');
    Output.Add(
      '  <link rel="stylesheet" type="text/css" media="all" href="design.css" />');
    Output.Add('  <title>' + HTMLEscape(Title) + '</title>');
    Output.Add('</head>');
    Output.Add('<body>');
    Output.Add('  <h1>' + HTMLEscape(Title) + '</h1>');
    Output.Add('');
    Output.Add('  <p>');
    Output.Add('    <a href="' + IndexFilename +
        '">&lt; Back to the index</a> | <a href="#keys">All keys</a>');
    Output.Add('  </p>');
    Output.Add('');
    Output.Add('  <h2>Information</h2>');
    Output.Add('');
    Output.Add('  <dl>');
    Output.Add('    <dt>Count of keys:</dt>');
    Output.Add('    <dd>' + IntToStr(Files.List.Count) + '</dd>');
    Output.Add('');
    Output.Add('    <dt>Total size:</dt>');
    Output.Add('    <dd>' + TFileInfo.FormatFileSize(Files.FileSizeSum)
        + '</dd>');
    Output.Add('');
    Output.Add(
      '    <dt><label for="crc-file"><abbr title="Cyclic Redundancy Check">CRC</abbr>-File:</label></dt>');
    Output.Add(
      '    <dd><input id="crc-file" type="text" readonly="readonly" value="' +
        SiteKey + IntToStr(MaxEdition) + '/' + HTMLEscape(CRCFile)
        + '" /></dd>');
    Output.Add(
      '    <dt><label for="sfv-file"><abbr title="Simple File Verification">SFV</abbr>-File:</label></dt>');
    Output.Add(
      '    <dd><input id="sfv-file" type="text" readonly="readonly" value="' +
        SiteKey + IntToStr(MaxEdition) + '/' + HTMLEscape(SFVFile)
        + '" /></dd>');

    if (InfoContent <> '') then
    begin
      Output.Add('');
      Output.Add('    <dt>Note:</dt>');
      Output.Add('    <dd>' + TStringReplacer.NL2BR(HTMLEscape(InfoContent))
          + '</dd>');
    end;

    Output.Add('  </dl>');
    Output.Add('');
    Output.Add('  <h2>Keys</h2>');
    I := 0;
    for FileInfo in Files.List do
    begin
      Inc(I);
      Output.Add('');
      if FileInfo.FileType = URL then
      begin
        Output.Add('  <h3>' + HTMLEscape(FileInfo.Description) + '</h3>');
        Output.Add('  <div>');
        Output.Add('    <a href="/' + FileInfo.Key + '">');
        Output.Add('      <img src="/' + FileInfo.Key +
            'activelink.png" alt="' + HTMLEscape
            (FileInfo.Description) + '" width="108" height="36" />');
        Output.Add('    </a>');
        Output.Add('  </div>');
        Output.Add('');
      end
      else
      begin
        Output.Add('  <h3>' + HTMLEscape(FileInfo.Filename) + '</h3>');
        Output.Add('  <dl>');

        if FileInfo.Sections.Count > 0 then
        begin
          Output.Add('    <dt>Other sections:</dt>');
          Output.Add('    <dd>');
          for J := 0 to FileInfo.Sections.Count - 1 do
          begin
            OtherSection := '      <a href="' + TStringReplacer.HTMLEscapeAll
              (TFileInfo.SectionToUrl(FileInfo.Sections[J], OutputExtension))
              + '">' + HTMLEscape
              (TFileInfo.SectionToTitle(FileInfo.Sections[J])) + '</a>';
            if J < FileInfo.Sections.Count - 1 then
            begin
              Output.Add(OtherSection + '<br />');
            end
            else
            begin
              Output.Add(OtherSection);
            end;
          end;
          Output.Add('    </dd>');
          Output.Add('');
        end;

        if FileInfo.FileOtherNames <> '' then
        begin
          Output.Add('    <dt>Other filenames:</dt>');
          Output.Add('    <dd>' + TStringReplacer.NL2BR
              (HTMLEscape(FileInfo.FileOtherNames)) + '</dd>');
          Output.Add('');
        end;
        if FileInfo.AudioTracks <> '' then
        begin
          Output.Add('    <dt>Played music:</dt>');
          Output.Add('    <dd>' + TStringReplacer.NL2BR
              (HTMLEscape(FileInfo.AudioTracks)) + '</dd>');
          Output.Add('');
        end;
        if FileInfo.Description <> '' then
        begin
          Output.Add('    <dt>Description:</dt>');
          Output.Add('    <dd>' + HTMLEscape(FileInfo.Description) + '</dd>');
          Output.Add('');
        end;
        Output.Add('    <dt>Size:</dt>');
        Output.Add('    <dd>' + TFileInfo.FormatFileSize(FileInfo.FileSize)
            + '</dd>');
        Output.Add('');
        Output.Add(
          '    <dt><abbr title="Cyclic Redundancy Check">CRC</abbr>:</dt>');
        Output.Add('    <dd>' + FileInfo.CRC + '</dd>');
        Output.Add('');

        if FileInfo.FileType = Movie then
        begin
          Output.Add('    <dt>Length:</dt>');
          Output.Add('    <dd>' + FileInfo.FileLength + ' hh:mm:ss</dd>');
          Output.Add('');
        end;
        Output.Add('    <dt><label for="key-' + FileInfo.CRC + '-' + IntToStr
            (FileInfo.FileSize) + '">Key:</label></dt>');
        Output.Add('    <dd><input id="key-' + FileInfo.CRC + '-' + IntToStr
            (FileInfo.FileSize) +
            '" type="text" readonly="readonly" value="' + FileInfo.Key +
            '" /></dd>');
        Output.Add('  </dl>');
        Output.Add('');
        if (FileInfo.FileType = Movie) or (FileInfo.FileType = Image) then
        begin
          Output.Add('  <div>');
          if FileInfo.HasBigThumbnail then
          begin
            Output.Add('    <a title="view big thumbnail" href="' +
                TStringReplacer.HTMLEscapeAll(FileInfo.BigThumbnailFilename)
                + '"><img src="' + TStringReplacer.HTMLEscapeAll
                (FileInfo.ThumbnailFilename)
                +
                '" alt="thumbnail of the file ' + HTMLEscape
                (FileInfo.Filename) + '" width="' + IntToStr
                (FileInfo.ThumbnailWidth) + '" height="' + IntToStr
                (FileInfo.ThumbnailHeight) + '" /></a>');
          end
          else
          begin
            Output.Add('    <img src="' + TStringReplacer.HTMLEscapeAll
                (FileInfo.ThumbnailFilename) +
                '" alt="thumbnail of the file ' + HTMLEscape(FileInfo.Filename)
                + '" width="' + IntToStr(FileInfo.ThumbnailWidth)
                + '" height="' + IntToStr(FileInfo.ThumbnailHeight)
                + '" />');
          end;
          Output.Add('  </div>');
          Output.Add('');
        end;
      end;
      Output.Add('  <hr />');
    end;
    Output.Add('');
    Output.Add('  <h2 id="keys"><label for="all">All keys</label></h2>');
    Output.Add('');
    Output.Add('  <div>');
    Output.Add('    <textarea id="all" cols="100" rows="' + IntToStr(I + 2)
        + '" readonly="readonly">');

    Output.Add(SiteKey + IntToStr(MaxEdition) + '/' + HTMLEscape(CRCFile));
    Output.Add(SiteKey + IntToStr(MaxEdition) + '/' + HTMLEscape(SFVFile));

    for FileInfo in Files.List do
    begin
      Output.Add(FileInfo.Key);
    end;
    Output.Add('</textarea>');
    Output.Add('  </div>');
    Output.Add('</body>');
    Output.Add('</html>');

    Output.SaveToFile(Filename, TSiteEncoding.Encoding);
  finally
    Output.Free;
  end;
end;

end.
