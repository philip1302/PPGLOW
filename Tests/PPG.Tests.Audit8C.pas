unit PPG.Tests.Audit8C;

{ Audit-Paket 8C (Docs\Audit-Paket8-Plan.md): Regressionstests. }

interface

uses
  TestFramework, PPG.Tests.Controls;

type
  TAudit8CTests = class(TControlTestCase)
  published
    procedure Placeholder;
  end;

implementation

procedure TAudit8CTests.Placeholder;
begin
  CheckTrue(True);
end;

initialization
  RegisterTest('Audit8C', TAudit8CTests.Suite);

end.
