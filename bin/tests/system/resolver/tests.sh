#!/bin/sh
#
# Copyright (C) 2004, 2007  Internet Systems Consortium, Inc. ("ISC")
# Copyright (C) 2000, 2001  Internet Software Consortium.
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS.  IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
# OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

# $Id: tests.sh,v 1.9.332.1 2010/05/19 06:43:42 marka Exp $

SYSTEMTESTTOP=..
. $SYSTEMTESTTOP/conf.sh

status=0

echo "I:checking non-cachable NXDOMAIN response handling"
ret=0
$DIG +tcp nxdomain.example.net @10.53.0.1 a -p 5300 > dig.out || ret=1
grep "status: NXDOMAIN" dig.out > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:checking non-cachable NODATA response handling"
ret=0
$DIG +tcp nodata.example.net @10.53.0.1 a -p 5300 > dig.out || ret=1
grep "status: NOERROR" dig.out > /dev/null || ret=1

if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`
echo "I:checking handling of bogus referrals"
# If the server has the "INSIST(!external)" bug, this query will kill it.
$DIG +tcp www.example.com. a @10.53.0.1 -p 5300 >/dev/null || status=1

echo "I:check handling of cname + other data / 1"
$DIG +tcp cname1.example.com. a @10.53.0.1 -p 5300 >/dev/null || status=1

echo "I:check handling of cname + other data / 2"
$DIG +tcp cname2.example.com. a @10.53.0.1 -p 5300 >/dev/null || status=1

echo "I:check that server is still running"
$DIG +tcp www.example.com. a @10.53.0.1 -p 5300 >/dev/null || status=1


echo "I:exit status: $status"
exit $status
