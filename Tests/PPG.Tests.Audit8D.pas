unit PPG.Tests.Audit8D;

{ Audit-Paket 8D (Docs\Audit-Paket8-Plan.md): Regressionstests. }

interface

uses
  TestFramework, PPG.Tests.Controls;

type
  TAudit8DTests = class(TControlTestCase)
  published
    procedure Placeholder;
  end;

implementation

procedure TAudit8DTests.Placeholder;
begin
  CheckTrue(True);
end;

initialization
  RegisterTest('Audit8D', TAudit8DTests.Suite);

end.
