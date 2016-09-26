unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, Menus, ExtCtrls, ActnList, SVNClasses;

type

  { TfMain }

  TfMain = class(TForm)
    actCommit: TAction;
    actShowUnversioned: TAction;
    actFlatMode: TAction;
    actShowModified: TAction;
    actShowUnmodified: TAction;
    actShowConflict: TAction;
    actUpdate: TAction;
    ActionList: TActionList;
    ImageList_22x22: TImageList;
    MainMenu: TMainMenu;
    MenuItem1: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    StatusBar1: TStatusBar;
    SVNFileListView: TListView;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    tvBookMark: TTreeView;
    procedure actCommitExecute(Sender: TObject);
    procedure actFlatModeExecute(Sender: TObject);
    procedure actShowConflictExecute(Sender: TObject);
    procedure actShowModifiedExecute(Sender: TObject);
    procedure actShowUnmodifiedExecute(Sender: TObject);
    procedure actShowUnversionedExecute(Sender: TObject);
    procedure actUpdateExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SVNFileListViewColumnClick(Sender: TObject; Column: TListColumn);
    procedure SVNFileListViewData(Sender: TObject; Item: TListItem);
    procedure tvBookMarkClick(Sender: TObject);
  private
    SVNStatus : TSVNClient;
    RepositoryPath: string;
    Filter: TSVNItemStatusSet;
    procedure LoadBookmarks;
    procedure UpdateFilesListView;
  public

  end;

var
  fMain: TfMain;

implementation
uses LazFileUtils, Config;
{$R *.lfm}

{ TfMain }

procedure TfMain.UpdateFilesListView;
var
  i: integer;
  Item: TListItem;
  SVNItem: TSVNStatusItem;
  Path: string;
  imgIdx: integer;

begin
  SVNFileListView.Clear;
  for i := 0 to SVNStatus.List.Count -1 do
    begin
      SVNItem := SVNStatus.List[i];
      if not (SVNItem.ItemStatus in Filter) then
        Continue;
      Item := SVNFileListView.Items.Add;

      with item do
         begin
       //checkboxes
         Caption := '';
         Checked := SVNItem.Checked;
         //path
         Path := SVNItem.Path;
         if pos(SVNStatus.RepositoryPath, Path) = 1 then
           path := CreateRelativePath(path, SVNStatus.RepositoryPath, false);
         SubItems.Add(Path);

         if (SVNItem.ItemStatus <> sisUnversioned) and
            (SVNItem.ItemStatus <> sisAdded) then
         begin
           //revision
           SubItems.Add(IntToStr(SVNItem.Revision));
           //commit revision
           SubItems.Add(IntToStr(SVNItem.CommitRevision));
           //author
           SubItems.Add(SVNItem.Author);
           //date
           SubItems.Add(DateTimeToStr(SVNItem.Date));
         end
         else
         begin
           //revision
           SubItems.Add('');
           //commit revision
           SubItems.Add('');
           //author
           SubItems.Add('');
           //date
           SubItems.Add('');
         end;

         //extension
         SubItems.Add(SVNItem.Extension);
         //file status
         SubItems.Add(TSVNClient.ItemStatusToStatus(SVNItem.ItemStatus));
         //property status
         SubItems.Add(SVNItem.PropStatus);
         //check if file is versioned
         Case SVNItem.ItemStatus of
          sisAdded:       if SVNItem.IsFolder then imgidx :=  2 else imgidx :=  1;
          sisConflicted:  if SVNItem.IsFolder then imgidx := -1 else imgidx :=  9;
          sisDeleted:     if SVNItem.IsFolder then imgidx := 13 else imgidx := 12;
          sisExternal:    if SVNItem.IsFolder then imgidx := 15 else imgidx := -1;
          sisIgnored:     if SVNItem.IsFolder then imgidx := -1 else imgidx := -1;
          sisIncomplete:  if SVNItem.IsFolder then imgidx := -1 else imgidx := -1;
          sisMerged:      if SVNItem.IsFolder then imgidx := -1 else imgidx := 42;
          sisMissing:     if SVNItem.IsFolder then imgidx := 44 else imgidx := 43;
          sisModified:    if SVNItem.IsFolder then imgidx := 46 else imgidx := 45;
          sisNone:        if SVNItem.IsFolder then imgidx := -1 else imgidx := -1;
          sisNormal:      if SVNItem.IsFolder then imgidx := 18 else imgidx := 56;
          sisObstructed:  if SVNItem.IsFolder then imgidx := -1 else imgidx := -1;
          sisReplaced:    if SVNItem.IsFolder then imgidx := 63 else imgidx := 62;
          sisUnversioned: if SVNItem.IsFolder then imgidx := 54 else imgidx := 53;
        else
          imgidx := -1;
        end;
        ImageIndex:= imgidx;
        StateIndex:= imgidx;

       end;

    end;

  //if Assigned(SVNStatus) then
  //   SVNFileListView.Items.Count:= SVNStatus.List.Count;
end;

procedure TfMain.LoadBookmarks;
var
  st: TStringList;
  i: integer;
  item: TTreeNode;
begin
  st := TStringList.Create;
  tvBookMark.Items[0].DeleteChildren;
  ConfigObj.ReadStrings('Repositories/Path', St);
  for i := 0 to st.Count -1 do
    begin
      item := tvBookMark.Items.AddChild(tvBookMark.Items[0], st[i]);
      item.ImageIndex:= 5;
      item.HasChildren:=true;
    end;
  tvBookMark.Items[0].Expand(False);
  st.free;
end;

procedure TfMain.FormCreate(Sender: TObject);
var
  st: TStringList;
begin
  LoadBookmarks;

  SVNStatus := TSVNClient.Create();
  SVNStatus.SVNExecutable:= ConfigObj.ReadString('SVN/Executable', SVNStatus.SVNExecutable);

  //ConfigObj.WriteString('SVN/Executable',SVNExecutable);
  //st:= TStringList.Create;
  //st.Add(SVNStatus.RepositoryPath);
  //st.Add(SVNStatus.RepositoryPath+'!!');
  //ConfigObj.WriteStrings('Repositories/Path', st);
  //st.free;

  SetColumn(SVNFileListView, 0, 25, '', False);
  SetColumn(SVNFileListView, 1, 200, rsPath, true);
  SetColumn(SVNFileListView, 2, 75, rsRevision, True);
  SetColumn(SVNFileListView, 3, 75, rsCommitRevision, True);
  SetColumn(SVNFileListView, 4, 75, rsAuthor, True);
  SetColumn(SVNFileListView, 5, 75, rsDate, True);
  SetColumn(SVNFileListView, 6, 75, rsExtension, True);
  SetColumn(SVNFileListView, 7, 100, rsFileStatus, True);
  SetColumn(SVNFileListView, 8, 125, rsPropertyStatus, True);

  Filter:=[sisAdded,
           sisConflicted,
           sisDeleted,
           sisExternal,
           sisIgnored,
           sisIncomplete,
           sisMerged,
           sisMissing,
           sisModified,
           sisNone,
           sisNormal,
           sisObstructed,
           sisReplaced,
           sisUnversioned];
  UpdateFilesListView;

  ConfigObj.Flush;

end;

procedure TfMain.actUpdateExecute(Sender: TObject);
begin
  //
end;

procedure TfMain.actCommitExecute(Sender: TObject);
begin
//
end;

procedure TfMain.actFlatModeExecute(Sender: TObject);
begin
  SVNStatus.FlatMode:= actFlatMode.Checked;
  UpdateFilesListView;
end;

procedure TfMain.actShowConflictExecute(Sender: TObject);
begin
  actShowConflict.Checked := not actShowConflict.Checked;
  if actShowConflict.Checked then
    Filter:=Filter + [sisConflicted]
  else
    Filter:=Filter - [sisConflicted];

  UpdateFilesListView;
end;

procedure TfMain.actShowModifiedExecute(Sender: TObject);
begin
  actShowUnmodified.Checked := not actShowUnmodified.Checked;
  if actShowUnmodified.Checked then
    Filter:=Filter + [sisAdded, sisDeleted, sisConflicted, sisModified]
  else
    Filter:=Filter - [sisAdded, sisDeleted, sisConflicted, sisModified];
  UpdateFilesListView;
end;

procedure TfMain.actShowUnmodifiedExecute(Sender: TObject);
begin
  actShowUnmodified.Checked := not actShowUnmodified.Checked;
  if actShowUnmodified.Checked then
    Filter:=Filter + [sisNormal]
  else
    Filter:=Filter - [sisNormal];
  UpdateFilesListView;
end;

procedure TfMain.actShowUnversionedExecute(Sender: TObject);
begin
  actShowUnversioned.Checked := not actShowUnversioned.Checked;
  if actShowUnversioned.Checked then
    Filter:=Filter + [sisUnversioned]
  else
    Filter:=Filter - [sisUnversioned];
  UpdateFilesListView;
end;

procedure TfMain.FormDestroy(Sender: TObject);
begin
  SVNStatus.Free;
end;

procedure TfMain.SVNFileListViewColumnClick(Sender: TObject; Column: TListColumn
  );
begin
  case Column.Index of
    0: SVNStatus.List.ReverseSort(siChecked);
    1: SVNStatus.List.ReverseSort(siPath);
    2: SVNStatus.List.ReverseSort(siExtension);
    3: SVNStatus.List.ReverseSort(siItemStatus);
    4: SVNStatus.List.ReverseSort(siPropStatus);
    5: SVNStatus.List.ReverseSort(siAuthor);
    6: SVNStatus.List.ReverseSort(siRevision);
    7: SVNStatus.List.ReverseSort(siCommitRevision);
    8: SVNStatus.List.ReverseSort(siDate);
  end;

  UpdateFilesListView;
end;

procedure TfMain.SVNFileListViewData(Sender: TObject; Item: TListItem);
var
  StatusItem : TSVNStatusItem;
  Path: string;
  imgidx: integer;
begin
  StatusItem := SVNStatus.List.Items[item.index];


end;

procedure TfMain.tvBookMarkClick(Sender: TObject);
begin
   if not Assigned(tvBookMark.Selected) then
      exit;
   SVNStatus.RepositoryPath := tvBookMark.Selected.Text;

   UpdateFilesListView;
end;

end.

