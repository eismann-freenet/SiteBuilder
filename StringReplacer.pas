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

unit StringReplacer;

interface

uses
  Generics.Collections, Classes, PerlRegEx, Key;

type
  TStringReplacer = class

  strict private
    class var FSpecialChars: TDictionary<string, string>;
    class var FCyrillicAlphabet: TDictionary<string, string>;
    class var FGermanAlphabet: TDictionary<string, string>;
    class var FSpanishAlphabet: TDictionary<string, string>;
    class var FAlbanianAlphabet: TDictionary<string, string>;
    class var FPortugueseAlphabet: TDictionary<string, string>;
    class var FSpecialCharsURL: TDictionary<string, string>;
    class var FRegEx: TPerlRegEx;

  protected
    class constructor Create;
    class destructor Destroy;

  public
    class function ReplaceWithDictionary(const Text: string;
      Dictionary: TDictionary<string, string>): string;
    class function NL2BR(const Value: string): string;
    class function Unicode2Latin(const Value: string): string;
    class function ReplaceSpecialChars(const Value: string): string;
    class function ReplaceNewLine(const Value: string): string;
    class function URLDecode(const Value: string): string;
    class function URLEncode(const Value: string): string;
    class function FormatKey(Value: TKey; const Description: string): string;
    class procedure TrimStringList(List: TStringList);
  end;

implementation

uses
  HTTPUtil, SysUtils;

{ TStringReplacer }

class constructor TStringReplacer.Create;
begin
  FRegEx := TPerlRegEx.Create;

  FSpecialChars := TDictionary<string, string>.Create;
  FSpecialChars.Add('„', '"');
  FSpecialChars.Add('“', '"');
  FSpecialChars.Add('”', '"');
  FSpecialChars.Add('–', '-'); // dash

  // Replacement rules are required as Freenet can't handle
  // files with non-latin characters in the filename.

  // http://en.wikipedia.org/wiki/Romanization_of_Russian#Transliteration_table
  FCyrillicAlphabet := TDictionary<string, string>.Create;
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
  FCyrillicAlphabet.Add('Û', 'Yu');
  FCyrillicAlphabet.Add('ю', 'yu');
  FCyrillicAlphabet.Add('û', 'yu');
  FCyrillicAlphabet.Add('Я', 'Ya');
  FCyrillicAlphabet.Add('я', 'ya');

  // http://en.wikipedia.org/wiki/German_language#Present
  FGermanAlphabet := TDictionary<string, string>.Create;
  FGermanAlphabet.Add('ß', 'ss');
  FGermanAlphabet.Add('ö', 'oe');
  FGermanAlphabet.Add('Ö', 'Oe');
  FGermanAlphabet.Add('ä', 'ae');
  FGermanAlphabet.Add('Ä', 'Ae');
  FGermanAlphabet.Add('ü', 'ue');
  FGermanAlphabet.Add('Ü', 'Ue');

  // http://en.wikipedia.org/wiki/Spanish_orthography#The_alphabet_in_Spanish
  // http://en.wikipedia.org/wiki/Ñ#History
  FSpanishAlphabet := TDictionary<string, string>.Create;
  FSpanishAlphabet.Add('Ñ', 'NN');
  FSpanishAlphabet.Add('ñ', 'nn');

  // https://en.wikipedia.org/wiki/Albanian_alphabet
  FAlbanianAlphabet := TDictionary<string, string>.Create;
  FAlbanianAlphabet.Add('Ë', 'E');
  FAlbanianAlphabet.Add('ë', 'e');

  // https://en.wikipedia.org/wiki/Portuguese_alphabet#Diacritics
  FPortugueseAlphabet := TDictionary<string, string>.Create;
  FPortugueseAlphabet.Add('Ç', 'c');
  FPortugueseAlphabet.Add('ç', 'c');
  FPortugueseAlphabet.Add('Á', 'A');
  FPortugueseAlphabet.Add('á', 'a');
  FPortugueseAlphabet.Add('É', 'E');
  FPortugueseAlphabet.Add('é', 'e');
  FPortugueseAlphabet.Add('Í', 'I');
  FPortugueseAlphabet.Add('í', 'i');
  FPortugueseAlphabet.Add('Ó', 'O');
  FPortugueseAlphabet.Add('ó', 'o');
  FPortugueseAlphabet.Add('Ú', 'U');
  FPortugueseAlphabet.Add('ú', 'u');
  FPortugueseAlphabet.Add('Â', 'A');
  FPortugueseAlphabet.Add('â', 'a');
  FPortugueseAlphabet.Add('Ê', 'E');
  FPortugueseAlphabet.Add('ê', 'e');
  FPortugueseAlphabet.Add('Ô', 'O');
  FPortugueseAlphabet.Add('ô', 'o');
  FPortugueseAlphabet.Add('Ã', 'A');
  FPortugueseAlphabet.Add('ã', 'a');
  FPortugueseAlphabet.Add('Õ', 'O');
  FPortugueseAlphabet.Add('õ', 'o');
  FPortugueseAlphabet.Add('À', 'A');
  FPortugueseAlphabet.Add('à', 'a');

  FSpecialCharsURL := TDictionary<string, string>.Create;
  FSpecialCharsURL.Add('°', 'deg');
end;

class destructor TStringReplacer.Destroy;
begin
  FRegEx.Free;
  FSpecialChars.Free;
  FCyrillicAlphabet.Free;
  FGermanAlphabet.Free;
  FSpanishAlphabet.Free;
  FAlbanianAlphabet.Free;
  FPortugueseAlphabet.Free;
  FSpecialCharsURL.Free;
end;

class function TStringReplacer.FormatKey(Value: TKey;
  const Description: string): string;
begin
  Result := '<a href="/' + Value.Key + '">';
  if Value.HasActiveLink then
  begin
    Result := Result + '<img src="/' + Value.Key + 'activelink.png" alt="' +
      HTMLEscape(Description) + '" width="108" height="36">';
  end
  else
  begin
    Result := Result + HTMLEscape(Description);
  end;
  Result := Result + '</a>';
end;

class function TStringReplacer.NL2BR(const Value: string): string;
const
  BR = '<br>';
begin
  Result := StringReplace(Value, #13, BR, [rfReplaceAll]);
end;

class function TStringReplacer.Unicode2Latin(const Value: string): string;
begin
  Result := ReplaceWithDictionary(Value, FCyrillicAlphabet);
  Result := ReplaceWithDictionary(Result, FGermanAlphabet);
  Result := ReplaceWithDictionary(Result, FSpanishAlphabet);
  Result := ReplaceWithDictionary(Result, FAlbanianAlphabet);
  Result := ReplaceWithDictionary(Result, FPortugueseAlphabet);
  Result := ReplaceWithDictionary(Result, FSpecialCharsURL);
end;

class function TStringReplacer.ReplaceSpecialChars(const Value: string): string;
begin
  Result := ReplaceWithDictionary(Value, FSpecialChars);
end;

class function TStringReplacer.ReplaceNewLine(const Value: string): string;
begin
  Result := StringReplace(Value, #13 + #10, #13, [rfReplaceAll]);
  Result := StringReplace(Result, #10, #13, [rfReplaceAll]);
  Result := StringReplace(Result, '|', #13, [rfReplaceAll]);
end;

class function TStringReplacer.ReplaceWithDictionary(const Text: string;
  Dictionary: TDictionary<string, string>): string;
var
  Letter: string;
begin
  Result := Text;
  for Letter in Dictionary.Keys do
  begin
    Result := StringReplace(Result, Letter, Dictionary[Letter], [rfReplaceAll]);
  end;
end;

// Original-Source:
// https://raw.githubusercontent.com/project-jedi/jvcl/master/tests/Jans/Source/jvStrings.pas
class function TStringReplacer.URLDecode(const Value: string): string;
var
  I: Integer;
  Ch: Char;
begin
  Result := '';
  I := 1;
  while I <= length(Value) do
  begin
    Ch := Value[I];
    case Ch of
      '%':
        begin
          Result := Result + Chr(StrToInt('$' + Value[I + 1] + Value[I + 2]));
          Inc(I, 2);
        end;
    else
      begin
        Result := Result + Ch;
      end;
    end;
    Inc(I);
  end;
end;

// Original-Source:
// https://raw.githubusercontent.com/project-jedi/jvcl/master/tests/Jans/Source/jvStrings.pas
class function TStringReplacer.URLEncode(const Value: string): string;
// Original:
// ValidURLChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789$-_@.&+-!*"''(),;/#?:';
// &+'()#!@, is encoded in a Freenet-Key -> Removed from this list.
const
  ValidURLChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789$-_.-*";/?:';
var
  I: Integer;
begin
  Result := '';
  for I := 1 to length(Value) do
  begin
    if Pos(UpperCase(Value[I]), ValidURLChars) > 0 then
    begin
      Result := Result + Value[I]
    end
    else
    begin
      // TODO:
      // Works only for latin-characters. Every other character
      // is replaced by a transliteration to a latin-character.
      Result := Result + '%';
      Result := Result + AnsiLowerCase(IntToHex(Byte(Value[I]), 2));
    end;
  end;
end;

class procedure TStringReplacer.TrimStringList(List: TStringList);
var
  I: Integer;
begin
  for I := List.Count - 1 downto 0 do
  begin
    List[I] := Trim(List[I]);
    if List[I] = '' then
    begin
      List.Delete(I);
    end;
  end;
end;

end.
