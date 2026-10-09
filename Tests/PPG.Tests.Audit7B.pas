unit PPG.Tests.Audit7B;

{ Audit-Paket 7B (Docs\Audit-Paket7-Plan.md): Regressionstests. }

interface

uses
  TestFramework, PPG.Tests.Controls;

type
  TAudit7BTests = class(TControlTestCase)
  published
    procedure Placeholder;
  end;

implementation

procedure TAudit7BTests.Placeholder;
begin
  CheckTrue(True);
end;

initialization
  RegisterTest('Audit7B', TAudit7BTests.Suite);

end.
