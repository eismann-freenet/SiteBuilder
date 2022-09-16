{
  Copyright 2014 - 2017 eismann@5H+yXYkQHMnwtQDzJB8thVYAAIs

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

unit Key;

interface

type
  TKeyType = (USK, CHK, SSK);

  TKey = class

  strict private
    FType: TKeyType;
    FCrypto: string; // the part between the @ and the first /
    FFilename: string;
    FEdition: Integer;
    FHasActiveLink: Boolean;

    function GetFilename: string;
    class function GetKeyType(const Key: string): TKeyType;
    function GetKey: string;
    function GetKeyWithoutEdition: string;

  public
    constructor Create(const Key: string; const HasActiveLink: Boolean = true);
    destructor Destroy; override;

    function HasEdition: Boolean;
    procedure SetEdition(const Edition: Integer);

    property Key: string read GetKey;
    property KeyWitoutEdition: string read GetKeyWithoutEdition;
    property KeyType: TKeyType read FType;
    property Filename: string read GetFilename;
    property Edition: Integer read FEdition;
    property HasActiveLink: Boolean read FHasActiveLink;
  end;

implementation

uses
  Classes, CSVFile, SysUtils, TypInfo, StringReplacer;

{ TKey }

constructor TKey.Create(const Key: string; const HasActiveLink: Boolean);
var
  KeyParts: TStringList;
begin
  FType := GetKeyType(Key);
  FEdition := -1; // default edition, if unknown

  // Extract the parts of the key
  KeyParts := TStringList.Create;
  try
    TCSVFile.Split(KeyParts, Key, '/');
    FCrypto := Copy(KeyParts[0], 5);
    FFilename := KeyParts[1];
    if KeyParts.Count = 4 then
    begin
      FEdition := StrToInt(KeyParts[2]);
    end;
  finally
    KeyParts.Free;
  end;

  FHasActiveLink := HasActiveLink;
end;

destructor TKey.Destroy;
begin
  inherited Destroy;
end;

function TKey.GetFilename: string;
begin
  // Does not work with newer versions of Indy,
  // because Freenet-Keys are not completely urlencoded.
  // All Non-Ansi characters are not encoded.
  // Result := TIdURI.URLDecode(KeyParts[1]);

  Result := TStringReplacer.URLDecode(FFilename);
end;

function TKey.GetKey: string;
begin
  Result := GetKeyWithoutEdition;

  if FType = USK then
  begin
    Result := Result + IntToStr(FEdition) + '/';
  end;
end;

class function TKey.GetKeyType(const Key: string): TKeyType;
var
  RawType: string;
  TypeID: Integer;
begin
  RawType := Copy(Key, 1, 3);
  TypeID := GetEnumValue(TypeInfo(TKeyType), RawType);
  if TypeID < 0 then
  begin
    raise Exception.CreateFmt('Invalid KeyType "%s" for key "%s"!',
      [RawType, Key]);
  end;

  Result := TKeyType(TypeID);
end;

function TKey.GetKeyWithoutEdition: string;
begin
  Result := GetEnumName(TypeInfo(TKeyType), Ord(FType))
    + '@' + FCrypto + '/' + FFilename;

  if FType = USK then
  begin
    Result := Result + '/';
  end;
end;

function TKey.HasEdition: Boolean;
begin
  Result := FEdition <> -1;
end;

procedure TKey.SetEdition(const Edition: Integer);
begin
  FEdition := Edition;
end;

end.
