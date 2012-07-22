#===============================================================================
#
#         FILE: Initrd.pm
#
#  DESCRIPTION: initrd methods for psadm
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Peter H. Ezetta (PE), peter.ezetta@zonarsystems.com
# ORGANIZATION: Zonar Systems, Inc.
#      VERSION: 1.0
#      CREATED: 07/21/2012 19:15:23
#     REVISION: ---
#===============================================================================

package Initrd;
use strict;
use warnings;
use File::Unpack;
use IO::Uncompress::Gunzip qw( gunzip $GunzipError );
use IO::Compress::Gzip qw( gzip $GzipError );

my $installdir = "/var/tftpboot/netboot/ubuntu-installer/amd64";
my $unpackdir  = "./image";
my $image      = "initrd.gz";
my $newc       = "image.cpio";

#===  FUNCTION  ================================================================
#         NAME: unpack
#      PURPOSE: Unpack initrd.gz image into working directory
#   PARAMETERS: None
#      RETURNS: None
#  DESCRIPTION: This function uncompresses, and unpacks an initrd.gz image.
#       THROWS: no exceptions
#     COMMENTS:
#     SEE ALSO: repack
#===============================================================================
sub unpack {
    my $uh = File::Unpack->new;

    chdir $installdir;

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
}    ## --- end sub unpack

#===  FUNCTION  ================================================================
#         NAME: repack
#      PURPOSE: Repack working directory into initrd.gz image.
#   PARAMETERS: None
#      RETURNS: None
#  DESCRIPTION: This function packs the working directory into a newc formatted
# 	  		    cpio archive, then compresses it with gzip into an initrd image
#       THROWS: no exceptions
#     COMMENTS:
#     SEE ALSO: unpack
#===============================================================================
sub repack {
    chdir $installdir;

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
}    ## --- end sub repack
