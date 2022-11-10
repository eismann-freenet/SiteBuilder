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

unit BookmarksParser;

interface

uses
  Generics.Collections, Key, SysUtils;

type
  TBookmarksParser = class

  strict private
    FEditions: TDictionary<string, Integer>;

  public
    constructor Create(const Filename: string; const Encoding: TEncoding);
    destructor Destroy; override;

    function GetCurrentEdition(const Key: TKey): Integer;
  end;

implementation

uses
  Classes;

{ TBookmarksParser }

const
  URIPattern = 'URI=';

constructor TBookmarksParser.Create(const Filename: string;
  const Encoding: TEncoding);
var
  FileContent: TStringList;
  FoundPos: Integer;
  Stream: TStream;
  Line: string;
  Key: TKey;
begin
  FEditions := TDictionary<string, Integer>.Create;

  if not FileExists(Filename) then
  begin
    Exit; // ignore missing files
  end;

  Stream := nil;
  FileContent := nil;

  try
    Stream := TFileStream.Create(Filename, fmOpenRead or fmShareDenyNone);
    FileContent := TStringList.Create;

    FileContent.LoadFromStream(Stream, Encoding);

    for Line in FileContent do
    begin
      FoundPos := Pos(URIPattern, Line);
      if FoundPos > 0 then
      begin
        Key := TKey.Create(Copy(Line, FoundPos + Length(URIPattern)));
        try
          FEditions.Add(Key.KeyWitoutEdition, Key.Edition);
        finally
          Key.Free;
        end;
      end;
    end;
  finally
    FileContent.Free;
    Stream.Free;
  end;
end;

destructor TBookmarksParser.Destroy;
begin
  FEditions.Free;
  inherited Destroy;
end;

function TBookmarksParser.GetCurrentEdition(const Key: TKey): Integer;
begin
  try
    Result := FEditions[Key.KeyWitoutEdition];
  except
    on EListError do
    begin
      raise Exception.CreateFmt('Key "%s" was not found in the Bookmarks-File!',
        [Key.KeyWitoutEdition]);
    end;
  end;
end;

end.
