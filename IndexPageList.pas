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

unit IndexPageList;

interface

uses
  IndexPage, Generics.Collections;

type
  TIndexPageList = class(TObjectList<TIndexPage>)

  public
    procedure AddFirst(Value: TIndexPage);

    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  IndexPageComparer;

{ TIndexPageList }

procedure TIndexPageList.AddFirst(Value: TIndexPage);
begin
  Insert(0, Value);
end;

constructor TIndexPageList.Create;
begin
  inherited Create(TIndexPageComparer.Create);
end;

destructor TIndexPageList.Destroy;
begin
  // The object of TIndexPageComparer is automatically destroyed.
  inherited Destroy;
end;

end.
