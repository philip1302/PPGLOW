# Traegt alle Demo\Showcase\*.pas, die noch fehlen, in PPGlowDemo.dpr (vor
# "DemoMain in") und PPGlowDemo.dproj (vor DemoMain.pas) ein. Beispiel-Units
# (Ex*) vor den Seiten (DemoShow*). Aufruf im Ordner Demo.
use strict; use warnings;
my @units = map { s/^Showcase\///; s/\.pas$//; $_ } sort glob('Showcase/*.pas');
my @ex = grep { /^Ex/ } @units;
my @show = grep { /^DemoShow/ && $_ ne 'DemoShowcase' } @units;
local $/;
open my $h, '<:raw', 'PPGlowDemo.dpr' or die; my $dpr = <$h>; close $h;
open $h, '<:raw', 'PPGlowDemo.dproj' or die; my $dproj = <$h>; close $h;
my ($adpr, $adproj) = ('', '');
for my $u (@ex, @show) {
  if ($dpr !~ /\b\Q$u\E in /) { $adpr .= "  $u in 'Showcase\x5C$u.pas',\r\n"; }
  if ($dproj !~ /Include="Showcase\x5C\Q$u\E\.pas"/) { $adproj .= "        <DCCReference Include=\"Showcase\x5C$u.pas\"/>\r\n"; }
}
$dpr =~ s/(  DemoMain in 'DemoMain\.pas')/$adpr$1/ or die "dpr";
$dproj =~ s/(        <DCCReference Include="DemoMain\.pas"\/>)/$adproj$1/ or die "dproj";
open my $o, '>:raw', 'PPGlowDemo.dpr' or die; print $o $dpr; close $o;
open $o, '>:raw', 'PPGlowDemo.dproj' or die; print $o $dproj; close $o;
my $n = () = $adpr =~ /\n/g;
print "$n Units eingetragen\n";
