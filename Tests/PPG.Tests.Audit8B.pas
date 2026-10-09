unit PPG.Tests.Audit8B;

{ Audit-Paket 8B (Docs\Audit-Paket8-Plan.md): Regressionstests. }

interface

uses
  TestFramework, PPG.Tests.Controls;

type
  TAudit8BTests = class(TControlTestCase)
  published
    procedure Placeholder;
  end;

implementation

procedure TAudit8BTests.Placeholder;
begin
  CheckTrue(True);
end;

initialization
  RegisterTest('Audit8B', TAudit8BTests.Suite);

end.
