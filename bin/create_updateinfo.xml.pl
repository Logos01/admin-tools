#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use Text::Unidecode;
use Frontier::Client;
use XML::Simple;
use Time::Local;
#use XML::Writer;
use IO::File;

my $opt_erratadir='/root/tmp/centos-errata';
my $opt_debug;
my $opt_quiet;
my $os_release;

my $opt_os_version='7';

sub debug($) {
  print "DEBUG: @_" if ($opt_debug);
}

sub info($) {
  print "INFO: @_" if (!$opt_quiet);
}

sub warning($) {
  print "WARNING: @_";
}

sub error($) {
  print "ERROR: @_";
}


sub parse_message($$) {
	my ($part, $subject) = @_;
	
	(my $upstream_details = $part) =~ s/.*Upstream details at : (.*?)\n.*/$1/s;
	$upstream_details =~ s/.*\>(.*)\<.*/$1/;
	$subject =~ s/\n//gs;
	$subject =~ s/\s+/ /g;
	(my $advid = $subject) =~ s/(.*?) .*/$1/;
	(my $synopsis = $subject) =~ s/.*? (.*)/$1/;
        my $os_release ='0';
        if ($subject  =~ /.* (\d+) .*/) {
                $os_release=$1;
        } elsif ($subject  =~ /.*\-(\d+) .*/) {
                $os_release=$1;
        }

	my $centos_xen_errata=0;
	if ( $os_release =~ /\D/) {
	   # OS release is not an integer, happens for xen and CSL errata
	   # so we just set it to the OS release, the package details will later point
	   # out if the advisory can be applied or not
	   $os_release = $opt_os_version;
	   if ($subject =~ /xen/i) {
		# xen errata need special treatment because of different format
		$centos_xen_errata=1;
	   }
	}

	if ( $os_release != $opt_os_version) {
		return;
	}

	# now get the packages per architecture
	my $i386_packages="";
	my $x86_64_packages="";
	my $s390x_packages="";

	if ($centos_xen_errata) {
		($part =~ /I386/s) && (($i386_packages = $part) =~ s/.*I386\s*\n\-+\n(.*?)\n\n.*/$1/s);
		($part =~ /X86_64/s) && (($x86_64_packages = $part) =~ s/.*X86_64\s*\n\-+\n(.*?)\n\n.*/$1/s);
	} else {
		($part =~ /i386:/s) && (($i386_packages = $part) =~ s/.*i386:\n(.*?)\n\n.*/$1/s);
		($part =~ /x86_64:/s) && (($x86_64_packages = $part) =~ s/.*x86_64:\n(.*?)\n\n.*/$1/s);
		($part =~ /s390x:/s) && (($s390x_packages = $part) =~ s/.*s390x:\n(.*?)\n\n.*/$1/s);
	}
	# remove first empty line
	$i386_packages =~ s/^\n//;
	$x86_64_packages =~ s/^\n//;
	$s390x_packages =~ s/^\n//;
	# remove emtpy lines
	$i386_packages =~ s/\n\s*\n/\n/g;
	$x86_64_packages =~ s/\n\s*\n/\n/g;
	$s390x_packages =~ s/\n\s*\n/\n/g;
	# remove last empty line
	$i386_packages =~ s/\n\s*$//;
	$x86_64_packages =~ s/\n\s*$//;
	$s390x_packages =~ s/\n\s*$//;
	debug("$advid i386 packages info found:\n$i386_packages\n");
	debug("$advid x86_64 packages info found:\n$x86_64_packages\n");
	debug("$advid s390x packages info found:\n$s390x_packages\n");
	my @i386_packages = split(/\n/s,$i386_packages);
	my @x86_64_packages = split(/\n/s,$x86_64_packages);
	my @s390x_packages = split(/\n/s,$s390x_packages);
	# remove the checksum info
	s/\S+\s+// for @i386_packages;
	s/\S+\s+// for @x86_64_packages;
	s/\S+\s+// for @s390x_packages;
	
	my $adv_type="";
	if (substr($advid,2,2) eq "SA") { $adv_type="Security Advisory";}
	elsif (substr($advid,2,2) eq "BA") { $adv_type="Bug Fix Advisory";}
	elsif (substr($advid,2,2) eq "EA") { $adv_type="Product Enhancement Advisory";}
	else {
		# something undetermined
		return;
	}
	
	my $adv={};
	$adv->{'synopsis'}=$synopsis;
	$adv->{'release'}=1;
	$adv->{'type'}=$adv_type;
	$adv->{'advisory_name'}=$advid;
	$adv->{'product'}="CentOS Linux";
	$adv->{'topic'}="not available";
	$adv->{'description'}="not available";
	$adv->{'notes'}="not available";
	$adv->{'solution'}="not available";
	$adv->{'os_release'}=$os_release;
	$adv->{'references'}="$upstream_details";
	# depending on the value off opt_architecture, one of the following will be used
	$adv->{'i386_packages'}=\@i386_packages;
	$adv->{'x86_64_packages'}=\@x86_64_packages;
	$adv->{'s390x_packages'}=\@s390x_packages;
	# the next is just to be able to skip looking for xen errata in rhn, when that option is choosen
	if ($centos_xen_errata) {
		$adv->{'centos_xen_errata'}=1;
	}
	return $adv;
}

sub parse_archivedir() {
  opendir(my $dh, $opt_erratadir) || die "can't opendir $opt_erratadir: $!";
  my @files = grep { !/^\./ && -f "$opt_erratadir/$_" } readdir($dh);
  closedir $dh;

  my $xml = {};

  foreach my $file (@files) {
	local $/=undef;
	open(IN,"$opt_erratadir/$file");
	my $string = <IN>;
	close(IN);
	local $/="\n";

	if($string =~ /\<TITLE\>\s+\[CentOS-announce\]\s+CE/) {
		debug("Single archive: $opt_erratadir/$file\n");
		my $part = $string;

		(my $subject = $part) =~ s/.*\<TITLE\> \[CentOS-announce\] (CE.*?)\<\/TITLE\>.*/$1/s;
		$part =~ s/.*\<PRE\>(.*?)\<\/PRE\>.*/$1/s;

		my $adv = parse_message($part, $subject);

		if(!defined $adv) {
			next;
		}

		$xml->{$adv->{'advisory_name'}}=$adv;
	} elsif($string =~ /\<TITLE\>\s+\[CentOS\]\s+CentOS-announce\s+Digest/) {
		debug("Multiple archive: $opt_erratadir/$file\n");
		
		my @parts = split(/Message:/,$string);
		# skip the first part, since it's general info
		shift(@parts);
		foreach my $part (@parts) {
			my $subject=$part;
			# concat the lines starting with white spaces to the previous line
        		$subject =~ s/\n\s+/ /gs;

			if ($subject !~ /Subject: \[CentOS-announce\] CE/s) {
				next;
			}
			$subject =~ s/.*Subject: \[CentOS-announce\] (CE.*?)\n.*/$1/s;
			#print "$subject\n";
	
			my $adv = parse_message($part, $subject);
			if (!defined($adv->{'advisory_name'})) {
				next;
			}
			$xml->{$adv->{'advisory_name'}}=$adv;
		}
	}
  }
  return $xml;
}


my $updateinfo= parse_archivedir();

my $updateinfo_xml = XML::Simple::XMLout($updateinfo);

print $updateinfo_xml;
