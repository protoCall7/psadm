#!/usr/bin/perl 
#===============================================================================
#
#         FILE: psadm.pl
#
#        USAGE: ./psadm.pl
#
#  DESCRIPTION: Administration tool for Ubuntu Preseed Configuration
#
#      OPTIONS: ---
# REQUIREMENTS: autodie, Term::Menus, File::Copy, File::Path, File::Fetch
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Peter H. Ezetta (PE), peter.ezetta@zonarsystems.com
#      COMPANY: Zonar Systems, Inc
#      VERSION: 1.1
#      CREATED: 07/19/2012 04:18:30 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use 5.010;
use autodie;
use Term::Menus;
use File::Copy;
use File::Path;
use File::Fetch;
use diagnostics;
require "Initrd.pm";

my @list       = ( 'Fetch', 'Unpack', 'Interface', 'Repack' );
my $banner     = "Please select an operation:";
my $unpackdir  = "./image";
my $installdir = "/var/tftpboot/netboot/ubuntu-installer/amd64";
my $image      = "initrd.gz";
my $preseed    = "preseed.cfg";
my $tftpdir    = "/var/tftpboot";
my $selection;

#===  FUNCTION  ================================================================
#         NAME: setNetIface
#      PURPOSE: Configures the default network interface in preseed.cfg
#   PARAMETERS: Network Interface Name
#      RETURNS: None
#  DESCRIPTION: Searches the preseed.cfg file for the default network interface
#  				and sets it according to user input.
#       THROWS: no exceptions
#     COMMENTS:
#     SEE ALSO: n/a
#===============================================================================
sub setNetIface {
    my $interface = shift;
    local $^I   = '.bk';
    local @ARGV = ("$preseed");

    chdir $installdir;
    chdir $unpackdir;
    unless ( -e $preseed ) {
        print "FATAL:  $preseed Not Found!";
        exit(1);
    }

    while (<>) {
        s/choose_interface select eth\d{1}/choose_interface select $interface/;
        print;
    }
}    ## --- end sub setNetIface

#===  FUNCTION  ================================================================
#         NAME: fetchNetboot
#      PURPOSE: Fetches Netboot image from Ubuntu
#   PARAMETERS: None
#      RETURNS: None
#  DESCRIPTION: Fetches Ubuntu 12.04 (Precise) netboot images from
#  				archive.ubuntu.com and unpacks them.
#       THROWS: no exceptions
#     COMMENTS: none
#     SEE ALSO: n/a
#===============================================================================
sub fetchNetboot {
    print "Fetching netboot.tar.gz...\n";
    my $ff =
      File::Fetch->new( uri =>
'http://archive.ubuntu.com/ubuntu/dists/precise/main/installer-amd64/current/images/netboot/netboot.tar.gz'
      );

    unless ( -e $tftpdir ) {
        print "$tftpdir does not exist.  Create it? [y/n]: ";
        my $response = <STDIN>;
        chomp $response;
        for ($response) {
            when (/y/) {
                mkdir $tftpdir;
            }
            when (/n/) {
                exit;
            }
            default {
                print "$response is not a valid response.\n";
                exit;
            }
        }
    }
    my $where = $ff->fetch( to => $tftpdir );
    print "Fetched netboot into $where.\n";

    print "Unpacking tarball...\n";
    chdir $tftpdir;
    my $u = File::Unpack->new;
    $u->unpack( 'netboot.tar.gz', $tftpdir );
    print
      "Netboot Image Installed.  Please Unpack Image, Install preseed.cfg to 
	  $installdir/image\nand Repack Image.\n";
}    ## --- end sub fetchNetboot

#-------------------------------------------------------------------------------
#  Generate menu and call appropriate subroutine.
#-------------------------------------------------------------------------------
$selection = &pick( \@list, $banner );

for ($selection) {
    when (/Unpack/) {
        &Initrd::unpack;
    }
    when (/Repack/) {
        &Initrd::repack;
    }
    when (/Interface/) {
        print "Please enter a network interface: ";
        my $interface = <STDIN>;
        chomp $interface;
        &setNetIface($interface);
    }
    when (/Fetch/) {
        &fetchNetboot;
    }
}
