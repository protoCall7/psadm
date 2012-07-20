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
# REQUIREMENTS: autodie, Term::Menus, IO::Uncompress::Gunzip, File::Copy,
# 				File::Unpack
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Peter H. Ezetta (PE), peter.ezetta@zonarsystems.com
#      COMPANY: Zonar Systems, Inc
#      VERSION: 1.0
#      CREATED: 07/19/2012 04:18:30 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use 5.010;
use autodie;
use Term::Menus;
use IO::Uncompress::Gunzip qw( gunzip $GunzipError );
use IO::Compress::Gzip qw( gzip $GzipError );
use File::Copy;
use File::Unpack;
use File::Path;
use diagnostics;

my @list       = ( 'Unpack', 'Repack' );
my $banner     = "Please select an operation:";
my $unpackdir  = "./image";
my $installdir = "/var/lib/tftpboot/ubuntu-installer/amd64";
my $image      = "initrd.gz";
my $newc       = "image.cpio";
my $selection;

#===  FUNCTION  ================================================================
#         NAME: unpack
#      PURPOSE: Unpack initrd.gz image into working directory
#   PARAMETERS: None 
#      RETURNS: None 
#  DESCRIPTION: This function uncompresses, and unpacks an initrd.gz image.
#       THROWS: no exceptions
#     COMMENTS: none
#     SEE ALSO: repack 
#===============================================================================
sub unpack {
    my $uh = File::Unpack->new;

    #chdir $installdir;

    die("FATAL:  initrd.gz Not Found!") unless -e $image;

    unless ( -e $unpackdir ) {
        print "Creating image directory: $unpackdir...\n";
        mkdir $unpackdir;
    }

    print "Uncompressing $image...\n";
    gunzip $image => $newc;
    $uh->unpack( $newc, $unpackdir );

    unlink($newc);
    unlink($image);
    print "Image Uncompressed to $unpackdir\n";
}

#===  FUNCTION  ================================================================
#         NAME: repack
#      PURPOSE: Repack working directory into initrd.gz image.
#   PARAMETERS: None
#      RETURNS: None
#  DESCRIPTION: This function packs the working directory into a newc formatted
#  				cpio archive, then compresses it with gzip into an initrd image
#       THROWS: no exceptions
#     COMMENTS: none
#     SEE ALSO: unpack 
#===============================================================================
sub repack {

    #chdir $installdir;

    unless ( -e $unpackdir ) {
        print "No Image to Repack!\n";
        exit(1);
    }
    print "Creating cpio Archive...\n";
    system("find $unpackdir | cpio --create --format='newc' > $newc");
    print "Compressing cpio Archive...\n";
    gzip $newc => $image;

    unlink($newc);
    rmtree($unpackdir);
}

$selection = &pick( \@list, $banner );
print $selection;

given ($selection) {
    when (/Unpack/) {
        &unpack;
    }
    when (/Repack/) {
        &repack;
    }
}
