#!/usr/bin/perl

use strict;
use warnings;
use IO::Pty;
use Net::OpenSSH;

my $host=shift;
my $user=shift;
my $password=shift;

my $ssh = Net::OpenSSH->new($host,default_ssh_opts=>['-oLogLevel=QUIET',],user=>"$user",password=>"$password",);

my($pty,$err,$pid) = $ssh->open3pty();

print $pty "\n\r";
my ($com1, $com2, $com3);

my $remotescript = '
pwd
echo ${PATH}
cd /usr/local/sbin
cd ../bin
ls -l
';

STDOUT: while (<$pty>) {
  print "$host:STDOUT:$_";
  if ( "$_" =~ /\$/ ) {
    unless ($com1) {
      print $pty "$remotescript\r";
      $com1 = 1;
    }
    unless ($com2) {
      print $pty 'echo "EXIT STATUS: $?"'; print $pty "\r";
      $com2 = 1;
    }
    unless ($com3) {
      print $pty "\n\r";
      $com3 = 1;
    }
  }
  last STDOUT if "$_" =~ /EXIT STATUS: [0-9]+/;
}

$ssh->system("ls /tmp")
  or die "remote command failed:" . $ssh->ereror;

$ssh->rsync_put(
	{
		verbose => 1,
		archive => 1,
		compress_level => 3,
	},
	"./basefile.html",
	"/tmp"
);
