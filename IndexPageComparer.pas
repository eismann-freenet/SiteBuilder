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

unit IndexPageComparer;

interface

uses
  IndexPage, Generics.Defaults;

type
  TIndexPageComparer = class(TComparer<TIndexPage>)
  public
    function Compare(const Left, Right: TIndexPage): Integer; override;
  end;

implementation

uses
  Sort;

{ TIndexPageListComparer }

function TIndexPageComparer.Compare(const Left, Right: TIndexPage): Integer;
begin
  Result := SortCompare(Left.Title, Right.Title);
end;

end.
