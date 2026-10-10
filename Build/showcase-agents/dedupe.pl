# Danach Schluessel, die schon in 91-praxis-typen.txt stehen, aus den
# 95-praxis-*.txt entfernen (siehe Ende).
# Doppelte Praxis-Schluessel ("Key ! Text") aus den 95-praxis-*.txt in
# 91-praxis-typen.txt zusammenfuehren: erste Fassung (alphabetisch nach
# Datei) bleibt, die anderen Zeilen werden entfernt.
# Aufruf im Ordner Docs\Controls\props: perl dedupe.pl
use strict; use warnings;
my @files = sort glob('95-praxis-*.txt');
my (%where, %text, @order);
for my $f (@files) {
  open my $h, '<:raw', $f or die $f;
  while (my $l = <$h>) {
    if ($l =~ /^([\w.]+)\s*!\s*/) {
      my $k = $1;
      push @{$where{$k}}, $f;
      if (!exists $text{$k}) { $text{$k} = $l; push @order, $k; }
    }
  }
  close $h;
}
my @dup = grep { @{$where{$_}} > 1 } @order;
goto CLEAN unless @dup;
# vorhandene gemeinsame Datei lesen (Schluessel dort nicht nochmal anhaengen)
my $common = '91-praxis-typen.txt';
my %have; my $content = '';
if (-e $common) {
  open my $h, '<:raw', $common or die; local $/; $content = <$h>; close $h;
  $have{$1} = 1 while $content =~ /^([\w.]+)\s*!/mg;
} else {
  $content = "# Praxis-Texte fuer gemeinsame Typen (Unterobjekte, Collection-Eintraege),\n# die mehrere Komponentenseiten brauchen. Format: siehe Build\\make-docs.ps1.\n";
}
for my $k (@dup) {
  next if $have{$k};
  my $t = $text{$k}; $t =~ s/\r?\n?$/\n/;
  $content .= $t;
}
open my $o, '>:raw', $common or die; print $o $content; close $o;
my %isdup = map { $_ => 1 } @dup;
for my $f (@files) {
  open my $h, '<:raw', $f or die; my @l = <$h>; close $h;
  my @keep = grep { !(/^([\w.]+)\s*!/ && $isdup{$1}) } @l;
  if (@keep != @l) { open my $w, '>:raw', $f or die; print $w @keep; close $w; }
}
print scalar(@dup), " gemeinsame Schluessel nach $common\n";
CLEAN:
# Schluessel, die schon in der gemeinsamen Datei stehen, aus den
# Komponenten-Dateien entfernen
{
  my %have;
  if (open my $c, '<:raw', '91-praxis-typen.txt') { while (<$c>) { $have{$1} = 1 if /^([\w.]+)\s*!/ } close $c; }
  for my $f (glob('95-praxis-*.txt')) {
    open my $h, '<:raw', $f or die; my @l = <$h>; close $h;
    my @k = grep { !(/^([\w.]+)\s*!/ && $have{$1}) } @l;
    if (@k != @l) { open my $w, '>:raw', $f or die; print $w @k; close $w; print "$f: ", scalar(@l) - scalar(@k), " entfernt\n"; }
  }
}
