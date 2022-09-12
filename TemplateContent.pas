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

unit TemplateContent;

interface

uses
  SiteBuilder, FileInfoList;

procedure WriteContent(const Filename, Title, InfoContent,
  IndexFilename: string; const Files: TFileInfoList);

implementation

uses
  Classes, SysUtils, FileInfo, HTTPUtil, Tools;

procedure WriteContent(const Filename, Title, InfoContent,
  IndexFilename: string; const Files: TFileInfoList);
var
  Output: TStringList;
  FileInfo: TFileInfo;
  I: Integer;
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
    Output.Add('    <dd>' + IntToStr(Files.Count) + '</dd>');
    Output.Add('');
    Output.Add('    <dt>Total size:</dt>');
    Output.Add('    <dd>' + TFileInfo.FormatFileSize(Files.FileSizeSum)
        + '</dd>');

    if (InfoContent <> '') then
    begin
      Output.Add('');
      Output.Add('    <dt>Note:</dt>');
      Output.Add('    <dd>' + NL2BR(HTMLEscape(InfoContent)) + '</dd>');
    end;

    Output.Add('  </dl>');
    Output.Add('');
    Output.Add('  <h2>Keys</h2>');
    I := 0;
    for FileInfo in Files.GetContent do
    begin
      Inc(I);
      Output.Add('');
      if FileInfo.FileType = URL then
      begin
        Output.Add('  <h3>' + FileInfo.Description + '</h3>');
        Output.Add('  <div>');
        Output.Add('    <a href="/' + FileInfo.Key + '">');
        Output.Add('      <img src="/' + FileInfo.Key +
            'activelink.png" alt="' +
            FileInfo.Description + '" width="108" height="36" />');
        Output.Add('    </a>');
        Output.Add('  </div>');
        Output.Add('');
      end
      else
      begin
        Output.Add('  <h3>' + HTMLEscape(FileInfo.Filename) + '</h3>');
        Output.Add('  <dl>');
        if FileInfo.FileOtherNames <> '' then
        begin
          Output.Add('    <dt>Other filenames:</dt>');
          Output.Add('    <dd>' + NL2BR(HTMLEscape(FileInfo.FileOtherNames))
              + '</dd>');
          Output.Add('');
        end;
        if FileInfo.AudioTracks <> '' then
        begin
          Output.Add('    <dt>Played music:</dt>');
          Output.Add('    <dd>' + NL2BR(HTMLEscape(FileInfo.AudioTracks))
              + '</dd>');
          Output.Add('');
        end;
        if FileInfo.Description <> '' then
        begin
          Output.Add('    <dt>Description:</d8t>');
          Output.Add('    <dd>' + HTMLEscape(FileInfo.Description) + '</dd>');
          Output.Add('');
        end;
        Output.Add('    <dt>Size:</dt>');
        Output.Add('    <dd>' + TFileInfo.FormatFileSize(FileInfo.FileSize)
            + '</dd>');
        Output.Add('');
        if FileInfo.FileType = Movie then
        begin
          Output.Add('    <dt>Length:</dt>');
          Output.Add('    <dd>' + FileInfo.FileLength + ' hh:mm:ss</dd>');
          Output.Add('');
        end;
        Output.Add('    <dt><label for="key' + IntToStr(I)
            + '">Key:</label></dt>');
        Output.Add('    <dd><input id="key' + IntToStr(I) +
            '" type="text" readonly="readonly" value="' + FileInfo.Key +
            '" /></dd>');
        Output.Add('  </dl>');
        Output.Add('');
        if (FileInfo.FileType = Movie) or (FileInfo.FileType = Image) then
        begin
          Output.Add('  <div>');
          Output.Add('    <img src="' + HTMLEscapeAll
              (FileInfo.ThumbnailFilename) +
              '" alt="thumbnail of the file ' + HTMLEscape(FileInfo.Filename)
              + '" width="' + IntToStr(FileInfo.ThumbnailWidth)
              + '" height="' + IntToStr(FileInfo.ThumbnailHeight)
              + '" />');
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
    Output.Add('    <textarea id="all" cols="100" rows="' + IntToStr(I)
        + '" readonly="readonly">');
    for FileInfo in Files.GetContent do
    begin
      Output.Add(FileInfo.Key);
    end;
    Output.Add('</textarea>');
    Output.Add('  </div>');
    Output.Add('</body>');
    Output.Add('</html>');

    Output.SaveToFile(Filename, TEncoding.UTF8);
  finally
    Output.Free;
  end;
end;

end.
