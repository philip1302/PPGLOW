unit PPG.VclStyles;

{ Uebernahme der Farben eines aktiven VCL-Styles (z.B. "Windows10 Dark").

  Formen (Rundung, Rahmenbreite, Glow-Groesse, Glow-Intensitaet) bleiben
  vom Preset; nur Farben kommen aus dem Style. Damit sehen PPGlow-Controls
  in gestylten Anwendungen aus "wie aus einem Guss", behalten aber ihre
  Glow-Optik.

  Hinweis: Diese Unit liest nur StyleServices - sie aendert keinen globalen
  Zustand und ist daher gefahrlos aus Paint-Pfaden nutzbar (keine
  Fensternachrichten). }

{$I ..\PPG.inc}

interface

uses
  Vcl.Graphics, PPG.Appearance;

/// True, wenn ein benutzerdefinierter (nicht-System-)VCL-Style aktiv ist.
function PPGVclStyleActive: Boolean;

/// Ueberschreibt die Farben in Target mit den Farben des aktiven VCL-Styles.
/// Target sollte vorher eine Kopie der Preset-Appearance sein (Formen bleiben).
procedure PPGApplyVclStyleColors(Target: TPPGAppearance);

/// Textfarbe fuer Beschriftungen neben Indikatoren (CheckBox/RadioButton).
function PPGVclStyleCheckTextColor(Enabled: Boolean): TColor;

/// Farben fuer Container (Panel, GroupBox) im aktiven VCL-Style.
procedure PPGVclStyleContainerColors(GroupBox, Enabled: Boolean;
  out Fill, Border, Text: TColor);

/// Farben fuer Eingabefelder (Edit, Memo, SpinEdit, ComboBox) im aktiven VCL-Style.
procedure PPGVclStyleEditColors(Enabled: Boolean; out Fill, Text: TColor);

/// Farben fuer Aufklapplisten im aktiven VCL-Style (Liste und Markierung).
procedure PPGVclStyleListColors(out Fill, Text, SelFill, SelText: TColor);

implementation

uses
  Vcl.Themes, PPG.Types;

function PPGVclStyleActive: Boolean;
begin
  Result := TStyleManager.IsCustomStyleActive;
end;

function StyleColor(C: TStyleColor; Fallback: TColor): TColor;
begin
  Result := StyleServices.GetStyleColor(C);
  if (Result = clNone) or (Result = clDefault) then
    Result := StyleServices.GetSystemColor(Fallback);
  Result := PPGColorToRGB(Result);
end;

function FontColor(F: TStyleFont; Fallback: TColor): TColor;
begin
  Result := StyleServices.GetStyleFontColor(F);
  if (Result = clNone) or (Result = clDefault) then
    Result := StyleServices.GetSystemColor(Fallback);
  Result := PPGColorToRGB(Result);
end;

procedure ApplyState(S: TPPGStateStyle; Base, Border, Glow, Text: TColor; Glossy: Boolean);
begin
  if Glossy then
    // Glanz-Optik des Classic-Presets in den Style-Farben nachbilden
    S.SetAll(PPGLighten(Base, 0.12), Base, PPGDarken(Base, 0.06), Base,
      Border, Glow, Text, S.GlowAlpha)
  else
    S.SetAll(Base, Base, Base, Base, Border, Glow, Text, S.GlowAlpha);
end;

procedure PPGApplyVclStyleColors(Target: TPPGAppearance);
var
  Glossy: Boolean;
  Accent, AccentText, Border, Normal: TColor;
begin
  if (Target = nil) or not PPGVclStyleActive then
    Exit;
  // Preset mit Verlauf (Classic) bleibt glaenzend, flache Presets bleiben flach
  Glossy := Target.Normal.Color <> Target.Normal.ColorTo;
  Accent := PPGColorToRGB(StyleServices.GetSystemColor(clHighlight));
  AccentText := PPGColorToRGB(StyleServices.GetSystemColor(clHighlightText));
  Border := StyleColor(scBorder, clBtnShadow);
  Normal := StyleColor(scButtonNormal, clBtnFace);

  Target.BeginUpdate;
  try
    ApplyState(Target.Normal, Normal, Border, Accent,
      FontColor(sfButtonTextNormal, clBtnText), Glossy);
    ApplyState(Target.Hot, StyleColor(scButtonHot, clBtnFace), Accent, Accent,
      FontColor(sfButtonTextHot, clBtnText), Glossy);
    ApplyState(Target.Down, StyleColor(scButtonPressed, clBtnFace), Accent, Accent,
      FontColor(sfButtonTextPressed, clBtnText), Glossy);
    ApplyState(Target.Disabled, StyleColor(scButtonDisabled, clBtnFace), Border, Border,
      FontColor(sfButtonTextDisabled, clGrayText), Glossy);
    // "An"-Zustand der Auswahl-Controls: Markierungsfarbe des Styles
    Target.Checked.SetAll(Accent, Accent, Accent, Accent, Accent, Accent, AccentText,
      Target.Checked.GlowAlpha);
    Target.FocusColor := Accent;
  finally
    Target.EndUpdate;
  end;
end;

function PPGVclStyleCheckTextColor(Enabled: Boolean): TColor;
begin
  if Enabled then
    Result := FontColor(sfCheckBoxTextNormal, clWindowText)
  else
    Result := FontColor(sfCheckBoxTextDisabled, clGrayText);
end;

procedure PPGVclStyleContainerColors(GroupBox, Enabled: Boolean;
  out Fill, Border, Text: TColor);
begin
  if Enabled then
    Fill := StyleColor(scPanel, clBtnFace)
  else
    Fill := StyleColor(scPanelDisabled, clBtnFace);
  Border := StyleColor(scBorder, clBtnShadow);
  if GroupBox then
  begin
    if Enabled then
      Text := FontColor(sfGroupBoxTextNormal, clWindowText)
    else
      Text := FontColor(sfGroupBoxTextDisabled, clGrayText);
  end
  else if Enabled then
    Text := FontColor(sfPanelTextNormal, clWindowText)
  else
    Text := FontColor(sfPanelTextDisabled, clGrayText);
end;

procedure PPGVclStyleEditColors(Enabled: Boolean; out Fill, Text: TColor);
begin
  if Enabled then
  begin
    Fill := StyleColor(scEdit, clWindow);
    Text := FontColor(sfEditBoxTextNormal, clWindowText);
  end
  else
  begin
    Fill := StyleColor(scEditDisabled, clBtnFace);
    Text := FontColor(sfEditBoxTextDisabled, clGrayText);
  end;
end;

procedure PPGVclStyleListColors(out Fill, Text, SelFill, SelText: TColor);
begin
  Fill := StyleColor(scListBox, clWindow);
  Text := FontColor(sfListItemTextNormal, clWindowText);
  SelFill := PPGColorToRGB(StyleServices.GetSystemColor(clHighlight));
  SelText := FontColor(sfListItemTextSelected, clHighlightText);
end;

end.
