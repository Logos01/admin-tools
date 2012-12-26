package Logos::extract_url;

use Exporter;
use IO;

@ISA = qw(Exporter);
@EXPORT = qw(extract_url);

sub extract_url {  
  my $file=shift;
  my $search=shift;

  my $fh;

  if (-e $file){
    open $fh, '<', $file;
  } else { 
    open $fh, '<', \$file;
  }
  
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
