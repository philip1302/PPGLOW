<#
  PPGlow Palettensymbole (Phase 9a)

  Erzeugt die Palettensymbole aller PPGlow-Komponenten als .dcr (Windows-
  Ressourcendatei mit Bitmaps) - ohne brcc32, ohne Grafikprogramm und ohne
  Symbolschrift. Jedes Symbol ist unten als kleine Vektorbeschreibung auf
  einem 32x32-Raster definiert und wird mit 4x4-Kantenglaettung gerastert.

  Aufruf:  powershell -ExecutionPolicy Bypass -File Build\make-icons.ps1 [-Preview <png>]

  Ausgabe:
  - Source\Design\PPGlow.dcr      (Grund-Controls, gelinkt von PPG.Reg)
  - Source\DesignDB\PPGlowDB.dcr  (DB-Controls, gelinkt von PPG.DB.Reg)
  - optional eine Vorschau aller Symbole als PNG (-Preview)

  Ressourcennamen wie von der IDE erwartet: TPPGBUTTON (24 px),
  TPPGBUTTON16 und TPPGBUTTON32. Format: 24-Bit-Bitmap; die Farbe des Pixels
  unten links ist transparent (Konvention der IDE von XE2 bis 13), deshalb
  bleibt dieser Pixel in jedem Symbol frei.

  Formen (Koordinaten im 32er-Raster, Farben siehe $Palette):
    rect x y w h radius fill [stroke [breite]]   - Rechteck, '-' = keine Farbe
    circle cx cy r fill [stroke [breite]]
    line x1 y1 x2 y2 breite farbe                - mit runden Enden
    poly farbe x1 y1 x2 y2 ...                    - gefuelltes Vieleck
    path breite farbe x1 y1 x2 y2 ...             - Linienzug
    db                                            - DB-Plakette unten rechts
#>
param(
  [string]$Preview = ''
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot

$Palette = @{
  'A' = 0x0F6CBD  # Akzent
  'L' = 0xCFE4FA  # Akzent hell
  'S' = 0x616161  # Rand
  'W' = 0xFFFFFF  # Flaeche
  'G' = 0xB0B0B0  # grau (Text-Platzhalter)
  'H' = 0xE6E6E6  # hellgrau (Flaeche)
  'D' = 0x242424  # Text dunkel
  'R' = 0xC42B1C  # Fehler/Signal
  'Y' = 0xF2B200  # Stern/Warnung
  'N' = 0x0F7B0F  # Erfolg
}

# Gemeinsame Bausteine
$Field = @('rect 2 9 28 14 3 W S 1.5')
$Lines3 = @('line 8 12 24 12 2 G', 'line 8 17 21 17 2 G', 'line 8 22 23 22 2 G')

$Icons = [ordered]@{
  'TPPGButton'      = @('rect 2 8 28 16 4 A', 'line 9 16 23 16 2.5 W')
  'TPPGCheckBox'    = @('rect 5 5 22 22 4 A', 'path 3 W 10 16 14.5 20.5 22 12')
  'TPPGRadioButton' = @('circle 16 16 11 W S 1.5', 'circle 16 16 6 A')
  'TPPGToggleSwitch'= @('rect 2 9 28 14 7 A', 'circle 23 16 4.5 W')
  'TPPGProgressBar' = @('rect 2 12 28 8 4 H', 'rect 2 12 18 8 4 A')
  'TPPGTrackBar'    = @('rect 3 14.5 26 3 1.5 H', 'rect 3 14.5 13 3 1.5 A', 'circle 16 16 6 W S 1.5', 'circle 16 16 3 A')
  'TPPGPanel'       = @('rect 3 5 26 22 4 H S 1.5')
  'TPPGGroupBox'    = @('rect 3 8 26 20 3 - S 1.5', 'rect 6 4 14 8 4 A')
  'TPPGRadioGroup'  = @('rect 3 4 26 24 3 - S 1.5', 'circle 9 11 3.5 W S 1.2', 'circle 9 11 1.8 A', 'line 15 11 25 11 2 G', 'circle 9 21 3.5 W S 1.2', 'line 15 21 23 21 2 G')
  'TPPGCheckGroup'  = @('rect 3 4 26 24 3 - S 1.5', 'rect 6 8 6 6 1.5 A', 'path 1.5 W 7.5 11 9 12.5 11 9.5', 'line 15 11 25 11 2 G', 'rect 6 18 6 6 1.5 W S 1', 'line 15 21 23 21 2 G')
  'TPPGEdit'        = $Field + @('line 8 13 8 19 1.5 D', 'line 11 16 20 16 2 G', 'line 3 22.5 29 22.5 2 A')
  'TPPGMemo'        = @('rect 3 4 26 24 3 W S 1.5') + $Lines3 + @('line 4 27 28 27 2 A')
  'TPPGSpinEdit'    = $Field + @('line 7 16 15 16 2 G', 'line 22 9 22 23 1.5 S', 'path 1.8 D 23.5 14 25.5 12 27.5 14', 'path 1.8 D 23.5 18 25.5 20 27.5 18')
  'TPPGComboBox'    = $Field + @('line 7 16 17 16 2 G', 'path 2 D 21 14 24 17 27 14')
  'TPPGTabControl'  = @('rect 3 11 26 17 3 W S 1.5', 'rect 4 5 10 8 2 A', 'rect 15 6 9 6 2 H', 'line 5 12 13 12 2 A')
  'TPPGPageControl' = @('rect 3 11 26 17 3 W S 1.5', 'rect 4 5 10 8 2 A', 'rect 15 6 9 6 2 H') + @('line 8 17 22 17 2 G', 'line 8 22 18 22 2 G')
  'TPPGListBox'     = @('rect 3 4 26 24 3 W S 1.5', 'rect 6 13 20 6 2 L', 'line 6 13.5 6 18.5 2 A', 'line 9 9 22 9 2 G', 'line 9 16 22 16 2 D', 'line 9 23 20 23 2 G')
  'TPPGCheckListBox'= @('rect 3 4 26 24 3 W S 1.5', 'rect 6 7 6 6 1.5 A', 'path 1.5 W 7.5 10 9 11.5 11 8.5', 'line 15 10 25 10 2 G', 'rect 6 18 6 6 1.5 W S 1', 'line 15 21 24 21 2 G')
  'TPPGTreeView'    = @('path 1.5 G 8 9 8 23 13 23', 'line 8 16 13 16 1.5 G', 'rect 4 5 8 6 1.5 A', 'rect 13 13 14 6 1.5 L', 'rect 13 20 12 6 1.5 H')
  'TPPGGrid'        = @('rect 3 5 26 22 2 W S 1.5', 'rect 3 5 26 6 2 A', 'line 3.5 16 28.5 16 1 S', 'line 3.5 21.5 28.5 21.5 1 S', 'line 12 5.5 12 26.5 1 S', 'line 20.5 5.5 20.5 26.5 1 S')
  'TPPGGridPrinter' = @('rect 8 3 16 8 1.5 W S 1.5', 'rect 3 11 26 12 2 A', 'rect 8 19 16 10 1.5 W S 1.5', 'line 11 23 21 23 1.5 G', 'line 11 26 18 26 1.5 G', 'circle 25 15 1.2 W')
  'TPPGLabel'       = @('path 2.5 D 7 25 13 7 19 25', 'line 9.5 19 16.5 19 2.5 D', 'line 21 25 27 25 2 A')
  'TPPGLinkLabel'   = @('line 4 16 28 16 2.5 A', 'line 4 21 28 21 1.5 A', 'path 2.5 A 7 12 7 9 25 9 25 12')
  'TPPGBadge'       = @('rect 3 10 18 14 3 H S 1', 'circle 23 10 7 R', 'line 23 7 23 13 2 W')
  'TPPGProgressRing'= @('circle 16 16 11 - H 3.5', 'path 3.5 A 16 5 22.5 7 26 12 27 16')
  'TPPGInfoBar'     = @('rect 2 7 28 18 3 L A 1.5', 'circle 9 16 4.5 A', 'line 9 14.5 9 18 1.5 W', 'line 16 13 26 13 2 G', 'line 16 19 23 19 2 G')
  'TPPGExpander'    = @('rect 3 4 26 9 3 A', 'path 2 W 21 7 24 10 27 7', 'rect 3 15 26 13 3 H S 1', 'line 7 21.5 19 21.5 2 G')
  'TPPGSplitter'    = @('rect 3 5 11 22 2 H S 1', 'rect 18 5 11 22 2 H S 1', 'line 16 9 16 23 2 A', 'path 1.5 A 12 16 10 16', 'path 1.5 A 20 16 22 16')
  'TPPGRating'      = @('poly Y 16 3 19.5 11.5 28.5 12 21.5 18 24 27 16 22 8 27 10.5 18 3.5 12 12.5 11.5')
  'TPPGSearchEdit'  = $Field + @('circle 10 15 4 - S 1.8', 'line 13 18 15.5 20.5 2 S', 'line 18 16 26 16 2 G')
  'TPPGCalendar'    = @('rect 3 5 26 23 3 W S 1.5', 'rect 3 5 26 7 3 A', 'line 8 3 8 8 2 S', 'line 24 3 24 8 2 S', 'rect 7 15 4 3 0.5 G', 'rect 14 15 4 3 0.5 G', 'rect 21 15 4 3 0.5 A', 'rect 7 21 4 3 0.5 G', 'rect 14 21 4 3 0.5 G')
  'TPPGDatePicker'  = $Field + @('line 7 16 15 16 2 G', 'rect 19 11 9 9 1.5 W S 1.2', 'rect 19 11 9 3 1 A')
  'TPPGTimePicker'  = $Field + @('line 7 16 13 16 2 G', 'circle 22.5 16 5 W S 1.5', 'path 1.5 A 22.5 13 22.5 16 24.5 17')
  'TPPGNavigationView' = @('rect 3 4 11 24 2 H', 'line 6 9 11 9 2 A', 'line 6 15 11 15 2 G', 'line 6 21 11 21 2 G', 'line 4 13 4 17 2 A', 'rect 16 4 13 24 2 W S 1')
  'TPPGBreadcrumb'  = @('line 3 16 8 16 2.5 G', 'path 2 S 10 12 13 16 10 20', 'line 15 16 19 16 2.5 G', 'path 2 S 21 12 24 16 21 20', 'line 26 16 29 16 2.5 A')
  'TPPGToolBar'     = @('rect 2 8 28 16 3 H', 'rect 5 11 6 10 2 A', 'rect 13 11 6 10 2 W S 1', 'line 22 16 22 16 2.5 S', 'line 25 16 25 16 2.5 S', 'line 28 16 28 16 2.5 S')
  'TPPGStatusBar'   = @('rect 3 5 26 22 3 W S 1', 'rect 3 21 26 6 2 A', 'line 6 24 13 24 1.5 W', 'line 17 24 22 24 1.5 W')
  'TPPGNotificationCenter' = @('rect 4 6 24 14 3 W S 1.5', 'line 8 11 22 11 2 D', 'line 8 15 18 15 2 G', 'rect 8 22 20 6 2 A')
  'TPPGSparkline'   = @('path 2.5 A 3 22 8 15 13 19 19 9 24 14 28 8', 'circle 28 8 3 W A 1.5')
  'TPPGGauge'       = @('path 4 H 8.2 25.8 5.8 22.2 5.0 18.0 5.8 13.8 8.2 10.2 11.8 7.8 16.0 7.0 20.2 7.8 23.8 10.2 26.2 13.8 27.0 18.0 26.2 22.2 23.8 25.8', 'path 4 A 8.2 25.8 6.3 23.2 5.2 20.3 5.0 17.1 5.7 14.1 7.3 11.3 9.5 9.1 12.3 7.6 15.4 7.0 18.6 7.3 21.5 8.5', 'line 13 20 19 20 2.5 D')
  'TPPGKpiTile'     = @('rect 2 4 28 24 3 W S 1.5', 'line 6 9.5 14 9.5 2 G', 'line 6 15.5 17 15.5 3.5 D', 'poly N 21 18 27 18 24 13', 'path 2 A 6 24 11 21 15 23 20 20 26 22')
  'TPPGChart'       = @('line 3 27.5 29 27.5 1.5 S', 'rect 5 16 5 11 1 L', 'rect 13 10 5 17 1 L', 'rect 21 19 5 8 1 L', 'path 2.5 A 4 17 11 9 18 14 28 5')
  'TPPGPlanner'     = @('rect 3 4 26 25 3 W S 1.5', 'rect 3 4 26 6 3 A', 'line 11 10 11 28 1 G', 'line 19 10 19 28 1 G', 'line 4 16 28 16 1 G', 'line 4 22 28 22 1 G', 'rect 12 12 6 9 1.5 L A 1', 'rect 20 18 7 9 1.5 A')
  'TPPGRibbon'      = @('rect 2 5 28 22 3 W S 1.5', 'rect 4 7 7 4 1 A', 'line 14 9 18 9 2 G', 'line 21 9 25 9 2 G', 'line 3 12.5 29 12.5 1 S', 'rect 5 15 7 9 1.5 L A 1', 'line 15 16 21 16 2 G', 'line 15 19.5 22 19.5 2 G', 'line 15 23 20 23 2 G', 'line 25 15 25 24 1 G')
  'TPPGKanban'      = @('rect 2 4 8 24 2 H', 'rect 12 4 8 24 2 H', 'rect 22 4 8 24 2 H', 'rect 3 6 6 5 1 W S 1', 'rect 3 12 6 5 1 W S 1', 'rect 13 6 6 5 1 A', 'rect 13 12 6 5 1 W S 1', 'rect 13 18 6 5 1 W S 1', 'rect 23 6 6 5 1 W S 1')
  'TPPGPlannerPrinter' = @('rect 8 3 16 8 1.5 W S 1.5', 'rect 3 11 26 12 2 A', 'rect 8 19 16 10 1.5 W S 1.5', 'rect 10 21 5 3 0.5 L', 'rect 17 21 5 6 0.5 A', 'circle 25 15 1.2 W')
  'TPPGKanbanPrinter' = @('rect 8 3 16 8 1.5 W S 1.5', 'rect 3 11 26 12 2 A', 'rect 8 19 16 10 1.5 W S 1.5', 'rect 10 21 3 6 0.5 L', 'rect 14.5 21 3 4 0.5 A', 'rect 19 21 3 7 0.5 L', 'circle 25 15 1.2 W')
  'TPPGPopupMenu'   = @('rect 6 3 22 26 3 W S 1.5', 'rect 8 11 18 6 1.5 L', 'line 11 7.5 22 7.5 2 G', 'line 11 14 22 14 2 A', 'line 11 20.5 20 20.5 2 G', 'line 11 25 18 25 2 G', 'path 2.5 D 2 2 2 10 5 7.5')
  'TPPGMenuBar'     = @('rect 2 4 28 7 2 H', 'line 5 7.5 9 7.5 2 D', 'line 13 7.5 17 7.5 2 A', 'line 21 7.5 25 7.5 2 D', 'rect 11 12 15 16 2 W S 1.5', 'line 14 17 23 17 2 G', 'line 14 23 21 23 2 G')
  'TPPGHintManager' = @('rect 3 4 26 16 3 W S 1.5', 'poly S 9 19.5 9 26 15 19.5', 'line 8 9.5 18 9.5 2 D', 'line 8 14.5 23 14.5 2 G', 'circle 26 25 4.5 A', 'line 26 23 26 27 1.5 W')
  'TPPGCustomHint'  = @('rect 3 4 26 16 3 Y S 1.5', 'poly S 9 19.5 9 26 15 19.5', 'line 8 9.5 18 9.5 2 D', 'line 8 14.5 23 14.5 2 D')
  'TPPGTeachingTip' = @('rect 3 10 26 18 3 W A 1.5', 'poly A 12 10.5 16 4 20 10.5', 'circle 9 17 3 A', 'line 14 16 25 16 2 D', 'rect 15 21 11 4 1.5 A')
  'TPPGTaskDialog'  = @('rect 2 3 28 26 3 W S 1.5', 'rect 2 3 28 6 3 H', 'poly Y 9 12 14 21 4 21', 'line 9 15 9 18 1.5 D', 'line 17 14 26 14 2 D', 'line 17 18 24 18 2 G', 'rect 18 23 9 4 1.5 A')
  'TPPGWizard'      = @('circle 6 7 3.5 A', 'line 10 7 13 7 1.5 A', 'circle 16 7 3.5 A', 'line 20 7 23 7 1.5 S', 'circle 26 7 3.5 W S 1.2', 'rect 3 13 26 15 2 W S 1.5', 'rect 18 22 9 4 1.5 A', 'line 7 18 19 18 2 G')
  'TPPGNumberEdit'  = $Field + @('line 13 12.5 13 19.5 2 D', 'path 2 D 17 13 19.5 12.5 19.5 19.5', 'line 17 19.5 22 19.5 2 D', 'line 6 16 9 16 2 A', 'line 7.5 14.5 7.5 17.5 2 A')
  'TPPGMaskEdit'    = $Field + @('line 7 19 10 19 2 D', 'line 12 19 15 19 2 G', 'line 17 19 20 19 2 G', 'line 22 19 25 19 2 G', 'line 7 13 10 13 2 D')
  'TPPGPasswordEdit'= $Field + @('circle 8 16 1.8 D', 'circle 13 16 1.8 D', 'circle 18 16 1.8 D', 'circle 24.5 16 3 - A 1.5', 'circle 24.5 16 1 A')
  'TPPGFileEdit'    = $Field + @('poly A 5 12 10 12 11.5 13.5 18 13.5 18 20 5 20', 'circle 22 16 1.2 D', 'circle 25 16 1.2 D', 'circle 28 16 1.2 D')
  'TPPGColorPicker' = $Field + @('rect 5 12 8 8 1.5 R', 'rect 14 12 8 8 1.5 A', 'path 2 D 23 14 25.5 17 28 14')
  'TPPGCheckComboBox' = $Field + @('rect 5 12 7 7 1.5 A', 'path 1.5 W 6.5 15.5 8 17 10.5 14', 'line 14 15.5 19 15.5 2 G', 'path 2 D 22 14 24.5 17 27 14')
  'TPPGColumnComboBox' = @('rect 2 3 28 9 3 W S 1.5', 'path 1.8 D 22 6.5 24.5 9 27 6.5', 'rect 2 13 28 16 2 W S 1', 'rect 2 13 28 5 2 H', 'line 11 13.5 11 28.5 1 S', 'line 5 22 9 22 1.5 G', 'line 13 22 26 22 1.5 G', 'line 5 26 9 26 1.5 G', 'line 13 26 23 26 1.5 G')
  'TPPGTagEdit'     = $Field + @('rect 4 12 9 8 3 L A 1', 'rect 15 12 9 8 3 L A 1', 'line 26 13 26 19 1.5 D')
  'TPPGStyleManager'= @('circle 16 16 12 W S 1.5', 'circle 11 12 3 A', 'circle 19 10 3 R', 'circle 22 17 3 Y', 'circle 12 20 3 N')
}

$DbIcons = [ordered]@{
  'TPPGDBEdit'           = $Icons['TPPGEdit'] + @('db')
  'TPPGDBMemo'           = $Icons['TPPGMemo'] + @('db')
  'TPPGDBCheckBox'       = $Icons['TPPGCheckBox'] + @('db')
  'TPPGDBComboBox'       = $Icons['TPPGComboBox'] + @('db')
  'TPPGDBLookupComboBox' = $Field + @('line 7 16 12 16 2 G', 'path 1.6 A 14 13 16 16 14 19', 'path 2 D 21 14 24 17 27 14', 'db')
  'TPPGDBDatePicker'     = $Icons['TPPGDatePicker'] + @('db')
  'TPPGDBGrid'           = $Icons['TPPGGrid'] + @('db')
  'TPPGDBChart'          = $Icons['TPPGChart'] + @('db')
  'TPPGDBPlanner'        = $Icons['TPPGPlanner'] + @('db')
  'TPPGDBKanban'         = $Icons['TPPGKanban'] + @('db')
  'TPPGDBMaskEdit'       = $Icons['TPPGMaskEdit'] + @('db')
  'TPPGDBNumberEdit'     = $Icons['TPPGNumberEdit'] + @('db')
  'TPPGDBColorPicker'    = $Icons['TPPGColorPicker'] + @('db')
  'TPPGDBCheckComboBox'  = $Icons['TPPGCheckComboBox'] + @('db')
  'TPPGDBTagEdit'        = $Icons['TPPGTagEdit'] + @('db')
}

$Source = @'
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;

public static class PPGIconMaker
{
    const int SS = 4; // Unterabtastung je Achse

    abstract class Shape
    {
        public int Color = -1;
        public abstract bool Contains(double x, double y);
    }

    class RRect : Shape
    {
        double X, Y, W, H, R;
        public RRect(double x, double y, double w, double h, double r) { X = x; Y = y; W = w; H = h; R = Math.Max(0, Math.Min(r, Math.Min(w, h) / 2)); }
        public override bool Contains(double px, double py)
        {
            if (px < X || py < Y || px > X + W || py > Y + H) return false;
            double cx = Math.Max(X + R, Math.Min(px, X + W - R));
            double cy = Math.Max(Y + R, Math.Min(py, Y + H - R));
            double dx = px - cx, dy = py - cy;
            return dx * dx + dy * dy <= R * R + 1e-9;
        }
    }

    class Ring : Shape
    {
        Shape Outer, Inner;
        public Ring(Shape outer, Shape inner) { Outer = outer; Inner = inner; }
        public override bool Contains(double x, double y) { return Outer.Contains(x, y) && (Inner == null || !Inner.Contains(x, y)); }
    }

    class Circle : Shape
    {
        double CX, CY, R;
        public Circle(double cx, double cy, double r) { CX = cx; CY = cy; R = r; }
        public override bool Contains(double x, double y) { double dx = x - CX, dy = y - CY; return dx * dx + dy * dy <= R * R; }
    }

    class Polyline : Shape
    {
        double[] P; double HalfW;
        public Polyline(double[] p, double w) { P = p; HalfW = w / 2; }
        public override bool Contains(double x, double y)
        {
            if (P.Length == 2) return Dist(x, y, P[0], P[1], P[0], P[1]) <= HalfW;
            for (int i = 0; i + 3 < P.Length; i += 2)
                if (Dist(x, y, P[i], P[i + 1], P[i + 2], P[i + 3]) <= HalfW) return true;
            return false;
        }
        static double Dist(double x, double y, double ax, double ay, double bx, double by)
        {
            double vx = bx - ax, vy = by - ay;
            double len = vx * vx + vy * vy;
            double t = len == 0 ? 0 : Math.Max(0, Math.Min(1, ((x - ax) * vx + (y - ay) * vy) / len));
            double dx = x - (ax + t * vx), dy = y - (ay + t * vy);
            return Math.Sqrt(dx * dx + dy * dy);
        }
    }

    class Polygon : Shape
    {
        double[] P;
        public Polygon(double[] p) { P = p; }
        public override bool Contains(double x, double y)
        {
            bool inside = false;
            int n = P.Length / 2;
            for (int i = 0, j = n - 1; i < n; j = i++)
            {
                double xi = P[2 * i], yi = P[2 * i + 1], xj = P[2 * j], yj = P[2 * j + 1];
                if (((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) inside = !inside;
            }
            return inside;
        }
    }

    static double D(string s) { return double.Parse(s, CultureInfo.InvariantCulture); }

    static int Col(string s, Dictionary<string, int> pal)
    {
        if (s == "-") return -1;
        int c;
        if (!pal.TryGetValue(s, out c)) throw new ArgumentException("Unbekannte Farbe: " + s);
        return c;
    }

    static void AddFilledAndStroke(List<Shape> list, Func<double, Shape> make, string fill, string[] t, int strokeIdx, Dictionary<string, int> pal)
    {
        int f = Col(fill, pal);
        if (f >= 0) { Shape s = make(0); s.Color = f; list.Add(s); }
        if (t.Length > strokeIdx)
        {
            int sc = Col(t[strokeIdx], pal);
            double w = t.Length > strokeIdx + 1 ? D(t[strokeIdx + 1]) : 1;
            if (sc >= 0) { Shape r = new Ring(make(0), make(w)); r.Color = sc; list.Add(r); }
        }
    }

    static List<Shape> Parse(string[] defs, Dictionary<string, int> pal)
    {
        List<Shape> list = new List<Shape>();
        foreach (string def in defs)
        {
            string[] t = def.Split(new char[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            switch (t[0])
            {
                case "rect":
                {
                    double x = D(t[1]), y = D(t[2]), w = D(t[3]), h = D(t[4]), r = D(t[5]);
                    AddFilledAndStroke(list, delegate (double inset)
                    {
                        if (inset <= 0) return new RRect(x, y, w, h, r);
                        return new RRect(x + inset, y + inset, w - 2 * inset, h - 2 * inset, Math.Max(0, r - inset));
                    }, t[6], t, 7, pal);
                    break;
                }
                case "circle":
                {
                    double cx = D(t[1]), cy = D(t[2]), r = D(t[3]);
                    AddFilledAndStroke(list, delegate (double inset) { return new Circle(cx, cy, r - inset); }, t[4], t, 5, pal);
                    break;
                }
                case "line":
                {
                    Shape s = new Polyline(new double[] { D(t[1]), D(t[2]), D(t[3]), D(t[4]) }, D(t[5]));
                    s.Color = Col(t[6], pal);
                    if (D(t[5]) > 0) list.Add(s);
                    break;
                }
                case "path":
                {
                    double[] p = new double[t.Length - 3];
                    for (int i = 3; i < t.Length; i++) p[i - 3] = D(t[i]);
                    Shape s = new Polyline(p, D(t[1]));
                    s.Color = Col(t[2], pal);
                    list.Add(s);
                    break;
                }
                case "poly":
                {
                    double[] p = new double[t.Length - 2];
                    for (int i = 2; i < t.Length; i++) p[i - 2] = D(t[i]);
                    Shape s = new Polygon(p);
                    s.Color = Col(t[1], pal);
                    list.Add(s);
                    break;
                }
                case "db":
                {
                    // Datenbank-Zylinder unten rechts mit weissem Rand (Freistellung)
                    Shape halo = new RRect(17, 15, 15, 17, 4); halo.Color = 0xFFFFFF; list.Add(halo);
                    Shape body = new RRect(19, 18, 11, 12, 3); body.Color = pal["N"]; list.Add(body);
                    Shape top = new RRect(19, 17, 11, 5, 2.5); top.Color = 0x6CCB6C; list.Add(top);
                    Shape band = new Polyline(new double[] { 20, 25, 29, 25 }, 1); band.Color = 0x0A5A0A; list.Add(band);
                    break;
                }
                default:
                    throw new ArgumentException("Unbekannte Form: " + t[0]);
            }
        }
        return list;
    }

    /// RGB-Pixel (Zeile fuer Zeile von oben) - Transparenz als Key-Farbe.
    public static int[] Render(string[] defs, Dictionary<string, int> pal, int size, int key, int edge)
    {
        List<Shape> shapes = Parse(defs, pal);
        int[] px = new int[size * size];
        double scale = 32.0 / size;
        for (int py = 0; py < size; py++)
            for (int pxl = 0; pxl < size; pxl++)
            {
                int r = 0, g = 0, b = 0, hit = 0;
                for (int sy = 0; sy < SS; sy++)
                    for (int sx = 0; sx < SS; sx++)
                    {
                        double x = (pxl + (sx + 0.5) / SS) * scale;
                        double y = (py + (sy + 0.5) / SS) * scale;
                        int c = -1;
                        for (int i = shapes.Count - 1; i >= 0; i--)
                            if (shapes[i].Contains(x, y)) { c = shapes[i].Color; break; }
                        if (c >= 0) { r += (c >> 16) & 255; g += (c >> 8) & 255; b += c & 255; hit++; }
                    }
                int idx = py * size + pxl;
                if (hit == 0) { px[idx] = key; continue; }
                int n = SS * SS, miss = n - hit;
                r += miss * ((edge >> 16) & 255); g += miss * ((edge >> 8) & 255); b += miss * (edge & 255);
                int v = ((r / n) << 16) | ((g / n) << 8) | (b / n);
                if (v == key) v ^= 1; // Key-Farbe nie versehentlich treffen
                px[idx] = v;
            }
        // Pixel unten links ist per Konvention transparent
        px[(size - 1) * size] = key;
        return px;
    }

    /// DIB (BITMAPINFOHEADER + 24-Bit-Pixel, von unten nach oben).
    public static byte[] Dib(int[] px, int size)
    {
        int stride = (size * 3 + 3) & ~3;
        MemoryStream ms = new MemoryStream();
        BinaryWriter w = new BinaryWriter(ms);
        w.Write(40); w.Write(size); w.Write(size); w.Write((short)1); w.Write((short)24);
        w.Write(0); w.Write(stride * size); w.Write(2835); w.Write(2835); w.Write(0); w.Write(0);
        for (int y = size - 1; y >= 0; y--)
        {
            for (int x = 0; x < size; x++)
            {
                int c = px[y * size + x];
                w.Write((byte)(c & 255)); w.Write((byte)((c >> 8) & 255)); w.Write((byte)((c >> 16) & 255));
            }
            for (int p = size * 3; p < stride; p++) w.Write((byte)0);
        }
        w.Flush();
        return ms.ToArray();
    }

    static void Align4(BinaryWriter w) { while (w.BaseStream.Position % 4 != 0) w.Write((byte)0); }

    /// Schreibt eine 32-Bit-.res/.dcr mit Bitmaps (RT_BITMAP) unter den angegebenen Namen.
    public static void WriteRes(string file, string[] names, byte[][] data)
    {
        MemoryStream ms = new MemoryStream();
        BinaryWriter w = new BinaryWriter(ms);
        // Leerer Eintrag am Anfang kennzeichnet eine 32-Bit-Ressourcendatei
        w.Write(0); w.Write(32); w.Write((short)-1); w.Write((short)0); w.Write((short)-1); w.Write((short)0);
        w.Write(0); w.Write((short)0); w.Write((short)0); w.Write(0); w.Write(0);
        for (int i = 0; i < names.Length; i++)
        {
            byte[] name = Encoding.Unicode.GetBytes(names[i].ToUpperInvariant() + "\0");
            int headerSize = 8 + 4 + name.Length;
            headerSize = (headerSize + 3) & ~3;
            headerSize += 16;
            w.Write(data[i].Length);
            w.Write(headerSize);
            w.Write((short)-1); w.Write((short)2);       // Typ RT_BITMAP
            w.Write(name); Align4(w);
            w.Write(0);                                    // DataVersion
            w.Write((short)0x1030);                        // MOVEABLE | PURE | DISCARDABLE
            w.Write((short)0x0409);                        // Sprache
            w.Write(0); w.Write(0);                        // Version, Characteristics
            w.Write(data[i]); Align4(w);
        }
        w.Flush();
        File.WriteAllBytes(file, ms.ToArray());
    }

    static uint Crc(byte[] buf, int start, int len)
    {
        uint c = 0xFFFFFFFF;
        for (int i = start; i < start + len; i++)
        {
            c ^= buf[i];
            for (int k = 0; k < 8; k++) c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
        }
        return c ^ 0xFFFFFFFF;
    }

    static void Chunk(BinaryWriter w, string type, byte[] data)
    {
        byte[] t = Encoding.ASCII.GetBytes(type);
        byte[] all = new byte[4 + data.Length];
        Array.Copy(t, all, 4); Array.Copy(data, 0, all, 4, data.Length);
        WriteBE(w, (uint)data.Length); w.Write(all); WriteBE(w, Crc(all, 0, all.Length));
    }

    static void WriteBE(BinaryWriter w, uint v) { w.Write((byte)(v >> 24)); w.Write((byte)(v >> 16)); w.Write((byte)(v >> 8)); w.Write((byte)v); }

    /// Vorschau als PNG (RGB, zlib per DeflateStream).
    public static void WritePng(string file, int[] px, int width, int height)
    {
        MemoryStream raw = new MemoryStream();
        for (int y = 0; y < height; y++)
        {
            raw.WriteByte(0);
            for (int x = 0; x < width; x++)
            {
                int c = px[y * width + x];
                raw.WriteByte((byte)((c >> 16) & 255)); raw.WriteByte((byte)((c >> 8) & 255)); raw.WriteByte((byte)(c & 255));
            }
        }
        byte[] rawBytes = raw.ToArray();
        MemoryStream z = new MemoryStream();
        z.WriteByte(0x78); z.WriteByte(0x9C);
        using (System.IO.Compression.DeflateStream d = new System.IO.Compression.DeflateStream(z, System.IO.Compression.CompressionMode.Compress, true))
            d.Write(rawBytes, 0, rawBytes.Length);
        uint a = 1, b2 = 0;
        foreach (byte v in rawBytes) { a = (a + v) % 65521; b2 = (b2 + a) % 65521; }
        uint adler = (b2 << 16) | a;
        z.WriteByte((byte)(adler >> 24)); z.WriteByte((byte)(adler >> 16)); z.WriteByte((byte)(adler >> 8)); z.WriteByte((byte)adler);

        MemoryStream ms = new MemoryStream();
        BinaryWriter w = new BinaryWriter(ms);
        w.Write(new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A });
        MemoryStream ih = new MemoryStream();
        BinaryWriter iw = new BinaryWriter(ih);
        WriteBE(iw, (uint)width); WriteBE(iw, (uint)height);
        iw.Write((byte)8); iw.Write((byte)2); iw.Write((byte)0); iw.Write((byte)0); iw.Write((byte)0);
        iw.Flush();
        Chunk(w, "IHDR", ih.ToArray());
        Chunk(w, "IDAT", z.ToArray());
        Chunk(w, "IEND", new byte[0]);
        w.Flush();
        File.WriteAllBytes(file, ms.ToArray());
    }
}
'@

if (-not ('PPGIconMaker' -as [type])) {
  Add-Type -TypeDefinition $Source -Language CSharp
}

$pal = New-Object 'System.Collections.Generic.Dictionary[string,int]'
foreach ($k in $Palette.Keys) { $pal[$k] = $Palette[$k] }
$Key = 0xFF00FF    # transparent (Pixel unten links)
$Edge = 0xF0F0F0   # Hintergrund fuer Kantenglaettung (helle Palette)
$Sizes = @(@{ Size = 24; Suffix = '' }, @{ Size = 16; Suffix = '16' }, @{ Size = 32; Suffix = '32' })

function Write-Dcr($Set, [string]$File) {
  $names = New-Object System.Collections.Generic.List[string]
  $data = New-Object System.Collections.Generic.List[byte[]]
  foreach ($cls in $Set.Keys) {
    foreach ($s in $Sizes) {
      $px = [PPGIconMaker]::Render([string[]]$Set[$cls], $pal, $s.Size, $Key, $Edge)
      $names.Add($cls + $s.Suffix)
      $data.Add([PPGIconMaker]::Dib($px, $s.Size))
    }
  }
  [PPGIconMaker]::WriteRes($File, $names.ToArray(), $data.ToArray())
  Write-Host ("{0}: {1} Symbole ({2} Bitmaps)" -f $File, $Set.Count, $names.Count)
}

Write-Dcr $Icons (Join-Path $Root 'Source\Design\PPGlow.dcr'.Replace('\', [IO.Path]::DirectorySeparatorChar))
$dbDir = Join-Path $Root ('Source\DesignDB'.Replace('\', [IO.Path]::DirectorySeparatorChar))
if (-not (Test-Path $dbDir)) { New-Item -ItemType Directory -Path $dbDir | Out-Null }
Write-Dcr $DbIcons (Join-Path $dbDir 'PPGlowDB.dcr')

if ($Preview -ne '') {
  # Vorschau: je Symbol eine Zeile mit 16, 24 und 32 px (2-fach vergroessert)
  $all = [ordered]@{}
  foreach ($k in $Icons.Keys) { $all[$k] = $Icons[$k] }
  foreach ($k in $DbIcons.Keys) { $all[$k] = $DbIcons[$k] }
  $cols = 6
  $cell = 2 * (16 + 24 + 32) + 4 * 8
  $rowH = 2 * 32 + 12
  $rows = [Math]::Ceiling($all.Count / $cols)
  $w = $cols * $cell; $h = $rows * $rowH
  $sheet = New-Object int[] ($w * $h)
  for ($i = 0; $i -lt $sheet.Length; $i++) { $sheet[$i] = $Edge }
  $n = 0
  foreach ($cls in $all.Keys) {
    $ox = ($n % $cols) * $cell + 8
    $oy = [Math]::Floor($n / $cols) * $rowH + 6
    foreach ($size in 16, 24, 32) {
      $px = [PPGIconMaker]::Render([string[]]$all[$cls], $pal, $size, $Key, $Edge)
      for ($y = 0; $y -lt 2 * $size; $y++) {
        for ($x = 0; $x -lt 2 * $size; $x++) {
          $c = $px[[Math]::Floor($y / 2) * $size + [Math]::Floor($x / 2)]
          if ($c -eq $Key) { $c = $Edge }
          $sheet[($oy + $y) * $w + $ox + $x] = $c
        }
      }
      $ox += 2 * $size + 8
    }
    $n++
  }
  [PPGIconMaker]::WritePng($Preview, $sheet, $w, $h)
  Write-Host "Vorschau: $Preview"
}
