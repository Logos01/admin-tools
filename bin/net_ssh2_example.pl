#!/usr/bin/perl


use strict;
use warnings;

use Term::ReadKey;
use Net::SSH2;
use LWP::Simple;
use User::pwent;

our $user = shift;
our $remoteuser = shift;
our $host = shift;

unless ( $user ) {
  print "\nLocal User: ";
  $user = ReadLine(0);
  chomp $user; $user =~ s/\r//;
  print "$user";
}

unless ( $remoteuser ) {
  print "\nRemote User: ";
  $remoteuser = ReadLine(0);
  chomp $remoteuser; $remoteuser =~ s/\r//;
  print "$remoteuser\n";
}

unless ( $host ) {
  print "\nRemote Host: ";
  $host = ReadLine(0);
  chomp $host; $host =~ s/\r//;
}

my $pw = getpwnam("$user") or die "Unknown user $user\n";
my $homedir = $pw->dir;

unless( $homedir ) {
  exit(1);
}

my $ssh = Net::SSH2->new();

unless ( $ssh->connect($host)) {
  print "Failed to connect to $host\n";
  exit(1);
}

my $testfile= "testfile" . time();
chomp $testfile;
my $data = get("http://www.google.com");
system("touch $testfile");
open my $fh, ">", "$testfile";
print $fh $data;
close $fh;

if (! $ssh->auth_publickey($remoteuser,"$homedir/.ssh/id_rsa.pub","$homedir/.ssh/id_rsa")) {
  ReadMode('noecho');
  print "\nPassword: ";
  my $pass = ReadLine(0);
  chomp $pass; $pass =~ s/\r//;
  ReadMode('restore');
  print "\n";
  unless ( $ssh->auth_password($remoteuser,$pass) ) {
    print "Authentication failed.\n";
    exit(1);
  }
} else {
  system("sleep 0.5");
  unless ( $ssh->scp_put($testfile,"/home/$remoteuser/$testfile") ) {
    my @error = $ssh->error();
    die("@error");
  } else {
    my $chan = $ssh->channel();
    $chan->shell();
    $chan->blocking(0);
    print $chan "uname -a\n";
    print "LINE: $_" while <$chan>;
    $chan->close;
  }
}


ReadMode('restore');
$ssh->disconnect();
exit(0);
