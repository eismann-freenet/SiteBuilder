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

unit IndexPageList;

interface

uses
  IndexPage, Generics.Collections, Classes;

type
  TIndexPageList = class(TPersistent)

  strict private
    FData: TObjectList<TIndexPage>;

  published
    property List: TObjectList<TIndexPage>read FData;

  public
    procedure Add(Value: TIndexPage);
    procedure AddFirst(Value: TIndexPage);
    procedure Sort;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  Tools, Generics.Defaults;

{ TIndexPageList }

procedure TIndexPageList.Add(Value: TIndexPage);
begin
  FData.Add(Value);
end;

procedure TIndexPageList.AddFirst(Value: TIndexPage);
begin
  FData.Insert(0, Value);
end;

constructor TIndexPageList.Create;
begin
  FData := TObjectList<TIndexPage>.Create;
end;

destructor TIndexPageList.Destroy;
begin
  FData.Free;
  inherited Destroy;
end;

procedure TIndexPageList.Sort;
begin
  FData.Sort(TComparer<TIndexPage>.Construct( function(const L,
        R: TIndexPage): Integer begin Result := StrCmpLogicalW(PChar(L.Title),
        PChar(R.Title)); end));
end;

end.
