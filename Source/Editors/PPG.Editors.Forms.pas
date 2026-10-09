unit PPG.Editors.Forms;

{ Dialoge der Designer-Editoren (Phase 9a), im Code aufgebaut (keine DFM).

  - TPPGAppearanceDialog: Farben je Zustand und allgemeine Masse; Vorschau
    mit zwei echten Exemplaren der Control-Klasse (aktiv und deaktiviert).
  - TPPGPresetGalleryDialog: alle registrierten Presets als Kacheln mit
    echten PPGlow-Controls; das gewaehlte Preset gilt fuer das Formular.
  - TPPGNavItemsDialog: verschachtelte Eintraege der NavigationView.
  - TPPGTreeItemsDialog: Knoten des TreeView.

  Alle Dialoge arbeiten auf einer KOPIE (Session bzw. eigenes Control);
  der Aufrufer uebernimmt das Ergebnis nur bei mrOk. Sie enthalten keine
  IDE-Abhaengigkeit und lassen sich deshalb auch in Tests oeffnen.

  Vorschau in der IDE: Die IDE faerbt ihre Dialoge mit ihrem VCL-Style. Die
  Vorschau-Controls schalten den Style ab (StyleElements = []), damit sie die
  echte Appearance zeigen. Hell/Dunkel folgt dem Modus der Anwendung
  (TPPGTheme), der bei PPGlow anwendungsweit gilt. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Graphics,
  PPG.SpinEdit,
  PPG.Types, PPG.Appearance, PPG.Controls.Base, PPG.NavigationView, PPG.TreeView,
  PPG.Editors.Logic;

type
  /// Basis: Formular ohne DFM mit OK/Abbrechen unten rechts.
  TPPGEditorDialog = class(TForm)
  private
    FPPI: Integer;
  protected
    FButtonBar: TPanel;
    FOkButton: TButton;
    FCancelButton: TButton;
    /// Logische 96-DPI-Pixel in Bildschirm-Pixel.
    function S(Value: Integer): Integer;
    function NewPanel(AParent: TWinControl; AAlign: TAlign; ASize: Integer): TPanel;
    function NewLabel(AParent: TWinControl; const ACaption: string; ALeft, ATop: Integer): TLabel;
    function NewButton(AParent: TWinControl; const ACaption: string; ALeft, ATop, AWidth: Integer;
      AOnClick: TNotifyEvent): TButton;
    function NewEdit(AParent: TWinControl; ALeft, ATop, AWidth: Integer; AOnChange: TNotifyEvent): TEdit;
    function NewSpin(AParent: TWinControl; ALeft, ATop, AWidth, AMin, AMax: Integer;
      AOnChange: TNotifyEvent): TPPGSpinEdit;
    function NewCheck(AParent: TWinControl; const ACaption: string; ALeft, ATop: Integer;
      AOnClick: TNotifyEvent): TCheckBox;
    /// Schaltet den VCL-Style der IDE fuer eine Vorschau ab.
    procedure PlainStyle(C: TControl);
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TPPGAppearanceDialog = class(TPPGEditorDialog)
  private
    FSession: TPPGAppearanceSession;
    FUpdating: Boolean;
    FState: TComboBox;
    FColors: array[0..6] of TColorBox;
    FGlowAlpha: TPPGSpinEdit;
    FDirection: TComboBox;
    FFocusColor: TColorBox;
    FRounding: TPPGSpinEdit;
    FBorderWidth: TPPGSpinEdit;
    FGlowSize: TPPGSpinEdit;
    FPreviewBox: TPanel;
    FPreview: TPPGCustomControl;
    FPreviewDisabled: TPPGCustomControl;
    FPreviewNote: TLabel;
    function CurrentStyle: TPPGStateStyle;
    function NewColorBox(AParent: TWinControl; ALeft, ATop: Integer): TColorBox;
    procedure CreatePreviews;
    procedure LoadValues;
    procedure UpdatePreviews;
    procedure StateClick(Sender: TObject);
    procedure ValueChange(Sender: TObject);
    procedure ResetClick(Sender: TObject);
  public
    constructor CreateFor(AOwner: TComponent; ATarget: TPPGCustomControl);
    destructor Destroy; override;
    property Session: TPPGAppearanceSession read FSession;
    property Preview: TPPGCustomControl read FPreview;
    property StateBox: TComboBox read FState;
    /// Farbe "Color" des gewaehlten Zustands (fuer Tests).
    function ColorBox0: TColorBox;
    property RoundingEdit: TPPGSpinEdit read FRounding;
  end;

  TPPGPresetGalleryDialog = class(TPPGEditorDialog)
  private
    FRoot: TComponent;
    FNames: TStringList;
    FRadios: TList<TRadioButton>;
    FInfo: TLabel;
    function GetSelectedPreset: string;
    procedure SetSelectedPreset(const Value: string);
    procedure AddTile(AParent: TWinControl; const AName: string; ATop: Integer);
    function MostUsedPreset: string;
  public
    constructor CreateFor(AOwner: TComponent; ARoot: TComponent);
    destructor Destroy; override;
    /// Anzahl der Komponenten, die das Preset bekommen (ohne StyleManager-Kunden).
    function TargetCount: Integer;
    property SelectedPreset: string read GetSelectedPreset write SetSelectedPreset;
    property PresetNames: TStringList read FNames;
  end;

  TPPGNavItemsDialog = class(TPPGEditorDialog)
  private
    FView: TPPGNavigationView;
    FTree: TTreeView;
    FUpdating: Boolean;
    FCaption: TEdit;
    FIconChar: TEdit;
    FPageIndex: TPPGSpinEdit;
    FBadge: TPPGSpinEdit;
    FFooter: TCheckBox;
    FEnabled: TCheckBox;
    FHint: TEdit;
    FKindLabel: TLabel;
    procedure RebuildTree(Select: TPPGNavItem);
    procedure AddNodes(Parent: TTreeNode; Items: TPPGNavItems; Select: TPPGNavItem;
      var Found: TTreeNode);
    procedure LoadFields;
    procedure TreeChange(Sender: TObject; Node: TTreeNode);
    procedure FieldChange(Sender: TObject);
    procedure AddItemClick(Sender: TObject);
    procedure AddChildClick(Sender: TObject);
    procedure AddHeaderClick(Sender: TObject);
    procedure AddSeparatorClick(Sender: TObject);
    procedure DeleteClick(Sender: TObject);
    procedure UpClick(Sender: TObject);
    procedure DownClick(Sender: TObject);
    procedure IndentClick(Sender: TObject);
    procedure OutdentClick(Sender: TObject);
  public
    constructor CreateFor(AOwner: TComponent; ASource: TPPGNavigationView);
    function SelectedItem: TPPGNavItem;
    procedure SelectItem(Item: TPPGNavItem);
    /// Arbeitskopie (Vorschau). Bei mrOk: Ziel.Items.Assign(View.Items).
    property View: TPPGNavigationView read FView;
    property StructureTree: TTreeView read FTree;
    property CaptionEdit: TEdit read FCaption;
  end;

  TPPGTreeItemsDialog = class(TPPGEditorDialog)
  private
    FTree: TPPGTreeView;
    FUpdating: Boolean;
    FText: TEdit;
    FDetail: TEdit;
    FBadge: TEdit;
    FImageIndex: TPPGSpinEdit;
    FSelectedIndex: TPPGSpinEdit;
    FCheckState: TComboBox;
    FEnabled: TCheckBox;
    FHasChildren: TCheckBox;
    procedure LoadFields;
    procedure TreeChange(Sender: TObject; Node: TPPGTreeNode);
    procedure FieldChange(Sender: TObject);
    procedure AddClick(Sender: TObject);
    procedure AddChildClick(Sender: TObject);
    procedure DeleteClick(Sender: TObject);
    procedure UpClick(Sender: TObject);
    procedure DownClick(Sender: TObject);
    procedure IndentClick(Sender: TObject);
    procedure OutdentClick(Sender: TObject);
  public
    constructor CreateFor(AOwner: TComponent; ASource: TPPGTreeView);
    /// Arbeitskopie. Bei mrOk: Ziel.Items.Assign(Tree.Items).
    property Tree: TPPGTreeView read FTree;
    property TextEdit: TEdit read FText;
  end;

implementation

uses
  System.TypInfo, PPG.Render.Registry, PPG.Panel, PPG.Button, PPG.CheckBox,
  PPG.ToggleSwitch, PPG.Edit, PPG.ErrorHandler, PPG.Exceptions;

resourcestring
  SDlgOk = 'OK';
  SDlgCancel = 'Cancel';
  SAppearanceTitle = 'Appearance of %s';
  SAppearanceState = 'State:';
  SAppearanceGeneral = 'General';
  SAppearanceReset = 'Preset values';
  SAppearancePreview = 'Preview';
  SAppearanceDisabled = 'Disabled';
  SAppearanceNoPreview = 'No preview for this control';
  SStateNormal = 'Normal';
  SStateHot = 'Hot (mouse over)';
  SStateDown = 'Down (pressed)';
  SStateDisabled = 'Disabled';
  SStateChecked = 'Checked';
  SColorColor = 'Color';
  SColorColorTo = 'Color to';
  SColorMirror = 'Mirror';
  SColorMirrorTo = 'Mirror to';
  SColorBorder = 'Border';
  SColorGlow = 'Glow';
  SColorText = 'Text';
  SGlowAlpha = 'Glow alpha';
  SDirection = 'Gradient';
  SFocusColor = 'Focus color';
  SRounding = 'Rounding';
  SBorderWidth = 'Border width';
  SGlowSize = 'Glow size';
  SGalleryTitle = 'Apply preset to form';
  SGalleryInfo = '%d components on %s get the selected preset. Components with a StyleManager follow their manager.';
  SGallerySample = 'Sample';
  SGalleryOption = 'Option';
  SGalleryInput = 'Text';
  SNavTitle = 'Items of %s';
  SNavNewItem = 'New item';
  SNavNewChild = 'New subitem';
  SNavNewHeader = 'New header';
  SNavNewSeparator = 'Separator';
  SNavItemCaption = 'Item';
  SNavHeaderCaption = 'Header';
  SNavSeparatorCaption = '(separator)';
  SNavFieldCaption = 'Caption';
  SNavFieldIcon = 'Icon (hex)';
  SNavFieldPage = 'Page index';
  SNavFieldBadge = 'Badge';
  SNavFieldFooter = 'Footer';
  SNavFieldEnabled = 'Enabled';
  SNavFieldHint = 'Hint';
  SNavKindItem = 'Kind: item';
  SNavKindHeader = 'Kind: header';
  SNavKindSeparator = 'Kind: separator';
  STreeTitle = 'Nodes of %s';
  STreeNew = 'New node';
  STreeNewChild = 'New subnode';
  STreeNodeCaption = 'Node';
  STreeFieldText = 'Text';
  STreeFieldDetail = 'Detail';
  STreeFieldBadge = 'Badge';
  STreeFieldImage = 'Image index';
  STreeFieldSelImage = 'Selected index';
  STreeFieldCheck = 'Check state';
  STreeFieldEnabled = 'Enabled';
  STreeFieldHasChildren = 'Has children (lazy)';
  SCheckUnchecked = 'Unchecked';
  SCheckChecked = 'Checked';
  SCheckGrayed = 'Grayed';
  SOpDelete = 'Delete';
  SOpUp = 'Up';
  SOpDown = 'Down';
  SOpIndent = 'Indent';
  SOpOutdent = 'Outdent';

type
  TCtrlAccess = class(TPPGCustomControl);
  TPPGCustomControlClass = class of TPPGCustomControl;

const
  FieldLeft = 8;
  FieldLabelWidth = 96;

{ TPPGEditorDialog }

constructor TPPGEditorDialog.Create(AOwner: TComponent);
begin
  // Keine DFM: CreateNew statt Create (sonst EResNotFound)
  inherited CreateNew(AOwner);
  FPPI := Screen.PixelsPerInch;
  if FPPI <= 0 then
    FPPI := 96;
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu];
  Position := poScreenCenter;
  Font.Name := 'Segoe UI';
  Font.Height := -S(12);
  KeyPreview := True;

  FButtonBar := NewPanel(Self, alBottom, 44);
  FCancelButton := NewButton(FButtonBar, SDlgCancel, 0, 10, 88, nil);
  FCancelButton.Anchors := [akTop, akRight];
  FCancelButton.Cancel := True;
  FCancelButton.ModalResult := mrCancel;
  FOkButton := NewButton(FButtonBar, SDlgOk, 0, 10, 88, nil);
  FOkButton.Anchors := [akTop, akRight];
  FOkButton.Default := True;
  FOkButton.ModalResult := mrOk;
end;

function TPPGEditorDialog.S(Value: Integer): Integer;
begin
  Result := MulDiv(Value, FPPI, 96);
end;

function TPPGEditorDialog.NewPanel(AParent: TWinControl; AAlign: TAlign; ASize: Integer): TPanel;
begin
  Result := TPanel.Create(Self);
  Result.BevelOuter := bvNone;
  Result.Caption := '';
  Result.Parent := AParent;
  Result.Align := AAlign;
  case AAlign of
    alLeft, alRight: Result.Width := S(ASize);
    alTop, alBottom: Result.Height := S(ASize);
  end;
end;

function TPPGEditorDialog.NewLabel(AParent: TWinControl; const ACaption: string;
  ALeft, ATop: Integer): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := AParent;
  Result.Caption := ACaption;
  Result.Left := S(ALeft);
  Result.Top := S(ATop) + S(3);
end;

function TPPGEditorDialog.NewButton(AParent: TWinControl; const ACaption: string;
  ALeft, ATop, AWidth: Integer; AOnClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  Result.Caption := ACaption;
  Result.SetBounds(S(ALeft), S(ATop), S(AWidth), S(26));
  Result.OnClick := AOnClick;
end;

function TPPGEditorDialog.NewEdit(AParent: TWinControl; ALeft, ATop, AWidth: Integer;
  AOnChange: TNotifyEvent): TEdit;
begin
  Result := TEdit.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(S(ALeft), S(ATop), S(AWidth), S(23));
  Result.OnChange := AOnChange;
end;

function TPPGEditorDialog.NewSpin(AParent: TWinControl; ALeft, ATop, AWidth, AMin, AMax: Integer;
  AOnChange: TNotifyEvent): TPPGSpinEdit;
begin
  Result := TPPGSpinEdit.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(S(ALeft), S(ATop), S(AWidth), S(23));
  Result.Min := AMin;
  Result.Max := AMax;
  Result.Value := AMin;
  Result.OnChange := AOnChange;
end;

function TPPGEditorDialog.NewCheck(AParent: TWinControl; const ACaption: string;
  ALeft, ATop: Integer; AOnClick: TNotifyEvent): TCheckBox;
begin
  Result := TCheckBox.Create(Self);
  Result.Parent := AParent;
  Result.Caption := ACaption;
  Result.SetBounds(S(ALeft), S(ATop), S(160), S(21));
  Result.OnClick := AOnClick;
end;

procedure TPPGEditorDialog.PlainStyle(C: TControl);
begin
{$IFDEF PPG_HAS_STYLEELEMENTS}
  C.StyleElements := [];
{$ENDIF}
end;

{ TPPGAppearanceDialog }

constructor TPPGAppearanceDialog.CreateFor(AOwner: TComponent; ATarget: TPPGCustomControl);
var
  Pane: TPanel;
  Y, I: Integer;
  D: TPPGGradientDirection;
  Names: array[0..6] of string;
  Reset: TButton;
begin
  Create(AOwner);
  FSession := TPPGAppearanceSession.Create(ATarget);
  Caption := Format(SAppearanceTitle, [PPGDisplayName(ATarget)]);
  ClientWidth := S(640);
  ClientHeight := S(500);
  FCancelButton.Left := ClientWidth - S(96);
  FOkButton.Left := ClientWidth - S(192);

  Pane := NewPanel(Self, alLeft, 300);
  NewLabel(Pane, SAppearanceState, FieldLeft, 10);
  FState := TComboBox.Create(Self);
  FState.Parent := Pane;
  FState.Style := csDropDownList;
  FState.SetBounds(S(FieldLeft + FieldLabelWidth), S(10), S(180), S(23));
  FState.Items.Add(SStateNormal);
  FState.Items.Add(SStateHot);
  FState.Items.Add(SStateDown);
  FState.Items.Add(SStateDisabled);
  FState.Items.Add(SStateChecked);
  FState.ItemIndex := 0;
  FState.OnClick := StateClick;

  Names[0] := SColorColor;
  Names[1] := SColorColorTo;
  Names[2] := SColorMirror;
  Names[3] := SColorMirrorTo;
  Names[4] := SColorBorder;
  Names[5] := SColorGlow;
  Names[6] := SColorText;
  Y := 44;
  for I := 0 to High(FColors) do
  begin
    NewLabel(Pane, Names[I], FieldLeft + 8, Y);
    FColors[I] := NewColorBox(Pane, FieldLeft + FieldLabelWidth, Y);
    Inc(Y, 30);
  end;
  NewLabel(Pane, SGlowAlpha, FieldLeft + 8, Y);
  FGlowAlpha := NewSpin(Pane, FieldLeft + FieldLabelWidth, Y, 80, 0, 255, ValueChange);
  Inc(Y, 30);
  NewLabel(Pane, SDirection, FieldLeft + 8, Y);
  FDirection := TComboBox.Create(Self);
  FDirection.Parent := Pane;
  FDirection.Style := csDropDownList;
  FDirection.SetBounds(S(FieldLeft + FieldLabelWidth), S(Y), S(180), S(23));
  for D := Low(TPPGGradientDirection) to High(TPPGGradientDirection) do
    FDirection.Items.Add(GetEnumName(TypeInfo(TPPGGradientDirection), Ord(D)));
  FDirection.OnClick := ValueChange;
  Inc(Y, 40);

  NewLabel(Pane, SAppearanceGeneral, FieldLeft, Y).Font.Style := [fsBold];
  Inc(Y, 26);
  NewLabel(Pane, SFocusColor, FieldLeft + 8, Y);
  FFocusColor := NewColorBox(Pane, FieldLeft + FieldLabelWidth, Y);
  Inc(Y, 30);
  NewLabel(Pane, SRounding, FieldLeft + 8, Y);
  FRounding := NewSpin(Pane, FieldLeft + FieldLabelWidth, Y, 80, 0, PPGMaxRounding, ValueChange);
  Inc(Y, 30);
  NewLabel(Pane, SBorderWidth, FieldLeft + 8, Y);
  FBorderWidth := NewSpin(Pane, FieldLeft + FieldLabelWidth, Y, 80, 0, PPGMaxBorderWidth, ValueChange);
  Inc(Y, 30);
  NewLabel(Pane, SGlowSize, FieldLeft + 8, Y);
  FGlowSize := NewSpin(Pane, FieldLeft + FieldLabelWidth, Y, 80, 0, PPGMaxGlowSize, ValueChange);

  Reset := NewButton(FButtonBar, SAppearanceReset, FieldLeft, 10, 120, ResetClick);
  Reset.Anchors := [akTop, akLeft];

  FPreviewBox := NewPanel(Self, alClient, 0);
  FPreviewBox.ParentBackground := False;
  FPreviewBox.Color := clWindow;
  NewLabel(FPreviewBox, SAppearancePreview, 16, 10).Font.Style := [fsBold];
  CreatePreviews;
  LoadValues;
end;

destructor TPPGAppearanceDialog.Destroy;
begin
  inherited Destroy;
  // Nach inherited: die Vorschau-Controls (Owner = Dialog) sind dann frei
  FreeAndNil(FSession);
end;

function TPPGAppearanceDialog.ColorBox0: TColorBox;
begin
  Result := FColors[0];
end;

function TPPGAppearanceDialog.NewColorBox(AParent: TWinControl; ALeft, ATop: Integer): TColorBox;
begin
  Result := TColorBox.Create(Self);
  Result.Parent := AParent;
  Result.Style := [cbStandardColors, cbExtendedColors, cbSystemColors, cbIncludeNone,
    cbCustomColor, cbPrettyNames];
  Result.SetBounds(S(ALeft), S(ATop), S(180), S(23));
  Result.OnChange := ValueChange;
end;

procedure TPPGAppearanceDialog.CreatePreviews;
var
  Cls: TPPGCustomControlClass;

  function Make(ATop: Integer; AEnabled: Boolean): TPPGCustomControl;
  begin
    Result := Cls.Create(Self);
    PlainStyle(Result);
    Result.Parent := FPreviewBox;
    Result.SetBounds(S(16), S(ATop), S(200), S(36));
    TCtrlAccess(Result).Preset := TCtrlAccess(FSession.Target).Preset;
    TCtrlAccess(Result).Caption := SAppearancePreview;
    Result.Enabled := AEnabled;
  end;

begin
  Cls := TPPGCustomControlClass(FSession.Target.ClassType);
  try
    FPreview := Make(40, True);
    FPreviewDisabled := Make(96, False);
    NewLabel(FPreviewBox, SAppearanceDisabled, 224, 104);
  except
    // Design-Editor-Grenze: eine Control-Klasse, die sich nicht allein
    // erzeugen laesst, verhindert nur die Vorschau, nicht das Bearbeiten.
    on E: Exception do
    begin
      TPPGErrorHandler.LogWarning(Self, E.Message);
      FreeAndNil(FPreview);
      FreeAndNil(FPreviewDisabled);
      FPreviewNote := NewLabel(FPreviewBox, SAppearanceNoPreview, 16, 40);
    end;
  end;
end;

function TPPGAppearanceDialog.CurrentStyle: TPPGStateStyle;
begin
  case FState.ItemIndex of
    1: Result := FSession.Work.Hot;
    2: Result := FSession.Work.Down;
    3: Result := FSession.Work.Disabled;
    4: Result := FSession.Work.Checked;
  else
    Result := FSession.Work.Normal;
  end;
end;

procedure TPPGAppearanceDialog.LoadValues;
var
  St: TPPGStateStyle;
begin
  FUpdating := True;
  try
    St := CurrentStyle;
    FColors[0].Selected := St.Color;
    FColors[1].Selected := St.ColorTo;
    FColors[2].Selected := St.ColorMirror;
    FColors[3].Selected := St.ColorMirrorTo;
    FColors[4].Selected := St.BorderColor;
    FColors[5].Selected := St.GlowColor;
    FColors[6].Selected := St.TextColor;
    FGlowAlpha.Value := St.GlowAlpha;
    FDirection.ItemIndex := Ord(St.GradientDirection);
    FFocusColor.Selected := FSession.Work.FocusColor;
    FRounding.Value := FSession.Work.Rounding;
    FBorderWidth.Value := FSession.Work.BorderWidth;
    FGlowSize.Value := FSession.Work.GlowSize;
  finally
    FUpdating := False;
  end;
  UpdatePreviews;
end;

procedure TPPGAppearanceDialog.UpdatePreviews;
begin
  if FPreview <> nil then
    TCtrlAccess(FPreview).Appearance.Assign(FSession.Work);
  if FPreviewDisabled <> nil then
    TCtrlAccess(FPreviewDisabled).Appearance.Assign(FSession.Work);
end;

procedure TPPGAppearanceDialog.StateClick(Sender: TObject);
begin
  LoadValues;
end;

procedure TPPGAppearanceDialog.ValueChange(Sender: TObject);
var
  St: TPPGStateStyle;
  W: TPPGAppearance;
begin
  if FUpdating then
    Exit;
  St := CurrentStyle;
  W := FSession.Work;
  W.BeginUpdate;
  try
    St.Color := FColors[0].Selected;
    St.ColorTo := FColors[1].Selected;
    St.ColorMirror := FColors[2].Selected;
    St.ColorMirrorTo := FColors[3].Selected;
    St.BorderColor := FColors[4].Selected;
    St.GlowColor := FColors[5].Selected;
    St.TextColor := FColors[6].Selected;
    // Waehrend der Eingabe koennen Werte ausserhalb der Grenzen stehen
    if (FGlowAlpha.Value >= 0) and (FGlowAlpha.Value <= 255) then
      St.GlowAlpha := FGlowAlpha.Value;
    if FDirection.ItemIndex >= 0 then
      St.GradientDirection := TPPGGradientDirection(FDirection.ItemIndex);
    W.FocusColor := FFocusColor.Selected;
    if (FRounding.Value >= 0) and (FRounding.Value <= PPGMaxRounding) then
      W.Rounding := FRounding.Value;
    if (FBorderWidth.Value >= 0) and (FBorderWidth.Value <= PPGMaxBorderWidth) then
      W.BorderWidth := FBorderWidth.Value;
    if (FGlowSize.Value >= 0) and (FGlowSize.Value <= PPGMaxGlowSize) then
      W.GlowSize := FGlowSize.Value;
  finally
    W.EndUpdate;
  end;
  UpdatePreviews;
end;

procedure TPPGAppearanceDialog.ResetClick(Sender: TObject);
begin
  FSession.ResetToPreset;
  LoadValues;
end;

{ TPPGPresetGalleryDialog }

constructor TPPGPresetGalleryDialog.CreateFor(AOwner: TComponent; ARoot: TComponent);
var
  Box: TScrollBox;
  I, Y: Integer;
begin
  Create(AOwner);
  FRoot := ARoot;
  FNames := TStringList.Create;
  FRadios := TList<TRadioButton>.Create;
  Caption := SGalleryTitle;
  ClientWidth := S(560);
  ClientHeight := S(520);
  FCancelButton.Left := ClientWidth - S(96);
  FOkButton.Left := ClientWidth - S(192);

  FInfo := TLabel.Create(Self);
  FInfo.Parent := NewPanel(Self, alTop, 48);
  FInfo.AutoSize := False;
  FInfo.WordWrap := True;
  FInfo.SetBounds(S(12), S(8), ClientWidth - S(24), S(36));
  FInfo.Anchors := [akLeft, akTop, akRight];
  FInfo.Caption := Format(SGalleryInfo, [TargetCount, PPGDisplayName(ARoot)]);

  Box := TScrollBox.Create(Self);
  Box.Parent := Self;
  Box.Align := alClient;
  Box.BorderStyle := bsNone;
  Box.VertScrollBar.Tracking := True;

  TPPGRendererRegistry.GetNames(FNames);
  Y := 4;
  for I := 0 to FNames.Count - 1 do
  begin
    AddTile(Box, FNames[I], Y);
    Inc(Y, 132);
  end;
  SelectedPreset := MostUsedPreset;
end;

destructor TPPGPresetGalleryDialog.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FRadios);
  FreeAndNil(FNames);
end;

procedure TPPGPresetGalleryDialog.AddTile(AParent: TWinControl; const AName: string; ATop: Integer);
var
  Radio: TRadioButton;
  Tile: TPPGPanel;
  Btn: TPPGButton;
  Chk: TPPGCheckBox;
  Tgl: TPPGToggleSwitch;
  Ed: TPPGEdit;
begin
  Radio := TRadioButton.Create(Self);
  Radio.Parent := AParent;
  Radio.Caption := AName;
  Radio.Font.Style := [fsBold];
  Radio.SetBounds(S(12), S(ATop), S(300), S(22));
  FRadios.Add(Radio);

  Tile := TPPGPanel.Create(Self);
  PlainStyle(Tile);
  Tile.Parent := AParent;
  Tile.Preset := AName;
  Tile.Caption := '';
  Tile.SetBounds(S(12), S(ATop + 24), S(500), S(96));

  Btn := TPPGButton.Create(Self);
  PlainStyle(Btn);
  Btn.Parent := Tile;
  Btn.Preset := AName;
  Btn.Caption := SGallerySample;
  Btn.SetBounds(S(12), S(12), S(110), S(32));

  Chk := TPPGCheckBox.Create(Self);
  PlainStyle(Chk);
  Chk.Parent := Tile;
  Chk.Preset := AName;
  Chk.Caption := SGalleryOption;
  Chk.Checked := True;
  Chk.SetBounds(S(140), S(16), S(120), S(24));

  Tgl := TPPGToggleSwitch.Create(Self);
  PlainStyle(Tgl);
  Tgl.Parent := Tile;
  Tgl.Preset := AName;
  Tgl.Caption := '';
  Tgl.Checked := True;
  Tgl.SetBounds(S(280), S(16), S(60), S(24));

  Ed := TPPGEdit.Create(Self);
  PlainStyle(Ed);
  Ed.Parent := Tile;
  Ed.Preset := AName;
  Ed.Text := SGalleryInput;
  Ed.SetBounds(S(12), S(54), S(250), S(30));
end;

function TPPGPresetGalleryDialog.TargetCount: Integer;
var
  L: TList<TComponent>;
  C: TComponent;
begin
  Result := 0;
  L := TList<TComponent>.Create;
  try
    TPPGPresetTargets.Collect(FRoot, L);
    for C in L do
      if not TPPGPresetTargets.UsesStyleManager(C) then
        Inc(Result);
  finally
    L.Free;
  end;
end;

function TPPGPresetGalleryDialog.MostUsedPreset: string;
var
  L: TList<TComponent>;
  Counts: TStringList;
  C: TComponent;
  P: string;
  I, Best, Idx: Integer;
begin
  Result := TPPGRendererRegistry.DefaultName;
  L := TList<TComponent>.Create;
  Counts := TStringList.Create;
  try
    TPPGPresetTargets.Collect(FRoot, L);
    for C in L do
    begin
      P := GetStrProp(C, 'Preset');
      Idx := Counts.IndexOf(P);
      if Idx < 0 then
        Counts.AddObject(P, TObject(1))
      else
        Counts.Objects[Idx] := TObject(NativeInt(Counts.Objects[Idx]) + 1);
    end;
    Best := 0;
    for I := 0 to Counts.Count - 1 do
      if NativeInt(Counts.Objects[I]) > Best then
      begin
        Best := NativeInt(Counts.Objects[I]);
        Result := Counts[I];
      end;
  finally
    Counts.Free;
    L.Free;
  end;
end;

function TPPGPresetGalleryDialog.GetSelectedPreset: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FRadios.Count - 1 do
    if FRadios[I].Checked then
      Exit(FNames[I]);
end;

procedure TPPGPresetGalleryDialog.SetSelectedPreset(const Value: string);
var
  I: Integer;
begin
  for I := 0 to FRadios.Count - 1 do
    FRadios[I].Checked := SameText(FNames[I], Value);
end;

{ TPPGNavItemsDialog }

constructor TPPGNavItemsDialog.CreateFor(AOwner: TComponent; ASource: TPPGNavigationView);
var
  Ops, Fields, Preview: TPanel;
  Y: Integer;
begin
  Create(AOwner);
  Caption := Format(SNavTitle, [PPGDisplayName(ASource)]);
  ClientWidth := S(760);
  ClientHeight := S(500);
  FCancelButton.Left := ClientWidth - S(96);
  FOkButton.Left := ClientWidth - S(192);

  // Vorschau rechts: eine echte NavigationView als Arbeitskopie
  Preview := NewPanel(Self, alRight, 240);
  FView := TPPGNavigationView.Create(Self);
  PlainStyle(FView);
  FView.Parent := Preview;
  FView.Align := alClient;
  FView.Preset := ASource.Preset;
  FView.Images := ASource.Images;
  FView.PaneTitle := ASource.PaneTitle;
  FView.Items.Assign(ASource.Items);

  Ops := NewPanel(Self, alRight, 120);
  Y := 8;
  NewButton(Ops, SNavNewItem, 8, Y, 104, AddItemClick); Inc(Y, 30);
  NewButton(Ops, SNavNewChild, 8, Y, 104, AddChildClick); Inc(Y, 30);
  NewButton(Ops, SNavNewHeader, 8, Y, 104, AddHeaderClick); Inc(Y, 30);
  NewButton(Ops, SNavNewSeparator, 8, Y, 104, AddSeparatorClick); Inc(Y, 40);
  NewButton(Ops, SOpUp, 8, Y, 104, UpClick); Inc(Y, 30);
  NewButton(Ops, SOpDown, 8, Y, 104, DownClick); Inc(Y, 30);
  NewButton(Ops, SOpIndent, 8, Y, 104, IndentClick); Inc(Y, 30);
  NewButton(Ops, SOpOutdent, 8, Y, 104, OutdentClick); Inc(Y, 40);
  NewButton(Ops, SOpDelete, 8, Y, 104, DeleteClick);

  Fields := NewPanel(Self, alBottom, 156);
  Y := 4;
  FKindLabel := NewLabel(Fields, '', FieldLeft, Y); Inc(Y, 24);
  NewLabel(Fields, SNavFieldCaption, FieldLeft, Y);
  FCaption := NewEdit(Fields, FieldLeft + FieldLabelWidth, Y, 260, FieldChange); Inc(Y, 28);
  NewLabel(Fields, SNavFieldIcon, FieldLeft, Y);
  FIconChar := NewEdit(Fields, FieldLeft + FieldLabelWidth, Y, 80, FieldChange);
  NewLabel(Fields, SNavFieldPage, FieldLeft + 200, Y);
  FPageIndex := NewSpin(Fields, FieldLeft + 290, Y, 70, -1, 9999, FieldChange); Inc(Y, 28);
  NewLabel(Fields, SNavFieldBadge, FieldLeft, Y);
  FBadge := NewSpin(Fields, FieldLeft + FieldLabelWidth, Y, 80, 0, 999999, FieldChange);
  FFooter := NewCheck(Fields, SNavFieldFooter, FieldLeft + 200, Y, FieldChange);
  FEnabled := NewCheck(Fields, SNavFieldEnabled, FieldLeft + 290, Y, FieldChange); Inc(Y, 28);
  NewLabel(Fields, SNavFieldHint, FieldLeft, Y);
  FHint := NewEdit(Fields, FieldLeft + FieldLabelWidth, Y, 260, FieldChange);

  FTree := TTreeView.Create(Self);
  FTree.Parent := Self;
  FTree.Align := alClient;
  FTree.ReadOnly := True;
  FTree.HideSelection := False;
  FTree.OnChange := TreeChange;

  if FView.Items.Count > 0 then
    RebuildTree(FView.Items[0])
  else
    RebuildTree(nil);
end;

procedure TPPGNavItemsDialog.AddNodes(Parent: TTreeNode; Items: TPPGNavItems;
  Select: TPPGNavItem; var Found: TTreeNode);
var
  I: Integer;
  It: TPPGNavItem;
  N: TTreeNode;
  T: string;
begin
  for I := 0 to Items.Count - 1 do
  begin
    It := Items[I];
    case It.Kind of
      nikHeader: T := '[' + It.Caption + ']';
      nikSeparator: T := SNavSeparatorCaption;
    else
      T := It.Caption;
    end;
    if It.Footer then
      T := T + ' (' + SNavFieldFooter + ')';
    N := FTree.Items.AddChildObject(Parent, T, It);
    if It = Select then
      Found := N;
    AddNodes(N, It.Items, Select, Found);
  end;
end;

procedure TPPGNavItemsDialog.RebuildTree(Select: TPPGNavItem);
var
  Found: TTreeNode;
begin
  Found := nil;
  FUpdating := True;
  FTree.Items.BeginUpdate;
  try
    FTree.Items.Clear;
    AddNodes(nil, FView.Items, Select, Found);
    FTree.FullExpand;
  finally
    FTree.Items.EndUpdate;
    FUpdating := False;
  end;
  FTree.Selected := Found;
  LoadFields;
end;

function TPPGNavItemsDialog.SelectedItem: TPPGNavItem;
begin
  if FTree.Selected = nil then
    Result := nil
  else
    Result := TPPGNavItem(FTree.Selected.Data);
end;

procedure TPPGNavItemsDialog.SelectItem(Item: TPPGNavItem);
begin
  RebuildTree(Item);
end;

procedure TPPGNavItemsDialog.LoadFields;
var
  It: TPPGNavItem;
  Has: Boolean;
begin
  It := SelectedItem;
  Has := It <> nil;
  FUpdating := True;
  try
    FCaption.Enabled := Has;
    FIconChar.Enabled := Has;
    FPageIndex.Enabled := Has;
    FBadge.Enabled := Has;
    FFooter.Enabled := Has;
    FEnabled.Enabled := Has;
    FHint.Enabled := Has;
    if not Has then
    begin
      FKindLabel.Caption := '';
      FCaption.Text := '';
      Exit;
    end;
    case It.Kind of
      nikHeader: FKindLabel.Caption := SNavKindHeader;
      nikSeparator: FKindLabel.Caption := SNavKindSeparator;
    else
      FKindLabel.Caption := SNavKindItem;
    end;
    FCaption.Text := It.Caption;
    if It.IconChar = 0 then
      FIconChar.Text := ''
    else
      FIconChar.Text := IntToHex(It.IconChar, 4);
    FPageIndex.Value := It.PageIndex;
    FBadge.Value := It.BadgeCount;
    FFooter.Checked := It.Footer;
    FEnabled.Checked := It.Enabled;
    FHint.Text := It.Hint;
  finally
    FUpdating := False;
  end;
end;

procedure TPPGNavItemsDialog.TreeChange(Sender: TObject; Node: TTreeNode);
begin
  if not FUpdating then
    LoadFields;
end;

procedure TPPGNavItemsDialog.FieldChange(Sender: TObject);
var
  It: TPPGNavItem;
  Code: Integer;
  V: Integer;
begin
  if FUpdating then
    Exit;
  It := SelectedItem;
  if It = nil then
    Exit;
  It.Caption := FCaption.Text;
  if Trim(FIconChar.Text) = '' then
    It.IconChar := 0
  else
  begin
    // Ungueltige Eingabe (waehrend des Tippens) aendert nichts
    Val('$' + Trim(FIconChar.Text), V, Code);
    if (Code = 0) and (V >= 0) and (V <= $FFFF) then
      It.IconChar := V;
  end;
  if FPageIndex.Value >= -1 then
    It.PageIndex := FPageIndex.Value;
  if FBadge.Value >= 0 then
    It.BadgeCount := FBadge.Value;
  It.Enabled := FEnabled.Checked;
  It.Hint := FHint.Text;
  if It.Footer <> FFooter.Checked then
  begin
    It.Footer := FFooter.Checked;
    RebuildTree(It);
  end
  else if FTree.Selected <> nil then
    FTree.Selected.Text := It.Caption;
end;

procedure TPPGNavItemsDialog.AddItemClick(Sender: TObject);
begin
  RebuildTree(TPPGNavItemOps.AddAfter(FView, SelectedItem, nikItem, SNavItemCaption));
  FCaption.SetFocus;
end;

procedure TPPGNavItemsDialog.AddChildClick(Sender: TObject);
var
  It: TPPGNavItem;
begin
  It := TPPGNavItemOps.AddChild(SelectedItem, SNavItemCaption);
  if It <> nil then
    RebuildTree(It);
end;

procedure TPPGNavItemsDialog.AddHeaderClick(Sender: TObject);
begin
  RebuildTree(TPPGNavItemOps.AddAfter(FView, SelectedItem, nikHeader, SNavHeaderCaption));
end;

procedure TPPGNavItemsDialog.AddSeparatorClick(Sender: TObject);
begin
  RebuildTree(TPPGNavItemOps.AddAfter(FView, SelectedItem, nikSeparator, ''));
end;

procedure TPPGNavItemsDialog.DeleteClick(Sender: TObject);
var
  It, Next: TPPGNavItem;
  Coll: TCollection;
begin
  It := SelectedItem;
  if It = nil then
    Exit;
  Coll := It.Collection;
  if It.Index + 1 < Coll.Count then
    Next := TPPGNavItem(Coll.Items[It.Index + 1])
  else if It.Index > 0 then
    Next := TPPGNavItem(Coll.Items[It.Index - 1])
  else
    Next := It.ParentItem;
  It.Free;
  RebuildTree(Next);
end;

procedure TPPGNavItemsDialog.UpClick(Sender: TObject);
begin
  if TPPGNavItemOps.Move(SelectedItem, -1) then
    RebuildTree(SelectedItem);
end;

procedure TPPGNavItemsDialog.DownClick(Sender: TObject);
begin
  if TPPGNavItemOps.Move(SelectedItem, 1) then
    RebuildTree(SelectedItem);
end;

procedure TPPGNavItemsDialog.IndentClick(Sender: TObject);
var
  It: TPPGNavItem;
begin
  It := SelectedItem;
  if TPPGNavItemOps.Indent(It) then
    RebuildTree(It);
end;

procedure TPPGNavItemsDialog.OutdentClick(Sender: TObject);
var
  It: TPPGNavItem;
begin
  It := SelectedItem;
  if TPPGNavItemOps.Outdent(It) then
    RebuildTree(It);
end;

{ TPPGTreeItemsDialog }

constructor TPPGTreeItemsDialog.CreateFor(AOwner: TComponent; ASource: TPPGTreeView);
var
  Ops, Fields: TPanel;
  Y: Integer;
begin
  Create(AOwner);
  Caption := Format(STreeTitle, [PPGDisplayName(ASource)]);
  ClientWidth := S(640);
  ClientHeight := S(480);
  FCancelButton.Left := ClientWidth - S(96);
  FOkButton.Left := ClientWidth - S(192);

  Ops := NewPanel(Self, alRight, 120);
  Y := 8;
  NewButton(Ops, STreeNew, 8, Y, 104, AddClick); Inc(Y, 30);
  NewButton(Ops, STreeNewChild, 8, Y, 104, AddChildClick); Inc(Y, 40);
  NewButton(Ops, SOpUp, 8, Y, 104, UpClick); Inc(Y, 30);
  NewButton(Ops, SOpDown, 8, Y, 104, DownClick); Inc(Y, 30);
  NewButton(Ops, SOpIndent, 8, Y, 104, IndentClick); Inc(Y, 30);
  NewButton(Ops, SOpOutdent, 8, Y, 104, OutdentClick); Inc(Y, 40);
  NewButton(Ops, SOpDelete, 8, Y, 104, DeleteClick);

  Fields := NewPanel(Self, alBottom, 150);
  Y := 4;
  NewLabel(Fields, STreeFieldText, FieldLeft, Y);
  FText := NewEdit(Fields, FieldLeft + FieldLabelWidth, Y, 260, FieldChange); Inc(Y, 28);
  NewLabel(Fields, STreeFieldDetail, FieldLeft, Y);
  FDetail := NewEdit(Fields, FieldLeft + FieldLabelWidth, Y, 260, FieldChange); Inc(Y, 28);
  NewLabel(Fields, STreeFieldBadge, FieldLeft, Y);
  FBadge := NewEdit(Fields, FieldLeft + FieldLabelWidth, Y, 80, FieldChange);
  NewLabel(Fields, STreeFieldCheck, FieldLeft + 200, Y);
  FCheckState := TComboBox.Create(Self);
  FCheckState.Parent := Fields;
  FCheckState.Style := csDropDownList;
  FCheckState.SetBounds(S(FieldLeft + 290), S(Y), S(110), S(23));
  FCheckState.Items.Add(SCheckUnchecked);
  FCheckState.Items.Add(SCheckChecked);
  FCheckState.Items.Add(SCheckGrayed);
  FCheckState.OnClick := FieldChange;
  Inc(Y, 28);
  NewLabel(Fields, STreeFieldImage, FieldLeft, Y);
  FImageIndex := NewSpin(Fields, FieldLeft + FieldLabelWidth, Y, 80, -1, 9999, FieldChange);
  NewLabel(Fields, STreeFieldSelImage, FieldLeft + 200, Y);
  FSelectedIndex := NewSpin(Fields, FieldLeft + 290, Y, 80, -1, 9999, FieldChange); Inc(Y, 28);
  FEnabled := NewCheck(Fields, STreeFieldEnabled, FieldLeft + FieldLabelWidth, Y, FieldChange);
  FHasChildren := NewCheck(Fields, STreeFieldHasChildren, FieldLeft + 290, Y, FieldChange);
  FHasChildren.Width := S(200);

  FTree := TPPGTreeView.Create(Self);
  PlainStyle(FTree);
  FTree.Parent := Self;
  FTree.Align := alClient;
  FTree.Preset := ASource.Preset;
  FTree.Images := ASource.Images;
  FTree.CheckBoxes := ASource.CheckBoxes;
  // Haken nicht automatisch weitergeben: im Editor zaehlt der eingestellte Wert
  FTree.AutoCheck := False;
  FTree.Items.Assign(ASource.Items);
  FTree.OnChange := TreeChange;
  if FTree.Items.Count > 0 then
    FTree.Selected := FTree.Items[0];
  LoadFields;
end;

procedure TPPGTreeItemsDialog.LoadFields;
var
  N: TPPGTreeNode;
  Has: Boolean;
begin
  N := FTree.Selected;
  Has := N <> nil;
  FUpdating := True;
  try
    FText.Enabled := Has;
    FDetail.Enabled := Has;
    FBadge.Enabled := Has;
    FImageIndex.Enabled := Has;
    FSelectedIndex.Enabled := Has;
    FCheckState.Enabled := Has;
    FEnabled.Enabled := Has;
    FHasChildren.Enabled := Has;
    if not Has then
    begin
      FText.Text := '';
      Exit;
    end;
    FText.Text := N.Text;
    FDetail.Text := N.Detail;
    FBadge.Text := N.Badge;
    FImageIndex.Value := N.ImageIndex;
    FSelectedIndex.Value := N.SelectedIndex;
    FCheckState.ItemIndex := Ord(N.CheckState);
    FEnabled.Checked := N.Enabled;
    FHasChildren.Checked := N.HasChildren and (N.Count = 0);
  finally
    FUpdating := False;
  end;
end;

procedure TPPGTreeItemsDialog.TreeChange(Sender: TObject; Node: TPPGTreeNode);
begin
  if not FUpdating then
    LoadFields;
end;

procedure TPPGTreeItemsDialog.FieldChange(Sender: TObject);
var
  N: TPPGTreeNode;
begin
  if FUpdating then
    Exit;
  N := FTree.Selected;
  if N = nil then
    Exit;
  N.Text := FText.Text;
  N.Detail := FDetail.Text;
  N.Badge := FBadge.Text;
  if FImageIndex.Value >= -1 then
    N.ImageIndex := FImageIndex.Value;
  if FSelectedIndex.Value >= -1 then
    N.SelectedIndex := FSelectedIndex.Value;
  if FCheckState.ItemIndex >= 0 then
    N.CheckState := TCheckBoxState(FCheckState.ItemIndex);
  N.Enabled := FEnabled.Checked;
  if N.Count = 0 then
    N.HasChildren := FHasChildren.Checked;
end;

procedure TPPGTreeItemsDialog.AddClick(Sender: TObject);
var
  N: TPPGTreeNode;
begin
  if FTree.Selected <> nil then
  begin
    // Direkt hinter dem gewaehlten Knoten (Insert fuegt davor ein)
    if FTree.Selected.GetNextSibling <> nil then
      N := FTree.Items.Insert(FTree.Selected.GetNextSibling, STreeNodeCaption)
    else
      N := FTree.Items.Add(FTree.Selected, STreeNodeCaption);
  end
  else
    N := FTree.Items.Add(nil, STreeNodeCaption);
  FTree.Selected := N;
  LoadFields;
end;

procedure TPPGTreeItemsDialog.AddChildClick(Sender: TObject);
var
  N: TPPGTreeNode;
begin
  if FTree.Selected = nil then
    Exit;
  N := FTree.Items.AddChild(FTree.Selected, STreeNodeCaption);
  FTree.Selected.Expanded := True;
  FTree.Selected := N;
  LoadFields;
end;

procedure TPPGTreeItemsDialog.DeleteClick(Sender: TObject);
var
  N, Next: TPPGTreeNode;
begin
  N := FTree.Selected;
  if N = nil then
    Exit;
  Next := N.GetNextSibling;
  if Next = nil then
    Next := N.GetPrevSibling;
  if Next = nil then
    Next := N.Parent;
  N.Delete;
  FTree.Selected := Next;
  LoadFields;
end;

procedure TPPGTreeItemsDialog.UpClick(Sender: TObject);
var
  N: TPPGTreeNode;
begin
  N := FTree.Selected;
  if TPPGTreeNodeOps.Move(N, -1) then
    FTree.Selected := N;
end;

procedure TPPGTreeItemsDialog.DownClick(Sender: TObject);
var
  N: TPPGTreeNode;
begin
  N := FTree.Selected;
  if TPPGTreeNodeOps.Move(N, 1) then
    FTree.Selected := N;
end;

procedure TPPGTreeItemsDialog.IndentClick(Sender: TObject);
var
  N: TPPGTreeNode;
begin
  N := FTree.Selected;
  if TPPGTreeNodeOps.Indent(N) then
    FTree.Selected := N;
end;

procedure TPPGTreeItemsDialog.OutdentClick(Sender: TObject);
var
  N: TPPGTreeNode;
begin
  N := FTree.Selected;
  if TPPGTreeNodeOps.Outdent(N) then
    FTree.Selected := N;
end;

end.
