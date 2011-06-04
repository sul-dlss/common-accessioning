#!/bin/sh

########################################################################
# JHOVE - JSTOR/Harvard Object Validation Environment
# Copyright 2003-2004 by JSTOR and the President and Fellows of Harvard College
# JHOVE is made available under the GNU General Public License (see the
# file LICENSE for details)
#
# Copy jhove.tmpl to jhove, and replace the value of JHOVE_HOME with
# the path to your jhove directory.
#
# Usage: jhove [-c config] [-m module [-p param]] [-h handler [-P param]]
#              [-e encoding] [-H handler] [-o output] [-x saxclass]
#              [-t tempdir] [-b bufsize] [[-krs] dir-file-or-uri [...]]
#
# where -c config   Configuration file pathname
#       -m module   Module name
#       -p param    Module-specific parameter
#       -h handler  Output handler name (defaults to TEXT)
#       -P param    Handler-specific parameter
#       -o output   Output file pathname (defaults to standard output)
#       -x saxclass SAX parser class (defaults to J2SE 1.4 default)
#       -t tempdir  Temporary directory in which to create temporary files
#       -b bufsize  Buffer size for buffered I/O (defaults to J2SE 1.4 default)
#       -k          Calculate CRC32, MD5, and SHA-1 checksums
#       -r          Display raw data flags, not textual equivalents
#       -s          Format identification based on internal signatures only
#       dir-file-or-uri Directory, file pathname or URI of formatted content
#
# Configuration constants:

# This script should be invoked using the full path
JHOVE_HOME=`dirname $0`
CONF=${JHOVE_HOME}/jhove.conf

JAVA_HOME=/etc/alternatives/jre
JAVA=/usr/bin/java

#XTRA_JARS=/users/stephen/xercesImpl.jar
EXTRA_JARS=              # Extra .jar files to add to CLASSPATH

# NOTE: Nothing below this line should be edited
########################################################################

CP=${JHOVE_HOME}/JhoveApp.jar:${EXTRA_JARS}

# Retrieve a copy of all command line arguments to pass to the application.

ARGS=""
for ARG do
    ARGS="$ARGS $ARG"
done

# Set the CLASSPATH and invoke the Java loader.
#{JAVA} -classpath $CP Jhove $ARGS -x org.apache.xerces.parsers.SAXParser
# ${JAVA} -classpath $CP Jhove $ARGS
${JAVA} -Xms128M -Xmx1024M -classpath $CP Jhove -c $CONF -h xml $ARGS
