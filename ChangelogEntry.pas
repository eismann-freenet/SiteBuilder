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

unit ChangelogEntry;

interface

uses
  Classes;

type
  TChangelogEntry = class(TPersistent)

  strict private
    FEdition: Integer;
    FDescription: string;

  published
    property Edition: Integer read FEdition;
    property Description: string read FDescription;

  public
    constructor Create(const Edition: Integer; const Description: string);
    destructor Destroy; override;
  end;

implementation

{ TChangelogEntry }

constructor TChangelogEntry.Create(const Edition: Integer;
  const Description: string);
begin
  FEdition := Edition;
  FDescription := Description;
end;

destructor TChangelogEntry.Destroy;
begin
  inherited Destroy;
end;

end.
