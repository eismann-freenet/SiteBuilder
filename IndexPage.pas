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

unit IndexPage;

interface

uses
  Classes;

type
  TIndexPage = class(TPersistent)

  strict private
    FURL: string;
    FTitle: string;
    FSection: string;

  published
    property URL: string read FURL;
    property Title: string read FTitle;
    property Section: string read FSection;

  public
    constructor Create(const Section, OutputExtension: string);
    destructor Destroy; override;
  end;

implementation

uses
  Tools, SysUtils, FileInfo;

{ TIndexPage }

constructor TIndexPage.Create(const Section, OutputExtension: string);
begin
  FSection := Section;
  FURL := TFileInfo.SectionToUrl(Section, OutputExtension);
  FTitle := TFileInfo.SectionToTitle(Section);
end;

destructor TIndexPage.Destroy;
begin
  inherited Destroy;
end;

end.
