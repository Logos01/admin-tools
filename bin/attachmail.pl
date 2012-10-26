#!/usr/bin/perl -w
use strict;
use Getopt::Long;

our ($to, $sub, $from, @files, $body);
our ($help, $debug);

GetOptions(
  't|to=s' => \$to,
  's|subject=s' => \$sub,
  'f|files=s@' => \@files,
  'from=s' => \$from,
  'b|body=s' => \$body,
  'h|help' => \$help,
  'd|debug' => \$debug,
);

unless($to){
  $to = shift @ARGV;
  $from = shift @ARGV;
  $files[0] = shift @ARGV;
  $sub = shift @ARGV;
  $body = shift @ARGV;
}

if($help){
  Usage();
}

unless($to){
  Usage();
}

sub Usage {
  print "Usage:\n";
  print "--t=|to=: <message recipient email address>\n";
  print "--s=|subject=: <subject of e-mail.>\n";
  print "--from=: [<message sender address.>[Defaults to unixuser\@localhost]\n";
  print "--b=|body=: <Body of the e-mail. Plaintext.>\n";
  print "--f=|files=: <individual file to be attached. Multiple invocations allowed.>\n";
  print "--h|help: prints this usage message.\n";
  exit(0);
}

our $shell="bash";
if ( $debug ) {
  $shell="bash -x";
}

if ( ! $from ) {
  my $sender = `whoami`;
  my $host = `hostname`;
  $sender =~ s/\n//;
  $host =~ s/\n//;
  $from = $sender . '@' . $host;
}

my $email;
open EMAIL, '+>', \$email;
print EMAIL "From: $from\n";
print EMAIL "To: $to\n";
print EMAIL "Mime-Version: 1.0\n";
print EMAIL "Content-Type: Multipart/Mixed;\n";
my $nextline = "\tboundary=" . '"ATTACHMENT-BOUNDARY"' . "\n";
print EMAIL $nextline;
print EMAIL "Return-Receipt-To: $from\n";
print EMAIL "Subject: $sub\n\n";
print EMAIL "--ATTACHMENT-BOUNDARY\n";
print EMAIL "Content-Disposition: inline;\n";
print EMAIL "Content-Type: text/plain;\n";
print EMAIL "\n$body\n";
foreach my $file ( @files ){
  my $mimetype = `file --mime $file | cut -d' ' -f2 | tr -d '\\n'`;
  $mimetype =~ s/$/;/;
  print EMAIL "\n--ATTACHMENT-BOUNDARY\n";
  print EMAIL "Content-Disposition: attachment;\n";
  my $nextline = "\tfilename=" . '"' . $file . '"' . "\n";
  print EMAIL "$nextline";
  print EMAIL "Content-Type: $mimetype";
  $nextline =~ s/filename/name/;
  print EMAIL "$nextline";
  print EMAIL "Content-Transfer-Encoding: base64;\n";
  my $base64 = `base64 $file`;
  $base64 =~ s/\n//g;
  print EMAIL "\n$base64\n";
}
print EMAIL "\n--ATTACHMENT-BOUNDARY--\n";
if ($debug) { 
  print $email;
 }
else{
  open(SENDCOMM,"|sendmail -t");
  print SENDCOMM $email;
  close SENDCOMM;
}
close EMAIL;

exit(0);
