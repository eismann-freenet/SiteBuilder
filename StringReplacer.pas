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

unit StringReplacer;

interface

uses
  Generics.Collections, PerlRegEx;

type
  TStringReplacer = class

  strict private
    class var FQuotes: TDictionary<Char, string>;
    class var FCyrillicAlphabet: TDictionary<Char, string>;
    class var FGermanAlphabet: TDictionary<Char, string>;
    class var FSpanishAlphabet: TDictionary<Char, string>;
    class var FRegEx: TPerlRegEx;

    class function ReplaceWithDictionary(const Text: string;
      Dictionary: TDictionary<Char, string>): string;

  protected
    class constructor Create;
    class destructor Destroy;

  public
    class function HTMLEscapeAll(const Text: string): string;
    class function NL2BR(const Value: string): string;
    class function Unicode2Latin(const Value: string): string;
    class function ReplacesQuotes(const Value: string): string;
  end;

implementation

{ TStringReplacer }

uses
  HTTPUtil, SysUtils, RegEx;

class constructor TStringReplacer.Create;
begin
  FRegEx := TPerlRegEx.Create;

  FQuotes := TDictionary<Char, string>.Create;
  FQuotes.Add('„', '"');
  FQuotes.Add('“', '"');
  FQuotes.Add('”', '"');

  // Replacement rules are required as Freenet can't handle
  // files with non-latin characters in the filename.

  // http://en.wikipedia.org/wiki/Romanization_of_Russian#Transliteration_table
  FCyrillicAlphabet := TDictionary<Char, string>.Create;
  FCyrillicAlphabet.Add('А', 'A');
  FCyrillicAlphabet.Add('а', 'a');
  FCyrillicAlphabet.Add('Б', 'B');
  FCyrillicAlphabet.Add('б', 'b');
  FCyrillicAlphabet.Add('В', 'V');
  FCyrillicAlphabet.Add('в', 'v');
  FCyrillicAlphabet.Add('Г', 'G');
  FCyrillicAlphabet.Add('г', 'g');
  FCyrillicAlphabet.Add('Д', 'D');
  FCyrillicAlphabet.Add('д', 'd');
  FCyrillicAlphabet.Add('Е', 'E');
  FCyrillicAlphabet.Add('е', 'e');
  FCyrillicAlphabet.Add('Ё', 'E');
  FCyrillicAlphabet.Add('ё', 'e');
  FCyrillicAlphabet.Add('Ж', 'Zh');
  FCyrillicAlphabet.Add('ж', 'zh');
  FCyrillicAlphabet.Add('З', 'Z');
  FCyrillicAlphabet.Add('з', 'z');
  FCyrillicAlphabet.Add('И', 'I');
  FCyrillicAlphabet.Add('и', 'i');
  FCyrillicAlphabet.Add('Й', 'Y');
  FCyrillicAlphabet.Add('й', 'y');
  FCyrillicAlphabet.Add('К', 'K');
  FCyrillicAlphabet.Add('к', 'k');
  FCyrillicAlphabet.Add('Л', 'L');
  FCyrillicAlphabet.Add('л', 'l');
  FCyrillicAlphabet.Add('М', 'M');
  FCyrillicAlphabet.Add('м', 'm');
  FCyrillicAlphabet.Add('Н', 'N');
  FCyrillicAlphabet.Add('н', 'n');
  FCyrillicAlphabet.Add('О', 'O');
  FCyrillicAlphabet.Add('о', 'o');
  FCyrillicAlphabet.Add('П', 'P');
  FCyrillicAlphabet.Add('п', 'p');
  FCyrillicAlphabet.Add('Р', 'R');
  FCyrillicAlphabet.Add('р', 'r');
  FCyrillicAlphabet.Add('С', 'S');
  FCyrillicAlphabet.Add('с', 's');
  FCyrillicAlphabet.Add('Т', 'T');
  FCyrillicAlphabet.Add('т', 't');
  FCyrillicAlphabet.Add('У', 'U');
  FCyrillicAlphabet.Add('у', 'u');
  FCyrillicAlphabet.Add('Ф', 'F');
  FCyrillicAlphabet.Add('ф', 'f');
  FCyrillicAlphabet.Add('Х', 'Kh');
  FCyrillicAlphabet.Add('х', 'kh');
  FCyrillicAlphabet.Add('Ц', 'Ts');
  FCyrillicAlphabet.Add('ц', 'ts');
  FCyrillicAlphabet.Add('Ч', 'Ch');
  FCyrillicAlphabet.Add('ч', 'ch');
  FCyrillicAlphabet.Add('Ш', 'Sh');
  FCyrillicAlphabet.Add('ш', 'sh');
  FCyrillicAlphabet.Add('Щ', 'Shch');
  FCyrillicAlphabet.Add('щ', 'shch');
  FCyrillicAlphabet.Add('Ъ', '');
  FCyrillicAlphabet.Add('ъ', '');
  FCyrillicAlphabet.Add('Ы', 'Y');
  FCyrillicAlphabet.Add('ы', 'y');
  FCyrillicAlphabet.Add('Ь', 'Y');
  FCyrillicAlphabet.Add('ь', 'y');
  FCyrillicAlphabet.Add('Э', 'E');
  FCyrillicAlphabet.Add('э', 'e');
  FCyrillicAlphabet.Add('Ю', 'Yu');
  FCyrillicAlphabet.Add('ю', 'yu');
  FCyrillicAlphabet.Add('Я', 'Ya');
  FCyrillicAlphabet.Add('я', 'ya');

  // http://en.wikipedia.org/wiki/German_language#Present
  FGermanAlphabet := TDictionary<Char, string>.Create;
  FGermanAlphabet.Add('ß', 'ss');
  FGermanAlphabet.Add('ö', 'oe');
  FGermanAlphabet.Add('Ö', 'Oe');
  FGermanAlphabet.Add('ä', 'ae');
  FGermanAlphabet.Add('Ä', 'Ae');
  FGermanAlphabet.Add('ü', 'ue');
  FGermanAlphabet.Add('Ü', 'Ue');

  // http://en.wikipedia.org/wiki/Spanish_orthography#The_alphabet_in_Spanish
  // http://en.wikipedia.org/wiki/Ñ#History
  FSpanishAlphabet := TDictionary<Char, string>.Create;
  FSpanishAlphabet.Add('Ñ', 'NN');
  FSpanishAlphabet.Add('ñ', 'nn');
end;

class destructor TStringReplacer.Destroy;
begin
  FRegEx.Free;
  FQuotes.Free;
  FCyrillicAlphabet.Free;
  FGermanAlphabet.Free;
  FSpanishAlphabet.Free;
end;

class function TStringReplacer.HTMLEscapeAll(const Text: string): string;
begin
  Result := HTMLEscape(Text);
  Result := RegExReplace(FRegEx, Result, '(?<!&)#', '%23');
end;

class function TStringReplacer.NL2BR(const Value: string): string;
const
  BR = '<br />';
begin
  Result := StringReplace(Value, #13 + #10, BR, [rfReplaceAll]);
  Result := StringReplace(Result, #13, BR, [rfReplaceAll]);  Result := StringReplace(Result, #10, BR, [rfReplaceAll]);end;
class function TStringReplacer.Unicode2Latin(const Value: string): string;
begin
  Result := ReplaceWithDictionary(Value, FCyrillicAlphabet);
  Result := ReplaceWithDictionary(Result, FGermanAlphabet);
  Result := ReplaceWithDictionary(Result, FSpanishAlphabet);
end;

class function TStringReplacer.ReplacesQuotes(const Value: string): string;
begin
  Result := ReplaceWithDictionary(Value, FQuotes);
end;

class function TStringReplacer.ReplaceWithDictionary(const Text: string;
  Dictionary: TDictionary<Char, string>): string;
var
  Letter: Char;
begin
  Result := Text;
  for Letter in Dictionary.Keys do
  begin
    Result := StringReplace(Result, Letter, Dictionary[Letter], [rfReplaceAll]);
  end;
end;

end.
