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

unit Tools;

interface

uses
  Classes;

function Unicode2Latin(const Value: string): string;
function NL2BR(const Value: string): string;
function ReplacesQuotes(const Value: string): string;
procedure Split(var List: TStringList; const Text: string; Delimiter: Char;
  QuoteChar: Char = '"');
function StrCmpLogicalW(const P1, P2: PWideChar): Integer; stdcall;
function HTMLEscapeAll(const Text: string): string;

implementation

uses
  Generics.Collections, SysUtils, HTTPUtil;

function NL2BR(const Value: string): string;
const
  BR = '<br />';
begin
  Result := StringReplace(Value, #13 + #10, BR, [rfReplaceAll]);
  Result := StringReplace(Result, #13, BR, [rfReplaceAll]);  Result := StringReplace(Result, #10, BR, [rfReplaceAll]);end;
function Unicode2Latin(const Value: string): string;
var
  CyrillicAlphabet, GermanAlphabet: TDictionary<Char, string>;
  Letter: Char;
begin
  CyrillicAlphabet := nil;
  GermanAlphabet := nil;

  try
    CyrillicAlphabet := TDictionary<Char, string>.Create;
    GermanAlphabet := TDictionary<Char, string>.Create;
    Result := Value;

    // Replacement rules are required as Freenet can't handle
    // files with non-latin characters in the filename.

    // http://en.wikipedia.org/wiki/Romanization_of_Russian#Transliteration_table
    CyrillicAlphabet.Add('А', 'A');
    CyrillicAlphabet.Add('а', 'a');
    CyrillicAlphabet.Add('И', 'I');
    CyrillicAlphabet.Add('и', 'i');
    CyrillicAlphabet.Add('Н', 'N');
    CyrillicAlphabet.Add('н', 'n');
    CyrillicAlphabet.Add('О', 'O');
    CyrillicAlphabet.Add('о', 'o');
    CyrillicAlphabet.Add('Я', 'Ya');
    CyrillicAlphabet.Add('я', 'ya');

    GermanAlphabet.Add('ß', 'ss');
    GermanAlphabet.Add('ö', 'oe');
    GermanAlphabet.Add('Ö', 'Oe');
    GermanAlphabet.Add('ä', 'ae');
    GermanAlphabet.Add('Ä', 'Ae');
    GermanAlphabet.Add('ü', 'ue');
    GermanAlphabet.Add('Ü', 'Ue');

    for Letter in CyrillicAlphabet.Keys do
    begin
      Result := StringReplace(Result, Letter, CyrillicAlphabet[Letter],
        [rfReplaceAll]);
    end;

    for Letter in GermanAlphabet.Keys do
    begin
      Result := StringReplace(Result, Letter, GermanAlphabet[Letter],
        [rfReplaceAll]);
    end;

  finally
    FreeAndNil(GermanAlphabet);
    FreeAndNil(CyrillicAlphabet);
  end;
end;

function ReplacesQuotes(const Value: string): string;
var
  Quotes: TStringList;
  Letter: string;
begin
  Quotes := TStringList.Create;
  try
    Result := Value;

    Quotes.Add('„');
    Quotes.Add('“');
    Quotes.Add('”');

    for Letter in Quotes do
    begin
      Result := StringReplace(Result, Letter, '"', [rfReplaceAll]);
    end;
  finally
    Quotes.Free;
  end;
end;

function StrCmpLogicalW(const P1, P2: PWideChar): Integer; stdcall;
external 'Shlwapi.dll';

procedure Split(var List: TStringList; const Text: string; Delimiter: Char;
  QuoteChar: Char);
begin
  List.Clear;
  List.Delimiter := Delimiter;
  List.QuoteChar := QuoteChar;
  List.StrictDelimiter := True;
  List.DelimitedText := Text;
end;

function HTMLEscapeAll(const Text: string): string;
begin
  Result := HTMLEscape(Text);
  Result := StringReplace(Result, '#', '%23', [rfReplaceAll]);
end;

end.
