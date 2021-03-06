unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, Data.Bind.EngExt,
  Fmx.Bind.DBEngExt, Data.FMTBcd, Data.DB,
  Data.Bind.Components, Data.Bind.DBScope, FMX.StdCtrls, FMX.ListView.Types,
  System.Rtti, System.Bindings.Outputs, Fmx.Bind.Editors, FMX.ListView,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.Async, FireDAC.DApt, FireDAC.UI.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Phys, FireDAC.FMXUI.Wait, FireDAC.Comp.UI,
  FireDAC.Phys.IBBase, FireDAC.Phys.IB, FireDAC.Comp.Client,
  FireDAC.Comp.DataSet, FireDAC.Phys.IBDef, FMX.Controls.Presentation;

type
  TIBLiteForm = class(TForm)
    BindingsList1: TBindingsList;
    BindSourceDB1: TBindSourceDB;
    ToolBar1: TToolBar;
    AddButton: TButton;
    DeleteButton: TButton;
    Label1: TLabel;
    ListView1: TListView;
    LinkFillControlToField1: TLinkFillControlToField;
    FDQueryDelete: TFDQuery;
    FDQueryInsert: TFDQuery;
    FDTableTask: TFDTable;
    FireTaskList: TFDConnection;
    FDPhysIBDriverLink1: TFDPhysIBDriverLink;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    procedure AddButtonClick(Sender: TObject);
    procedure DeleteButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TaskListBeforeConnect(Sender: TObject);
  private
    { Private declarations }
    procedure OnIdle(Sender: TObject; var ADone: Boolean);
{$IFDEF OSX}
    function GetResourcesDir: string;
{$ENDIF OSX}
  public
    { Public declarations }
  end;

var
  IBLiteForm: TIBLiteForm;

implementation

{$R *.fmx}

uses
{$IFDEF OSX}
  Macapi.Foundation,
{$ENDIF OSX}
  System.iOUTils;

procedure TIBLiteForm.AddButtonClick(Sender: TObject);
var
  TaskName: String;
  LPrompt: String;
  LDefaultValue: String;
begin
  try
    LPrompt := 'Task';
    LDefaultValue := '';

    InputQuery('Enter New Task', LPrompt, LDefaultValue,
      procedure(const AResult: TModalResult; const AValues: array of string)
      begin
        if AResult = mrOk then
          TaskName := AValues[0]
        else
          TaskName := '';
        if not (TaskName.Trim = '') then
        begin
          FDQueryInsert.ParamByName('TaskName').AsString := TaskName;
          FDQueryInsert.ExecSQL();
          FDTableTask.Refresh;
          LinkFillControlToField1.BindList.FillList;
        end;
      end);

  except
    on e: Exception do
    begin
      ShowMessage(e.Message);
    end;
  end;
end;

procedure TIBLiteForm.DeleteButtonClick(Sender: TObject);
var
  TaskName: string;
begin
  TaskName := ListView1.Selected.Text;
  try
    FDQueryDelete.ParamByName('TaskName').AsString := TaskName;
    FDQueryDelete.ExecSQL;
    FDTableTask.Refresh;
    LinkFillControlToField1.BindList.FillList;
    if (ListView1.Selected = nil) and (ListView1.Items.Count > 0) then
      // Select last item
      ListView1.ItemIndex := ListView1.Items.Count - 1;
  except
    on e: Exception do
    begin
      ShowMessage(e.Message);
    end;
  end;
end;

procedure TIBLiteForm.FormCreate(Sender: TObject);
begin
  try
    // For unidirectional dataset, don't refill automatically when dataset is activated
    // because dataset is reactivated everytime use DataSet.First.
    LinkFillControlToField1.AutoActivate := False;
    LinkFillControlToField1.AutoFill := False;
    Application.OnIdle := OnIdle;
    FireTaskList.Connected := True;
    FDTableTask.Active := True;
    LinkFillControlToField1.BindList.FillList;
  except
    on e: Exception do
    begin
      ShowMessage(e.Message);
    end;
  end;
end;

{$IFDEF OSX}
function TIBLiteForm.GetResourcesDir: string;
var
  Bundle: NSBundle;
begin
  Bundle := TNSBundle.Wrap(TNSBundle.OCClass.mainBundle);
  Result := UTF8ToString(Bundle.resourcePath.UTF8String);
end;
{$ENDIF OSX}

procedure TIBLiteForm.OnIdle(Sender: TObject; var ADone: Boolean);
begin
  DeleteButton.Visible := ListView1.Selected <> nil;
end;

procedure TIBLiteForm.TaskListBeforeConnect(Sender: TObject);
begin
  {$IF DEFINED(IOS) or DEFINED(ANDROID)}
  FireTaskList.Params.Values['Database'] := TPath.GetDocumentsPath + PathDelim + 'TASKS.GDB';
  {$ELSE}
  {$IFDEF OSX}
    FireTaskList.Params.Values['Database'] := GetHomePath + PathDelim + 'TASKS.GDB';
  {$ELSE}
    FireTaskList.Params.Values['Database'] := GetCurrentDir + PathDelim + 'TASKS.GDB';
  {$ENDIF}
  {$ENDIF}
  FireTaskList.Params.Values['User_name'] := 'sysdba';
  FireTaskList.Params.Values['Password'] := 'masterkey';
end;

end.
