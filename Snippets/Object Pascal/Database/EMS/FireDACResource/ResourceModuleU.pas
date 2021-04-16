//---------------------------------------------------------------------------

// This software is Copyright (c) 2014 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of Delphi, C++Builder or RAD Studio (Embarcadero Products).
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------
unit ResourceModuleU;

// EMS Resource Module

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  EMS.Services, EMS.ResourceAPI, EMS.ResourceTypes, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.UI.Intf, FireDAC.VCLUI.Wait, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Phys,
  FireDAC.Phys.SQLite, Data.DB, FireDAC.Comp.Client, FireDAC.Comp.UI,
  FireDAC.Stan.StorageJSON, FireDAC.Comp.DataSet, System.Generics.Collections;

type
  [ResourceName('test')]  // Url segment.  For example, use http://localhost:8080/test
  TResourceModule = class(TDataModule)
    dsOrders: TDataSource;
    dsCustomers: TDataSource;
    qOrders: TFDQuery;
    qCustomers: TFDQuery;
    FDSchemaAdapter1: TFDSchemaAdapter;
    FDStanStorageJSONLink1: TFDStanStorageJSONLink;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink;
    FDConnection1: TFDConnection;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure DataSetUpdateError(ASender: TDataSet; AException: EFDException;
      ARow: TFDDatSRow; ARequest: TFDUpdateRequest;
      var AAction: TFDErrorAction);
  private
    FErrorsList: TList<TJSONObject>;
    procedure AddErrorsToBody(const AResponse: TEndpointResponse);
  published
    [EndpointName('GetRecords')] // Name to show in analytics
    procedure Get(const AContext: TEndpointContext; const ARequest: TEndpointRequest; const AResponse: TEndpointResponse);
    [EndpointName('PostUpdates')] // Name to show in  analytics
    procedure Post(const AContext: TEndpointContext; const ARequest: TEndpointRequest; const AResponse: TEndpointResponse);
  end;

procedure Register;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

uses
  System.Variants;

procedure Register;
begin
  RegisterResource(TypeInfo(TResourceModule));
end;

procedure TResourceModule.DataModuleCreate(Sender: TObject);
begin
  FErrorsList := TList<TJSONObject>.create;
end;

procedure TResourceModule.DataModuleDestroy(Sender: TObject);
begin
  FErrorsList.Free;
end;

procedure TResourceModule.DataSetUpdateError(ASender: TDataSet;
  AException: EFDException; ARow: TFDDatSRow; ARequest: TFDUpdateRequest;
  var AAction: TFDErrorAction);
var
  LFieldsList: TStringList;
  I: integer;
  LDataStr: string;
  LDataStrOldValue: string;
  LJSONObject, LJSONArrayItem: TJSONObject;
  LJSONArray: TJSONArray;
begin
  LFieldsList := TStringList.create;
  try
    LJSONObject := TJSONObject.Create;
    try
      LJSONObject.AddPair('ErrorMessage', AException.Message);
      LJSONObject.AddPair('DataSource', ASender.Name);
      ASender.GetFieldNames(LFieldsList);
      LJSONArray := TJSONArray.Create;
      try
        for I := 0 to LFieldsList.Count - 1 do
        begin
          LDataStr := '';
          LDataStrOldValue := '';
          if not VarIsNull(ARow.GetData(LFieldsList[I])) then
            LDataStr := ARow.GetData(LFieldsList[I]);
          if not VarIsNull(ASender.FieldByName(LFieldsList[I]).OldValue) then
            LDataStrOldValue := ASender.FieldByName(LFieldsList[I]).OldValue;

          if LDataStr <> LDataStrOldValue then
          begin
            LJSONArrayItem := TJSONObject.Create;
            try
              LJSONArrayItem.AddPair('RowID', ARow.RowID.ToString);
              LJSONArrayItem.AddPair('FieldName', LFieldsList[I]);
              LJSONArrayItem.AddPair('OldValue', TJSONstring.Create(LDataStrOldValue));
              LJSONArrayItem.AddPair('NewValue', TJSONstring.Create(LDataStr));
              LJSONArray.AddElement(LJSONArrayItem);
            except
              LJSONArrayItem.Free;
              raise;
            end;
          end;
        end;
      except
        LJSONArray.Free;
        raise;
      end;
      LJSONObject.AddPair('Changes', LJSONArray);
      FErrorsList.Add(LJSONObject);
    except
      LJSONObject.Free;
    end;
  finally
    LFieldsList.Free;
  end;
end;

// Get table data
procedure TResourceModule.Get(const AContext: TEndpointContext; const ARequest: TEndpointRequest; const AResponse: TEndpointResponse);
var
  oStr: TMemoryStream;
begin
  oStr := TMemoryStream.Create;
  try
    qCustomers.Open;
    qOrders.Open;
    FDSchemaAdapter1.SaveToStream(oStr, TFDStorageFormat.sfJSON);
    // Response owns stream
    AResponse.Body.SetStream(oStr, 'application/json', True);
  except
    oStr.Free;
  end;
end;

// Apply updates
procedure TResourceModule.Post(const AContext: TEndpointContext;
  const ARequest: TEndpointRequest; const AResponse: TEndpointResponse);
var
  LStream: TStream;
begin
  if not SameText(ARequest.Body.ContentType, 'application/json') then
    AResponse.RaiseBadRequest('content type');
  if not ARequest.Body.TryGetStream(LStream) then
    AResponse.RaiseBadRequest('no stream');
  LStream.Position := 0;
  FDSchemaAdapter1.LoadFromStream(LStream, TFDStorageFormat.sfJSON);
  if FDSchemaAdapter1.ApplyUpdates > 0 then
    AddErrorsToBody(AResponse);
end;

procedure TResourceModule.AddErrorsToBody(const AResponse: TEndpointResponse);
var
  LStream: TStream;
  I: integer;
  LJSONObject : TJSONObject;
  LJSONArray: TJSONArray;
begin
  LJSONObject := TJSONObject.Create;
  try
    LJSONArray := TJSONArray.Create;
    try
      for I := FErrorsList.Count - 1 downto 0 do
        LJSONArray.Add(FErrorsList[I]);

      LJSONObject.AddPair('Errors', LJSONArray);
      AResponse.Body.SetValue(LJSONObject, True);
    except
      LJSONArray.Free;
    end;
  except
    LJSONObject.Free
  end;
  FErrorsList.Clear;
end;


end.


