unit PPG.DpiUtils;

{ DPI- und Systemabfragen fuer Controls.

  DPI-Strategie der Suite: Alle Masse werden logisch (96 DPI) gespeichert und
  erst beim Zeichnen mit der aktuellen PPI des Controls skaliert.
  - ab 10.3: TControl.CurrentPPI (Per-Monitor-V2)
  - davor  : Screen.PixelsPerInch (System-DPI)
  ChangeScale muss deshalb fuer die Glow-Masse NICHT ueberschrieben werden
  -> keine Doppelskalierung bei Monitorwechsel. }

{$I ..\PPG.inc}

interface

uses
  Vcl.Controls;

function PPGControlPPI(Control: TControl): Integer;
function PPGIsHighContrast: Boolean;
/// Fragt den UI-Zustand (UISF_HIDEFOCUS / UISF_HIDEACCEL) per WM_QUERYUISTATE ab.
/// ACHTUNG: NIE waehrend Paint aufrufen! Jede Nachricht fuehrt in der VCL zu
/// FreeMemoryContexts, das den DC einer Ziel-TBitmap (PaintTo, Drucken,
/// Screenshots) mitten im Zeichnen ungueltig macht. Ergebnis zwischenspeichern.
function PPGQueryUIState(Control: TWinControl): Cardinal;
/// Auswertung eines zwischengespeicherten UI-Zustands.
function PPGFocusCuesVisible(UIState: Cardinal): Boolean;
function PPGAcceleratorCuesVisible(UIState: Cardinal): Boolean;

implementation

uses
  Winapi.Windows, Winapi.Messages, Vcl.Forms;

function PPGControlPPI(Control: TControl): Integer;
begin
{$IFDEF PPG_HAS_PPI}
  if Control <> nil then
    Result := Control.CurrentPPI
  else
    Result := Screen.PixelsPerInch;
{$ELSE}
  Result := Screen.PixelsPerInch;
{$ENDIF}
  if Result <= 0 then
    Result := 96;
end;

function PPGIsHighContrast: Boolean;
var
  HC: THighContrast;
begin
  FillChar(HC, SizeOf(HC), 0);
  HC.cbSize := SizeOf(HC);
  Result := SystemParametersInfo(SPI_GETHIGHCONTRAST, SizeOf(HC), @HC, 0) and
    ((HC.dwFlags and HCF_HIGHCONTRASTON) <> 0);
end;

function PPGQueryUIState(Control: TWinControl): Cardinal;
begin
  if (Control = nil) or not Control.HandleAllocated then
    Result := 0
  else
    Result := Cardinal(SendMessage(Control.Handle, WM_QUERYUISTATE, 0, 0));
end;

function PPGFocusCuesVisible(UIState: Cardinal): Boolean;
begin
  Result := (UIState and UISF_HIDEFOCUS) = 0;
end;

function PPGAcceleratorCuesVisible(UIState: Cardinal): Boolean;
begin
  Result := (UIState and UISF_HIDEACCEL) = 0;
end;

end.
