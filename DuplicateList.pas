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

unit DuplicateList;

interface

uses
  Generics.Collections, DuplicateEntry;

type
  TDuplicateList = class(TObjectList<TDuplicateEntry>)
  strict private
    FIsUsed: Boolean;
  public
    constructor Create(const AOwnsObjects: Boolean = True);
    destructor Destroy; override;
    procedure SetUsed(const Value: Boolean);
    function IsUsed: Boolean;
    function HasAudioTracks: Boolean;
  end;

implementation

uses
  DuplicateEntryComparer;

{ TDuplicateList }

constructor TDuplicateList.Create(const AOwnsObjects: Boolean = True);
begin
  inherited Create(TDuplicateEntryComparer.Create, AOwnsObjects);
  SetUsed(false);
end;

destructor TDuplicateList.Destroy;
begin
  // The object of TDuplicateEntryComparer is automatically destroyed.
  inherited Destroy;
end;

function TDuplicateList.HasAudioTracks: Boolean;
var
  DuplicateEntry: TDuplicateEntry;
begin
  Result := false;
  for DuplicateEntry in Self do
  begin
    if DuplicateEntry.AudioTracks <> '' then
    begin
      Result := True;
    end;
  end;
end;

function TDuplicateList.IsUsed: Boolean;
begin
  Result := FIsUsed;
end;

procedure TDuplicateList.SetUsed(const Value: Boolean);
begin
  FIsUsed := Value;
end;

end.
