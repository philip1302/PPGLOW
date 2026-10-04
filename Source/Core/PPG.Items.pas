unit PPG.Items;

{ Item-Modell der Listen-Controls (ListBox, Baum, Grid, Combo-Liste).

  Ein Control kennt nur IPPGItemSource (Dependency Inversion), nie die
  konkrete Datenhaltung. Drei Quellen:
  - TPPGCollectionSource : TPPGItems (TOwnedCollection, im Designer pflegbar)
  - TPPGStringsSource    : TStrings (DFM-kompatibel zu TListBox.Items)
  - TPPGVirtualSource    : nur Anzahl + OnGetItem (Millionen Eintraege,
                           Daten bleiben beim Anwender)

  Aenderungen meldet eine Quelle ueber OnChanged(Index): Index >= 0 = genau
  dieser Eintrag (nur neu zeichnen), -1 = Struktur (Anzahl/Reihenfolge). }

{$I ..\PPG.inc}

interface

uses
  System.Classes, Vcl.StdCtrls, PPG.Types;

type
  /// Alle Angaben zu einem Eintrag (ein Aufruf pro Eintrag und Paint).
  TPPGItemData = record
    Text: string;
    Detail: string;     // zweite Zeile (dezenter)
    Badge: string;      // kleine Plakette rechts (z.B. Anzahl)
    Group: string;      // Gruppen-Ueberschrift (gleiche Gruppe = gleicher Text)
    ImageIndex: Integer;
    Checked: TCheckBoxState;
    Enabled: Boolean;
    IsHeader: Boolean;  // Ueberschrift-Zeile (nicht waehlbar, ohne Kaestchen)
    Data: Pointer;
  end;

  TPPGItemsChangeEvent = procedure(Sender: TObject; Index: Integer) of object;

  IPPGItemSource = interface
    ['{7D3E9B15-4A60-4C2F-9E81-B0A5C6D7E214}']
    function Count: Integer;
    procedure GetItem(Index: Integer; var Data: TPPGItemData);
    /// Haekchen setzen (Anwender-Aktion); False = Quelle kann das nicht.
    function SetChecked(Index: Integer; Value: TCheckBoxState): Boolean;
    function GetOnChanged: TPPGItemsChangeEvent;
    procedure SetOnChanged(const Value: TPPGItemsChangeEvent);
    property OnChanged: TPPGItemsChangeEvent read GetOnChanged write SetOnChanged;
  end;

  TPPGItem = class(TCollectionItem)
  private
    FText: string;
    FDetail: string;
    FBadge: string;
    FGroup: string;
    FImageIndex: TPPGImageIndex;
    FChecked: TCheckBoxState;
    FEnabled: Boolean;
    FTag: NativeInt;
    FData: Pointer;
    procedure SetText(const Value: string);
    procedure SetDetail(const Value: string);
    procedure SetBadge(const Value: string);
    procedure SetGroup(const Value: string);
    procedure SetImageIndex(const Value: TPPGImageIndex);
    procedure SetChecked(const Value: TCheckBoxState);
    procedure SetEnabled(const Value: Boolean);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    property Data: Pointer read FData write FData;
  published
    property Text: string read FText write SetText;
    property Detail: string read FDetail write SetDetail;
    property Badge: string read FBadge write SetBadge;
    property Group: string read FGroup write SetGroup;
    property ImageIndex: TPPGImageIndex read FImageIndex write SetImageIndex default -1;
    property Checked: TCheckBoxState read FChecked write SetChecked default cbUnchecked;
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property Tag: NativeInt read FTag write FTag default 0;
  end;

  TPPGItems = class(TOwnedCollection)
  private
    FOnChange: TPPGItemsChangeEvent;
    function GetItem(Index: Integer): TPPGItem;
    procedure SetItem(Index: Integer; const Value: TPPGItem);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TPPGItem; overload;
    function Add(const AText: string; AImageIndex: Integer = -1): TPPGItem; overload;
    function Insert(Index: Integer): TPPGItem;
    function IndexOfText(const AText: string): Integer;
    property Items[Index: Integer]: TPPGItem read GetItem write SetItem; default;
    /// Index >= 0: Eintrag geaendert, -1: Struktur geaendert.
    property OnChange: TPPGItemsChangeEvent read FOnChange write FOnChange;
  end;

  /// Gemeinsame Basis der Quellen (Ereignis-Verwaltung).
  TPPGItemSourceBase = class(TInterfacedObject, IPPGItemSource)
  private
    FOnChanged: TPPGItemsChangeEvent;
  protected
    procedure Changed(Index: Integer);
  public
    function Count: Integer; virtual; abstract;
    procedure GetItem(Index: Integer; var Data: TPPGItemData); virtual; abstract;
    function SetChecked(Index: Integer; Value: TCheckBoxState): Boolean; virtual;
    function GetOnChanged: TPPGItemsChangeEvent;
    procedure SetOnChanged(const Value: TPPGItemsChangeEvent);
  end;

  TPPGCollectionSource = class(TPPGItemSourceBase)
  private
    FItems: TPPGItems;
    procedure ItemsChanged(Sender: TObject; Index: Integer);
  public
    constructor Create(AItems: TPPGItems);
    destructor Destroy; override;
    function Count: Integer; override;
    procedure GetItem(Index: Integer; var Data: TPPGItemData); override;
    function SetChecked(Index: Integer; Value: TCheckBoxState): Boolean; override;
  end;

  /// TStrings als Quelle: Text = Zeile, Data = Objects[]. Aenderungen kommen
  /// nur an, wenn die Liste ein TStringList ist (OnChange) oder der Besitzer
  /// NotifyChanged aufruft.
  TPPGStringsSource = class(TPPGItemSourceBase)
  private
    FStrings: TStrings;
    FOldOnChange: TNotifyEvent;
    procedure StringsChanged(Sender: TObject);
  public
    constructor Create(AStrings: TStrings);
    destructor Destroy; override;
    procedure NotifyChanged;
    function Count: Integer; override;
    procedure GetItem(Index: Integer; var Data: TPPGItemData); override;
  end;

  TPPGGetItemEvent = procedure(Sender: TObject; Index: Integer;
    var Data: TPPGItemData) of object;
  TPPGSetCheckedEvent = procedure(Sender: TObject; Index: Integer;
    Value: TCheckBoxState) of object;

  /// Virtuell: Anzahl setzen, Daten liefert OnGetItem bei Bedarf.
  TPPGVirtualSource = class(TPPGItemSourceBase)
  private
    FCount: Integer;
    FOnGetItem: TPPGGetItemEvent;
    FOnSetChecked: TPPGSetCheckedEvent;
    procedure SetCount(const Value: Integer);
  public
    function Count: Integer; override;
    procedure GetItem(Index: Integer; var Data: TPPGItemData); override;
    function SetChecked(Index: Integer; Value: TCheckBoxState): Boolean; override;
    /// Daten eines Eintrags haben sich geaendert (neu zeichnen).
    procedure InvalidateItem(Index: Integer);
    property ItemCount: Integer read FCount write SetCount;
    property OnGetItem: TPPGGetItemEvent read FOnGetItem write FOnGetItem;
    property OnSetChecked: TPPGSetCheckedEvent read FOnSetChecked write FOnSetChecked;
  end;

/// Leerer Eintrag (ImageIndex -1, Enabled True).
procedure PPGInitItemData(var Data: TPPGItemData);

implementation

uses
  System.SysUtils, PPG.Consts, PPG.Exceptions;

procedure PPGInitItemData(var Data: TPPGItemData);
begin
  Data.Text := '';
  Data.Detail := '';
  Data.Badge := '';
  Data.Group := '';
  Data.ImageIndex := -1;
  Data.Checked := cbUnchecked;
  Data.Enabled := True;
  Data.IsHeader := False;
  Data.Data := nil;
end;

{ TPPGItem }

constructor TPPGItem.Create(Collection: TCollection);
begin
  FImageIndex := -1;
  FEnabled := True;
  inherited Create(Collection);
end;

procedure TPPGItem.Assign(Source: TPersistent);
var
  S: TPPGItem;
begin
  if Source is TPPGItem then
  begin
    S := TPPGItem(Source);
    FText := S.FText;
    FDetail := S.FDetail;
    FBadge := S.FBadge;
    FGroup := S.FGroup;
    FImageIndex := S.FImageIndex;
    FChecked := S.FChecked;
    FEnabled := S.FEnabled;
    FTag := S.FTag;
    FData := S.FData;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGItem.GetDisplayName: string;
begin
  if FText <> '' then
    Result := FText
  else
    Result := inherited GetDisplayName;
end;

procedure TPPGItem.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    Changed(False);
  end;
end;

procedure TPPGItem.SetDetail(const Value: string);
begin
  if FDetail <> Value then
  begin
    FDetail := Value;
    Changed(False);
  end;
end;

procedure TPPGItem.SetBadge(const Value: string);
begin
  if FBadge <> Value then
  begin
    FBadge := Value;
    Changed(False);
  end;
end;

procedure TPPGItem.SetGroup(const Value: string);
begin
  if FGroup <> Value then
  begin
    FGroup := Value;
    Changed(True); // Gruppen beeinflussen die Struktur (Ueberschriften)
  end;
end;

procedure TPPGItem.SetImageIndex(const Value: TPPGImageIndex);
begin
  if FImageIndex <> Value then
  begin
    FImageIndex := Value;
    Changed(False);
  end;
end;

procedure TPPGItem.SetChecked(const Value: TCheckBoxState);
begin
  if FChecked <> Value then
  begin
    FChecked := Value;
    Changed(False);
  end;
end;

procedure TPPGItem.SetEnabled(const Value: Boolean);
begin
  if FEnabled <> Value then
  begin
    FEnabled := Value;
    Changed(False);
  end;
end;

{ TPPGItems }

constructor TPPGItems.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TPPGItem);
end;

function TPPGItems.GetItem(Index: Integer): TPPGItem;
begin
  Result := TPPGItem(inherited GetItem(Index));
end;

procedure TPPGItems.SetItem(Index: Integer; const Value: TPPGItem);
begin
  inherited SetItem(Index, Value);
end;

function TPPGItems.Add: TPPGItem;
begin
  Result := TPPGItem(inherited Add);
end;

function TPPGItems.Add(const AText: string; AImageIndex: Integer): TPPGItem;
begin
  BeginUpdate;
  try
    Result := Add;
    Result.Text := AText;
    Result.ImageIndex := AImageIndex;
  finally
    EndUpdate;
  end;
end;

function TPPGItems.Insert(Index: Integer): TPPGItem;
begin
  Result := TPPGItem(inherited Insert(Index));
end;

function TPPGItems.IndexOfText(const AText: string): Integer;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if AnsiSameText(Items[I].Text, AText) then
      Exit(I);
  Result := -1;
end;

procedure TPPGItems.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
  if Assigned(FOnChange) then
    if Item <> nil then
      FOnChange(Self, Item.Index)
    else
      FOnChange(Self, -1);
end;

{ TPPGItemSourceBase }

procedure TPPGItemSourceBase.Changed(Index: Integer);
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self, Index);
end;

function TPPGItemSourceBase.SetChecked(Index: Integer; Value: TCheckBoxState): Boolean;
begin
  Result := False;
end;

function TPPGItemSourceBase.GetOnChanged: TPPGItemsChangeEvent;
begin
  Result := FOnChanged;
end;

procedure TPPGItemSourceBase.SetOnChanged(const Value: TPPGItemsChangeEvent);
begin
  FOnChanged := Value;
end;

{ TPPGCollectionSource }

constructor TPPGCollectionSource.Create(AItems: TPPGItems);
begin
  inherited Create;
  FItems := AItems;
  if FItems <> nil then
    FItems.OnChange := ItemsChanged;
end;

destructor TPPGCollectionSource.Destroy;
begin
  if (FItems <> nil) and (TMethod(FItems.OnChange).Data = Self) then
    FItems.OnChange := nil;
  inherited Destroy;
end;

procedure TPPGCollectionSource.ItemsChanged(Sender: TObject; Index: Integer);
begin
  Changed(Index);
end;

function TPPGCollectionSource.Count: Integer;
begin
  if FItems = nil then
    Result := 0
  else
    Result := FItems.Count;
end;

procedure TPPGCollectionSource.GetItem(Index: Integer; var Data: TPPGItemData);
var
  It: TPPGItem;
begin
  It := FItems[Index];
  Data.Text := It.Text;
  Data.Detail := It.Detail;
  Data.Badge := It.Badge;
  Data.Group := It.Group;
  Data.ImageIndex := It.ImageIndex;
  Data.Checked := It.Checked;
  Data.Enabled := It.Enabled;
  Data.Data := It.Data;
end;

function TPPGCollectionSource.SetChecked(Index: Integer; Value: TCheckBoxState): Boolean;
begin
  FItems[Index].Checked := Value; // meldet sich selbst ueber Update
  Result := True;
end;

{ TPPGStringsSource }

constructor TPPGStringsSource.Create(AStrings: TStrings);
begin
  inherited Create;
  FStrings := AStrings;
  if FStrings is TStringList then
  begin
    FOldOnChange := TStringList(FStrings).OnChange;
    TStringList(FStrings).OnChange := StringsChanged;
  end;
end;

destructor TPPGStringsSource.Destroy;
begin
  if (FStrings is TStringList) and
    (TMethod(TStringList(FStrings).OnChange).Data = Self) then
    TStringList(FStrings).OnChange := FOldOnChange;
  inherited Destroy;
end;

procedure TPPGStringsSource.StringsChanged(Sender: TObject);
begin
  if Assigned(FOldOnChange) then
    FOldOnChange(Sender);
  Changed(-1);
end;

procedure TPPGStringsSource.NotifyChanged;
begin
  Changed(-1);
end;

function TPPGStringsSource.Count: Integer;
begin
  if FStrings = nil then
    Result := 0
  else
    Result := FStrings.Count;
end;

procedure TPPGStringsSource.GetItem(Index: Integer; var Data: TPPGItemData);
begin
  Data.Text := FStrings[Index];
  Data.Data := FStrings.Objects[Index];
end;

{ TPPGVirtualSource }

procedure TPPGVirtualSource.SetCount(const Value: Integer);
begin
  if Value < 0 then
    raise EPPGPropertyError.CreateFmt(SPPGInvalidArgument, [Value, 'ItemCount']);
  if FCount <> Value then
  begin
    FCount := Value;
    Changed(-1);
  end;
end;

function TPPGVirtualSource.Count: Integer;
begin
  Result := FCount;
end;

procedure TPPGVirtualSource.GetItem(Index: Integer; var Data: TPPGItemData);
begin
  if Assigned(FOnGetItem) then
    FOnGetItem(Self, Index, Data);
end;

function TPPGVirtualSource.SetChecked(Index: Integer; Value: TCheckBoxState): Boolean;
begin
  Result := Assigned(FOnSetChecked);
  if Result then
  begin
    FOnSetChecked(Self, Index, Value);
    Changed(Index);
  end;
end;

procedure TPPGVirtualSource.InvalidateItem(Index: Integer);
begin
  Changed(Index);
end;

end.
