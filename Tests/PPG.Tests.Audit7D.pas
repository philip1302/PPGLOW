unit PPG.Tests.Audit7D;

{ Audit-Paket 7D (Docs\Audit-Paket7-Plan.md): Regressionstests. }

interface

uses
  TestFramework, PPG.Tests.Controls;

type
  TAudit7DTests = class(TControlTestCase)
  published
    procedure Placeholder;
  end;

implementation

procedure TAudit7DTests.Placeholder;
begin
  CheckTrue(True);
end;

initialization
  RegisterTest('Audit7D', TAudit7DTests.Suite);

end.
