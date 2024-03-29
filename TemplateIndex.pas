﻿{
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

unit TemplateIndex;

interface

uses
  IndexPageList;

procedure WriteIndex(const Filename, ChangelogFile, SiteKey, SiteName,
  SiteAuthor, SiteDescription, SiteKeywords: string; const MaxEdition: Integer;
  const Pages: TIndexPageList; const TrimHTML: Boolean);

implementation

uses
  Classes, SysUtils, IndexPage, HTTPUtil, SiteEncoding, StringReplacer,
  FileInfo;

function Spaces(const Count: Integer): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Count - 1 do
  begin
    Result := Result + ' ';
  end;
end;

procedure NormalizeLevel(var Output: TStringList; var OpenLevel: Integer;
  const I: Integer);
begin
  while OpenLevel > I do
  begin
    Dec(OpenLevel);
    Output.Add(Spaces(6 + (4 * OpenLevel)) + '</ul>');
    Output.Add(Spaces(4 + (4 * OpenLevel)) + '</li>');
  end;
  while OpenLevel < I do
  begin
    Output.Add(Spaces(6 + (4 * OpenLevel)) + '<ul>');
    Inc(OpenLevel);
  end;
end;

procedure WriteIndex(const Filename, ChangelogFile, SiteKey, SiteName,
  SiteAuthor, SiteDescription, SiteKeywords: string; const MaxEdition: Integer;
  const Pages: TIndexPageList; const TrimHTML: Boolean);
var
  Output, LastTitleParts, TitleParts: TStringList;
  Page, NextPage: TIndexPage;
  OpenLevel, I, J: Integer;
begin
  Output := nil;
  TitleParts := nil;
  LastTitleParts := nil;

  try
    Output := TStringList.Create;
    TitleParts := TStringList.Create;
    LastTitleParts := TStringList.Create;

    Output.Add('<!DOCTYPE html>');
    Output.Add('<html lang="en">');
    Output.Add('<head>');
    Output.Add
      ('  <meta http-equiv="content-type" content="text/html; charset=utf-8">');
    Output.Add('  <meta name="author" content="' +
      HTMLEscape(SiteAuthor) + '">');
    Output.Add('  <meta name="description" content="' +
      HTMLEscape(SiteDescription) + '">');
    Output.Add('  <meta name="keywords" content="' +
      HTMLEscape(SiteKeywords) + '">');
    Output.Add('  <link rel="stylesheet" href="design.css">');
    Output.Add('  <title>' + HTMLEscape(SiteName) + '</title>');
    Output.Add('</head>');
    Output.Add('<body>');
    Output.Add('  <h1>' + HTMLEscape(SiteName) + '</h1>');
    Output.Add('');
    Output.Add('  <ul>');

    OpenLevel := 0;

    for I := 0 to Pages.Count - 1 do
    begin
      Page := Pages[I];
      if I < Pages.Count - 1 then
      begin
        NextPage := Pages[I + 1];
      end
      else
      begin
        NextPage := nil;
      end;
      TFileInfo.SectionToSplitTitle(Page.Section, TitleParts);
      while LastTitleParts.Count < TitleParts.Count do
      begin
        LastTitleParts.Add('');
      end;

      for J := 0 to TitleParts.Count - 1 do
      begin

        if J < TitleParts.Count - 1 then
        begin
          if TitleParts[J] <> LastTitleParts[J] then
          begin
            NormalizeLevel(Output, OpenLevel, J);

            Output.Add(Spaces(4 + (4 * OpenLevel)) + '<li>' +
              HTMLEscape(TitleParts[J]));
            Output.Add(Spaces(6 + (4 * OpenLevel)) + '<ul>');
            Inc(OpenLevel);
          end;
        end
        else
        begin
          NormalizeLevel(Output, OpenLevel, J);

          Output.Add(Spaces(4 + (4 * OpenLevel)) + '<li>' + '<a href="' +
            TStringReplacer.URLEncode(Page.URL) + '">' +
            HTMLEscape(TitleParts[J]) + '</a>');
          if (NextPage = nil) or (Pos(Page.Title + ' > ', NextPage.Title) = 0)
          then
          begin
            Output[Output.Count - 1] := Output[Output.Count - 1] + '</li>';
          end;
        end;
      end;

      // Output.Add('    <li><a href="' + Page.URL + '">' + Page.Title + '</a></li>');
      LastTitleParts.Clear;
      LastTitleParts.AddStrings(TitleParts);
    end;
    NormalizeLevel(Output, OpenLevel, 0);

    Output.Add('  </ul>');
    Output.Add('');
    Output.Add('  <p>');
    Output.Add('    <a href="/' + SiteKey +
      '-1/">Check for newer versions of this freesite</a>');
    Output.Add('    |');
    Output.Add('    <a href="/?newbookmark=' + SiteKey + IntToStr(MaxEdition) +
      '/&amp;desc=' + HTMLEscape(SiteName) +
      '&amp;hasAnActivelink=true">Bookmark this Freesite</a>');
    Output.Add('    |');
    Output.Add('    <a href="about.htm">About</a>');
    Output.Add('    |');
    Output.Add('    <a href="' + ChangelogFile + '">Changelog</a>');
    Output.Add('  </p>');
    Output.Add('');
    Output.Add('</body>');
    Output.Add('</html>');

    if TrimHTML then
    begin
      TStringReplacer.TrimStringList(Output);
    end;

    Output.SaveToFile(Filename, TSiteEncoding.Encoding);
  finally
    LastTitleParts.Free;
    TitleParts.Free;
    Output.Free;
  end;
end;

end.
