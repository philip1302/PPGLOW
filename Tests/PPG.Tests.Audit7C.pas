unit PPG.Tests.Audit7C;

{ Audit-Paket 7C (Docs\Audit-Paket7-Plan.md): Regressionstests. }

interface

uses
  TestFramework, PPG.Tests.Controls;

type
  TAudit7CTests = class(TControlTestCase)
  published
    procedure Placeholder;
  end;

implementation

procedure TAudit7CTests.Placeholder;
begin
  CheckTrue(True);
end;

initialization
  RegisterTest('Audit7C', TAudit7CTests.Suite);

end.
