#!/bin/sh

testdir=/dor/workspace/test/jhove-test
samples=$testdir/content-files
output=$testdir/output/jhove-out.xml
rm -f $output
JHOVE_HOME=`dirname $0`
$JHOVE_HOME/jhove.sh $samples > $output
less $output