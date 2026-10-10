unit ExSearchEditFilter;

// Praxisbeispiel 2 zu TPPGSearchEdit (Demo-Seite "Eingabe > TPPGSearchEdit"):
// Suchfeld ueber einer Artikelliste. OnSearch filtert die Liste (ohne
// Vorschlagsliste), ValidationState warnt bei 0 Treffern, OnSubmit (Enter)
// waehlt den ersten Treffer.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.StyleManager, PPG.Controls.Field, PPG.Labels, PPG.ListBox, PPG.SearchEdit;

type
  /// Artikelliste mit Suchfeld: Die Liste zeigt nur die Treffer, Enter
  /// waehlt den ersten.
  TArticleFilter = class(TComponent)
  private
    FSearch: TPPGSearchEdit;
    FList: TPPGListBox;
    FCount: TPPGLabel;
    FArticles: TStringList;
    procedure SearchFilter(Sender: TObject; const SearchText: string);
    procedure SearchSubmit(Sender: TObject; const SearchText: string);
  public
    constructor CreateIn(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    destructor Destroy; override;
    property Search: TPPGSearchEdit read FSearch;
    property List: TPPGListBox read FList;
    property CountLabel: TPPGLabel read FCount;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
constructor TArticleFilter.CreateIn(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);
  // Stammdaten (sonst aus der Datenbank)
  FArticles := TStringList.Create;
  FArticles.CommaText := '"Netzwerkkabel 2 m","Netzwerkkabel 5 m","HDMI-Kabel 1,5 m",' +
    '"Maus kabellos","Maus mit Kabel","Tastatur DE","Monitor 24 Zoll","Monitor 27 Zoll",' +
    '"Dockingstation USB-C","Headset Office","Webcam HD","USB-Stick 64 GB"';

  FSearch := TPPGSearchEdit.Create(Self);
  FSearch.Parent := AParent;
  FSearch.SetBounds(16, 16, 260, 32);
  FSearch.StyleManager := AStyles;
  FSearch.TextHint := 'Artikel filtern';
  FSearch.SearchDelay := 150;   // Liste folgt fast sofort, aber nicht bei jedem Zeichen
  FSearch.MaxLength := 40;
  FSearch.OnSearch := SearchFilter;
  FSearch.OnSubmit := SearchSubmit;

  FCount := TPPGLabel.Create(Self);
  FCount.Parent := AParent;
  FCount.SetBounds(288, 22, 142, 20);

  FList := TPPGListBox.Create(Self);
  FList.Parent := AParent;
  FList.SetBounds(16, 60, 414, 200);
  FList.StyleManager := AStyles;

  SearchFilter(FSearch, '');   // Anfangs alle Artikel
end;

destructor TArticleFilter.Destroy;
begin
  FArticles.Free;
  inherited Destroy;
end;

procedure TArticleFilter.SearchFilter(Sender: TObject; const SearchText: string);
var
  Key: string;
  I: Integer;
begin
  // Keine Vorschlaege (Items bleibt leer): Die Liste selbst zeigt die Treffer
  Key := LowerCase(Trim(SearchText));
  FList.Items.BeginUpdate;
  try
    FList.Items.Clear;
    for I := 0 to FArticles.Count - 1 do
      if (Key = '') or (Pos(Key, LowerCase(FArticles[I])) > 0) then
        FList.Items.Add(FArticles[I]);
  finally
    FList.Items.EndUpdate;
  end;
  FCount.Caption := Format('%d von %d Artikeln', [FList.Items.Count, FArticles.Count]);
  // Keine Treffer: gelber Rand und ein Hinweis, statt einer leeren Liste ohne Erklaerung
  if FList.Items.Count = 0 then
  begin
    FSearch.ValidationState := pvsWarning;
    FSearch.ValidationHint := 'Kein Artikel passt zu "' + Trim(SearchText) + '".';
  end
  else
  begin
    FSearch.ValidationState := pvsNone;
    FSearch.ValidationHint := '';
  end;
end;

procedure TArticleFilter.SearchSubmit(Sender: TObject; const SearchText: string);
begin
  // Enter: eine noch wartende Suche ist entfallen, also jetzt filtern und
  // den ersten Treffer waehlen
  SearchFilter(Sender, SearchText);
  if FList.Items.Count > 0 then
  begin
    FList.ItemIndex := 0;
    if FList.CanFocus then
      FList.SetFocus;
  end;
end;
// EXAMPLE-END

end.
