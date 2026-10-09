unit PPG.Tests.Audit7A;

{ Audit-Paket 7A (Docs\Audit-Paket7-Plan.md): Regressionstests. }

interface

uses
  TestFramework, PPG.Tests.Controls;

type
  TAudit7ATests = class(TControlTestCase)
  published
    procedure Placeholder;
  end;

implementation

procedure TAudit7ATests.Placeholder;
begin
  CheckTrue(True);
end;

initialization
  RegisterTest('Audit7A', TAudit7ATests.Suite);

end.
