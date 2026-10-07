unit PPG.Editors.Logic;

{ Logik der Designer-Editoren (Phase 9a) - ohne DesignIntf, deshalb auch in
  den Tests und zur Laufzeit verwendbar. Die Dialoge (PPG.Editors.Forms) und
  die IDE-Anbindung (PPG.Reg) sind nur duenne Schichten darueber.

  - Preset auf ein ganzes Formular anwenden (alle Komponenten mit einer
    published Property "Preset": Controls, StyleManager, NotificationCenter).
  - Eintraege der NavigationView und Knoten des TreeView verschieben,
    einruecken und ausruecken.
  - Appearance auf einer Kopie bearbeiten (Abbrechen verwirft). }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.Generics.Collections,
  PPG.Appearance, PPG.Controls.Base, PPG.NavigationView, PPG.TreeView;

type
  /// Alle Komponenten von Root (Owner-Kette), die ein Preset haben.
  /// Liefert die Anzahl.
  TPPGPresetTargets = class
  public
    class function Collect(Root: TComponent; List: TList<TComponent>): Integer; static;
    /// Setzt das Preset aller Ziele. Erst wird geprueft, dass das Preset
    /// existiert (sonst EPPGPropertyError, nichts geaendert). Komponenten mit
    /// StyleManager werden uebersprungen (ihr Preset kommt vom Manager).
    /// Ergebnis: Anzahl geaenderter Komponenten.
    class function Apply(Root: TComponent; const Preset: string): Integer; static;
    class function HasPreset(C: TComponent): Boolean; static;
    class function UsesStyleManager(C: TComponent): Boolean; static;
  end;

  /// Struktur-Operationen fuer die verschachtelten Eintraege der NavigationView.
  /// Alle liefern False, wenn die Operation nicht moeglich ist (dann bleibt
  /// alles unveraendert).
  TPPGNavItemOps = class
  public
    /// Wird letzter Untereintrag des vorigen Geschwisters.
    class function Indent(Item: TPPGNavItem): Boolean; static;
    /// Wird Geschwister direkt hinter dem Elterneintrag.
    class function Outdent(Item: TPPGNavItem): Boolean; static;
    /// Delta -1 = nach oben, +1 = nach unten (innerhalb der Geschwister).
    class function Move(Item: TPPGNavItem; Delta: Integer): Boolean; static;
    /// Neuer Eintrag hinter Item (Item = nil: am Ende der obersten Ebene).
    class function AddAfter(View: TPPGNavigationView; Item: TPPGNavItem;
      AKind: TPPGNavItemKind; const ACaption: string): TPPGNavItem; static;
    class function AddChild(Item: TPPGNavItem; const ACaption: string): TPPGNavItem; static;
  end;

  /// Struktur-Operationen fuer Knoten des TreeView (wie TPPGNavItemOps).
  TPPGTreeNodeOps = class
  public
    class function Indent(Node: TPPGTreeNode): Boolean; static;
    class function Outdent(Node: TPPGTreeNode): Boolean; static;
    class function Move(Node: TPPGTreeNode; Delta: Integer): Boolean; static;
  end;

  /// Bearbeitet die Appearance eines Controls auf einer Kopie.
  TPPGAppearanceSession = class
  private
    FTarget: TPPGCustomControl;
    FWork: TPPGAppearance;
  public
    constructor Create(ATarget: TPPGCustomControl);
    destructor Destroy; override;
    /// Kopie auf die Vorgaben des Presets des Ziels zuruecksetzen.
    procedure ResetToPreset;
    /// True, wenn die Kopie vom Ziel abweicht.
    function Modified: Boolean;
    /// Kopie ins Ziel schreiben.
    procedure Apply;
    property Target: TPPGCustomControl read FTarget;
    property Work: TPPGAppearance read FWork;
  end;

implementation

uses
  System.SysUtils, System.TypInfo, Vcl.ComCtrls,
  PPG.Consts, PPG.Exceptions, PPG.Render.Intf, PPG.Render.Registry, PPG.StyleManager;

type
  // StyleManager und Appearance sind in der Basis protected
  TCtrlAccess = class(TPPGCustomControl);

{ TPPGPresetTargets }

class function TPPGPresetTargets.HasPreset(C: TComponent): Boolean;
var
  P: PPropInfo;
begin
  P := GetPropInfo(C, 'Preset');
  Result := (P <> nil) and (P^.PropType^^.Kind in [tkString, tkLString, tkWString, tkUString]) and
    (P^.SetProc <> nil);
end;

class function TPPGPresetTargets.UsesStyleManager(C: TComponent): Boolean;
begin
  Result := (C is TPPGCustomControl) and (TCtrlAccess(C).StyleManager <> nil);
end;

class function TPPGPresetTargets.Collect(Root: TComponent; List: TList<TComponent>): Integer;
var
  I: Integer;
  C: TComponent;
begin
  Result := 0;
  if Root = nil then
    Exit;
  for I := 0 to Root.ComponentCount - 1 do
  begin
    C := Root.Components[I];
    if HasPreset(C) then
    begin
      if List <> nil then
        List.Add(C);
      Inc(Result);
    end;
  end;
end;

class function TPPGPresetTargets.Apply(Root: TComponent; const Preset: string): Integer;
var
  L: TList<TComponent>;
  C: TComponent;
  R: IPPGRenderer;
begin
  // Erst validieren, dann zuweisen: unbekanntes Preset aendert nichts
  R := TPPGRendererRegistry.Find(Preset);
  if R = nil then
    raise EPPGPropertyError.CreateInvalid(Root, 'Preset', Preset);
  Result := 0;
  L := TList<TComponent>.Create;
  try
    Collect(Root, L);
    for C in L do
    begin
      if UsesStyleManager(C) then
        Continue;
      if SameText(GetStrProp(C, 'Preset'), Preset) then
        Continue;
      SetStrProp(C, 'Preset', Preset);
      Inc(Result);
    end;
  finally
    L.Free;
  end;
end;

{ TPPGNavItemOps }

class function TPPGNavItemOps.Indent(Item: TPPGNavItem): Boolean;
var
  Prev: TPPGNavItem;
begin
  Result := False;
  if (Item = nil) or (Item.Index = 0) then
    Exit;
  Prev := TPPGNavItems(Item.Collection).Items[Item.Index - 1];
  // Nur echte Eintraege koennen Untereintraege haben
  if Prev.Kind <> nikItem then
    Exit;
  Item.Collection := Prev.Items;
  Prev.Expanded := True;
  Result := True;
end;

class function TPPGNavItemOps.Outdent(Item: TPPGNavItem): Boolean;
var
  Parent: TPPGNavItem;
  Idx: Integer;
begin
  Result := False;
  if Item = nil then
    Exit;
  Parent := Item.ParentItem;
  if Parent = nil then
    Exit;
  Idx := Parent.Index;
  Item.Collection := Parent.Collection;
  Item.Index := Idx + 1;
  Result := True;
end;

class function TPPGNavItemOps.Move(Item: TPPGNavItem; Delta: Integer): Boolean;
var
  NewIndex: Integer;
begin
  Result := False;
  if (Item = nil) or (Delta = 0) then
    Exit;
  NewIndex := Item.Index + Delta;
  if (NewIndex < 0) or (NewIndex >= Item.Collection.Count) then
    Exit;
  Item.Index := NewIndex;
  Result := True;
end;

class function TPPGNavItemOps.AddAfter(View: TPPGNavigationView; Item: TPPGNavItem;
  AKind: TPPGNavItemKind; const ACaption: string): TPPGNavItem;
var
  Coll: TPPGNavItems;
begin
  if Item <> nil then
    Coll := TPPGNavItems(Item.Collection)
  else
    Coll := View.Items;
  Result := Coll.Add;
  Result.Kind := AKind;
  Result.Caption := ACaption;
  if Item <> nil then
    Result.Index := Item.Index + 1;
end;

class function TPPGNavItemOps.AddChild(Item: TPPGNavItem; const ACaption: string): TPPGNavItem;
begin
  Result := nil;
  if (Item = nil) or (Item.Kind <> nikItem) then
    Exit;
  Result := Item.Items.Add;
  Result.Caption := ACaption;
  Item.Expanded := True;
end;

{ TPPGTreeNodeOps }

class function TPPGTreeNodeOps.Indent(Node: TPPGTreeNode): Boolean;
var
  Prev: TPPGTreeNode;
begin
  Result := False;
  if Node = nil then
    Exit;
  Prev := Node.GetPrevSibling;
  if Prev = nil then
    Exit;
  Node.MoveTo(Prev, naAddChild);
  Prev.Expanded := True;
  Result := True;
end;

class function TPPGTreeNodeOps.Outdent(Node: TPPGTreeNode): Boolean;
var
  Parent, After: TPPGTreeNode;
begin
  Result := False;
  if (Node = nil) or (Node.Parent = nil) then
    Exit;
  Parent := Node.Parent;
  After := Parent.GetNextSibling;
  if After <> nil then
    Node.MoveTo(After, naInsert)
  else
    Node.MoveTo(Parent, naAdd);
  Result := True;
end;

class function TPPGTreeNodeOps.Move(Node: TPPGTreeNode; Delta: Integer): Boolean;
var
  Sib, After: TPPGTreeNode;
begin
  Result := False;
  if Node = nil then
    Exit;
  if Delta < 0 then
  begin
    Sib := Node.GetPrevSibling;
    if Sib = nil then
      Exit;
    Node.MoveTo(Sib, naInsert);
    Result := True;
  end
  else if Delta > 0 then
  begin
    Sib := Node.GetNextSibling;
    if Sib = nil then
      Exit;
    After := Sib.GetNextSibling;
    if After <> nil then
      Node.MoveTo(After, naInsert)
    else
      Node.MoveTo(Sib, naAdd);
    Result := True;
  end;
end;

{ TPPGAppearanceSession }

constructor TPPGAppearanceSession.Create(ATarget: TPPGCustomControl);
begin
  inherited Create;
  if ATarget = nil then
    raise EPPGError.CreateResFmt(@SPPGNoTarget, [ClassName]);
  FTarget := ATarget;
  FWork := TPPGAppearance.Create(nil);
  FWork.Assign(TCtrlAccess(ATarget).Appearance);
end;

destructor TPPGAppearanceSession.Destroy;
begin
  FreeAndNil(FWork);
  inherited Destroy;
end;

procedure TPPGAppearanceSession.ResetToPreset;
begin
  if FTarget.Renderer <> nil then
    FTarget.Renderer.ApplyDefaults(FWork);
end;

function TPPGAppearanceSession.Modified: Boolean;
begin
  Result := not FWork.Equals(TCtrlAccess(FTarget).Appearance);
end;

procedure TPPGAppearanceSession.Apply;
begin
  TCtrlAccess(FTarget).Appearance.Assign(FWork);
end;

end.
