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

unit TemplateContent;

interface

uses
  SiteBuilder, FileInfoList;

procedure WriteContent(const Section, Filename, Title, InfoContent,
  IndexFilename: string; const Files: TFileInfoList;
  const OutputExtension, SiteKey, CRCPath, CRCFile, SFVFile: string;
  const MaxEdition: Integer; const SiteAuthor, SiteDescription,
  SiteKeywords: string; const TrimHTML: Boolean);

implementation

uses
  Classes, SysUtils, FileInfo, HTTPUtil, StringReplacer, SiteEncoding,
  DuplicateEntry, DuplicateList;

procedure WriteContent(const Section, Filename, Title, InfoContent,
  IndexFilename: string; const Files: TFileInfoList;
  const OutputExtension, SiteKey, CRCPath, CRCFile, SFVFile: string;
  const MaxEdition: Integer; const SiteAuthor, SiteDescription,
  SiteKeywords: string; const TrimHTML: Boolean);
var
  Key, KeyFilename, OtherSection: string;
  DuplicateListHasAudioTracks: Boolean;
  DuplicateEntry: TDuplicateEntry;
  Output, Sections: TStringList;
  DuplicateList: TDuplicateList;
  FileInfo: TFileInfo;
  J: Integer;
begin
  Output := TStringList.Create;
  try
    Output.Add('<!DOCTYPE html>');
    Output.Add('<html lang="en">');
    Output.Add('<head>');
    Output.Add(
      '  <meta http-equiv="content-type" content="text/html; charset=utf-8" />'
      );
    Output.Add('  <meta name="author" content="' + HTMLEscape(SiteAuthor)
        + '" />');
    Output.Add('  <meta name="description" content="' + HTMLEscape
        (SiteDescription) + '" />');
    Output.Add('  <meta name="keywords" content="' + HTMLEscape(SiteKeywords)
        + '" />');
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
    Output.Add('');
    Output.Add(
      '    <dt><label for="crc-file"><abbr title="Cyclic Redundancy Check">CRC</abbr>-File:</label></dt>');
    Output.Add(
      '    <dd><input id="crc-file" type="text" readonly="readonly" value="' +
        SiteKey + IntToStr(MaxEdition) + '/' + TStringReplacer.URLEncode
        (CRCPath + CRCFile) + '" /><br />');
    Output.Add('    <a href="' + TStringReplacer.URLEncode(CRCPath + CRCFile)
        + '?type=text/plain">' + HTMLEscape(CRCFile) + '</a></dd>');
    Output.Add('');
    Output.Add(
      '    <dt><label for="sfv-file"><abbr title="Simple File Verification">SFV</abbr>-File:</label></dt>');
    Output.Add(
      '    <dd><input id="sfv-file" type="text" readonly="readonly" value="' +
        SiteKey + IntToStr(MaxEdition) + '/' + TStringReplacer.URLEncode
        (CRCPath + SFVFile) + '" /><br />');
    Output.Add('    <a href="' + TStringReplacer.URLEncode(CRCPath + SFVFile)
        + '?type=text/plain">' + HTMLEscape(SFVFile) + '</a></dd>');
    Output.Add('');

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

    for FileInfo in Files do
    begin
      Key := FileInfo.Key.Key;
      KeyFilename := FileInfo.Key.Filename;

      Output.Add('');
      if FileInfo.FileType = URL then
      begin
        Output.Add('  <h3>' + HTMLEscape(FileInfo.Description) + '</h3>');
        Output.Add('  <div>');
        Output.Add('    ' + TStringReplacer.FormatKey(FileInfo.Key,
            FileInfo.Description));
        Output.Add('  </div>');
      end
      else
      begin
        Output.Add('  <h3>' + HTMLEscape(KeyFilename) + '</h3>');
        Output.Add('  <dl>');

        Sections := TStringList.Create;
        try
          FileInfo.GetOtherSections(Sections, Section);
          if Sections.Count > 0 then
          begin
            Output.Add('    <dt>Other sections:</dt>');
            Output.Add('    <dd>');
            for J := 0 to Sections.Count - 1 do
            begin
              OtherSection := '      <a href="' + TStringReplacer.URLEncode
                (TFileInfo.SectionToUrl(Sections[J], OutputExtension))
                + '">' + HTMLEscape(TFileInfo.SectionToTitle(Sections[J]))
                + '</a>';
              if J < Sections.Count - 1 then
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
        finally
          Sections.Free;
        end;

        if FileInfo.FileOtherNames <> '' then
        begin
          Output.Add('    <dt>Other filenames:</dt>');
          Output.Add('    <dd>' + TStringReplacer.NL2BR
              (HTMLEscape(FileInfo.FileOtherNames)) + '</dd>');
          Output.Add('');
        end;

        if (FileInfo.AudioTracks <> '') or (FileInfo.AudioType <> NotSet) then
        begin
          Output.Add('    <dt>Audio:</dt>');
          Output.Add('    <dd><a href="#audio-' + FileInfo.Identifier +
              '" class="open-popup"></a>');
          Output.Add('      <a href="#close" class="overlay" id="audio-' +
              FileInfo.Identifier + '"></a>');
          Output.Add('      <div class="popup">');
          Output.Add('        <dl>');

          if FileInfo.AudioTracks <> '' then
          begin
            Output.Add('          <dt>Played music:</dt>');
            Output.Add('          <dd>' + TStringReplacer.NL2BR
                (HTMLEscape(FileInfo.AudioTracks)) + '</dd>');
          end;

          if (FileInfo.AudioTracks <> '') and (FileInfo.AudioType <> NotSet)
            then
          begin
            Output.Add('');
          end;

          if FileInfo.AudioType <> NotSet then
          begin
            Output.Add('          <dt>Audio Type:</dt>');
            Output.Add('          <dd>' + TFileInfo.FormatAudioType
                (FileInfo.AudioType) + '</dd>');
          end;

          Output.Add('        </dl>');
          Output.Add('        <a class="close" href="#close"></a>');
          Output.Add('      </div>');
          Output.Add('    </dd>');
          Output.Add('');
        end;

        if FileInfo.HasDuplicateList then
        begin
          DuplicateList := FileInfo.DuplicateList;
          DuplicateListHasAudioTracks := DuplicateList.HasAudioTracks;

          Output.Add('    <dt>Duplicates:</dt>');
          Output.Add('    <dd><a href="#duplicate-' + FileInfo.Identifier +
              '" class="open-popup"></a>');
          Output.Add('      <a href="#close" class="overlay" id="duplicate-' +
              FileInfo.Identifier + '"></a>');
          Output.Add('      <div class="popup">');
          Output.Add('        <table>');
          Output.Add('          <thead>');
          Output.Add('            <tr>');
          Output.Add('              <th>Filename(s)</th>');

          if DuplicateListHasAudioTracks then
          begin
            Output.Add('              <th>Played music</th>');
          end;

          Output.Add(
            '              <th><abbr title="Cyclic Redundancy Check">CRC</abbr></th>');
          Output.Add('              <th>Reason</th>');
          Output.Add('            </tr>');
          Output.Add('          </thead>');
          Output.Add('          <tbody>');

          for DuplicateEntry in DuplicateList do
          begin
            Output.Add('            <tr>');
            Output.Add('              <td>' + TStringReplacer.NL2BR
                (HTMLEscape(DuplicateEntry.Filenames)) + '</td>');

            if DuplicateListHasAudioTracks then
            begin
              Output.Add('              <td>' + TStringReplacer.NL2BR
                  (HTMLEscape(DuplicateEntry.AudioTracks)) + '</td>');
            end;

            Output.Add('              <td>' + HTMLEscape(DuplicateEntry.CRC)
                + '</td>');
            Output.Add('              <td>' + HTMLEscape
                (DuplicateEntry.GetFormatedReason(Key)) + '</td>');
            Output.Add('            </tr>');
          end;

          Output.Add('          </tbody>');
          Output.Add('        </table>');
          Output.Add('        <a class="close" href="#close"></a>');
          Output.Add('      </div>');
          Output.Add('    </dd>');
          Output.Add('');
        end;

        if FileInfo.Description <> '' then
        begin
          Output.Add('    <dt>Description:</dt>');
          Output.Add('    <dd>' + TStringReplacer.NL2BR
              (HTMLEscape(FileInfo.Description)) + '</dd>');
          Output.Add('');
        end;

        Output.Add('    <dt>Size:</dt>');
        Output.Add('    <dd>' + TFileInfo.FormatFileSize(FileInfo.FileSize)
            + '</dd>');
        Output.Add('');
        Output.Add(
          '    <dt><abbr title="Cyclic Redundancy Check">CRC</abbr>:</dt>');
        Output.Add('    <dd>' + HTMLEscape(FileInfo.CRC) + '</dd>');
        Output.Add('');

        if FileInfo.FileType = Movie then
        begin
          Output.Add('    <dt>Length:</dt>');
          Output.Add('    <dd>' + FileInfo.GetFileLength + ' hh:mm:ss</dd>');
          Output.Add('');
        end;

        Output.Add('    <dt><label for="key-' + FileInfo.Identifier +
            '">Key:</label></dt>');
        Output.Add('    <dd><input id="key-' + FileInfo.Identifier +
            '" type="text" readonly="readonly" value="' + Key + '" /></dd>');
        Output.Add('');
        Output.Add('    <dt>Download:</dt>');
        Output.Add('    <dd><a href="/' + Key + '">' + HTMLEscape(KeyFilename)
            + '</a></dd>');
        Output.Add('  </dl>');

        if (FileInfo.FileType = Movie) or (FileInfo.FileType = Image) then
        begin
          Output.Add('');
          Output.Add('  <div>');
          if FileInfo.HasBigThumbnail then
          begin
            Output.Add('    <a href="' + TStringReplacer.URLEncode
                (FileInfo.BigThumbnailFilename) +
                '" title="view big thumbnail"><img src="' +
                TStringReplacer.URLEncode(FileInfo.ThumbnailFilename)
                + '" alt="thumbnail of the file ' + HTMLEscape(KeyFilename)
                + '" width="' + IntToStr(FileInfo.ThumbnailWidth)
                + '" height="' + IntToStr(FileInfo.ThumbnailHeight)
                + '" /></a>');
          end
          else
          begin
            Output.Add('    <img src="' + TStringReplacer.URLEncode
                (FileInfo.ThumbnailFilename)
                +
                '" alt="thumbnail of the file ' + HTMLEscape(KeyFilename)
                + '" width="' + IntToStr(FileInfo.ThumbnailWidth)
                + '" height="' + IntToStr(FileInfo.ThumbnailHeight) + '" />');
          end;
          Output.Add('  </div>');
        end;
      end;

      Output.Add('');
      Output.Add('  <hr />');
    end;

    Output.Add('');
    Output.Add('  <h2 id="keys"><label for="all">All keys</label></h2>');
    Output.Add('');
    Output.Add('  <div>');
    Output.Add('    <textarea id="all" cols="100" rows="' + IntToStr
        (Files.Count + 2) + '" readonly="readonly">');

    Output.Add(SiteKey + IntToStr(MaxEdition) + '/' + TStringReplacer.URLEncode
        (CRCPath + CRCFile));
    Output.Add(SiteKey + IntToStr(MaxEdition) + '/' + TStringReplacer.URLEncode
        (CRCPath + SFVFile));

    for FileInfo in Files do
    begin
      Output.Add(FileInfo.Key.Key);
    end;
    Output.Add('</textarea>');
    Output.Add('  </div>');
    Output.Add('</body>');
    Output.Add('</html>');

    if TrimHTML then
    begin
      TStringReplacer.TrimStringList(Output);
    end;

    Output.SaveToFile(Filename, TSiteEncoding.Encoding);
  finally
    Output.Free;
  end;
end;

end.
