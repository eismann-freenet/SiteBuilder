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

unit TemplateChangelog;

interface

uses
  ChangelogEntryList;

procedure WriteChangelog(const Filename, IndexFilename: string;
  const Changelog: TChangelogEntryList; const SiteAuthor,
  SiteDescription: string);

implementation

uses
  Classes, SysUtils, ChangelogEntry, HTTPUtil, SiteEncoding;

procedure WriteChangelog(const Filename, IndexFilename: string;
  const Changelog: TChangelogEntryList; const SiteAuthor,
  SiteDescription: string);
var
  Output: TStringList;
  ChangelogEntry: TChangelogEntry;
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
    Output.Add('  <title>Changelog</title>');
    Output.Add('</head>');
    Output.Add('<body>');
    Output.Add('  <h1>Changelog</h1>');
    Output.Add('');
    Output.Add('  <p>');
    Output.Add('    <a href="' + IndexFilename +
        '">&lt; Back to the index</a>');
    Output.Add('  </p>');
    Output.Add('');
    Output.Add('  <table border="1">');
    Output.Add('    <thead>');
    Output.Add('      <tr>');
    Output.Add('        <td>Edition</td>');
    Output.Add('        <td>Changes</td>');
    Output.Add('      </tr>');
    Output.Add('    </thead>');
    Output.Add('    <tbody>');

    for ChangelogEntry in Changelog.List do
    begin
      Output.Add('      <tr>');
      Output.Add('        <td>' + IntToStr(ChangelogEntry.Edition) + '</td>');
      Output.Add('        <td>' + HTMLEscape(ChangelogEntry.Description)
          + '</td>');
      Output.Add('      </tr>');
    end;

    Output.Add('    </tbody>');
    Output.Add('  </table>');
    Output.Add('');
    Output.Add('</body>');
    Output.Add('</html>');

    Output.SaveToFile(Filename, TSiteEncoding.Encoding);
  finally
    Output.Free;
  end;
end;

end.
