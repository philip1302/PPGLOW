unit PPG.RichEdit;

{ TPPGRichEdit - mehrzeiliges Eingabefeld mit Formatierung (Ersatz fuer TRichEdit).

  - Natives RichEdit (msftedit, RICHEDIT50W) ohne Rahmen im PPGlow-Rahmen
    (siehe PPG.Controls.Field): Preset, Fokusrahmen, Hover, ValidationState,
    Hochkontrast, Screenreader. IME, Undo, Zwischenablage, Rechtschreibung und
    Drucken kommen vom RichEdit selbst.
  - API wie TRichEdit: Lines (RTF per LoadFromStream/SaveToStream, PlainText
    schaltet auf reinen Text), SelAttributes, DefAttributes, Paragraph (die
    VCL-Klassen TTextAttributes und TParaAttributes), FindText, Print, Zoom.
  - Theme: Fensterfarbe und Standard-Textfarbe (DefAttributes.Color) folgen dem
    Theme (Dark Mode, Hochkontrast, VCL-Style). Nur die Standardfarbe wird
    gesetzt; Text mit eigener Farbe (RTF-Farbtabelle, SelAttributes.Color)
    behaelt sie.
  - Die Scrollbalken bleiben nativ; im Dark Mode im dunklen Windows-Design.
  - Wie bei TRichEdit liefert Text die Absaetze mit #13 getrennt (Lines.Text
    mit #13#10). Die Zeilen im DFM sind reiner Text ohne Formatierung. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, Vcl.Controls, Vcl.Graphics,
  Vcl.StdCtrls, Vcl.ComCtrls,
  // nach Vcl.StdCtrls: ab XE3 liegt TScrollStyle in System.UITypes (Alias deprecated)
  System.UITypes,
  PPG.Controls.Field;

type
  /// Natives RichEdit im Inneren eines Felds (ohne Rahmen).
  TPPGFieldRichEdit = class(TCustomRichEdit, IPPGFieldInner)
  private
    FTextColor: TColor;
    FDarkScrollBars: Boolean;
    procedure SetTextColor(const Value: TColor);
    procedure SetDarkScrollBars(const Value: Boolean);
    procedure ApplyScrollTheme;
    function PushTextColor: THandle;
    procedure PopTextColor(Saved: THandle);
    { IPPGFieldInner }
    procedure SetFieldTextColor(Color: TColor);
    procedure SetFieldDarkScrollBars(Value: Boolean);
    procedure CMColorChanged(var Message: TMessage); message CM_COLORCHANGED;
  protected
    procedure CreateWnd; override;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    /// Farbe fuer Text ohne eigene Farbe statt Font.Color (clNone = Font.Color).
    property TextColor: TColor read FTextColor write SetTextColor;
    property DarkScrollBars: Boolean read FDarkScrollBars write SetDarkScrollBars;
  end;

  TPPGRichLinkClickEvent = procedure(Sender: TObject; const URL: string;
    Button: TMouseButton) of object;

  TPPGCustomRichEdit = class(TPPGCustomField)
  private
    FOnSelectionChange: TNotifyEvent;
    FOnLinkClick: TPPGRichLinkClickEvent;
    FOnProtectChange: TRichEditProtectChange;
    FOnResizeRequest: TRichEditResizeEvent;
    FOnSaveClipboard: TRichEditSaveClipboard;
    function Rich: TCustomRichEdit;
    function GetLines: TStrings;
    procedure SetLines(const Value: TStrings);
    function GetPlainText: Boolean;
    procedure SetPlainText(const Value: Boolean);
    function GetScrollBars: TScrollStyle;
    procedure SetScrollBars(const Value: TScrollStyle);
    function GetWantReturns: Boolean;
    procedure SetWantReturns(const Value: Boolean);
    function GetWantTabs: Boolean;
    procedure SetWantTabs(const Value: Boolean);
    function GetRichWordWrap: Boolean;
    procedure SetRichWordWrap(const Value: Boolean);
    function GetHideScrollBars: Boolean;
    procedure SetHideScrollBars(const Value: Boolean);
    function GetRichHideSelection: Boolean;
    procedure SetRichHideSelection(const Value: Boolean);
    function GetZoom: Integer;
    procedure SetZoom(const Value: Integer);
    function GetEnableURLs: Boolean;
    procedure SetEnableURLs(const Value: Boolean);
    function GetShowURLHint: Boolean;
    procedure SetShowURLHint(const Value: Boolean);
    function GetSpellChecking: Boolean;
    procedure SetSpellChecking(const Value: Boolean);
    function GetCaretPos: TPoint;
    procedure SetCaretPos(const Value: TPoint);
    function GetActiveLineNo: Integer;
    function GetSelAttributes: TTextAttributes;
    procedure SetSelAttributes(const Value: TTextAttributes);
    function GetDefAttributes: TTextAttributes;
    procedure SetDefAttributes(const Value: TTextAttributes);
    function GetParagraph: TParaAttributes;
    procedure InnerSelectionChange(Sender: TObject);
    procedure InnerLinkClick(Sender: TCustomRichEdit; const URL: string; Button: TMouseButton);
    procedure InnerProtectChange(Sender: TObject; StartPos, EndPos: Integer;
      var AllowChange: Boolean);
    procedure InnerResizeRequest(Sender: TObject; Rect: TRect);
    procedure InnerSaveClipboard(Sender: TObject; NumObjects, NumChars: Integer;
      var SaveClipboard: Boolean);
  protected
    function CreateInner: TCustomEdit; override;
    function AccValue: string; override;
    /// OnSelectionChange (Auswahl oder Cursor haben sich geaendert).
    procedure SelectionChange; virtual;
    property Lines: TStrings read GetLines write SetLines;
    /// True: Lines.LoadFromStream/SaveToStream lesen und schreiben reinen Text
    /// statt RTF. Vorgabe False (RTF).
    property PlainText: Boolean read GetPlainText write SetPlainText default False;
    property ScrollBars: TScrollStyle read GetScrollBars write SetScrollBars default ssNone;
    property WantReturns: Boolean read GetWantReturns write SetWantReturns default True;
    property WantTabs: Boolean read GetWantTabs write SetWantTabs default False;
    property WordWrap: Boolean read GetRichWordWrap write SetRichWordWrap default True;
    property HideScrollBars: Boolean read GetHideScrollBars write SetHideScrollBars default True;
    /// Eigene Eigenschaft statt der des TCustomEdit: das RichEdit hat eine eigene.
    property HideSelection: Boolean read GetRichHideSelection write SetRichHideSelection
      default True;
    property Zoom: Integer read GetZoom write SetZoom default 100;
    property EnableURLs: Boolean read GetEnableURLs write SetEnableURLs default False;
    property ShowURLHint: Boolean read GetShowURLHint write SetShowURLHint default False;
    property SpellChecking: Boolean read GetSpellChecking write SetSpellChecking default False;
    property OnSelectionChange: TNotifyEvent read FOnSelectionChange write FOnSelectionChange;
    property OnLinkClick: TPPGRichLinkClickEvent read FOnLinkClick write FOnLinkClick;
    property OnProtectChange: TRichEditProtectChange read FOnProtectChange
      write FOnProtectChange;
    property OnResizeRequest: TRichEditResizeEvent read FOnResizeRequest
      write FOnResizeRequest;
    property OnSaveClipboard: TRichEditSaveClipboard read FOnSaveClipboard
      write FOnSaveClipboard;
  public
    constructor Create(AOwner: TComponent); override;
    /// Sucht Text ab StartPos in den naechsten Length Zeichen; Ergebnis = Position
    /// oder -1. Markiert den Fund nicht.
    function FindText(const SearchStr: string; StartPos, Length: Integer;
      Options: TSearchTypes): Integer;
    /// Druckt den Inhalt (formatiert) auf dem Standarddrucker.
    procedure Print(const Caption: string);
    /// Fuegt Text als Link (anklickbar, OnLinkClick) an der Auswahl ein.
    procedure SetSelTextToFriendlyURL(const Text, URL: string);
    property CaretPos: TPoint read GetCaretPos write SetCaretPos;
    /// Nummer der Zeile mit dem Cursor (0-basiert).
    property ActiveLineNo: Integer read GetActiveLineNo;
    /// Zeichen der Auswahl (nach dem Markieren; ohne Auswahl: an der Cursorstelle).
    property SelAttributes: TTextAttributes read GetSelAttributes write SetSelAttributes;
    /// Standardzeichen: gilt fuer Text ohne eigene Formatierung.
    property DefAttributes: TTextAttributes read GetDefAttributes write SetDefAttributes;
    /// Absatzformat der Auswahl.
    property Paragraph: TParaAttributes read GetParagraph;
  end;

  TPPGRichEdit = class(TPPGCustomRichEdit)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property UseSystemContextMenu;
    property ValidationState;
    property ValidationHint;
    property HighContrastSupport;
    { wie TRichEdit }
    property Align;
    property Anchors;
    property BiDiMode;
    property BorderStyle;
    property Color default clWindow;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property EnableURLs;
    property Enabled;
    property Font;
    property HideScrollBars;
    property HideSelection;
    property Lines;
    property MaxLength;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PlainText;
    property PopupMenu;
    property ReadOnly;
    property ReadOnlyStyle;
    property ScrollBars;
    property ShowHint;
    property ShowURLHint;
    property SpellChecking;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop;
    property Visible;
    property WantReturns;
    property WantTabs;
    property WordWrap;
    property Zoom;
    property Touch;
    property OnGesture;
    property OnChange;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnLinkClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnProtectChange;
    property OnResizeRequest;
    property OnSaveClipboard;
    property OnSelectionChange;
    property OnStartDock;
    property OnStartDrag;
    property OnMouseActivate;
    property DoubleBuffered;
    property ParentDoubleBuffered;
  end;

implementation

uses
  System.SysUtils, Winapi.UxTheme, PPG.Types;

type
  /// Zugriff auf die geschuetzten Teile von TCustomRichEdit.
  TRichAccess = class(TCustomRichEdit);

{ TPPGFieldRichEdit }

constructor TPPGFieldRichEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTextColor := clNone;
end;

procedure TPPGFieldRichEdit.SetTextColor(const Value: TColor);
begin
  if FTextColor <> Value then
  begin
    FTextColor := Value;
    if HandleAllocated then
      Invalidate;
  end;
end;

procedure TPPGFieldRichEdit.SetFieldTextColor(Color: TColor);
begin
  SetTextColor(Color);
end;

procedure TPPGFieldRichEdit.SetFieldDarkScrollBars(Value: Boolean);
begin
  SetDarkScrollBars(Value);
end;

procedure TPPGFieldRichEdit.SetDarkScrollBars(const Value: Boolean);
begin
  if FDarkScrollBars <> Value then
  begin
    FDarkScrollBars := Value;
    ApplyScrollTheme;
  end;
end;

var
  SetSysColorsTemp: function(Colors, Brushes: Pointer; Count: THandle): THandle; stdcall;
  SetSysColorsTempLooked: Boolean;

function TPPGFieldRichEdit.PushTextColor: THandle;
var
  Colors: array[0..COLOR_3DFACE] of DWORD;
  I: Integer;
begin
  Result := 0;
  if (FTextColor = clNone) or not HandleAllocated then
    Exit;
  if ColorToRGB(FTextColor) = TColor(GetSysColor(COLOR_WINDOWTEXT)) then
    Exit;
  if not SetSysColorsTempLooked then
  begin
    SetSysColorsTempLooked := True;
    @SetSysColorsTemp := GetProcAddress(GetModuleHandle(user32), 'SetSysColorsTemp');
  end;
  if not Assigned(SetSysColorsTemp) then
    Exit;
  for I := Low(Colors) to High(Colors) do
    Colors[I] := GetSysColor(I);
  Colors[COLOR_WINDOWTEXT] := DWORD(ColorToRGB(FTextColor));
  Result := SetSysColorsTemp(@Colors, nil, Length(Colors));
end;

procedure TPPGFieldRichEdit.PopTextColor(Saved: THandle);
begin
  if (Saved <> 0) and Assigned(SetSysColorsTemp) then
    SetSysColorsTemp(nil, nil, Saved);
end;

procedure TPPGFieldRichEdit.ApplyScrollTheme;
begin
  if not HandleAllocated then
    Exit;
  // Rein kosmetisch (siehe TPPGFieldMemo)
  if FDarkScrollBars then
    SetWindowTheme(Handle, 'DarkMode_Explorer', nil)
  else
    SetWindowTheme(Handle, nil, nil);
  SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or
    SWP_NOACTIVATE or SWP_FRAMECHANGED);
end;

procedure TPPGFieldRichEdit.CMColorChanged(var Message: TMessage);
begin
  // Die VCL schickt EM_SETBKGNDCOLOR ohne Pruefung und erzwingt damit ein
  // Fenster, auch wenn das Feld noch keinen Parent hat. CreateWnd setzt die
  // Farbe selbst.
  if HandleAllocated then
    inherited
  else
    Brush.Color := Color;
end;

procedure TPPGFieldRichEdit.CreateWnd;
var
  FollowsParent: Boolean;
begin
  FollowsParent := ParentFont;
  inherited CreateWnd;
  // Die VCL setzt hier Font.Charset und loest damit ParentFont ab; das Feld
  // soll seine Schrift aber weiter an das innere RichEdit geben.
  if FollowsParent and not ParentFont then
    ParentFont := True;
  if FDarkScrollBars then
    ApplyScrollTheme;
end;

procedure TPPGFieldRichEdit.WndProc(var Message: TMessage);
var
  Saved: THandle;
begin
  // Text ohne eigene Farbe ("automatisch") malt das RichEdit in COLOR_WINDOWTEXT,
  // nicht in Font.Color. Waehrend des Zeichnens gilt deshalb die Themefarbe als
  // Systemfarbe (derselbe Weg wie die VCL beim Zeichnen deaktivierter RichEdits).
  // Text mit eigener Farbe und der gespeicherte RTF-Inhalt bleiben unberuehrt.
  if (Message.Msg = WM_PAINT) or (Message.Msg = WM_PRINT) or (Message.Msg = WM_PRINTCLIENT) then
  begin
    Saved := PushTextColor;
    try
      inherited WndProc(Message);
    finally
      PopTextColor(Saved);
    end;
  end
  else
    inherited WndProc(Message);
end;

{ TPPGCustomRichEdit }

constructor TPPGCustomRichEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AutoSize := False; // Mehrzeiler: Groesse bestimmt der Anwender
  Width := 185;
  Height := 89;
end;

function TPPGCustomRichEdit.CreateInner: TCustomEdit;
var
  R: TRichAccess;
begin
  Result := TPPGFieldRichEdit.Create(Self);
  R := TRichAccess(Result);
  R.OnSelectionChange := InnerSelectionChange;
  R.OnLinkClick := InnerLinkClick;
  R.OnProtectChange := InnerProtectChange;
  R.OnResizeRequest := InnerResizeRequest;
  R.OnSaveClipboard := InnerSaveClipboard;
end;

function TPPGCustomRichEdit.Rich: TCustomRichEdit;
begin
  Result := TCustomRichEdit(Inner);
end;

procedure TPPGCustomRichEdit.SelectionChange;
begin
  if Assigned(FOnSelectionChange) then
    FOnSelectionChange(Self);
end;

procedure TPPGCustomRichEdit.InnerSelectionChange(Sender: TObject);
begin
  SelectionChange;
end;

procedure TPPGCustomRichEdit.InnerLinkClick(Sender: TCustomRichEdit; const URL: string;
  Button: TMouseButton);
begin
  if Assigned(FOnLinkClick) then
    FOnLinkClick(Self, URL, Button);
end;

procedure TPPGCustomRichEdit.InnerProtectChange(Sender: TObject; StartPos, EndPos: Integer;
  var AllowChange: Boolean);
begin
  if Assigned(FOnProtectChange) then
    FOnProtectChange(Self, StartPos, EndPos, AllowChange);
end;

procedure TPPGCustomRichEdit.InnerResizeRequest(Sender: TObject; Rect: TRect);
begin
  if Assigned(FOnResizeRequest) then
    FOnResizeRequest(Self, Rect);
end;

procedure TPPGCustomRichEdit.InnerSaveClipboard(Sender: TObject; NumObjects, NumChars: Integer;
  var SaveClipboard: Boolean);
begin
  if Assigned(FOnSaveClipboard) then
    FOnSaveClipboard(Self, NumObjects, NumChars, SaveClipboard);
end;

function TPPGCustomRichEdit.GetLines: TStrings;
begin
  Result := TRichAccess(Rich).Lines;
end;

procedure TPPGCustomRichEdit.SetLines(const Value: TStrings);
begin
  TRichAccess(Rich).Lines.Assign(Value);
end;

function TPPGCustomRichEdit.GetPlainText: Boolean;
begin
  Result := TRichAccess(Rich).PlainText;
end;

procedure TPPGCustomRichEdit.SetPlainText(const Value: Boolean);
begin
  TRichAccess(Rich).PlainText := Value;
end;

function TPPGCustomRichEdit.GetScrollBars: TScrollStyle;
begin
  Result := TRichAccess(Rich).ScrollBars;
end;

procedure TPPGCustomRichEdit.SetScrollBars(const Value: TScrollStyle);
begin
  TRichAccess(Rich).ScrollBars := Value;
end;

function TPPGCustomRichEdit.GetWantReturns: Boolean;
begin
  Result := TRichAccess(Rich).WantReturns;
end;

procedure TPPGCustomRichEdit.SetWantReturns(const Value: Boolean);
begin
  TRichAccess(Rich).WantReturns := Value;
end;

function TPPGCustomRichEdit.GetWantTabs: Boolean;
begin
  Result := TRichAccess(Rich).WantTabs;
end;

procedure TPPGCustomRichEdit.SetWantTabs(const Value: Boolean);
begin
  TRichAccess(Rich).WantTabs := Value;
end;

function TPPGCustomRichEdit.GetRichWordWrap: Boolean;
begin
  Result := TRichAccess(Rich).WordWrap;
end;

procedure TPPGCustomRichEdit.SetRichWordWrap(const Value: Boolean);
begin
  TRichAccess(Rich).WordWrap := Value;
  InvalidateInner;
end;

function TPPGCustomRichEdit.GetHideScrollBars: Boolean;
begin
  Result := TRichAccess(Rich).HideScrollBars;
end;

procedure TPPGCustomRichEdit.SetHideScrollBars(const Value: Boolean);
begin
  TRichAccess(Rich).HideScrollBars := Value;
end;

function TPPGCustomRichEdit.GetRichHideSelection: Boolean;
begin
  Result := TRichAccess(Rich).HideSelection;
end;

procedure TPPGCustomRichEdit.SetRichHideSelection(const Value: Boolean);
begin
  if Rich.HandleAllocated then
    TRichAccess(Rich).HideSelection := Value
  else
    try
      // Die VCL setzt das Feld und schickt dann ohne Pruefung eine Nachricht
      // (erzwingt ein Fenster); CreateParams liest das Feld spaeter.
      TRichAccess(Rich).HideSelection := Value;
    except
      on EInvalidOperation do
        if TRichAccess(Rich).HideSelection <> Value then
          raise;
    end;
end;

function TPPGCustomRichEdit.GetZoom: Integer;
begin
  Result := Rich.Zoom;
end;

procedure TPPGCustomRichEdit.SetZoom(const Value: Integer);
begin
  Rich.Zoom := PPGCheckRange(Self, 'Zoom', Value, 1, 6400);
end;

function TPPGCustomRichEdit.GetEnableURLs: Boolean;
begin
  Result := Rich.EnableURLs;
end;

procedure TPPGCustomRichEdit.SetEnableURLs(const Value: Boolean);
begin
  Rich.EnableURLs := Value;
end;

function TPPGCustomRichEdit.GetShowURLHint: Boolean;
begin
  Result := Rich.ShowURLHint;
end;

procedure TPPGCustomRichEdit.SetShowURLHint(const Value: Boolean);
begin
  Rich.ShowURLHint := Value;
end;

function TPPGCustomRichEdit.GetSpellChecking: Boolean;
begin
  Result := Rich.SpellChecking;
end;

procedure TPPGCustomRichEdit.SetSpellChecking(const Value: Boolean);
begin
  Rich.SpellChecking := Value;
end;

function TPPGCustomRichEdit.GetCaretPos: TPoint;
begin
  Result := TRichAccess(Rich).CaretPos;
end;

procedure TPPGCustomRichEdit.SetCaretPos(const Value: TPoint);
begin
  TRichAccess(Rich).CaretPos := Value;
end;

function TPPGCustomRichEdit.GetActiveLineNo: Integer;
begin
  Result := Integer(Rich.ActiveLineNo);
end;

function TPPGCustomRichEdit.GetSelAttributes: TTextAttributes;
begin
  Result := Rich.SelAttributes;
end;

procedure TPPGCustomRichEdit.SetSelAttributes(const Value: TTextAttributes);
begin
  Rich.SelAttributes := Value;
end;

function TPPGCustomRichEdit.GetDefAttributes: TTextAttributes;
begin
  Result := Rich.DefAttributes;
end;

procedure TPPGCustomRichEdit.SetDefAttributes(const Value: TTextAttributes);
begin
  Rich.DefAttributes := Value;
end;

function TPPGCustomRichEdit.GetParagraph: TParaAttributes;
begin
  Result := Rich.Paragraph;
end;

function TPPGCustomRichEdit.FindText(const SearchStr: string; StartPos, Length: Integer;
  Options: TSearchTypes): Integer;
begin
  Result := Rich.FindText(SearchStr, StartPos, Length, Options);
end;

procedure TPPGCustomRichEdit.Print(const Caption: string);
begin
  Rich.Print(Caption);
end;

procedure TPPGCustomRichEdit.SetSelTextToFriendlyURL(const Text, URL: string);
begin
  Rich.SetSelTextToFriendlyURL(Text, URL);
end;

function TPPGCustomRichEdit.AccValue: string;
begin
  Result := Text;
end;

end.
