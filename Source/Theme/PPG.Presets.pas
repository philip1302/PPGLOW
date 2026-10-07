unit PPG.Presets;

{ Composition Root der mitgelieferten Presets: Das Einbinden dieser Unit
  stellt sicher, dass alle Standard-Renderer registriert sind.
  Eigene Presets: Renderer von TPPGRendererBase ableiten und in der
  initialization der eigenen Unit per TPPGRendererRegistry.RegisterRenderer
  anmelden - kein PPGlow-Control muss dafuer geaendert werden. }

{$I ..\PPG.inc}

interface

uses
  PPG.Render.Classic, PPG.Render.ModernFlat, PPG.Render.Fluent11;

implementation

end.
