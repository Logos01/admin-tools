package Logos::extract_url;

use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(extract_url);

sub extract_url {  
  my $file=shift;
  my $search=shift;

  open my $fh, '<', $file;

  my @urls;
  while (<$fh>) {
    chomp $_;
    if ( $_ =~ /$search/ ) {
      foreach (split "=", $_) {
        foreach (split '"', $_) {
          if ( $_ =~ /$search$/ ) {
            push(@urls, $_);
          }
        }
      }
    }
  }
  close $fh;
  if (@urls) { print $urls[-1]; }
}

1;
