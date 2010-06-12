# $Id: MyConfig.pm 1771 2009-10-08 20:24:20Z mjs $

# This configures "cpan" to install modules locally in 
# $HOME/local/lib/CPAN.  To use it,
#
# 1. 
#
# Run cpan's setup program.  This will generate the file:
#
#   ~/.cpan/CPAN/MyConfig.pm
#
# Don't worry about the settings for makepl_arg and mbuildpl_arg--
# this file will (eventually) overwrite them.  The point is to
# get this file created, and with the options set that "cpan" 
# expects to be set.  (e.g. if a new version of "cpan" comes out, 
# it might expect more variables to be set, which our custom version
# won't have.)
#
# 2.
#
# Copy this somewhere in the PERL5LIB path, such that it is
# loaded via "use CPAN::Config".  For example, if 
# $HOME/local/lib/CPAN is in the PERL5LIB path, this is a
# suitable filename:
#
#   $HOME/local/lib/CPAN/CPAN/Config.pm
#
# What's going to happen is that we load this config using the
# "use CPAN::Config" call below, and then amend a few settings.
#
# 3.
#
# Run ~/.config/install to replace the generated MyConfig.pm with
# this file.  This file overwrites some of the settings.
#
# 4.
#
# Check on the settings:
#
#   cpan> o conf
#
# If the custom configuration doesn't seem to be picked up, and
# the situation needs to be debugged, start by looking at
#
#   CPAN::HandleConfig::require_myconfig_or_config()
#
# (On OS X, cpan started looking for CPAN::MyConfig in
# ~/Library/Application Support/.cpan.)
#
# 5.
#
# If you need to install CPAN itself, get it via:
#
# http://search.cpan.org/search?query=CPAN&mode=all

use CPAN::Config;

$CPAN::Config->{'makepl_arg'} = q[LIB=$HOME/local/lib/CPAN INSTALLMAN1DIR=$HOME/local/man/man1 INSTALLMAN3DIR=$HOME/local/man/man3 INSTALLSCRIPT=$HOME/local/lib/CPAN/bin INSTALLDIRS=perl];
$CPAN::Config->{'mbuildpl_arg'} = q[--install_path arch=$LOCAL/lib/CPAN --install_path lib=$HOME/local/lib/CPAN --install_path script=$HOME/local/lib/CPAN/bin --install_path bin=$LOCAL/bin --install_path libdoc=$HOME/local/man/man3 --install_path bindoc=$HOME/local/man/man1];

1;

__END__
