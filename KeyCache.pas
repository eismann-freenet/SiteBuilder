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

unit KeyCache;

interface

uses
  SQLite3Wrap;

type
  TIntegerArray = array of Integer;

  TKeyCache = class

  strict private
    FDB: TSQLite3Database;
    FKeySearchStatement: TSQLite3Statement;
    FCRCSearchStatement: TSQLite3Statement;
    FInsertEntryStatement: TSQLite3Statement;
    FSelectKeyStatement: TSQLite3Statement;
    FSelectFilesizeStatement: TSQLite3Statement;
    FSelectThumbnailHeightStatement: TSQLite3Statement;
    FSelectThumbnailWidthStatement: TSQLite3Statement;
    FSelectBigThumbnailHeightStatement: TSQLite3Statement;
    FSelectBigThumbnailWidthStatement: TSQLite3Statement;
    FSelectVideoLengthStatement: TSQLite3Statement;
    FSelectCRCStatement: TSQLite3Statement;
    FUpdateFilesizeStatement: TSQLite3Statement;
    FUpdateThumbnailHeightStatement: TSQLite3Statement;
    FUpdateThumbnailWidthStatement: TSQLite3Statement;
    FUpdateBigThumbnailHeightStatement: TSQLite3Statement;
    FUpdateBigThumbnailWidthStatement: TSQLite3Statement;
    FUpdateVideoLengthStatement: TSQLite3Statement;
    FUpdateCRCStatement: TSQLite3Statement;
    FInitUsedStatement: TSQLite3Statement;
    FSetUsedStatement: TSQLite3Statement;
    FRemoveUnusedStatement: TSQLite3Statement;
    FInsertDatabaseVersion: TSQLite3Statement;
    FUpdateDatabaseVersion: TSQLite3Statement;
    FSelectDatabaseVersion: TSQLite3Statement;
    FSelectSimilarVideoLength: TSQLite3Statement;

    function GetIntValue(Statement: TSQLite3Statement;
      const KeyID: Integer): Integer;
    function GetStringValue(Statement: TSQLite3Statement;
      const KeyID: Integer): string;
    class procedure UpdateIntValue(Statement: TSQLite3Statement;
      const KeyID: Integer; const Value: Integer);
    class procedure UpdateStringValue(Statement: TSQLite3Statement;
      const KeyID: Integer; const Value: string);

    function GetDatabaseVersion: Integer;
    procedure SetDatabaseVersion(const Version: Integer);

  public
    constructor Create(const DBFilename: string);
    destructor Destroy; override;

    procedure Add(const Key: string; const Filesize, ThumbnailHeight,
      ThumbnailWidth, BigThumbnailHeight, BigThumbnailWidth,
      VideoLength: Integer; const CRC: string);

    procedure UpdateVideoLength(const KeyID, Value: Integer);
    procedure UpdateThumbnailHeight(const KeyID, Value: Integer);
    procedure UpdateThumbnailWidth(const KeyID, Value: Integer);
    procedure UpdateBigThumbnailHeight(const KeyID, Value: Integer);
    procedure UpdateBigThumbnailWidth(const KeyID, Value: Integer);
    procedure UpdateFilesize(const KeyID, Value: Integer);
    procedure UpdateCRC(const KeyID: Integer; const Value: string);

    function GetKeyIDByKey(const Key: string): Integer;
    function GetKeyIDByCRC(const CRC: string): Integer;
    function GetKey(const KeyID: Integer): string;
    function GetVideoLength(const KeyID: Integer): Integer;
    function GetThumbnailHeight(const KeyID: Integer): Integer;
    function GetThumbnailWidth(const KeyID: Integer): Integer;
    function GetBigThumbnailHeight(const KeyID: Integer): Integer;
    function GetBigThumbnailWidth(const KeyID: Integer): Integer;
    function GetFilesize(const KeyID: Integer): Integer;
    function GetCRC(const KeyID: Integer): string;

    function GetSimilarVideoLength(const VideoLength, Difference: Integer)
      : TIntegerArray;

    procedure InitUsed;
    procedure SetUsed(const KeyID: Integer);
    procedure RemoveUnsed;
  end;

implementation

uses
  SQLite3, SysUtils;

{ TKeyCache }

const
  KeyCacheTable = 'KeyCache';
  KeyCacheKeyIndex = 'KeyCacheKeyIndex';
  KeyCacheCRCIndex = 'KeyCacheCRCIndex';
  ColumnID = 'ID';
  ColumnKey = 'Key';
  ColumnFilesize = 'Filesize';
  ColumnThumbnailHeight = 'ThumbnailHeight';
  ColumnThumbnailWidth = 'ThumbnailWidth';
  ColumnBigThumbnailHeight = 'BigThumbnailHeight';
  ColumnBigThumbnailWidth = 'BigThumbnailWidth';
  ColumnVideoLength = 'VideoLength';
  ColumnCRC = 'CRC';
  ColumnUsed = 'Used';
  DatabaseVersionTable = 'DatabaseVersion';
  ColumnVersion = 'Version';
  MaxKeySize = 500;
  CurrentDatabaseVersion = 2;

  CreateDatabaseVersionTableSQL = 'CREATE TABLE IF NOT EXISTS ' +
    DatabaseVersionTable + ' (' + ColumnID +
    ' INTEGER PRIMARY KEY AUTOINCREMENT, ' + ColumnVersion + ' INTEGER);';

  InsertDatabaseVersionSQL = 'INSERT INTO ' + DatabaseVersionTable + ' (' +
    ColumnVersion + ') VALUES (?);';

  UpdateDatabaseVersionSQL = 'UPDATE ' + DatabaseVersionTable + ' SET ' +
    ColumnVersion + ' = ? WHERE ' + ColumnID + ' = ?;';

  SelectDatabaseVersionSQL = 'SELECT ' + ColumnVersion + ' FROM ' +
    DatabaseVersionTable + ' WHERE ' + ColumnID + ' = ?;';

  CreateKeyCacheTableSQL = 'CREATE TABLE IF NOT EXISTS ' + KeyCacheTable +
    ' (' + ColumnID + ' INTEGER PRIMARY KEY AUTOINCREMENT, ' + ColumnKey +
    ' VARCHAR(500), ' + ColumnFilesize + ' INTEGER, ' + ColumnThumbnailHeight +
    ' INTEGER, ' + ColumnThumbnailWidth + ' INTEGER, ' +
    ColumnBigThumbnailHeight + ' INTEGER, ' + ColumnBigThumbnailWidth +
    ' INTEGER, ' + ColumnVideoLength + ' INTEGER, ' + ColumnCRC +
    ' VARCHAR(8), ' + ColumnUsed + ' INTEGER);';

  CreateKeyCacheKeyIndexSQL = 'CREATE UNIQUE INDEX IF NOT EXISTS ' +
    KeyCacheKeyIndex + ' ON ' + KeyCacheTable + ' (' + ColumnKey + ');';

  DropOldKeyCacheKeyIndexSQL = 'DROP INDEX IF EXISTS KeyCacheIndex;';

  CreateKeyCacheCRCIndexSQL = 'CREATE INDEX IF NOT EXISTS ' +
    KeyCacheCRCIndex + ' ON ' + KeyCacheTable + ' (' + ColumnCRC + ');';

  SelectIDByKeySQL = 'SELECT ' + ColumnID + ' FROM ' + KeyCacheTable +
    ' WHERE ' + ColumnKey + ' = ?;';

  SelectIDByCRCSQL = 'SELECT ' + ColumnID + ' FROM ' + KeyCacheTable +
    ' WHERE ' + ColumnCRC + ' = ?;';

  InsertEntrySQL = 'INSERT INTO ' + KeyCacheTable + ' (' + ColumnKey + ', ' +
    ColumnFilesize + ', ' + ColumnThumbnailHeight + ', ' +
    ColumnThumbnailWidth + ', ' +
    ColumnBigThumbnailHeight + ', ' + ColumnBigThumbnailWidth + ', ' +
    ColumnVideoLength + ', ' + ColumnCRC + ', ' + ColumnUsed +
    ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1);';

  SelectKeySQL = 'SELECT ' + ColumnKey + ' FROM ' + KeyCacheTable + ' WHERE ' +
    ColumnID + ' = ?;';

  SelectFilesizeSQL = 'SELECT ' + ColumnFilesize + ' FROM ' + KeyCacheTable +
    ' WHERE ' + ColumnID + ' = ?;';

  SelectThumbnailHeightSQL = 'SELECT ' + ColumnThumbnailHeight + ' FROM ' +
    KeyCacheTable + ' WHERE ' + ColumnID + ' = ?;';

  SelectThumbnailWidthSQL = 'SELECT ' + ColumnThumbnailWidth + ' FROM ' +
    KeyCacheTable + ' WHERE ' + ColumnID + ' = ?;';

  SelectBigThumbnailHeightSQL = 'SELECT ' + ColumnBigThumbnailHeight +
    ' FROM ' + KeyCacheTable + ' WHERE ' + ColumnID + ' = ?;';

  SelectBigThumbnailWidthSQL = 'SELECT ' + ColumnBigThumbnailWidth + ' FROM ' +
    KeyCacheTable + ' WHERE ' + ColumnID + ' = ?;';

  SelectVideoLengthSQL = 'SELECT ' + ColumnVideoLength + ' FROM ' +
    KeyCacheTable + ' WHERE ' + ColumnID + ' = ?;';

  SelectCRCSQL = 'SELECT ' + ColumnCRC + ' FROM ' + KeyCacheTable + ' WHERE ' +
    ColumnID + ' = ?;';

  UpdateFilesizeSQL = 'UPDATE ' + KeyCacheTable + ' SET ' + ColumnFilesize +
    ' = ? WHERE ' + ColumnID + ' = ?;';

  UpdateThumbnailHeightSQL = 'UPDATE ' + KeyCacheTable + ' SET ' +
    ColumnThumbnailHeight + ' = ? WHERE ' + ColumnID + ' = ?;';

  UpdateThumbnailWidthSQL = 'UPDATE ' + KeyCacheTable + ' SET ' +
    ColumnThumbnailWidth + ' = ? WHERE ' + ColumnID + ' = ?;';

  UpdateBigThumbnailHeightSQL = 'UPDATE ' + KeyCacheTable + ' SET ' +
    ColumnBigThumbnailHeight + ' = ? WHERE ' + ColumnID + ' = ?;';

  UpdateBigThumbnailWidthSQL = 'UPDATE ' + KeyCacheTable + ' SET ' +
    ColumnBigThumbnailWidth + ' = ? WHERE ' + ColumnID + ' = ?;';

  UpdateVideoLengthSQL = 'UPDATE ' + KeyCacheTable + ' SET ' +
    ColumnVideoLength + ' = ? WHERE ' + ColumnID + ' = ?;';

  UpdateCRCSQL = 'UPDATE ' + KeyCacheTable + ' SET ' + ColumnCRC +
    ' = ? WHERE ' + ColumnID + ' = ?;';

  InitUsedSQL = 'UPDATE ' + KeyCacheTable + ' SET ' + ColumnUsed + ' = 0;';
  SetUsedSQL = 'UPDATE ' + KeyCacheTable + ' SET ' + ColumnUsed +
    ' = 1 WHERE ' + ColumnID + ' = ?;';
  RemoveUnusedSQL = 'DELETE FROM ' + KeyCacheTable + ' WHERE ' + ColumnUsed +
    ' = 0;';

  SelectSimilarVideoLengthSQL = 'SELECT ' + ColumnID + ' FROM ' +
    KeyCacheTable + ' WHERE ' + ColumnVideoLength +
    ' BETWEEN ? AND ?;';

procedure TKeyCache.Add(const Key: string; const Filesize, ThumbnailHeight,
  ThumbnailWidth, BigThumbnailHeight, BigThumbnailWidth, VideoLength: Integer;
  const CRC: string);
begin
  if Length(Key) > MaxKeySize then
  begin
    raise Exception.CreateFmt('Key "%s" is to long.', [Key]);
  end;
  FInsertEntryStatement.BindText(1, Key);
  FInsertEntryStatement.BindInt(2, Filesize);
  FInsertEntryStatement.BindInt(3, ThumbnailHeight);
  FInsertEntryStatement.BindInt(4, ThumbnailWidth);
  FInsertEntryStatement.BindInt(5, BigThumbnailHeight);
  FInsertEntryStatement.BindInt(6, BigThumbnailWidth);
  FInsertEntryStatement.BindInt(7, VideoLength);
  FInsertEntryStatement.BindText(8, CRC);
  FInsertEntryStatement.StepAndReset;
end;

constructor TKeyCache.Create(const DBFilename: string);
begin
  FDB := TSQLite3Database.Create;

  FDB.Open(DBFilename);

  FDB.Execute(CreateDatabaseVersionTableSQL);
  FDB.Execute(CreateKeyCacheTableSQL);
  FDB.Execute(CreateKeyCacheKeyIndexSQL);
  FDB.Execute(CreateKeyCacheCRCIndexSQL);

  FInsertDatabaseVersion := FDB.Prepare(InsertDatabaseVersionSQL);
  FUpdateDatabaseVersion := FDB.Prepare(UpdateDatabaseVersionSQL);
  FSelectDatabaseVersion := FDB.Prepare(SelectDatabaseVersionSQL);

  FKeySearchStatement := FDB.Prepare(SelectIDByKeySQL);
  FInsertEntryStatement := FDB.Prepare(InsertEntrySQL);

  FCRCSearchStatement := FDB.Prepare(SelectIDByCRCSQL);

  FSelectKeyStatement := FDB.Prepare(SelectKeySQL);
  FSelectFilesizeStatement := FDB.Prepare(SelectFilesizeSQL);
  FSelectThumbnailHeightStatement := FDB.Prepare(SelectThumbnailHeightSQL);
  FSelectThumbnailWidthStatement := FDB.Prepare(SelectThumbnailWidthSQL);
  FSelectBigThumbnailHeightStatement := FDB.Prepare
    (SelectBigThumbnailHeightSQL);
  FSelectBigThumbnailWidthStatement := FDB.Prepare(SelectBigThumbnailWidthSQL);
  FSelectVideoLengthStatement := FDB.Prepare(SelectVideoLengthSQL);
  FSelectCRCStatement := FDB.Prepare(SelectCRCSQL);

  FUpdateFilesizeStatement := FDB.Prepare(UpdateFilesizeSQL);
  FUpdateThumbnailHeightStatement := FDB.Prepare(UpdateThumbnailHeightSQL);
  FUpdateThumbnailWidthStatement := FDB.Prepare(UpdateThumbnailWidthSQL);
  FUpdateBigThumbnailHeightStatement := FDB.Prepare
    (UpdateBigThumbnailHeightSQL);
  FUpdateBigThumbnailWidthStatement := FDB.Prepare(UpdateBigThumbnailWidthSQL);
  FUpdateVideoLengthStatement := FDB.Prepare(UpdateVideoLengthSQL);
  FUpdateCRCStatement := FDB.Prepare(UpdateCRCSQL);

  FInitUsedStatement := FDB.Prepare(InitUsedSQL);
  FSetUsedStatement := FDB.Prepare(SetUsedSQL);
  FRemoveUnusedStatement := FDB.Prepare(RemoveUnusedSQL);

  FSelectSimilarVideoLength := FDB.Prepare(SelectSimilarVideoLengthSQL);

  case GetDatabaseVersion of
    - 1, 0: // missing version
      begin
        SetDatabaseVersion(CurrentDatabaseVersion);
      end;
    1:
      begin
        FDB.Execute(DropOldKeyCacheKeyIndexSQL);
        SetDatabaseVersion(CurrentDatabaseVersion);
      end;
    CurrentDatabaseVersion:
      ; // nothing to do
  else
    raise Exception.Create('Unknown Database-Version!');
  end;
end;

destructor TKeyCache.Destroy;
begin
  FInsertDatabaseVersion.Free;
  FUpdateDatabaseVersion.Free;
  FSelectDatabaseVersion.Free;

  FKeySearchStatement.Free;
  FInsertEntryStatement.Free;

  FCRCSearchStatement.Free;

  FSelectKeyStatement.Free;
  FSelectFilesizeStatement.Free;
  FSelectThumbnailHeightStatement.Free;
  FSelectThumbnailWidthStatement.Free;
  FSelectBigThumbnailHeightStatement.Free;
  FSelectBigThumbnailWidthStatement.Free;
  FSelectVideoLengthStatement.Free;
  FSelectCRCStatement.Free;

  FUpdateFilesizeStatement.Free;
  FUpdateThumbnailHeightStatement.Free;
  FUpdateThumbnailWidthStatement.Free;
  FUpdateBigThumbnailHeightStatement.Free;
  FUpdateBigThumbnailWidthStatement.Free;
  FUpdateVideoLengthStatement.Free;
  FUpdateCRCStatement.Free;

  FInitUsedStatement.Free;
  FSetUsedStatement.Free;
  FRemoveUnusedStatement.Free;

  FSelectSimilarVideoLength.Free;

  FDB.Free;

  inherited Destroy;
end;

function TKeyCache.GetDatabaseVersion: Integer;
begin
  Result := GetIntValue(FSelectDatabaseVersion, 1);
end;

procedure TKeyCache.SetDatabaseVersion(const Version: Integer);
begin
  if GetDatabaseVersion = -1 then
  begin
    FInsertDatabaseVersion.BindInt(1, Version);
    FInsertDatabaseVersion.StepAndReset;
  end
  else
  begin
    UpdateIntValue(FUpdateDatabaseVersion, 1, Version);
  end;
end;

function TKeyCache.GetKey(const KeyID: Integer): string;
begin
  Result := GetStringValue(FSelectKeyStatement, KeyID);
end;

function TKeyCache.GetKeyIDByCRC(const CRC: string): Integer;
begin
  Result := -1;
  FCRCSearchStatement.BindText(1, CRC);
  while FCRCSearchStatement.Step = SQLITE_ROW do
  begin
    Result := FCRCSearchStatement.ColumnInt(0);
  end;
  FCRCSearchStatement.Reset;
end;

function TKeyCache.GetKeyIDByKey(const Key: string): Integer;
begin
  Result := -1;
  FKeySearchStatement.BindText(1, Key);
  while FKeySearchStatement.Step = SQLITE_ROW do
  begin
    Result := FKeySearchStatement.ColumnInt(0);
  end;
  FKeySearchStatement.Reset;
end;

function TKeyCache.GetIntValue(Statement: TSQLite3Statement;
  const KeyID: Integer): Integer;
begin
  Result := -1;
  Statement.BindInt(1, KeyID);
  while Statement.Step = SQLITE_ROW do
  begin
    Result := Statement.ColumnInt(0);
  end;
  Statement.Reset;
end;

function TKeyCache.GetSimilarVideoLength(const VideoLength, Difference: Integer)
  : TIntegerArray;
begin
  SetLength(Result, 0);
  FSelectSimilarVideoLength.BindInt(1, VideoLength - Difference);
  FSelectSimilarVideoLength.BindInt(2, VideoLength + Difference);
  while FSelectSimilarVideoLength.Step = SQLITE_ROW do
  begin
    SetLength(Result, Length(Result) + 1);
    Result[ High(Result)] := FSelectSimilarVideoLength.ColumnInt(0);
  end;
  FSelectSimilarVideoLength.Reset;
end;

function TKeyCache.GetStringValue(Statement: TSQLite3Statement;
  const KeyID: Integer): string;
begin
  Result := '';
  Statement.BindInt(1, KeyID);
  while Statement.Step = SQLITE_ROW do
  begin
    Result := Statement.ColumnText(0);
  end;
  Statement.Reset;
end;

function TKeyCache.GetFilesize(const KeyID: Integer): Integer;
begin
  Result := GetIntValue(FSelectFilesizeStatement, KeyID);
end;

function TKeyCache.GetBigThumbnailHeight(const KeyID: Integer): Integer;
begin
  Result := GetIntValue(FSelectBigThumbnailHeightStatement, KeyID);
end;

function TKeyCache.GetBigThumbnailWidth(const KeyID: Integer): Integer;
begin
  Result := GetIntValue(FSelectBigThumbnailWidthStatement, KeyID);
end;

function TKeyCache.GetThumbnailHeight(const KeyID: Integer): Integer;
begin
  Result := GetIntValue(FSelectThumbnailHeightStatement, KeyID);
end;

function TKeyCache.GetThumbnailWidth(const KeyID: Integer): Integer;
begin
  Result := GetIntValue(FSelectThumbnailWidthStatement, KeyID);
end;

function TKeyCache.GetVideoLength(const KeyID: Integer): Integer;
begin
  Result := GetIntValue(FSelectVideoLengthStatement, KeyID);
end;

procedure TKeyCache.InitUsed;
begin
  FInitUsedStatement.StepAndReset;
end;

procedure TKeyCache.RemoveUnsed;
begin
  FRemoveUnusedStatement.StepAndReset;
end;

procedure TKeyCache.SetUsed(const KeyID: Integer);
begin
  FSetUsedStatement.BindInt(1, KeyID);
  FSetUsedStatement.StepAndReset;
end;

function TKeyCache.GetCRC(const KeyID: Integer): string;
begin
  Result := GetStringValue(FSelectCRCStatement, KeyID);
end;

class procedure TKeyCache.UpdateIntValue(Statement: TSQLite3Statement;
  const KeyID: Integer; const Value: Integer);
begin
  Statement.BindInt(1, Value);
  Statement.BindInt(2, KeyID);
  Statement.StepAndReset;
end;

class procedure TKeyCache.UpdateStringValue(Statement: TSQLite3Statement;
  const KeyID: Integer; const Value: string);
begin
  Statement.BindText(1, Value);
  Statement.BindInt(2, KeyID);
  Statement.StepAndReset;
end;

procedure TKeyCache.UpdateVideoLength(const KeyID, Value: Integer);
begin
  UpdateIntValue(FUpdateVideoLengthStatement, KeyID, Value);
end;

procedure TKeyCache.UpdateBigThumbnailHeight(const KeyID, Value: Integer);
begin
  UpdateIntValue(FUpdateBigThumbnailHeightStatement, KeyID, Value);
end;

procedure TKeyCache.UpdateBigThumbnailWidth(const KeyID, Value: Integer);
begin
  UpdateIntValue(FUpdateBigThumbnailWidthStatement, KeyID, Value);
end;

procedure TKeyCache.UpdateThumbnailHeight(const KeyID, Value: Integer);
begin
  UpdateIntValue(FUpdateThumbnailHeightStatement, KeyID, Value);
end;

procedure TKeyCache.UpdateThumbnailWidth(const KeyID, Value: Integer);
begin
  UpdateIntValue(FUpdateThumbnailWidthStatement, KeyID, Value);
end;

procedure TKeyCache.UpdateFilesize(const KeyID, Value: Integer);
begin
  UpdateIntValue(FUpdateFilesizeStatement, KeyID, Value);
end;

procedure TKeyCache.UpdateCRC(const KeyID: Integer; const Value: string);
begin
  UpdateStringValue(FUpdateCRCStatement, KeyID, Value);
end;

end.
